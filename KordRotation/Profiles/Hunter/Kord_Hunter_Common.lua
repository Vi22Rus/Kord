-- Kord Rotation | Hunter | Shared core (load BEFORE the four Hunter profiles)
-- No direct WoW API. A GameData adapter supplies the state described in C.Contract.
-- UNKNOWN is nil. Only an explicit true/false may prove a condition.
-- Every strategy disagreement between guides lives in C.CommonConfig / profile Config
-- as a CFG entry: {key,type,default,values|min/max,group,label,desc,conflict}.
-- The addon UI should be generated from <Profile>.Config; Profile.Next(state, options)
-- resolves and validates options itself (bad value -> default).
local C = { version = "2.0.0-design" }
KordHunterCommon = C

-- ---------------------------------------------------------------- contract
C.Contract = [[
spells : known[Name], ready[Name]  (ready already includes cooldown/mana/range/usable)
player : playerLevel healthPercent manaPercent inCombat inGroup inDungeon inRaid inPvP
         moving hasAggro threatHigh tankHasAggro incomingDamage needEscape
         otherAspectActive travelAspectActive playerBuffs[Name] talents{LoneWolf,ExposePrey,Resourcefulness}
target : targetValid targetHostile targetAlive targetAttackable targetBoss targetElite
         targetPlayer targetHealthPercent targetTTD targetCrowdControlled targetCanBeControlled
         targetCastingDangerous targetDebuffs[Name] targetDebuffRemaining[Name]
         inMeleeRange inRangedRange
area   : enemyCount aoeSafe breakableCCNearby aoeGroundSafe trapSharedReady trapPlacementSafe
cast   : currentCast canFinishCast (long cast or channel finishes safely)
swing  : autoShotActive rangedSwingRemaining autoMeleeActive meleeSwingWindow raptorStrikeQueued
pet    : petExists petDead petHealthPercent petMendActive petAttackingTarget petHappiness petCanFeed
procs  : rapidKillingProc
]]
-- Legacy names used by the first drafts are accepted and mapped once per call.
C.Aliases = {
  level = "playerLevel", isMoving = "moving", crowdControlNearby = "breakableCCNearby",
  mendPetActive = "petMendActive", petAttacking = "petAttackingTarget",
  canFinishLongCast = "canFinishCast", canFinishChannel = "canFinishCast",
}

function C.Normalize(state)
  local s = {}
  for k, v in pairs(state) do s[k] = v end
  for old, new in pairs(C.Aliases) do
    if s[new] == nil and s[old] ~= nil then s[new] = s[old] end
  end
  if s.petExists ~= nil and s.petDead == nil and s.petAlive ~= nil then s.petDead = not s.petAlive end
  return s
end

-- ---------------------------------------------------------------- config
local function E(key, default, values, group, label, desc, conflict)
  return { key = key, type = "enum", default = default, values = values, group = group,
           label = label, desc = desc, conflict = conflict }
end
local function B(key, default, group, label, desc)
  return { key = key, type = "bool", default = default, group = group, label = label, desc = desc }
end
local function N(key, default, min, max, group, label, desc, conflict)
  return { key = key, type = "number", default = default, min = min, max = max, group = group,
           label = label, desc = desc, conflict = conflict }
end
C.E, C.B, C.N = E, B, N

