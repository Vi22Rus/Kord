-- Profile Contract v1: real registry, conditions and engine; fake WoW-only inputs.
-- Lua 5.1 compatible; this is not in-game verification.
local KR={}
local n=0
local function eq(a,b,msg)
 n=n+1
 assert(a==b,(msg or "assert").." got "..tostring(a).." expected "..tostring(b))
end
local function r(v) return {status="READY",value=v} end
KR.characterState={classToken="HUNTER",index=1}
local level=20
local reads=0
local auraReads=0
local auraValue=nil
local conditionCalls=0
KR.GameAPI={IsSafeValue=function(_,v) return v~="SECRET" end}
KR.GameState={
 GetSnapshot=function()
  reads=reads+1
  return {player={level=r(level),moving=r(false),exists=r(true)},
   target={exists=r(true)},context={inGroup=r(false)}}
 end,
 ReadSignal=function(_,field,id)
  auraReads=auraReads+1
  if field=="target.debuff" and id==1978 and auraValue~=nil then
   return r(auraValue)
  end
  return {status="UNKNOWN",reason="provider_unavailable"}
 end
}
KR.SpellCatalogue={Read=function()
 return {status="ready",entries={
  {id=101,known=true,name="Sting",texture=101},
  {id=102,known=true,name="Arcane",texture=102}
 }}
end}
KR.BindingResolver={Resolve=function(_,id)
 return {status="READY",spellID=id,bindingLabel="1",bindingSource="mock"}
end}
local enabled=true
local mode="single"
local allowExperimental=false
local config={}
local settings={enabled=true,targetMode="single",
 categories={damage=true,buffs=true},spells={},config={}}
KR.RotationSettings={
 GetProfile=function()
  settings.enabled=enabled
  settings.targetMode=mode
  settings.allowUnverifiedProfiles=allowExperimental
  settings.config=config
  return settings,KR.characterState.classToken.."_TREE_"..KR.characterState.index
 end
}
local results={[101]="READY",[102]="READY"}
local eligibilityCalls=0
local factCalls=0
local factEnabled=false
local rangeFactEnabled=false
KR.AbilityEligibility={
 Evaluate=function(_,id,opts)
  eligibilityCalls=eligibilityCalls+1
  eq(type(opts.stateSnapshot),"table","per-evaluation snapshot")
  return {spellID=id,status=results[id] or "UNKNOWN",
   reason=results[id]=="UNKNOWN" and "cooldown_unverified" or nil}
 end,
 Fact=function(_,id,kind)
  factCalls=factCalls+1
  if factEnabled and id==102 and kind=="cooldownActive" then
   return r(false)
  end
  if rangeFactEnabled and id==102 and kind=="inRange" then
   return r(false)
  end
  return {status="UNKNOWN"}
 end
}
assert(loadfile("KordRotation/Core/RotationProfiles.lua"))("KordRotation",KR)
assert(loadfile("KordRotation/Core/RotationConditions.lua"))("KordRotation",KR)
assert(loadfile("KordRotation/Core/RotationEngine.lua"))("KordRotation",KR)
local P,C,E=KR.RotationProfiles,KR.RotationConditions,KR.RotationEngine
local function rule(id,spell,when,extra)
 local row={id=id,type="SPELL",spell=spell,
  category=spell=="Sting" and "buffs" or "damage",
  target="enemy",cast="idle",chargesRequired=false,
  reason=id,when=when}
 for k,v in pairs(extra or {}) do row[k]=v end
 return row
end
local function profile(spec,id,lo,hi,status)
 return {contractVersion=1,id=id,version="1.0",
  classToken="HUNTER",specIndex=spec,levelMin=lo,levelMax=hi,
  status=status or "verified",
  Spells={Sting=101,Arcane=102},
  Needs={auras={1978},ranges={102},enemyCount=false,ttd=false,swing=false},
  Config={{key="threshold",type="number",default=10,min=1,max=30,
   group="damage",label="Threshold",desc="Mock threshold"},
   {key="useSting",type="bool",default=true,
    group="buffs",label="Use Sting",desc="Mock boolean toggle"},
   {key="alternate",type="enum",default=true,values={true,false},
    group="damage",label="Alternate",desc="Mock enum false"}},
  Rules={rule("Arcane","Arcane",function() return true end)}
 }
