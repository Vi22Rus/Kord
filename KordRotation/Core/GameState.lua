-- Kord Rotation (c) 2026 Vi22Rus. All rights reserved.
-- Stage 2.3: conservative read-only player/target/combat snapshot.
-- No recommendation, button pressing or protected gameplay action occurs here.
local addonName, KR = ...
KR.GameState = KR.GameState or {}
local S = KR.GameState

local watched = {
    "identity", "target", "combat", "health", "resources", "cast",
    "talents", "heartbeat", "auras", "cooldowns", "itemCooldown", "pet",
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

-- Optional EventBus revision evidence; absent bus must remain unverified.
local function inventoryBagRevision()
    local bus=KR.EventBus
    if not bus or type(bus.GetInventoryRevision)~="function" then return nil end
    local ok,value=pcall(bus.GetInventoryRevision,bus)
    if not ok or not finite(value,0) or value~=math.floor(value) then
        return nil
    end
    return value
end

function S:ReadInventoryObservation()
    local result=inventoryObservation()
    result.items={}
    result.families={}
    result.bagRevision=inventoryBagRevision()
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
    local startRevision=inventoryBagRevision()
    local count=read("C_Item.GetItemCount","number",itemID,false,false)
    local endRevision=inventoryBagRevision()
    if startRevision~=endRevision then
        result.reason="item_bag_revision_changed"
        return result
    end
    result.bagRevision=endRevision
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

-- IT-01/1.3: a single bounded, on-demand snapshot of source-supported
-- player bag indices 0..4; no equipped, bank or reagent bank scanning.
-- The mapping of those indices to bags on the target Forever build is
-- still CLIENT NOT RUN. This reader does not issue item-use eligibility.
local INVENTORY_BAGS={0,1,2,3,4}
local MAX_INVENTORY_SLOTS_PER_BAG=80

function S:ReadInventoryBagSnapshot()
    local result=inventoryObservation("bag_reader_unverified")
    result.source="GameState.InventoryBagSnapshot"
    result.bagIDs={0,1,2,3,4}
    result.scopeEvidence="source_supported_bag_ids_pending_forever_qa"
    result.complete=false
    local startRevision=inventoryBagRevision()

    local api=KR.GameAPI
    if not api or type(api.Read)~="function"
        or type(api.ReadField)~="function"
        or type(api.Probe)~="function" then
        result.reason="bag_api_adapter_missing"
        return result
    end
    local methods={
        "C_Container.GetContainerNumSlots",
        "C_Container.GetContainerItemID",
        "C_Container.GetContainerItemInfo",
    }
    for _,name in ipairs(methods) do
        local capability=api:Probe(name)
        if not capability or capability.status~="READY" then
            result.reason="bag_api_missing"
            return result
        end
    end

    local counts={}
    local visited=0
    for _,bagID in ipairs(INVENTORY_BAGS) do
        local slots=api:Read("C_Container.GetContainerNumSlots","number",bagID)
        if slots.status~="READY" or not finite(slots.value,0)
            or slots.value~=math.floor(slots.value)
            or slots.value>MAX_INVENTORY_SLOTS_PER_BAG then
            result.reason="item_bag_scan_incomplete"
            return result
        end
        for slot=1,slots.value do
            visited=visited+1
            local id=api:Read("C_Container.GetContainerItemID","number",bagID,slot)
            local info=api:Read("C_Container.GetContainerItemInfo","table",bagID,slot)
            if id.status=="UNKNOWN" and id.reason=="no_value"
                and info.status=="UNKNOWN" and info.reason=="no_value" then
                -- Both independent sources report an empty slot.
            elseif id.status=="READY" and info.status=="READY" then
                local itemID=id.value
                if not finite(itemID,1) or itemID~=math.floor(itemID) then
                    result.reason="item_bag_scan_incomplete"
                    return result
                end
                local amount=api:ReadField(info.value,"stackCount","number")
                if amount.status~="READY" or not finite(amount.value,1)
                    or amount.value~=math.floor(amount.value) then
                    result.reason="item_bag_scan_incomplete"
                    return result
                end
                local identity=api:ReadField(info.value,"itemID","number")
                if identity.status~="READY"
                    or identity.value~=itemID then
                    result.reason="item_bag_scan_incomplete"
                    return result
                end
                counts[itemID]=(counts[itemID] or 0)+amount.value
            else
                result.reason="item_bag_scan_incomplete"
                return result
            end
        end
    end
    local endRevision=inventoryBagRevision()
    if endRevision~=startRevision then
        result.reason="item_bag_revision_changed"
        return result
    end
    result.bagRevision=endRevision
    result.status="READY"
    result.reason=nil
    result.complete=true
    result.countsByID=counts
    result.visitedSlots=visited
    return result
end

-- IT-01/1.5: one functional family -> one set of distinct itemID reads.
-- No independent bag scanner, no bank/equipped item counts, no item-use gate.
-- Results represent a bounded sequence of reads: atomic inventory revision
-- checks are deferred to IT-01/1.6, never claimed by this observation.
function S:ReadInventoryFamilyObservation(familyID)
    local result=inventoryObservation("item_family_catalog_unverified")
    result.source="GameState.InventoryFamilyObservation"
    if not inventorySafeID(familyID,"family") then
        result.reason="item_family_id_unverified"
        return result
    end
    result.familyID=familyID
    local catalog=KR.ItemFamilyCatalog
    if not catalog or type(catalog.GetFamily)~="function"
        or type(catalog.GetRevision)~="function" then
        result.reason="item_family_catalog_unavailable"
        return result
    end
    local ok,entry=pcall(catalog.GetFamily,catalog,familyID)
    if not ok or type(entry)~="table" then
        result.reason="item_family_catalog_unavailable"
        return result
    end
    if entry.status~="READY" then
        result.reason=entry.reason or "item_family_unknown"
        return result
    end
    local ids=entry.itemIDs
    if type(ids)~="table" or #ids<1 or #ids>256
        or not inventorySafeID(entry.familyID,"family")
        or entry.familyID~=familyID then
        result.reason="item_family_catalog_invalid"
        return result
    end
    local revisionOK,revision=pcall(catalog.GetRevision,catalog)
    if not revisionOK or not finite(revision,1)
        or revision~=math.floor(revision) or revision~=entry.revision then
        result.reason="item_catalog_revision_changed"
        return result
    end
    result.catalogRevision=revision
    local startBagRevision=inventoryBagRevision()

    local distinct,seen={},{}
    for index=1,#ids do
        local id=ids[index]
        if not inventorySafeID(id,"item") then
            result.reason="item_family_catalog_invalid"
            return result
        end
        if not seen[id] then
            seen[id]=true
            distinct[#distinct+1]=id
        end
    end
    -- The family members are independently reported even when count is
    -- incomplete; there is never a fabricated zero for a missing reader.
    result.knownItemIDs=distinct
    local knownCounts={}
    local subtotal,known,unknown=0,0,0
    for _,itemID in ipairs(distinct) do
        local readOK,item=pcall(self.ReadInventoryItemObservation,self,itemID)
        local valid=readOK and type(item)=="table"
            and item.status=="READY" and item.itemID==itemID
            and item.inventoryScope=="BAGS_ONLY"
            and finite(item.count,0) and item.count==math.floor(item.count)
        if valid then
            if not finite(subtotal+item.count,0) then
                result.reason="item_family_count_overflow"
                return result
            end
            knownCounts[itemID]=item.count
            subtotal=subtotal+item.count
            known=known+1
        else
            unknown=unknown+1
        end
    end
    local stable,newRevision=pcall(catalog.GetRevision,catalog)
    if not stable or newRevision~=revision then
        result.reason="item_catalog_revision_changed"
        return result
    end
    local endBagRevision=inventoryBagRevision()
    if startBagRevision~=endBagRevision then
        result.reason="item_bag_revision_changed"
        return result
    end
    result.bagRevision=endBagRevision
    result.countsByID=knownCounts
    result.knownComponents=known
    result.unknownComponents=unknown
    if unknown>0 then
        result.reason="item_family_partial"
        if known>0 then result.knownMinimum=subtotal end
        return result
    end
    result.status="READY"
    result.reason=nil
    result.count=subtotal
    -- 'READY' here proves only the model's complete scalar observation.
    -- No item usable/cooldown/combat eligibility follows from family count.
    return result
end

-- IT-02/2.2-2.3: read-only item-specific cooldown observation.
-- A valid item cooldown is NOT proof of usable item or shared group readiness.
-- C_Container accepts bag/slot, not an itemID: never guess a slot identity.
local function unknownItemCooldown(reason,source)
    return {status="UNKNOWN",reason=reason,source=source}
end
local function itemCooldownEnabled(value)
    if value==true or value==1 then return true end
    if value==false or value==0 then return false end
    return nil
end
local function itemCooldownTuple(api,raw)
    if type(raw)~="table" or raw.status~="READY" then
        return nil,"item_cd_invalid_tuple"
    end
    local values=raw.value
    if type(values)~="table" then return nil,"item_cd_invalid_tuple" end
    local start,duration,enabled
    if type(values[1])=="table" then
        -- Some API revisions expose a structured cooldown result.
        local data=values[1]
        local a=api:ReadField(data,"startTime","number")
        local b=api:ReadField(data,"duration","number")
        local c=api:ReadField(data,"isEnabled")
        if a.status~="READY" or b.status~="READY" or c.status~="READY" then
            return nil,"item_cd_invalid_tuple"
        end
        start,duration,enabled=a.value,b.value,c.value
    else
        start,duration,enabled=values[1],values[2],values[3]
    end
    if not finite(start,0) or not finite(duration,0) then
        return nil,"item_cd_invalid_tuple"
    end
    -- Only the exact (0,0) tuple supports a confirmed idle cooldown.
    -- A mixed-zero tuple does not prove the previous cooldown expired.
    if (start==0) ~= (duration==0) then
        return nil,"item_cd_invalid_tuple"
    end
    local usable=itemCooldownEnabled(enabled)
    if usable==nil then return nil,"item_cd_invalid_tuple" end
    if not usable then return nil,"item_cd_disabled" end
    return {startTime=start,duration=duration,enabled=true}
end

function S:ReadItemCooldownObservation(itemID)
    local result=unknownItemCooldown("item_cd_api_missing",
        "GameState.ItemCooldownObservation")
    if not inventorySafeID(itemID,"item") then
        result.reason="item_cd_id_unverified"
        return result
    end
    result.itemID=itemID
    local api=KR.GameAPI
    if not api or type(api.ReadValues)~="function"
        or type(api.Read)~="function" then return result end
    local bus=KR.EventBus
    local function cooldownRevision()
        if not bus or type(bus.GetItemCooldownRevision)~="function" then return nil end
        local ok,value=pcall(bus.GetItemCooldownRevision,bus)
        if ok and finite(value,0) and value==math.floor(value) then return value end
        return nil
    end
    local initialRevision=cooldownRevision()
    -- Only fallback if the first API is absent; secret, error, malformed
    -- or disabled results must not become an invented READY via fallback.
    local candidates={"C_Item.GetItemCooldown","GetItemCooldown"}
    for _,name in ipairs(candidates) do
        local ok,raw=pcall(api.ReadValues,api,name,itemID)
        if not ok or type(raw)~="table" then
            result.reason="item_cd_read_failed"
            return result
        end
        if raw.status~="UNAVAILABLE" or raw.reason~="api_missing" then
            result.source=name
            if raw.status~="READY" then
                result.reason=raw.reason=="protected_value"
                    and "item_cd_secret" or "item_cd_invalid_tuple"
                return result
            end
            -- Structured cooldown values may contain protected/secret fields.
            -- Normalize under pcall; any access fault stays UNKNOWN.
            local normalized,fields,reason=pcall(itemCooldownTuple,api,raw)
            if not normalized then
                result.reason="item_cd_secret"
                return result
            end
            if not fields then result.reason=reason return result end
            local clockOK,clock=pcall(api.Read,api,"GetTime","number")
            if not clockOK or type(clock)~="table" or clock.status~="READY"
                or not finite(clock.value,0) then
                result.reason="item_cd_remaining_unknown"
                return result
            end
            local now=clock.value
            -- Discontinuous/foreign epoch: never turn it into READY.
            if fields.startTime>now or not finite(fields.startTime+fields.duration,0) then
                result.reason="item_cd_remaining_unknown"
                return result
            end
            local remaining=math.max(0,fields.startTime+fields.duration-now)
            if not finite(remaining,0) then
                result.reason="item_cd_remaining_unknown"
                return result
            end
            local finalRevision=cooldownRevision()
            if initialRevision~=finalRevision then
                result.reason="item_cd_revision_changed"
                return result
            end
            result.revision=finalRevision
            -- An individual zero does not clear shared potion lockout.
            result.status="READY"
            result.reason=nil
            result.startTime=fields.startTime
            result.duration=fields.duration
            result.remaining=remaining
            result.enabled=true
            result.active=remaining>0
            -- IT-02/2.4: READY is only itemID-specific cooldown evidence.
            -- Never reuse it to imply a clear GCD, combat gate, bag count,
            -- charges, or item usability. Separate providers own those facts.
            result.cooldownScope="ITEM_SPECIFIC"
            result.gcdStatus="UNKNOWN"
            result.combatUseStatus="UNKNOWN"
            result.inventoryStatus="UNKNOWN"
            result.chargesStatus="UNKNOWN"
            result.usabilityStatus="UNKNOWN"
            result.observedAt=now
            -- Revision follows in IT-02/2.7; absent revision is not zero.
            return result
        end
    end
    return result
end

-- IT-02/2.6 (partial): the one shared group catalog is the sole
-- source of group identity. Membership candidates alone are NOT cooldown
-- evidence. Until correlated use / validated cooldown facts exist, fail closed.
function S:ReadSharedItemCooldownObservation(groupID)
    local result=unknownItemCooldown("item_cd_group_unknown",
        "GameState.SharedItemCooldownObservation")
    if not inventorySafeID(groupID,"family") then
        result.reason="item_cd_group_id_unverified"
        return result
    end
    result.groupID=groupID
    result.groupStatus="UNKNOWN"
    local catalog=KR.SharedCooldownGroupCatalog
    if not catalog or type(catalog.GetGroup)~="function" then
        result.reason="item_cd_group_catalog_missing"
        return result
    end
    local ok,group=pcall(catalog.GetGroup,catalog,groupID)
    local api=KR.GameAPI
    if not ok or type(group)~="table" or not api
        or type(api.IsSafeValue)~="function" then
        result.reason="item_cd_group_catalog_invalid"
        return result
    end
    local safeOk,isSafe=pcall(api.IsSafeValue,api,group)
    if not safeOk or isSafe~=true then
        result.reason="item_cd_group_catalog_invalid"
        return result
    end
    -- A catalogue table may carry protected fields or metatable accessors.
    -- Both field extraction and scalar safety checks must be guarded.
    local fieldsOK,status,identity,reason,verification=pcall(function()
        return group.status,group.groupID,group.reason,group.verification
    end)
    if not fieldsOK then
        result.reason="item_cd_group_catalog_invalid"
        return result
    end
    local safetyOK,fieldsSafe=pcall(function()
        return api:IsSafeValue(status) and api:IsSafeValue(identity)
            and api:IsSafeValue(reason)
            and (verification==nil or api:IsSafeValue(verification))
    end)
    if not safetyOK or not fieldsSafe
        or status~="UNKNOWN" or identity~=groupID then
        result.reason="item_cd_group_catalog_invalid"
        return result
    end
    if reason=="item_cd_group_unverified"
        and verification=="PENDING_FOREVER" then
        result.reason="item_cd_group_partial"
        result.catalogSource="SharedCooldownGroupCatalog"
        result.verification="PENDING_FOREVER"
        -- Candidate item IDs are source data, not shared-lockout evidence.
        -- Export only bounded aggregate count, never mutable IDs to profiles.
        if type(catalog.GetCandidateMembers)=="function" then
            local candidatesOK,candidates=pcall(catalog.GetCandidateMembers,catalog,groupID)
            if candidatesOK and type(candidates)=="table" then
                local checked,count=pcall(function()
                    if candidates.status~="UNKNOWN"
                        or candidates.reason~="item_cd_use_attribution_unknown"
                        or candidates.groupID~=groupID
                        or not api:IsSafeValue(candidates.candidateCount)
                        or type(candidates.candidateCount)~="number"
                        or candidates.candidateCount<1 or candidates.candidateCount>32
                        or candidates.candidateCount~=math.floor(candidates.candidateCount) then
                        return nil
                    end
                    return candidates.candidateCount
                end)
                if checked and count then result.candidateCount=count end
            end
        end
        -- Prepare a unique source-only spell map on demand; never in Tick.
        if type(catalog.PrepareUseSpellIndex)=="function" then
            pcall(catalog.PrepareUseSpellIndex,catalog,groupID)
        end
        local useOK,observed=pcall(self.ReadObservedItemUse,self,groupID)
        if useOK and type(observed)=="table" then
            local valid,accepted,observedAt=pcall(function()
                return api:IsSafeValue(observed)
                    and observed.reason=="item_cd_use_attribution_estimated"
                    and observed.confidence=="ESTIMATED"
                    and api:IsSafeValue(observed.observedAt)
                    and finite(observed.observedAt,0),observed.observedAt
            end)
            if valid and accepted then
                result.useAttribution="ESTIMATED"
                result.useObservedAt=observedAt
            end
        end
        -- Reuse the single bounded member-evidence pipeline. Source-only
        -- confidence must never become a group READY or numeric remaining.
        if type(self.ReadSharedItemCooldownMemberEvidence)=="function" then
            local okEvidence,evidence=pcall(self.ReadSharedItemCooldownMemberEvidence,
                self,groupID)
            if okEvidence and type(evidence)=="table" then
                local checked,fields=pcall(function()
                    if not api:IsSafeValue(evidence)
                        or evidence.groupID~=groupID
                        or evidence.status~="UNKNOWN"
                        or evidence.groupStatus~="UNKNOWN"
                        or evidence.candidateCount~=result.candidateCount
                        or not api:IsSafeValue(evidence.itemCooldownConfidence)
                        or not api:IsSafeValue(evidence.groupLockoutConfidence)
                        or not api:IsSafeValue(evidence.groupReadyConfidence)
                        or (evidence.itemCooldownConfidence~="CONFIRMED"
                            and evidence.itemCooldownConfidence~="UNKNOWN")
                        or (evidence.groupLockoutConfidence~="ESTIMATED"
                            and evidence.groupLockoutConfidence~="UNKNOWN")
                        or evidence.groupReadyConfidence~="UNKNOWN"
                        or not api:IsSafeValue(evidence.useCorrelation)
                        or (evidence.useCorrelation~="ESTIMATED"
                            and evidence.useCorrelation~="UNKNOWN")
                        or not api:IsSafeValue(evidence.propagationEvidence)
                        or (evidence.propagationEvidence~="ALIGNED_CANDIDATES"
                            and evidence.propagationEvidence~="SINGLE_CANDIDATE"
                            and evidence.propagationEvidence~="MIXED_CANDIDATES"
                            and evidence.propagationEvidence~="UNKNOWN")
                        or (evidence.groupLockoutConfidence=="ESTIMATED"
                            and (evidence.useCorrelation~="ESTIMATED"
                                or evidence.propagationEvidence~="ALIGNED_CANDIDATES"))
                        or not api:IsSafeValue(evidence.itemCooldownRevision)
                        or not api:IsSafeValue(evidence.inventoryRevision)
                        or not api:IsSafeValue(evidence.familyRevision)
                        or not finite(evidence.itemCooldownRevision,0)
                        or not finite(evidence.inventoryRevision,0)
                        or not finite(evidence.familyRevision,1) then
                        return nil
                    end
                    return {item=evidence.itemCooldownConfidence,
                        group=evidence.groupLockoutConfidence,
                        ready=evidence.groupReadyConfidence,
                        useCorrelation=evidence.useCorrelation,
                        propagation=evidence.propagationEvidence,
                        itemRev=evidence.itemCooldownRevision,
                        bagRev=evidence.inventoryRevision,
                        familyRev=evidence.familyRevision}
                end)
                if checked and fields then
                    result.itemCooldownConfidence=fields.item
                    result.groupLockoutConfidence=fields.group
                    result.groupReadyConfidence=fields.ready
                    result.useCorrelation=fields.useCorrelation
                    result.propagationEvidence=fields.propagation
                    result.itemCooldownRevision=fields.itemRev
                    result.inventoryRevision=fields.bagRev
                    result.familyRevision=fields.familyRev
                end
            end
        end
    elseif reason=="item_cd_group_unknown" then
        result.reason="item_cd_group_unknown"
    else
        result.reason="item_cd_group_catalog_invalid"
    end
    -- No remaining, active or revision is inferred from family membership.
    return result
end

-- IT-02/2.6: explicit, bounded member-cooldown evidence on demand.
-- Inventory membership and shared-lockout semantics remain unverified.
-- No scheduled scans, no item use, and NEVER a group READY decision.
function S:ReadSharedItemCooldownMemberEvidence(groupID)
    local result={status="UNKNOWN",groupStatus="UNKNOWN",
        reason="item_cd_use_attribution_unknown",
        source="GameState.SharedItemCooldownMemberEvidence"}
    if not inventorySafeID(groupID,"family") then
        result.reason="item_cd_group_id_unverified"
        return result
    end
    result.groupID=groupID
    local catalog=KR.SharedCooldownGroupCatalog
    local api=KR.GameAPI
    if not catalog or type(catalog.GetCandidateMembers)~="function"
        or not api or type(api.IsSafeValue)~="function" then
        result.reason="item_cd_group_catalog_missing"
        return result
    end
    local ok,candidates=pcall(catalog.GetCandidateMembers,catalog,groupID)
    if not ok or type(candidates)~="table" then
        result.reason="item_cd_group_members_unverified"
        return result
    end
    local valid,ids,catalogRevision=pcall(function()
        if not api:IsSafeValue(candidates)
            or candidates.status~="UNKNOWN"
            or candidates.reason~="item_cd_use_attribution_unknown"
            or candidates.groupID~=groupID
            or not api:IsSafeValue(candidates.familyRevision)
            or not finite(candidates.familyRevision,1)
            or candidates.familyRevision~=math.floor(candidates.familyRevision) then
            return nil
        end
        local members=candidates.candidateItemIDs
        if type(members)~="table" or not api:IsSafeValue(members)
            or #members<1 or #members>32
            or candidates.candidateCount~=#members then return nil end
        local seen,out={},{}
        for i=1,#members do
            local id=members[i]
            if not inventorySafeID(id,"item") or seen[id] then return nil end
            seen[id]=true
            out[i]=id
        end
        for key in pairs(members) do
            if type(key)~="number" or key~=math.floor(key)
                or key<1 or key>#members then return nil end
        end
        return out,candidates.familyRevision
    end)
    if not valid or not ids then
        result.reason="item_cd_group_members_unverified"
        return result
    end
    local bus=KR.EventBus
    local families=KR.ItemFamilyCatalog
    if not bus or type(bus.GetItemCooldownRevision)~="function"
        or type(bus.GetInventoryRevision)~="function"
        or not families or type(families.GetRevision)~="function" then
        result.reason="item_cd_revision_unavailable"
        return result
    end
    local function revisions()
        local readOK,itemRev,bagRev,familyRev=pcall(function()
            return bus:GetItemCooldownRevision(),
                bus:GetInventoryRevision(),families:GetRevision()
        end)
        if not readOK or not finite(itemRev,0)
            or itemRev~=math.floor(itemRev) or not finite(bagRev,0)
            or bagRev~=math.floor(bagRev) or not finite(familyRev,1)
            or familyRev~=math.floor(familyRev) then return nil end
        return {itemRev,bagRev,familyRev}
    end
    local before=revisions()
    if not before or before[3]~=catalogRevision then
        result.reason="item_cd_revision_changed"
        return result
    end
    -- A source-only spell event is useful only if its candidate item is
    -- independently observed on cooldown in this exact revision snapshot.
    -- Correlation is a diagnostic ESTIMATE, never group lockout evidence.
    local useOK,use=pcall(self.ReadObservedItemUse,self,groupID)
    local observedID,observedAt=nil,nil
    if useOK and type(use)=="table" then
        local validUse,accepted=pcall(function()
            return api:IsSafeValue(use)
                and use.status=="UNKNOWN"
                and use.reason=="item_cd_use_attribution_estimated"
                and use.confidence=="ESTIMATED"
                -- Only the observed PLAYER use-spell event is accepted as
                -- provenance; a forged/source-less estimate is not evidence.
                and api:IsSafeValue(use.groupStatus)
                and use.groupStatus=="UNKNOWN"
                and api:IsSafeValue(use.source)
                and use.source=="UNIT_SPELLCAST_SUCCEEDED"
                and inventorySafeID(use.candidateItemID,"item")
                and api:IsSafeValue(use.observedAt)
                and finite(use.observedAt,0)
                and use.familyRevision==before[3]
        end)
        if validUse and accepted then
            observedID,observedAt=use.candidateItemID,use.observedAt
        end
    end
    local active,inactive,unknown,coincident=0,0,0,0
    local maxRemaining=0
    local matchedUse=false
    local originStart,originDuration=nil,nil
    local activeTuples={}
    local starts={}
    -- A stable revision does not ensure these sequential cooldown reads
    -- describe the same instant. Bound the sampled monotonic clock span.
    local firstSampleAt,lastSampleAt=nil,nil
    local sampleTimeIncoherent=false
    for _,id in ipairs(ids) do
        local readOK,record=pcall(self.ReadItemCooldownObservation,self,id)
        local good,isActive,remaining,start,duration,sampledAt=pcall(function()
            if not readOK or type(record)~="table"
                or not api:IsSafeValue(record)
                or record.status~="READY"
                or not api:IsSafeValue(record.itemID) or record.itemID~=id
                or record.cooldownScope~="ITEM_SPECIFIC"
                or not api:IsSafeValue(record.active)
                or type(record.active)~="boolean"
                or not api:IsSafeValue(record.remaining)
                or not finite(record.remaining,0)
                or record.active~=(record.remaining>0)
                or not api:IsSafeValue(record.revision)
                or record.revision~=before[1]
                or not api:IsSafeValue(record.observedAt)
                or not finite(record.observedAt,0) then
                return nil
            end
            local start,duration=record.startTime,record.duration
            local tupleSafe=api:IsSafeValue(start) and api:IsSafeValue(duration)
                and finite(start,0) and finite(duration,0)
            return true,record.active,record.remaining,
                tupleSafe and start or nil,tupleSafe and duration or nil,
                record.observedAt
        end)
        if good and isActive~=nil then
            if lastSampleAt and sampledAt<lastSampleAt then
                sampleTimeIncoherent=true
            end
            firstSampleAt=firstSampleAt or sampledAt
            lastSampleAt=sampledAt
            if sampledAt-firstSampleAt>2 then
                sampleTimeIncoherent=true
            end
        end
        if not good or isActive==nil then
            unknown=unknown+1
        elseif isActive then
            active=active+1
            if remaining>maxRemaining then maxRemaining=remaining end
            -- Coincidence is not proof of shared lockout. Never return
            -- ESTIMATED_ACTIVE or CONFIRMED without item-use attribution.
            if finite(start,0) and finite(duration,0)
                and start>0 and duration>0 then
                -- Keep only bounded, locally copied scalar tuples. Never
                -- store raw API returns or use these to infer group READY.
                activeTuples[#activeTuples+1]={itemID=id,
                    startTime=start,duration=duration}
                local key=tostring(start)..":"..tostring(duration)
                starts[key]=(starts[key] or 0)+1
                if starts[key]>coincident then coincident=starts[key] end
                -- At most a two-second window avoids arbitrary historical
                -- correlations. Matching a use-spell still is not a group rule.
                if id==observedID and observedAt
                    and math.abs(start-observedAt)<=2 then
                    matchedUse=true
                    originStart,originDuration=start,duration
                end
            end
        else
            inactive=inactive+1
        end
    end
    local after=revisions()
    if sampleTimeIncoherent then
        result.reason="item_cd_sample_time_incoherent"
        return result
    end
    if not after or before[1]~=after[1] or before[2]~=after[2]
        or before[3]~=after[3] then
        result.reason="item_cd_revision_changed"
        return result
    end
    result.candidateCount=#ids
    result.knownActiveCount=active
    result.knownInactiveCount=inactive
    result.unknownCount=unknown
    result.coincidentActiveCount=coincident
    result.candidateMaxRemaining=active>0 and maxRemaining or nil
    result.itemCooldownRevision=before[1]
    result.inventoryRevision=before[2]
    result.familyRevision=before[3]
    result.useCorrelation=matchedUse and "ESTIMATED" or "UNKNOWN"
    result.useCorrelationReason=matchedUse
        and "item_cd_use_member_time_match"
        or "item_cd_use_attribution_unknown"
    -- An event-associated origin may have matching cooldown tuples on
    -- other candidate IDs. This remains merely source-only PROPAGATION
    -- EVIDENCE; item-specific independent cooldowns can coincide by chance.
    result.propagationEvidence="UNKNOWN"
    if matchedUse then
        local aligned,divergent=0,0
        for _,tuple in ipairs(activeTuples) do
            if math.abs(tuple.startTime-originStart)<=2
                and math.abs(tuple.duration-originDuration)<=2 then
                aligned=aligned+1
            else
                divergent=divergent+1
            end
        end
        result.alignedCandidateCount=aligned
        result.divergentActiveCount=divergent
        result.inactiveCandidateCount=inactive
        -- Divergent active tuples and idle candidate IDs are diagnostic
        -- conflicts only, not evidence that the shared rule is false.
        if divergent>0 or inactive>0 then
            result.propagationEvidence="MIXED_CANDIDATES"
        elseif aligned>=2 then
            result.propagationEvidence="ALIGNED_CANDIDATES"
        else
            result.propagationEvidence="SINGLE_CANDIDATE"
        end
    end
    -- Separate individual certainty from group-lockout certainty.
    local provider=KR.SharedCooldownConfidence
    if provider and type(provider.Evaluate)=="function" then
        local ok,level=pcall(provider.Evaluate,provider,result)
        if ok and type(level)=="table" then
            local safeResult,valid=pcall(function()
                return api:IsSafeValue(level)
                    and level.status=="UNKNOWN"
                    and level.groupReadyConfidence=="UNKNOWN"
                    and (level.itemCooldownConfidence=="CONFIRMED"
                        or level.itemCooldownConfidence=="UNKNOWN")
                    and (level.groupLockoutConfidence=="ESTIMATED"
                        or level.groupLockoutConfidence=="UNKNOWN")
                    and api:IsSafeValue(level.reason)
            end)
            if safeResult and valid then
                result.itemCooldownConfidence=level.itemCooldownConfidence
                result.groupLockoutConfidence=level.groupLockoutConfidence
                result.groupReadyConfidence="UNKNOWN"
                result.confidenceReason=level.reason
            end
        end
    end
    -- No group active/remaining, confidence CONFIRMED or READY is emitted.
    return result
end


-- IT-02/2.6: successful PLAYER spellcast may match a UNIQUE item use-spell.
-- Events have no itemID; store only bounded source-only observational evidence.
-- This does not prove a shared cooldown or any group READY state.
function S:ObserveSuccessfulItemUseSpell(spellID)
    local catalog=KR.SharedCooldownGroupCatalog
    if not catalog or type(catalog.FindObservedUseSpell)~="function" then
        return false
    end
    local ok,match=pcall(catalog.FindObservedUseSpell,catalog,spellID)
    local api=KR.GameAPI
    local matchOK,verified=pcall(function()
        return ok and type(match)=="table"
            and api and api:IsSafeValue(match)
            and match.reason=="item_cd_use_spell_source_match"
            and match.groupID=="POTION_SHARED"
            and inventorySafeID(match.itemID,"item")
            and api:IsSafeValue(match.familyRevision)
            and finite(match.familyRevision,1)
            and match.familyRevision==math.floor(match.familyRevision)
    end)
    if not matchOK or not verified then return false end
    local now=clock()
    if not now then return false end
    self.lastObservedItemUse={itemID=match.itemID,
        groupID="POTION_SHARED",observedAt=now,
        familyRevision=match.familyRevision,
        source="UNIT_SPELLCAST_SUCCEEDED",confidence="ESTIMATED"}
    return true
end
function S:ReadObservedItemUse(groupID)
    local unknown={status="UNKNOWN",reason="item_cd_use_attribution_unknown"}
    if groupID~="POTION_SHARED" then return unknown end
    local evidence=self.lastObservedItemUse
    if not evidence then return unknown end
    local now=clock()
    local families=KR.ItemFamilyCatalog
    if not now or not families or type(families.GetRevision)~="function" then
        return unknown
    end
    local ok,rev=pcall(families.GetRevision,families)
    local valid,same=pcall(function()
        return ok and finite(rev,1)
            and KR.GameAPI and KR.GameAPI:IsSafeValue(evidence.familyRevision)
            and rev==evidence.familyRevision
            and finite(evidence.observedAt,0)
            and now>=evidence.observedAt and now-evidence.observedAt<=180
    end)
    if not valid or not same then
        self.lastObservedItemUse=nil
        return unknown
    end
    return {status="UNKNOWN",groupStatus="UNKNOWN",
        reason="item_cd_use_attribution_estimated",
        candidateItemID=evidence.itemID,observedAt=evidence.observedAt,
        confidence="ESTIMATED",source=evidence.source,
        familyRevision=evidence.familyRevision}
end
function S:ClearObservedItemUse()
    self.lastObservedItemUse=nil
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
