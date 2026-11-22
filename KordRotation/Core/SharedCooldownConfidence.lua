-- Kord Rotation (c) 2026 Vi22Rus. All rights reserved.
-- IT-02/2.6: explicit, fail-closed confidence semantics.
local addonName, KR = ...
KR.SharedCooldownConfidence=KR.SharedCooldownConfidence or {}
local C=KR.SharedCooldownConfidence
local function count(n)
 return type(n)=="number" and n==n and n>=0 and n<=32
     and n==math.floor(n)
end
local function safe(v)
 local api=KR.GameAPI
 if not api or type(api.IsSafeValue)~="function" then return false end
 local ok,yes=pcall(api.IsSafeValue,api,v)
 return ok and yes==true
end
function C:Evaluate(evidence)
 local unknown={status="UNKNOWN",reason="item_cd_group_evidence_unverified",
   itemCooldownConfidence="UNKNOWN",groupLockoutConfidence="UNKNOWN",
   groupReadyConfidence="UNKNOWN"}
 if type(evidence)~="table" or not safe(evidence) then return unknown end
 local ok,x=pcall(function()
   return {status=evidence.status,groupStatus=evidence.groupStatus,
    candidateCount=evidence.candidateCount,knownActiveCount=evidence.knownActiveCount,
    knownInactiveCount=evidence.knownInactiveCount,unknownCount=evidence.unknownCount,
    useCorrelation=evidence.useCorrelation,propagationEvidence=evidence.propagationEvidence,
    alignedCandidateCount=evidence.alignedCandidateCount,
    divergentActiveCount=evidence.divergentActiveCount,
    inactiveCandidateCount=evidence.inactiveCandidateCount}
 end)
 if not ok then return unknown end
 for _,v in pairs(x) do if not safe(v) then return unknown end end
 if x.status~="UNKNOWN" or x.groupStatus~="UNKNOWN" then return unknown end
 local n,a,i,u=x.candidateCount,x.knownActiveCount,
    x.knownInactiveCount,x.unknownCount
 if not count(n) or n<1 or not count(a) or not count(i)
     or not count(u) or a+i+u~=n then return unknown end
 local out={status="UNKNOWN",reason="item_cd_group_rule_unverified",
     itemCooldownConfidence=(a+i)>0 and "CONFIRMED" or "UNKNOWN",
     groupLockoutConfidence="UNKNOWN",groupReadyConfidence="UNKNOWN"}
 -- CONFIRMED is permitted only for individual cooldown records read
 -- from the item-specific provider, never for unverified group semantics.
 if x.useCorrelation=="ESTIMATED"
     and x.propagationEvidence=="ALIGNED_CANDIDATES"
     and count(x.alignedCandidateCount) and x.alignedCandidateCount>=2
     and x.alignedCandidateCount==a
     and count(x.divergentActiveCount) and x.divergentActiveCount==0
     and count(x.inactiveCandidateCount) and x.inactiveCandidateCount==i
     and i==0 then
   out.groupLockoutConfidence="ESTIMATED"
   out.reason="item_cd_group_estimated"
 elseif x.propagationEvidence=="MIXED_CANDIDATES" then
   out.reason="item_cd_group_conflict"
 elseif x.useCorrelation=="ESTIMATED" then
   out.reason="item_cd_group_partial"
 end
 return out
end
