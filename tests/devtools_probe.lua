-- Run locally; v14 presence-only read bridge only, no WoW game API.
local secret={}
local called={}
local D={}
function D:Safe(v)return v~=secret end
local bridge={Probe=function(_,name) called[#called+1]=name
 return {status=name=="UnitExists" and "READY" or "UNAVAILABLE"}
end}
_G.KordRotationCoreObservation=bridge
assert(loadfile("KordRotationDevTools/Probe.lua"))("KordRotationDevTools",D)
local n=0
local function eq(a,b,m)n=n+1;assert(a==b,(m or "").." got "..tostring(a).." expected "..tostring(b))end
eq(D:ProbeMethod("UnitExists").status,"READY","present")
eq(D:ProbeMethod("UnitExists").matrix,1,"matrix 1")
eq(D:ProbeMethod("RunMacroText").status,"UNAVAILABLE","no protected action")
eq(D:ProbeMethod(secret).status,"UNAVAILABLE","secret name denied")
eq(#called,2,"unknown methods never called")
local result=D:ProbeAll()
eq(result.total,22,"exact catalog count")
eq(result.present,1,"presence is not success")
eq(result.evidence,"presence_only_not_client_pass","no client pass")
eq(result.entries[1].matrix,1,"v14 numbering")
_G.KordRotationCoreObservation=nil
eq(D:ProbeMethod("UnitExists").status,"UNAVAILABLE","missing bridge")
print("PASS DevTools probe mock "..n.." assertions")
