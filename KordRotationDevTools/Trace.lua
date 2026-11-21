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
    if status==self.lastObserved then return false end
    self.lastObserved=status
    -- Coarse ENGINE transition only; never claim per-rule Eligibility trace.
    return self:Record("ENGINE",status,"manual_sample")
end