end
local nilAura=function(S,cfg)
 conditionCalls=conditionCalls+1
 if cfg and cfg.useSting==false then return false end
 return S:isNot("target.debuff",1978)
end
local p=profile(1,"HUNTER_BM_LEVELING_PVE",1,59)
p.Rules={
 rule("OptionalSting","Sting",function(S,cfg)
  if cfg.alternate==false then return false end
  return nilAura(S,cfg)
 end,{onUnknown="skip"}),
 rule("Arcane","Arcane",function()return true end)
}
local bad=profile(1,"BAD",1,59)
bad.contractVersion=2
eq(P:Register("HUNTER",1,bad),false,"contract version rejected")
bad=profile(1,"BAD",1,59)
bad.Needs.auras={[1]=1978,[3]=1979}
eq(P:Register("HUNTER",1,bad),false,"sparse Needs list rejected independently of #")
bad=profile(1,"BAD",1,59)
bad.Needs.ranges={[2]=102}
eq(P:Register("HUNTER",1,bad),false,"leading hole in Needs ranges rejected")
bad=profile(1,"BAD",1,59)
bad.Config={[1]=bad.Config[1],[3]=bad.Config[2]}
eq(P:Register("HUNTER",1,bad),false,"sparse Config rejected independently of #")
bad=profile(1,"BAD",1,59)
bad.Rules={[2]=bad.Rules[1]}
eq(P:Register("HUNTER",1,bad),false,"sparse Rules rejected independently of #")
bad=profile(1,"BAD",1,59)
bad.Needs.auras={[999999]=1978}
eq(P:Register("HUNTER",1,bad),false,"out-of-bounds array index rejected without #")
bad=profile(1,"BAD",1,59)
bad.Needs.unknownProvider=true
eq(P:Register("HUNTER",1,bad),false,"unknown needs rejected")
bad=profile(1,"BAD",1,59)
bad.Rules[1].spell="Missing"
eq(P:Register("HUNTER",1,bad),false,"undeclared spell rejected")
bad=profile(1,"BAD",1,59)
bad.Config[1].default=math.huge
eq(P:Register("HUNTER",1,bad),false,"nonfinite CFG default rejected")
bad=profile(1,"BAD",1,59)
bad.Config[1].min=-math.huge
eq(P:Register("HUNTER",1,bad),false,"nonfinite CFG bound rejected")
bad=profile(1,"BAD",1,59)
bad.Spells.Sting="SECRET"
eq(P:Register("HUNTER",1,bad),false,"protected SpellID rejected")
eq(P:Register("HUNTER",1,p),false,"unapproved skip rejected")
p.SkipExceptions={OptionalSting={reason="optional debuff",testID="PC-002",safeOptional=true}}
eq(P:Register("HUNTER",1,p),true,"register approved skip")
eq(P:Has("HUNTER_TREE_1"),true,"spec registered")
eq(P:Get("HUNTER_TREE_1",20).id,p.id,"level profile selected")
local copy=P:Get("HUNTER_TREE_1",20)
copy.Spells.Sting=999
eq(P:Get("HUNTER_TREE_1",20).Spells.Sting,101,"copy immutable")
local internal=P:ResolveForEngine("HUNTER_TREE_1",20)
eq(internal.Spells.Sting,101,"engine references validated profile")
eq(P:ResolveForEngine("HUNTER_TREE_1",20),internal,
 "no deep copy on each engine evaluation")
eq(P:Get("HUNTER_TREE_1",20)==internal,false,
 "external Get never leaks internal table")
local overlapping=profile(1,"HUNTER_DUPLICATE",59,60)
eq(P:Register("HUNTER",1,overlapping),false,"level overlap forbidden")
local at60=profile(1,"HUNTER_BM_60_PVE",60,60,"mock_tested")
eq(P:Register("HUNTER",1,at60),true,"second level range")
eq(P:Has("HUNTER_TREE_1"),true,"multi range Has works")
eq(P:Get("HUNTER_TREE_1",60).id,at60.id,"level60 profile selected")
eq(P:Get("HUNTER_TREE_1",61),nil,"out of range no silent fallback")
-- Profile lookup must not compare or use protected keys/levels.
local originalSafeProfile=KR.GameAPI.IsSafeValue
KR.GameAPI.IsSafeValue=function(self,value)
 if value==22 then return false end
 return originalSafeProfile(self,value)