C.CommonConfig = {
  -- Hunter's Mark
  E("mark", "smart", { "smart", "all", "elite", "boss", "off" }, "debuffs", "Hunter's Mark",
    "smart: elites/bosses, group content, or long fights; all: every mob; elite: elite+boss only; boss: bosses only.",
    "Guides disagree: some mark every mob, others only elites. Default is smart."),
  N("markMinTTD", 15, 0, 100, "debuffs", "Mark: min time-to-die (s)", "Used by 'smart' for ordinary mobs outside groups."),
  B("markInTrash", true, "debuffs", "Mark trash in dungeons/raids", "Off = in group content mark only elites/bosses."),
  -- Serpent Sting
  E("sting", "smart", { "smart", "all", "elite", "boss", "off" }, "debuffs", "Serpent Sting",
    "smart: only if target lives long enough; all: every target; elite/boss: only those.",
    "Guides disagree on mana efficiency of Sting on trash. Default is smart (TTD based)."),
  N("stingMinTTD", 12, 0, 100, "debuffs", "Sting: min time-to-die (s)", "Used by 'smart'."),
  N("stingMinMana", 40, 0, 100, "debuffs", "Sting: min mana %", ""),
  -- cooldowns
  E("rapidFire", "strong", { "strong", "boss", "on_cooldown", "manual", "off" }, "cooldowns", "Rapid Fire",
    "strong: elites/bosses/long fights; boss: bosses only; on_cooldown: always when ready.",
    "Guides disagree: save for bosses vs. use on every cooldown."),
  N("rapidMinTTD", 15, 0, 100, "cooldowns", "Rapid Fire: min time-to-die (s)", ""),
  -- AoE / traps
  E("aoe", "safe", { "safe", "aggressive", "off" }, "aoe", "AoE policy",
    "safe: only if aoeSafe=true and no breakable CC nearby; aggressive: ignores CC (dangerous); off.", nil),
  E("traps", "contextual", { "contextual", "defensive", "offensive", "off" }, "traps", "Traps",
    "defensive: Freezing/Frost for escape only; contextual: + Immolation on tough targets; offensive: + Explosive AoE.", nil),
  N("volleyTargets", 4, 2, 10, "aoe", "Volley: min enemies", ""),
  N("volleyMinMana", 40, 0, 100, "aoe", "Volley: min mana %", ""),
  -- survival
  E("feign", "contextual", { "contextual", "emergency", "manual" }, "survival", "Feign Death",
    "contextual: drop threat in groups and at low HP; emergency: only at low HP with aggro; manual: never suggest.",
    "Guides disagree: FD on routine pulled aggro vs. only in emergencies."),
  N("feignSoloAt", 30, 0, 100, "survival", "Feign (solo/emergency) HP %", ""),
  N("feignGroupAt", 45, 0, 100, "survival", "Feign (group, aggro) HP %", ""),
  N("deterrenceAt", 35, 0, 100, "survival", "Deterrence HP %", ""),
  B("pvpControl", true, "survival", "Control hostile players", "Scatter/Concussive vs dangerous player casts."),
  -- pet
  E("pet", "auto", { "auto", "pet", "lone_wolf" }, "pet", "Pet mode",
    "auto: follow Lone Wolf talent; pet: always want pet; lone_wolf: never.", nil),
  B("petReminder", true, "pet", "Pet upkeep", "Call/Revive/Dismiss/Feed suggestions out of combat."),
  B("petAttackCommand", true, "pet", "Suggest pet attack", "Emit PET_ATTACK action when pet is idle."),
  N("petMendAt", 45, 0, 100, "pet", "Mend Pet HP %", ""),
  -- buffs
  B("aspectReminder", true, "buffs", "Aspect upkeep", ""),
  B("trueshotReminder", true, "buffs", "Trueshot Aura upkeep", "Only if known."),
  -- ranged weaving
  E("autoShotProtect", "window", { "window", "off" }, "ranged", "Protect Auto Shot",
    "window: cast long shots only when enough swing time remains; off: ignore swing timer.",
    "Guides disagree on clipping Auto Shot with Aimed Shot."),
  E("unknownSwing", "allow", { "allow", "block" }, "ranged", "If swing timer unknown",
    "allow: treat as not blocking (needed when adapter lacks swing data); block: strict.", nil),
  N("manaReserve", 25, 0, 100, "mana", "Mana reserve %", "Fillers/stings need mana above this."),
}

function C.Defaults(list)
  local d = {}
  for _, e in ipairs(list) do d[e.key] = e.default end
  return d
end

