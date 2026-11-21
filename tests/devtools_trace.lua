-- Trace/performance with mock events: client API, frame implementation NOT tested.
local clock=5
GetTime=function()clock=clock+0.2;return clock end
local elapsed=7
debugprofilestop=function()elapsed=elapsed+2;return elapsed end
local D={active=false,records={},maxRecords=100,maxDuration=900,
 settings={},matrix="v14",version="test",maxSessions=2,maxExport=32768,
 Safe=function()return true end,ReadCore=function()return {engineStatus="UNKNOWN"} end}
local lastframe
CreateFrame=function()
 local f={scripts={},events={}}
 function f:RegisterEvent(e)self.events[e]=true end
 function f:UnregisterAllEvents()self.events={} end
 function f:SetScript(k,v)self.scripts[k]=v end
 lastframe=f
 return f
end
assert(loadfile("KordRotationDevTools/Recorder.lua"))("KordRotationDevTools",D)
assert(loadfile("KordRotationDevTools/Trace.lua"))("KordRotationDevTools",D)
assert(loadfile("KordRotationDevTools/Performance.lua"))("KordRotationDevTools",D)
local n=0
local function eq(a,b,m)n=n+1;assert(a==b,(m or "").." expected "..tostring(b).." got "..tostring(a))end
eq(D:Measure().status,"READY","manual measurement available")
eq(#D.records,0,"not recording")
eq(D:Start(),true,"manual start")
eq(type(lastframe.scripts.OnEvent),"function","event handler enabled")
eq(lastframe.events.UPDATE_BINDINGS,true,"event registered")
lastframe.scripts.OnEvent(lastframe,"UPDATE_BINDINGS")
eq(#D.records>0,true,"recorded events")
eq(D.records[1].reason,"update_bindings","named event not manual_sample")
eq(lastframe.events.UNIT_SPELLCAST_SUCCEEDED,true,"player cast event registered")
local beforeOtherUnit=#D.records
lastframe.scripts.OnEvent(lastframe,"UNIT_SPELLCAST_SUCCEEDED","target")
eq(#D.records,beforeOtherUnit,"other unit cast ignored")
lastframe.scripts.OnEvent(lastframe,"UNIT_SPELLCAST_SUCCEEDED","player")
eq(D.records[#D.records].reason,"unit_spellcast_succeeded","player cast named")
D:ObserveTransition()
local count=#D.records
D:ObserveTransition()
eq(#D.records,count,"unchanged state not duplicated")
eq(D:Measure().status,"READY","read-only measurement")
eq(D:Stop(),true,"stop")
eq(lastframe.scripts.OnEvent,nil,"event removed")
eq(lastframe.scripts.OnUpdate,nil,"poll removed")
eq(D.active,false,"off by default after stop")
print("PASS DevTools trace/performance mock "..n.." assertions")
