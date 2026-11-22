-- IT-02/2.6 confidence is about separate evidence layers, never group READY.
local KR={GameAPI={IsSafeValue=function(_,value) return value~="SECRET" end}}
assert(loadfile("KordRotation/Core/SharedCooldownConfidence.lua"))("KordRotation",KR)
local C=KR.SharedCooldownConfidence
local function evidence(active,inactive,unknown,correlation,propagation)
 return {status="UNKNOWN",groupStatus="UNKNOWN",
    candidateCount=active+inactive+unknown,knownActiveCount=active,
    knownInactiveCount=inactive,unknownCount=unknown,
    useCorrelation=correlation,propagationEvidence=propagation,
    alignedCandidateCount=active,divergentActiveCount=0,
    inactiveCandidateCount=inactive}
end
local good=C:Evaluate(evidence(2,0,17,"ESTIMATED","ALIGNED_CANDIDATES"))
assert(good.status=="UNKNOWN" and good.itemCooldownConfidence=="CONFIRMED")
assert(good.groupLockoutConfidence=="ESTIMATED")
assert(good.groupReadyConfidence=="UNKNOWN")
assert(good.reason=="item_cd_group_estimated")
local idle=C:Evaluate(evidence(0,19,0,"UNKNOWN","UNKNOWN"))
assert(idle.itemCooldownConfidence=="CONFIRMED")
assert(idle.groupReadyConfidence=="UNKNOWN" and idle.groupLockoutConfidence=="UNKNOWN")
local absent=C:Evaluate(evidence(0,0,19,"UNKNOWN","UNKNOWN"))
assert(absent.itemCooldownConfidence=="UNKNOWN")
local mixed=C:Evaluate(evidence(2,1,16,"ESTIMATED","MIXED_CANDIDATES"))
assert(mixed.groupLockoutConfidence=="UNKNOWN" and mixed.reason=="item_cd_group_conflict")
local single=C:Evaluate(evidence(1,0,18,"ESTIMATED","SINGLE_CANDIDATE"))
assert(single.groupLockoutConfidence=="UNKNOWN")
local wrong=evidence(2,0,17,"UNKNOWN","ALIGNED_CANDIDATES")
assert(C:Evaluate(wrong).groupLockoutConfidence=="UNKNOWN")
wrong=evidence(2,0,17,"ESTIMATED","ALIGNED_CANDIDATES")
wrong.alignedCandidateCount=1
assert(C:Evaluate(wrong).groupLockoutConfidence=="UNKNOWN")
wrong.alignedCandidateCount=33
assert(C:Evaluate(wrong).groupLockoutConfidence=="UNKNOWN")
wrong=evidence(3,0,16,"ESTIMATED","ALIGNED_CANDIDATES")
wrong.alignedCandidateCount=2 -- third active tuple is not aligned
assert(C:Evaluate(wrong).groupLockoutConfidence=="UNKNOWN")
wrong=evidence(2,0,17,"ESTIMATED","ALIGNED_CANDIDATES")
wrong.divergentActiveCount="SECRET"
assert(C:Evaluate(wrong).groupLockoutConfidence=="UNKNOWN")
wrong=evidence(2,0,17,"ESTIMATED","ALIGNED_CANDIDATES")
wrong.inactiveCandidateCount=1 -- contradicts aggregate inactive count
assert(C:Evaluate(wrong).groupLockoutConfidence=="UNKNOWN")
wrong.alignedCandidateCount=2
wrong.divergentActiveCount=1
assert(C:Evaluate(wrong).groupLockoutConfidence=="UNKNOWN")
wrong=evidence(2,0,17,"ESTIMATED","ALIGNED_CANDIDATES")
wrong.candidateCount=1
assert(C:Evaluate(wrong).itemCooldownConfidence=="UNKNOWN")
wrong=evidence(2,0,17,"ESTIMATED","ALIGNED_CANDIDATES")
wrong.status="READY"
assert(C:Evaluate(wrong).itemCooldownConfidence=="UNKNOWN")
assert(C:Evaluate(setmetatable({},{
 __index=function() error("protected field") end
})).groupReadyConfidence=="UNKNOWN")
assert(C:Evaluate("SECRET").groupReadyConfidence=="UNKNOWN")
print("shared_item_cooldown_confidence_mock PASS")
