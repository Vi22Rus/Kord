-- Diagnostic audit covers every profile rule even when the live evaluator
-- would stop on the first UNKNOWN. No spell cast or other gameplay action.
local KR={characterState={classToken="HUNTER",index=1,level=30}}
KR.GameAPI={IsSafeValue=function(_,value)return true end}
local snapshot={player={level={status="READY",value=30}}}
local snapshotReads=0
KR.GameState={GetSnapshot=function()
 snapshotReads=snapshotReads+1
 return snapshot
end}
local observations={}
KR.RotationConditions={
 Create=function()
  return {AuditValue=function(_,field)
    observations[#observations+1]={field=field,status="UNKNOWN",
      reason="signal_provider_unimplemented"}
  end}
 end,
 ObservationCount=function()return #observations end,
 ObservationsSince=function(_,_,start)
  local result={}
  for i=start+1,#observations do result[#result+1]=observations[i] end
  return result
 end,
 Check=function(_,_,id)
  return {status="READY",spellID=id,checks={
   {name="cast",status="READY"},
   {name="gcd",status="READY"},
   {name="range",status="READY"},
  }}
 end
}
KR.RotationSettings={GetProfile=function()return {
 enabled=true,targetMode="single",categories={damage=true},spells={},
 moduleConfigs={HUNTER_BM_LEVELING_PVE={mana="fast"}},
},"HUNTER_TREE_1" end}
KR.RotationProfiles={ResolveForEngine=function(_,key,level)
 assert(key=="HUNTER_TREE_1" and level==30)
 return {id="HUNTER_BM_LEVELING_PVE",Config={
  {key="mana",type="enum",default="balanced",values={"fast","balanced"}},
 },Spells={Mark=1130,Arcane=14283},
 Rules={
  {spell="Mark",type="SPELL",category="damage",target="enemy",
   cast="idle",chargesRequired=false,mode="any",
   when=function(S,cfg)
    assert(cfg.mana=="fast")
    S:AuditValue("target.debuff")
    return nil
   end},
  {spell="Arcane",type="SPELL",category="damage",target="enemy",
   cast="idle",chargesRequired=false,mode="any",
   when=function(S)
    S:AuditValue("target.ttd")
    return true
   end},
 }}
end}
KR.RotationEngine={}
assert(loadfile("KordRotation/Core/RotationAudit.lua"))("KordRotation",KR)
local result=KR.RotationEngine:AuditFull()
assert(result.status=="READY")
assert(result.profileID=="HUNTER_BM_LEVELING_PVE")
assert(#result.rules==2)
assert(result.rules[1].status=="UNKNOWN")
assert(result.rules[1].reason=="condition_unknown")
assert(result.rules[1].signals[1].field=="target.debuff")
assert(result.rules[2].status=="READY")
assert(result.rules[2].checks[3].name=="range")
assert(result.rules[2].signals[1].field=="target.ttd")
assert(snapshotReads==1)
print("PASS full BM audit: all rules visited, checked and traced")
