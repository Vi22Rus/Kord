-- Kord Rotation DevTools (c) 2026 Vi22Rus; see root LICENSE.
-- Explicit opt-in, bounded memory, no unknown input serialization.
local _,D=...
local kinds={EVENT=true,ENGINE=true,ELIGIBILITY=true,PROFILE=true,TARGET=true,ERROR=true,API=true,PERFORMANCE=true,CHECK=true,BAR=true,DISPLAY=true,RULE=true,SIGNAL=true,STAGE=true,METHOD=true}
local statuses={READY=true,BLOCKED=true,UNKNOWN=true,UNAVAILABLE=true,ERROR=true}
local reasons={none=true,unknown=true,unavailable=true,protected_value=true,
    cooldown_unavailable=true,spellbook_unavailable=true,api_missing=true,
    engine_unavailable=true,profile_not_registered=true,rotation_disabled=true,
    already_casting=true,global_cooldown=true,not_learned=true,
    invalid_method=true,api_call_failed=true,presence_only=true,
    target_missing=true,no_eligible_rule=true,invalid_status=true,
    snapshot_unavailable=true,manual_sample=true,game_state_unavailable=true,
    aura_hidden_by_client=true,
    action_slot_unconfirmed=true,spell_visual_data_unverified=true,
    matrix_probe=true,no_single_safe_probe=true,unlisted_method=true,
    method_call=true,method_total=true,method_trace_overflow=true,
    method_trace_unavailable=true,
    diagnostic_code_unmapped=true,diagnostic_code_invalid=true,
    diagnostic_detail_unmapped=true,
    core_bridge_missing=true,probe_failed=true,
    condition_unknown=true,condition_false=true,no_confirmed_visible_slots=true,
    profile_unverified=true,rotation_settings_unavailable=true,
    player_level_unverified=true,spellbook_unavailable=true,
    target_present=true,target_absent=true,target_unverified=true,
    player_target_changed=true,update_bindings=true,spell_update_cooldown=true,
    actionbar_slot_changed=true,spells_changed=true,player_regen_enabled=true,
    player_regen_disabled=true,player_entering_world=true,
    unit_spellcast_succeeded=true,unit_spellcast_start=true,
    unit_spellcast_failed=true,unit_spellcast_interrupted=true,
    target_observed=true,engine_exception=true,engine_dependency_missing=true,
    condition_error=true,higher_priority_unknown=true,category_disabled=true,
    no_eligible_rule=true,action_slot_unconfirmed=true,
    arcane_rank_4_rule=true,actionbar_scan=true,actionbar_buttons=true,
    arcane_rank_on_bar=true,arcane_findspell=true,
    panel_enabled=true,test_mode=true,recommendation_accepted=true,
    visibility_allowed=true,frame_created=true,frame_shown=true,
    target_live=true,target_snapshot=true,ui_engine_status=true,
    priority_1_rule=true,eligibility_ready_count=true,
    eligibility_blocked_count=true,eligibility_unknown_count=true,
    profile_ui=true,engine_decisive_priority=true,
    engine_decisive_reason=true}
