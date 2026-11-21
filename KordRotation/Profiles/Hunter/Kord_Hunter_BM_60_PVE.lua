-- Kord_Rotation
-- Hunter / Beast Mastery / PvE / Level 60 (dungeon + raid)  (WoW: Forever)
-- Rotation v1.2
--
-- Вход:
--   s   = состояние боя от движка (см. список полей ниже)
--   cfg = пользовательские настройки (можно частичные, остальное из defaults)
--
-- Выход:
--   spell name (строка из BM.spells) или nil
--
-- Базовый приоритет (одна цель), по гайдам Forever:
--   Serpent Sting -> Summon Hawk (держим 2 ястреба) -> Aimed Shot ->
--   Arcane Shot (когда у обоих ястребов осталось >= 6 с) ->
--   Rapid Fire / Bestial Wrath по кулдауну.
-- AoE: Multi-Shot по кулдауну, Explosive Trap под группой, Sting, затем как выше.
--
-- Известные факты (сверьте с книгой заклинаний своего клиента):
--   * Summon Hawk и Arcane Shot делят перезарядку 6 с, ястреб живёт 18 с, до 2 штук.
--   * Aimed Shot и Multi-Shot делят перезарядку 6 с.
--   * Bestial Wrath: перезарядка 120 с, длительность 18 с, нужен питомец.
--   * Все ловушки делят перезарядку 30 с и дают угрозу.
--   * Движение прерывает Auto Shot.
--
-- Поля s, которые ожидает ротация:
--   ready[spell]            способность изучена, готова, хватает ресурса и дистанции
--   known[spell]            способность изучена (для Summon Hawk)
--   has_target, in_combat, in_group, target_distance
--   pull_in                 секунд до пулла по таймеру (nil, если таймера нет)
--   has_pet, pet_dead, pet_health_percent, pet_mend_active, pet_attacking_target
--   mana_percent
--   target_elite, target_boss, long_fight, in_dungeon, in_raid
--   target_has_mark, mark_profitable
--   sting_profitable, sting_remaining
--   target_dying_soon, target_will_survive_burst
--   hawk_count, oldest_hawk_remaining   (движок считает по своим кастам, 18 с)
--   aimed_profitable, multi_profitable
--   enemies, enemies_near_player, aoe_safe, trap_profitable, volley_profitable
--   intimidation_profitable
--   has_aggro                моб бьёт игрока, а не танка/питомца
--   threat_high              угроза игрока близка к угрозе танка
--   target_approaching, target_slowed, target_targets_player
--   target_has_wing_clip, need_distance, mongoose_usable
--   auto_shot_active
--   player_health_percent, freezing_trap_profitable, frost_trap_profitable
--   Feign Death: in_dungeon/in_raid + has_aggro, или в открытом мире has_aggro + HP <= cfg.feign_hp
--   has_hawk_aspect, has_travel_aspect, has_trueshot_aura

local BM = {}

BM.defaults = {
    mark = "all",
    -- all / elite / instance / elite_or_instance / smart / off

    sting = "smart",
    -- smart / all / elite / off

    hawk_arcane = "hawk",
    -- auto / hawk / arcane / off

    mana = "balanced",
    -- max (без порога) / fast (10%) / balanced (25%) / economy (40%)

    cooldowns = "on_cd",
    -- on_cd (по кулдауну, как советуют гайды) / boss (только элиты и боссы) / off

    intimidation = true,

    use_feign_death = true,
    feign_hp = 30,
    use_disengage = true,
    use_wing_clip = true,
    use_aimed_shot = true,
    use_freezing_trap = true,
    use_frost_trap = true,
    mend_pet_hp = 50,


    aoe = "safe",
    -- safe / aggressive / off

    traps = "aoe",
    -- aoe (только Explosive в AoE) / always (ещё Immolation как филлер) / off
    -- Ловушки дают угрозу и делят перезарядку, поэтому по умолчанию только AoE.


    pull_cast = true,
    -- Aimed Shot заранее под таймер пулла

    summon_pet = true,
    mend_pet = true,
    pet_attack = true,
    aspect = true,
    trueshot_aura = true
}

