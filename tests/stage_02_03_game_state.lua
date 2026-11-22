-- Stage 2.3 standalone Lua mock tests: lua tests/stage_02_03_game_state.lua
-- No WoW client, Blizzard or external network required.
local KR = {}
local time = 10
local hasTarget = false
local currentPlayerHealth = 50
local playerGuid = "Player-1"
local secretGuid = nil

GetTime = function() return time end
UnitExists = function(unit) return unit == "player" or (unit == "target" and hasTarget) end
UnitGUID = function(unit)
    if unit == "player" then return secretGuid or playerGuid end
    return "Creature-2"
end
UnitClass = function() return "Warrior", "WARRIOR" end
UnitLevel = function() return 60 end
UnitIsDeadOrGhost = function() return false end
UnitAffectingCombat = function() return false end
InCombatLockdown = function() return false end
IsMounted = function() return false end
UnitCanAttack = function(_, unit) return unit=="target" end
UnitCanAssist = function() return false end
UnitIsUnit = function() return false end
UnitHealth = function(unit) return unit == "player" and currentPlayerHealth or 80 end
UnitHealthMax = function() return 100 end
UnitPowerType = function() return 1 end
UnitPower = function() return 25 end
UnitPowerMax = function() return 100 end
UnitCastingInfo = function() return nil end
UnitChannelInfo = function() return nil end
issecretvalue = function(value) return value == "SECRET" end

local frameCount=0
CreateFrame=function()
    frameCount=frameCount+1
    return {
        RegisterEvent=function() end,
        SetScript=function(self,key,fn) self[key]=fn end
    }
end

local function module(path)
    local loader=assert(loadfile("KordRotation/"..path))
    loader("KordRotation",KR)
end
module("Core/GameAPI.lua")
module("Core/EventBus.lua")
module("Core/AuraEvidence.lua")
module("Core/GameState.lua")

local function eq(actual,expected,message)
    if actual~=expected then
        error((message or "mismatch")..": expected "..tostring(expected)..
            ", got "..tostring(actual),2)
    end
end

-- Opt-in diagnostics observe every real adapter call; method presence
-- probes stay distinct and neither game arguments nor values are saved.
eq(KR.GameAPI:BeginDiagnosticTrace(),true,"trace explicitly enabled")
eq(KR.GameAPI:Read("UnitExists","boolean","target").value,false,
 "trace: normal API read")
eq(KR.GameAPI:Read("UnitExists","boolean","target").value,false,
 "trace: repeated API read")
eq(KR.GameAPI:Read("UnitExists","string","target").status,"UNKNOWN",
 "trace: rejected return type")
eq(KR.GameAPI:Probe("UnitExists").status,"READY",
 "trace: presence-only probe")
eq(KR.GameAPI:ReadField({x=5},"x","number").value,5,
 "trace: field read")
KR.GameAPI:ObserveDiagnostic("GameAPI.ActionBarScanner.findspell",
 "UNKNOWN","visible_spell_rank_mismatch")
local events=KR.GameAPI:DrainDiagnosticTrace()
local observed={}
for _,event in ipairs(events.entries) do
 observed[event.method.."/"..event.status.."/"..event.reason]=event.count
 eq(event.method:find("Creature",1,true),nil,"no raw target")
end
eq(observed["UnitExists/READY/none"],2,"actual method call count")
eq(observed["UnitExists/UNKNOWN/unexpected_type"],1,
 "failure reason retained")
eq(observed["GameAPI.Probe.UnitExists/READY/none"],1,
 "presence probe never merges with real read")
eq(observed["GameAPI.ReadField.x/READY/none"],1,
 "field key metadata recorded without value")
eq(observed["GameAPI.ActionBarScanner.findspell/UNKNOWN/visible_spell_rank_mismatch"],
 1,"button scanner internal checkpoint")
eq(#KR.GameAPI:DrainDiagnosticTrace().entries,0,
 "drain clears events and index")
KR.GameAPI:Read("UnitExists","boolean","target")
eq(#KR.GameAPI:DrainDiagnosticTrace().entries,1,
 "fresh reads remain observable after drain")
