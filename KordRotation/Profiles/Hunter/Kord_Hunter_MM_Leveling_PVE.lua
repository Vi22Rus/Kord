-- Kord Rotation | Hunter Marksmanship | Leveling 1-59 | PVE | WoW Forever
-- Requires Kord_Hunter_Common.lua loaded first. No direct WoW API.
-- Interface: MM.Next(state, options) -> {spellID, spell, phase, reason} | {action="PET_ATTACK",...} | nil
local C = KordHunterCommon
local E, N = C.E, C.N
local S = {
  AutoShot=75, RaptorStrike=2973, MongooseBite=1495, SerpentSting=1978, ArcaneShot=3044,
  ConcussiveShot=5116, WingClip=2974, AspectMonkey=13163, AspectHawk=13165, CallPet=883,
  RevivePet=982, MendPet=136, FeedPet=6991, MultiShot=2643, AimedShot=19434, HuntersMark=1130,
  RapidFire=3045, FeignDeath=5384, Disengage=781, FreezingTrap=1499, FrostTrap=13809,
  ExplosiveTrap=13813, ImmolationTrap=13795, Volley=1510, Deterrence=19263, ScatterShot=19503,
  TrueshotAura=1299346, SniperShot=1310687, SummonHawk=1293241, DismissPet=2641,
}
local MM = { id = "HUNTER_MM_LEVELING", version = "2.0.0-design", minLevel = 1, maxLevel = 59,
  Spells = S, aspect = "AspectHawk", aspectFallback = "AspectMonkey" }

MM.ExtraConfig = {
  E("aimed", "smart", { "smart", "always", "off" }, "rotation", "Aimed Shot",
    "smart: only vs strong targets, in groups, or when the fight is long; always: main shot; off.",
    "Guides disagree: Aimed Shot as main leveling shot (long cast, mana) vs. Arcane+Auto filler."),
  N("aimedMinTTD", 8, 0, 100, "rotation", "Aimed (smart): min time-to-die (s)", ""),
  E("sniper", "smart", { "smart", "opener", "proc", "cooldown", "off" }, "rotation", "Sniper Shot",
    "smart: strong/group/proc; opener: before combat; proc: only with Rapid Killing; cooldown: always.", nil),
  N("sniperMinTTD", 5, 0, 100, "rotation", "Sniper: min time-to-die (s)", ""),
  E("multi", "smart", { "smart", "aoe_only", "opportunistic", "off" }, "rotation", "Multi-Shot",
    "smart: AoE, plus single-target in groups; aoe_only: 2+ safe targets; opportunistic: always.", nil),
  E("arcane", "balanced", { "balanced", "aggressive", "conserve", "off" }, "rotation", "Arcane Shot filler",
    "balanced: above reserve; conserve: reserve+35; aggressive: always.", nil),
  E("hawk", "smart", { "smart", "aggressive", "off" }, "rotation", "Summon Hawk",
    "smart: when adapter says refresh needed; aggressive: whenever ready; off.", nil),
}
C.NewProfile(MM)

local function meleePhase(x)
  local s, o = x.s, x.o
  local r
  if s.hasAggro == true or s.targetPlayer == true then
    r = x.try("WingClip", C.absent(s.targetDebuffs, "WingClip"), "control", "Slow enemy to regain distance") if r then return r end
    r = x.rec("ScatterShot", "control", "Create distance") if r then return r end
    if o.traps ~= "off" and s.trapSharedReady ~= false then
      r = x.rec("FreezingTrap", "control", "Peel enemy") if r then return r end
      r = x.rec("FrostTrap", "control", "Slow enemy") if r then return r end
    end
  end
  if o.traps == "offensive" and C.aoeOK(s, o) and s.trapSharedReady ~= false and s.trapPlacementSafe == true then
    r = x.rec("ExplosiveTrap", "aoe", "Melee-range AoE") if r then return r end
  end
  r = x.rec("MongooseBite", "melee", "Counterattack") if r then return r end
  return x.rec("RaptorStrike", "melee", "Melee fallback")
