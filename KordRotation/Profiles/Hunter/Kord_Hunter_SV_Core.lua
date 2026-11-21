-- Kord Rotation | Hunter Survival | Shared core for SV 60 and SV Leveling
-- Load after Kord_Hunter_Common.lua and before the two SV profiles. No direct WoW API.
local C = KordHunterCommon
local E, B, N = C.E, C.B, C.N

C.SVConfig = {
  E("combatStyle", "auto", { "auto", "melee", "weave", "ranged" }, "style", "Combat style",
    "auto: melee when in range, shots while closing; melee: never spend mana on shots if melee reachable; " ..
    "weave: non-reactive melee GCDs only inside a confirmed swing window; ranged: only reactive melee skills in melee.",
    "Guides disagree: full melee vs. ranged-weave for Survival."),
  E("manaStyle", "maximum", { "maximum", "balanced", "efficient" }, "style", "Mana style",
    "maximum: Kick+Raptor always; balanced: Raptor only solo; efficient: Kick+Raptor only solo (groups).",
    "Guides disagree on spending mana on Raptor Strike / Strider Kick in dungeons."),
  B("exposePreyMark", true, "debuffs", "Mark with Expose Prey talent",
    "With the talent, Hunter's Mark is worth it on ordinary targets too."),
  B("rapidFireInMelee", true, "cooldowns", "Rapid Fire while meleeing",
    "Off = Rapid Fire only when at range."),
  N("lacerateMinTargetHP", 30, 0, 100, "melee", "Lacerate: min target HP %", ""),
  N("bossBleedMinTTD", 12, 0, 100, "melee", "Lacerate on elites/bosses: min TTD (s)", ""),
  B("immolationTrap", true, "traps", "Immolation Trap in melee", "Only on strong targets, in groups, or solo with Resourcefulness."),
}

local function style(x)
  local s, o = x.s, x.o
  local lvl = s.playerLevel
  local grp = C.group(s)
  local m = o.manaStyle
  local skipKick, skipRaptor
  if x.P.leveling then
    local l = type(lvl) == "number" and lvl or 0
    skipKick = grp and l >= 40 and (m == "efficient" or (m == "balanced" and l < 50))
    skipRaptor = grp and (m ~= "maximum" or (l >= 30 and l < 40))
  else
    skipKick = grp and m == "efficient"
    skipRaptor = grp and m ~= "maximum"
  end
  return skipKick, skipRaptor
end

local function markWanted(x)
  local s, o = x.s, x.o
  if C.markWorth(s, o) then return true end
  return o.exposePreyMark and o.mark ~= "off" and o.mark ~= "boss" and o.mark ~= "elite"
    and C.present(s.talents, "ExposePrey")
end

local function meleeDamage(x)
  local s, o = x.s, x.o
  if not C.melee(s) then return nil end
  local safe = s.targetCrowdControlled == false and s.breakableCCNearby ~= true
  if not safe then return nil end
  local combat = o.combatStyle
  local weaving = combat == "weave" and s.meleeSwingWindow ~= true
  local spend = combat ~= "ranged" and not weaving
  local skipKick, skipRaptor = style(x)
  local questing = s.inDungeon == false and s.inRaid == false
  local r
  if spend and questing and o.manaStyle ~= "efficient" then
    r = x.rec("StriderKick", "melee", "Questing opener: Strider Kick") if r then return r end
  end
  if markWanted(x) and C.absent(s.targetDebuffs, "HuntersMark") then
    r = x.rec("HuntersMark", "debuff", "Mark valuable target") if r then return r end
  end
  r = x.rec("MongooseBite", "melee", "Reactive dodge window") if r then return r end
  r = x.rec("Counterattack", "melee", "Reactive parry window") if r then return r end
  if spend and not skipKick then
    r = x.rec("StriderKick", "melee", "Weapon-damage kick") if r then return r end
  end
  if spend and not skipRaptor and s.raptorStrikeQueued == false then
    r = x.rec("RaptorStrike", "melee", "Queue next swing once") if r then return r end
  end
  if spend and type(s.targetHealthPercent) == "number" and s.targetHealthPercent > o.lacerateMinTargetHP
     and (not C.strong(s) or (type(s.targetTTD) == "number" and s.targetTTD >= o.bossBleedMinTTD)) then
    local rem = type(s.targetDebuffRemaining) == "table" and s.targetDebuffRemaining.Lacerate or nil
    local refresh = C.absent(s.targetDebuffs, "Lacerate")
      or (not C.group(s) and type(rem) == "number" and rem <= 2 and C.present(s.targetDebuffs, "Lacerate"))
    if refresh then r = x.rec("Lacerate", "melee", "Maintain bleed") if r then return r end end
  end
  if spend and o.traps ~= "off" and o.immolationTrap and s.trapSharedReady == true and s.trapPlacementSafe == true then
    local lowLevel = x.P.leveling and type(s.playerLevel) == "number" and s.playerLevel < 30
    if C.strong(s) or C.group(s) or (questing and (lowLevel or C.present(s.talents, "Resourcefulness"))) then
      r = x.rec("ImmolationTrap", "trap", "Single-target fire trap") if r then return r end
    end
  end
  if s.autoMeleeActive == false and s.autoSwitching ~= true then
    return x.rec("Attack", "auto", "Keep melee auto-attacking")
  end
