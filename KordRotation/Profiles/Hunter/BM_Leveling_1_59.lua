-- Kord_Rotation
-- Hunter / Beast Mastery / PvE / Leveling 1-59  (WoW: Forever)
-- Rotation v2.3
-- (v2.1: порядок Hawk -> Aimed -> Arcane; Multi-Shot как филлер только до Aimed Shot)
--
-- Вход:
--   s   = состояние боя от движка (см. список полей ниже)
--   cfg = пользовательские настройки (можно частичные, остальное из defaults)
--
-- Выход:
--   spell name (строка из BM.spells) или nil
--
-- Единый приоритетный список без уровневых "корзин": неизученные способности
-- отсекаются через s.ready, поэтому ротация сама "растёт" вместе с уровнем.
-- Уровень используется только для выбора аспекта (Monkey до 10, Hawk с 10).
--
-- Что открывается по ходу прокачки (ориентир, по гайдам):
--   4  Serpent Sting, Aspect of the Monkey
--   6  Arcane Shot, Hunter's Mark
--   8  Concussive Shot
--   10 питомец, Aspect of the Hawk
--   16 Immolation Trap
--   25 Summon Hawk (талант)
--   40 Bestial Wrath (талант), Volley
-- Aimed Shot в Forever базовый, его уровень проверьте в книге заклинаний.
--
-- Поля s, которые ожидает ротация:
--   ready[spell]            способность изучена, готова, хватает ресурса и дистанции
--   known[spell]            способность изучена (для Summon Hawk и Aimed Shot)
--   level, has_target, in_combat, target_distance
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
--   has_aggro                моб бьёт игрока, а не питомца
--   target_approaching, target_slowed, target_targets_player
--   target_has_wing_clip, need_distance, mongoose_usable
--   auto_shot_active
--   player_health_percent, freezing_trap_profitable, frost_trap_profitable
--   Feign Death: in_dungeon/in_raid + has_aggro, или в открытом мире has_aggro + HP <= cfg.feign_hp
--   has_hawk_aspect, has_monkey_aspect, has_travel_aspect

local BM = {}

BM.defaults = {
    mark = "all",
    -- all / elite / instance / elite_or_instance / smart / off

    sting = "smart",
    -- smart / all / elite / off

    hawk_arcane = "hawk",
    -- auto / hawk / arcane / off

    aimed_multi = "auto",
    -- auto / aimed / multi

    multi_filler = true,
    -- Multi-Shot как филлер на одиночной цели, пока Aimed Shot не изучен
    -- (общая перезарядка 6 с с Aimed Shot)

    mana = "balanced",
    -- fast (15%) / balanced (30%) / economy (50%) / max (без порога)

    bestial_wrath = "all",
    -- all / elite / off

    rapid_fire = "strong",
    -- all / strong / off

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

    summon_pet = true,
    mend_pet = true,
    pet_attack = true,
    aspect = true
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
    ASPECT_MONKEY = "Aspect of the Monkey"
}

BM.spells = SPELL

-- Summon Hawk и Arcane Shot делят перезарядку (6 с), ястреб живёт 18 с, до 2 штук.
-- Ястреба обновляем, когда старый почти закончился (запас на задержку),
-- Arcane Shot вставляем, когда у обоих ястребов осталось не меньше 6 секунд.
local HAWK_RECAST = 1.5
local ARCANE_MIN_REMAINING = 6

local MANA_FLOOR = {
    max = 0,
    fast = 15,
    balanced = 30,
    economy = 50
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

local function WrathAllowed(s, cfg)
    if cfg.bestial_wrath == "off" then
        return false
    end

    if cfg.bestial_wrath == "elite" then
        return s.target_elite or s.target_boss
    end

    return s.target_will_survive_burst
end

local function RapidAllowed(s, cfg)
    if cfg.rapid_fire == "off" then
        return false
    end

    if cfg.rapid_fire == "all" then
        return s.target_will_survive_burst
    end

    return Strong(s)
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

local function Feign(s, cfg)
    if not cfg.use_feign_death or not s.in_combat then return nil end

    -- Подземелья/рейды: фактический срыв агро, независимо от здоровья.
    -- Открытый мир: только агро на охотнике и HP ниже порога cfg.feign_hp.
    local grouped_instance = s.in_dungeon or s.in_raid
    local should_feign = s.has_aggro and (
        grouped_instance
        or (s.player_health_percent or 100) <= cfg.feign_hp
    )
    return Pick(s, SPELL.FEIGN, should_feign)
end

-- ==================================================
-- АСПЕКТ / ПИТОМЕЦ
-- ==================================================

local function Aspect(s, cfg)
    if not cfg.aspect or s.has_travel_aspect then
        return nil
    end

    -- Не дёргаем игрока без цели и вне боя (например, при беге в Cheetah).
    if not (s.has_target or s.in_combat) then
        return nil
    end

    if (s.level or 1) >= 10 then
        return Pick(s, SPELL.ASPECT_HAWK, not s.has_hawk_aspect)
    end

    return Pick(s, SPELL.ASPECT_MONKEY, not s.has_monkey_aspect)
end

local function SummonPet(s, cfg)
    if not cfg.summon_pet or s.has_pet or s.in_combat then
        return nil
    end

    if s.pet_dead then
        return Pick(s, SPELL.REVIVE, true)
    end

    return Pick(s, SPELL.CALL_PET, true)
end

local function MendPet(s, cfg)
    if not cfg.mend_pet or not s.has_pet then
        return nil
    end

    return Pick(
        s, SPELL.MEND,
        (s.pet_health_percent or 100) <= cfg.mend_pet_hp
            and not s.pet_mend_active
    )
end

local function PetAttack(s, cfg)
    if not cfg.pet_attack or not s.has_pet or not s.has_target then
        return nil
    end

    return Pick(
        s, SPELL.PET_ATTACK,
        not s.pet_attacking_target
    )
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
            and (s.sting_remaining or 0) <= 2
            and ManaOK(s, cfg)
    )
