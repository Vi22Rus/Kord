-- Standalone test for the real read-only CoreObservation module, no WoW runtime.
local KR={}
local reads=0
local protected="PROTECTED"
KR.GameAPI={IsSafeValue=function(_,v)return v~=protected end}
KR.GameState={current={revision=9},GetSnapshot=function()reads=reads+1;error("unexpected read")end}
KR.EventBus={listenerErrors=2}
KR.BindingResolver={dirty=true}
KR.RotationDisplay={lastEngineStatus="UNKNOWN",lastEngineReason="cooldown_unavailable",
 lastSummary={profileStatus="READY",eligibilityReady=1,eligibilityBlocked=2,eligibilityUnknown=0}}
KR.RotationEngine={Evaluate=function()reads=reads+1;error("unexpected evaluation")end}
assert(loadfile("KordRotation/Core/CoreObservation.lua"))("KordRotation",KR)
local n=0
local function eq(a,b,label)
 n=n+1
 assert(a==b,(label or "assert")..": got "..tostring(a)..", expected "..tostring(b))
end
local o=KR.CoreObservation:Read()
eq(o.version,1,"contract revision")
eq(o.status,"READY","read status")
eq(o.engineStatus,"UNKNOWN","engine status")
eq(o.engineReason,"cooldown_unavailable","reason allowlist")
eq(o.stateRevision,9,"snapshot revision")
eq(o.eventListenerErrors,2,"bounded event count")
eq(o.bindingDirty,true,"binding invalidation flag")
eq(o.profileStatus,"READY","profile status no raw ID")
eq(o.eligibilityReady,1,"eligible count")
eq(o.eligibilityBlocked,2,"blocked count")
eq(o.eligibilityUnknown,0,"unknown count")
eq(o.spellID,nil,"no Spell ID")
eq(o.target,nil,"no target")
eq(o.keybind,nil,"no key")
eq(reads,0,"no internal refresh or evaluate")
o.engineStatus="READY"
eq(KR.CoreObservation:Read().engineStatus,"UNKNOWN","fresh copy")
KR.RotationDisplay.lastEngineStatus=protected
KR.RotationDisplay.lastEngineReason=protected
KR.GameState.current.revision=protected
KR.EventBus.listenerErrors=-1
KR.BindingResolver.dirty=protected
o=KR.CoreObservation:Read()
eq(o.engineStatus,"UNKNOWN","secret status hidden")
eq(o.engineReason,nil,"secret reason hidden")
eq(o.stateRevision,nil,"secret revision hidden")
eq(o.eventListenerErrors,0,"invalid counter zero")
eq(o.bindingDirty,false,"secret dirty not true")
KR.RotationDisplay.lastEngineStatus="READY"
KR.RotationDisplay.lastEngineReason="Player Name: Someone"
o=KR.CoreObservation:Read()
eq(o.engineStatus,"READY","public status")
eq(o.engineReason,nil,"unapproved reason format hidden")
eq(reads,0,"no WoW API polling")
KR.GameAPI.Probe=function(_,name)
 return {status=name=="UnitExists" and "READY" or "UNAVAILABLE",reason="presence_only"}
end
local bridge=_G.KordRotationCoreObservation
eq(bridge:Probe("UnitExists").status,"READY","allowlisted presence bridge")
eq(bridge:Probe("PROTECTED").status,"UNAVAILABLE","protected API name denied")
eq(bridge:Probe("SetBinding Action").status,"UNAVAILABLE","invalid API name denied")
-- The optional DevTools bridge can compare live and cached target booleans
-- without returning a GUID or forcing a rotation evaluation.
KR.GameAPI.Read=function(_,name,kind,unit)
 if name=="UnitExists" and kind=="boolean" and unit=="target" then
  return {status="READY",value=true}
 end
 return {status="UNKNOWN"}
end
KR.GameState.current.target={exists={status="READY",value=false}}
local t=bridge.Target()
eq(t.liveExists,true,"explicit live target observation")
eq(t.snapshotExists,false,"stale cached target exposed as boolean only")
eq(t.liveStatus,"READY","live status")
eq(t.snapshotStatus,"READY","cached status")
eq(t.guid,nil,"no target GUID exported")
eq(reads,0,"target observation never invokes engine")
KR.GameState.current.target.exists={status="UNKNOWN",value=protected}
t=bridge.Target()
eq(t.snapshotStatus,"UNKNOWN","protected cached target hidden")
eq(t.snapshotExists,nil,"no protected value exported")
-- Explicit DevTools diagnosis is the only observation that reevaluates
-- the engine; the ordinary read-only snapshot above never does.
KR.RotationEngine.Evaluate=function()
 reads=reads+1
 return {status="UNKNOWN",reason="action_slot_unconfirmed",
  diagnostics={{status="UNKNOWN",reason="action_slot_unconfirmed",
   spellID=14283}}}
end
local diagnosis=bridge.Diagnose()
eq(diagnosis.status,"UNKNOWN","explicit diagnosis status")
eq(diagnosis.reason,"action_slot_unconfirmed","actual engine refusal")
eq(diagnosis.firstReason,"action_slot_unconfirmed","first priority refusal")
eq(diagnosis.spellID,nil,"no raw spell ID in DevTools")
eq(diagnosis.diagnostics,nil,"no raw diagnostics exported")
eq(reads,1,"engine reevaluates only for explicit diagnosis")
print("PASS 2.8.6 observer mock: "..n.." assertions")
