-- Kord Rotation DevTools (c) 2026 Vi22Rus; see root LICENSE.
-- Recording only after explicit Start, no mutation of KordRotation.
local _,D=...
local tracked={
 PLAYER_TARGET_CHANGED=1, UPDATE_BINDINGS=33,
 SPELL_UPDATE_COOLDOWN=25, ACTIONBAR_SLOT_CHANGED=32,
 SPELLS_CHANGED=19, PLAYER_REGEN_ENABLED=17,
 PLAYER_REGEN_DISABLED=17, PLAYER_ENTERING_WORLD=18,
}
local reasons={
 PLAYER_TARGET_CHANGED="manual_sample",
 UPDATE_BINDINGS="manual_sample",
 SPELL_UPDATE_COOLDOWN="manual_sample",
 ACTIONBAR_SLOT_CHANGED="manual_sample",
 SPELLS_CHANGED="manual_sample",
 PLAYER_REGEN_ENABLED="manual_sample",
 PLAYER_REGEN_DISABLED="manual_sample",
 PLAYER_ENTERING_WORLD="manual_sample",
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
    frame:SetScript("OnEvent",function(_,event)
        if not D.active or not tracked[event] then return end
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
    return true
end
function D:ObserveTransition()
    if not self.active then return false end
    local snapshot=self:ReadCore()
    local status=snapshot and snapshot.engineStatus
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

    local profile=snapshot and snapshot.profileStatus
    if not self:Safe(profile) or (profile~="READY" and profile~="BLOCKED"
        and profile~="UNAVAILABLE" and profile~="UNKNOWN") then
        profile="UNKNOWN"
    end
    if profile~=self.lastProfile then
        if self:Record("PROFILE",profile,"manual_sample") then
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

    if status~=self.lastObserved then
        if self:Record("ENGINE",status,"manual_sample") then
            self.lastObserved=status
            return true
        end
    end
    return false
end
