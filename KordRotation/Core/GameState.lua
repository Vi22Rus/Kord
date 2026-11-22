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
        -- A classification is an ordinary direct v14 signal when the client
        -- supplies it. Never infer elite/normal from level or health.
        local classification=read("UnitClassification","string","target")
        if classification.status=="READY" and
            (classification.value=="normal" or classification.value=="elite"
            or classification.value=="rare" or classification.value=="rareelite"
            or classification.value=="worldboss" or classification.value=="trivial"
            or classification.value=="minus") then
            record.classification=classification
        else
            record.classification=invalid(classification,"classification_unverified")
        end
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
        -- WoW Forever next-swing skills (including Raptor Strike) can
        -- report IsSpellInRange=true far outside melee. Never use that
        -- boolean to establish distance. JustAC's Forever reference
        -- uses C_SwingTimer.IsTargetWithinSwingRange(0) instead.
        local target=type(snapshot)=="table" and api:IsSafeValue(snapshot)
            and api:ReadField(snapshot,"target","table") or nil
        if not target or target.status~="READY" then
            return unknown("melee_target_unverified")
        end
        local identity=api:ReadField(target.value,"guid","table")
        local exists=api:ReadField(target.value,"exists","table")
        if identity.status~="READY" or exists.status~="READY" then
            return unknown("melee_target_unverified")
        end
        local guid=api:ReadField(identity.value,"value","string")
        local gStatus=api:ReadField(identity.value,"status","string")
        local present=api:ReadField(exists.value,"value","boolean")
        local eStatus=api:ReadField(exists.value,"status","string")
        if guid.status~="READY" or guid.value==""
            or gStatus.status~="READY" or gStatus.value~="READY"
            or present.status~="READY" or present.value~=true
            or eStatus.status~="READY" or eStatus.value~="READY" then
            return unknown("melee_target_unverified")
        end
        local function sameTarget()
            local current=api:Read("UnitGUID","string","target")
            return current.status=="READY" and current.value==guid.value
        end
        if not sameTarget() then return unknown("melee_target_changed") end
        local swing=api:Read("C_SwingTimer.IsTargetWithinSwingRange","boolean",0)
        local value,source
        if swing.status=="READY" then
            value,source=swing.value,"C_SwingTimer.IsTargetWithinSwingRange"
        else
            -- A confirmed OUTSIDE the ~10-yard duel interaction band
            -- disproves melee. Being inside it does NOT prove 5 yards.
            local interact=api:Read("CheckInteractDistance","boolean","target",3)
            if interact.status=="READY" and interact.value==false then
                value,source=false,"CheckInteractDistance"
            end
        end
        if not sameTarget() then return unknown("melee_target_changed") end
        if type(value)=="boolean" and api:IsSafeValue(value) then
            return {status="READY",value=value,source=source}
        end
        return unknown("melee_range_unverified")
    elseif field=="player.travelAspect" then
        -- Cheetah and Pack are the movement aspects. Use the existing
        -- protected-aware aura provider; only two confirmed absences
        -- establish false. A failed scan is UNKNOWN, never false.
        local cheetah=self:ReadSignal("player.buff",5118,snapshot)
        if cheetah.status=="READY" and cheetah.value==true then
            if cheetah.source~="AuraEvidence.own_or_live_positive"
                and KR.AuraEvidence and KR.AuraEvidence.ObserveLive then
                KR.AuraEvidence:ObserveLive(5118)
            end
            return {status="READY",value=true,source="TravelAspectAuras"}
        end
        local pack=self:ReadSignal("player.buff",13159,snapshot)
        if pack.status=="READY" and pack.value==true then
            if pack.source~="AuraEvidence.own_or_live_positive"
                and KR.AuraEvidence and KR.AuraEvidence.ObserveLive then
                KR.AuraEvidence:ObserveLive(13159)
            end
            return {status="READY",value=true,source="TravelAspectAuras"}
        end
        if cheetah.status=="READY" and cheetah.value==false
            and pack.status=="READY" and pack.value==false then
            return {status="READY",value=false,source="TravelAspectAuras"}
        end
        -- Sonah's C.buff + C.no(C.consumed(...)) remembers a confirmed
        -- travel aspect until our successful combat-aspect cast consumed it.
        -- This permits the combat safety recommendation even when the
        -- client hides aura details on entering combat.
        if KR.AuraEvidence and KR.AuraEvidence.ReadTravel then
            local past=KR.AuraEvidence:ReadTravel()
            if past and past.status=="READY" and past.value==true then
                return past
            end
        end
        return unknown("travel_aspect_aura_unverified")
    elseif field=="autoShot.active" then
        local r=self:ReadAutoShot(75)
        if r and r.active and r.active.status=="READY"
            and type(r.active.value)=="boolean"
            and api:IsSafeValue(r.active.value) then
            return {status="READY",value=r.active.value,source="AutoShot"}
        end
        return unknown("auto_shot_state_unknown")
    elseif field=="target.targetsPlayer" or field=="player.hasAggro" then
        -- Tie the target-of-target query to the SAME target as the
        -- evaluation snapshot. Otherwise a target switch between the
        -- snapshot and UnitIsUnit may attribute aggro to another mob.
        if type(snapshot)~="table" or not api:IsSafeValue(snapshot) then
            return unknown("target_snapshot_unverified")
        end
        local target=api:ReadField(snapshot,"target","table")
        if target.status~="READY" then
            return unknown("target_snapshot_unverified")
        end
        local present=api:ReadField(target.value,"exists","table")
        local identity=api:ReadField(target.value,"guid","table")
        if present.status~="READY" or identity.status~="READY" then
            return unknown("target_snapshot_unverified")
        end
        local pStatus=api:ReadField(present.value,"status","string")
        local pValue=api:ReadField(present.value,"value","boolean")
        local gStatus=api:ReadField(identity.value,"status","string")
        local gValue=api:ReadField(identity.value,"value","string")
        if pStatus.status~="READY" or pStatus.value~="READY"
            or pValue.status~="READY" or pValue.value~=true
            or gStatus.status~="READY" or gStatus.value~="READY"
            or gValue.status~="READY" or gValue.value=="" then
            return unknown("target_snapshot_unverified")
        end
        local function sameTarget()
            local current=api:Read("UnitGUID","string","target")
            return current.status=="READY" and current.value==gValue.value
        end
        if not sameTarget() then return unknown("target_changed") end
        local exists=api:Read("UnitExists","boolean","targettarget")
        local relation
        if exists.status=="READY" and exists.value==false then
            relation=false
        elseif exists.status=="READY" and exists.value==true then
            local check=api:Read("UnitIsUnit","boolean","targettarget","player")
            if check.status=="READY" and type(check.value)=="boolean"
                and api:IsSafeValue(check.value) then
                relation=check.value
            end
        end
        if not sameTarget() then return unknown("target_changed") end
        if type(relation)=="boolean" then
            return {status="READY",value=relation,source="UnitIsUnit"}
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
        -- ForeverAuras/BuffTrigger2.lua SafeForEachAura: a generic
        -- targeted spell-ID query can still return an aura when the
        -- player-specific lookup did not. Verify the exact ID and flag.
        if unit=="player" then
            local generic=api:Read("C_UnitAuras.GetUnitAuraBySpellID",
                "table","player",spellID)
            if generic.status=="READY" then
                local sid=api:ReadField(generic.value,"spellId","number")
                local help=api:ReadField(generic.value,"isHelpful","boolean")
                if sid.status=="READY" and sid.value==spellID
                    and help.status=="READY" and help.value==true then
                    if KR.AuraCooldownViewer then
                        KR.AuraCooldownViewer:Observe(spellID,true)
                    end
                    return {status="READY",value=true,
                        source="GameState.ReadSignal.aura_unit_id"}
                end
            end
        end
        -- Sonah/Core/Atoms/Auras.lua ReadApi: try an address-based
        -- localized spell-name lookup before any list enumeration.
        -- This is a documented third lookup, not a fabricated aura scan.
        -- A nil by-name response only proves absence when the client
        -- positively confirms that auras are not secret.
        local spellInfo=api:Read("C_Spell.GetSpellInfo","table",spellID)
        local localized
        if spellInfo.status=="READY" then
            local n=api:ReadField(spellInfo.value,"name","string")
            if n.status=="READY" and n.value~="" then localized=n.value end
        end
        if not localized then
            local legacy=api:ReadValues("GetSpellInfo",spellID)
            if legacy.status=="READY" then
                local n=legacy.value and legacy.value[1]
                if type(n)=="string" and n~="" and api:IsSafeValue(n) then
                    localized=n
                end
            end
        end
        if localized then
            local byName=api:Read("C_UnitAuras.GetAuraDataBySpellName",
                "table",unit,localized,unit=="target" and "HARMFUL" or "HELPFUL")
            if byName.status=="READY" then
                local spell=api:ReadField(byName.value,"spellId","number")
                local kind=api:ReadField(byName.value,flag,"boolean")
                if spell.status=="READY" and spell.value==spellID
                    and kind.status=="READY" and kind.value==true then
                    if unit=="player" and KR.AuraCooldownViewer then
                        KR.AuraCooldownViewer:Observe(spellID,true)
                    end
                    return {status="READY",value=true,
                        source="GameState.ReadSignal.aura_name"}
                end
                -- A different rank/name collision is not proof.
                return unknown("aura_identity_unverified")
            end
            -- A missing by-name aura is only absent when secret mode is
            -- explicitly FALSE. In hidden mode, Sonah returns nil.
            if byName.reason=="no_value" then
                local mode=api:Read("C_Secrets.ShouldAurasBeSecret","boolean")
                if mode.status=="READY" and mode.value==false then
                    if unit=="target" then
                        local current=api:Read("UnitGUID","string","target")
                        if current.status~="READY" or current.value~=targetGUID then
                            return unknown("aura_target_changed")
                        end
                    end
                    if unit=="player" and KR.AuraCooldownViewer then
                        KR.AuraCooldownViewer:Observe(spellID,false)
                    end
                    return {status="READY",value=false,
                        source="GameState.ReadSignal.aura_name"}
                end
            end
        end
        -- Rotation Master Platform/cooldown_viewer.lua: Blizzard's
        -- Cooldown Manager exposes a plain tracked presence bit even when
        -- auraInstanceID is secret. This is a read-only fallback, no
        -- custom protected aura scan and no guessed raw secret value.
        if KR.AuraCooldownViewer and
            type(KR.AuraCooldownViewer.GetPresence)=="function" then
            local present=KR.AuraCooldownViewer:GetPresence(spellID,unit)
            if type(present)=="boolean" then
                return {status="READY",value=present,
                    source="AuraCooldownViewer"}
            end
        end
        -- Sonah Auras.lua tracks positive self-cast aspects when the live
        -- aura API becomes unreadable. This is only positive evidence;
        -- no history never means the aura is absent.
        if unit=="player" and KR.AuraEvidence and
            type(KR.AuraEvidence.Read)=="function" then
            local past=KR.AuraEvidence:Read(spellID)
            if past and past.status=="READY" and past.value==true then
                return past
            end
        end
        -- Sonah Secret.AurasHidden and ForeverAuras BuffTrigger2 establish:
        -- while auras are secret, enumeration may throw even though the
        -- direct known-ID lookup returned no aura. This is UNKNOWN, not
        -- proof of absence. Never call the denied batch/index APIs.
        local secrecy=api:Read("C_Secrets.ShouldAurasBeSecret","boolean")
        if secrecy.status=="READY" and secrecy.value==true then
            -- Rotation Master Core/aura_conditions.lua lastRead fallback:
            -- keep an explicitly observed clean absence. Unlike RM's
            -- implicit initial absence, an unobserved hidden aura is
            -- still UNKNOWN in the Kord v14 strict evidence contract.
            if unit=="player" and KR.AuraCooldownViewer and
                KR.AuraCooldownViewer:GetObserved(spellID)==false then
                return {status="READY",value=false,
                    source="AuraCooldownViewer.last_read_absent"}
            end
            return unknown("aura_hidden_by_client")
        end
        -- Sonah Secret.RestrictionsActive falls back to combat lockdown
        -- when the dedicated aura secrecy predicate is unreadable.
        -- This only makes the decision more conservative; no claimed
        -- absent aura can be produced from hidden combat state.
        if secrecy.status~="READY" then
            local lockdown=api:Read("InCombatLockdown","boolean")
            if lockdown.status~="READY" or lockdown.value==true then
                return unknown("aura_secrecy_unverified")
            end
        end
        -- Prefer a single validated batch read, as in the ForeverAuras /
        -- JustAC reference implementations. A protected field is UNKNOWN,
        -- never evidence of aura absence. A completed plain list is
        -- authoritative for this unit/filter at the time of observation.
        if api:Probe("C_UnitAuras.GetUnitAuras").status=="READY" then
            local batch=api:Read("C_UnitAuras.GetUnitAuras","table",
                unit,unit=="target" and "HARMFUL" or "HELPFUL")
            if batch.status=="READY" then
                local items=batch.value
                local count=0
                local complete=true
                local match=false
                local okScan=pcall(function()
                    -- Reject sparse/extra-key tables: ipairs otherwise stops at
                    -- the first hole and could fabricate a negative scan.
                    local size=0
                    for key in pairs(items) do
                        if type(key)~="number" or key~=math.floor(key)
                            or key<1 or key>256 then
                            complete=false
                            break
                        end
                        size=size+1
                    end
                    if complete then
                        for index=1,size do
                            if rawget(items,index)==nil then
                                complete=false
                                break
                            end
                        end
                    end
                    if not complete then return end
                    for index,aura in ipairs(items) do
                        count=count+1
                        if count>256 then complete=false break end
                        local spell=api:ReadField(aura,"spellId","number")
                        if spell.status~="READY" then
                            complete=false
                            break
                        end
                        if spell.value==spellID then
                            local kind=api:ReadField(aura,flag,"boolean")
                            if kind.status~="READY" then
                                complete=false
                            elseif kind.value==true then
                                match=true
                            end
                            break
                        end
                    end
                end)
                if not okScan then complete=false end
                if unit=="target" then
                    local current=api:Read("UnitGUID","string","target")
                    if current.status~="READY" or current.value~=targetGUID then
                        return unknown("aura_target_changed")
                    end
                end
                if match then
                    return {status="READY",value=true,
                        source="GameState.ReadSignal.aura_batch"}
                end
                if complete then
                    return {status="READY",value=false,
                        source="GameState.ReadSignal.aura_batch"}
                end
                return unknown("aura_batch_fields_unverified")
            end
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
    if unit=="player" and KR.AuraCooldownViewer then
        KR.AuraCooldownViewer:Observe(spellID,true)
    end
    return {status="READY",value=true,source="GameState.ReadSignal"}