eq(KR.GameAPI:EndDiagnosticTrace(),true,"trace explicitly disabled")
KR.GameAPI:Read("UnitExists","boolean","target")
eq(#KR.GameAPI:DrainDiagnosticTrace().entries,0,
 "production does not collect inactive trace")
eq(KR.GameAPI:Read("UnitExists","boolean","target").value,false,"false must survive")
eq(KR.GameAPI:Read("UnitExists","string","target").status,"UNKNOWN","type mismatch")
eq(KR.GameAPI:Read("CastSpellByID","boolean",1).status,"UNAVAILABLE","no cast APIs")
eq(KR.EventBus:Initialize(),true)
eq(KR.GameState:Initialize(),true)
eq(KR.GameState:Initialize(),true,"idempotent subscription")
eq(frameCount,2,"event bus and positive cast evidence frames")
local first=KR.GameState:GetSnapshot()
eq(first.status,"READY")
eq(first.player.class.value[2],"WARRIOR")
eq(first.player.health.percent.value,50)
eq(first.resources.percent.value,25)
eq(first.target.status,"ABSENT")
eq(first.casting.status,"UNKNOWN","idle cannot be assumed")
local again=KR.GameState:GetSnapshot()
eq(first.revision,again.revision,"fresh snapshot is cached")
again.player.health.current.value=900
eq(KR.GameState:GetSnapshot().player.health.current.value,50,"no mutable cache exposure")

hasTarget=true
KR.EventBus:HandleEvent("PLAYER_TARGET_CHANGED")
local second=KR.GameState:GetSnapshot()
eq(second.target.status,"READY")
eq(second.target.guid.value,"Creature-2")
eq(second.revision,first.revision+1,"dirty revision read before flush")
KR.EventBus:Flush()
eq(KR.GameState:GetSnapshot().revision,second.revision+1,"event dispatch invalidates")

currentPlayerHealth=110
KR.EventBus:HandleEvent("UNIT_HEALTH","player")
local invalid=KR.GameState:GetSnapshot()
eq(invalid.player.health.status,"UNKNOWN","health greater than maximum")
eq(invalid.player.health.current.reason,"health_exceeds_max")
eq(KR.EventBus:HandleEvent("UNIT_HEALTH","other"),false,"unrelated units ignored")

secretGuid="SECRET"
KR.EventBus:HandleEvent("UNIT_FLAGS","player")
local protected=KR.GameState:GetSnapshot()
eq(protected.player.guid.status,"UNKNOWN","secret GUID")
eq(protected.player.guid.value,nil,"secret never exposed")

UnitPowerType=function() return nil end
time=time+1
local missingPower=KR.GameState:GetSnapshot()
eq(missingPower.resources.status,"UNKNOWN")
eq(missingPower.resources.current.reason,"power_type_unknown")

UnitExists=function() return nil end
time=time+1
local unknown=KR.GameState:GetSnapshot()
eq(unknown.status,"UNKNOWN","unknown existence")
eq(unknown.target.status,"UNKNOWN","nil is not absence")

-- v14 #12/#13: direct aura lookups prove presence only; nil is UNKNOWN.
local auraReads=0
local auraPlayer={spellId=1978,isHelpful=true}
local auraTarget={spellId=1978,isHarmful=true}
C_UnitAuras={
 GetPlayerAuraBySpellID=function(id)
  auraReads=auraReads+1
  if id==1978 then return auraPlayer end
  return nil
 end,
 GetUnitAuraBySpellID=function(unit,id)
  auraReads=auraReads+1
  if unit=="target" and id==1978 then return auraTarget end
  return nil
 end,
}
local targetPresent={target={exists={status="READY",value=true},
 guid={status="READY",value="Creature-2"}}}
local targetMissing={target={exists={status="READY",value=false}}}
eq(KR.GameState:ReadSignal("player.buff",1978).value,true,"verified player buff")
local playerPresent={player={exists={status="READY",value=true}}}
local playerAbsent={player={exists={status="READY",value=false}}}
local playerUnknown={player={exists={status="UNKNOWN"}}}
eq(KR.GameState:ReadSignal("player.buff",1978,playerPresent).value,true,
 "confirmed snapshot permits player buff")