end
eq(P:Get("HUNTER_TREE_1",22),nil,"protected level cannot resolve a profile")
eq(P:Has("HUNTER_TREE_1",22),false,"protected level is not a registered match")
eq(P:Get("SECRET",20),nil,"protected key cannot index registry")
eq(P:Has("SECRET"),false,"protected key cannot be queried")
KR.GameAPI.IsSafeValue=originalSafeProfile
local exp=profile(2,"HUNTER_MM_60_PVE",60,60,"experimental")
eq(P:Register("HUNTER",2,exp),true,"experimental profile registered")
KR.characterState.index=2
level=60
eq(E:Evaluate().reason,"profile_unverified","experimental opt-in defaults false")
allowExperimental=true
local experimentalResult=E:Evaluate()
eq(experimentalResult.status,"READY","explicit experimental opt-in evaluated")
eq(experimentalResult.queue[1].source,"experimental_profile",
 "experimental source retained for UI gate")
allowExperimental=false
KR.characterState.index=1
level=20
local state=E:Evaluate()
eq(state.status,"READY","skip unknown optional")
eq(state.queue[1].spellID,102,"second candidate chosen")
eq(state.diagnostics[1].reason,"condition_unknown_skipped","skip diagnosed")
eq(conditionCalls,1,"condition evaluated once")
eq(auraReads,1,"one missing provider read")
auraValue=false
state=E:Evaluate()
eq(state.queue[1].spellID,101,"first priority selected when aura absent")
config.useSting=false
state=E:Evaluate()
eq(state.queue[1].spellID,102,"boolean false override disables first rule")
config.useSting=true
config.alternate=false
state=E:Evaluate()
eq(state.queue[1].spellID,102,"false enum value prevents first rule")
config.alternate=true
auraValue=true
state=E:Evaluate()
eq(state.queue[1].spellID,102,"present debuff blocks refresh")
auraValue=false
results[101]="UNKNOWN"
state=E:Evaluate()
eq(state.status,"UNKNOWN","Eligibility unknown always stops")
eq(#state.queue,0,"no queue after unknown")
results[101]="BLOCKED"
state=E:Evaluate()
eq(state.queue[1].spellID,102,"Eligibility BLOCKED continues")
results[101]="READY"
enabled=false
eq(E:Evaluate().reason,"rotation_disabled","disabled blocks")
enabled=true
mode="auto"
eq(E:Evaluate().reason,"auto_target_count_unverified","auto never guessed")
mode="single"
level=60
eq(E:Evaluate().reason,"profile_unverified","mock_tested not active")
level=20
local stop=profile(2,"HUNTER_MM_LEVELING_PVE",1,59)
stop.Rules={rule("UnknownSting","Sting",nilAura),
 rule("Arcane","Arcane",function()return true end)}
eq(P:Register("HUNTER",2,stop),true,"stop profile registered")
KR.characterState.index=2
auraValue=nil
state=E:Evaluate()
eq(state.status,"UNKNOWN","default unknown stops")
eq(state.reason,"condition_unknown","unknown reason preserved")
eq(#state.queue,0,"no leak from lower priority")
local broken=profile(3,"HUNTER_SV_LEVELING_PVE",1,59)
broken.Rules={
 {id="Pet",type="PET_COMMAND",action="PET_ATTACK",
  category="buffs",target="none",cast="allow",chargesRequired=false,
  reason="unsupported",when=function()error("pet should not be evaluated")end},
 rule("BadOptional","Sting",function()error("condition crash")end,
  {onUnknown="skip"}),
 rule("Arcane","Arcane",function()return true end)
}
broken.SkipExceptions={BadOptional={reason="optional",testID="PC-003",safeOptional=true}}
eq(P:Register("HUNTER",3,broken),true,"test invalid condition path")
KR.characterState.index=3
state=E:Evaluate()
eq(state.status,"UNKNOWN","condition error never skipped")
eq(state.reason,"condition_error","condition exception masked")
eq(state.diagnostics[1].reason,"unsupported_action","pet command disabled cleanly")
eq(#state.queue,0,"no false pet icon")
KR.characterState.index=1
-- A restricted S exposes only functions and is allocation-local.
local direct=P:Get("HUNTER_TREE_1",20)
local S=C:Create(direct,KR.GameState:GetSnapshot())
eq(S.player,nil,"raw snapshot inaccessible")
eq(type(S.all),"function","restricted methods exist")
eq(pcall(function()S.player={} end),false,"direct injection denied")
local touched=0
eq(S:all(function()return false end,function() touched=touched+1;return true end),
 false,"all short-circuits")
eq(touched,0,"all second condition never read")
eq(S:any(function()return nil end,function()return false end),nil,
 "any preserves UNKNOWN")
eq(S:any(function()return nil end,function()return true end),true,
 "any later true resolves")
eq(S:any(function()return false end,function()return false end),false,
 "any known false result")
eq(pcall(function()S:any(function()return "bad" end)end),false,
 "any invalid child fails closed")
local beforeUndeclared=auraReads
eq(S:is("target.debuff",123456),nil,"undeclared aura fails closed")
eq(auraReads,beforeUndeclared,"undeclared aura does not call provider")
eq(S:all(function()return nil end,function()error("eager")end),nil,
 "all first unknown stops")
eq(pcall(function()S:all(function()return "not tri-state" end)end),
 false,"invalid nested condition throws")
eq(S:ge("player.level",10),true,"typed scalar level")
eq(S:isNot("target.debuff",1978),nil,"uncertain aura remains nil")
local before=eligibilityCalls
eq(S:spellAvailable(102),"READY","eligible result")
eq(S:spellAvailable(102),"READY","cached eligible result")
eq(C:Check(S,102,{target="enemy",cast="idle",chargesRequired=false}).status,
 "READY","shared cache with engine")
eq(eligibilityCalls,before+1,"one Eligibility call per exact policy")
eq(S:spellAvailable(987654),"UNKNOWN","spell outside registry never checked")
eq(S:spellFact(102,"cooldownActive"),nil,"unproven fact UNKNOWN")
-- Even a faulty/future Fact provider reporting READY must not approve an
-- undefined chargesAtLeast threshold in Profile Contract v1.
local beforeCharges=factCalls
local originalFact=KR.AbilityEligibility.Fact
KR.AbilityEligibility.Fact=function(_,id,kind)
 factCalls=factCalls+1
 if kind=="chargesAtLeast" then return r(true) end
 return {status="UNKNOWN"}
end
eq(S:spellFact(102,"chargesAtLeast"),nil,"undefined charge threshold stays UNKNOWN")
eq(factCalls,beforeCharges,"undefined charge threshold never calls provider")
KR.AbilityEligibility.Fact=originalFact
local beforeRangeFact=factCalls
eq(S:spellFact(101,"inRange"),nil,"undeclared range fact is UNKNOWN")
eq(factCalls,beforeRangeFact,"undeclared range does not reach Fact provider")
eq(S:spellFact(102,"inRange"),nil,"declared but unavailable range UNKNOWN")
eq(factCalls,beforeRangeFact+1,"declared range reaches Fact provider once")
factEnabled=true
local S2=C:Create(direct,KR.GameState:GetSnapshot())
local prevFact=factCalls
eq(S2:spellFact(102,"cooldownActive"),false,"confirmed false fact")
eq(S2:spellFact(102,"cooldownActive"),false,"fact cached")
eq(factCalls,prevFact+1,"one fact provider read")
-- A confirmed false range fact is cached, not confused with unknown.
rangeFactEnabled=true
local S3=C:Create(direct,KR.GameState:GetSnapshot())
local beforeRange=factCalls
eq(S3:spellFact(101,"inRange"),nil,"undeclared range denied even with active provider")
eq(factCalls,beforeRange,"undeclared range must not invoke provider")
eq(S3:spellFact(102,"inRange"),false,"verified false range preserved")
eq(S3:spellFact(102,"inRange"),false,"false range cached in one evaluation")
eq(factCalls,beforeRange+1,"range false read exactly once per evaluation")
local S4=C:Create(direct,KR.GameState:GetSnapshot())
eq(S4:spellFact(102,"inRange"),false,"fresh evaluation reads confirmed range")
eq(factCalls,beforeRange+2,"range fact cache does not leak across evaluations")
print("PASS profile contract v1 mock: "..n.." assertions")
