-- Kord Rotation (c) 2026 Vi22Rus. All rights reserved.
-- Contract v1: one safe current recommendation; no speculative future queue.
local addonName, KR=...
KR.RotationEngine=KR.RotationEngine or {}
local E=KR.RotationEngine
local function unknown(reason,profileID,diagnostics)
 return {status="UNKNOWN",reason=reason,queue={},source="RotationEngine",
  profileID=profileID,diagnostics=diagnostics or {}}
end
local function blocked(reason,profileID,diagnostics)
 return {status="BLOCKED",reason=reason,queue={},source="RotationEngine",
  profileID=profileID,diagnostics=diagnostics or {}}
end
local function safe(value)
 local api=KR.GameAPI
 if not api or type(api.IsSafeValue)~="function" then return false end
 local ok,valid=pcall(api.IsSafeValue,api,value)
 return ok and valid==true
end
local function validID(id)
 return safe(id) and type(id)=="number" and id==id
  and id==math.floor(id) and id>=1 and id<=99999999
end
local function asset(value)
 return safe(value) and
  ((type(value)=="string" and #value>0 and #value<=255)
   or (type(value)=="number" and value==value
     and value<math.huge and value>0))
end
local function identity()
 local s=KR.characterState
 if type(s)~="table" or not safe(s) or not safe(s.classToken)
     or type(s.classToken)~="string" or not s.classToken:match("^[A-Z]+$")
     or not safe(s.index) or type(s.index)~="number"
     or s.index~=math.floor(s.index) or s.index<1 or s.index>3 then return nil end
 return s.classToken.."_TREE_"..s.index
end
local function config(profile,saved)
 local cfg={}
 local options=nil
 if type(saved)=="table" then
  local modules=saved.moduleConfigs
  options=type(modules)=="table" and modules[profile.id] or saved.config
 end
 if type(options)~="table" or not safe(options) then options={} end
 for _,def in ipairs(profile.Config) do
  local value=options[def.key]
  if not safe(value) then value=nil end
  if def.type=="bool" then
   if type(value)=="boolean" then
    cfg[def.key]=value
   else
    cfg[def.key]=def.default
   end
  elseif def.type=="number" then
   cfg[def.key]=type(value)=="number" and value==value and
    value~=math.huge and value~=-math.huge and value>=def.min
    and value<=def.max and value or def.default
  elseif def.type=="enum" then
   local valid=false
   for _,candidate in ipairs(def.values) do
    if type(candidate)==type(value) and candidate==value then valid=true end
   end
   if valid then cfg[def.key]=value
   else cfg[def.key]=def.default end
  end
 end
 return cfg
end
local function findVisual(id)
 local book=KR.SpellCatalogue
 if not book or type(book.Read)~="function" then return nil end
 local ok,data=pcall(book.Read,book)
 if not ok or type(data)~="table" or not safe(data)
     or not safe(data.status) or data.status~="ready"
     or type(data.entries)~="table" or not safe(data.entries) then return nil end
 for _,entry in ipairs(data.entries) do
  if type(entry)=="table" and safe(entry)
      and validID(entry.id) and entry.id==id
      and safe(entry.known) and entry.known==true
      and safe(entry.name) and type(entry.name)=="string"
      and #entry.name>0 and #entry.name<=255
      and asset(entry.texture) then
   return entry.name,entry.texture
  end
 end
 return nil
end
local function binding(id)
 local module=KR.BindingResolver
 if not module or type(module.Resolve)~="function" then return nil,nil end
 local ok,b=pcall(module.Resolve,module,id)
 if not ok or type(b)~="table" or not safe(b)
    or not safe(b.status) or b.status~="READY"
    or not validID(b.spellID) or b.spellID~=id
    or not safe(b.bindingLabel)
    or type(b.bindingLabel)~="string"
    or #b.bindingLabel<1 or #b.bindingLabel>64
    or (b.bindingSource~=nil and
      (not safe(b.bindingSource) or type(b.bindingSource)~="string")) then
  return nil,nil
 end
 return b.bindingLabel,b.bindingSource
end
local function levelOf(snapshot)
 if not safe(snapshot) or type(snapshot)~="table"
    or type(snapshot.player)~="table" or not safe(snapshot.player)
    or type(snapshot.player.level)~="table" then return nil end
 local r=snapshot.player.level
 if not safe(r) or not safe(r.status) or r.status~="READY"
     or not validID(r.value) or r.value>100 then return nil end
 return r.value
end
local function run(channel,sharedSnapshot,sharedContext)
 channel=channel=="defensive" and "defensive" or "main"
 if not KR.RotationProfiles or type(KR.RotationProfiles.ResolveForEngine)~="function"
    or not KR.RotationSettings or not KR.AbilityEligibility
    or not KR.RotationConditions or not KR.GameState then
  return unknown("engine_dependency_missing")
 end
 local identityID=identity()
 if not identityID then return unknown("specialization_unknown") end
 if not KR.RotationProfiles:Has(identityID) then
  return unknown("profile_not_registered") end
 local saved,id=KR.RotationSettings:GetProfile(false)
 if id~=identityID or not saved then return unknown("rotation_settings_unavailable") end
 if not safe(saved) or saved.enabled~=true then return unknown("rotation_disabled") end
 local mode=saved.targetMode
 if not safe(mode) then return unknown("target_mode_invalid") end
 if mode=="auto" then return unknown("auto_target_count_unverified") end
 if mode~="single" and mode~="aoe" then return unknown("target_mode_invalid") end
 if type(KR.GameState.GetSnapshot)~="function" then
  return unknown("game_state_missing") end
 local snapshot=sharedSnapshot
 if snapshot==nil then
  local ok,read=pcall(KR.GameState.GetSnapshot,KR.GameState,true)
  if ok then snapshot=read end
 end
 if type(snapshot)~="table" or not safe(snapshot)
   or type(snapshot.player)~="table" or type(snapshot.target)~="table" then
  return unknown("game_state_unavailable") end
 local level=levelOf(snapshot)
 if not level then return unknown("player_level_unverified") end
 local profile=KR.RotationProfiles:ResolveForEngine(identityID,level)
 if not profile then return unknown("profile_for_level_missing") end
 if profile.status~="verified" and
    not (profile.status=="experimental" and saved.allowUnverifiedProfiles==true) then
  return unknown("profile_unverified",profile.id) end
 local cfg=sharedContext and sharedContext.config or config(profile,saved)
 local S=sharedContext and sharedContext.conditions
 if not S then S=KR.RotationConditions:Create(profile,snapshot) end
 if not S then return unknown("condition_context_missing",profile.id) end
 local diagnostics={}
 local combatRecord=snapshot.player and snapshot.player.combat
 local inCombat=type(combatRecord)=="table" and safe(combatRecord)
     and combatRecord.status=="READY" and safe(combatRecord.value)
     and combatRecord.value==true
 local auraInMain=inCombat and
     KR.RotationSettings:GetFlag("buffsInCombatMain")==true
 for i,rule in ipairs(profile.Rules) do
  local spellID=rule.type=="SPELL" and profile.Spells[rule.spell] or nil
  local status,reason
  local ruleChecks,ruleBarReason
  -- The rule and effective category determine the window; spell identity
  -- and the localized name never participate in this decision.
  local overrides=type(saved.spells)=="table" and saved.spells[spellID] or nil
  local category=rule.category
  if type(overrides)=="table" and
      type(overrides.category)=="string" then
   category=overrides.category
  end
  local kind,maintenance=KR.RotationProfiles:RecommendationKind(rule,category)
  if (maintenance and ((channel=="main")~=auraInMain))
      or (not maintenance and channel=="defensive") then
   status,reason="BLOCKED","routed_to_other_channel"
  elseif rule.type~="SPELL" then
   status,reason="BLOCKED","unsupported_action"
  elseif rule.mode~=nil and rule.mode~="any" and rule.mode~=mode then
   status,reason="BLOCKED","mode_not_selected"
  else
   if rule.enabled==false or
       (type(overrides)=="table" and overrides.enabled==false) then
    status,reason="BLOCKED","rule_disabled"
   elseif type(saved.categories)~="table"
       or saved.categories[category]~=true then
    status,reason="BLOCKED","category_disabled"
   else
    -- A function is called only for this priority and gets no raw snapshot.
    local conditionOK,when=pcall(rule.when,S,cfg)
    if not conditionOK then
     status,reason="UNKNOWN","condition_error"
    elseif when==false then
     status,reason="BLOCKED","condition_false"
    elseif when~=true then
     status,reason="UNKNOWN",when==nil and
       "condition_unknown" or "condition_invalid"
    else
     local policy={target=rule.target,cast=rule.cast,
       chargesRequired=rule.chargesRequired}
     local result=KR.RotationConditions:Check(S,spellID,policy)
     status,reason=result.status,result.reason
     -- Safe core-only metadata, never included in the public recommendation.
     -- Keep the diagnostic only for the rule that was actually evaluated.
     if type(result.checks)=="table" and safe(result.checks)
         and #result.checks<=6 then
      ruleChecks=result.checks
     end
     if type(result.barReason)=="string" and safe(result.barReason) then
      ruleBarReason=result.barReason
     end
     if status~="READY" and status~="BLOCKED" and status~="UNKNOWN" then
      status,reason="UNKNOWN","eligibility_status_invalid"
     end
    end
   end
  end
  local diag={priority=i,status=status,reason=reason}
  if ruleChecks then diag.checks=ruleChecks end
  if ruleBarReason then diag.barReason=ruleBarReason end
  diagnostics[#diagnostics+1]=diag
  if status=="UNKNOWN" then
   if reason=="condition_unknown" and rule.onUnknown=="skip" then
    diag.reason="condition_unknown_skipped"
   else return unknown(reason or "higher_priority_unknown",profile.id,diagnostics) end
  elseif status=="READY" then
   local name,texture=findVisual(spellID)
   if not name then
    diag.status,diag.reason="UNKNOWN","spell_visual_data_unverified"
    return unknown("spell_visual_data_unverified",profile.id,diagnostics)
   end
   local keybind,bindingSource=binding(spellID)
   local record={spellID=spellID,texture=texture,name=name,
    keybind=keybind,bindingSource=bindingSource,
    source=profile.status=="verified" and "verified_profile" or "experimental_profile",
    priority=i,category=category,mode=mode,
    recommendationType=kind,channel=channel}
   return {status="READY",source="RotationEngine",profileID=profile.id,
    mode=mode,channel=channel,queue={record},diagnostics=diagnostics}
  end
 end
 return blocked("no_eligible_rule",profile.id,diagnostics)
end
function E:Evaluate()
 local ok,result=pcall(run,"main")
 if not ok or type(result)~="table" then return unknown("engine_exception") end
 return result
end
-- Independent optional aura channel: unknown DPS conditions cannot block it.
function E:EvaluateDefensive()
 local ok,result=pcall(run,"defensive")
 if not ok or type(result)~="table" then return unknown("engine_exception") end
 return result
end
-- Both channels observe exactly the same fresh read-only game snapshot.
-- Evaluations remain independent: an unknown DPS fact must not block aura upkeep.
function E:EvaluateBoth()
 if not KR.GameState or type(KR.GameState.GetSnapshot)~="function" then
  return unknown("game_state_missing"),unknown("game_state_missing")
 end
 local ok,snapshot=pcall(KR.GameState.GetSnapshot,KR.GameState,true)
 if not ok or type(snapshot)~="table" then
  return unknown("game_state_unavailable"),unknown("game_state_unavailable")
 end
 -- Share the same per-evaluation demand-driven provider cache in both
 -- channels. Each condition and Blizzard API fact is read at most once,
 -- even when a recommendation is evaluated for both windows.
 local prepared
 local currentID=identity()
 if currentID and KR.RotationProfiles and KR.RotationSettings and
     KR.RotationConditions and type(KR.RotationConditions.Create)=="function" then
  local saved=KR.RotationSettings:GetProfile(false)
  local level=levelOf(snapshot)
  if saved and level then
   local profile=KR.RotationProfiles:ResolveForEngine(currentID,level)
   if profile then
    local ctx=KR.RotationConditions:Create(profile,snapshot)
    if ctx then prepared={conditions=ctx,config=config(profile,saved)} end
   end
  end
 end
 local mainOK,main=pcall(run,"main",snapshot,prepared)
 local defOK,def=pcall(run,"defensive",snapshot,prepared)
 if not mainOK or type(main)~="table" then main=unknown("engine_exception") end
 if not defOK or type(def)~="table" then def=unknown("engine_exception") end
 return main,def
end
-- UI/EventBus own bounded updates; this module installs no OnUpdate loop.