local readsBeforePlayerGuard=auraReads
eq(KR.GameState:ReadSignal("player.buff",1978,playerAbsent).status,"UNKNOWN",
 "absent player snapshot cannot produce READY aura")
eq(KR.GameState:ReadSignal("player.buff",1978,playerUnknown).status,"UNKNOWN",
 "unknown player existence cannot produce READY aura")
eq(KR.GameState:ReadSignal("player.buff",1978,{}).status,"UNKNOWN",
 "missing player state cannot produce READY aura")
eq(auraReads,readsBeforePlayerGuard,"invalid player snapshot skips aura API")
eq(KR.GameState:ReadSignal("target.debuff",1978,targetPresent).value,true,
 "verified target debuff")
eq(KR.GameState:ReadSignal("player.buff",12345).status,"UNKNOWN",
 "nil aura cannot prove absence")
eq(KR.GameState:ReadSignal("target.debuff",12345,targetPresent).status,"UNKNOWN",
 "nil debuff cannot prove absence")
-- Optional full AuraData enumeration can prove a missing buff/debuff if
-- it reaches the ordinary nil terminator without protected fields.
C_UnitAuras.GetAuraDataByIndex=function(unit,index,filter)
 if index==1 then
  return {spellId=1978,isHarmful=filter=="HARMFUL",
      isHelpful=filter=="HELPFUL"}
 end
 return nil
end
local verifiedAbsent=KR.GameState:ReadSignal("target.debuff",12345,targetPresent)
eq(verifiedAbsent.status,"READY","fully enumerated missing debuff proven")
eq(verifiedAbsent.value,false,"missing debuff explicitly false")
local absentBuff=KR.GameState:ReadSignal("player.buff",12345,playerPresent)
eq(absentBuff.status,"READY","fully enumerated missing buff proven")
eq(absentBuff.value,false,"missing buff explicitly false")
-- Sonah own-cast tracking is bounded and positive-only; an unseen aura
-- remains UNKNOWN when auras are secret. No protected scan is required.
eq(KR.AuraEvidence:Read(13165),nil,"no invented initial aspect")
KR.AuraEvidence:ObserveCast("player",13165)
eq(KR.AuraEvidence:Read(13165).value,true,"confirmed player aspect cast")
eq(KR.AuraEvidence:Read(13163),nil,"other aspect not inferred absent")
KR.AuraEvidence:ObserveCast("player",13163)
eq(KR.AuraEvidence:Read(13165),nil,"switch invalidates old aspect")
eq(KR.AuraEvidence:Read(13163).value,true,"new aspect cast tracked")
KR.AuraEvidence:Reset()
eq(KR.AuraEvidence:Read(13163),nil,"world/death reset removes evidence")
KR.AuraEvidence:ObserveLive(5118)
eq(KR.AuraEvidence:ReadTravel().value,true,"verified travel remembered")
KR.AuraEvidence:ObserveCast("player",14318)
eq(KR.AuraEvidence:ReadTravel(),nil,"combat aspect consumes travel")
eq(KR.AuraEvidence:Read(13165).value,true,"Hawk ranks normalized")
KR.AuraEvidence:Reset()

-- ForeverAuras uses the generic known-ID lookup in hidden-aura mode;
-- it can return a readable self aura even if the specialized lookup misses.
C_UnitAuras.GetUnitAuraBySpellID=function(unit,id)
 if unit=="player" and id==12345 then
  return {spellId=12345,isHelpful=true}
 end
 return nil
end
local genericSelf=KR.GameState:ReadSignal("player.buff",12345,playerPresent)
eq(genericSelf.status,"READY","generic targeted player aura verified")
eq(genericSelf.value,true,"generic player aura presence")
C_UnitAuras.GetUnitAuraBySpellID=nil
-- Sonah address-by-name access is able to establish a clean negative
-- even when the two list APIs cannot enumerate the client's auras.
C_Spell={GetSpellInfo=function(id)
 if id==12345 then return {name="Reference Test Aura"} end
 return nil
end}
C_UnitAuras.GetAuraDataBySpellName=function(unit,name,filter)
 if name=="Reference Test Aura" then return nil end
 return nil