end

-- ==================================================
-- SUMMON HAWK / ARCANE SHOT (общая перезарядка)
-- ==================================================

-- Порядок в ротации: Hawk -> Aimed Shot -> Arcane Shot,
-- поэтому Arcane Shot не перехватывает очередь у Aimed Shot.

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

    -- До Summon Hawk (или по выбору пользователя, или если цель скоро умрёт)
    -- работает только Arcane Shot.
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
    -- Режим "multi": при нескольких целях не занимаем время Aimed Shot.
    if cfg.aimed_multi == "multi"
        and AoEAllowed(s, cfg)
    then
        return nil
    end

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
    local action = Pick(
        s, SPELL.WRATH,
        s.has_pet
            and s.pet_attacking_target
            and WrathAllowed(s, cfg)
    )
    if action then return action end

    action = Pick(
        s, SPELL.RAPID,
        RapidAllowed(s, cfg)
    )
    if action then return action end

    if cfg.intimidation then
        action = Pick(
            s, SPELL.INTIMIDATE,
            s.has_pet
                and s.pet_attacking_target
                and s.intimidation_profitable
        )
        if action then return action end
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

    if n >= 3 then
        local action = Pick(
            s, SPELL.EXPLOSIVE,
            (s.enemies_near_player or 0) >= 3
                and s.trap_profitable
        )
        if action then return action end

        action = Pick(
            s, SPELL.VOLLEY,
            s.volley_profitable
        )
        if action then return action end
    end

    -- Режим "aimed": Multi-Shot в AoE не используем.
    if cfg.aimed_multi == "aimed" then
        return nil
    end

    -- Multi-Shot бьёт до трёх целей.
    return Pick(
        s, SPELL.MULTI,
        s.multi_profitable
            and ManaOK(s, cfg)
    )
end

-- ==================================================
-- ФИЛЛЕРЫ (когда основные способности на перезарядке)
-- ==================================================

local function Filler(s, cfg)
    local action = Pick(
        s, SPELL.IMMOLATION,
        (s.enemies_near_player or 0) >= 1
            and s.trap_profitable
    )
    if action then return action end

    -- Aimed Shot и Multi-Shot делят перезарядку (6 с), поэтому Multi-Shot
    -- как филлер на одиночной цели нужен только пока Aimed Shot не изучен.
    -- Иначе Multi-Shot задерживал бы более сильный Aimed Shot.
    if cfg.multi_filler
        and (not cfg.use_aimed_shot or not (s.known and s.known[SPELL.AIMED]))
    then
        action = Pick(
            s, SPELL.MULTI,
            s.multi_profitable
                and ManaOK(s, cfg)
        )
        if action then return action end
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
    -- Disengage сбрасывает угрозу, моб переключается на питомца.
    local action = Pick(
        s, SPELL.DISENGAGE,
        cfg.use_disengage
            and s.has_pet
            and s.has_aggro
    )
    if action then return action end

    -- Кулдауны и ловушки не требуют дистанции стрельбы.
    action = ControlTraps(s, cfg)
    if action then return action end

    action = Cooldowns(s, cfg)
    if action then return action end

    action = Pick(
        s, SPELL.IMMOLATION,
        s.trap_profitable
    )
    if action then return action end

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

    action = Mark(s, cfg)
    if action then return action end

    -- Замедление: без питомца (уровни 1-9) или если моб бежит к игроку.
    action = Pick(
        s, SPELL.CONCUSSIVE,
        s.target_approaching
            and not s.target_slowed
            and (not s.has_pet or s.target_targets_player)
    )
    if action then return action end

    action = ControlTraps(s, cfg)
    if action then return action end

    action = Cooldowns(s, cfg)
    if action then return action end

    action = AoE(s, cfg)
    if action then return action end

    action = HawkOnly(s, cfg)
    if action then return action end

    action = Aimed(s, cfg)
    if action then return action end

    action = ArcaneShot(s, cfg)
    if action then return action end

    action = Sting(s, cfg)
    if action then return action end

    return Filler(s, cfg)
end

-- ==================================================
-- MAIN
-- ==================================================

function BM.Next(s, cfg)
    cfg = WithDefaults(cfg)

    local action = Feign(s, cfg)
    if action then return action end

    action = Aspect(s, cfg)
        or SummonPet(s, cfg)
        or MendPet(s, cfg)
    if action then return action end

    if not s.has_target then
        return nil
    end

    -- Перед пуллом: метка, затем питомец.
    if not s.in_combat then
        action = Mark(s, cfg)
        if action then return action end
    end

    action = PetAttack(s, cfg)
    if action then return action end

    if (s.target_distance or 99) <= 8 then
        return Melee(s, cfg)
    end

    return Ranged(s, cfg)
end

return BM