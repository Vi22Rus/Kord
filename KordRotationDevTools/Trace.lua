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
    return true
end
function D:TraceStop()
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