end

function MM.rotate(x)
  local s, o = x.s, x.o
  if C.melee(s) then return meleePhase(x) end
  if not C.ranged(s) then
    -- Dead zone: ranged shots impossible; only ground traps are castable.
    if s.hasAggro == true and s.inMeleeRange == false and o.traps ~= "off" and s.trapSharedReady ~= false then
      return x.rec("FrostTrap", "control", "Slow pursuer from dead zone")
    end
    return nil
  end
  local r = C.PetAttack(x)
  if r then return r end
  if C.markWorth(s, o) and C.absent(s.targetDebuffs, "HuntersMark") then
    r = x.rec("HuntersMark", "debuff", "Mark target") if r then return r end
  end
  if C.rapidWorth(s, o) then r = x.rec("RapidFire", "cooldown", "Offensive cooldown") if r then return r end end
  if C.stingWorth(s, o) and C.absent(s.targetDebuffs, "SerpentSting") and C.mana(s, o.manaReserve) then
    r = x.rec("SerpentSting", "debuff", "Sting target") if r then return r end
  end
  if s.autoShotActive == false then r = x.rec("AutoShot", "damage", "Start Auto Shot") if r then return r end end
  local moving = s.moving ~= false
  local aoe = C.aoeOK(s, o)
  if aoe and o.multi ~= "off" and C.autoWindow(s, o, 0.5) then
    r = x.rec("MultiShot", "aoe", "Multiple safe targets") if r then return r end
  end
  if aoe and s.enemyCount >= o.volleyTargets and not moving and s.canFinishCast == true
     and C.mana(s, o.volleyMinMana) and (s.aoeGroundSafe == true or o.aoe == "aggressive") then
    r = x.rec("Volley", "aoe", "Large safe group") if r then return r end
  end
  if not moving then
    local longFight = type(s.targetTTD) == "number" and s.targetTTD >= o.aimedMinTTD
    local aimedOK = o.aimed == "always" or (o.aimed == "smart" and (C.strong(s) or C.group(s) or longFight))
    if s.rapidKillingProc == true and o.aimed ~= "off" then
      r = x.rec("AimedShot", "damage", "Spend Rapid Killing proc") if r then return r end
    end
    local sm = o.sniper
    local sniperOK = sm ~= "off" and s.canFinishCast == true and type(s.targetTTD) == "number" and s.targetTTD >= o.sniperMinTTD
      and (sm == "cooldown" or (sm == "proc" and s.rapidKillingProc == true) or (sm == "opener" and s.inCombat == false)
        or (sm == "smart" and (s.rapidKillingProc == true or C.strong(s) or C.group(s))))
    if sniperOK and C.autoWindow(s, o, 3) then r = x.rec("SniperShot", "damage", "Long cast when safe") if r then return r end end
    if aimedOK and C.autoWindow(s, o, 0) then r = x.rec("AimedShot", "damage", "Main single-target shot") if r then return r end end
  end
  if o.multi == "opportunistic" or (o.multi == "smart" and s.inCombat == true and C.group(s)) then
    r = x.rec("MultiShot", "damage", "Instant shot") if r then return r end
  end
  if o.hawk ~= "off" and (o.hawk == "aggressive" or s.hawkRefreshNeeded == true) then
    r = x.rec("SummonHawk", "damage", "Refresh summoned hawk") if r then return r end
  end
  if o.arcane ~= "off" and (o.arcane == "aggressive" or (o.arcane == "balanced" and C.mana(s, o.manaReserve))
     or (o.arcane == "conserve" and C.mana(s, o.manaReserve + 35))) and C.autoWindow(s, o, 0.5) then
    r = x.rec("ArcaneShot", "damage", "Instant filler") if r then return r end
  end
  return nil
end
return MM
