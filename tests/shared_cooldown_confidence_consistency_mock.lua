-- IT-02/2.6: bounded confidence consistency; synthetic Lua 5.1 fixture.
local KR={GameAPI={IsSafeValue=function(_,value) return value~="SECRET" end}}
assert(loadfile("KordRotation/Core/SharedCooldownConfidence.lua"))("KordRotation",KR)
local C=KR.SharedCooldownConfidence
local function evidence()
    return {status="UNKNOWN",groupStatus="UNKNOWN",candidateCount=3,
        knownActiveCount=2,knownInactiveCount=0,unknownCount=1,
        useCorrelation="ESTIMATED",propagationEvidence="ALIGNED_CANDIDATES",
        alignedCandidateCount=2,divergentActiveCount=0,inactiveCandidateCount=0}
end
local valid=C:Evaluate(evidence())
assert(valid.itemCooldownConfidence=="CONFIRMED")
assert(valid.groupLockoutConfidence=="ESTIMATED")
assert(valid.groupReadyConfidence=="UNKNOWN")
local function invalid(edit)
    local x=evidence()
    edit(x)
    local out=C:Evaluate(x)
    assert(out.status=="UNKNOWN")
    assert(out.groupLockoutConfidence=="UNKNOWN")
    assert(out.groupReadyConfidence=="UNKNOWN")
    assert(out.reason=="item_cd_group_evidence_unverified")
end
invalid(function(x) x.alignedCandidateCount=3 end)
invalid(function(x) x.divergentActiveCount=1 end)
invalid(function(x) x.inactiveCandidateCount=1 end)
invalid(function(x) x.propagationEvidence="MIXED_CANDIDATES"; x.alignedCandidateCount=nil end)
invalid(function(x) x.propagationEvidence="UNKNOWN" end)
invalid(function(x) x.alignedCandidateCount="SECRET" end)
invalid(function(x) x.useCorrelation="UNKNOWN" end)
local mixed=evidence()
mixed.propagationEvidence="MIXED_CANDIDATES"
mixed.alignedCandidateCount=1
mixed.divergentActiveCount=1
local conflict=C:Evaluate(mixed)
assert(conflict.reason=="item_cd_group_conflict")
assert(conflict.groupLockoutConfidence=="UNKNOWN")
assert(conflict.groupReadyConfidence=="UNKNOWN")
print("shared_cooldown_confidence_consistency_mock PASS")
