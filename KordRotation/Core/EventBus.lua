-- Kord Rotation (c) 2026 Vi22Rus. All rights reserved.
-- Stage 2.2: event-driven invalidation only. Does not compute or cast a rotation.
local addonName, KR = ...
KR.EventBus = KR.EventBus or {}
local E = KR.EventBus

local channels = {
    PLAYER_LOGIN="identity", PLAYER_LEVEL_UP="identity",
    TRAIT_CONFIG_UPDATED="talents", PLAYER_TALENT_UPDATE="talents",
    ACTIVE_TALENT_GROUP_CHANGED="talents", SPELLS_CHANGED="spellbook",
    ACTIONBAR_SLOT_CHANGED="actionbar", ACTIONBAR_PAGE_CHANGED="actionbar",
    UPDATE_SHAPESHIFT_FORM="actionbar", UPDATE_BINDINGS="bindings",
    UPDATE_MACROS="actionbar", PLAYER_TARGET_CHANGED="target",
    UNIT_AURA="auras", UNIT_POWER_UPDATE="resources",
    UNIT_POWER_FREQUENT="resources", UNIT_SPELLCAST_START="cast",
    UNIT_SPELLCAST_STOP="cast", UNIT_SPELLCAST_CHANNEL_START="cast",
    UNIT_SPELLCAST_CHANNEL_STOP="cast", UNIT_SPELLCAST_SUCCEEDED="cast",
    PLAYER_REGEN_ENABLED="combat", PLAYER_REGEN_DISABLED="combat",
    PLAYER_DEAD="combat", PLAYER_ALIVE="combat", PLAYER_UNGHOST="combat",
}
local unitEvents = {
    UNIT_AURA=true, UNIT_POWER_UPDATE=true, UNIT_POWER_FREQUENT=true,
    UNIT_SPELLCAST_START=true, UNIT_SPELLCAST_STOP=true,
    UNIT_SPELLCAST_CHANNEL_START=true, UNIT_SPELLCAST_CHANNEL_STOP=true,
    UNIT_SPELLCAST_SUCCEEDED=true,
}
local function relevant(event, unit)
    return not unitEvents[event] or unit == "player" or unit == "target"
end
local function deltaValue(value)
    return type(value)=="number" and value==value
        and value>0 and value<math.huge and value or 0
end
local function safeDiagnostic(message)
    if KR.Diagnostics and type(KR.Diagnostics.Log)=="function" then
        KR.Diagnostics:Log("WARN", "EventBus", message)
    end
end

-- A channel revision changes on every accepted event; consumers can request a snapshot.
function E:MarkDirty(channel)
    if type(channel)~="string" or channel=="" then return false end
    self.revisions=self.revisions or {}
    self.pending=self.pending or {}
    self.revisions[channel]=(self.revisions[channel] or 0)+1
    self.pending[channel]=self.revisions[channel]
    return true
end

function E:Subscribe(channel, token, callback)
    if type(channel)~="string" or channel==""
        or type(token)~="string" or token==""
        or type(callback)~="function" then return false end
    self.listeners=self.listeners or {}
    self.listeners[channel]=self.listeners[channel] or {}
    self.listeners[channel][token]=callback
    return true
end

function E:Unsubscribe(channel, token)
    if not self.listeners or not self.listeners[channel] then return false end
    local exists=self.listeners[channel][token]~=nil
    self.listeners[channel][token]=nil
    return exists
end

function E:HandleEvent(event, unit)
    local channel=channels[event]
    if not channel or not relevant(event, unit) then return false end
    return self:MarkDirty(channel)
end

-- Coalesce all events within a 0.20s update window. No scans from OnUpdate.
function E:Flush()
    if not self.pending then return end
    local pending=self.pending
    self.pending={}
    for channel, revision in pairs(pending) do
        local listeners=self.listeners and self.listeners[channel]
        if listeners then
            for token, callback in pairs(listeners) do
                local ok=pcall(callback, channel, revision)
                if not ok then
                    self.listenerErrors=(self.listenerErrors or 0)+1
                    if self.listenerErrors <= 3 then
                        safeDiagnostic("Subscriber failed: "..channel.." / "..token)
                    end
                end
            end
        end
    end
end

function E:Tick(elapsed)
    local dt=deltaValue(elapsed)
    self.accumulator=(self.accumulator or 0)+dt
    self.heartbeat=(self.heartbeat or 0)+dt
    -- Heartbeat is a low-frequency invalidation, not a fabricated game snapshot.
    if self.heartbeat >= 2 then
        self.heartbeat=self.heartbeat % 2
        if self.listeners and self.listeners.heartbeat
            and next(self.listeners.heartbeat) then self:MarkDirty("heartbeat") end
    end
    if self.accumulator >= 0.20 then
        self.accumulator=self.accumulator % 0.20
        self:Flush()
    end
end

function E:Initialize()
    if self.frame then return true end
    if type(CreateFrame)~="function" then return false end
    local ok, frame=pcall(CreateFrame, "Frame")
    if not ok or not frame then return false end
    self.registered={}
    for event in pairs(channels) do
        local success=pcall(frame.RegisterEvent, frame, event)
        self.registered[event]=success
    end
    frame:SetScript("OnEvent", function(_,event,unit)
        E:HandleEvent(event,unit)
    end)
    frame:SetScript("OnUpdate",function(_,elapsed) E:Tick(elapsed) end)
    self.frame=frame
    return true
end

function E:Status()
    local unavailable={}
    for event, registered in pairs(self.registered or {}) do
        if not registered then unavailable[#unavailable+1]=event end
    end
    table.sort(unavailable)
    return {initialized=self.frame~=nil, revisions=self.revisions or {},
        unregistered=unavailable, listenerErrors=self.listenerErrors or 0}
end
-- Copyright notice: see repository LICENSE.