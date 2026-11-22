-- Kord Rotation (c) 2026 Vi22Rus. All rights reserved.
-- Stage 2.3: conservative read-only player/target/combat snapshot.
-- No recommendation, button pressing or protected gameplay action occurs here.
local addonName, KR = ...
KR.GameState = KR.GameState or {}
local S = KR.GameState

local watched = {
    "identity", "target", "combat", "health", "resources", "cast",
    "talents", "heartbeat", "auras", "cooldowns", "pet",
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
        -- Matrix #14/#78/#92: threat situation is an integer 0..3.
        if record.threat.status=="READY" and
            record.threat.value~=math.floor(record.threat.value) then
            record.threat=invalid(record.threat,"threat_level_invalid")
        end
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
    -- v14 #30: pet-target relation is proven only with both targets present.
    if pet.exists.status=="READY" and pet.exists.value==true then
        pet.targetExists=read("UnitExists","boolean","pettarget")
        if pet.targetExists.status=="READY" and pet.targetExists.value==true
            and target.exists.status=="READY" and target.exists.value==true then
            pet.attackingTarget=read("UnitIsUnit","boolean","pettarget","target")
        else
            pet.attackingTarget=invalid(pet.targetExists,"pet_target_not_confirmed")
        end
    else
        pet.targetExists=invalid(pet.exists,"pet_not_confirmed")
        pet.attackingTarget=invalid(pet.exists,"pet_not_confirmed")
    end
    local context={
        inGroup=read("IsInGroup","boolean"),
        inRaid=read("IsInRaid","boolean"),
        inInstance=read("IsInInstance","boolean"),
    }
    -- v14 #18/#90/#91: GetInstanceInfo second result is instance type.
    if context.inInstance.status=="READY" and context.inInstance.value==true then
        local instance=tuple("GetInstanceInfo",{"string","string"})
        if instance.status=="READY" then
            local kind=instance.value[2]
            if kind=="party" or kind=="raid" or kind=="pvp"
                or kind=="arena" or kind=="scenario" then
                context.instanceType={status="READY",value=kind,
                    source="GetInstanceInfo",observedAt=instance.observedAt}
            else
                context.instanceType=invalid(instance,"instance_type_unrecognized")
            end
        else context.instanceType=invalid(instance,"instance_type_unknown") end
    elseif context.inInstance.status=="READY" and context.inInstance.value==false then
        context.instanceType={status="READY",value="none",
            source="IsInInstance",observedAt=context.inInstance.observedAt}
    else context.instanceType=invalid(context.inInstance,"instance_unknown") end
    -- A confirmed instance with unreadable type is NOT a fully READY context.
    context.status=statusOf({context.inGroup,context.inRaid,
        context.inInstance,context.instanceType})
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

function S:GetSnapshot(force)
    -- A live rotation evaluation must not reuse target existence from a
    -- previous evaluation. The standalone /kre dump reads UnitExists fresh.
    -- Cached snapshots remain available to other consumers.
    local now=clock()
    local dirty=force==true or self.dirty or not self.current
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

-- Profile Contract v1: demand-driven, fail-closed signal provider.
-- v14 #12/#13: a readable matching aura proves presence; a nil lookup
-- cannot prove absence because access/visibility can be restricted.
function S:ReadSignal(field,spellID,snapshot)
    local function unknown(reason)
        return {status="UNKNOWN",reason=reason,source="GameState.ReadSignal"}
    end
    local api=KR.GameAPI
    if not api or type(api.IsSafeValue)~="function"
        or type(api.Read)~="function" or type(api.ReadField)~="function" then
        return unknown("signal_api_unavailable")
    end
    local ok,safeField=pcall(api.IsSafeValue,api,field)
    if not ok or safeField~=true or type(field)~="string" then
        return unknown("signal_field_unverified")
    end
    if field=="target.melee" then
        local mod=KR.AbilityEligibility
        if mod and type(mod.Fact)=="function" then
            local ok,r=pcall(mod.Fact,mod,2973,"inRange",
                {stateSnapshot=snapshot})
            if ok and type(r)=="table" and r.status=="READY"
                and type(r.value)=="boolean" and api:IsSafeValue(r.value) then
                return {status="READY",value=r.value,source="RaptorStrikeRange"}
            end
        end
        return unknown("melee_range_unverified")
    elseif field=="autoShot.active" then
        local r=self:ReadAutoShot(75)
        if r and r.active and r.active.status=="READY"
            and type(r.active.value)=="boolean"
            and api:IsSafeValue(r.active.value) then
            return {status="READY",value=r.active.value,source="AutoShot"}
        end
        return unknown("auto_shot_state_unknown")
    elseif field=="target.targetsPlayer" or field=="player.hasAggro" then
        local exists=api:Read("UnitExists","boolean","targettarget")
        if exists.status~="READY" or exists.value~=true then
            return unknown("target_target_unverified")
        end
        local relation=api:Read("UnitIsUnit","boolean","targettarget","player")
        if relation.status=="READY" and type(relation.value)=="boolean" then
            return {status="READY",value=relation.value,source="UnitIsUnit"}
        end
        return unknown("target_target_unverified")
    end
    if field~="player.buff" and field~="target.debuff" then
        return unknown("signal_provider_unimplemented")
    end
    local idOK,idSafe=pcall(api.IsSafeValue,api,spellID)
    if not idOK or idSafe~=true or not finite(spellID,1)
        or spellID~=math.floor(spellID) or spellID>99999999 then
        return unknown("aura_spell_id_unverified")
    end
    local name,unit,flag
    if field=="player.buff" then
        name,unit,flag="C_UnitAuras.GetPlayerAuraBySpellID","player","isHelpful"
    else
        name,unit,flag="C_UnitAuras.GetUnitAuraBySpellID","target","isHarmful"
    end
    -- A supplied evaluation snapshot is authoritative for player existence.
    -- A positive aura lookup must not override an unknown/absent player.
    if unit=="player" and snapshot~=nil then
        local okSnapshot,safeSnapshot=pcall(api.IsSafeValue,api,snapshot)
        if not okSnapshot or safeSnapshot~=true or type(snapshot)~="table" then
            return unknown("aura_player_unverified")
        end
        local player=api:ReadField(snapshot,"player","table")
        if player.status~="READY" then return unknown("aura_player_unverified") end
        local exists=api:ReadField(player.value,"exists","table")
        if exists.status~="READY" then return unknown("aura_player_unverified") end
        local status=api:ReadField(exists.value,"status","string")
        local present=api:ReadField(exists.value,"value","boolean")
        if status.status~="READY" or status.value~="READY"
            or present.status~="READY" or present.value~=true then
            return unknown("aura_player_unverified")
        end
    end
    -- Require a stable target identity across the aura read. An existence
    -- flag alone cannot bind an AuraData record to this evaluation's target.
    local targetGUID
    if unit=="target" then
        local okSnapshot,safeSnapshot=pcall(api.IsSafeValue,api,snapshot)
        if not okSnapshot or safeSnapshot~=true or type(snapshot)~="table" then
            return unknown("aura_target_unverified")
        end
        local target=api:ReadField(snapshot,"target","table")
        if target.status~="READY" then return unknown("aura_target_unverified") end
        local exists=api:ReadField(target.value,"exists","table")
        local guid=api:ReadField(target.value,"guid","table")
        if exists.status~="READY" or guid.status~="READY" then
            return unknown("aura_target_unverified")
        end
        local existsStatus=api:ReadField(exists.value,"status","string")
        local existsValue=api:ReadField(exists.value,"value","boolean")
        local guidStatus=api:ReadField(guid.value,"status","string")
        local guidValue=api:ReadField(guid.value,"value","string")
        if existsStatus.value~="READY" or existsValue.value~=true
            or guidStatus.value~="READY" or guidValue.status~="READY"
            or guidValue.value=="" then
            return unknown("aura_target_unverified")
        end
        targetGUID=guidValue.value
        local current=api:Read("UnitGUID","string","target")
        if current.status~="READY" or current.value~=targetGUID then
            return unknown("aura_target_changed")
        end
    end
    local r
    if unit=="player" then
        r=api:Read(name,"table",spellID)
    else
        r=api:Read(name,"table",unit,spellID)
    end
    if not r or r.status~="READY" then
        if r and (r.reason=="protected_value" or
            r.reason=="api_call_failed") then
            return unknown("aura_lookup_unverified")
        end
        -- Forever C_UnitAuras.GetAuraDataByIndex enumeration allows a
        -- complete, bounded negative scan. Nil terminator is distinct
        -- from a protected/failed entry. No false-negative guessing.
        if api:Probe("C_UnitAuras.GetAuraDataByIndex").status~="READY" then
            return unknown("aura_scan_unavailable")
        end
        local completed=false
        for index=1,64 do
            local row=api:Read("C_UnitAuras.GetAuraDataByIndex",
                "table",unit,index,unit=="target" and "HARMFUL" or "HELPFUL")
            if row.status=="UNKNOWN" and row.reason=="no_value" then
                completed=true
                break
            end
            if row.status~="READY" or not api:IsSafeValue(row.value) then
                return unknown("aura_scan_unverified")
            end
            local spell=api:ReadField(row.value,"spellId","number")
            if spell.status~="READY" then
                return unknown("aura_scan_unverified")
            end
            if spell.value==spellID then
                if unit=="target" then
                    local current=api:Read("UnitGUID","string","target")
                    if current.status~="READY" or current.value~=targetGUID then
                        return unknown("aura_target_changed")
                    end
                end
                return {status="READY",value=true,
                    source="GameState.ReadSignal.aura_scan"}
            end
        end
        if not completed then return unknown("aura_scan_limit") end
        if unit=="target" then
            local current=api:Read("UnitGUID","string","target")
            if current.status~="READY" or current.value~=targetGUID then
                return unknown("aura_target_changed")
            end
        end
        return {status="READY",value=false,
            source="GameState.ReadSignal.aura_scan"}
    end
    local id=api:ReadField(r.value,"spellId","number")
    local matching=api:ReadField(r.value,flag,"boolean")
    if not id or id.status~="READY" or id.value~=spellID
        or not matching or matching.status~="READY" or matching.value~=true then
        return unknown("aura_identity_unverified")
    end
    if unit=="target" then
        local current=api:Read("UnitGUID","string","target")
        if current.status~="READY" or current.value~=targetGUID then
            return unknown("aura_target_changed")
        end
    end
    return {status="READY",value=true,source="GameState.ReadSignal"}
end

-- v14 #24: two independent Auto Shot flags; no invented swing/queued timing.
function S:ReadAutoShot(spellID)
    if not KR.GameAPI or type(KR.GameAPI.IsSafeValue)~="function"
        or not KR.GameAPI:IsSafeValue(spellID)
        or type(spellID)~="number" or spellID~=math.floor(spellID)
        or spellID<1 or spellID>99999999 then
        return {status="UNKNOWN",reason="auto_shot_spell_id_unverified"}
    end
    local active=read("C_Spell.IsAutoRepeatSpell","boolean",spellID)
    local current=read("C_Spell.IsCurrentSpell","boolean",spellID)
    local result={active=active,current=current,spellID=spellID,
        source="GameState.ReadAutoShot",matrix=24}
    result.status=statusOf({active,current})
    if result.status~="READY" then result.reason="auto_shot_state_unknown" end
    return result
end

-- Matrix v14 #3-6: Curve-only percent probing is explicitly opt-in.
-- This does not replace numeric UnitHealth when it is already plain/readable.
function S:ReadHealthPercent(unit,curve)
    if not KR.GameAPI or type(KR.GameAPI.ReadHealthPercent)~="function" then
        return {status="UNAVAILABLE",reason="game_api_missing"}
    end
    return KR.GameAPI:ReadHealthPercent(unit,curve)
end

function S:ReadPowerPercent(unit,powerType,curve)
    if not KR.GameAPI or type(KR.GameAPI.ReadPowerPercent)~="function" then
        return {status="UNAVAILABLE",reason="game_api_missing"}
    end
    return KR.GameAPI:ReadPowerPercent(unit,powerType,curve)
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
