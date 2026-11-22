-- Regression: Hunter BM must never downrank Arcane Shot just because
-- its highest trained rank is temporarily blocked.
-- Run from repo root with Lua 5.1 (e.g. texlua).
local KR={}
local tests=0
local function eq(actual,expected,message)
 tests=tests+1
 assert(actual==expected,(message or "assert")
  ..": expected "..tostring(expected).." got "..tostring(actual))
end
local function ready(value) return {status="READY",value=value} end
local level=30
local targetExists=true
local known={
 [14283]=true,[14282]=true,[14281]=true,[3044]=true
}
local eligible="BLOCKED"
local eligibilityCalls={}
KR.characterState={classToken="HUNTER",index=1}
KR.GameAPI={IsSafeValue=function()return true end}
KR.GameState={GetSnapshot=function()
 return {player={level=ready(level)},target={exists=ready(targetExists)}}
end}
KR.RotationSettings={GetProfile=function()
 return {enabled=true,targetMode="single",allowUnverifiedProfiles=true,
  categories={damage=true},spells={},config={}},"HUNTER_TREE_1"
end}
KR.SpellCatalogue={Read=function()
 return {status="ready",entries={
  {id=14283,known=true,name="Arcane Shot",texture=14283}
 }}
end}
KR.BindingResolver={Resolve=function(_,id)
 return {status="READY",spellID=id,bindingLabel="1",bindingSource="mock"}
end}
KR.AbilityEligibility={
 Fact=function(_,id,kind)
  eq(kind,"known","pilot checks learned ranks only")
  if known[id]==nil then return {status="UNKNOWN",reason="unknown"} end
  return {status="READY",value=known[id]}
 end,
 Evaluate=function(_,id)
  eligibilityCalls[#eligibilityCalls+1]=id
  return {status=eligible,spellID=id,
    reason=eligible=="BLOCKED" and "global_cooldown" or nil}
 end
}
assert(loadfile("KordRotation/Core/RotationProfiles.lua"))("KordRotation",KR)
assert(loadfile("KordRotation/Core/RotationConditions.lua"))("KordRotation",KR)
assert(loadfile("KordRotation/Core/RotationEngine.lua"))("KordRotation",KR)
assert(loadfile("KordRotation/Profiles/Hunter/BM_Pilot_Experimental.lua"))("KordRotation",KR)
-- Pilot is now a 61+ fallback; test its condition logic independently
-- at level 30, where the production selector uses full BM leveling.
local pilot=KR.RotationProfiles:Get("HUNTER_TREE_1",61)
assert(pilot)
KR.RotationProfiles.ResolveForEngine=function()return pilot end
local result=KR.RotationEngine:Evaluate()
eq(result.status,"BLOCKED","cooldown on rank 4 blocks recommendation")
eq(result.reason,"no_eligible_rule","no inappropriate lower-rank fallback")
eq(#eligibilityCalls,1,"only highest trained rank evaluated")
eq(eligibilityCalls[1],14283,"rank 4 passed to eligibility")
eq(result.diagnostics[5].reason,"global_cooldown","rank 4 preserved")
for i=6,8 do
 eq(result.diagnostics[i].reason,"condition_false","lower ranks suppressed")
end
eligible="READY"
eligibilityCalls={}
result=KR.RotationEngine:Evaluate()
eq(result.status,"READY","highest trained rank becomes recommendation")
eq(result.queue[1].spellID,14283,"rank 4 displayed, not rank 3")
eq(#eligibilityCalls,1,"no lower rank eligibility calls")
targetExists=false
eligibilityCalls={}
result=KR.RotationEngine:Evaluate()
eq(result.status,"BLOCKED","absent target blocks recommendation")
eq(#eligibilityCalls,0,"no eligibility calls for absent target")
targetExists=true
level=36
known[14284]=nil
eligible="READY"
eligibilityCalls={}
result=KR.RotationEngine:Evaluate()
eq(result.status,"UNKNOWN","unverified rank 5 cannot silently downrank")
eq(#eligibilityCalls,0,"no unverified fallback cast")
print("PASS Hunter BM highest trained Arcane Shot "..tests.." assertions")