local SPELL = {
    MARK          = "Hunter's Mark",
    STING         = "Serpent Sting",
    ARCANE        = "Arcane Shot",
    HAWK          = "Summon Hawk",
    AUTO          = "Auto Shot",
    AIMED         = "Aimed Shot",
    MULTI         = "Multi-Shot",
    RAPID         = "Rapid Fire",
    WRATH         = "Bestial Wrath",
    INTIMIDATE    = "Intimidation",
    CONCUSSIVE    = "Concussive Shot",
    RAPTOR        = "Raptor Strike",
    MONGOOSE      = "Mongoose Bite",
    WING          = "Wing Clip",
    DISENGAGE     = "Disengage",
    FEIGN         = "Feign Death",
    FREEZING      = "Freezing Trap",
    FROST         = "Frost Trap",
    EXPLOSIVE     = "Explosive Trap",
    IMMOLATION    = "Immolation Trap",
    VOLLEY        = "Volley",
    MEND          = "Mend Pet",
    CALL_PET      = "Call Pet",
    REVIVE        = "Revive Pet",
    PET_ATTACK    = "Pet Attack",
    ASPECT_HAWK   = "Aspect of the Hawk",
    TRUESHOT      = "Trueshot Aura"
}

BM.spells = SPELL

-- Ястреба обновляем, когда старый почти закончился (запас на задержку).
-- Arcane Shot вставляем, когда у обоих ястребов осталось не меньше 6 секунд.
local HAWK_RECAST = 1.5
local ARCANE_MIN_REMAINING = 6

-- Serpent Sting живёт 15 с: обновляем, когда осталось меньше одного GCD.
local STING_REFRESH = 1.5

-- Время каста Aimed Shot и запас на задержку для предварительного каста под таймер.
-- Проверьте в игре: select(7, GetSpellInfo("Aimed Shot")) / 1000
local AIMED_CAST_TIME = 2.0
local AIMED_LATENCY = 0.3

local MANA_FLOOR = {
    max = 0,
    fast = 10,
    balanced = 25,
    economy = 40
}

-- cfg может быть частичным: недостающие ключи берутся из defaults
local defaultsMeta = { __index = BM.defaults }

local function WithDefaults(cfg)
    if not cfg then
        return BM.defaults
    end

    if getmetatable(cfg) == nil then
        setmetatable(cfg, defaultsMeta)
    end

    return cfg
end

local function Ready(s, spell)
    return s.ready[spell] == true
end

local function Pick(s, spell, condition)
    if condition and Ready(s, spell) then
        return spell
    end
end

local function Strong(s)
    return s.target_elite
        or s.target_boss
        or s.long_fight
end

local function ManaOK(s, cfg)
    local floor = MANA_FLOOR[cfg.mana] or MANA_FLOOR.balanced
    return (s.mana_percent or 100) >= floor
end

local function MarkAllowed(s, cfg)
    local mode = cfg.mark

    if mode == "off" then return false end
    if mode == "all" then return true end
    if mode == "elite" then return s.target_elite or s.target_boss end
    if mode == "instance" then return s.in_dungeon or s.in_raid end
    if mode == "elite_or_instance" then return s.target_elite or s.target_boss or s.in_dungeon or s.in_raid end
    if mode == "smart" then return Strong(s) or s.mark_profitable end

    return false
end

local function StingAllowed(s, cfg)
    local mode = cfg.sting

    if mode == "off" then return false end
    if mode == "all" then return true end
    if mode == "elite" then return s.target_elite or s.target_boss end

    return s.sting_profitable
end

local function CooldownAllowed(s, cfg)
    if cfg.cooldowns == "off" then
        return false
    end

    if cfg.cooldowns == "boss" then
        return s.target_elite or s.target_boss
    end

    return s.target_will_survive_burst
end

local function AoEAllowed(s, cfg)
    local n = s.enemies or 1

    if cfg.aoe == "off" then
        return false
    end

    if cfg.aoe == "aggressive" then
        return n >= 2
    end

    return n >= 2 and s.aoe_safe
end

-- ==================================================
-- ПОДГОТОВКА: аспект, аура, питомец
-- ==================================================

local function Maintenance(s, cfg)
    -- Аспект: только если есть цель или бой, чтобы не мешать бегу в Cheetah/Pack.
    if cfg.aspect
        and not s.has_travel_aspect
        and (s.has_target or s.in_combat)
    then
        local action = Pick(
            s, SPELL.ASPECT_HAWK,
            not s.has_hawk_aspect
        )
        if action then return action end
    end

    if not s.in_combat then
        -- Trueshot Aura даёт группе Ranged Attack Power.
        if cfg.trueshot_aura then
            local action = Pick(
                s, SPELL.TRUESHOT,
                not s.has_trueshot_aura
            )
            if action then return action end
        end

        if cfg.summon_pet and not s.has_pet then
            if s.pet_dead then
                return Pick(s, SPELL.REVIVE, true)
            end

            return Pick(s, SPELL.CALL_PET, true)
        end
    end

    if cfg.mend_pet and s.has_pet then
        return Pick(
            s, SPELL.MEND,
            (s.pet_health_percent or 100) <= cfg.mend_pet_hp
                and not s.pet_mend_active
        )
    end
