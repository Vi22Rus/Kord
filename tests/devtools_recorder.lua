-- Explicit opt-in and bounded diagnostic recorder mock, no WoW API.
local saved
local clock=1
GetTime=function()clock=clock+0.1;return clock end
local safe=false
issecretvalue=function(v)return v==saved end
local D={matrix="v14",version="test",active=false,records={},maxRecords=3,
 maxSessions=2,maxDuration=900,maxExport=32768,settings={}}
function D:Safe(v) return not issecretvalue(v) end
assert(loadfile("KordRotationDevTools/Recorder.lua"))("KordRotationDevTools",D)
local n=0
local function eq(a,b,label)n=n+1;assert(a==b,(label or "").." expected "..tostring(b).." got "..tostring(a))end
eq(D:Record("EVENT","READY","none"),false,"opt in")
eq(D:Start(),true,"start")
eq(D:Record("EVENT","READY","none",83,5),true,"first")
eq(D:Record("ENGINE","UNKNOWN","protected_value",20,9),true,"second")
eq(D:Record("ERROR","ERROR","api_call_failed"),true,"third")
eq(D:Record("EVENT","READY","none"),false,"overflow")
eq(D.dropped,1,"dropped count")
saved="SECRET"
eq(D:Record("EVENT","READY",saved),false,"secret denied")
eq(D.dropped,2,"secret counted")
local report=D:Export()
eq(report:find("SECRET",1,true),nil,"secret never exported")
eq(report:find("protected_value",1,true)~=nil,true,"allowlisted reason")
eq(D:Stop(),true,"stop")
eq(D.active,false,"inactive after stop")
eq(#D.settings.sessions,1,"one persisted session")
eq(D.settings.sessions[1].records[1].kind,"EVENT","safe copy")
eq(D:Start(),true,"new manual start")
eq(#D.records,0,"new session has no history")
eq(D:Stop(),true,"second stop")
eq(#D.settings.sessions,2,"two sessions")
eq(D:Start(),true,"third start")
eq(D:Stop(),true,"third stop")
eq(#D.settings.sessions,2,"history bounded")
eq(D:Clear(),true,"clear")
eq(#D.settings.sessions,0,"history erased")
eq(D:Start(),true,"start after clear")
eq(D:Clear(),false,"cannot clear while recording")
eq(D:Stop(),true,"final stop")
print("PASS DevTools recorder mock "..n.." assertions")
