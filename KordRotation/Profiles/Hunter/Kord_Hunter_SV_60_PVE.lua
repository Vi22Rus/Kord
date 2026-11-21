-- Kord Rotation | Hunter Survival | Level 60 | PVE | WoW Forever
-- No direct WoW API. Shared GameData adapter supplies canonical, verified signals.
-- UNKNOWN is nil; only explicit true/false may prove a condition.
-- Interface: SV.Next(state, options) -> {spellID, spell, phase, reason} or nil.
local SV = { id = 'HUNTER_SV_60_PVE', version = '1.0.0-design', level = 60 }
local Spells = {
 Attack=6603, AutoShot=75, RaptorStrike=2973, MongooseBite=1495,
 Counterattack=19306, StriderKick=1317257, Lacerate=24118,
 HuntersMark=1130, SerpentSting=1978, ArcaneShot=3044,
 AimedShot=19434, MultiShot=2643, Volley=1510, RapidFire=3045,
 ImmolationTrap=13795, ExplosiveTrap=13813, FreezingTrap=1499,
 FrostTrap=13809, WingClip=2974, Disengage=781, Deterrence=19263,
 FeignDeath=5384, AspectMonkey=13163, AspectBeast=13161,
 CallPet=883, RevivePet=982, MendPet=136, FeedPet=6991
}
SV.Spells = Spells
SV.Metadata = {class='HUNTER', spec='SV', mode='60', content='PVE',
 standalone=true, engineRegistered=false, gameplayVerified=false}
SV.Defaults = {
 manaStyle='maximum', combatStyle='auto', huntersMark='priority',
 serpentSting='long', traps='contextual', rapidFire='strong',
 petMode='auto', feignDeath='contextual', aoeMode='safe',
 petReminder=true, aspectReminder=true, autoAttackReminder=true,
 petMendAt=50, feignSoloAt=30, feignGroupAt=45,
 deterrenceAt=35, stingMinTTD=12, markMinTargetHP=60,
 lacerateMinTargetHP=30, volleyMinMana=40, rapidMinTTD=15,
 bossBleedMinTTD=12, stingMinMana=40, meleeSwingMinWindow=0.2
}
SV.Enums = {
 manaStyle={'maximum','balanced','efficient'},
 combatStyle={'auto','melee','weave','ranged'},
 huntersMark={'priority','all','off'},
 serpentSting={'long','all','off'},
 traps={'contextual','offensive','defensive','off'},
 rapidFire={'strong','on_cooldown','manual'},
 petMode={'auto','pet','lone_wolf'},
 feignDeath={'contextual','emergency','manual'},
 aoeMode={'safe','aggressive','off'}
}
local function opt(o,k)
 local v=type(o)=='table' and o[k] or nil
 local list=SV.Enums[k]
 if list then
  for _,allowed in ipairs(list) do if v==allowed then return v end end
  return SV.Defaults[k]
 end
 if type(SV.Defaults[k])=='boolean' then
  if type(v)=='boolean' then return v end
  return SV.Defaults[k]
 end
 if type(v)=='number' and v==v and v>=0 and v<=100 then return v end
 return SV.Defaults[k]
end
local function ready(s,k)
 return type(s.known)=='table' and s.known[k]==true
  and type(s.ready)=='table' and s.ready[k]==true
end
local function recommend(s,k,phase,reason)
 if ready(s,k) then return {spellID=Spells[k],spell=k,phase=phase,reason=reason} end
end
local function attempt(s,k,condition,phase,reason)
 if condition then return recommend(s,k,phase,reason) end
end
local function present(t,k) return type(t)=='table' and t[k]==true end
local function absent(t,k) return type(t)=='table' and t[k]==false end
local function melee(s) return s.inMeleeRange==true end
local function ranged(s) return s.inRangedRange==true and s.inMeleeRange~=true end
local function group(s) return s.inDungeon==true or s.inRaid==true end
local function questing(s) return s.inWorld==true and s.inDungeon==false and s.inRaid==false end
local function strong(s) return s.targetBoss==true or s.targetElite==true end
local function safe(s) return s.targetCrowdControlled==false and s.breakableCCNearby==false end
local function mana(s,minimum)
 return type(s.manaPercent)=='number' and s.manaPercent>=minimum
end
local function petWanted(s,o)
 local p=opt(o,'petMode')
 if p=='pet' then return true end
 if p=='lone_wolf' then return false end
 if type(s.talents)=='table' then
  if s.talents.LoneWolf==true then return false end
  if s.talents.LoneWolf==false then return true end
 end
 return nil