-- Fixed engine/eligibility refusal vocabulary. These tokens are emitted
-- by our own modules; do not accept arbitrary user/player/API strings.
-- Keeping this list aligned with AbilityEligibility and RotationEngine
-- prevents a real UNKNOWN cause from being silently exported as "unknown".
local fixedRefusals={
    spell_known_unverified=true,cooldown_activity_unknown=true,
    cooldown_active_unclassified=true,cooldown_invalid=true,
    cooldown_disabled=true,cooldown_clock_unknown=true,
    individual_cooldown=true,gcd_unavailable=true,
    gcd_activity_unknown=true,gcd_invalid=true,gcd_clock_unknown=true,
    charges_api_missing=true,charges_unavailable=true,charges_invalid=true,
    no_charges=true,usability_unavailable=true,usability_invalid=true,
    insufficient_resources=true,spell_unusable=true,
    target_policy_required=true,target_unknown=true,
    target_life_unknown=true,target_dead=true,
    target_relation_unknown=true,target_relation_invalid=true,
    out_of_range=true,range_unavailable=true,cast_policy_required=true,
    cast_api_unavailable=true,cast_unknown=true,invalid_spell_id=true,
    options_protected=true,policy_protected=true,
    charge_policy_required=true,level_policy_invalid=true,
    scanner_unavailable=true,player_unknown=true,player_missing=true,
    player_life_unknown=true,player_dead=true,player_level_unknown=true,
    player_level_too_low=true,fact_kind_unverified=true,
    fact_options_unverified=true,fact_value_unverified=true,
    cooldown_fact_unavailable=true,range_target_unverified=true,
    range_target_changed=true,range_fact_unavailable=true,
    fact_provider_unimplemented=true,
    specialization_unknown=true,target_mode_invalid=true,
    auto_target_count_unverified=true,game_state_missing=true,
    profile_for_level_missing=true,condition_context_missing=true,
    unsupported_action=true,mode_not_selected=true,rule_disabled=true,
    condition_invalid=true,eligibility_status_invalid=true,
    condition_unknown_skipped=true,
}
for code in pairs(fixedRefusals) do reasons[code]=true end
local scannerFailures={
    button_not_visible=true,button_slot_unconfirmed=true,
    button_action_unconfirmed=true,button_action_info_unconfirmed=true,
    button_action_not_spell=true,button_spell_id_unconfirmed=true,
    button_mapping_changed=true,button_revalidation_unknown=true,
    spell_not_confirmed_on_visible_bar=true,
    visible_spell_rank_mismatch=true,
}
for code in pairs(scannerFailures) do reasons[code]=true end
local eligibilityStages={"cast","usability","charges","cooldown","gcd","range"}
reasons.arcane_rank_4_bar_failure=true
reasons.not_evaluated=true
for _,name in ipairs(eligibilityStages) do
    reasons["arcane_check_"..name]=true
end
-- All spell/rule names remain private. Encode only the validated
-- rule number, fixed field name and check stage; never serialize SpellIDs.
local bmSignalNames={
 "player.level","player.moving","player.combat",
 "player.health.percent","player.mounted","player.hasAggro",
 "player.travelAspect","target.exists","target.dead",
 "target.attackable","target.isPlayer","target.threat",
 "target.classification","target.melee","target.targetsPlayer",
 "target.approaching","target.slowed","target.wingClip",
 "target.willSurviveBurst","target.dyingSoon","target.stingRemaining",
 "target.ttd","target.debuff","player.buff","pet.exists",
 "pet.dead","pet.health.percent","pet.attackingTarget",
 "pet.mendActive","context.inGroup","context.inRaid",
 "context.inInstance","context.instanceType",
 "resources.percent","trap.profitable","need.distance",
 "mongoose.usable","autoShot.active","autoShot.swing",
 "pull.remaining",
 "intimidation.profitable","aoe.safe","volley.profitable",
 "multi.profitable","enemy.count","hawk.count",
 "hawk.oldestRemaining","aimed.profitable","sting.profitable",
 "spell.range","fact.known","fact.inRange","fact.cooldownActive"
}
local bmCheckStages={"cast","usability","charges","cooldown","gcd","range"}
for i=1,64 do
 reasons["bm_rule_"..i]=true
 reasons["bm_bar_"..i]=true
 for _,name in ipairs(bmSignalNames) do
  local fixed=name:lower():gsub("[^a-z0-9]","_")
  reasons["bm_signal_"..i.."_"..fixed]=true
 end
 for _,name in ipairs(bmCheckStages) do
  reasons["bm_stage_"..i.."_"..name]=true
 end
