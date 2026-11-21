-- Kord Rotation — Hunter Marksmanship Leveling 1–59
-- Standalone, engine-independent decision profile. No direct WoW API calls.
-- Interface: MM.Next(state, options) -> {spellID, spell, reason, phase} or nil.
-- All state values are supplied by the future shared Kord GameData contract.
-- Unknown data are nil, never silently coerced to safe/true.
local MM = { id = 'HUNTER_MM_LEVELING', version = '1.0.0-design' }
local S = {
  AutoShot=75, RaptorStrike=2973, MongooseBite=1495,
  SerpentSting=1978, ArcaneShot=3044, ConcussiveShot=5116,
  WingClip=2974, AspectMonkey=13163, AspectHawk=13165,
  CallPet=883, RevivePet=982, MendPet=136, PetAttack=0,
  MultiShot=2643, AimedShot=19434, HuntersMark=1130,
  RapidFire=3045, FeignDeath=5384, Disengage=781,
  FreezingTrap=1499, FrostTrap=13809, ExplosiveTrap=13813,
  ImmolationTrap=13795, Volley=1510, Deterrence=19263,
  ScatterShot=19503, ViperSting=3034, TrueshotAura=1299346,
  SniperShot=1310687, SummonHawk=1293241, DismissPet=2641,
}
MM.Spells=S
MM.Defaults={
  mark='smart', sting='smart', sniper='smart', rapidFire='strong',
  pet='auto', multi='smart', arcane='balanced', hawk='smart',
  aoe='safe', traps='defensive', feign='contextual',
  manaReserve=25, mendPetAt=45, feignSoloAt=30,
  feignGroupAt=40, deterrenceAt=35, stingMinHealth=25,
  markMinHealth=60, volleyTargets=4,
  petReminder=true, aspectReminder=true, trueshotReminder=true,
  allowPvpControl=true,
}
MM.Options={
  mark={'smart','all','elite','off'},sting={'smart','all','elite','off'},
  sniper={'smart','opener','proc','cooldown','off'},
  rapidFire={'strong','cooldown','manual','off'},
  pet={'auto','pet','lone_wolf'},multi={'smart','aoe_only','opportunistic','off'},
  arcane={'balanced','aggressive','conserve','off'},
  hawk={'smart','aggressive','off'},aoe={'safe','aggressive','off'},
  traps={'defensive','offensive','off'},feign={'contextual','emergency','manual'},
}
local function opt(o,k)
  if type(o)=='table' and o[k]~=nil then return o[k] end
  return MM.Defaults[k]
end
local function is(s,k) return s[k]==true end
local function has(s,k) return type(s.known)=='table' and s.known[k]==true end
local function ready(s,k)
  return has(s,k) and type(s.ready)=='table' and s.ready[k]==true
end
local function auraMissing(s,k)
  return type(s.playerBuffs)=='table' and s.playerBuffs[k]==false
end
local function dotMissing(s,k)
  return type(s.targetDebuffs)=='table' and s.targetDebuffs[k]==false
end
local function mana(s,minimum)
  return type(s.manaPercent)=='number' and s.manaPercent>=minimum
end
local function targetStrong(s)
  return is(s,'targetElite') or is(s,'targetBoss') or is(s,'targetPlayer')
end
local function inGroupContent(s)
  return is(s,'inDungeon') or is(s,'inRaid')
end
local function petMode(s,o)
  local mode=opt(o,'pet')
  if mode=='lone_wolf' then return false end
  if mode=='pet' then return true end
  if type(s.talents)=='table' and s.talents.LoneWolf==true then return false end
  if type(s.talents)=='table' and s.talents.LoneWolf==false then return true end
  return nil -- never guess whether Lone Wolf is active
end
local function recommend(s,k,reason,phase)
  if not ready(s,k) then return nil end
  return {spellID=S[k],spell=k,reason=reason,phase=phase}
end
local function pick(s,k,condition,reason,phase)
  if condition then return recommend(s,k,reason,phase) end
end
local function safeAoE(s,o)
  if opt(o,'aoe')=='off' or type(s.enemyCount)~='number' or s.enemyCount<2 then return false end
  if opt(o,'aoe')=='safe' and (s.aoeSafe~=true or s.crowdControlNearby~=false) then return false end
  return true
end
local function markWorth(s,o)
  local mode=opt(o,'mark')
  if mode=='off' then return false end
  if mode=='all' then return true end
  if mode=='elite' then return targetStrong(s) end
  return targetStrong(s) or inGroupContent(s) or
    (type(s.targetHealthPercent)=='number' and s.targetHealthPercent>=opt(o,'markMinHealth'))
