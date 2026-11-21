-- Kord Rotation (c) 2026 Vi22Rus. All rights reserved.
-- Profile Contract v1: immutable metadata copies, no executable legacy profiles.
local addonName, KR = ...
KR.RotationProfiles = KR.RotationProfiles or {}
local P = KR.RotationProfiles
local registry = {}
local statuses={draft=true,mock_tested=true,experimental=true,verified=true}
local categories={damage=true,cooldowns=true,buffs=true,racial=true,
 trinkets=true,consumables=true,defensive=true,interrupts=true,movement=true}
local targets={enemy=true,friendly=true,self=true,none=true}
local casts={idle=true,allow=true}
local allowedNeeds={auras=true,ranges=true,enemyCount=true,ttd=true,swing=true}
local function spellID(n)
 return type(n)=="number" and n==n and n~=math.huge
     and n==math.floor(n) and n>=1 and n<=99999999
end
local function dense(t,max)
 if type(t)~="table" or #t>max then return false end
 local count=0
 for k in pairs(t) do
  if type(k)~="number" or k~=math.floor(k) or k<1 or k>#t then return false end
  count=count+1
 end
 return count==#t
end
local function nonempty(s,max)
 return type(s)=="string" and #s>0 and #s<=max
end
local function copy(value,depth)
 if type(value)~="table" then return value end
 if depth>8 then return nil end
 local out={}
 for k,v in pairs(value) do out[k]=copy(v,depth+1) end
 return out
end
local function needList(value)
 if not dense(value,96) then return false end
 local seen={}
 for _,n in ipairs(value) do
  if not spellID(n) or seen[n] then return false end
  seen[n]=true
 end
 return true
