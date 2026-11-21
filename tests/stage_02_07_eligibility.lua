local KR={}
Enum={SpellBookSpellBank={Player=0}}
local spellKnownByApi=true
local spellKnownAvailable=true
local secretSpellId={}
local secretPolicy={}
local protectedCharges=false
local chargeMaximum=2
local chargeIsActive=false
local missingGcdField=false
local missingChargeCount=false
local missingChargeMax=false
local nilUsability=false
local nilRange=false
local protectedUsability=false
local playerLevel=40
local levelAvailable=true
local learned=true
local slot=true
local active=false
local gcdActive=false
local usable=true
local noPower=false
local chargeCount=1
local charging=true
local distance=true
local targetGUID="Creature-Target"
local guidReadCount=0
local switchTargetOnSecondRead=false
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
KR.GameState={GetSnapshot=function()return {player={exists=r(true),dead=r(dead),level=levelAvailable and r(playerLevel) or {status="UNKNOWN"}},target={exists=r(targetExists),guid=r(targetGUID),dead=r(false),attackable=r(attackable),assistable=r(true)}} end}
KR.EventBus={Subscribe=function() return true end}
KR.GameAPI={
 IsSafeValue=function(_,value)
  return not rawequal(value,secretSpellId) and not rawequal(value,secretPolicy)
 end,
 Probe=function(_,name)
  if name=="C_SpellBook.IsSpellKnown" and not spellKnownAvailable then
   return {status="UNAVAILABLE"}
  end
  return {status="READY"}
 end,
 ReadField=function(_,rec,key)
  if protected or (protectedCharges and key=="currentCharges") then return {status="UNKNOWN"} end
  return rec[key]~=nil and r(rec[key]) or {status="UNKNOWN"}
 end,
 Read=function(_,name,typ,...)
  local id=(...)
  if name=="GetTime" then return r(now) end
  if name=="UnitGUID" then
   guidReadCount=guidReadCount+1
   if switchTargetOnSecondRead and guidReadCount%2==0 then return r("Creature-Switched") end
   return r(targetGUID)
  end
  if name=="C_SpellBook.IsSpellKnown" then return r(spellKnownByApi) end
  if name=="C_Spell.GetSpellCooldown" then
   if id==61304 and missingGcdField then return r({isOnGCD=true}) end
   return r({isActive=id==61304 and gcdActive or active,isOnGCD=false})
  end
  if name=="C_Spell.GetSpellCharges" then
   local chargeInfo={isActive=chargeIsActive}
   if not missingChargeCount then chargeInfo.currentCharges=chargeCount end
   if not missingChargeMax then chargeInfo.maxCharges=chargeMaximum end
   return r(chargeInfo)
  end
  if name=="C_Spell.IsSpellInRange" then
   return nilRange and {status="UNKNOWN"} or r(distance)
  end
  return {status="UNKNOWN"}
 end,
 ReadValues=function(_,name,...)
  if name=="C_Spell.IsSpellUsable" then
   if nilUsability then return {status="UNKNOWN"} end
   if protectedUsability then return {status="UNKNOWN",reason="protected_value"} end
   return {status="READY",value={usable,noPower}}
  end
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
learned=false
spellKnownByApi=false;eq(eval().reason,"not_learned","known API negative")
spellKnownByApi=true;eq(eval().status,"READY","talent granted known spell")
spellKnownAvailable=false;eq(eval().status,"UNKNOWN","known API absent")
eq(eval().reason,"spell_known_unverified","no false unlearned")
spellKnownAvailable=true;learned=true
local secretResult=KR.AbilityEligibility:Evaluate(secretSpellId,targetPolicy)
eq(secretResult.reason,"invalid_spell_id","secret ID rejected before math.floor")
eq(secretResult.spellID,nil,"secret ID must never escape through result")
eq(KR.AbilityEligibility:Evaluate(101,secretPolicy).reason,
   "options_protected","secret options rejected before indexing")
eq(KR.AbilityEligibility:Evaluate(101,{
 target=secretPolicy,cast="idle",chargesRequired=true}).reason,
 "policy_protected","secret target policy rejected before comparison")
eq(KR.AbilityEligibility:Evaluate(101,{
 target="enemy",cast="idle",chargesRequired=true,minLevel=secretPolicy}).reason,
 "policy_protected","secret level policy rejected before math")
slot=false;eq(eval().status,"UNKNOWN","slot");slot=true
noPower=true;eq(eval().reason,"insufficient_resources");noPower=false
usable=false;eq(eval().reason,"spell_unusable");usable=true
chargeCount=0;eq(eval().reason,"no_charges");chargeCount=1
protectedCharges=true;eq(eval().status,"UNKNOWN","secret charge remains unknown")
eq(eval().reason,"charges_invalid","secret charge cannot be treated as zero")
protectedCharges=false
-- v14 #26: recharge activity cannot synthesize protected/absent count.
chargeIsActive=true
chargeCount=0;eq(eval().reason,"no_charges","zero remains blocked during recharge")
chargeCount=1;eq(eval().status,"READY","recharge while count is banked")
missingChargeCount=true;eq(eval().status,"UNKNOWN","missing currentCharges")
missingChargeCount=false
missingChargeMax=true;eq(eval().status,"UNKNOWN","missing maxCharges")
missingChargeMax=false
chargeCount=2.5;eq(eval().reason,"charges_invalid","fractional currentCharges")
chargeCount=3;eq(eval().reason,"charges_invalid","current exceeds max")
chargeCount=-1;eq(eval().reason,"charges_invalid","negative currentCharges")
chargeCount=1
chargeMaximum=0;eq(eval().reason,"charges_invalid","zero maxCharges")
chargeMaximum=2
chargeIsActive=false
nilUsability=true;eq(eval().status,"UNKNOWN","nil usability remains unknown")
nilUsability=false
protectedUsability=true;eq(eval().status,"UNKNOWN","secret usability remains unknown")
protectedUsability=false
nilRange=true;eq(eval().status,"UNKNOWN","nil range remains unknown")
eq(eval().reason,"range_unavailable","nil range never means in range")
nilRange=false
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
-- v14 #25: secret/missing GCD isActive must not become ready,
-- even when isOnGCD=true or timing fields are present.
missingGcdField=true
eq(eval().status,"UNKNOWN","GCD missing isActive")
eq(eval().reason,"gcd_activity_unknown","GCD incomplete table")
missingGcdField=false
distance=false;eq(eval().reason,"out_of_range");distance=true
targetExists=false;eq(eval().reason,"target_missing");targetExists=true
attackable=false;eq(eval().reason,"target_relation_invalid");attackable=true
casting="Frostbolt";eq(eval().reason,"already_casting");casting=nil
protected=true;eq(eval().status,"UNKNOWN","protected");protected=false
eq(eval({target="self",cast="allow",chargesRequired=false}).status,"READY","self buff")
local leveled={target="enemy",cast="idle",chargesRequired=true,minLevel=40}
eq(eval(leveled).status,"READY","minimum level exactly reached")
leveled.minLevel=41
eq(eval(leveled).reason,"player_level_too_low","minimum level not reached")
levelAvailable=false
eq(eval(leveled).reason,"player_level_unknown","unknown level not enough")
levelAvailable=true
leveled.minLevel=40
playerLevel=40.5
eq(eval(leveled).reason,"player_level_unknown","noninteger player level")
playerLevel=40
leveled.minLevel=40.5
eq(eval(leveled).reason,"level_policy_invalid","noninteger required level")
leveled.minLevel=101
eq(eval(leveled).reason,"level_policy_invalid","minimum level out of bounds")
leveled.minLevel=0
eq(eval(leveled).reason,"level_policy_invalid","minimum level zero")
leveled.minLevel=40
eq(eval(leveled).status,"READY","level rule again passes")
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
-- Contract v1 Fact: typed, fail-closed observations, not final spell readiness.
local function fact(kind,id)
 return KR.AbilityEligibility:Fact(id or 101,kind,{stateSnapshot=KR.GameState:GetSnapshot()})
end
eq(fact("cooldownActive").status,"READY","cooldown fact readable")
eq(fact("cooldownActive").value,false,"cooldown fact inactive")
active=true
eq(fact("cooldownActive").value,true,"cooldown fact active")
active=false
missingGcdField=false
local oldReadFact=KR.GameAPI.Read
KR.GameAPI.Read=function(self,name,typ,...)
 if name=="C_Spell.GetSpellCooldown" and (...)==101 then
  return r({isOnGCD=true})
 end
 return oldReadFact(self,name,typ,...)
end
eq(fact("cooldownActive").status,"UNKNOWN","missing active field not guessed from GCD")
KR.GameAPI.Read=oldReadFact
distance=false
eq(fact("inRange").value,false,"range false retained")
distance=true
eq(fact("inRange").value,true,"range true retained")
nilRange=true
eq(fact("inRange").status,"UNKNOWN","nil range not inferred")
nilRange=false
local rangeBefore=guidReadCount
targetExists=false
eq(fact("inRange").status,"UNKNOWN","absent target cannot yield range")
eq(guidReadCount,rangeBefore,"absent target does not read GUID")
targetExists=true
local oldGUID=targetGUID
targetGUID="Creature-Other"
local oldSnapshot=KR.GameState.GetSnapshot
KR.GameState.GetSnapshot=function()
 local record=oldSnapshot()
 record.target.guid=r(oldGUID)
 return record
end
eq(fact("inRange").status,"UNKNOWN","stale range target GUID")
KR.GameState.GetSnapshot=oldSnapshot
targetGUID=oldGUID
switchTargetOnSecondRead=true
guidReadCount=0
eq(fact("inRange").status,"UNKNOWN","target switched mid-range read")
switchTargetOnSecondRead=false
guidReadCount=0
protected=true
eq(fact("cooldownActive").status,"UNKNOWN","protected cooldown field unknown")
protected=false
eq(fact("known").status,"READY","known fact from confirmed catalogue")
eq(fact("known").value,true,"known catalogue affirmative")
learned=false
spellKnownByApi=false
eq(fact("known").status,"READY","explicit SpellBook negative is a known fact")
eq(fact("known").value,false,"explicit unlearned remains false")
spellKnownByApi=true
eq(fact("known").value,true,"SpellBook positive covers absent catalogue entry")
spellKnownAvailable=false
eq(fact("known").status,"UNKNOWN","catalogue absence plus missing API is unknown")
spellKnownAvailable=true
local previousCatalogue=KR.SpellCatalogue.Read
KR.SpellCatalogue.Read=function() return {status="UNAVAILABLE"} end
eq(fact("known").status,"UNKNOWN","unavailable catalogue never implies unknown spell")
KR.SpellCatalogue.Read=function() error("spellbook failure") end
eq(fact("known").status,"UNKNOWN","catalogue exception fails closed")
KR.SpellCatalogue.Read=function() return {status="ready",entries={false}} end
eq(fact("known").status,"UNKNOWN","malformed catalogue entry fails closed")
KR.SpellCatalogue.Read=previousCatalogue
learned=true
eq(fact("chargesAtLeast").status,"UNKNOWN","charges threshold missing")
eq(fact("notSupported").status,"UNKNOWN","invalid fact kind closed")
eq(KR.AbilityEligibility:Fact(secretSpellId,"inRange").status,
 "UNKNOWN","secret spellID rejected")
eq(KR.AbilityEligibility:Initialize(),true,"initialization")
print("PASS stage 2.7 eligibility mock: "..count.." checks")