function C.Merge(...)
  local out = {}
  for _, l in ipairs({ ... }) do
    for _, src in ipairs(l) do
      local e = {}
      for k, v in pairs(src) do e[k] = v end   -- copy: profiles may override defaults safely
      local replaced = false
      for i, old in ipairs(out) do if old.key == e.key then out[i] = e replaced = true break end end
      if not replaced then out[#out + 1] = e end
    end
  end
  return out
end

function C.Resolve(list, o)
  local r, given = {}, type(o) == "table" and o or {}
  for _, e in ipairs(list) do
    local v, ok = given[e.key], false
    if e.type == "enum" then
      for _, a in ipairs(e.values) do if v == a then ok = true break end end
    elseif e.type == "bool" then ok = type(v) == "boolean"
    else ok = type(v) == "number" and v == v and v >= e.min and v <= e.max end
    if ok then r[e.key] = v else r[e.key] = e.default end
  end
  return r
end

-- ---------------------------------------------------------------- predicates
local function num(v) return type(v) == "number" end
function C.mana(s, min) return num(s.manaPercent) and s.manaPercent >= min end
function C.absent(t, k) return type(t) == "table" and t[k] == false end
function C.present(t, k) return type(t) == "table" and t[k] == true end
function C.group(s) return s.inDungeon == true or s.inRaid == true end
function C.strong(s) return s.targetBoss == true or s.targetElite == true end
function C.melee(s) return s.inMeleeRange == true end
function C.ranged(s) return s.inRangedRange == true and s.inMeleeRange ~= true end
function C.petWanted(s, o)
  if o.pet == "pet" then return true end
  if o.pet == "lone_wolf" then return false end
  if type(s.talents) ~= "table" then return nil end
  if s.talents.LoneWolf == true then return false end
  if s.talents.LoneWolf == false then return true end
  return nil
end
function C.aoeOK(s, o)
  if o.aoe == "off" or not num(s.enemyCount) or s.enemyCount < 2 then return false end
  if o.aoe == "safe" and (s.aoeSafe ~= true or s.breakableCCNearby ~= false) then return false end
  return true
end
-- Auto Shot protection: may a cast that needs `seconds` of swing time start now?
function C.autoWindow(s, o, seconds)
  if o.autoShotProtect == "off" or s.autoShotActive == false then return true end
  if num(s.rangedSwingRemaining) then return s.rangedSwingRemaining >= seconds end
  return o.unknownSwing == "allow"
end
local function worthByMode(s, o, mode, minTTD, trashOK)
  if mode == "off" then return false end
  if mode == "all" then return true end
  if mode == "boss" then return s.targetBoss == true end
  if mode == "elite" then return C.strong(s) end
  if C.strong(s) then return true end
  if C.group(s) and trashOK then return true end
  return num(s.targetTTD) and s.targetTTD >= minTTD
end
function C.markWorth(s, o) return worthByMode(s, o, o.mark, o.markMinTTD, o.markInTrash) end
function C.stingWorth(s, o) return worthByMode(s, o, o.sting, o.stingMinTTD, false) end
function C.rapidWorth(s, o)
  local m = o.rapidFire
  if m == "off" or m == "manual" or s.inCombat ~= true then return false end
  if m == "on_cooldown" then return true end
  if s.targetBoss == true then return true end
  if m == "boss" then return false end
  return C.strong(s) or (num(s.targetTTD) and s.targetTTD >= o.rapidMinTTD)
end

-- ---------------------------------------------------------------- context
-- x = {P=profile, s=state, o=options}; x.rec returns an action only if READY.
function C.Context(P, s, o)
  local x = { P = P, s = s, o = o }
  function x.rec(k, phase, reason)
    if type(s.known) == "table" and s.known[k] == true and type(s.ready) == "table" and s.ready[k] == true then
      return { spellID = P.Spells[k], spell = k, phase = phase, reason = reason }
    end
  end
  function x.try(k, cond, phase, reason) if cond then return x.rec(k, phase, reason) end end
  return x
end

-- ---------------------------------------------------------------- shared blocks
function C.Maintenance(x)
  local s, o = x.s, x.o
  local pet = C.petWanted(s, o)
  local r
  if s.inCombat ~= true then
    if o.petReminder then
      if pet == true then
        r = x.try("RevivePet", s.petDead == true, "pet", "Revive dead pet") if r then return r end
        r = x.try("CallPet", s.petExists == false and s.petDead == false, "pet", "Call missing pet") if r then return r end
        r = x.try("FeedPet", s.petCanFeed == true and num(s.petHappiness) and s.petHappiness < 3, "pet", "Feed unhappy pet")
        if r then return r end
        r = x.try("MendPet", s.petExists == true and s.petDead ~= true and num(s.petHealthPercent)
          and s.petHealthPercent <= 60 and s.petMendActive == false, "pet", "Heal pet before pull")
        if r then return r end
      elseif pet == false then
        r = x.try("DismissPet", s.petExists == true, "pet", "Lone Wolf: dismiss pet") if r then return r end
      end
    end
    if o.trueshotReminder and C.absent(s.playerBuffs, "TrueshotAura") then
      r = x.rec("TrueshotAura", "buff", "Maintain Trueshot Aura") if r then return r end
    end
    if o.aspectReminder and s.travelAspectActive ~= true and s.otherAspectActive ~= true then
      r = x.try(x.P.aspect, C.absent(s.playerBuffs, x.P.aspect), "buff", "Maintain combat aspect")
      if r then return r end
      if x.P.aspectFallback then
        r = x.try(x.P.aspectFallback, C.absent(s.playerBuffs, x.P.aspectFallback)
          and not (type(s.known) == "table" and s.known[x.P.aspect] == true), "buff", "Early-level aspect")
        if r then return r end
      end
    end
  elseif s.travelAspectActive == true then
    r = x.rec(x.P.aspect, "survival", "Leave travel aspect in combat") if r then return r end
    if x.P.aspectFallback then return x.rec(x.P.aspectFallback, "survival", "Leave travel aspect in combat") end
  end
end

function C.Survival(x)
  local s, o = x.s, x.o
  if s.inCombat ~= true then return nil end
  local hp, grp, r = s.healthPercent, C.group(s) or s.inGroup == true, nil
  if o.feign ~= "manual" then
    local danger = num(hp) and hp <= o.feignSoloAt
    if o.feign == "contextual" and grp and s.hasAggro == true
       and (s.tankHasAggro == false or s.threatHigh == true) then
      r = x.rec("FeignDeath", "survival", "Dangerous group threat") if r then return r end
    end
    if danger and s.hasAggro == true then
      r = x.rec("FeignDeath", "survival", "Emergency threat reset") if r then return r end
    end
    if o.feign == "contextual" and grp and num(hp) and hp <= o.feignGroupAt and s.hasAggro == true then
      r = x.rec("FeignDeath", "survival", "Low HP with group aggro") if r then return r end
    end
  end
  if num(hp) and hp <= o.deterrenceAt and s.hasAggro ~= false then
    r = x.rec("Deterrence", "survival", "Defensive cooldown") if r then return r end
  end
  if C.petWanted(s, o) == true and s.petExists == true and s.petDead ~= true and num(s.petHealthPercent)
     and s.petHealthPercent <= o.petMendAt and s.petMendActive == false then
    r = x.rec("MendPet", "survival", "Heal injured pet") if r then return r end
  end
  if C.melee(s) and s.hasAggro == true and (x.P.escapeAlways or s.needEscape == true) then
    r = x.rec("Disengage", "survival", "Create distance") if r then return r end
    if o.traps ~= "off" and s.trapSharedReady ~= false and s.targetCanBeControlled == true
       and s.breakableCCNearby == false then
      r = x.rec("FreezingTrap", "control", "Control attacker") if r then return r end
    end
    if o.traps ~= "off" then
      r = x.try("FrostTrap", s.trapSharedReady ~= false, "control", "Slow nearby enemies") if r then return r end
    end
    r = x.try("WingClip", C.absent(s.targetDebuffs, "WingClip"), "control", "Slow attacker")
    if r then return r end
  end
  if o.pvpControl and s.targetPlayer == true and s.targetCastingDangerous == true and s.targetCanBeControlled == true then
    r = x.rec("ScatterShot", "control", "Stop dangerous cast") if r then return r end
    r = x.rec("ConcussiveShot", "control", "Slow hostile player") if r then return r end
  end
end

-- Pet attack is a command, not a spell; emitted as a separate action type.
function C.PetAttack(x)
  local s, o = x.s, x.o
  if o.petAttackCommand and C.petWanted(s, o) == true and s.petExists == true and s.petDead ~= true
     and s.petAttackingTarget == false and s.targetHostile == true and s.targetAttackable ~= false then
    return { action = "PET_ATTACK", phase = "pull", reason = "Send pet to target" }
  end
end

-- Shared entry: builds Next() from a profile definition P with P.rotate(x).
function C.NewProfile(P)
  P.Config = C.Merge(C.CommonConfig, P.ExtraConfig or {})
  P.Defaults = C.Defaults(P.Config)
  function P.Resolve(o) return C.Resolve(P.Config, o) end
  function P.Next(state, options)
    if type(state) ~= "table" then return nil end
    local s = C.Normalize(state)
    local lv = s.playerLevel
    if not num(lv) or lv < P.minLevel or lv > P.maxLevel then return nil end
    local x = C.Context(P, s, C.Resolve(P.Config, options))
    local r = C.Survival(x) if r then return r end
    r = C.Maintenance(x) if r then return r end
    if s.targetValid ~= true or s.targetHostile ~= true or s.targetAlive == false
       or s.targetAttackable == false then return nil end
    if s.currentCast ~= nil and s.currentCast ~= false then return nil end
    return P.rotate(x)
  end
  return P
end

return C
