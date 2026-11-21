-- Kord Rotation (c) 2026 Vi22Rus. All rights reserved.
-- Profile Contract v1: per-evaluation restricted methods; no eager providers.
local addonName,KR=...
KR.RotationConditions=KR.RotationConditions or {}
local C=KR.RotationConditions
local contexts=setmetatable({},{__mode="k"})
local direct={
 ["player.moving"]={"player","moving"},
 ["player.level"]={"player","level"},
 ["player.combat"]={"player","combat"},
 ["player.health.percent"]={"player","health","percent"},
 ["target.isPlayer"]={"target","isPlayer"},
 ["target.exists"]={"target","exists"},
 ["target.attackable"]={"target","attackable"},
 ["pet.exists"]={"pet","exists"},
 ["pet.dead"]={"pet","dead"},
 ["pet.health.percent"]={"pet","health","percent"},
 ["context.inGroup"]={"context","inGroup"},
 ["context.inRaid"]={"context","inRaid"},
 ["context.inInstance"]={"context","inInstance"},
 ["resources.percent"]={"resources","percent"}
}
local function safe(value)
 local api=KR.GameAPI
 if not api or type(api.IsSafeValue)~="function" then return false end
 local ok,allowed=pcall(api.IsSafeValue,api,value)
 return ok and allowed==true
end
local function number(n)
 return safe(n) and type(n)=="number" and n==n
  and n~=math.huge and n~=-math.huge
end
local function spellID(n)
 return number(n) and n==math.floor(n) and n>=1 and n<=99999999
end
local function has(list,id)
 if type(list)~="table" then return false end
 for _,value in ipairs(list) do if value==id then return true end end
 return false
end
local function declared(ctx,field,id)
 local needs=ctx.profile.Needs
 if direct[field] then return id==nil end
 if field=="target.debuff" or field=="player.buff" then
  return spellID(id) and has(needs.auras,id)
 end
 if field=="spell.range" then
  return spellID(id) and has(needs.ranges,id)
 end
 if field=="target.ttd" then return needs.ttd==true and id==nil end
 if field=="enemy.count" then return needs.enemyCount==true and id==nil end
 if field=="autoShot.swing" then return needs.swing==true and id==nil end
 return false
end
local function directRead(ctx,field)
 local path=direct[field]
 if not path then return nil end
 local current=ctx.snapshot
 for _,key in ipairs(path) do
  if type(current)~="table" or not safe(current) then return nil end
  current=current[key]
 end
 if type(current)~="table" or not safe(current)
     or not safe(current.status) or current.status~="READY"
     or not safe(current.value) then return nil end
 local value=current.value
 if type(value)=="boolean" or type(value)=="string" then return value end
 if number(value) then return value end
 return nil
end
local function value(ctx,field,id)
 if not safe(field) or type(field)~="string"
     or not declared(ctx,field,id) then return nil end
 local key=field..":"..(id and tostring(id) or "")
 if ctx.readDone[key] then return ctx.readCache[key] end
 ctx.readDone[key]=true
 local answer=nil
 if direct[field] then
  answer=directRead(ctx,field)
 else
  local state=KR.GameState
  if state and type(state.ReadSignal)=="function" then
   -- ReadSignal is a future canonical v14 provider, never bypass GameAPI.
   local ok,record=pcall(state.ReadSignal,state,field,id,ctx.snapshot)
   if ok and type(record)=="table" and safe(record)
       and safe(record.status) and record.status=="READY"
       and safe(record.value) then
    if type(record.value)=="boolean" or type(record.value)=="string"
        or number(record.value) then answer=record.value end
   end
  end
 end
 ctx.readCache[key]=answer
 return answer
end
local function spellAllowed(ctx,id)
 if not spellID(id) then return false end
 for _,candidate in pairs(ctx.profile.Spells) do
  if candidate==id then return true end
 end
 return false
