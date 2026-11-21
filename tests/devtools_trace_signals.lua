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
local detailedObserver=D.ObserveDetails
D.ObserveDetails=function() return false end -- isolate legacy transition assertions
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
 return {status="UNKNOWN",reason="spellbook_unavailable",
  firstStatus="UNKNOWN",firstReason="action_slot_unconfirmed"}
end
eq(D:ObserveTransition(),true,"record direct engine refusal")
eq(D.entries[10].kind,"ENGINE","direct engine diagnostic kind")
eq(D.entries[10].reason,"spellbook_unavailable","engine direct refusal preserved")
eq(D:ObserveTransition(),true,"first priority diagnostic recorded")
eq(D.entries[11].kind,"ELIGIBILITY","first priority kind")
eq(D.entries[11].reason,"action_slot_unconfirmed","first priority reason recorded")
-- Detailed observations are now recorded with the session, not shown
-- only in /krdev why. A sampled diagnostic must cover the full path.
D.ObserveDetails=detailedObserver
_G.KordRotationCoreObservation.ActionBar=function()
 return {status="READY",reason="scan_has_spells",confirmedSpellButtons=29,
  arcaneRankOnBar=4,arcaneFindStatus="READY",arcaneFindReason="confirmed"}
end
_G.KordRotationCoreObservation.Display=function()
 return {panelEnabled=true,testMode=false,recommendationAccepted=false,
  visibilityAllowed=false,frameCreated=true,frameShown=false,
  lastEngineStatus="UNKNOWN",lastEngineReason="action_slot_unconfirmed"}
end
_G.KordRotationCoreObservation.Target=function()
 return {liveStatus="READY",liveExists=true,
  snapshotStatus="READY",snapshotExists=true}
end
local beforeDetails=#D.entries
eq(D:ObserveDetails({arcaneR4Status="UNKNOWN",
 arcaneR4Reason="action_slot_unconfirmed"},true),true,"detail sample created")
local matches={}
for i=beforeDetails+1,#D.entries do
 local entry=D.entries[i]
 matches[entry.reason]=entry.status
end
eq(matches.arcane_rank_4_rule,"UNKNOWN","rank four recorded")
eq(matches.priority_1_rule,"UNKNOWN","priority 1 recorded")
eq(matches.profile_ui,"UNAVAILABLE","UI profile status recorded")
eq(matches.eligibility_ready_count,"READY","ready count including zero supported")
eq(matches.eligibility_blocked_count,"READY","blocked count recorded")
eq(matches.eligibility_unknown_count,"READY","unknown count recorded")
eq(matches.actionbar_scan,"READY","scanner recorded")
eq(matches.actionbar_buttons,"READY","confirmed buttons recorded")
eq(matches.arcane_rank_on_bar,"READY","rank on bar recorded")
eq(matches.arcane_findspell,"READY","FindSpell recorded")
eq(matches.target_live,"READY","live target recorded")
eq(matches.target_snapshot,"READY","cached target recorded")
eq(matches.panel_enabled,"READY","panel flag recorded")
eq(matches.test_mode,"BLOCKED","test mode false recorded")
eq(matches.recommendation_accepted,"BLOCKED","UI rejection recorded")
eq(matches.visibility_allowed,"BLOCKED","frame gate recorded")
eq(matches.frame_created,"READY","frame existence recorded")
eq(matches.frame_shown,"BLOCKED","frame visibility recorded")
eq(matches.ui_engine_status,"UNKNOWN","last UI engine recorded")
local detailsCount=#D.entries
eq(D:ObserveDetails({arcaneR4Status="UNKNOWN",
 arcaneR4Reason="action_slot_unconfirmed"},true),true,"repeat sample available")
eq(#D.entries,detailsCount,"unchanged detailed observations not duplicated")
_G.KordRotationCoreObservation=nil
D.active=false
current.engineStatus="BLOCKED"
eq(D:ObserveTransition(),false,"opt-in disabled")
eq(#D.entries,detailsCount,"no late recording")
print("PASS DevTools aggregate trace mock: "..n.." assertions")
