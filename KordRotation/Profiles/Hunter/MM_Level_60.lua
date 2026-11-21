-- Kord Rotation | Hunter Marksmanship | Level 60 | WoW Forever
-- Design profile: NOT loaded by TOC; no direct WoW API calls.
-- Sonah is primary reference; MaxDps, JustAC, RotationGuide, ForeverRotation corroborate.
-- The shared GameData adapter supplies the fields described below.
-- READY means an explicit known/ready true; UNKNOWN must never become true.
-- Output: one suggested action; this module does not cast spells.
local MM = {id="HUNTER_MM_60", version="1.0.0-design", level=60}
local S = {
 AutoShot=75, HuntersMark=1130, SerpentSting=1978, ArcaneShot=3044,
 AimedShot=19434, MultiShot=2643, SniperShot=1310687, RapidFire=3045,
 Volley=1510, TrueshotAura=1299346, AspectHawk=13165,
 RaptorStrike=2973, MongooseBite=1495, WingClip=2974,
 ConcussiveShot=5116, ScatterShot=19503, FreezingTrap=1499,
 FrostTrap=13809, ExplosiveTrap=13813, ImmolationTrap=13795,
 FeignDeath=5384, Deterrence=19263, Disengage=781,
 CallPet=883, RevivePet=982, MendPet=136, DismissPet=2641,
 ViperSting=3034, ScorpidSting=3043
}
MM.Spells=S
MM.Defaults={
 context="auto", mark="priority", sting="long", rapidFire="boss",
 sniper="safe", aimed="priority", multi="cleave", volley="safe",
 arcane="balanced", aoe="safe", traps="defensive", pet="auto",
 feign="contextual", petReminder=true, aspectReminder=true,
 trueshotReminder=true, pvpControl=true,
 manaReserve=25, stingMinTTD=12, sniperMinTTD=5,
 sniperMinAutoWindow=4, aimedMinAutoWindow=0,
 multiMinAutoWindow=0.5, arcaneMinAutoWindow=0.5,
 volleyTargets=4, petMendAt=40, feignSoloAt=30,
 feignGroupAt=45, deterrenceAt=35, rapidMinTTD=15
}
MM.Options={
 context={"auto","raid","dungeon","world","pvp"},
 mark={"priority","all","boss","off"},
 sting={"long","all","boss","off"},
 rapidFire={"boss","on_cooldown","manual","off"},
 sniper={"safe","opener","on_cooldown","off"},
 aimed={"priority","off"},
 multi={"cleave","group","on_cooldown","off"},
 volley={"safe","aggressive","off"},
 arcane={"balanced","aggressive","conserve","off"},
 aoe={"safe","aggressive","off"},traps={"defensive","offensive","off"},
 pet={"auto","pet","lone_wolf"},
 feign={"contextual","emergency","manual"}
}
-- Canonical shared signals (all optional until the adapter can verify them):
-- known[name], ready[name], playerBuffs[name], targetDebuffs[name]
-- targetValid, targetHostile, inCombat, inDungeon, inRaid, inPvP,
-- targetBoss, targetElite, targetPlayer, targetHealthPercent, targetTTD,
-- healthPercent, manaPercent, hasAggro, threatHigh, tankHasAggro,
-- enemyCount, aoeSafe, crowdControlNearby, inMeleeRange, inRangedRange,
-- moving, canFinishLongCast, autoShotActive, rangedSwingRemaining,
-- currentCast, targetCanBeControlled, targetCastingDangerous,
-- petExists, petDead, petHealthPercent, petMendActive, petAttacking,
-- talents.LoneWolf. A missing value is UNKNOWN, not a favorable state.
local function option(o,k)
 local value=type(o)=="table" and o[k] or nil
 local allowed=MM.Options[k]
 if allowed then
  for _,v in ipairs(allowed) do if value==v then return value end end
  return MM.Defaults[k]
 end
 if type(MM.Defaults[k])=="boolean" then
  return type(value)=="boolean" and value or MM.Defaults[k]
 end
 if type(value)=="number" and value==value and value>=0 and value<=100 then return value end
 return MM.Defaults[k]
end
local function yes(s,k) return s[k]==true end
local function known(s,k) return type(s.known)=="table" and s.known[k]==true end
local function ready(s,k) return known(s,k) and type(s.ready)=="table" and s.ready[k]==true end
local function absent(t,k) return type(t)=="table" and t[k]==false end
local function present(t,k) return type(t)=="table" and t[k]==true end
local function action(s,k,phase,reason)
 if not ready(s,k) then return nil end
 return {spellID=S[k],spell=k,phase=phase,reason=reason}
end
local function try(s,k,condition,phase,reason)
 if condition then return action(s,k,phase,reason) end
end
local function strong(s) return yes(s,"targetBoss") or yes(s,"targetElite") or yes(s,"targetPlayer") end
local function groupContent(s) return yes(s,"inDungeon") or yes(s,"inRaid") end
local function context(s,o)
 local x=option(o,"context")
 if x~="auto" then return x end
 if yes(s,"inRaid") then return "raid" end
 if yes(s,"inDungeon") then return "dungeon" end
 if yes(s,"inPvP") then return "pvp" end
 return "world"