end
local function maintenance(s,o)
 local pet=petWanted(s,o)
 if opt(o,'petReminder') and pet==true then
  local r=attempt(s,'RevivePet',s.inCombat==false and s.petDead==true,'pet','Revive pet')
  if r then return r end
  r=attempt(s,'CallPet',s.inCombat==false and s.petExists==false and s.petDead==false,'pet','Call pet')
  if r then return r end
  if s.inCombat==false and s.petCanFeed==true and type(s.petHappiness)=='number' and s.petHappiness<3 then
   r=recommend(s,'FeedPet','pet','Feed unhappy pet')
   if r then return r end
  end
  if s.petExists==true and type(s.petHealthPercent)=='number'
   and s.petHealthPercent<=opt(o,'petMendAt') and s.petMendActive==false then
   r=recommend(s,'MendPet','pet','Heal injured pet')
   if r then return r end
  end
 end
 if opt(o,'aspectReminder') and s.inCombat==false then
  if type(s.known)=='table' and s.known.AspectBeast==true then
   local r=attempt(s,'AspectBeast',absent(s.playerBuffs,'AspectBeast')
    and s.otherAspectActive==false,'buff','Survival melee aspect')
   if r then return r end
  elseif type(s.known)=='table' and s.known.AspectBeast==false then
   local r=attempt(s,'AspectMonkey',absent(s.playerBuffs,'AspectMonkey')
    and s.otherAspectActive==false,'buff','Early survival dodge aspect')
   if r then return r end
  end
 end
end
local function survival(s,o)
 if s.inCombat~=true then return nil end
 local hp=s.healthPercent
 local danger=type(hp)=='number' and hp<=opt(o,'feignSoloAt')
 local mode=opt(o,'feignDeath')
 if mode~='manual' then
  if mode=='contextual' and group(s) and s.hasAggro==true
    and (s.tankHasAggro==false or s.threatHigh==true) then
   local r=recommend(s,'FeignDeath','survival','Dangerous group threat')
   if r then return r end
  end
  if danger and s.hasAggro==true then
   local r=recommend(s,'FeignDeath','survival','Emergency threat reset')
   if r then return r end
  end
  if group(s) and s.hasAggro==true and type(hp)=='number'
   and hp<=opt(o,'feignGroupAt') then
   local r=recommend(s,'FeignDeath','survival','Low health with group aggro')
   if r then return r end
  end
 end
 if type(hp)=='number' and hp<=opt(o,'deterrenceAt') and s.incomingDamage==true then
  local r=recommend(s,'Deterrence','survival','Defensive cooldown')
  if r then return r end
 end
 if melee(s) and s.hasAggro==true and s.needEscape==true then
  local r=recommend(s,'Disengage','survival','Escape dangerous melee')
  if r then return r end
  if opt(o,'traps')~='off' and s.trapSharedReady==true
   and s.targetCanBeControlled==true and safe(s) then
   r=recommend(s,'FreezingTrap','control','Control dangerous attacker')
   if r then return r end
  end
  r=attempt(s,'WingClip',absent(s.targetDebuffs,'WingClip'),'control','Slow attacker')
  if r then return r end
 end
end
local function markWanted(s,o)
 if opt(o,'huntersMark')=='off' then return false end
 if opt(o,'huntersMark')=='all' then return true end
 if strong(s) or group(s) then return true end
 if present(s.talents,'ExposePrey') and type(s.targetHealthPercent)=='number'
   and s.targetHealthPercent>=opt(o,'markMinTargetHP') then return true end
 return false
end
local function stingWanted(s,o)
 if opt(o,'serpentSting')=='off' then return false end
 if opt(o,'serpentSting')=='all' then return true end
 return type(s.targetTTD)=='number' and s.targetTTD>=opt(o,'stingMinTTD')
end
local function meleeDamage(s,o)
 if not melee(s) or not safe(s) then return nil end
 local combat=opt(o,'combatStyle')
 -- Ranged fallback is a preference, not a prohibition against melee survival.
 -- Weave requires a confirmed swing window before spending non-reactive GCDs.
 local weaving=combat=='weave' and s.meleeSwingWindow~=true
 local dungeon=group(s)
 local style=opt(o,'manaStyle')
 local r
 if not weaving and questing(s) and opt(o,'manaStyle')~='efficient' then
  r=recommend(s,'StriderKick','melee','Questing opener: Strider Kick')
  if r then return r end
 end
 if markWanted(s,o) and absent(s.targetDebuffs,'HuntersMark') then
  r=recommend(s,'HuntersMark','debuff','Mark valuable target')
  if r then return r end
 end
 r=recommend(s,'MongooseBite','melee','Reactive dodge / Expose Prey window')
 if r then return r end
 r=recommend(s,'Counterattack','melee','Reactive parry window')
 if r then return r end
 -- At 60 only efficient dungeon/raid mode saves mana by skipping Kick.
 local skipKick=dungeon and style=='efficient'
 if not skipKick and not weaving then
  r=recommend(s,'StriderKick','melee','Weapon-damage kick')
  if r then return r end
 end
 local skipRaptor=dungeon and (style=='balanced' or style=='efficient')
 if not skipRaptor and not weaving and s.raptorStrikeQueued==false then
  r=recommend(s,'RaptorStrike','melee','Queue next melee swing once')
  if r then return r end
 end
 if not weaving and type(s.targetHealthPercent)=='number'
  and s.targetHealthPercent>opt(o,'lacerateMinTargetHP')
  and (not strong(s) or (type(s.targetTTD)=='number'
   and s.targetTTD>=opt(o,'bossBleedMinTTD'))) then
  local remains=type(s.targetDebuffRemaining)=='table' and s.targetDebuffRemaining.Lacerate or nil
  local refresh=absent(s.targetDebuffs,'Lacerate')
   or (not group(s) and type(remains)=='number' and remains<=2
    and s.targetDebuffs.Lacerate==true)
  if refresh then
   r=recommend(s,'Lacerate','melee','Maintain 21-second bleed')
   if r then return r end
  end
 end
 if not weaving and opt(o,'traps')~='off' and s.trapSharedReady==true and s.trapPlacementSafe==true then
  local worth=strong(s) or group(s) or (questing(s) and
   present(s.talents,'Resourcefulness'))
  if worth then
   r=recommend(s,'ImmolationTrap','trap','Single-target fire trap')
   if r then return r end
  end
 end
 if opt(o,'autoAttackReminder') and s.autoMeleeActive==false and s.autoSwitching==false then
  return recommend(s,'Attack','auto','Keep melee auto-attacking')
 end