end

local function aoe(x)
  local s, o = x.s, x.o
  if not C.aoeOK(s, o) or s.targetCrowdControlled ~= false then return nil end
  local r
  if C.melee(s) and o.traps == "offensive" and s.trapSharedReady == true and s.trapPlacementSafe == true then
    r = x.rec("ExplosiveTrap", "aoe", "AoE fire trap") if r then return r end
  end
  if C.ranged(s) then
    r = x.rec("MultiShot", "aoe", "Cleave") if r then return r end
    if s.enemyCount >= o.volleyTargets and s.moving == false and s.canFinishCast == true
       and C.mana(s, o.volleyMinMana) and (s.aoeGroundSafe == true or o.aoe == "aggressive") then
      r = x.rec("Volley", "aoe", "Sustained AoE channel") if r then return r end
    end
  end
end

local function rangedDamage(x)
  local s, o = x.s, x.o
  if not C.ranged(s) then return nil end
  local preferMelee = o.combatStyle == "melee" and s.canReachMelee == true
  local r
  if markWanted(x) and C.absent(s.targetDebuffs, "HuntersMark") then
    r = x.rec("HuntersMark", "debuff", "Mark valuable target") if r then return r end
  end
  if preferMelee then
    if s.autoShotActive == false then return x.rec("AutoShot", "auto", "Auto Shot while closing") end
    return nil
  end
  if C.stingWorth(s, o) and C.absent(s.targetDebuffs, "SerpentSting") and C.mana(s, o.stingMinMana) then
    r = x.rec("SerpentSting", "debuff", "Sting while closing") if r then return r end
  end
  if s.autoShotActive == false then r = x.rec("AutoShot", "auto", "Start Auto Shot") if r then return r end end
  if s.moving == false and s.canFinishCast == true and C.autoWindow(s, o, 0) then
    r = x.rec("AimedShot", "ranged", "Ranged fallback: Aimed Shot") if r then return r end
  end
  if C.mana(s, o.manaReserve + 5) and C.autoWindow(s, o, 0.5) then
    return x.rec("ArcaneShot", "ranged", "Ranged fallback: Arcane Shot")
  end
end

function C.SVRotate(x)
  local s, o = x.s, x.o
  if s.targetPlayer == true then return nil end                 -- PVE profile
  if s.targetCrowdControlled ~= false then return nil end       -- never hit a controlled target
  if type(s.enemyCount) == "number" and s.enemyCount >= 2 and s.breakableCCNearby ~= false then return nil end
  if C.rapidWorth(s, o) and (C.ranged(s) or (o.rapidFireInMelee and (C.melee(s) or C.group(s)))) then
    local r = x.rec("RapidFire", "cooldown", "Attack speed for meaningful fight") if r then return r end
  end
  local r = C.PetAttack(x) if r then return r end
  r = aoe(x) if r then return r end
  r = meleeDamage(x) if r then return r end
  return rangedDamage(x)
end
return C