end
local function eligibility(ctx,id,opts)
 if not spellAllowed(ctx,id) then
  return {status="UNKNOWN",reason="spell_not_declared"}
 end
 if type(opts)~="table" or not safe(opts) then
  return {status="UNKNOWN",reason="eligibility_policy_unverified"}
 end
 local target,cast,charges=opts.target,opts.cast,opts.chargesRequired
 if not safe(target) or not safe(cast) or not safe(charges)
   or (target~="enemy" and target~="friendly" and target~="self" and target~="none")
   or (cast~="idle" and cast~="allow") or type(charges)~="boolean" then
  return {status="UNKNOWN",reason="eligibility_policy_unverified"}
 end
 local key=tostring(id)..":"..target..":"..cast..":"..tostring(charges)
 if ctx.eligibilityCache[key] then return ctx.eligibilityCache[key] end
 local result={status="UNKNOWN",reason="eligibility_missing"}
 local mod=KR.AbilityEligibility
 if mod and type(mod.Evaluate)=="function" then
  local ok,record=pcall(mod.Evaluate,mod,id,{
   target=target,cast=cast,chargesRequired=charges,stateSnapshot=ctx.snapshot
  })
  if ok and type(record)=="table" and safe(record)
      and safe(record.status) and safe(record.spellID)
      and record.spellID==id
      and (record.status=="READY" or record.status=="BLOCKED"
          or record.status=="UNKNOWN")
      and (record.reason==nil or
          (safe(record.reason) and type(record.reason)=="string")) then
   result={status=record.status,reason=record.reason}
  else result={status="UNKNOWN",reason="eligibility_unverified"} end
 end
 ctx.eligibilityCache[key]=result
 return result
end
local methods={}
function methods:is(field,id)
 local ctx=contexts[self]
 local current=ctx and value(ctx,field,id)
 if type(current)~="boolean" then return nil end
 return current==true
end
function methods:isNot(field,id)
 local result=methods.is(self,field,id)
 if result==nil then return nil end
 return not result
end
function methods:eq(field,expected)
 local ctx=contexts[self]
 if not ctx or not safe(expected) then return nil end
 local current=value(ctx,field)
 if current==nil or type(current)~=type(expected) then return nil end
 return current==expected
end
function methods:ge(field,threshold)
 local ctx=contexts[self]
 if not ctx or not number(threshold) then return nil end
 local current=value(ctx,field)
 if not number(current) then return nil end
 return current>=threshold
end
function methods:le(field,threshold)
 local ctx=contexts[self]
 if not ctx or not number(threshold) then return nil end
 local current=value(ctx,field)
 if not number(current) then return nil end
 return current<=threshold
end
function methods:all(...)
 local args={...}
 for i=1,select("#",...) do
  if type(args[i])~="function" then error("condition_not_callable") end
  local v=args[i]()
  if v~=true and v~=false and v~=nil then error("invalid_condition_result") end
  if v==false then return false end
  if v~=true then return nil end
 end
 return true
end
function methods:any(...)
 local args={...}
 local unknown=false
 for i=1,select("#",...) do
  if type(args[i])~="function" then error("condition_not_callable") end
  local v=args[i]()
  if v~=true and v~=false and v~=nil then error("invalid_condition_result") end
  if v==true then return true end
  if v~=false then unknown=true end
 end
 if unknown then return nil end
 return false
end
function methods:spellAvailable(id)
 local ctx=contexts[self]
 if not ctx then return "UNKNOWN" end
 local result=eligibility(ctx,id,{target="enemy",cast="idle",chargesRequired=false})
 return result.status
end
function methods:spellFact(id,kind)
 local ctx=contexts[self]
 if not ctx or not spellAllowed(ctx,id) or not safe(kind)
     or (kind~="known" and kind~="cooldownActive"
      and kind~="inRange" and kind~="chargesAtLeast") then return nil end
 -- Needs is an allowlist for profile facts, not an eager preload request.
 -- Range facts may be queried only for explicitly declared spell IDs.
 if kind=="inRange" and not has(ctx.profile.Needs.ranges,id) then return nil end
 local key=tostring(id)..":"..kind
 if ctx.factDone[key] then return ctx.factCache[key] end
 ctx.factDone[key]=true
 local result=nil
 local mod=KR.AbilityEligibility
 -- An unimplemented fact provider MUST NOT be inferred from full Eligibility.
 if mod and type(mod.Fact)=="function" then
  local ok,record=pcall(mod.Fact,mod,id,kind,{stateSnapshot=ctx.snapshot})
  if ok and type(record)=="table" and safe(record)
      and safe(record.status) and record.status=="READY"
      and safe(record.value) and type(record.value)=="boolean" then
   result=record.value
  end
 end
 ctx.factCache[key]=result
 return result
end
function C:Create(profile,snapshot)
 if type(profile)~="table" or type(snapshot)~="table" then return nil end
 local ctx={profile=profile,snapshot=snapshot,readDone={},readCache={},
  eligibilityCache={},factDone={},factCache={}}
 local S=setmetatable({},{
  __index=methods,
  __newindex=function() error("restricted_profile_state") end,
  __metatable=false
 })
 contexts[S]=ctx
 return S
end
function C:Check(S,spellIDValue,policy)
 local ctx=contexts[S]
 if not ctx then return {status="UNKNOWN",reason="context_unavailable"} end
 return eligibility(ctx,spellIDValue,policy)
end
-- No game globals are accessed here; all direct reads use canonical data.