end
C_Secrets={ShouldAurasBeSecret=function() return false end}
local namedAbsent=KR.GameState:ReadSignal("player.buff",12345,playerPresent)
eq(namedAbsent.status,"READY","clean by-name absence proven")
eq(namedAbsent.value,false,"clean by-name negative kept")
C_UnitAuras.GetAuraDataBySpellName=function(unit,name,filter)
 return {spellId=12345,isHelpful=true,isHarmful=false}
end
local namedPresent=KR.GameState:ReadSignal("player.buff",12345,playerPresent)
eq(namedPresent.status,"READY","by-name verified buff exists")
eq(namedPresent.value,true,"by-name verified spell identity")
C_UnitAuras.GetAuraDataBySpellName=nil
C_Spell.GetSpellInfo=nil
-- Sonah/ForeverAuras reference: when the client hides auras, do NOT
-- attempt forbidden batch/index enumeration after a direct-ID miss.
local deniedReads=0
C_Secrets={ShouldAurasBeSecret=function() return true end}
C_UnitAuras.GetUnitAuras=function()
 deniedReads=deniedReads+1
 error("auras cannot be accessed when secret")
end
C_UnitAuras.GetAuraDataByIndex=function()
 deniedReads=deniedReads+1
 error("auras cannot be accessed when secret")
end
local hidden=KR.GameState:ReadSignal("player.buff",12345,playerPresent)
eq(hidden.status,"UNKNOWN","hidden aura absence stays unknown")
eq(hidden.reason,"aura_hidden_by_client","explicit source-backed refusal")
eq(deniedReads,0,"no forbidden aura enumeration under restrictions")
-- Sonah restrictions fallback: when the secrecy predicate is unavailable
-- and combat lockdown is true, still do not call a denied aura scan.
C_Secrets.ShouldAurasBeSecret=nil
local oldLockdown=InCombatLockdown
InCombatLockdown=function() return true end
local unknownMode=KR.GameState:ReadSignal("player.buff",12345,playerPresent)
eq(unknownMode.status,"UNKNOWN","secrecy predicate unavailable in combat")
eq(unknownMode.reason,"aura_secrecy_unverified",
 "unknown secrecy failure is visible")
eq(deniedReads,0,"combat fallback skips forbidden scans")
InCombatLockdown=oldLockdown
C_Secrets.ShouldAurasBeSecret=function() return false end
C_UnitAuras.GetUnitAuras=nil

C_UnitAuras.GetAuraDataByIndex=function()
 return {spellId="SECRET"}
end
eq(KR.GameState:ReadSignal("target.debuff",12345,targetPresent).status,
 "UNKNOWN","protected aura scan stays unknown")
C_UnitAuras.GetAuraDataByIndex=nil
local beforeMissing=auraReads
eq(KR.GameState:ReadSignal("target.debuff",1978,targetMissing).status,"UNKNOWN",
 "absent target cannot assert debuff")
eq(auraReads,beforeMissing,"missing target skips provider")
auraTarget={spellId=1978,isHelpful=true}
eq(KR.GameState:ReadSignal("target.debuff",1978,targetPresent).status,"UNKNOWN",
 "unverified harmful flag")
auraTarget={spellId=1979,isHarmful=true}
eq(KR.GameState:ReadSignal("target.debuff",1978,targetPresent).status,"UNKNOWN",
 "wrong aura spellID")
auraTarget={spellId=1978,isHarmful="SECRET"}
eq(KR.GameState:ReadSignal("target.debuff",1978,targetPresent).status,"UNKNOWN",
 "secret aura property fails closed")
auraTarget={spellId=1978,isHarmful=true}
-- A full protected AuraData record, not just a protected scalar field.
local originalSecretProbe=issecretvalue
local protectedAura={spellId=1978,isHarmful=true}
issecretvalue=function(v)
 return rawequal(v,protectedAura) or originalSecretProbe(v)
