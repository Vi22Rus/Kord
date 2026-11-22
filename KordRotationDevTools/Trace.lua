-- Kord Rotation DevTools (c) 2026 Vi22Rus; see root LICENSE.
-- Recording only after explicit Start, no mutation of KordRotation.
local _,D=...
local tracked={
 PLAYER_TARGET_CHANGED=1, UPDATE_BINDINGS=33,
 SPELL_UPDATE_COOLDOWN=25, ACTIONBAR_SLOT_CHANGED=32,
 SPELLS_CHANGED=19, PLAYER_REGEN_ENABLED=17,
 PLAYER_REGEN_DISABLED=17, PLAYER_ENTERING_WORLD=18,
 UNIT_SPELLCAST_SUCCEEDED=25, UNIT_SPELLCAST_START=25,
 UNIT_SPELLCAST_FAILED=25, UNIT_SPELLCAST_INTERRUPTED=25,
}
local reasons={
 PLAYER_TARGET_CHANGED="player_target_changed",
 UPDATE_BINDINGS="update_bindings",
 SPELL_UPDATE_COOLDOWN="spell_update_cooldown",
 ACTIONBAR_SLOT_CHANGED="actionbar_slot_changed",
 SPELLS_CHANGED="spells_changed",
 PLAYER_REGEN_ENABLED="player_regen_enabled",
 PLAYER_REGEN_DISABLED="player_regen_disabled",
 PLAYER_ENTERING_WORLD="player_entering_world",
 UNIT_SPELLCAST_SUCCEEDED="unit_spellcast_succeeded",
 UNIT_SPELLCAST_START="unit_spellcast_start",
 UNIT_SPELLCAST_FAILED="unit_spellcast_failed",
 UNIT_SPELLCAST_INTERRUPTED="unit_spellcast_interrupted",
}
local playerOnly={
 UNIT_SPELLCAST_SUCCEEDED=true, UNIT_SPELLCAST_START=true,
 UNIT_SPELLCAST_FAILED=true, UNIT_SPELLCAST_INTERRUPTED=true,
}
function D:TraceStart()
    if not self.active then return false end
    if type(CreateFrame)~="function" then return false end
    if not self.traceFrame then self.traceFrame=CreateFrame("Frame") end
    local frame=self.traceFrame
    for event in pairs(tracked) do
        -- Client may omit events. Feature-detect, never fake successful hooks.
        pcall(frame.RegisterEvent,frame,event)
    end
    frame:SetScript("OnEvent",function(_,event,unit)
        if not D.active or not tracked[event] then return end
        -- Do not record other units' spellcasts or any spell ID/name.
        if playerOnly[event] and (not D:Safe(unit) or unit~="player") then return end
        D:Record("EVENT","READY",reasons[event],tracked[event])
        if event=="PLAYER_TARGET_CHANGED" then D.nextDetailedAt=nil end
        D:ObserveTransition()
    end)
    frame:SetScript("OnUpdate",function(self,elapsed)
        if not D.active then return end
        local delta=type(elapsed)=="number" and elapsed>0 and elapsed<5 and elapsed or 0
        self.accum=(self.accum or 0)+delta
        if self.accum<0.75 then return end
        self.accum=0
        D:ObserveTransition()
    end)
    self.lastObserved=nil
    self.lastProfile=nil
    self.lastEligibility=nil
    self.lastErrors=nil
    self.lastTarget=nil
    self.lastFirstReason=nil
    self.lastDetailKeys={}
    self.nextDetailedAt=nil
    self.methodAggregate={}
    self.apiTraceUnavailableRecorded=nil
    local bridge=_G.KordRotationCoreObservation
    if type(bridge)=="table" and type(bridge.BeginAPITrace)=="function" then
        local ok,enabled=pcall(bridge.BeginAPITrace)
        self.apiTraceStarted=ok and enabled==true
    else
        self.apiTraceStarted=false
    end
    if not self.apiTraceStarted then
        self:Record("METHOD","UNAVAILABLE","method_trace_unavailable")
        self.apiTraceUnavailableRecorded=true
    end
    self:ObserveTransition()
    return true
