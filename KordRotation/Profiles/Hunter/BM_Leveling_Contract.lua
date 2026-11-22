-- Kord Rotation (c) 2026 Vi22Rus; see root LICENSE.
-- Whole BM leveling 1–59 strategy port from Kord_Hunter_BM_Leveling_PVE.lua v2.3.
-- Data-driven Profile Contract v1. No WoW API in rule callbacks.
local _,KR=...
local M={}
KR.BMLeveling=M
local spec={
 {"Mark","Hunter's Mark",1130,"buffs","enemy","debuff"},
 {"Sting","Serpent Sting",1978,"damage","enemy"},
 {"Arcane","Arcane Shot",3044,"damage","enemy"},
 {"Hawk","Summon Hawk",1293241,"damage","enemy"},
 {"Auto","Auto Shot",75,"damage","enemy"},
 {"Aimed","Aimed Shot",19434,"damage","enemy"},
 {"Multi","Multi-Shot",2643,"damage","enemy"},
 {"Rapid","Rapid Fire",3045,"cooldowns","none"},
 {"Wrath","Bestial Wrath",19574,"cooldowns","none"},
 {"Intimidate","Intimidation",19577,"cooldowns","enemy"},
 {"Concussive","Concussive Shot",5116,"damage","enemy"},
 {"Raptor","Raptor Strike",2973,"damage","enemy"},
 {"Mongoose","Mongoose Bite",1495,"damage","enemy"},
 {"Wing","Wing Clip",2974,"damage","enemy"},
 {"Disengage","Disengage",781,"movement","enemy"},
 {"Feign","Feign Death",5384,"defensive","none"},
 {"Freezing","Freezing Trap",1499,"defensive","none"},
 {"Frost","Frost Trap",13809,"defensive","none"},
 {"Explosive","Explosive Trap",13813,"damage","none"},
 {"Immolation","Immolation Trap",13795,"damage","none"},
 {"Volley","Volley",1510,"damage","enemy"},
 {"Mend","Mend Pet",136,"buffs","none","utility"},
 {"CallPet","Call Pet",883,"buffs","none","utility"},
 {"Revive","Revive Pet",982,"buffs","none","utility"},
 {"AspectHawk","Aspect of the Hawk",13165,"buffs","none","aspect"},
 {"AspectMonkey","Aspect of the Monkey",13163,"buffs","none","aspect"},
 {"Trueshot","Trueshot Aura",19506,"buffs","none","aura"},
}
local defaults={
 {"mark","enum","all",{"all","elite","instance","elite_or_instance","smart","off"},"debuffs","Hunter's Mark"},
 {"sting","enum","smart",{"smart","all","elite","off"},"debuffs","Serpent Sting"},
 {"hawk_arcane","enum","hawk",{"auto","hawk","arcane","off"},"damage","Summon Hawk / Arcane Shot"},
 {"aimed_multi","enum","auto",{"auto","aimed","multi"},"damage","Aimed Shot / Multi-Shot"},
 {"multi_filler","bool",true,nil,"damage","Multi-Shot filler"},
 {"mana","enum","balanced",{"fast","balanced","economy","max"},"resource","Mana reserve"},
 {"bestial_wrath","enum","all",{"all","elite","off"},"cooldowns","Bestial Wrath"},
 {"rapid_fire","enum","strong",{"all","strong","off"},"cooldowns","Rapid Fire"},
 {"intimidation","bool",true,nil,"cooldowns","Intimidation"},
 {"use_feign_death","bool",true,nil,"survival","Feign Death"},
 {"feign_hp","number",30,{min=1,max=100},"survival","Feign Death HP %"},
 {"use_disengage","bool",true,nil,"survival","Disengage"},
 {"use_wing_clip","bool",true,nil,"survival","Wing Clip"},
 {"use_aimed_shot","bool",true,nil,"damage","Aimed Shot"},
 {"use_freezing_trap","bool",true,nil,"survival","Freezing Trap"},
 {"use_frost_trap","bool",true,nil,"survival","Frost Trap"},
 {"mend_pet_hp","number",50,{min=1,max=100},"pet","Mend Pet HP %"},
 {"aoe","enum","safe",{"safe","aggressive","off"},"aoe","AoE policy"},
 {"summon_pet","bool",true,nil,"pet","Call / Revive Pet"},
 {"mend_pet","bool",true,nil,"pet","Mend Pet"},
 {"pet_attack","bool",true,nil,"pet","Pet Attack"},
 {"aspect","bool",true,nil,"buffs","Aspects"},
}
local arcaneRanks={{14287,60},{14286,52},{14285,44},{14284,36},
 {14283,28},{14282,20},{14281,12},{3044,6}}