end
local function stingWorth(s,o)
  local mode=opt(o,'sting')
  if mode=='off' then return false end
  if mode=='all' then return true end
  if mode=='elite' then return targetStrong(s) end
  return targetStrong(s) or inGroupContent(s) or
    (type(s.targetHealthPercent)=='number' and s.targetHealthPercent>=opt(o,'stingMinHealth'))
end
local function threat(s,o)
  local fd=opt(o,'feign')
  if fd=='manual' or not is(s,'inCombat') then return nil end
  local hp=s.healthPercent
  local group=is(s,'inGroup') or inGroupContent(s)
  local pvp=is(s,'inPvP')
  if fd=='emergency' then
    return pick(s,'FeignDeath',type(hp)=='number' and hp<=opt(o,'feignSoloAt') and s.hasAggro==true,
      'Emergency threat reset','survival')
  end
  if pvp then
    return pick(s,'FeignDeath',is(s,'targetPlayer') and type(hp)=='number' and hp<=25,
      'PvP emergency target break','survival')
  end
  if group and s.hasAggro==true then
    return recommend(s,'FeignDeath','Group threat reset','survival')
  end
  if group and s.hasAggro~=false and type(hp)=='number' and hp<=opt(o,'feignGroupAt') then
    return recommend(s,'FeignDeath','Group emergency: threat uncertain','survival')
  end
  if not group and s.hasAggro==true and type(hp)=='number' and hp<=opt(o,'feignSoloAt') then
    return recommend(s,'FeignDeath','Solo emergency, not routine aggro','survival')
  end
end
local function survival(s,o)
  local r=threat(s,o)
  if r then return r end
  local hp=s.healthPercent
  r=pick(s,'Deterrence',is(s,'inCombat') and type(hp)=='number' and hp<=opt(o,'deterrenceAt'),
    'Defensive survival cooldown','survival')
  if r then return r end
  if is(s,'inCombat') and s.hasAggro==true and s.inMeleeRange==true then
    r=recommend(s,'Disengage','Drop threat in melee','survival')
    if r then return r end
  end
  if petMode(s,o)==true and s.petExists==true and s.petAlive==true and
     type(s.petHealthPercent)=='number' and s.petHealthPercent<=opt(o,'mendPetAt') and
     s.mendPetActive~=true then
    r=recommend(s,'MendPet','Pet health below configured threshold','survival')
    if r then return r end
  end
end
local function maintenance(s,o)
  local r
  local wants=petMode(s,o)
  if not is(s,'inCombat') then
    if wants==false and s.petExists==true and is(s,'talentLoneWolf') then
      r=recommend(s,'DismissPet','Activate Lone Wolf without a pet','maintenance')
      if r then return r end
    end
    if wants==true and opt(o,'petReminder') then
      if s.petDead==true then
        r=recommend(s,'RevivePet','Revive dead pet','maintenance')
        if r then return r end
      elseif s.petExists==false then
        r=recommend(s,'CallPet','Call missing pet','maintenance')
        if r then return r end
      end
      if s.petExists==true and s.petAlive==true and
         type(s.petHealthPercent)=='number' and s.petHealthPercent<=60 and s.mendPetActive~=true then
        r=recommend(s,'MendPet','Heal pet before pulling','maintenance')
        if r then return r end
      end
    end
    if opt(o,'trueshotReminder') and auraMissing(s,'TrueshotAura') then
      r=recommend(s,'TrueshotAura','Maintain Trueshot Aura','maintenance')
      if r then return r end
    end
    if opt(o,'aspectReminder') and s.travelAspectActive~=true then
      if auraMissing(s,'AspectHawk') then
        r=recommend(s,'AspectHawk','Maintain ranged aspect','maintenance')
        if r then return r end
      end
      if not has(s,'AspectHawk') and auraMissing(s,'AspectMonkey') then
        r=recommend(s,'AspectMonkey','Low-level defensive aspect','maintenance')
        if r then return r end
      end
    end
  elseif s.travelAspectActive==true then
    r=recommend(s,'AspectHawk','Remove daze-prone travel aspect in combat','survival')
    if r then return r end
    r=recommend(s,'AspectMonkey','Remove travel aspect in combat','survival')
    if r then return r end
  end
end
local function melee(s,o)
  if s.inMeleeRange~=true then return nil end
  local r
  if s.hasAggro==true or is(s,'targetPlayer') then
    r=pick(s,'WingClip',dotMissing(s,'WingClip'),'Slow enemy to regain distance','control')
    if r then return r end
    r=recommend(s,'ScatterShot','Create distance','control')
    if r then return r end
    if opt(o,'traps')~='off' then
      r=recommend(s,'FreezingTrap','Peel enemy to regain range','control')
      if r then return r end
      r=recommend(s,'FrostTrap','Slow enemy to regain range','control')
      if r then return r end
    end
  end
  if safeAoE(s,o) and opt(o,'traps')=='offensive' then
    r=recommend(s,'ExplosiveTrap','Melee-range AoE','aoe')
    if r then return r end
  end
  r=recommend(s,'MongooseBite','Melee counterattack','melee')
  if r then return r end
  return recommend(s,'RaptorStrike','Melee fallback','melee')