end
auraTarget=protectedAura
eq(KR.GameState:ReadSignal("target.debuff",1978,targetPresent).status,"UNKNOWN",
 "protected AuraData table is not readable")
issecretvalue=originalSecretProbe
auraTarget={spellId=1978,isHarmful=true}
-- An API exception must never be interpreted as proof of absence.
local realAuraLookup=C_UnitAuras.GetUnitAuraBySpellID
C_UnitAuras.GetUnitAuraBySpellID=function() error("aura access restricted") end
eq(KR.GameState:ReadSignal("target.debuff",1978,targetPresent).status,"UNKNOWN",
 "aura provider exception remains UNKNOWN")
C_UnitAuras.GetUnitAuraBySpellID=realAuraLookup
-- Identity lost after a successful aura lookup is still UNKNOWN.
local originalUnitGUID=UnitGUID
local guidCalls=0
UnitGUID=function(unit)
 if unit=="target" then
  guidCalls=guidCalls+1
  if guidCalls==2 then return "SECRET" end
 end
 return originalUnitGUID(unit)
end
eq(KR.GameState:ReadSignal("target.debuff",1978,targetPresent).status,"UNKNOWN",
 "protected post-read target GUID fails closed")
UnitGUID=originalUnitGUID
local missingGuid={target={exists={status="READY",value=true}}}
local beforeGuid=auraReads
eq(KR.GameState:ReadSignal("target.debuff",1978,missingGuid).status,"UNKNOWN",
 "target GUID is mandatory")
eq(auraReads,beforeGuid,"missing GUID cannot query aura")
local staleTarget={target={exists={status="READY",value=true},
 guid={status="READY",value="Creature-OLD"}}}
eq(KR.GameState:ReadSignal("target.debuff",1978,staleTarget).status,"UNKNOWN",
 "snapshot GUID mismatch is UNKNOWN")
eq(auraReads,beforeGuid,"stale target prevented before aura read")
local actualGUID=UnitGUID
local guidReadCount=0
UnitGUID=function(unit)
 if unit=="target" then
  guidReadCount=guidReadCount+1
  if guidReadCount>=2 then return "Creature-NEW" end
 end
 return actualGUID(unit)
end
eq(KR.GameState:ReadSignal("target.debuff",1978,targetPresent).status,"UNKNOWN",
 "target changed during aura lookup")
UnitGUID=actualGUID
eq(KR.GameState:ReadSignal("target.debuff",1978,
 {target={exists={status="READY",value=true},
 guid={status="READY",value="SECRET"}}}).status,"UNKNOWN",
 "secret GUID must not be compared or queried")
eq(KR.GameState:ReadSignal("target.debuff","SECRET",targetPresent).status,"UNKNOWN",
 "protected aura ID rejected")
local beforeUnsupported=auraReads
eq(KR.GameState:ReadSignal("target.ttd").status,"UNKNOWN",
 "unimplemented TTD stays unknown")
eq(auraReads,beforeUnsupported,"unsupported signal does not query API")

-- Test a missed PLAYER_TARGET_CHANGED event on a stable clock.
UnitExists=function(unit) return unit=="player" or (unit=="target" and hasTarget) end
hasTarget=false
time=time+1
KR.GameState:GetSnapshot(true)
hasTarget=true
local cachedTarget=KR.GameState:GetSnapshot()
eq(cachedTarget.target.exists.value,false,"normal cache retains old target")
local freshTarget=KR.GameState:GetSnapshot(true)
eq(freshTarget.target.exists.value,true,"forced evaluation detects selected target")
eq(freshTarget.target.attackable.value,true,"forced evaluation reads hostile target")
hasTarget=false
eq(KR.GameState:GetSnapshot(true).target.exists.value,false,
 "forced evaluation detects target removal")

GetTime=nil
eq(KR.GameAPI:Read("GetTime","number").status,"UNAVAILABLE")
local noClock=KR.GameState:GetSnapshot()
eq(noClock.observedAt,nil,"no invented timestamp")
print("PASS Stage 2.3 GameState mock scenarios")
