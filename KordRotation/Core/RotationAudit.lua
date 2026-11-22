-- Kord Rotation (c) 2026 Vi22Rus; see root LICENSE.
-- Opt-in read-only full-profile inspection. Called only by the optional
-- DevTools bridge while its user has started recording. NO gameplay actions.
local _,KR=...
local A=KR.RotationEngine
local function safe(v)
 local api=KR.GameAPI
 if not api or type(api.IsSafeValue)~="function" then return false end
 local ok,yes=pcall(api.IsSafeValue,api,v)
 return ok and yes==true
end
local function config(profile,saved)
 local result={}
 local all=type(saved)=="table" and saved.moduleConfigs or nil
 local data=type(all)=="table" and all[profile.id] or nil
 if type(data)~="table" or not safe(data) then data={} end
 for _,def in ipairs(profile.Config or {}) do
  local v=data[def.key]
  if not safe(v) then v=nil end
  if def.type=="bool" then
   result[def.key]=type(v)=="boolean" and v or def.default
  elseif def.type=="number" then
   result[def.key]=type(v)=="number" and v==v
    and v>=def.min and v<=def.max and v or def.default
  elseif def.type=="enum" then
   local valid=false
   for _,candidate in ipairs(def.values) do
    if candidate==v then valid=true break end
   end
   result[def.key]=valid and v or def.default
  end
 end
 return result
end
local function audit()
 local state=KR.characterState
 if not state or not safe(state) then
  return {status="UNKNOWN",reason="specialization_unknown",rules={}}
 end
 local class=state.classToken
 local index=state.index
 if not safe(class) or not safe(index)
    or type(class)~="string" or type(index)~="number"
    or index<1 or index>3 or index~=math.floor(index) then
  return {status="UNKNOWN",reason="specialization_unknown",rules={}}
 end
 local identity=class.."_TREE_"..index
 local settings=KR.RotationSettings
 local saved,key
 if settings and type(settings.GetProfile)=="function" then
  saved,key=settings:GetProfile(false)
 end
 if key~=identity or not saved then
  return {status="UNKNOWN",reason="rotation_settings_unavailable",rules={}}
 end
 local gs=KR.GameState
 if not gs or type(gs.GetSnapshot)~="function" then
  return {status="UNKNOWN",reason="game_state_missing",rules={}}
 end
 local ok,snapshot=pcall(gs.GetSnapshot,gs,true)
 if not ok or type(snapshot)~="table" or not safe(snapshot) then
  return {status="UNKNOWN",reason="game_state_unavailable",rules={}}
 end
 local levelRecord=snapshot.player and snapshot.player.level
 local level=levelRecord and levelRecord.status=="READY" and levelRecord.value
 if not safe(level) or type(level)~="number"
     or level~=math.floor(level) or level<1 or level>100 then
  return {status="UNKNOWN",reason="player_level_unverified",rules={}}
 end
 local profiles=KR.RotationProfiles
 local profile=profiles and profiles:ResolveForEngine(identity,level)
 if not profile then
  return {status="UNKNOWN",reason="profile_for_level_missing",rules={}}
 end
 local C=KR.RotationConditions
 local S=C and C:Create(profile,snapshot)
 if not S then
  return {status="UNKNOWN",reason="condition_context_missing",rules={}}
 end
 local cfg=config(profile,saved)
 local result={status="READY",reason="none",rules={},profileID=profile.id,
  rulesTotal=#profile.Rules}
 local mode=saved.targetMode
 for i,rule in ipairs(profile.Rules) do
  local before=C:ObservationCount(S)
  local st,why,checks,barReason
  if rule.type~="SPELL" then
   -- Unsupported action types are still audited for prerequisite data,
   -- but never passed to AbilityEligibility or emitted as recommendations.
   local evaluated,condition=pcall(rule.when,S,cfg)
   if not evaluated then st,why="UNKNOWN","condition_error"
   elseif condition==nil then st,why="UNKNOWN","condition_unknown"
   elseif condition==false then st,why="BLOCKED","condition_false"
   else st,why="BLOCKED","unsupported_action" end
  elseif rule.mode and rule.mode~="any" and rule.mode~=mode then
   st,why="BLOCKED","mode_not_selected"
  else
   local spellID=profile.Spells[rule.spell]
   local overrides=type(saved.spells)=="table"
       and saved.spells[spellID] or nil
   local category=type(overrides)=="table" and overrides.category
       or rule.category
   if rule.enabled==false or
       (type(overrides)=="table" and overrides.enabled==false) then
    st,why="BLOCKED","rule_disabled"
   elseif type(saved.categories)~="table"
       or saved.categories[category]~=true then
    st,why="BLOCKED","category_disabled"
   else
    local evaluated,condition=pcall(rule.when,S,cfg)
    if not evaluated then
     st,why="UNKNOWN","condition_error"
    elseif condition==false then
     st,why="BLOCKED","condition_false"
    elseif condition~=true then
     st,why="UNKNOWN",condition==nil and
       "condition_unknown" or "condition_invalid"
    else
     local policy={target=rule.target,cast=rule.cast,
       chargesRequired=rule.chargesRequired}
     local record=C:Check(S,spellID,policy)
     if type(record)=="table" and safe(record) then
      st,why=record.status,record.reason
      if type(record.checks)=="table" and safe(record.checks)
         and #record.checks<=6 then checks=record.checks end
      if type(record.barReason)=="string" and safe(record.barReason) then
       barReason=record.barReason
      end
     else st,why="UNKNOWN","eligibility_unverified" end
    end
   end
  end
  result.rules[#result.rules+1]={
   priority=i,status=st,reason=why,checks=checks,
   barReason=barReason,signals=C:ObservationsSince(S,before)
  }
 end
 return result
end
function A:AuditFull()
 local ok,result=pcall(audit)
 if not ok or type(result)~="table" then
  return {status="UNKNOWN",reason="engine_exception",rules={}}
 end
 return result
end