end
reasons.bm_profile_bm_leveling=true
reasons.bm_profile_bm_pilot=true
reasons.bm_profile_bm_60=true
reasons.bm_profile_unavailable=true
for _,why in ipairs({
 "signal_provider_unimplemented","signal_api_unavailable",
 "signal_field_unverified","signal_provider_error",
 "signal_unverified","direct_field_unverified",
 "aura_player_unverified","aura_target_unverified",
 "aura_target_changed","aura_spell_id_unverified",
 "aura_scan_unavailable","aura_scan_unverified",
 "aura_scan_limit","aura_lookup_unverified",
 "aura_identity_unverified","melee_range_unverified",
 "auto_shot_state_unknown","target_target_unverified",
 "spell_not_declared","eligibility_policy_unverified",
 "eligibility_missing","eligibility_unverified",
 "context_unavailable",
}) do reasons[why]=true end
-- Only bounded scalar diagnostics can be exported. No user strings,
-- frame objects, spell IDs, slot IDs or names are accepted.
local detailWords={confirmed=true,spell_not_confirmed_on_visible_bar=true,
  unsupported_contract=true,protected_or_invalid_table=true,
  unsupported_key=true,field_access_failed=true,unexpected_type=true,
  no_value=true,invalid_number=true,percentage_out_of_range=true,
  curve_or_unit_unverified=true,curve_or_power_unverified=true,
  presence_only_not_game_verified=true,reason_unavailable=true,
 rank_not_confirmed=true,find_spell_exception=true,scan_has_spells=true,
 no_confirmed_visible_slots=true,scan_unavailable=true,
 scanner_unavailable=true,unknown=true,none=true}
local function safeDetail(v)
    if v==nil then return nil end
    if not D:Safe(v) then return "diagnostic_detail_unmapped" end
    if type(v)=="number" and v==v and v==math.floor(v)
        and v>=0 and v<=1200 then return v end
    if type(v)=="string" and #v<=64 and (detailWords[v] or reasons[v]) then return v end
    -- An unlisted detail must be visible as a contract gap; never export
    -- raw user/game data. The original rejected value is not retained.
    return "diagnostic_detail_unmapped"
end
local function now()
    if type(GetTime)~="function" then return nil end
    local ok,t=pcall(GetTime)
    if not ok or not D:Safe(t) or type(t)~="number"
        or t~=t or t==math.huge or t<0 then return nil end
    return t
end
local function enum(value,allowed,unknown)
    if not D:Safe(value) or type(value)~="string" or not allowed[value] then
        return unknown
    end
    return value
end
local function int(v,min,max)
    if not D:Safe(v) or type(v)~="number" or v~=v
        or v~=math.floor(v) or v<min or v>max then return nil end
    return v
end
local function sanitizeReason(v)
    if not D:Safe(v) or type(v)~="string" or #v<1 or #v>64
        or not string.match(v,"^[a-z][a-z0-9_]*$") then
        return "diagnostic_code_invalid"
    end
    -- Do not silently erase a newly introduced fixed internal code.
    -- Never record the rejected value (which may be user data).
    return reasons[v] and v or "diagnostic_code_unmapped"
end
-- Store each bounded journal segment as a scalar-only SavedVariables
-- record. WoW itself flushes SavedVariables to disk on logout/reload;
-- addons cannot create arbitrary files during gameplay.
function D:SaveJournalPart(final)
    if not self.session or type(self.records)~="table" then return false end
    if #self.records==0 and not final then return false end
    local db=self.settings
    db.sessions=type(db.sessions)=="table" and db.sessions or {}
    local kept={matrix=self.matrix,version=self.version,
        started=self.session.started,stopped=now() or 0,
        sessionID=self.session.sessionID,
        dropped=final and self.dropped or 0,
        evictedParts=final and (self.evictedParts or 0) or 0,
        part=(self.journalPart or 0)+1,
        final=final==true,records={}}
    for i,item in ipairs(self.records) do
        kept.records[i]={sequence=item.sequence,kind=item.kind,
            status=item.status,reason=item.reason,
            matrix=item.matrix,elapsed=item.elapsed,time=item.time,
            detail=item.detail,method=item.method,count=item.count}
    end
    table.insert(db.sessions,kept)
    local limit=type(self.maxSessions)=="number" and self.maxSessions or 8
    while #db.sessions>limit do
        local removed=table.remove(db.sessions,1)
        if removed and removed.sessionID==self.journalID then
            self.evictedParts=(self.evictedParts or 0)+1
        end
    end
    kept.evictedParts=self.evictedParts or 0
    self.settings=db
    KordRotationDevToolsDB=db
    self.journalPart=kept.part
    return true