end
function D:TraceStop()
    if self.active then self:ObserveDetails(nil,true) end
    self:DrainAPIMethods()
    -- Persist final per-method totals once, not hundreds of identical
    -- records every 2 seconds. The first observation preserves timing.
    for _,entry in pairs(self.methodAggregate or {}) do
        self:Record("METHOD",entry.status,"method_total",
            entry.matrix,nil,entry.reason,entry.method,entry.count)
    end
    self.methodAggregate=nil
    local bridge=_G.KordRotationCoreObservation
    if type(bridge)=="table" and type(bridge.EndAPITrace)=="function" then
        pcall(bridge.EndAPITrace)
    end
    local frame=self.traceFrame
    if frame then
        frame:SetScript("OnEvent",nil)
        frame:SetScript("OnUpdate",nil)
        if type(frame.UnregisterAllEvents)=="function" then
            pcall(frame.UnregisterAllEvents,frame)
        end
    end
    self.lastObserved=nil
    self.lastProfile=nil
    self.lastEligibility=nil
    self.lastErrors=nil
    self.lastTarget=nil
    self.lastDetailKeys=nil
    self.nextDetailedAt=nil
    return true
end
-- Observe the live target only through the sanitized main-addon bridge.
-- Do not query game APIs, inspect target GUIDs or retain unit objects.
function D:ObserveTarget()
    local bridge=_G.KordRotationCoreObservation
    if type(bridge)~="table" or type(bridge.Target)~="function" then return false end
    local ok,data=pcall(bridge.Target)
    if not ok or type(data)~="table" or not self:Safe(data) then return false end
    local state="UNKNOWN"
    if self:Safe(data.liveStatus) and data.liveStatus=="READY"
        and self:Safe(data.liveExists)
        and type(data.liveExists)=="boolean" then
        state=data.liveExists and "READY" or "BLOCKED"
    end
    if state==self.lastTarget then return false end
    local reason=state=="READY" and "target_present"
        or state=="BLOCKED" and "target_absent" or "target_unverified"
    if self:Record("TARGET",state,reason,1) then
        self.lastTarget=state
        return true
    end
    return false
end
-- Drain every actual read-only GameAPI invocation through the scalar
-- bridge; group repeated (method,status,reason) tuples into counts.
-- This is independent of the 101-row *presence-only* v14 census.
function D:DrainAPIMethods()
    if not self.active then return false end
    local bridge=_G.KordRotationCoreObservation
    if type(bridge)~="table" or type(bridge.APITrace)~="function" then
        if not self.apiTraceUnavailableRecorded then
            self:Record("METHOD","UNAVAILABLE","method_trace_unavailable")
            self.apiTraceUnavailableRecorded=true
        end
        return false
    end
    local ok,result=pcall(bridge.APITrace)
    if not ok or type(result)~="table" or not self:Safe(result)
        or type(result.entries)~="table" or not self:Safe(result.entries) then
        self:Record("METHOD","UNKNOWN","method_trace_overflow")
        return false
    end
    if result.active~=true then
        if not self.apiTraceUnavailableRecorded then
            self:Record("METHOD","UNAVAILABLE","method_trace_unavailable")
            self.apiTraceUnavailableRecorded=true
        end
        return false
    end
    local ids={}
    for _,row in ipairs(self.V14Registry or {}) do
        if type(row.method)=="string" and ids[row.method]==nil then
            ids[row.method]=row.id
        end
    end
    for index,item in ipairs(result.entries) do
        if index>2048 then
            self:Record("METHOD","UNKNOWN","method_trace_overflow")
            return false
        end
        if type(item)=="table" and self:Safe(item)
            and self:Safe(item.method) and self:Safe(item.status)
            and self:Safe(item.reason) and self:Safe(item.count)
            and type(item.method)=="string"
            and type(item.status)=="string"
            and type(item.reason)=="string"
            and type(item.count)=="number" and item.count>=1
            and item.count<=1000000000 and
            item.count==math.floor(item.count) then
            self.methodAggregate=self.methodAggregate or {}
            local key=item.method.."|"..item.status.."|"..item.reason
            local existing=self.methodAggregate[key]
            if not existing then
                existing={method=item.method,status=item.status,
                    reason=item.reason,matrix=ids[item.method],count=0}
                self.methodAggregate[key]=existing
                -- First occurrence is enough for chronology. The final
                -- totals emitted on Stop capture the complete volume.
                self:Record("METHOD",item.status,"method_call",
                    ids[item.method],nil,item.reason,
                    item.method,item.count)
            end
            existing.count=math.min(1000000000,
                existing.count+item.count)
        else
            self:Record("METHOD","UNKNOWN","method_trace_overflow")
        end
    end
    if self:Safe(result.overflow) and
        type(result.overflow)=="number" and result.overflow>0
        and result.overflow==result.overflow
        and result.overflow<math.huge then
        self:Record("METHOD","UNKNOWN","method_trace_overflow",
            nil,nil,"none","GameAPI.unsupported",
            math.min(1000000000,math.floor(result.overflow)))
    end
    return true