end
local function manaOK(s,o,extra)
 return type(s.manaPercent)=="number" and s.manaPercent>=option(o,"manaReserve")+(extra or 0)
end
local function aoeOK(s,o)
 if option(o,"aoe")=="off" or type(s.enemyCount)~="number" or s.enemyCount<2 then return false end
 if option(o,"aoe")=="safe" and (s.aoeSafe~=true or s.crowdControlNearby~=false) then return false end
 return true
end
local function ranged(s)
 -- A verified range is mandatory; do not treat unknown range as safe.
 return s.inRangedRange==true and s.inMeleeRange~=true
end
local function autoWindow(s,seconds)
 return type(s.rangedSwingRemaining)=="number" and s.rangedSwingRemaining>=seconds
end
local function noCast(s) return s.currentCast==false or s.currentCast==nil end
local function petWanted(s,o)
 local p=option(o,"pet")
 if p=="pet" then return true end
 if p=="lone_wolf" then return false end
 if type(s.talents)~="table" then return nil end
 if s.talents.LoneWolf==true then return false end
 if s.talents.LoneWolf==false then return true end
 return nil
end
local function worthMark(s,o)
 local mode=option(o,"mark")
 if mode=="off" then return false end
 if mode=="all" then return true end
 if mode=="boss" then return yes(s,"targetBoss") end
 return strong(s) or groupContent(s)
end
local function worthSting(s,o)
 local mode=option(o,"sting")
 if mode=="off" then return false end
 if mode=="all" then return true end
 if mode=="boss" then return yes(s,"targetBoss") end
 return type(s.targetTTD)=="number" and s.targetTTD>=option(o,"stingMinTTD")
end
local function maintenance(s,o)
 local pet=petWanted(s,o)
 if option(o,"petReminder") and not yes(s,"inCombat") and pet==true then
  local r=try(s,"RevivePet",s.petDead==true,"maintenance","Revive dead pet")
  if r then return r end
  r=try(s,"CallPet",s.petExists==false and s.petDead==false,"maintenance","Call missing pet")
  if r then return r end
 end
 if option(o,"petReminder") and not yes(s,"inCombat") and pet==false then
  local r=try(s,"DismissPet",s.petExists==true,"maintenance","Lone Wolf: dismiss pet")
  if r then return r end
 end
 if option(o,"trueshotReminder") and absent(s.playerBuffs,"TrueshotAura") then
  local r=action(s,"TrueshotAura","maintenance","Maintain Trueshot Aura")
  if r then return r end
 end
 if option(o,"aspectReminder") and absent(s.playerBuffs,"AspectHawk")
   and s.otherAspectActive==false then
  return action(s,"AspectHawk","maintenance","Maintain combat aspect")
 end
end
local function survival(s,o)
 local hp=s.healthPercent
 local group=groupContent(s)
 local mode=option(o,"feign")
 if yes(s,"inCombat") and mode~="manual" then
  local emergency=type(hp)=="number" and hp<=option(o,"feignSoloAt")
  local groupDanger=group and (s.hasAggro==true or s.threatHigh==true)
    and (s.tankHasAggro==false or s.threatHigh==true)
  if mode=="contextual" and groupDanger then
   local r=action(s,"FeignDeath","survival","Reduce dangerous group threat")
   if r then return r end
  end
  if emergency and (s.hasAggro==true or (group and s.hasAggro~=false)) then
   local r=action(s,"FeignDeath","survival","Emergency threat reset")
   if r then return r end
  end
  if group and type(hp)=="number" and hp<=option(o,"feignGroupAt")
    and s.hasAggro==true then
   local r=action(s,"FeignDeath","survival","Low-health group threat reset")
   if r then return r end
  end
 end
 if yes(s,"inCombat") and type(hp)=="number" and hp<=option(o,"deterrenceAt") then
  local r=action(s,"Deterrence","survival","Survival defensive cooldown")
  if r then return r end
 end
 local pet=petWanted(s,o)
 if pet==true and s.petExists==true and type(s.petHealthPercent)=="number"
   and s.petHealthPercent<=option(o,"petMendAt") and s.petMendActive==false then
  local r=action(s,"MendPet","survival","Heal injured pet")
  if r then return r end
 end
 if yes(s,"inCombat") and yes(s,"inMeleeRange") and s.hasAggro==true then
  local r=action(s,"Disengage","survival","Create distance")
  if r then return r end
  if option(o,"traps")~="off" then
   r=try(s,"FreezingTrap",s.targetCanBeControlled==true and s.crowdControlNearby==false,
     "control","Control attacker")
   if r then return r end
   r=action(s,"FrostTrap","control","Slow nearby enemies")
   if r then return r end
  end
  r=action(s,"WingClip","control","Slow attacker to escape")
  if r then return r end
 end
 if option(o,"pvpControl") and yes(s,"targetPlayer") and yes(s,"targetCastingDangerous")
   and s.targetCanBeControlled==true then
  local r=action(s,"ScatterShot","control","Stop dangerous cast")
  if r then return r end
  r=action(s,"ConcussiveShot","control","Slow hostile player")
  if r then return r end
 end