end
function D:Start()
    if self.active then return false,"already_recording" end
    self.active=true
    self.records={}
    self.sequence=0
    self.dropped=0
    self.journalPart=0
    self.exportPage=0
    self.evictedParts=0
    local nextID=type(self.settings.nextSessionID)=="number"
        and self.settings.nextSessionID or 0
    if nextID<0 or nextID>999999999 or nextID~=math.floor(nextID) then
        nextID=0
    end
    self.journalID=nextID+1
    self.settings.nextSessionID=self.journalID
    self.started=now()
    self.lastTick=nil
    self.lastCooldownTick=nil
    self.session={matrix=self.matrix,version=self.version,
        started=self.started or 0,sessionID=self.journalID,
        records=self.records}
    -- Only the main addon's static GameAPI allowlist is accepted as a
    -- diagnostic method name; never persist arbitrary game/player strings.
    self.apiTraceAllowed={}
    local bridge=_G.KordRotationCoreObservation
    if type(bridge)=="table" and type(bridge.APIMethodNames)=="function" then
        local ok,names=pcall(bridge.APIMethodNames)
        if ok and type(names)=="table" and self:Safe(names) then
            for _,name in ipairs(names) do
                if self:Safe(name) and type(name)=="string"
                    and #name<=80 and name:match("^[A-Za-z][A-Za-z0-9_.]*$") then
                    self.apiTraceAllowed[name]=true
                end
            end
        end
    end
    if self.TraceStart then self:TraceStart() end
    -- Once per opt-in session, log one row for each canonical v14 API
    -- presence check. No combat API is executed by this census.
    if self.ProbeAll then self:ProbeAll() end
    return true
end
function D:Stop()
    if not self.active then return false,"not_recording" end
    self.stopping=true
    if self.TraceStop then self:TraceStop() end
    self.active=false
    self.stopping=false
    if self.session then self:SaveJournalPart(true) end
    self.session=nil
    return true
end
function D:Record(kind,status,reason,matrix,elapsed,detail,method,count)
    if not self.active then return false,"not_recording" end
    local current=now()
    if not self.stopping and self.started and current
        and current-self.started>self.maxDuration then
        -- A final diagnostic snapshot during Stop must not recursively Stop.
        if not self.stopping then self:Stop() end
        return false,"session_limit"
    end
    if #self.records>=self.maxRecords then
        -- Rotate a completed segment into SavedVariables and keep recording.
        -- Drop only when persistence is unavailable.
        if self:SaveJournalPart(false) then
            self.records={}
            self.session.records=self.records
        else
            self.dropped=self.dropped+1
            return false,"buffer_full"
        end
    end
    if not D:Safe(kind) or not D:Safe(status) or not D:Safe(reason)
        or not D:Safe(matrix) or not D:Safe(elapsed) then
        self.dropped=self.dropped+1
        return false,"protected_value"
    end
    kind=enum(kind,kinds,"ERROR")
    status=enum(status,statuses,"UNKNOWN")
    reason=sanitizeReason(reason)
    local v14=int(matrix,1,101)
    local latency=int(elapsed,0,1000000)
    local cleanDetail=safeDetail(detail)
    local cleanMethod
    local cleanCount
    if kind=="METHOD" then
        -- Generic safe reason vocabulary for actual GameAPI calls:
        -- no new Recorder whitelist edit is required for a newly added
        -- internal adapter failure code. The bridge supplies only a
        -- bounded reason token, never the original game return value.
        if self:Safe(detail) and type(detail)=="string" and #detail>=1
            and #detail<=64 and detail:match("^[a-z][a-z0-9_]*$") then
            cleanDetail=detail
        end
        local known=self:Safe(method) and type(method)=="string"
            and self.apiTraceAllowed and self.apiTraceAllowed[method]
        -- Only a bounded ASCII field key is accepted from the protected
        -- GameAPI.ReadField path; never a field value or arbitrary input.
        local fieldName=self:Safe(method) and type(method)=="string"
            and #method<=80 and
            method:match("^GameAPI%.ReadField%.[A-Za-z_][A-Za-z0-9_]*$")
        if known or fieldName then
            cleanMethod=method
        else
            cleanMethod="GameAPI.unsupported"
        end
        cleanCount=int(count,1,1000000000) or 1
    end
    -- A cooldown storm may be throttled, but distinct target, engine,
    -- profile and player-cast transitions are never lost to a global 50ms
    -- gate. The bounded maxRecords/maxDuration limits still apply.
    if kind=="EVENT" and reason=="spell_update_cooldown"
        and self.lastCooldownTick and current
        and current-self.lastCooldownTick<0.20 then
        return false,"coalesced_cooldown"
    end
    self.sequence=self.sequence+1
    self.records[#self.records+1]={sequence=self.sequence,kind=kind,
        status=status,reason=reason,matrix=v14,elapsed=latency,time=current,
        detail=cleanDetail,method=cleanMethod,count=cleanCount}
    self.lastTick=current
    if kind=="EVENT" and reason=="spell_update_cooldown" then
        self.lastCooldownTick=current
    end
    return true
