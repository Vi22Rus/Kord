-- Separate addon boot/reload mock. No WoW client used.
local login
local frame={}
local registered={}
function frame:RegisterEvent(name)
 assert(name=="PLAYER_LOGIN" or name=="PLAYER_LOGOUT")
 registered[name]=true
end
function frame:SetScript(kind,fn) assert(kind=="OnEvent"); login=fn end
CreateFrame=function() return frame end
local D={CreateUI=function(self)self.created=(self.created or 0)+1 end}
KordRotationDevToolsDB={sessions={{records={},started=0,stopped=0}}}
assert(loadfile("KordRotationDevTools/Core.lua"))("KordRotationDevTools",D)
assert(type(login)=="function")
assert(registered.PLAYER_LOGIN and registered.PLAYER_LOGOUT)
local n=0
local function eq(a,b,label)
 n=n+1
 assert(a==b,(label or "")..": expected "..tostring(b).." got "..tostring(a))
end
D.active=true
D.records={{secret="should not survive"}}
login(nil,"PLAYER_LOGIN")
eq(D.active,false,"reload never auto-records")
eq(#D.records,0,"new in-memory session empty")
eq(#D.settings.sessions,1,"finished sessions retained")
eq(D.created,1,"UI initialized")
D.active=true
local stopped=0
D.Stop=function(self)stopped=stopped+1;self.active=false end
login(nil,"PLAYER_LOGOUT")
eq(stopped,1,"logout saves active recording")
eq(D.active,false,"recording stops on logout")
eq(D:ReadCore().status,"UNAVAILABLE","missing observation bridge")
_G.KordRotationCoreObservation={Read=function()
 return {version=1,status="READY",engineStatus="BLOCKED"}
end}
eq(D:ReadCore().engineStatus,"BLOCKED","read-only bridge")
eq(_G.KordRotationDevTools,D,"separate namespace exported")
print("PASS DevTools boot mock: "..n.." assertions")