end
local function melee(s,o)
 if not yes(s,"inMeleeRange") then return nil end
 local r=action(s,"MongooseBite","melee","Available melee counterattack")
 if r then return r end
 r=action(s,"RaptorStrike","melee","Melee damage while in dead zone")
 if r then return r end
 return try(s,"WingClip",absent(s.targetDebuffs,"WingClip"),"melee","Create distance")
end
local function burst(s,o,ctx)
 local mode=option(o,"rapidFire")
 if mode=="off" or mode=="manual" or not yes(s,"inCombat") then return nil end
 local worth=mode=="on_cooldown" or yes(s,"targetBoss") or
  (strong(s) and type(s.targetTTD)=="number" and s.targetTTD>=option(o,"rapidMinTTD"))
 if ctx=="world" and mode=="boss" and not strong(s) then worth=false end
 return try(s,"RapidFire",worth and ranged(s),"cooldown","Rapid Fire for sustained damage")
end
local function rangedDamage(s,o,ctx)
 if not ranged(s) then return nil end
 local aoe=aoeOK(s,o)
 local moving=yes(s,"moving")
 local r
 if worthMark(s,o) and absent(s.targetDebuffs,"HuntersMark") then
  r=action(s,"HuntersMark","debuff","Mark priority target")
  if r then return r end
 end
 if worthSting(s,o) and absent(s.targetDebuffs,"SerpentSting") and manaOK(s,o,0) then
  r=action(s,"SerpentSting","debuff","Maintain sting on worthwhile target")
  if r then return r end
 end
 if aoe and option(o,"multi")~="off" then
  local mode=option(o,"multi")
  if (mode=="on_cooldown" or mode=="cleave" or groupContent(s) or s.enemyCount>=2)
    and (autoWindow(s,option(o,"multiMinAutoWindow")) or s.autoShotActive==false) then
   r=action(s,"MultiShot","aoe","Instant cleave; shared cooldown with Aimed Shot")
   if r then return r end
  end
 end
 if aoe and option(o,"volley")~="off" and type(s.enemyCount)=="number"
   and s.enemyCount>=option(o,"volleyTargets") and not moving
   and s.canFinishLongCast==true and s.aoeGroundSafe==true then
  r=action(s,"Volley","aoe","Sustained AoE on stable pack")
  if r then return r end
 end
 -- Rapid Killing proc favors Aimed Shot; unknown proc does not activate this branch.
 if option(o,"aimed")~="off" and not moving and s.rapidKillingProc==true
   and (autoWindow(s,option(o,"aimedMinAutoWindow")) or s.autoShotActive==false) then
  r=action(s,"AimedShot","damage","Spend Rapid Killing proc")
  if r then return r end
 end
 if option(o,"aimed")~="off" and not moving
   and (autoWindow(s,option(o,"aimedMinAutoWindow")) or s.autoShotActive==false) then
  r=action(s,"AimedShot","damage","Single-target priority; shares cooldown with Multi-Shot")
  if r then return r end
 end
 local sniperMode=option(o,"sniper")
 if sniperMode~="off" and not moving and s.canFinishLongCast==true
   and type(s.targetTTD)=="number" and s.targetTTD>=option(o,"sniperMinTTD")
   and (sniperMode~="opener" or s.inCombat==false)
   and (sniperMode=="on_cooldown" or sniperMode=="opener" or strong(s) or groupContent(s))
   and (autoWindow(s,option(o,"sniperMinAutoWindow")) or s.autoShotActive==false) then
  r=action(s,"SniperShot","damage","Safe Sniper Shot window")
  if r then return r end
 end
 local arcaneMode=option(o,"arcane")
 if arcaneMode~="off" and (arcaneMode=="aggressive" or
   (arcaneMode=="balanced" and manaOK(s,o,0)) or
   (arcaneMode=="conserve" and manaOK(s,o,20))) and
   (autoWindow(s,option(o,"arcaneMinAutoWindow")) or s.autoShotActive==false) then
  r=action(s,"ArcaneShot","damage","Instant filler without wasting Auto Shot")
  if r then return r end
 end
 if option(o,"multi")=="on_cooldown" and not aoe and
   (autoWindow(s,option(o,"multiMinAutoWindow")) or s.autoShotActive==false) then
  r=action(s,"MultiShot","damage","Optional single-target instant Multi-Shot")
  if r then return r end
 end
 if s.autoShotActive==false then
  return action(s,"AutoShot","damage","Start Auto Shot")
 end
end
function MM.Next(state,options)
 if type(state)~="table" then return nil end
 if state.playerLevel~=nil and state.playerLevel~=60 then return nil end
 local s=state
 local o=options
 local r=survival(s,o)
 if r then return r end
 r=maintenance(s,o)
 if r then return r end
 if s.targetValid~=true or s.targetHostile~=true then return nil end
 if s.currentCast~=nil and s.currentCast~=false then return nil end
 r=melee(s,o)
 if r then return r end
 local ctx=context(s,o)
 r=burst(s,o,ctx)
 if r then return r end
 return rangedDamage(s,o,ctx)
end
return MM