end

-- Питомца отправляем только когда бой уже идёт, чтобы не сделать пулл раньше танка.
local function PetAttack(s, cfg)
    if not cfg.pet_attack
        or not s.has_pet
        or not s.has_target
        or not s.in_combat
    then
        return nil
    end

    return Pick(
        s, SPELL.PET_ATTACK,
        not s.pet_attacking_target
    )
end

-- ==================================================
-- УГРОЗА
-- ==================================================

local function Threat(s, cfg)
    if not s.in_combat then return nil end

    -- Подземелья/рейды: использовать Feign Death только при реальном агро.
    -- В открытом мире: реальное агро и HP не выше cfg.feign_hp.
    -- Высокая угроза без переключения цели не служит причиной для Feign Death.
    local grouped_instance = s.in_dungeon or s.in_raid
    local should_feign = s.has_aggro and (
        grouped_instance
        or (s.player_health_percent or 100) <= cfg.feign_hp
    )

    if cfg.use_feign_death then
        local action = Pick(s, SPELL.FEIGN, should_feign)
        if action then return action end
    end

    if cfg.use_disengage and s.in_group and s.has_aggro then
        return Pick(s, SPELL.DISENGAGE, true)
    end
end

-- ==================================================
-- МЕТКА / ЖАЛО
-- ==================================================

local function Mark(s, cfg)
    return Pick(
        s, SPELL.MARK,
        not s.target_has_mark
            and MarkAllowed(s, cfg)
    )
end

local function Sting(s, cfg)
    return Pick(
        s, SPELL.STING,
        StingAllowed(s, cfg)
            and (s.sting_remaining or 0) <= STING_REFRESH
            and ManaOK(s, cfg)
    )
end

-- ==================================================
-- SUMMON HAWK / ARCANE SHOT (общая перезарядка)
-- ==================================================

local function HawkOnly(s, cfg)
    local mode = cfg.hawk_arcane

    if mode == "off" or mode == "arcane" then
        return nil
    end

    if not (s.known and s.known[SPELL.HAWK]) then
        return nil
    end

    -- Цель скоро умрёт: ястреб не окупится.
    if s.target_dying_soon then
        return nil
    end

    local hawks = s.hawk_count or 0
    local oldest = s.oldest_hawk_remaining or 0

    return Pick(
        s, SPELL.HAWK,
        ManaOK(s, cfg)
            and (hawks < 2 or oldest <= HAWK_RECAST)
    )
end

local function ArcaneShot(s, cfg)
    local mode = cfg.hawk_arcane

    if mode == "off" then
        return nil
    end

    local ok = ManaOK(s, cfg)
    local hawkKnown = s.known and s.known[SPELL.HAWK]

    if not hawkKnown then
        return Pick(s, SPELL.ARCANE, ok)
    end

    if mode == "hawk" then
        return nil
    end

    if mode == "arcane" or s.target_dying_soon then
        return Pick(s, SPELL.ARCANE, ok)
    end

    local hawks = s.hawk_count or 0
    local oldest = s.oldest_hawk_remaining or 0

    return Pick(
        s, SPELL.ARCANE,
        ok
            and hawks >= 2
            and oldest >= ARCANE_MIN_REMAINING
    )
end

-- ==================================================
-- AIMED SHOT
-- ==================================================

local function Aimed(s, cfg)
    if not cfg.use_aimed_shot then return nil end
    return Pick(
        s, SPELL.AIMED,
        s.aimed_profitable
            and ManaOK(s, cfg)
    )
end

-- ==================================================
-- КУЛДАУНЫ
-- ==================================================

local function Cooldowns(s, cfg)
    if CooldownAllowed(s, cfg) then
        local action = Pick(
            s, SPELL.RAPID,
            true
        )
        if action then return action end

        action = Pick(
            s, SPELL.WRATH,
            s.has_pet
                and s.pet_attacking_target
        )
        if action then return action end
    end

    -- Intimidation удерживает угрозу на питомце и даёт ему гарантированный крит.
    if cfg.intimidation then
        return Pick(
            s, SPELL.INTIMIDATE,
            s.has_pet
                and s.pet_attacking_target
                and s.intimidation_profitable
        )
    end
end

