-- IT-02/2.6 + 2.9: manual DevTools inspection of bounded shared evidence.
local KR={GameAPI={IsSafeValue=function(_,v) return v~="SECRET" end}}
local sample={status="UNKNOWN",groupStatus="UNKNOWN",candidateCount=19,
    knownActiveCount=2,knownInactiveCount=0,unknownCount=17,
    itemCooldownConfidence="CONFIRMED",groupLockoutConfidence="ESTIMATED",
    groupReadyConfidence="UNKNOWN",useCorrelation="ESTIMATED",
    propagationEvidence="ALIGNED_CANDIDATES",candidateItemIDs={118,858}}
KR.GameState={ReadSharedItemCooldownMemberEvidence=function() return sample end}
assert(loadfile("KordRotation/Core/CoreObservation.lua"))("KordRotation",KR)
local bridge=_G.KordRotationCoreObservation
local raw=bridge.SharedCooldownDiagnostic()
assert(raw.status=="UNKNOWN" and raw.code=="item_cd_group_estimated")
assert(raw.active==2 and raw.inactive==0 and raw.unknown==17)
assert(raw.candidateItemIDs==nil and raw.groupRemaining==nil)
local D={Safe=function(_,v) return v~="SECRET" end}
assert(loadfile("KordRotationDevTools/Probe.lua"))("KordRotationDevTools",D)
local report=D:SharedCooldownDiagnostic()
assert(report.lockoutConfidence=="ESTIMATED" and report.readyConfidence=="UNKNOWN")
assert(report.candidates==19 and report.candidateItemIDs==nil)
sample.groupLockoutConfidence="CONFIRMED"
assert(bridge.SharedCooldownDiagnostic().code=="item_cd_group_partial")
assert(D:SharedCooldownDiagnostic().lockoutConfidence=="UNKNOWN")
sample.groupLockoutConfidence="UNKNOWN"
sample.propagationEvidence="MIXED_CANDIDATES"
assert(D:SharedCooldownDiagnostic().code=="item_cd_group_conflict")
sample.knownActiveCount="SECRET"
assert(bridge.SharedCooldownDiagnostic().active==nil)
sample.knownActiveCount=2
KR.GameState.ReadSharedItemCooldownMemberEvidence=function() error("protected") end
assert(D:SharedCooldownDiagnostic().status=="UNKNOWN")
_G.KordRotationCoreObservation=nil
print("shared_cooldown_devtools_mock PASS")
