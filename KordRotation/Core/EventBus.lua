-- Kord Rotation (c) 2026 Vi22Rus. All rights reserved.
-- Stage 2.2: event-driven invalidation only. Does not compute or cast a rotation.
local addonName, KR = ...
KR.EventBus = KR.EventBus or {}
local E = KR.EventBus

local channels = {
    PLAYER_LOGIN="identity", PLAYER_ENTERING_WORLD="identity", PLAYER_LEVEL_UP="identity",
    TRAIT_CONFIG_UPDATED="talents", PLAYER_TALENT_UPDATE="talents",
    ACTIVE_TALENT_GROUP_CHANGED="talents", SPELLS_CHANGED="spellbook",
    PLAYER_SPECIALIZATION_CHANGED="talents", CHARACTER_POINTS_CHANGED="talents",
    LEARNED_SPELL_IN_TAB="spellbook", LEARNED_SPELL_IN_SKILL_LINE="spellbook",
    SKILL_LINES_CHANGED="spellbook",
    ACTIONBAR_SLOT_CHANGED="actionbar", ACTIONBAR_PAGE_CHANGED="actionbar",
    ACTIONBAR_UPDATE_STATE="actionbar", UPDATE_BONUS_ACTIONBAR="actionbar",
    UPDATE_OVERRIDE_ACTIONBAR="actionbar", UPDATE_VEHICLE_ACTIONBAR="actionbar",
    UPDATE_POSSESS_BAR="actionbar", UPDATE_STEALTH="actionbar",
    MODIFIER_STATE_CHANGED="actionbar", ADDON_LOADED="actionbar",
    UPDATE_SHAPESHIFT_FORM="actionbar", UPDATE_BINDINGS="bindings",
    UPDATE_MACROS="actionbar", PLAYER_TARGET_CHANGED="target",
    SPELL_UPDATE_COOLDOWN="cooldowns", ACTIONBAR_UPDATE_COOLDOWN="cooldowns",
    BAG_UPDATE_COOLDOWN="itemCooldown",
    SPELL_UPDATE_CHARGES="cooldowns", SPELL_UPDATE_USABLE="cooldowns",
    UNIT_AURA="auras", UNIT_HEALTH="health", UNIT_MAXHEALTH="health",
    UNIT_PET="pet", PET_BAR_UPDATE="pet",
    UNIT_DISPLAYPOWER="resources", UNIT_MAXPOWER="resources", UNIT_POWER_UPDATE="resources",
    UNIT_POWER_FREQUENT="resources", UNIT_FLAGS="combat",
    UNIT_SPELLCAST_START="cast",
    UNIT_SPELLCAST_STOP="cast", UNIT_SPELLCAST_INTERRUPTED="cast",
    UNIT_SPELLCAST_FAILED="cast", UNIT_SPELLCAST_CHANNEL_START="cast",
    UNIT_SPELLCAST_CHANNEL_STOP="cast", UNIT_SPELLCAST_SUCCEEDED="cast",
    PLAYER_REGEN_ENABLED="combat", PLAYER_REGEN_DISABLED="combat",
    PLAYER_DEAD="combat", PLAYER_ALIVE="combat", PLAYER_UNGHOST="combat",
    -- IT-01/1.6: optional inventory signals, registered through client probe.
    BAG_UPDATE="inventory", BAG_UPDATE_DELAYED="inventory",
    BAG_CONTAINER_UPDATE="inventory",
    ZONE_CHANGED="identity", ZONE_CHANGED_NEW_AREA="identity",
}
local unitEvents = {
    UNIT_AURA=true, UNIT_HEALTH=true, UNIT_MAXHEALTH=true,
    UNIT_PET=true,
    UNIT_DISPLAYPOWER=true, UNIT_MAXPOWER=true, UNIT_POWER_UPDATE=true,
    UNIT_POWER_FREQUENT=true, UNIT_FLAGS=true,
    UNIT_SPELLCAST_START=true, UNIT_SPELLCAST_STOP=true,
    UNIT_SPELLCAST_INTERRUPTED=true, UNIT_SPELLCAST_FAILED=true,
    UNIT_SPELLCAST_CHANNEL_START=true, UNIT_SPELLCAST_CHANNEL_STOP=true,
    UNIT_SPELLCAST_SUCCEEDED=true,
}
local function relevant(event, unit)
    return not unitEvents[event] or unit == "player" or unit == "target"
        or unit == "pet" or unit == "pettarget"
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

-- Inventory revision is separate from general event-channel revisions. All
-- changes invalidate shared observations; a known bag ID also gets its own
-- revision. Unknown event parameters invalidate all bags, never imply zero.
local function knownBag(bagID)
    if type(bagID)~="number" then return false end
    local ok,valid=pcall(function()
        return bagID==math.floor(bagID) and bagID>=0 and bagID<=4
    end)
    return ok and valid==true
end

function E:GetInventoryRevision()
    return self.inventoryRevision or 0
end

function E:GetBagRevision(bagID)
    if not knownBag(bagID) then return nil end
    return self.bagRevisions and self.bagRevisions[bagID] or 0
end

