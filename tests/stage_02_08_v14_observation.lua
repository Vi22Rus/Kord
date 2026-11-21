-- Standalone test for the real read-only CoreObservation module, no WoW runtime.
local KR={}
local reads=0
local protected="PROTECTED"
KR.GameAPI={IsSafeValue=function(_,v)return v~=protected end}
KR.GameState={current={revision=9},GetSnapshot=function()reads=reads+1;error("unexpected read")end}
KR.EventBus={listenerErrors=2}
KR.BindingResolver={dirty=true}
KR.RotationDisplay={lastEngineStatus="UNKNOWN",lastEngineReason="cooldown_unavailable"}
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
print("PASS 2.8.6 observer mock: "..n.." assertions")
