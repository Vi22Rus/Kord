-- IT-01/1.7: per-evaluation inventory facts and transparent UNKNOWN.
-- Execute from repository root in Lua 5.1; no WoW client API required.
local calls={item=0,family=0}
local answers={item=2,family=3}
local KR={
 GameAPI={IsSafeValue=function(_,x) return x~=nil end},
 GameState={
  ReadInventoryItemObservation=function(_,id)
   calls.item=calls.item+1
   if answers.item=="unknown" then
    return {status="UNKNOWN",reason="item_count_secret"}
   end
   return {status="READY",itemID=id,inventoryScope="BAGS_ONLY",
       count=answers.item}
  end,
  ReadInventoryFamilyObservation=function(_,id)
   calls.family=calls.family+1
   if answers.family=="unknown" then
    return {status="UNKNOWN",reason="item_family_partial"}
   end
   return {status="READY",familyID=id,inventoryScope="BAGS_ONLY",
       count=answers.family}
  end
 }
}
assert(loadfile("KordRotation/Core/RotationConditions.lua"))("KordRotation",KR)
local C=KR.RotationConditions
local profile={Needs={items={ids={5512},families={"HEALTHSTONE"}}},Spells={}}
local S=C:Create(profile,{})
assert(S.items:count(5512)==2)
assert(S.items:count(5512)==2 and calls.item==1)
assert(S:observe("items.count",5512)==2 and calls.item==1)
assert(S.items:hasAny("HEALTHSTONE")==true)
assert(S.items:familyCount("HEALTHSTONE")==3 and calls.family==2)
assert(S.items:count(9999)==nil and calls.item==1)
assert(S.items:hasAny("UNDECLARED")==nil and calls.family==2)
-- One evaluation memo is shared across both conditions windows.
answers.item=0
assert(S.items:count(5512)==2)
local B=C:Create(profile,{})
assert(B.items:count(5512)==0 and calls.item==2)
answers.item="unknown"
local U=C:Create(profile,{})
assert(U.items:count(5512)==nil)
assert(U.items:count(5512)==nil and calls.item==3)
answers.family=0
local Z=C:Create(profile,{})
assert(Z.items:hasAny("HEALTHSTONE")==false)
answers.family="unknown"
local P=C:Create(profile,{})
assert(P.items:hasAny("HEALTHSTONE")==nil)
-- No bank/equipped or invented readiness is inferred from numeric count.
answers.item=2
KR.GameState.ReadInventoryItemObservation=function(_,id)
 calls.item=calls.item+1
 return {status="READY",itemID=id,inventoryScope="BANK",count=9}
end
assert(C:Create(profile,{}).items:count(5512)==nil)
print("inventory_conditions_mock PASS")