function E:InvalidateInventory(bagID, reason)
    self.inventoryRevision=(self.inventoryRevision or 0)+1
    if knownBag(bagID) then
        self.bagRevisions=self.bagRevisions or {}
        self.bagRevisions[bagID]=(self.bagRevisions[bagID] or 0)+1
    else
        -- Global or ambiguous signals invalidate every player bag.
        self.bagRevisions=self.bagRevisions or {}
        for id=0,4 do
            self.bagRevisions[id]=(self.bagRevisions[id] or 0)+1
        end
    end
    self.inventoryLastReason=reason or "inventory_invalidation"
    self:MarkDirty("inventory") -- Existing 0.20s coalescing, no scans.
    return self.inventoryRevision
end

-- Soulwell may not emit BAG_UPDATE_DELAYED. A confirmed interaction/item
-- signal or an explicit UI/DevTools request can invalidate on demand.
-- Does not register invented WoW events or poll bags each frame.
function E:RequestInventoryRefresh(reason)
    if type(reason)~="string" or reason=="" then
        reason="explicit_inventory_refresh"
    end
    return self:InvalidateInventory(nil,reason)
end

-- IT-02/2.7: revisions are invalidation evidence, never proof of use.
function E:GetItemCooldownRevision()
    return self.itemCooldownRevision or 0
end
function E:InvalidateItemCooldown(reason)
    self.itemCooldownRevision=(self.itemCooldownRevision or 0)+1
    self.itemCooldownLastReason=type(reason)=="string" and reason or "item_cd_invalidation"
    -- A real invalidation restarts the bounded refresh window.
    self.itemCooldownRefreshElapsed=0
    self:MarkDirty("itemCooldown")
    return self.itemCooldownRevision
end
function E:RequestItemCooldownRefresh(reason)
    return self:InvalidateItemCooldown(reason or "explicit_item_cd_refresh")
end

function E:HandleEvent(event, unit, castGUID, spellID)
    local channel=channels[event]
    if not channel or not relevant(event, unit) then return false end
    if channel=="inventory" then
        local bagID=(event=="BAG_UPDATE" or event=="BAG_CONTAINER_UPDATE")
            and unit or nil
        self:InvalidateInventory(bagID,event)
    elseif channel~="itemCooldown" then
        self:MarkDirty(channel)
    end
    -- Optional cooldown event and conservative independent invalidations.
    -- Neither a cast nor an inventory update establishes item identity.
    -- JustAC Forever: UNIT_SPELLCAST_SUCCEEDED identifies a spell, NOT an
    -- item. Only a previously prepared unique use-spell map may correlate it.
    if event=="UNIT_SPELLCAST_SUCCEEDED" and unit=="player"
        and KR.GameState and type(KR.GameState.ObserveSuccessfulItemUseSpell)=="function" then
        pcall(KR.GameState.ObserveSuccessfulItemUseSpell,KR.GameState,spellID)
    elseif (event=="PLAYER_REGEN_ENABLED" or event=="PLAYER_ENTERING_WORLD"
        or event=="ZONE_CHANGED_NEW_AREA")
        and KR.GameState and type(KR.GameState.ClearObservedItemUse)=="function" then
        pcall(KR.GameState.ClearObservedItemUse,KR.GameState)
    end
    if event=="BAG_UPDATE_COOLDOWN" or event=="BAG_UPDATE_DELAYED"
        or event=="BAG_UPDATE" or event=="ACTIONBAR_UPDATE_COOLDOWN"
        or event=="UNIT_SPELLCAST_SUCCEEDED"
        or event=="PLAYER_REGEN_ENABLED" or event=="PLAYER_REGEN_DISABLED"
        or event=="PLAYER_ENTERING_WORLD"
        or event=="ZONE_CHANGED" or event=="ZONE_CHANGED_NEW_AREA" then
        self:InvalidateItemCooldown(event)
    end
    return true
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
    -- IT-02/2.7: a bounded wake-up for clients missing bag cooldown events.
    -- This only changes an observation revision; no API or inventory scan.
    -- Without a listener there is no work and no invented evidence.
    local listeners=self.listeners and self.listeners.itemCooldown
    if listeners and next(listeners) then
        self.itemCooldownRefreshElapsed=(self.itemCooldownRefreshElapsed or 0)+dt
        if self.itemCooldownRefreshElapsed>=2 then
            self:InvalidateItemCooldown("item_cd_periodic_refresh")
        end
    else
        self.itemCooldownRefreshElapsed=0
    end
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
        local valid=true
        local validator=type(C_EventUtils)=="table" and C_EventUtils.IsEventValid
        if type(validator)=="function" then
            local ok,available=pcall(validator,event)
            valid=ok and available==true
        end
        self.registered[event]=valid and pcall(frame.RegisterEvent, frame, event) or false
    end
    frame:SetScript("OnEvent", function(_,event,unit,castGUID,spellID)
        E:HandleEvent(event,unit,castGUID,spellID)
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
        inventoryRevision=self:GetInventoryRevision(),
        itemCooldownRevision=self:GetItemCooldownRevision(),
        itemCooldownLastReason=self.itemCooldownLastReason,
        bagRevisions=self.bagRevisions or {},
        inventoryLastReason=self.inventoryLastReason,
        unregistered=unavailable, listenerErrors=self.listenerErrors or 0}
end
-- Copyright notice: see repository LICENSE.