end
local function validate(profile,classToken,specIndex)
 if type(profile)~="table" or profile.contractVersion~=1
     or not nonempty(profile.id,96) or not profile.id:match("^[A-Z][A-Z0-9_]+$")
     or not nonempty(profile.version,40)
     or profile.classToken~=classToken or profile.specIndex~=specIndex
     or not statuses[profile.status]
     or type(profile.levelMin)~="number" or type(profile.levelMax)~="number"
     or profile.levelMin~=math.floor(profile.levelMin)
     or profile.levelMax~=math.floor(profile.levelMax)
     or profile.levelMin<1 or profile.levelMax>100
     or profile.levelMin>profile.levelMax then
  return false,"invalid_profile_metadata"
 end
 if type(profile.Spells)~="table" then return false,"invalid_spell_registry" end
 local ids,spellNames={},{}
 local count=0
 for name,n in pairs(profile.Spells) do
  if not nonempty(name,48) or not name:match("^[A-Za-z][A-Za-z0-9_]*$")
      or not spellID(n) or ids[n] then return false,"invalid_spell_registry" end
  ids[n],spellNames[name]=true,n
  count=count+1
 end
 if count==0 or count>256 then return false,"invalid_spell_registry" end
 if type(profile.Needs)~="table" then return false,"invalid_needs" end
 for key,val in pairs(profile.Needs) do
  if not allowedNeeds[key] then return false,"invalid_needs" end
  if key=="auras" or key=="ranges" then
   if not needList(val) then return false,"invalid_needs" end
  elseif type(val)~="boolean" then return false,"invalid_needs" end
 end
 if type(profile.Config)~="table" or not dense(profile.Config,128) then
  return false,"invalid_config"
 end
 local configKeys={}
 for _,item in ipairs(profile.Config) do
  if type(item)~="table" or not nonempty(item.key,48)
      or configKeys[item.key] or not nonempty(item.label,128)
      or not nonempty(item.group,64) or type(item.desc)~="string"
      or (item.type~="bool" and item.type~="number" and item.type~="enum") then
   return false,"invalid_config"
  end
  configKeys[item.key]=true
  if item.type=="bool" and type(item.default)~="boolean" then return false,"invalid_config" end
  if item.type=="number" and
     (type(item.default)~="number" or type(item.min)~="number"
      or type(item.max)~="number" or item.min>item.max
      or item.default<item.min or item.default>item.max) then
   return false,"invalid_config"
  end
  if item.type=="enum" then
   if not dense(item.values,32) then return false,"invalid_config" end
   local ok=false
   for _,v in ipairs(item.values) do
    if v==item.default then ok=true end
   end
   if not ok then return false,"invalid_config" end
  end
 end
 if not dense(profile.Rules,64) or #profile.Rules==0 then
  return false,"invalid_rules"
 end
 local ruleKeys,usedSkip={},{}
 for _,rule in ipairs(profile.Rules) do
  if type(rule)~="table" or not nonempty(rule.id,64)
      or ruleKeys[rule.id] or type(rule.when)~="function"
      or (rule.onUnknown~=nil and rule.onUnknown~="stop" and rule.onUnknown~="skip")
      or not nonempty(rule.reason,128)
      or not categories[rule.category]
      or not targets[rule.target] or not casts[rule.cast]
      or type(rule.chargesRequired)~="boolean"
      or (rule.enabled~=nil and type(rule.enabled)~="boolean") then
   return false,"invalid_rules"
  end
  if rule.type=="SPELL" then
   if type(rule.spell)~="string" or not spellNames[rule.spell]
       or (rule.spellID~=nil and rule.spellID~=spellNames[rule.spell]) then
    return false,"invalid_rule_spell"
   end
  elseif rule.type=="PET_COMMAND" then
   if not nonempty(rule.action,64) or rule.spell~=nil or rule.spellID~=nil then
    return false,"invalid_action"
   end
  else return false,"invalid_action" end
  ruleKeys[rule.id]=true
  if rule.mode~=nil and rule.mode~="any" and rule.mode~="single"
      and rule.mode~="aoe" then return false,"invalid_rule_mode" end
  if rule.onUnknown=="skip" then
   -- Defensive/cooldown actions are not optional improvements by default.
   if rule.category=="defensive" or rule.category=="cooldowns"
       or rule.category=="interrupts" then return false,"skip_not_approved" end
   usedSkip[rule.id]=true
  end
 end
 local skips=profile.SkipExceptions or {}
 if type(skips)~="table" then return false,"invalid_skip_registry" end
 for key,item in pairs(skips) do
  if not usedSkip[key] or type(item)~="table"
      or not nonempty(item.reason,128) or not nonempty(item.testID,64)
      or item.safeOptional~=true then return false,"skip_not_approved" end
 end
 for key in pairs(usedSkip) do
  if not skips[key] then return false,"skip_not_approved" end
 end
 return true
end
function P:Register(classToken,specIndex,profile)
 if type(classToken)~="string" or not classToken:match("^[A-Z]+$")
     or #classToken>16 or type(specIndex)~="number"
     or specIndex~=math.floor(specIndex) or specIndex<1 or specIndex>3 then
  return false,"invalid_profile_identity"
 end
 local ok,reason=validate(profile,classToken,specIndex)
 if not ok then return false,reason end
 local key=classToken.."_TREE_"..specIndex
 local list=registry[key] or {}
 for _,existing in ipairs(list) do
  if existing.id==profile.id
      or (existing.levelMin<=profile.levelMax
      and profile.levelMin<=existing.levelMax) then
   return false,"profile_level_overlap"
  end
 end
 -- Copy all metadata so later mutations cannot change a registered profile.
 -- Function values are intentionally retained; they receive only restricted S.
 list[#list+1]=copy(profile,0)
 registry[key]=list
 return true,profile.id
end
function P:Get(key,level)
 if type(key)~="string" then return nil end
 local list=registry[key]
 if not list then return nil end
 if level==nil and #list==1 then return copy(list[1],0) end
 if type(level)~="number" or level~=math.floor(level) then return nil end
 for _,profile in ipairs(list) do
  if level>=profile.levelMin and level<=profile.levelMax then
   return copy(profile,0)
  end
 end
 return nil
end
function P:Has(key,level)
 if type(key)~="string" or registry[key]==nil then return false end
 if level==nil then return true end
 return self:Get(key,level)~=nil
end
-- No profiles are registered by default; old Hunter sources remain unloaded.