-- ==================================================
-- AOE
-- ==================================================

local function AoE(s, cfg)
    if not AoEAllowed(s, cfg) then
        return nil
    end

    local n = s.enemies or 1

    if n >= 3 and cfg.traps ~= "off" then
        local action = Pick(
            s, SPELL.EXPLOSIVE,
            (s.enemies_near_player or 0) >= 3
                and s.trap_profitable
        )
        if action then return action end
    end

    -- Multi-Shot по кулдауну (делит перезарядку с Aimed Shot, бьёт до трёх целей).
    local action = Pick(
        s, SPELL.MULTI,
        s.multi_profitable
            and ManaOK(s, cfg)
    )
    if action then return action end

    if n >= 3 then
        return Pick(
            s, SPELL.VOLLEY,
            s.volley_profitable
                and ManaOK(s, cfg)
        )
    end
end

-- ==================================================
-- ФИЛЛЕР
-- ==================================================

local function Filler(s, cfg)
    if cfg.traps == "always" then
        return Pick(
            s, SPELL.IMMOLATION,
            (s.enemies_near_player or 0) >= 1
                and s.trap_profitable
        )
    end
end

local function ControlTraps(s, cfg)
    local action = Pick(
        s, SPELL.FREEZING,
        cfg.use_freezing_trap and s.freezing_trap_profitable
    )
    if action then return action end

    return Pick(
        s, SPELL.FROST,
        cfg.use_frost_trap and s.frost_trap_profitable
    )
end

-- ==================================================
-- БЛИЖНИЙ БОЙ (мёртвая зона и ближе)
-- ==================================================

local function Melee(s, cfg)
    local action = Threat(s, cfg)
    if action then return action end

    action = ControlTraps(s, cfg)
    if action then return action end

    action = Cooldowns(s, cfg)
    if action then return action end

    if cfg.traps == "always" then
        action = Pick(
            s, SPELL.IMMOLATION,
            s.trap_profitable
        )
        if action then return action end
    end

    action = Pick(
        s, SPELL.WING,
        cfg.use_wing_clip
            and s.need_distance
            and not s.target_has_wing_clip
    )
    if action then return action end

    action = Pick(
        s, SPELL.MONGOOSE,
        s.mongoose_usable
    )
    if action then return action end

    action = Pick(s, SPELL.RAPTOR, true)
    if action then return action end

    return nil
end

-- ==================================================
-- ДАЛЬНИЙ БОЙ
-- ==================================================

local function Ranged(s, cfg)
    local action = Pick(
        s, SPELL.AUTO,
        not s.auto_shot_active
    )
    if action then return action end

    action = Threat(s, cfg)
    if action then return action end

    action = Mark(s, cfg)
    if action then return action end

    -- Замедление моба, который бежит к игроку.
    action = Pick(
        s, SPELL.CONCUSSIVE,
        s.target_approaching
            and not s.target_slowed
            and (s.has_aggro or not s.has_pet)
    )
    if action then return action end

    action = ControlTraps(s, cfg)
    if action then return action end

    action = Cooldowns(s, cfg)
    if action then return action end

    action = AoE(s, cfg)
    if action then return action end

    action = Sting(s, cfg)
    if action then return action end

    action = HawkOnly(s, cfg)
    if action then return action end

    action = Aimed(s, cfg)
    if action then return action end

    action = ArcaneShot(s, cfg)
    if action then return action end

    return Filler(s, cfg)
end

-- ==================================================
-- ПРЕДВАРИТЕЛЬНЫЙ КАСТ ПОД ТАЙМЕР ПУЛЛА
-- ==================================================

local function PullCast(s, cfg)
    if not cfg.pull_cast
        or not cfg.use_aimed_shot
        or s.in_combat
        or not s.pull_in
    then
        return nil
    end

    if s.pull_in <= AIMED_CAST_TIME + AIMED_LATENCY then
        return Pick(s, SPELL.AIMED, true)
    end
end

-- ==================================================
-- MAIN
-- ==================================================

function BM.Next(s, cfg)
    cfg = WithDefaults(cfg)

    local action = Threat(s, cfg)
    if action then return action end

    action = Maintenance(s, cfg)
    if action then return action end

    if not s.has_target then
        return nil
    end

    if not s.in_combat then
        action = Mark(s, cfg)
        if action then return action end

        return PullCast(s, cfg)
    end

    action = PetAttack(s, cfg)
    if action then return action end

    if (s.target_distance or 99) <= 8 then
        return Melee(s, cfg)
    end

    return Ranged(s, cfg)
end

return BM