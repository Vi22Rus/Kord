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
KR.RotationEngine.Evaluate=function()
 reads=reads+1
 return {status="BLOCKED",reason="no_eligible_rule",
  profileID="HUNTER_BM_PILOT_EXPERIMENTAL",diagnostics={
   {status="BLOCKED",reason="condition_false"},
   {status="BLOCKED",reason="condition_false"},
   {status="BLOCKED",reason="condition_false"},
   {status="BLOCKED",reason="condition_false"},
   {status="UNKNOWN",reason="action_slot_unconfirmed",
    barReason="button_action_info_unconfirmed",checks={
     {name="cast",status="UNKNOWN",reason="cast_unknown"},
     {name="usability",status="READY"},
     {name="charges",status="READY"},
     {name="cooldown",status="UNKNOWN",reason="cooldown_unavailable"},
     {name="gcd",status="UNKNOWN",reason="gcd_activity_unknown"},
     {name="range",status="UNKNOWN",reason="range_unavailable"},
    }}}}
end
local hunter=bridge.Diagnose()
eq(hunter.firstReason,"condition_false","first high rank level-gated")
eq(hunter.arcaneR4Status,"UNKNOWN","rank-4 rule inspected separately")
eq(hunter.arcaneR4Reason,"action_slot_unconfirmed",
 "actual rank-4 refusal exposed")
eq(hunter.arcaneR4BarReason,"button_action_info_unconfirmed",
 "scanner stage reason safely bridged")
eq(#hunter.arcaneR4Checks,6,"all six observed check stages bridged")
eq(hunter.arcaneR4Checks[1].reason,"cast_unknown","first stage reason")
eq(hunter.arcaneR4Checks[4].reason,"cooldown_unavailable","cooldown stage reason")
eq(hunter.arcaneR4Checks[6].reason,"range_unavailable","later UNKNOWN retained")
eq(hunter.arcaneR4Checks[1].spellID,nil,"no raw Spell ID bridged")
eq(hunter.decisivePriority,5,"decisive engine priority is exact")
eq(hunter.decisiveStatus,"UNKNOWN","decisive status observed")
eq(hunter.decisiveReason,"action_slot_unconfirmed",
 "decisive reason observed")
eq(reads,2,"engine reevaluates only for explicit diagnosis")
-- Scanner coverage is inspected only on manual DevTools request.
KR.characterState={classToken="HUNTER",index=1}
KR.GameState.current.player={level={status="READY",value=30}}
local scannerReads=0
KR.ActionBarScanner={GetSnapshot=function()
 scannerReads=scannerReads+1
 return {status="READY",entries={
  {spellID=14283,slot=7},
  {spellID=14282,slot=8}
 }}
end,FindSpell=function(_,id)
 eq(id,14283,"revalidation uses observed rank ID")
 return {status="UNKNOWN",reason="spell_not_confirmed_on_visible_bar"}
end}
KR.RotationProfiles={ResolveForEngine=function(_,identity,level)
 eq(identity,"HUNTER_TREE_1","manual scan Hunter profile identity")
 eq(level,30,"manual scan player level")
 return {Spells={ArcaneShotR3=14282,ArcaneShotR4=14283}}
end}
local bars=bridge.ActionBar()
eq(bars.status,"READY","manual scanner returns available")
eq(bars.confirmedSpellButtons,2,"manual scanner confirmed spells")
eq(bars.arcaneRankOnBar,4,"highest observed Arcane rank")
eq(bars.arcaneFindStatus,"UNKNOWN","snapshot matching does not prove live revalidation")
eq(bars.arcaneFindReason,"spell_not_confirmed_on_visible_bar",
 "exact FindSpell failure shown")
eq(bars.spellID,nil,"no raw spell ID in DevTools output")
eq(scannerReads,1,"scanner read only on manual request")
-- Final UI output path is observed without forcing refresh.
local visibilityChecks=0
KR.GameAPI.ReadField=function(_,obj,key)
 local value=obj[key]
 if value==nil then return {status="UNKNOWN"} end
 return {status="READY",value=value}
end
KR.RotationDisplay.frame={IsShown=function() return false end}
KR.RotationDisplay.productionReady=false
KR.RotationDisplay.lastEngineStatus="UNKNOWN"
KR.RotationDisplay.lastEngineReason="action_slot_unconfirmed"
KR.RotationDisplay.ShouldShow=function()
 visibilityChecks=visibilityChecks+1
 return false
end
KR.db={panel={showPanel=true,testMode=false}}
local display=bridge.Display()
eq(display.panelEnabled,true,"user panel is enabled")
eq(display.testMode,false,"normal mode not test preview")
eq(display.status,"READY","display observer accessible")
eq(display.frameCreated,true,"frame is instantiated")
eq(display.frameShown,false,"actual frame hidden")
eq(display.recommendationAccepted,false,"UI rejected non-ready result")
eq(display.visibilityAllowed,false,"display gate denies visibility")
eq(display.lastEngineReason,"action_slot_unconfirmed","last UI engine reason")
eq(visibilityChecks,1,"observation never calls Refresh")
print("PASS 2.8.6 observer mock: "..n.." assertions")