end
local function aoe(s,o)
 if not safe(s) then return nil end
 if opt(o,'aoeMode')=='off' or type(s.enemyCount)~='number' or s.enemyCount<2 then return nil end
 if opt(o,'aoeMode')=='safe' and (s.aoeSafe~=true or s.breakableCCNearby~=false) then return nil end
 local r
 if melee(s) and s.trapSharedReady==true and s.trapPlacementSafe==true
   and opt(o,'traps')~='off' then
  r=recommend(s,'ExplosiveTrap','aoe','Shared-cooldown AoE fire trap')
  if r then return r end
 end
 if ranged(s) then
  r=recommend(s,'MultiShot','aoe','Three-target cleave')
  if r then return r end
  if s.enemyCount>=4 and s.moving==false and s.canFinishChannel==true
   and mana(s,opt(o,'volleyMinMana')) and s.aoeGroundSafe==true then
   r=recommend(s,'Volley','aoe','Sustained four-target channel')
   if r then return r end
  end
 end
end
local function rangedDamage(s,o)
 if not ranged(s) then return nil end
 local combat=opt(o,'combatStyle')
 -- Full-melee mode may use ranged auto-attacks while approaching, but
 -- does not spend mana on ranged damage unless melee is unavailable.
 local preferMelee=combat=='melee' and s.canReachMelee==true
 local r
 if markWanted(s,o) and absent(s.targetDebuffs,'HuntersMark') then
  r=recommend(s,'HuntersMark','debuff','Mark valuable target')
  if r then return r end
 end
 if not preferMelee and stingWanted(s,o) and absent(s.targetDebuffs,'SerpentSting') and mana(s,opt(o,'stingMinMana')) then
  r=recommend(s,'SerpentSting','debuff','Sting target while closing')
  if r then return r end
 end
 if not preferMelee and s.moving==false and s.canFinishLongCast==true then
  r=recommend(s,'AimedShot','ranged','Ranged fallback: Aimed Shot')
  if r then return r end
 end
 if not preferMelee and mana(s,30) then
  r=recommend(s,'ArcaneShot','ranged','Ranged fallback: Arcane Shot')
  if r then return r end
 end
 if opt(o,'autoAttackReminder') and s.autoShotActive==false then
  return recommend(s,'AutoShot','auto','Start Auto Shot')
 end
end
function SV.Next(state,options)
 if type(state)~='table' then return nil end
 local s=state
 if s.playerLevel~=60 then return nil end
 local r=survival(s,options)
 if r then return r end
 r=maintenance(s,options)
 if r then return r end
 if s.targetValid~=true or s.targetHostile~=true or s.targetPlayer==true
  or s.targetAttackable~=true then return nil end
 if s.currentCast~=nil and s.currentCast~=false then return nil end
 -- A hostile target under crowd control must not receive damaging actions.
 if s.targetCrowdControlled~=false then return nil end
 -- Never attack a nearby controlled pack without verified AoE safety.
 if s.breakableCCNearby~=false and type(s.enemyCount)=='number' and s.enemyCount>=2 then
  return nil
 end
 if opt(options,'rapidFire')~='manual' and s.inCombat==true
  and (opt(options,'rapidFire')=='on_cooldown' or strong(s)
   or (type(s.targetTTD)=='number' and s.targetTTD>=opt(options,'rapidMinTTD')
    and (group(s) or s.targetElite==true)))
  and (melee(s) or group(s)) then
  r=recommend(s,'RapidFire','cooldown','Attack speed for meaningful fight')
  if r then return r end
 end
 r=aoe(s,options)
 if r then return r end
 r=meleeDamage(s,options)
 if r then return r end
 return rangedDamage(s,options)
end
return SV
