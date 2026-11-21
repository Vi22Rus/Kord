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
D.active=false
current.engineStatus="BLOCKED"
eq(D:ObserveTransition(),false,"opt-in disabled")
eq(#D.entries,6,"no late recording")
print("PASS DevTools aggregate trace mock: "..n.." assertions")