end
-- A compact session journal instead of an ever-growing UI report.
-- Sample at most once per two seconds (or immediately after target change),
-- record only changes, and never serialize raw game objects.
function D:ObserveDetails(diagnosis,force,summary)
    if not self.active then return false end
    local bridge=_G.KordRotationCoreObservation
    if type(bridge)~="table" then return false end
    local clock
    if type(GetTime)=="function" then
        local ok,v=pcall(GetTime)
        if ok and self:Safe(v) and type(v)=="number"
            and v==v and v>=0 and v<math.huge then clock=v end
    end
    if not force and clock and self.nextDetailedAt
        and clock<self.nextDetailedAt then return false end
    if clock then self.nextDetailedAt=clock+2 end
    self.lastDetailKeys=self.lastDetailKeys or {}
    local function fetch(method)
        local fn=bridge[method]
        if type(fn)~="function" or not D:Safe(fn) then return nil end
        local ok,value=pcall(fn)
        if ok and type(value)=="table" and D:Safe(value) then return value end
        return nil
    end
    local function status(value)
        if not D:Safe(value) then return "UNKNOWN" end
        if value=="READY" or value=="BLOCKED" or value=="UNKNOWN"
            or value=="UNAVAILABLE" or value=="ERROR" then return value end
        return "UNKNOWN"
    end
    local function flag(value)
        if not D:Safe(value) or type(value)~="boolean" then return "UNKNOWN" end
        return value and "READY" or "BLOCKED"
    end
    local function add(kind,st,why,detail)
        st=status(st)
        if not D:Safe(detail) then detail=nil end
        if type(detail)=="string" and (#detail>64
            or not detail:match("^[a-z][a-z0-9_]*$")) then detail=nil end
        if type(detail)~="number" and type(detail)~="string" then detail=nil end
        local key=kind..":"..why
        local signature=st..":"..(detail and tostring(detail) or "")
        if self.lastDetailKeys[key]==signature then return end
        if self:Record(kind,st,why,nil,nil,detail) then
            self.lastDetailKeys[key]=signature
        end
    end
    self:DrainAPIMethods()
    local diag=diagnosis or fetch("Diagnose")
    if diag then
        add("CHECK",diag.decisiveStatus,"engine_decisive_priority",
            diag.decisivePriority)
        add("CHECK",diag.decisiveStatus,"engine_decisive_reason",
            diag.decisiveReason)
        add("CHECK",diag.firstStatus,"priority_1_rule",diag.firstReason)
        if diag.defensiveStatus then
            add("CHECK",diag.defensiveStatus,"defensive_engine_decision",
                diag.defensiveReason)
            add("CHECK",diag.defensiveRuleStatus,"defensive_rule_priority",
                diag.defensivePriority)
            add("CHECK",diag.defensiveRuleStatus,"defensive_rule_reason",
                diag.defensiveRuleReason)
        end
        -- The rank-4 fixed-position test belongs ONLY to the old pilot.
        -- For the full BM 1–59 module, use the generic RULE/SIGNAL/STAGE
        -- audit instead; its Arcane priority is no longer number five.
        if diag.arcaneR4Status~=nil then
            add("CHECK",diag.arcaneR4Status,"arcane_rank_4_rule",
                diag.arcaneR4Reason)
        if diag.arcaneR4BarReason~=nil then
            add("CHECK",diag.arcaneR4Status,
                "arcane_rank_4_bar_failure",diag.arcaneR4BarReason)
        end
        local checks=diag.arcaneR4Checks
        local names={"cast","usability","charges","cooldown","gcd","range"}
        local observed={}
        if D:Safe(checks) and type(checks)=="table"
            and #checks<=6 then
            for _,check in ipairs(checks) do
                if D:Safe(check) and type(check)=="table"
                    and D:Safe(check.name) then
                    for _,name in ipairs(names) do
                        if name==check.name then
                            observed[name]={status=check.status,reason=check.reason}
                            break
                        end
                    end
                end
            end
        end
        -- A BLOCKED stops the canonical lazy evaluator. Mark unvisited
        -- checks as not_evaluated so prior UNKNOWN results cannot linger.
        for _,name in ipairs(names) do
            local check=observed[name]
            add("CHECK",check and check.status or "UNAVAILABLE",
                "arcane_check_"..name,
                check and check.reason or "not_evaluated")
        end
        end -- pilot-only fixed priority snapshot
    end
    -- Full-profile audit: evaluate every registered rule independently
    -- and journal the signal / eligibility cause. Each key is stable and
    -- only written when its result changes; no raw player or spell data.
    local audit=fetch("Audit")
    if audit and D:Safe(audit) then
        local module=tostring(audit.module or "unavailable")
        local modules={bm_leveling=true,bm_pilot=true,bm_60=true,
            unavailable=true}
        if modules[module] then
            add("PROFILE",audit.status,"bm_profile_"..module,
                audit.ruleCount)
        end
        local stages={"cast","usability","charges","cooldown","gcd","range"}
        if type(audit.rules)=="table" and D:Safe(audit.rules)
            and #audit.rules<=64 then
            for index,rule in ipairs(audit.rules) do
                if type(rule)=="table" and D:Safe(rule)
                    and rule.priority==index then
                    add("RULE",rule.status,"bm_rule_"..index,rule.reason)
                    if rule.barReason~=nil then
                        add("BAR",rule.status,"bm_bar_"..index,
                            rule.barReason)
                    end
                    local inputs=rule.signals
                    if type(inputs)=="table" and D:Safe(inputs)
                        and #inputs<=24 then
                        for _,signal in ipairs(inputs) do
                            if type(signal)=="table" and D:Safe(signal)
                                and D:Safe(signal.name)
                                and type(signal.name)=="string" then
                                local slug=signal.name:lower():gsub(
                                    "[^a-z0-9]","_")
                                -- A READY read used to conceal whether a
                                -- confirmed predicate was true or false.
                                -- Preserve UNKNOWN for secrets; label only
                                -- explicitly validated public 1/0 evidence.
                                local factStatus=signal.status
                                local factReason=signal.reason
                                if factStatus=="READY"
                                    and signal.booleanValue==0 then
                                    factStatus="BLOCKED"
                                    factReason="fact_false"
                                elseif factStatus=="READY"
                                    and signal.booleanValue==1 then
                                    factReason="fact_true"
                                end
                                add("SIGNAL",factStatus,
                                    "bm_signal_"..index.."_"..slug,
                                    factReason)
                            end
                        end
                    end
                    local known={}
                    if type(rule.checks)=="table" and D:Safe(rule.checks)
                        and #rule.checks<=6 then
                        for _,check in ipairs(rule.checks) do
                            if type(check)=="table" and D:Safe(check)
                                and D:Safe(check.name) then
                                for _,name in ipairs(stages) do
                                    if check.name==name then
                                        known[name]={status=check.status,
                                            reason=check.reason}
                                    end
                                end
                            end
                        end
                    end
                    for _,name in ipairs(stages) do
                        local check=known[name]
                        add("STAGE",check and check.status or "UNAVAILABLE",
                            "bm_stage_"..index.."_"..name,
                            check and check.reason or "not_evaluated")
                    end
                end
            end
        end
    end
    local core=summary or self:ReadCore()
    if core then
        add("CHECK",core.profileStatus,"profile_ui")
        local function count(value)
            if not D:Safe(value) or type(value)~="number" or value~=value
                or value<0 or value>1200 or value~=math.floor(value) then
                return nil
            end
            return value
        end
        local er=count(core.eligibilityReady)
        local eb=count(core.eligibilityBlocked)
        local eu=count(core.eligibilityUnknown)
        add("CHECK",er and "READY" or "UNKNOWN","eligibility_ready_count",er)
        add("CHECK",eb and "READY" or "UNKNOWN","eligibility_blocked_count",eb)
        add("CHECK",eu and "READY" or "UNKNOWN","eligibility_unknown_count",eu)
    end
    local bar=fetch("ActionBar")
    if bar then
        add("BAR",bar.status,"actionbar_scan",bar.reason)
        add("BAR",bar.status,"actionbar_buttons",bar.confirmedSpellButtons)
        local rank=bar.arcaneRankOnBar
        local rankOK=D:Safe(rank) and type(rank)=="number"
            and rank==math.floor(rank) and rank>=1 and rank<=8
        add("BAR",rankOK and "READY" or "UNKNOWN",
            "arcane_rank_on_bar",rankOK and rank or nil)
        add("BAR",bar.arcaneFindStatus,"arcane_findspell",
            bar.arcaneFindReason)
    end
    local target=fetch("Target")
    if target then
        add("TARGET",target.liveStatus=="READY"
                and flag(target.liveExists) or "UNKNOWN","target_live")
        add("TARGET",target.snapshotStatus=="READY"
                and flag(target.snapshotExists) or "UNKNOWN","target_snapshot")
    end
    local display=fetch("Display")
    if display then
        add("DISPLAY",flag(display.panelEnabled),"panel_enabled")
        add("DISPLAY",flag(display.testMode),"test_mode")
        add("DISPLAY",flag(display.recommendationAccepted),
            "recommendation_accepted")
        add("DISPLAY",flag(display.visibilityAllowed),"visibility_allowed")
        add("DISPLAY",flag(display.frameCreated),"frame_created")
        add("DISPLAY",flag(display.frameShown),"frame_shown")
        add("DISPLAY",display.lastEngineStatus,"ui_engine_status",
            display.lastEngineReason)
        add("DISPLAY",flag(display.defensiveEnabled),"defensive_enabled")
        add("DISPLAY",flag(display.defensiveCombatOnly),"defensive_combat_only")
        add("DISPLAY",flag(display.auraPromotion),"aura_promotion")
        add("DISPLAY",flag(display.defensiveInCombatMain),
            "defensive_in_combat_main")
        add("DISPLAY",flag(display.defensivePreferenceStored),
            "defensive_preference_stored")
        add("DISPLAY",display.defensiveStatus,"defensive_engine_status",
            display.defensiveReason)
        add("DISPLAY",flag(display.defensiveRecommendation),
            "defensive_recommendation")
        add("DISPLAY",flag(display.defensiveFrameCreated),
            "defensive_frame_created")
        add("DISPLAY",flag(display.defensiveFrameShown),
            "defensive_frame_shown")
        add("DISPLAY",flag(display.defensiveVisibilityAllowed),
            "defensive_visibility_allowed")
    end
    return true
