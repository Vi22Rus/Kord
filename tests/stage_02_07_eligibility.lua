local KR={}
local learned=true
local slot=true
local active=false
local gcdActive=false
local usable=true
local noPower=false
local chargeCount=1
local charging=true
local distance=true
local dead=false
local targetExists=true
local attackable=true
local casting=nil
local protected=false
local now=100
local targetPolicy={target="enemy",cast="idle",chargesRequired=true}
local function r(value) return {status="READY",value=value} end
KR.SpellCatalogue={Read=function() return {status="ready",entries= learned and {{id=101,known=true}} or {{id=102,known=true}}} end}
KR.ActionBarScanner={FindSpell=function() return slot and {status="READY",slot=1} or {status="UNKNOWN"} end}
KR.GameState={GetSnapshot=function()return {player={exists=r(true),dead=r(dead)},target={exists=r(targetExists),dead=r(false),attackable=r(attackable),assistable=r(true)}} end}
KR.EventBus={Subscribe=function() return true end}
KR.GameAPI={
 Probe=function(_,name) return {status="READY"} end,
 ReadField=function(_,rec,key) if protected then return {status="UNKNOWN"} end return rec[key]~=nil and r(rec[key]) or {status="UNKNOWN"} end,
 Read=function(_,name,typ,...)
  local id=(...)
  if name=="GetTime" then return r(now) end
  if name=="C_Spell.GetSpellCooldown" then return r({isActive=id==61304 and gcdActive or active,isOnGCD=false}) end
  if name=="C_Spell.GetSpellCharges" then return r({currentCharges=chargeCount,maxCharges=2}) end
  if name=="C_Spell.IsSpellInRange" then return r(distance) end
  return {status="UNKNOWN"}
 end,
 ReadValues=function(_,name,...)
  if name=="C_Spell.IsSpellUsable" then return {status="READY",value={usable,noPower}} end
  if name=="UnitCastingInfo" then return {status="READY",value={casting}} end
  if name=="UnitChannelInfo" then return {status="READY",value={}} end
  return {status="UNKNOWN"}
 end,
}
assert(loadfile("KordRotation/Core/AbilityEligibility.lua"))("KordRotation",KR)
local count=0
local function eq(got,want,msg)
 count=count+1
 assert(got==want,(msg or "case").." got "..tostring(got).." expected "..tostring(want))
end
local function eval(opts) return KR.AbilityEligibility:Evaluate(101,opts or targetPolicy) end
eq(eval().status,"READY","available")
learned=false;eq(eval().reason,"not_learned");learned=true
slot=false;eq(eval().status,"UNKNOWN","slot");slot=true
noPower=true;eq(eval().reason,"insufficient_resources");noPower=false
usable=false;eq(eval().reason,"spell_unusable");usable=true
chargeCount=0;eq(eval().reason,"no_charges");chargeCount=1
active=true;eq(eval().reason,"cooldown_active_unclassified");active=false
-- v14 #83: even with isOnGCD=true, snapshot polling must not turn
-- an active cooldown into a READY recommendation.
local previousRead=KR.GameAPI.Read
KR.GameAPI.Read=function(self,name,typ,...)
 if name=="C_Spell.GetSpellCooldown" and (...)==101 then
  return r({isActive=true,isOnGCD=true})
 end
 return previousRead(self,name,typ,...)
end
eq(eval().status,"BLOCKED","isOnGCD not authoritative outside event")
eq(eval().reason,"cooldown_active_unclassified","active cannot be categorized")
KR.GameAPI.Read=previousRead
gcdActive=true;eq(eval().reason,"global_cooldown");gcdActive=false
distance=false;eq(eval().reason,"out_of_range");distance=true
targetExists=false;eq(eval().reason,"target_missing");targetExists=true
attackable=false;eq(eval().reason,"target_relation_invalid");attackable=true
casting="Frostbolt";eq(eval().reason,"already_casting");casting=nil
protected=true;eq(eval().status,"UNKNOWN","protected");protected=false
eq(eval({target="self",cast="allow",chargesRequired=false}).status,"READY","self buff")
eq(eval({target="none",cast="idle",chargesRequired=false}).status,"READY","no target")
eq(eval({target="enemy"}).status,"UNKNOWN","missing cast policy")
eq(eval({cast="idle"}).status,"UNKNOWN","missing target policy")
eq(eval({target="self",cast="allow"}).reason,"charge_policy_required","missing charge policy")
eq(KR.AbilityEligibility:Evaluate(0,targetPolicy).status,"UNKNOWN","invalid ID")
-- Confirmed player death blocks, not merely UNKNOWN.
dead=true;eq(eval().reason,"player_dead","dead player");dead=false
-- Explicit friend policy is checked separately from attackability.
attackable=false;eq(eval({target="friendly",cast="idle",chargesRequired=false}).status,"READY","friendly spell")
attackable=true
-- Modern API absent: legacy cooldown, usability, charges and range are used.
local oldProbe=KR.GameAPI.Probe
KR.GameAPI.Probe=function(_,name)
 if string.sub(name,1,8)=="C_Spell." then return {status="UNAVAILABLE"} end
 return {status="READY"}
end
local oldMulti=KR.GameAPI.ReadValues
KR.GameAPI.ReadValues=function(self,name,...)
 if name=="GetSpellCooldown" then return {status="READY",value={0,0,1}} end
 if name=="GetSpellCharges" then return {status="READY",value={1,2}} end
 if name=="IsUsableSpell" then return {status="READY",value={true,false}} end
 if name=="IsSpellInRange" then return {status="READY",value={1}} end
 return oldMulti(self,name,...)
end
eq(eval().status,"READY","legacy APIs")
KR.GameAPI.ReadValues=oldMulti;KR.GameAPI.Probe=oldProbe
eq(KR.AbilityEligibility:Initialize(),true,"initialization")
print("PASS stage 2.7 eligibility mock: "..count.." checks")