local hawkRanks={1293527,1293526,1293525,1293241}
local function cfgTable(is60)
 local config={}
 for _,row in ipairs(defaults) do
  local record={key=row[1],type=row[2],default=row[3],
   group=row[5],label=row[6],desc="BM leveling v2.3: "..row[6]}
  if row[2]=="enum" then record.values=row[4]
  elseif row[2]=="number" then
   record.min=row[4].min
   record.max=row[4].max end
  config[#config+1]=record
 end
 if is60 then
  config[#config+1]={key="cooldowns",type="enum",default="on_cd",
      values={"on_cd","boss","off"},group="cooldowns",
      label="Cooldowns",desc="BM 60 v1.2: cooldown policy"}
  config[#config+1]={key="trueshot_aura",type="bool",default=true,
      group="buffs",label="Trueshot Aura",
      desc="BM 60 v1.2: maintain aura"}
  config[#config+1]={key="pull_cast",type="bool",default=true,
      group="damage",label="Pre-pull Aimed Shot",
      desc="BM 60 v1.2: requires confirmed pull timing"}
  config[#config+1]={key="traps",type="enum",default="aoe",
      values={"aoe","always","off"},group="traps",
      label="Trap policy",desc="BM 60 v1.2: control trap usage"}
 end
 return config
end
local function and2(a,b)
 if a==false or b==false then return false end
 if a==true and b==true then return true end
 return nil
end
local function not3(v)
 if v==true then return false end
 if v==false then return true end
 return nil
end
local function less(value,max)
 if type(value)~="number" then return nil end
 return value<=max
end
local function known(S,spells,key)
 local v=S:spellFact(spells[key],"known")
 return v
end
local function target(S)
 return S:is("target.exists")
end
local function combat(S)
 return S:is("player.combat")
end
local function signal(S,key,id)
 return S:observe(key,id)
end
local function mana(S,cfg,is60)
 local floor=is60 and {max=0,fast=10,balanced=25,economy=40}
    or {max=0,fast=15,balanced=30,economy=50}
 local pct=signal(S,"resources.percent")
 local min=floor[cfg.mana] or 30
 if type(pct)~="number" then return nil end
 return pct>=min
end
local function enabledFeature(cfg,key)
 return cfg[key]~=false
end
local function makeRules(spells,is60)
 local rules={}
 local function add(id,key,condition,mode,category,actionType)
  local data
  for _,item in ipairs(spec) do if item[1]==key then data=item break end end
  if not data and actionType~="PET_COMMAND" then return end
  local rule={id=id,type=actionType or "SPELL",
   spell=key,
   action=actionType=="PET_COMMAND" and key or nil,
   category=category or (data and data[4] or "damage"),
   target=data and data[5] or "enemy",
   cast="idle",chargesRequired=false,mode=mode or "any",
   -- Category-driven by default; only deviations carry semantic metadata.
   recommendationType=data and data[6] or nil,
   reason="BM leveling v2.3: "..id,
   when=function(S,cfg)
    -- Honor a disabled module option before any spellbook/provider read.
    -- Optional high-level abilities must not block low-level leveling when
    -- the user explicitly turned the feature off.
    local gated={
      Feign="use_feign_death",Disengage="use_disengage",
      Wing="use_wing_clip",Aimed="use_aimed_shot",
      Freezing="use_freezing_trap",Frost="use_frost_trap",
      Mend="mend_pet",CallPet="summon_pet",Revive="summon_pet",
      PetAttack="pet_attack",AspectHawk="aspect",AspectMonkey="aspect",
      Intimidate="intimidation"
    }
    if gated[key] and cfg[gated[key]]==false then return false end
    if key=="Mark" and cfg.mark=="off" then return false end
    if key=="Sting" and cfg.sting=="off" then return false end
    if key=="Hawk" and (cfg.hawk_arcane=="off"
        or cfg.hawk_arcane=="arcane") then return false end
    if key=="Arcane" and cfg.hawk_arcane=="off" then return false end
    if key=="Wrath" and cfg.bestial_wrath=="off" then return false end
    if key=="Rapid" and cfg.rapid_fire=="off" then return false end
    if actionType~="PET_COMMAND" then
     -- A missing/unlearned spell must not block earlier conditions such
     -- as threat, hawk count or TTD that are irrelevant at this level.
     local trained=known(S,spells,key)
     if trained~=true then return trained end
    end
    local applicable=condition(S,cfg)
    if applicable~=true then return applicable end
    return true
   end}
  -- Optional buffs/movement/damage are safe to skip if their condition
  -- needs an unimplemented provider. Core Eligibility UNKNOWN never skips.
  if rule.category=="buffs" or rule.category=="damage"
     or rule.category=="movement" or rule.category=="cooldowns"
     or rule.category=="defensive" then
   rule.onUnknown="skip"
  end
  -- PET_COMMAND must carry action but no spell; Lua 'and nil or' cannot select nil.
  if actionType=="PET_COMMAND" then rule.spell=nil end
  rules[#rules+1]=rule
 end
 local function hasTargetAndMana(S,c)
  return and2(target(S),mana(S,c,is60))
 end
 local function markAllowed(S,c)
  if c.mark=="off" then return false end
  if c.mark=="all" then return true end
  local kind=signal(S,"target.classification")
  local elite=kind=="elite" or kind=="rareelite" or kind=="worldboss"
  if c.mark=="elite" then
   if type(kind)~="string" then return nil end
   return elite
  end
  local instance=signal(S,"context.inInstance")
  if c.mark=="instance" then return instance end
  if c.mark=="elite_or_instance" then
   if elite or instance==true then return true end
   if type(kind)=="string" and instance==false then return false end
   return nil
  end
  if elite then return true end
  local ttd=signal(S,"target.ttd")
  if type(ttd)~="number" then return nil end
  return ttd>=15
 end
 local function markWhen(S,c)
  local enabled=and2(target(S),markAllowed(S,c))
  if enabled~=true then return enabled end
  return S:isNot("target.debuff",spells.Mark)
 end
 -- Long-running aspects are useful before the pull even without a target.
 -- The individual aspect conditions still protect travel forms.
 local function maintenance(S,c)
  return true
 end
 -- Original BM.Next priority: Feign -> aspect -> pet upkeep -> target.
 add("feign","Feign",function(S,c)
  if not c.use_feign_death then return false end
  if combat(S)~=true then return combat(S) end
  local hp=signal(S,"player.health.percent")
  local low=less(hp,c.feign_hp)
  local instance=signal(S,"context.inInstance")
  if low==false and instance==false then return false end
  return and2(signal(S,"player.hasAggro"),
    instance==true and true or low)
 end,nil,"defensive")
 add("aspect_hawk","AspectHawk",function(S,c)
  if not c.aspect then return false end
  local level=S:ge("player.level",10)
  if level~=true then return level end
  local active=maintenance(S,c)
  if active~=true then return active end
  local travel=signal(S,"player.travelAspect")
  local hawkMissing=S:isNot("player.buff",spells.AspectHawk)
  -- An already confirmed Hawk never needs another cast.
  if hawkMissing==false then return false end
  local fighting=combat(S)
  if travel==true then
   -- Preserve Cheetah / Pack while travelling outside combat. Once
   -- combat is confirmed, a missing/hidden Hawk is a valid safety switch.
   if fighting==false then return hawkMissing end
   if fighting==true then return true end
   return nil
  end
  -- Unknown travel aura cannot justify cancelling it before combat.
  if travel~=false and fighting~=true then return nil end
  return hawkMissing
 end)
 add("aspect_monkey","AspectMonkey",function(S,c)
  if not c.aspect then return false end
  local upper=S:ge("player.level",10)
  -- Level >= 10 disables Monkey; avoid Lua's 'and false or nil' trap.
  if upper==true then return false end
  if upper==nil then return nil end
  if maintenance(S,c)~=true then return maintenance(S,c) end
  return S:isNot("player.buff",spells.AspectMonkey)
 end)
 if is60 then
  add("trueshot_aura","Trueshot",function(S,c)
   if not c.trueshot_aura then return false end
   return S:isNot("player.buff",spells.Trueshot)
  end,nil,"buffs")
 end
 add("revive_pet","Revive",function(S,c)
  if not c.summon_pet or combat(S)~=false then return false end
  return and2(not3(signal(S,"pet.exists")),signal(S,"pet.dead"))
 end)
 add("call_pet","CallPet",function(S,c)
  if not c.summon_pet or combat(S)~=false then return false end
  return and2(not3(signal(S,"pet.exists")),
   not3(signal(S,"pet.dead")))
 end)
 add("mend_pet","Mend",function(S,c)
  if not c.mend_pet then return false end
  local hasPet=signal(S,"pet.exists")
  if hasPet~=true then return hasPet end
  local low=less(signal(S,"pet.health.percent"),c.mend_pet_hp)
  if low~=true then return low end
  return not3(signal(S,"pet.mendActive"))
 end)
 add("prepull_mark","Mark",function(S,c)
  if combat(S)~=false then return false end
  return markWhen(S,c)
 end,nil,"buffs")
 if is60 then
  add("prepull_aimed","Aimed",function(S,c)
   if not c.pull_cast or not c.use_aimed_shot then return false end
   if combat(S)~=false then return false end
   local seconds=signal(S,"pull.remaining")
   if type(seconds)~="number" then return nil end
   return seconds>=2.3 and seconds<=6
  end,nil,"damage")
 end
 add("pet_attack","PetAttack",function(S,c)
  if not c.pet_attack then return false end
  return and2(target(S),
    and2(signal(S,"pet.exists"),
    not3(signal(S,"pet.attackingTarget"))))
 end,nil,"damage","PET_COMMAND")
 -- Ranged / melee branch selection requires proven distance; do not
 -- confuse 'out of range' with 'inside the ranged dead-zone'.
 local function melee(S)
  return signal(S,"target.melee")
 end
 local function ranged(S)
  return not3(melee(S))
 end
 add("melee_disengage","Disengage",function(S,c)
  if not c.use_disengage then return false end
  return and2(melee(S),and2(signal(S,"pet.exists"),
   signal(S,"player.hasAggro")))
 end,nil,"movement")
 local function trapWhen(S,c,key)
  if is60 and c.traps=="off" then return false end
  if key=="Freezing" and not c.use_freezing_trap then return false end
  if key=="Frost" and not c.use_frost_trap then return false end
  return and2(target(S),signal(S,"trap.profitable"))
 end
 for _,item in ipairs({
  {"melee_freezing","Freezing"},{"melee_frost","Frost"}
 }) do
  add(item[1],item[2],function(S,c)
   return and2(melee(S),trapWhen(S,c,item[2]))
  end,nil,"defensive")
 end
 local function wrathAllowed(S,c)
  if c.bestial_wrath=="off" then return false end
  if c.bestial_wrath=="elite" then
   local kind=signal(S,"target.classification")
   if type(kind)~="string" then return nil end
   return kind=="elite" or kind=="rareelite" or kind=="worldboss"
  end
  return signal(S,"target.willSurviveBurst")
 end
 local function strong(S)
  local kind=signal(S,"target.classification")
  if kind=="elite" or kind=="worldboss" or kind=="rareelite" then return true end
  if type(kind)~="string" then return nil end
  local ttd=signal(S,"target.ttd")
  if type(ttd)~="number" then return nil end
  return ttd>=15
 end
 local function cds(S,c,key)
  if is60 then
   if c.cooldowns=="off" then return false end
   if c.cooldowns=="boss" then
    local kind=signal(S,"target.classification")
    if type(kind)~="string" then return nil end
    if kind~="elite" and kind~="worldboss" and kind~="rareelite"
       then return false end
   end
  end
  if key=="Wrath" then
   return and2(wrathAllowed(S,c),
     and2(signal(S,"pet.exists"),signal(S,"pet.attackingTarget")))
  elseif key=="Rapid" then
   if c.rapid_fire=="off" then return false end
   if c.rapid_fire=="all" then return signal(S,"target.willSurviveBurst") end
   return strong(S)
  end
  if not c.intimidation then return false end
  return and2(signal(S,"pet.exists"),
   and2(signal(S,"pet.attackingTarget"),
    signal(S,"intimidation.profitable")))
 end
 for _,act in ipairs({"Wrath","Rapid","Intimidate"}) do
  add("melee_"..act:lower(),act,function(S,c)
   return and2(melee(S),cds(S,c,act))
  end,nil,"cooldowns")
 end
 add("melee_immolation","Immolation",function(S,c)
  return and2(melee(S),signal(S,"trap.profitable"))
 end)
 add("melee_wing","Wing",function(S,c)
  if not c.use_wing_clip then return false end
  return and2(melee(S),and2(signal(S,"need.distance"),
   not3(signal(S,"target.wingClip"))))
 end,nil,"movement")
 add("melee_mongoose","Mongoose",function(S)
  return and2(melee(S),signal(S,"mongoose.usable"))
 end)
 add("melee_raptor","Raptor",function(S)
  return melee(S)
 end)
 add("ranged_auto","Auto",function(S)
  return and2(ranged(S),not3(signal(S,"autoShot.active")))
 end)
 add("ranged_mark","Mark",function(S,c)
  return and2(ranged(S),markWhen(S,c))
 end,nil,"buffs")
 add("ranged_concussive","Concussive",function(S)
  return and2(ranged(S),
   and2(signal(S,"target.approaching"),
    and2(not3(signal(S,"target.slowed")),
     S:any(function()return S:isNot("pet.exists")end,
       function()return signal(S,"target.targetsPlayer")end))))
 end)
 for _,item in ipairs({{"ranged_freezing","Freezing"},{"ranged_frost","Frost"}}) do
  add(item[1],item[2],function(S,c)
   return and2(ranged(S),trapWhen(S,c,item[2]))
  end,nil,"defensive")
 end
 for _,act in ipairs({"Wrath","Rapid","Intimidate"}) do
  add("ranged_"..act:lower(),act,function(S,c)
   return and2(ranged(S),cds(S,c,act))
  end,nil,"cooldowns")
 end
 local function aoe(S,c)
  if c.aoe=="off" then return false end
  local n=signal(S,"enemy.count")
  if type(n)~="number" then return nil end
  if n<2 then return false end
  if c.aoe=="aggressive" then return true end
  return signal(S,"aoe.safe")
 end
 add("aoe_explosive","Explosive",function(S,c)
  return and2(ranged(S),and2(aoe(S,c),
   and2(S:ge("enemy.count",3),signal(S,"trap.profitable"))))
 end,nil,"damage")
 add("aoe_volley","Volley",function(S,c)
  return and2(ranged(S),and2(aoe(S,c),
   and2(S:ge("enemy.count",3),signal(S,"volley.profitable"))))
 end,nil,"damage")
 add("aoe_multi","Multi",function(S,c)
  if c.aimed_multi=="aimed" then return false end
  return and2(ranged(S),and2(aoe(S,c),
   and2(signal(S,"multi.profitable"),mana(S,c,is60))))
 end,nil,"damage")
 add("ranged_hawk","Hawk",function(S,c)
  if c.hawk_arcane=="off" or c.hawk_arcane=="arcane" then return false end
  local knownHawk=known(S,spells,"Hawk")
  if knownHawk~=true then return knownHawk end
  if signal(S,"target.dyingSoon")==true then return false end
  local count=signal(S,"hawk.count")
  local oldest=signal(S,"hawk.oldestRemaining")
  if type(count)~="number" then return nil end
  if count>=2 and type(oldest)~="number" then return nil end
  return and2(ranged(S),and2(mana(S,c,is60),
   count<2 or oldest<=1.5))
 end)
 add("ranged_aimed","Aimed",function(S,c)
  if not c.use_aimed_shot then return false end
  if c.aimed_multi=="multi" and aoe(S,c)==true then return false end
  return and2(ranged(S),and2(mana(S,c,is60),
   signal(S,"aimed.profitable")))
 end)
 add("ranged_arcane","Arcane",function(S,c)
  if c.hawk_arcane=="off" then return false end
  local gate=and2(ranged(S),mana(S,c,is60))
  if gate~=true then return gate end
  local h=known(S,spells,"Hawk")
  if h==false then return true end
  if h~=true then return nil end
  if c.hawk_arcane=="hawk" then return false end
  if c.hawk_arcane=="arcane" then return true end
  if signal(S,"target.dyingSoon")==true then return true end
  local count=signal(S,"hawk.count")
  local oldest=signal(S,"hawk.oldestRemaining")
  if type(count)~="number" or type(oldest)~="number" then return nil end
  return count>=2 and oldest>=6
 end)
 add("ranged_sting","Sting",function(S,c)
  if c.sting=="off" then return false end
  local gate=and2(ranged(S),mana(S,c,is60))
  if gate~=true then return gate end
  if c.sting=="elite" then
   local kind=signal(S,"target.classification")
   if type(kind)~="string" then return nil end
   if kind~="elite" and kind~="rareelite" and kind~="worldboss" then
    return false
   end
  elseif c.sting=="smart" then
   local good=signal(S,"sting.profitable")
   if good~=true then return good end
  end
  local remain=signal(S,"target.stingRemaining")
  if type(remain)~="number" then
   return S:isNot("target.debuff",spells.Sting)
  end
  return remain<=2
 end)
 add("filler_immolation","Immolation",function(S)
  return and2(ranged(S),signal(S,"trap.profitable"))
 end)
 add("filler_multi","Multi",function(S,c)
  if not c.multi_filler then return false end
  local aimedKnown=known(S,spells,"Aimed")
  if c.use_aimed_shot and aimedKnown~=false then
   return aimedKnown==true and false or nil
  end
  return and2(ranged(S),and2(mana(S,c,is60),
   signal(S,"multi.profitable")))
 end)
 return rules
end
local function readLearned()
 local book=KR.SpellCatalogue
 if not book or type(book.Read)~="function" then return nil end
 local ok,data=pcall(book.Read,book)
 if not ok or type(data)~="table" or data.status~="ready"
    or type(data.entries)~="table" then return nil end
 return data.entries
end
local function resolveSpells(entries)
 local spells={}
 for _,row in ipairs(spec) do spells[row[1]]=row[3] end
 if type(entries)~="table" then return spells end
 -- Resolve localized spell names using the same protected-aware GameAPI
 -- as SpellCatalogue; English labels in the design source are not WoW locale IDs.
 local names={}
 local api=KR.GameAPI
 for _,row in ipairs(spec) do
  local name=row[2]
  if api and type(api.ReadValues)=="function" then
   local ok,r=pcall(api.ReadValues,api,"GetSpellInfo",row[3])
   if ok and type(r)=="table" and r.status=="READY"
      and type(r.value)=="table" and type(r.value[1])=="string"
      and api:IsSafeValue(r.value[1]) and r.value[1]~="" then
    name=r.value[1]
   end
  end
  if name==row[2] and api and type(api.Read)=="function"
      and type(api.ReadField)=="function" then
   local ok,r=pcall(api.Read,api,"C_Spell.GetSpellInfo",
       "table",row[3])
   if ok and type(r)=="table" and r.status=="READY" then
    local v=api:ReadField(r.value,"name","string")
    if v and v.status=="READY" and type(v.value)=="string"
        and v.value~="" then name=v.value end
   end
  end
  names[row[1]]=name
 end
 local ranked={}
 for _,entry in ipairs(entries) do
  if type(entry)=="table" and type(entry.name)=="string"
      and type(entry.id)=="number" and entry.known==true then
   for _,row in ipairs(spec) do
    if entry.name==names[row[1]] then
     local old=ranked[row[1]]
     local rank=type(entry.rankNumber)=="number" and entry.rankNumber or 0
     if not old or rank>old.rank then
      ranked[row[1]]={id=entry.id,rank=rank}
     end
    end
   end
  end
 end
 for key,v in pairs(ranked) do spells[key]=v.id end
 local seen={}
 for _,entry in ipairs(entries) do
  if type(entry)=="table" and type(entry.id)=="number" and
     entry.known==true then seen[entry.id]=true end
 end
 for _,candidate in ipairs(arcaneRanks) do
  if seen[candidate[1]] then spells.Arcane=candidate[1] break end
 end
 for _,id in ipairs(hawkRanks) do
  if seen[id] then spells.Hawk=id break end
 end
 -- Sonah ActionSlots: only pair a learned rank with an independently
 -- verified exact spell ID on a visible action button.
 local scanner=KR.ActionBarScanner
 if scanner and type(scanner.GetSnapshot)=="function" then
  local ok,bar=pcall(scanner.GetSnapshot,scanner)
  if ok and type(bar)=="table" and bar.status=="READY"
      and type(bar.entries)=="table" then
   local visible={}
   for _,button in ipairs(bar.entries) do
    if type(button)=="table" and type(button.spellID)=="number"
        and (not api or not api.IsSafeValue
             or api:IsSafeValue(button.spellID)) then
     visible[button.spellID]=true
    end
   end
   for _,key in ipairs({"AspectHawk","AspectMonkey"}) do
    local selected,selectedRank
    for _,entry in ipairs(entries) do
     if type(entry)=="table" and entry.known==true
         and type(entry.id)=="number" and visible[entry.id]
         and entry.name==names[key] then
      local rank=type(entry.rankNumber)=="number" and entry.rankNumber or 0
      if not selected or rank>selectedRank then
       selected,selectedRank=entry.id,rank
      end
     end
    end
    if selected then spells[key]=selected end
   end
  end
 end
 return spells
end
local function barSignature()
 local scanner=KR.ActionBarScanner
 if not scanner or type(scanner.GetSnapshot)~="function" then return nil end
 local ok,snapshot=pcall(scanner.GetSnapshot,scanner)
 if not ok or type(snapshot)~="table" or snapshot.status~="READY"
     or type(snapshot.entries)~="table" then return nil end
 local ids={}
 for _,item in ipairs(snapshot.entries) do
  if type(item)=="table" and type(item.spellID)=="number" then
   ids[#ids+1]=tostring(item.spellID)
  end
 end
 table.sort(ids)
 return table.concat(ids,",")
end
function M:Register()
 if not KR.RotationProfiles or not KR.RotationProfiles.Replace then
  return false,"registry_unavailable"
 end
 local spells=resolveSpells(readLearned())
 local rules=makeRules(spells,false)
 local skips={}
 for _,rule in ipairs(rules) do
  if rule.onUnknown=="skip" then
   skips[rule.id]={safeOptional=true,
     reason="Optional legacy improvement with unavailable condition source",
     testID="BM_LEVELING_DIAG_"..rule.id}
  end
 end
 local ok,why=KR.RotationProfiles:Replace("HUNTER",1,{
  contractVersion=1,id="HUNTER_BM_LEVELING_PVE",version="2.3.0-contract1",
  classToken="HUNTER",specIndex=1,levelMin=1,levelMax=59,
  status="experimental",Spells=spells,Rules=rules,
  Needs={auras={spells.Mark,spells.Sting,spells.AspectHawk,
      spells.AspectMonkey},ranges={spells.Arcane},
      enemyCount=true,ttd=true,swing=true},
  Config=cfgTable(false),SkipExceptions=skips
 })
 if not ok then return false,why end
 local success,reason=self:Register60()
 if not success then return false,reason end
 -- Re-evaluate rank only when the visible bar spell-ID set changes.
 self.barSignature=barSignature()
 if not self.barSubscribed and KR.EventBus
     and type(KR.EventBus.Subscribe)=="function" then
  self.barSubscribed=KR.EventBus:Subscribe("actionbar",
      "BMLevelingRankSelection",function()
   local signature=barSignature()
   if signature and signature~=M.barSignature then M:Register() end
  end)==true
 end
 return true,"HUNTER_BM_LEVELING_PVE"
end
function M:Register60()
 if not KR.RotationProfiles or not KR.RotationProfiles.Replace then
  return false,"registry_unavailable"
 end
 local spells=resolveSpells(readLearned())
 local rules=makeRules(spells,true)
 local skips={}
 for _,rule in ipairs(rules) do
  if rule.onUnknown=="skip" then
   skips[rule.id]={safeOptional=true,
      reason="Optional BM 60 legacy improvement with unavailable provider",
      testID="BM_60_DIAG_"..rule.id}
  end
 end
 local auras={spells.Mark,spells.Sting,spells.AspectHawk,
     spells.AspectMonkey,spells.Trueshot}
 return KR.RotationProfiles:Replace("HUNTER",1,{
  contractVersion=1,id="HUNTER_BM_60_PVE",version="1.2.0-contract1",
  classToken="HUNTER",specIndex=1,levelMin=60,levelMax=60,
  status="experimental",Spells=spells,Rules=rules,
  Needs={auras=auras,ranges={spells.Arcane},
      enemyCount=true,ttd=true,swing=true},
  Config=cfgTable(true),SkipExceptions=skips
 })
end