end

function D:ObserveTransition()
    if not self.active then return false end
    local snapshot=self:ReadCore()
    -- During an explicitly started recording, collect the engine's actual
    -- refusal independently of whether the user-facing panel was refreshed.
    local diagnostic
    local bridge=_G.KordRotationCoreObservation
    if type(bridge)=="table" and type(bridge.Diagnose)=="function" then
        local ok,record=pcall(bridge.Diagnose)
        if ok and type(record)=="table" and self:Safe(record) then
            diagnostic=record
        end
    end
    self:ObserveDetails(diagnostic,false,snapshot)
    local status=diagnostic and diagnostic.status
        or (snapshot and snapshot.engineStatus)
    if type(status)~="string" or not self:Safe(status) then status="UNKNOWN" end
    if status~="READY" and status~="BLOCKED" and status~="UNKNOWN" then
        status="UNKNOWN"
    end
    -- At most one aggregate transition per read. Rate-limited recorder may
    -- reject a sample; preserve previous marker and retry on the next tick.
    local rawErrors=snapshot and snapshot.eventListenerErrors
    local errors=0
    if self:Safe(rawErrors) and type(rawErrors)=="number"
        and rawErrors==rawErrors and rawErrors>=0 and rawErrors<=1000000000
        and rawErrors==math.floor(rawErrors) then
        errors=rawErrors
    end
    if self.lastErrors==nil then self.lastErrors=errors end
    if errors>self.lastErrors then
        if self:Record("ERROR","ERROR","manual_sample") then
            self.lastErrors=errors
            return true
        end
        return false
    end
    if errors<self.lastErrors then self.lastErrors=errors end

    local profile=diagnostic and diagnostic.profileStatus
        or (snapshot and snapshot.profileStatus)
    if not self:Safe(profile) or (profile~="READY" and profile~="BLOCKED"
        and profile~="UNAVAILABLE" and profile~="UNKNOWN") then
        profile="UNKNOWN"
    end
    if profile~=self.lastProfile then
        local profileReason=profile=="UNAVAILABLE" and "profile_not_registered"
            or profile=="BLOCKED" and "profile_unverified" or "none"
        if self:Record("PROFILE",profile,profileReason) then
            self.lastProfile=profile
            return true
        end
        return false
    end

    local function count(v)
        if not D:Safe(v) or type(v)~="number" or v~=v
            or v<0 or v>64 or v~=math.floor(v) then return 0 end
        return v
    end
    local r=count(snapshot and snapshot.eligibilityReady)
    local b=count(snapshot and snapshot.eligibilityBlocked)
    local u=count(snapshot and snapshot.eligibilityUnknown)
    local key=r..":"..b..":"..u
    if (r+b+u)>0 and key~=self.lastEligibility then
        local eligibility=u>0 and "UNKNOWN" or
            (r>0 and "READY" or "BLOCKED")
        if self:Record("ELIGIBILITY",eligibility,"manual_sample") then
            self.lastEligibility=key
            return true
        end
        return false
    end

    local engineReason=diagnostic and diagnostic.reason
        or (snapshot and snapshot.engineReason)
    if type(engineReason)~="string" or not self:Safe(engineReason)
        or #engineReason>64 or not engineReason:match("^[a-z][a-z0-9_]*$") then
        engineReason="unknown"
    end
    local engineKey=status..":"..engineReason
    if engineKey~=self.lastObserved then
        if self:Record("ENGINE",status,engineReason) then
            self.lastObserved=engineKey
            return true
        end
        return false
    end
    if diagnostic and diagnostic.firstReason~=nil then
        local firstReason=diagnostic.firstReason
        local firstStatus=diagnostic.firstStatus
        if not self:Safe(firstReason) or type(firstReason)~="string"
            or #firstReason>64 or not firstReason:match("^[a-z][a-z0-9_]*$") then
            firstReason="unknown"
        end
        if firstStatus~="READY" and firstStatus~="BLOCKED"
            and firstStatus~="UNKNOWN" then firstStatus="UNKNOWN" end
        local key=firstStatus..":"..firstReason
        if key~=self.lastFirstReason then
            if self:Record("ELIGIBILITY",firstStatus,firstReason) then
                self.lastFirstReason=key
                return true
            end
        end
    end
    return self:ObserveTarget()
end
