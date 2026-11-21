-- Kord Rotation | Hunter Marksmanship | Level 60 | PVE | WoW Forever
-- Requires Kord_Hunter_Common.lua loaded first. No direct WoW API.
-- Interface: MM.Next(state, options) -> {spellID, spell, phase, reason} | {action="PET_ATTACK",...} | nil
-- MM.Config is the CFG schema for the addon UI (see Common for entry format).
local C = KordHunterCommon
local E, B, N = C.E, C.B, C.N
local S = {
  AutoShot=75, HuntersMark=1130, SerpentSting=1978, ArcaneShot=3044, AimedShot=19434,
  MultiShot=2643, SniperShot=1310687, RapidFire=3045, Volley=1510, TrueshotAura=1299346,
  AspectHawk=13165, RaptorStrike=2973, MongooseBite=1495, WingClip=2974, ConcussiveShot=5116,
  ScatterShot=19503, FreezingTrap=1499, FrostTrap=13809, ExplosiveTrap=13813, ImmolationTrap=13795,
  FeignDeath=5384, Deterrence=19263, Disengage=781, CallPet=883, RevivePet=982, MendPet=136,
  DismissPet=2641, FeedPet=6991,
}
local MM = { id = "HUNTER_MM_60", version = "2.0.0-design", minLevel = 60, maxLevel = 60,
  Spells = S, aspect = "AspectHawk", escapeAlways = true }

MM.ExtraConfig = {
  E("aimed", "priority", { "priority", "off" }, "rotation", "Aimed Shot",
    "priority: main single-target shot while standing still.", nil),
  E("multi", "cleave", { "cleave", "group", "on_cooldown", "off" }, "rotation", "Multi-Shot",
    "cleave: only vs 2+ safe targets; group: also single-target in dungeon/raid; on_cooldown: always.",
    "Guides disagree on Multi-Shot in single-target: mana cost vs extra DPS. Default cleave."),
  E("volley", "safe", { "safe", "aggressive", "off" }, "rotation", "Volley",
    "safe: needs aoeGroundSafe; aggressive: ignores ground safety; off.", nil),
  E("sniper", "safe", { "safe", "opener", "on_cooldown", "off" }, "rotation", "Sniper Shot",
    "safe: strong targets/group content; opener: only before combat; on_cooldown: always.", nil),
  E("arcane", "balanced", { "balanced", "aggressive", "conserve", "off" }, "rotation", "Arcane Shot filler",
    "balanced: above mana reserve; conserve: reserve+20; aggressive: always.", nil),
  N("sniperMinTTD", 5, 0, 100, "rotation", "Sniper: min time-to-die (s)", ""),
  N("sniperMinAutoWindow", 4, 0, 10, "weaving", "Sniper: min swing time left (s)", ""),
  N("aimedMinAutoWindow", 0, 0, 10, "weaving", "Aimed: min swing time left (s)", ""),
  N("multiMinAutoWindow", 0.5, 0, 10, "weaving", "Multi: min swing time left (s)", ""),
  N("arcaneMinAutoWindow", 0.5, 0, 10, "weaving", "Arcane: min swing time left (s)", ""),
}
C.NewProfile(MM)

local function melee(x)
  local r = x.rec("MongooseBite", "melee", "Reactive counterattack")
  if r then return r end
  r = x.rec("RaptorStrike", "melee", "Melee damage in dead zone")
  if r then return r end
  return x.try("WingClip", C.absent(x.s.targetDebuffs, "WingClip"), "control", "Create distance")
end

function MM.rotate(x)
  local s, o = x.s, x.o
  if C.melee(s) then return melee(x) end
  if not C.ranged(s) then return nil end
  local r = C.PetAttack(x)
  if r then return r end
  if C.rapidWorth(s, o) then
    r = x.rec("RapidFire", "cooldown", "Rapid Fire on worthwhile target") if r then return r end
  end
  if C.markWorth(s, o) and C.absent(s.targetDebuffs, "HuntersMark") then
    r = x.rec("HuntersMark", "debuff", "Mark target") if r then return r end
  end
  if C.stingWorth(s, o) and C.absent(s.targetDebuffs, "SerpentSting") and C.mana(s, o.stingMinMana) then
    r = x.rec("SerpentSting", "debuff", "Maintain Sting") if r then return r end
  end
  if s.autoShotActive == false then
    r = x.rec("AutoShot", "damage", "Start Auto Shot") if r then return r end
  end
  local moving = s.moving ~= false           -- unknown movement blocks casts
  local aoe = C.aoeOK(s, o)
  if aoe and o.multi ~= "off" and C.autoWindow(s, o, o.multiMinAutoWindow) then
    r = x.rec("MultiShot", "aoe", "Cleave on safe group") if r then return r end
  end
  if aoe and o.volley ~= "off" and s.enemyCount >= o.volleyTargets and not moving
     and s.canFinishCast == true and C.mana(s, o.volleyMinMana)
     and (o.volley == "aggressive" or s.aoeGroundSafe == true) then
    r = x.rec("Volley", "aoe", "Sustained AoE") if r then return r end
  end
  if o.aimed ~= "off" and not moving and C.autoWindow(s, o, o.aimedMinAutoWindow) then
    r = x.rec("AimedShot", "damage", s.rapidKillingProc == true and "Spend Rapid Killing proc" or "Main single-target shot")
    if r then return r end
  end
  if o.sniper ~= "off" and not moving and s.canFinishCast == true and type(s.targetTTD) == "number"
     and s.targetTTD >= o.sniperMinTTD and (o.sniper ~= "opener" or s.inCombat == false)
     and (o.sniper ~= "safe" or C.strong(s) or C.group(s))
     and C.autoWindow(s, o, o.sniperMinAutoWindow) then
    r = x.rec("SniperShot", "damage", "Safe Sniper window") if r then return r end
  end
  if o.arcane ~= "off" and (o.arcane == "aggressive" or (o.arcane == "balanced" and C.mana(s, o.manaReserve))
     or (o.arcane == "conserve" and C.mana(s, o.manaReserve + 20))) and C.autoWindow(s, o, o.arcaneMinAutoWindow) then
    r = x.rec("ArcaneShot", "damage", "Instant filler") if r then return r end
  end
  if not aoe and (o.multi == "on_cooldown" or (o.multi == "group" and C.group(s) and s.inCombat == true))
     and C.autoWindow(s, o, o.multiMinAutoWindow) then
    r = x.rec("MultiShot", "damage", "Single-target Multi-Shot") if r then return r end
  end
  return nil
end
return MM