end

-- IT-01 / 1.1: one logical inventory observation, never a bag scanner.
-- No item read API or catalogue is validated yet; every derived observation
-- uses this shared, fail-closed base and never implies count=0 or READY.
local function inventoryObservation(reason)
    return {
        status="UNKNOWN",
        source="GameState.InventoryObservation",
        reason=reason or "inventory_reader_unverified",
        scope="BAGS_ONLY",
        inventoryScope="BAGS_ONLY",
        -- revision/bagRevision/catalogRevision/observedAt are intentionally
        -- absent until the corresponding sources are validated.
    }
end

local function inventorySafeID(value, kind)
    local api=KR.GameAPI
    if not api or type(api.IsSafeValue)~="function" then return false end
    local ok,safe=pcall(api.IsSafeValue,api,value)
    if not ok or safe~=true then return false end
    if kind=="item" then
        return type(value)=="number" and value==math.floor(value)
            and value>0 and value<math.huge
    end
    return type(value)=="string" and #value>0
end

function S:ReadInventoryObservation()
    local result=inventoryObservation()
    result.items={}
    result.families={}
    return result
end

-- IT-01/1.2: source-supported C_Item reader; in-game Forever QA pending.
-- The API read is protected by GameAPI:Read (pcall/secret/nil/type).
-- This is a bag-count observation, NOT item usability or an action.
function S:ReadInventoryItemObservation(itemID)
    local result=inventoryObservation("inventory_reader_unverified")
    result.source="GameState.InventoryItemObservation"
    if not inventorySafeID(itemID,"item") then
        result.reason="item_id_unverified"
        return result
    end
    result.itemID=itemID
    local count=read("C_Item.GetItemCount","number",itemID,false,false)
    if not count or count.status~="READY" then
        result.reason=count and count.reason or "inventory_reader_unavailable"
        if count and count.reason=="protected_value" then
            result.reason="item_count_secret"
        end
        if count then result.observedAt=count.observedAt end
        return result
    end
    local value=count.value
    if not finite(value,0) or value~=math.floor(value) then
        result.reason="item_count_invalid"
        return result
    end
    result.count=value
    result.status="READY"
    result.reason=nil
    result.apiSource=count.source
    result.observedAt=count.observedAt
    -- false/false BAGS_ONLY semantics are source-supported, client NOT RUN.
    return result
end

function S:ReadInventoryFamilyObservation(familyID)
    local result=inventoryObservation("item_family_catalog_unverified")
    result.source="GameState.InventoryFamilyObservation"
    if inventorySafeID(familyID,"family") then
        result.familyID=familyID
    else
        result.reason="item_family_id_unverified"
    end
    return result
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