end
function D:Clear()
    if self.active then return false,"stop_first" end
    self.records={}
    self.session=nil
    self.sequence=0
    self.dropped=0
    self.settings.sessions={}
    self.exportPage=0
    KordRotationDevToolsDB=self.settings
    return true
end
local function encode(v)
    if v==nil then return "" end
    if type(v)=="number" then return string.format("%.0f",v) end
    return type(v)=="string" and v or ""
end
-- Pagination avoids silent 32 KB truncation while keeping the edit box
-- bounded. Each page contains complete rows, in chronological order.
-- The full archive still follows SavedVariables segment retention limits.
function D:Export(page)
    local records={}
    for _,part in ipairs(self.settings.sessions or {}) do
        if type(part)=="table" and part.sessionID==self.journalID
            and type(part.records)=="table" then
            for _,item in ipairs(part.records) do
                records[#records+1]=item
            end
        end
    end
    if self.active then
        for _,item in ipairs(self.records or {}) do
            records[#records+1]=item
        end
    end
    local limit=type(self.maxExport)=="number"
        and math.max(1024,math.floor(self.maxExport)) or 32768
    -- Reserve room for the header/footer and printable page metadata.
    local budget=math.max(512,limit-240)
    local pages={{}}
    local used=0
    local function emit(line)
        if used+#line+1>budget and #pages[#pages]>0 then
            pages[#pages+1]={}
            used=0
        end
        pages[#pages][#pages[#pages]+1]=line
        used=used+#line+1
    end
    for _,v in ipairs(records) do
        local line=table.concat({encode(v.sequence),encode(v.kind),
            encode(v.status),encode(v.reason),encode(v.matrix),
            encode(v.elapsed),encode(v.time),encode(v.detail),
            encode(v.method),encode(v.count)},"\t")
        emit(line)
    end
    local total=#pages
    page=type(page)=="number" and page==math.floor(page)
        and math.max(1,math.min(page,total)) or 1
    local header="KordRotationDevTools\tmatrix="..self.matrix..
        "\tversion="..self.version.."\tpage="..page.."/"..total
    local lines={header}
    for _,line in ipairs(pages[page]) do lines[#lines+1]=line end
    lines[#lines+1]="dropped="..encode(self.dropped)
    lines[#lines+1]="evicted_parts="..encode(self.evictedParts or 0)
    lines[#lines+1]="page="..page.."/"..total
    lines[#lines+1]="truncated="..(total>1 and "1" or "0")
    return table.concat(lines,"\n"),page,total
end