end
local function sniperWorth(s,o)
  local mode=opt(o,'sniper')
  if mode=='off' or s.isMoving~=false or s.canFinishLongCast~=true then return false end
  if mode=='cooldown' then return true end
  if mode=='proc' then return s.rapidKillingProc==true end
  if mode=='opener' then return s.inCombat==false end
  return s.rapidKillingProc==true or targetStrong(s) or inGroupContent(s) or
    (s.inCombat==false and s.targetLongLived==true)
end
local function damage(s,o)
  if s.inRangedRange~=true then return nil end
  local r
  local aoe=safeAoE(s,o)
  if dotMissing(s,'HuntersMark') and markWorth(s,o) and
     (s.inCombat==false or targetStrong(s) or inGroupContent(s)) then
    r=recommend(s,'HuntersMark','Mark target according to strategy','pull')
    if r then return r end
  end
  if petMode(s,o)==true and s.petExists==true and s.petAlive==true and
     s.petAttackingTarget==false and s.targetHostile==true then
    -- PetAttack is a command, not a normal spell; the shared action contract
    -- must supply a verified pet-action recommendation separately.
    return {action='PET_ATTACK',reason='Send pet to hostile target',phase='pull'}
  end
  if opt(o,'rapidFire')~='off' and opt(o,'rapidFire')~='manual' and s.inCombat==true and
     (opt(o,'rapidFire')=='cooldown' or targetStrong(s)) then
    r=recommend(s,'RapidFire','Offensive cooldown on suitable target','cooldowns')
    if r then return r end
  end
  if dotMissing(s,'SerpentSting') and stingWorth(s,o) and mana(s,opt(o,'manaReserve')) then
    r=recommend(s,'SerpentSting','Damage over time / Rapid Recuperation synergy','damage')
    if r then return r end
  end
  if aoe and s.enemyCount>=2 and opt(o,'multi')~='off' then
    r=recommend(s,'MultiShot','Multiple safe targets','aoe')
    if r then return r end
  end
  if aoe and s.enemyCount>=opt(o,'volleyTargets') and s.isMoving==false and mana(s,40) then
    r=recommend(s,'Volley','Large safe group','aoe')
    if r then return r end
  end
  if s.isMoving==false then
    r=pick(s,'AimedShot',s.rapidKillingProc==true,'Consume Rapid Killing proc','damage')
    if r then return r end
    r=pick(s,'SniperShot',sniperWorth(s,o),'Long cast when safe and profitable','damage')
    if r then return r end
    r=recommend(s,'AimedShot','Main single-target shot','damage')
    if r then return r end
  end
  if opt(o,'multi')=='opportunistic' or (opt(o,'multi')=='smart' and s.inCombat==true and
     (inGroupContent(s) or (s.isSolo==true and type(s.level)=='number' and s.level<40))) then
    r=recommend(s,'MultiShot','Instant shot / shared cooldown policy','damage')
    if r then return r end
  end
  if opt(o,'hawk')~='off' and (opt(o,'hawk')=='aggressive' or s.hawkRefreshNeeded==true) then
    r=recommend(s,'SummonHawk','Refresh talented summoned hawks','damage')
    if r then return r end
  end
  if opt(o,'arcane')~='off' and
     (opt(o,'arcane')=='aggressive' or
      (opt(o,'arcane')=='balanced' and mana(s,opt(o,'manaReserve'))) or
      (opt(o,'arcane')=='conserve' and mana(s,60))) then
    r=recommend(s,'ArcaneShot','Instant ranged filler','damage')
    if r then return r end
  end
  return recommend(s,'AutoShot','Maintain ranged auto-attack','fallback')
end
function MM.Next(s,o)
  if type(s)~='table' then return nil end
  if type(s.level)~='number' or s.level<1 or s.level>59 then return nil end
  local r=survival(s,o)
  if r then return r end
  r=maintenance(s,o)
  if r then return r end
  if s.targetHostile~=true or s.targetAlive~=true then return nil end
  if s.inMeleeRange==true then return melee(s,o) end
  if s.inRangedRange==true then return damage(s,o) end
  -- Dead zone or unknown range: no invented distance, no impossible cast.
  if s.hasAggro==true and s.inMeleeRange==false then
    return pick(s,'ConcussiveShot',s.inRangedRange~=false,'Slow pursuer','control')
  end
  return nil
end
return MM