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
module("Core/GameState.lua")

local function eq(actual,expected,message)
    if actual~=expected then
        error((message or "mismatch")..": expected "..tostring(expected)..
            ", got "..tostring(actual),2)
    end
end

eq(KR.GameAPI:Read("UnitExists","boolean","target").value,false,"false must survive")
eq(KR.GameAPI:Read("UnitExists","string","target").status,"UNKNOWN","type mismatch")
eq(KR.GameAPI:Read("CastSpellByID","boolean",1).status,"UNAVAILABLE","no cast APIs")
eq(KR.EventBus:Initialize(),true)
eq(KR.GameState:Initialize(),true)
eq(KR.GameState:Initialize(),true,"idempotent subscription")
eq(frameCount,1,"one event frame")
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
eq(KR.GameState:ReadSignal("target.debuff",1978,targetPresent).value,true,
 "verified target debuff")
eq(KR.GameState:ReadSignal("player.buff",12345).status,"UNKNOWN",
 "nil aura cannot prove absence")
eq(KR.GameState:ReadSignal("target.debuff",12345,targetPresent).status,"UNKNOWN",
 "nil debuff cannot prove absence")
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

GetTime=nil
eq(KR.GameAPI:Read("GetTime","number").status,"UNAVAILABLE")
local noClock=KR.GameState:GetSnapshot()
eq(noClock.observedAt,nil,"no invented timestamp")
print("PASS Stage 2.3 GameState mock scenarios")
