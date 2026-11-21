-- DevTools captures only aggregate state transitions, never Spell ID.
local current={engineStatus="READY",profileStatus="READY",
    eligibilityReady=1,eligibilityBlocked=1,eligibilityUnknown=0,
    eventListenerErrors=0}
local D={active=true,entries={}}
function D:ReadCore() return current end
function D:Safe(v) return v~="SECRET" end
function D:Record(kind,status,reason)
 self.entries[#self.entries+1]={kind=kind,status=status,reason=reason}
 return true
end
assert(loadfile("KordRotationDevTools/Trace.lua"))("KordRotationDevTools",D)
local n=0
local function eq(a,b,label)
 n=n+1
 assert(a==b,(label or "")..": got "..tostring(a).." expected "..tostring(b))
end
eq(D:ObserveTransition(),true,"initial profile")
eq(D.entries[1].kind,"PROFILE","profile category")
eq(D:ObserveTransition(),true,"initial eligibility")
eq(D.entries[2].kind,"ELIGIBILITY","aggregate category")
eq(D.entries[2].status,"READY","ready aggregate")
eq(D:ObserveTransition(),true,"initial engine")
eq(D.entries[3].kind,"ENGINE","engine category")
eq(D:ObserveTransition(),false,"no duplicate")
current.eligibilityUnknown=1
eq(D:ObserveTransition(),true,"eligibility changed")
eq(D.entries[4].status,"UNKNOWN","unknown aggregate")
current.eventListenerErrors=2
eq(D:ObserveTransition(),true,"error delta")
eq(D.entries[5].kind,"ERROR","error category")
current.profileStatus="UNAVAILABLE"
eq(D:ObserveTransition(),true,"profile missing")
eq(D.entries[6].status,"UNAVAILABLE","unavailable profile")
current.eventListenerErrors="SECRET"
eq(D:ObserveTransition(),false,"secret counter cannot be exported")
-- Actual engine reason must survive in the trace, instead of manual_sample.
current.engineReason="action_slot_unconfirmed"
eq(D:ObserveTransition(),true,"new engine reason creates a transition")
eq(D.entries[7].kind,"ENGINE","engine reason transition kind")
eq(D.entries[7].reason,"action_slot_unconfirmed","real refusal reason preserved")
local liveTarget=true
_G.KordRotationCoreObservation={Target=function()
 return {liveStatus="READY",liveExists=liveTarget}
end}
eq(D:ObserveTransition(),true,"new live target observation")
eq(D.entries[8].kind,"TARGET","target recorded separately")
eq(D.entries[8].reason,"target_present","target present readable")
liveTarget=false
eq(D:ObserveTransition(),true,"target removal observed")
eq(D.entries[9].reason,"target_absent","target removal reason")
_G.KordRotationCoreObservation.Diagnose=function()
 return {status="UNKNOWN",reason="action_slot_unconfirmed",
  firstStatus="UNKNOWN",firstReason="action_slot_unconfirmed"}
end
eq(D:ObserveTransition(),true,"record direct engine refusal")
eq(D.entries[10].kind,"ENGINE","direct engine diagnostic kind")
eq(D.entries[10].reason,"action_slot_unconfirmed","engine direct refusal preserved")
eq(D:ObserveTransition(),true,"first priority diagnostic recorded")
eq(D.entries[11].kind,"ELIGIBILITY","first priority kind")
eq(D.entries[11].reason,"action_slot_unconfirmed","first priority reason recorded")
_G.KordRotationCoreObservation=nil
D.active=false
current.engineStatus="BLOCKED"
eq(D:ObserveTransition(),false,"opt-in disabled")
eq(#D.entries,11,"no late recording")
print("PASS DevTools aggregate trace mock: "..n.." assertions")
