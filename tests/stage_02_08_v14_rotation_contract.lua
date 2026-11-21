-- 2.8.4d: integration of real RotationProfiles + RotationEngine + AbilityEligibility.
-- WoW API functions are mocks; this is NOT an in-game test.
local KR={characterState={classToken="WARRIOR",index=1}}
local reads=0
local groupKnown=true
local inGroup=false
local brokenState=false
local cooldownFirst=false
local unknownFirst=false
local gcdActive=false
local targetExists=true
local usability=true
local function r(value) return {status="READY",value=value} end
KR.GameState={GetSnapshot=function()
 reads=reads+1
 if brokenState then error("snapshot failure") end
 return {player={exists=r(true),dead=r(false),level=r(60)},
  target={exists=r(targetExists),dead=r(false),attackable=r(true),assistable=r(true)},
  context={inGroup=groupKnown and r(inGroup) or {status="UNKNOWN"}}}
end}
KR.SpellCatalogue={Read=function()return {status="ready",entries={
 {id=101,known=true,name="First",texture=101},
 {id=102,known=true,name="Second",texture=102}}}end}
KR.ActionBarScanner={FindSpell=function(_,id)return {status="READY",slot=id}end}
KR.GameAPI={
 IsSafeValue=function()return true end,
 Probe=function()return {status="READY"}end,
 ReadField=function(_,record,key)
  if record[key]==nil then return {status="UNKNOWN"} end
  return r(record[key])
 end,
 Read=function(_,name,_,id)
  if name=="C_Spell.GetSpellCooldown" then
   if id==101 and unknownFirst then return r({}) end
   return r({isActive=id==61304 and gcdActive or (id==101 and cooldownFirst or false)})
  end
  if name=="C_Spell.IsSpellInRange" then return r(true) end
  return {status="UNKNOWN"}
 end,
 ReadValues=function(_,name)
  if name=="C_Spell.IsSpellUsable" then return {status="READY",value={usability,false}} end
  if name=="UnitCastingInfo" or name=="UnitChannelInfo" then
   return {status="READY",value={}}
  end
  return {status="UNKNOWN"}
 end
}
KR.RotationSettings={GetProfile=function()
 return {enabled=true,targetMode="single",categories={damage=true},spells={}},"WARRIOR_TREE_1"
end}
KR.BindingResolver={Resolve=function()return {status="READY",bindingLabel="1",bindingSource="mock"}end}
assert(loadfile("KordRotation/Core/AbilityEligibility.lua"))("KordRotation",KR)
assert(loadfile("KordRotation/Core/RotationProfiles.lua"))("KordRotation",KR)
assert(loadfile("KordRotation/Core/RotationEngine.lua"))("KordRotation",KR)
local function rule(id)
 return {spellID=id,category="damage",target="enemy",cast="allow",chargesRequired=false}
end
local first=rule(101)
first.requires={{field="context.inGroup",equals=false}}
assert(KR.RotationProfiles:Register("WARRIOR",1,{verified=true,single={first,rule(102)},aoe={}}))
local n=0
local function eq(got,want,label)
 n=n+1
 assert(got==want,(label or "assert")..": expected "..tostring(want)..", got "..tostring(got))
end
local E=KR.RotationEngine
local function evaluate()
 local before=reads
 local result=E:Evaluate()
 eq(reads,before+1,"single GameState read")
 return result
end
local state=evaluate()
eq(state.status,"READY","first READY")
eq(state.queue[1].spellID,101,"first priority selected")
eq(state.queue[1].keybind,"1","binding retained")
eq(#state.queue,1,"one recommendation")
cooldownFirst=true
state=evaluate()
eq(state.status,"READY","blocked first skips to next")
eq(state.queue[1].spellID,102,"second selected")
unknownFirst=true
state=evaluate()
eq(state.status,"UNKNOWN","uncertain first blocks lower priority")
eq(#state.queue,0,"empty on unknown")
unknownFirst=false
cooldownFirst=false
groupKnown=false
state=evaluate()
eq(state.status,"UNKNOWN","unknown required context blocks first")
eq(#state.queue,0,"required context prevents fallback")
groupKnown=true
inGroup=true
state=evaluate()
eq(state.status,"READY","proven mismatch skips to second")
eq(state.queue[1].spellID,102,"mismatch fallback")
inGroup=false
gcdActive=true
state=evaluate()
eq(state.status,"BLOCKED","gcd blocks all candidates")
eq(#state.queue,0,"gcd queue empty")
gcdActive=false
targetExists=false
state=evaluate()
eq(state.status,"BLOCKED","no target blocks enemy rules")
targetExists=true
usability=false
state=evaluate()
eq(state.status,"BLOCKED","spell unusable blocks all")
usability=true
brokenState=true
local before=reads
state=E:Evaluate()
eq(reads,before+1,"failed snapshot tried once")
eq(state.reason,"game_state_unavailable","snapshot exception fail closed")
eq(#state.queue,0,"exception no queue")
brokenState=false
KR.characterState.index=2
state=E:Evaluate()
eq(state.reason,"profile_not_registered","no cross-spec fallback")
print("PASS 2.8.4d integration mock: "..n.." assertions")
