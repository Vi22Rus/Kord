-- Run locally; v14 presence-only read bridge only, no WoW game API.
local secret={}
local called={}
local D={}
function D:Safe(v)return v~=secret end
local bridge={Probe=function(_,name) called[#called+1]=name
 return {status=name=="UnitExists" and "READY" or "UNAVAILABLE"}
end}
_G.KordRotationCoreObservation=bridge
assert(loadfile("KordRotationDevTools/V14Registry.lua"))("KordRotationDevTools",D)
assert(loadfile("KordRotationDevTools/Probe.lua"))("KordRotationDevTools",D)
local n=0
local function eq(a,b,m)n=n+1;assert(a==b,(m or "").." got "..tostring(a).." expected "..tostring(b))end
eq(D:ProbeMethod("UnitExists").status,"READY","present")
eq(D:ProbeMethod("UnitExists").matrix,1,"matrix 1")
eq(D:ProbeMethod("RunMacroText").status,"UNAVAILABLE","no protected action")
eq(D:ProbeMethod(secret).status,"UNAVAILABLE","secret name denied")
eq(#called,2,"unknown methods never called")
bridge.Probe=function() return {status=secret} end
eq(D:ProbeMethod("UnitExists").status,"UNKNOWN","secret status not forwarded")
bridge.Probe=function(_,name) called[#called+1]=name
 return {status=name=="UnitExists" and "READY" or "UNAVAILABLE"} end
local result=D:ProbeAll()
eq(result.total,101,"101 matrix rows")
eq(result.present>0,true,"presence recorded")
eq(result.present<101,true,"unverified rows not PASS")
eq(result.evidence,"presence_only_not_client_pass","no client pass")
eq(result.entries[1].matrix,1,"v14 numbering")
D.ReadCore=function() return {engineStatus="BLOCKED",
 engineReason="no_eligible_rule",profileStatus="READY",
 eligibilityReady=0,eligibilityBlocked=1,eligibilityUnknown=0} end
bridge.Target=function() return {liveStatus="READY",liveExists=true,
 snapshotStatus="READY",snapshotExists=false} end
local diagnostic=D:Why()
eq(diagnostic:find("Engine %(last UI evaluation%): BLOCKED / no_eligible_rule")~=nil,
 true,"DevTools reports engine refusal")
eq(diagnostic:find("Target UnitExists %(live%): true")~=nil,true,
 "DevTools reports current live target")
eq(diagnostic:find("Target exists %(cached snapshot%): false")~=nil,true,
 "DevTools reports stale core state without raw GUID")
bridge.Target=function() return {liveStatus="UNKNOWN",liveExists=secret,
 snapshotStatus="UNKNOWN",snapshotExists=secret} end
diagnostic=D:Why()
eq(diagnostic:find("Target UnitExists %(live%): UNKNOWN")~=nil,true,
 "DevTools hides protected live target")
bridge.Diagnose=function()
 return {status="UNKNOWN",reason="action_slot_unconfirmed",
  firstStatus="UNKNOWN",firstReason="action_slot_unconfirmed"}
end
local manual=D:Why()
eq(manual:find("Engine %(manual evaluation%): UNKNOWN / action_slot_unconfirmed")~=nil,
 true,"manual diagnosis includes actual engine refusal")
eq(manual:find("Priority 1 (Arcane rank 8): UNKNOWN / action_slot_unconfirmed",1,true)~=nil,
 true,"manual diagnosis includes first priority reason")
bridge.ActionBar=function()
 return {status="READY",confirmedSpellButtons=9,arcaneRankOnBar=4,
 arcaneFindStatus="UNKNOWN",arcaneFindReason="spell_not_confirmed_on_visible_bar"}
end
local barReport=D:Why()
eq(barReport:find("Confirmed spell buttons: 9",1,true)~=nil,true,
 "DevTools why includes confirmed button count")
eq(barReport:find("Hunter Arcane Shot rank on bar: 4",1,true)~=nil,true,
 "DevTools why includes observed Arcane rank")
eq(barReport:find("Arcane Shot FindSpell: UNKNOWN / spell_not_confirmed_on_visible_bar",1,true)~=nil,true,
 "DevTools reports final action-slot revalidation result")
bridge.Display=function()
 return {status="READY",panelEnabled=true,testMode=false,lastEngineStatus="UNKNOWN",
  lastEngineReason="action_slot_unconfirmed",
  recommendationAccepted=false,visibilityAllowed=false,
  frameCreated=true,frameShown=false}
end
local uiReport=D:Why()
eq(uiReport:find("Display accepts recommendation: false",1,true)~=nil,
 true,"DevTools reports recommendation rejected by final UI")
eq(uiReport:find("Display frame shown: false",1,true)~=nil,
 true,"DevTools reports actual hidden frame")
eq(uiReport:find("Display panel enabled: true",1,true)~=nil,
 true,"DevTools reports actual panel enabled setting")
eq(uiReport:find("Display test mode: false",1,true)~=nil,
 true,"DevTools distinguishes preview mode from live recommendations")
_G.KordRotationCoreObservation=nil
eq(D:ProbeMethod("UnitExists").status,"UNAVAILABLE","missing bridge")
print("PASS DevTools probe mock "..n.." assertions")
