-- Explicit opt-in and bounded diagnostic recorder mock, no WoW API.
local saved
local clock=1
GetTime=function()clock=clock+0.1;return clock end
local safe=false
-- A nil optional field is not a secret (test sentinel must first exist).
issecretvalue=function(v)return saved~=nil and v==saved end
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
eq(D:Record("EVENT","READY","none"),true,"full buffer rotates into SavedVariables")
eq(D.dropped,0,"no records dropped on successful rotation")
saved="SECRET"
eq(D:Record("EVENT","READY",saved),false,"secret denied")
eq(D.dropped,1,"secret counted")
local report=D:Export()
eq(report:find("SECRET",1,true),nil,"secret never exported")
eq(report:find("protected_value",1,true)~=nil,true,"allowlisted reason")
eq(D:Stop(),true,"stop")
eq(D.active,false,"inactive after stop")
eq(#D.settings.sessions,2,"two automatically persisted segments")
eq(D.settings.sessions[1].records[1].kind,"EVENT","safe rotated copy")
eq(D.settings.sessions[1].final,false,"rotated part marked nonfinal")
eq(D.settings.sessions[2].final,true,"stop saves final part")
eq(D.settings.sessions[1].part,1,"first segment")
eq(D.settings.sessions[2].part,2,"second segment")
eq(D.settings.sessions[1].sessionID,D.settings.sessions[2].sessionID,
 "rotated segments belong to the same recording")
local savedReport=D:Export()
local firstCount=0
for _ in savedReport:gmatch("protected_value") do firstCount=firstCount+1 end
eq(firstCount,1,"post-stop export does not duplicate persisted events")
eq(D.settings.sessions[1].records[2].reason,"protected_value",
 "full first segment retained in SavedVariables")
eq(D:Start(),true,"new manual start")
eq(#D.records,0,"new session has no history")
eq(D:Stop(),true,"second stop")
eq(#D.settings.sessions,2,"retention bounded to two segments")
eq(D:Start(),true,"third start")
eq(D:Stop(),true,"third stop")
eq(#D.settings.sessions,2,"history bounded")
eq(D:Clear(),true,"clear")
eq(#D.settings.sessions,0,"history erased")
eq(D:Start(),true,"start after clear")
eq(D:Clear(),false,"cannot clear while recording")
eq(D:Stop(),true,"final stop")
-- Close-spaced distinct diagnostic events must never be dropped because
-- a cooldown notification was recorded milliseconds earlier.
D.maxRecords=20
GetTime=function() return 200 end
eq(D:Start(),true,"burst session starts")
eq(D:Record("EVENT","READY","spell_update_cooldown",25),true,"first cooldown")
eq(D:Record("EVENT","READY","spell_update_cooldown",25),false,
 "duplicate cooldown is coalesced")
eq(D:Record("TARGET","READY","target_present",1),true,
 "target transition survives cooldown flood")
eq(D:Record("ENGINE","UNKNOWN","action_slot_unconfirmed"),true,
 "engine refusal survives same-frame events")
eq(D:Record("EVENT","READY","unit_spellcast_succeeded",25),true,
 "player cast survives same-frame events")
eq(D:Record("CHECK","UNKNOWN","arcane_rank_4_rule",nil,nil,
 "action_slot_unconfirmed"),true,"rank rule is recorded")
eq(D:Record("BAR","READY","actionbar_buttons",nil,nil,29),true,
 "button coverage is recorded")
eq(D:Record("DISPLAY","BLOCKED","frame_shown"),true,
 "frame visibility is recorded")
eq(D:Record("DISPLAY","BLOCKED","frame_shown",nil,nil,
 "PlayerName-SECRET"),true,"arbitrary detail is discarded")
local structured=D:Export()
eq(structured:find("arcane_rank_4_rule",1,true)~=nil,true,
 "structured rank reason is exported")
eq(structured:find("action_slot_unconfirmed",1,true)~=nil,true,
 "known refusal reason is exported")
eq(structured:find("actionbar_buttons",1,true)~=nil,true,
 "button coverage marker is exported")
eq(structured:find("29",1,true)~=nil,true,
 "button count is exported")
eq(structured:find("PlayerName-SECRET",1,true),nil,
 "arbitrary personal data never exported")
eq(D.dropped,0,"intentional cooldown coalescing is not data loss")
-- Real ability refusal reasons previously went missing from the eighth
-- detail column even when CoreObservation returned them safely.
for _,why in ipairs({
 "cast_unknown","usability_invalid","gcd_activity_unknown",
 "range_unavailable","cooldown_active_unclassified",
 "spell_known_unverified","target_relation_unknown",
 "button_action_info_unconfirmed","button_mapping_changed"
}) do
 eq(D:Record("CHECK","UNKNOWN","arcane_rank_4_rule",nil,nil,why),
  true,"known eligibility detail accepted: "..why)
end
local detailed=D:Export()
for _,why in ipairs({
 "cast_unknown","usability_invalid","gcd_activity_unknown",
 "range_unavailable","cooldown_active_unclassified",
 "spell_known_unverified","target_relation_unknown",
 "button_action_info_unconfirmed","button_mapping_changed"
}) do
 eq(detailed:find("\t"..why,1,true)~=nil,true,
  "real reason is exported in detail: "..why)
end
eq(D:Record("CHECK","UNKNOWN","arcane_rank_4_rule",nil,nil,
 "unexpected_private_player_name"),true,"unknown detail does not break recording")
eq(D.records[#D.records].detail,"diagnostic_detail_unmapped",
 "unknown details are visibly rejected without exporting raw content")
eq(D:Record("CHECK","UNKNOWN","brand_new_internal_reason"),true,
 "unknown fixed code still records")
eq(D.records[#D.records].reason,"diagnostic_code_unmapped",
 "unknown fixed code cannot silently collapse to unknown")
eq(D:Record("CHECK","UNKNOWN","PrivateName!"),true,
 "untrusted reason still records a safe contract failure")
eq(D.records[#D.records].reason,"diagnostic_code_invalid",
 "untrusted reason is not copied into SavedVariables")

eq(D:Record("CHECK","UNKNOWN","arcane_check_cast",nil,nil,"cast_unknown"),
 true,"cast check can be recorded")
eq(D:Record("CHECK","UNKNOWN","arcane_check_range",nil,nil,"range_unavailable"),
 true,"range check can be recorded")
eq(D:Record("CHECK","UNKNOWN","arcane_rank_4_bar_failure",nil,nil,
 "button_action_info_unconfirmed"),true,"scanner subreason can be recorded")
local detailedChecks=D:Export()
eq(detailedChecks:find("arcane_check_cast",1,true)~=nil,true,
 "cast check label survives export")
eq(detailedChecks:find("button_action_info_unconfirmed",1,true)~=nil,true,
 "action info failure stage survives export")
-- Failures found in live game logs must survive the final SavedVariables
-- sanitizer. The old whitelist silently emptied bm_bar_2 details.
for _,why in ipairs({
 "spell_not_confirmed_on_visible_bar",
 "visible_spell_rank_mismatch",
 "aura_batch_fields_unverified",
 "travel_aspect_aura_unverified"
}) do
 eq(D:Record("BAR","UNKNOWN","bm_bar_2",nil,nil,why),true,
  "new refusal recorded "..why)
 eq(D.records[#D.records].detail,why,
  "new refusal preserved "..why)
end
eq(D:Record("API","READY","matrix_probe",1,nil,"presence_only"),
 true,"matrix row recorded")
eq(D.records[#D.records].matrix,1,"matrix index persists")
eq(D:Record("API","UNKNOWN","matrix_probe",23,nil,
 "no_single_safe_probe"),true,"composite row recorded")
eq(D.records[#D.records].detail,"no_single_safe_probe",
 "unavailable matrix evidence retained")
D.apiTraceAllowed={UnitExists=true,
 ["GameAPI.ActionBarScanner.findspell"]=true}
eq(D:Record("METHOD","UNKNOWN","method_call",1,nil,
 "future_api_error","UnitExists",42),true,
 "generic API failure accepted without an explicit reason whitelist")
eq(D.records[#D.records].detail,"future_api_error",
 "future adapter failure kept verbatim after code-pattern validation")
eq(D.records[#D.records].count,42,"method count recorded")
eq(D:Record("METHOD","UNKNOWN","method_call",nil,nil,
 "unexpected_type","GameAPI.ReadField.isActive",11),true,
 "per-field method label automatically accepted")
eq(D.records[#D.records].method,"GameAPI.ReadField.isActive",
 "method metadata retained")
eq(D:Record("METHOD","UNKNOWN","method_call",nil,nil,
 "unknown","Private Player Name",1),true,
 "malformed method rejected")
eq(D.records[#D.records].method,"GameAPI.unsupported",
 "user-input method cannot enter journal")
eq(D:Stop(),true,"burst session stops")
local methodExport=D:Export()
eq(methodExport:find("GameAPI.ReadField.isActive",1,true)~=nil,true,
 "field-specific method exported")
eq(methodExport:find("future_api_error",1,true)~=nil,true,
 "new future method reason exported without a per-code patch")
eq(methodExport:find("Private Player Name",1,true),nil,
 "untrusted method never exported")

print("PASS DevTools recorder mock "..n.." assertions")
