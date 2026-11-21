-- Kord Rotation (c) 2026 Vi22Rus. All rights reserved.
-- Stage 2.3: conservative read-only player/target/combat snapshot.
-- No recommendation, button pressing or protected gameplay action occurs here.
local addonName, KR = ...
KR.GameState = KR.GameState or {}
local S = KR.GameState

local watched = {
    "identity", "target", "combat", "health", "resources", "cast",
    "talents", "heartbeat", "auras", "cooldowns",
}
local function finite(number, minimum)
    return type(number) == "number" and number == number
        and number ~= math.huge and number ~= -math.huge
        and (minimum == nil or number >= minimum)
end

local function invalid(read, reason)
    return {
        status = "UNKNOWN", source = read and read.source or "GameState",
        reason = reason, observedAt = read and read.observedAt or nil,
    }
end
local function unavailable(name)
    return {status = "UNAVAILABLE", source = name, reason = "adapter_missing"}
end
local function read(name, expectedType, ...)
    if not KR.GameAPI or type(KR.GameAPI.Read) ~= "function" then
        return unavailable(name)
    end
    return KR.GameAPI:Read(name, expectedType, ...)
end
local function tuple(name, types, ...)
    if not KR.GameAPI or type(KR.GameAPI.ReadTuple) ~= "function" then
        return unavailable(name)
    end
    return KR.GameAPI:ReadTuple(name, types, ...)
end
local function number(name, minimum, maximum, ...)
    local result = read(name, "number", ...)
    if result.status ~= "READY" then return result end
    if not finite(result.value, minimum)
        or (maximum and result.value > maximum) then
        return invalid(result, "out_of_range")
    end
    return result
end

local function copy(source, depth)
    if type(source) ~= "table" or depth > 9 then return source end
    local result = {}
    for k, v in pairs(source) do
        if type(v) == "table" then result[k] = copy(v, depth + 1)
        elseif type(v) ~= "function" and type(v) ~= "userdata" then result[k] = v end
    end
    return result
end
local function statusOf(items)
    for _, value in ipairs(items) do
        if not value or value.status ~= "READY" then return "UNKNOWN" end
    end
    return "READY"
end
local function cleanHealth(unit)
    local current = number("UnitHealth", 0, nil, unit)
    local maximum = number("UnitHealthMax", 1, nil, unit)
    local result = {current=current, maximum=maximum}
    if current.status == "READY" and maximum.status == "READY" then
        if current.value > maximum.value then
            result.current = invalid(current, "health_exceeds_max")
        else
            result.percent = {status="READY", source="GameState.health",
                value=(current.value / maximum.value) * 100,
                observedAt=current.observedAt}
        end
    end
    result.status = statusOf({result.current, result.maximum})
    return result
end
local function cleanPower()
    local kind = number("UnitPowerType", 0, nil, "player")
    local result = {kind=kind}
    if kind.status ~= "READY" then
        result.current = invalid(kind, "power_type_unknown")
        result.maximum = invalid(kind, "power_type_unknown")
        result.status = "UNKNOWN"
        return result
    end
    local current = number("UnitPower", 0, nil, "player", kind.value)
    local maximum = number("UnitPowerMax", 0, nil, "player", kind.value)
    result.current, result.maximum = current, maximum
    if current.status == "READY" and maximum.status == "READY" then
        if current.value > maximum.value then
            result.current=invalid(current, "power_exceeds_max")
        elseif maximum.value > 0 then
            result.percent = {status="READY", source="GameState.power",
                value=current.value * 100 / maximum.value,
                observedAt=current.observedAt}
        elseif current.value ~= 0 then
            result.current=invalid(current, "nonzero_power_without_max")
        end
    end
    result.status = statusOf({result.kind, result.current, result.maximum})
    return result
end

local function unitSnapshot(unit)
    local exists = read("UnitExists", "boolean", unit)
    local record = {exists=exists}
    if exists.status ~= "READY" then
        record.status="UNKNOWN"
        record.reason="unit_existence_unknown"
        return record
    end
    if exists.value == false then
        -- This is a proven absence, not an untrusted GUID or stale health value.
        record.status="ABSENT"
        return record
    end
    record.guid=read("UnitGUID", "string", unit)
    record.health=cleanHealth(unit)
    record.dead=read("UnitIsDeadOrGhost", "boolean", unit)
    if unit == "player" then
        local identity=tuple("UnitClass", {"string","string"}, "player")
        record.class=identity
        record.level=number("UnitLevel", 1, nil, "player")
        record.combat=read("UnitAffectingCombat", "boolean", "player")
        record.mounted=read("IsMounted", "boolean")
        -- Matrix #9: a boolean, not an inferred movement flag from casting.
        record.moving=read("IsPlayerMoving", "boolean")
    elseif unit=="target" then
        record.attackable=read("UnitCanAttack", "boolean", "player", "target")
        record.assistable=read("UnitCanAssist", "boolean", "player", "target")
        -- Matrix #38/#67/#100: UnitIsUnit(player,target) is NOT UnitIsPlayer.
        record.isPlayer=read("UnitIsPlayer", "boolean", "target")
        record.threat=number("UnitThreatSituation",0,3,"player","target")
    end
    record.status=statusOf({record.guid, record.dead, record.exists})
    return record
