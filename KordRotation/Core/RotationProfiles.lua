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
-- Explicit semantic classification: not every spell in 'buffs' is an aura.
local recommendationTypes={aura=true}
local allowedNeeds={auras=true,ranges=true,enemyCount=true,ttd=true,swing=true}
local function finite(n)
 return type(n)=="number" and n==n and n~=math.huge and n~=-math.huge
end
local function spellID(n)
 local api=KR.GameAPI
 if api and type(api.IsSafeValue)=="function" then
  local ok,allowed=pcall(api.IsSafeValue,api,n)
  if not ok or allowed~=true then return false end
 end
 return finite(n) and n==math.floor(n) and n>=1 and n<=99999999
end
local function dense(t,max)
 -- Lua 5.1 does not define #t for an array with holes. Establish a
 -- contiguous 1..count sequence without consulting the length operator.
 if type(t)~="table" then return false end
 local count=0
 for k in pairs(t) do
  if type(k)~="number" or k~=k or k~=math.floor(k)
      or k<1 or k>max then return false end
  count=count+1
  if count>max then return false end
 end
 for i=1,count do
  if rawget(t,i)==nil then return false end
 end
 return true
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
     (not finite(item.default) or not finite(item.min)
      or not finite(item.max) or item.min>item.max
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
      or (rule.recommendationType~=nil and
          not recommendationTypes[rule.recommendationType])
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
 local called,ok,reason=pcall(validate,profile,classToken,specIndex)
 if not called then return false,"profile_validation_error" end
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
 local copied,record=pcall(copy,profile,0)
 if not copied or type(record)~="table" then
  return false,"profile_copy_unavailable"
 end
 list[#list+1]=record
 registry[key]=list
 return true,profile.id
end
local function safeIdentityValue(value)
 local api=KR.GameAPI
 if not api or type(api.IsSafeValue)~="function" then return false end
 local ok,safe=pcall(api.IsSafeValue,api,value)
 return ok and safe==true
end
local function selectProfile(key,level)
 -- Public lookups must never compare protected levels or index by a
 -- protected key. Only trusted, ordinary values can select a profile.
 if not safeIdentityValue(key) or type(key)~="string" then return nil end
 local list=registry[key]
 if not list then return nil end
 if level==nil then return #list==1 and list[1] or nil end
 if not safeIdentityValue(level) or type(level)~="number"
     or level~=level or level~=math.floor(level) then return nil end
 for _,profile in ipairs(list) do
  if level>=profile.levelMin and level<=profile.levelMax then
   return profile
  end
 end
 return nil
end
function P:Get(key,level)
 local profile=selectProfile(key,level)
 return profile and copy(profile,0) or nil
end
-- Internal engine-only view of registered, source-validated, stable metadata.
-- Never expose this reference to profile callbacks, SavedVariables or DevTools.
-- Only trusted KordRotation code may call this; external Get remains defensive.
function P:ResolveForEngine(key,level)
 return selectProfile(key,level)
end
function P:Has(key,level)
 if not safeIdentityValue(key) or type(key)~="string"
     or registry[key]==nil then return false end
 if level==nil then return true end
 return selectProfile(key,level)~=nil
end
-- Replace the active level interval atomically after the spellbook changes.
-- Used for dynamically registered, learned-rank profiles at login/level-up.
function P:Replace(classToken,specIndex,profile)
 local key=type(classToken)=="string" and classToken.."_TREE_"..tostring(specIndex) or nil
 if not key then return false,"invalid_profile_identity" end
 local called,valid,why=pcall(validate,profile,classToken,specIndex)
 if not called or not valid then return false,why or "profile_validation_error" end
 local list=registry[key] or {}
 for _,item in ipairs(list) do
  if item.id~=profile.id and item.levelMin<=profile.levelMax
    and profile.levelMin<=item.levelMax then
   return false,"profile_level_overlap"
  end
 end
 local ok,record=pcall(copy,profile,0)
 if not ok or type(record)~="table" then return false,"profile_copy_unavailable" end
 local updated={}
 for _,item in ipairs(list) do if item.id~=profile.id then updated[#updated+1]=item end end
 updated[#updated+1]=record
 registry[key]=updated
 return true,profile.id
end
-- No profiles are registered by default; old Hunter sources remain unloaded.