end

local function castingSnapshot(unit)
    -- A nil name can mean idle OR an unsupported API return: fail closed.
    -- Full cast timing is a separate contract to validate against Forever.
    local cast = read("UnitCastingInfo", "string", unit)
    local channel = read("UnitChannelInfo", "string", unit)
    local result={cast=cast, channel=channel}
    if cast.status=="READY" then
        result.status="CASTING"
    elseif channel.status=="READY" then
        result.status="CHANNELING"
    else
        result.status="UNKNOWN"
        result.reason="no_verified_cast_or_channel"
    end
    return result
end

local function clock()
    local value=number("GetTime", 0)
    return value.status=="READY" and value.value or nil
end

function S:ReadNow()
    local player=unitSnapshot("player")
    local target=unitSnapshot("target")
    -- Matrix #5/#77/#99: pet absence is not a player/target proxy.
    local pet=unitSnapshot("pet")
    local context={
        inGroup=read("IsInGroup","boolean"),
        inRaid=read("IsInRaid","boolean"),
        inInstance=read("IsInInstance","boolean"),
    }
    context.status=statusOf({context.inGroup,context.inRaid,context.inInstance})
    local combat={
        player=player.combat or invalid(player.exists, "player_missing"),
        lockdown=read("InCombatLockdown", "boolean"),
    }
    combat.status=statusOf({combat.player,combat.lockdown})
    local playerPower=player.exists.status=="READY" and
        player.exists.value==true and cleanPower() or
        {status="UNKNOWN", reason="player_not_confirmed"}
    local cast=player.exists.status=="READY" and
        player.exists.value==true and castingSnapshot("player") or
        {status="UNKNOWN", reason="player_not_confirmed"}
    local now=clock()
    local status = player.exists.status == "READY"
        and player.exists.value == true
        and target.exists.status == "READY"
        and combat.status == "READY" and "READY" or "UNKNOWN"
    local result = {
        status=status, observedAt=now, revision=(self.revision or 0)+1,
        player=player, target=target, pet=pet, context=context,
        combat=combat, resources=playerPower,
        casting=cast, reason=status=="UNKNOWN" and "critical_field_unknown" or nil,
    }
    self.revision=result.revision
    self.current=result
    self.dirty=false
    self.lastReadAt=now
    self.busRevisions=self.busRevisions or {}
    if KR.EventBus and KR.EventBus.revisions then
        for _,channel in ipairs(watched) do
            self.busRevisions[channel]=KR.EventBus.revisions[channel] or 0
        end
    end
    return copy(result,0)
end

function S:Invalidate(reason)
    self.dirty=true
    self.lastInvalidation=type(reason)=="string" and reason or "manual"
end

function S:GetSnapshot()
    local now=clock()
    local dirty=self.dirty or not self.current
    if KR.EventBus and KR.EventBus.revisions then
        for _,channel in ipairs(watched) do
            if (KR.EventBus.revisions[channel] or 0) ~=
                ((self.busRevisions or {})[channel] or 0) then
                dirty=true
                break
            end
        end
    end
    -- Without a trustworthy clock, every request reads again; never return stale forever.
    if not now or not self.lastReadAt or now < self.lastReadAt
        or now - self.lastReadAt >= 0.5 then dirty=true end
    if dirty then return self:ReadNow() end
    return copy(self.current,0)
end

function S:Initialize()
    if self.initialized then return true end
    if not KR.EventBus or type(KR.EventBus.Subscribe)~="function" then
        return false
    end
    for _, channel in ipairs(watched) do
        local ok=KR.EventBus:Subscribe(channel,"GameState",function(ch)
            S:Invalidate(ch)
        end)
        if not ok then return false end
    end
    self.initialized=true
    self:Invalidate("initialize")
    return true
end
-- Copyright notice (c) 2026 Vi22Rus; see root LICENSE.
