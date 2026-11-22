-- IT-02/2.8: lazy cooldown facts, strict Needs and UNKNOWN fail-closed.
local calls={item=0,shared=0}
local mode="active"
local KR={
 GameAPI={IsSafeValue=function(_,x) return x~="SECRET" end},
 GameState={
  ReadItemCooldownObservation=function(_,id)
   calls.item=calls.item+1
   if mode=="fail" then error("simulated") end
   if mode=="unknown" then return {status="UNKNOWN",reason="item_cd_secret"} end
   if mode=="wrong" then id=900 end
   if mode=="scope" then
    return {status="READY",itemID=id,cooldownScope="GCD",active=false,remaining=0}
   end
   if mode=="secret" then
    return {status="READY",itemID=id,cooldownScope="ITEM_SPECIFIC",
       active="SECRET",remaining=0}
   end
   local active=mode~="idle"
   return {status="READY",itemID=id,cooldownScope="ITEM_SPECIFIC",
       active=active,remaining=active and 12 or 0}
  end,
  ReadSharedItemCooldownObservation=function(_,id)
   calls.shared=calls.shared+1
   if mode=="confirmed" then
    return {status="READY",groupID=id,groupStatus="CONFIRMED_ACTIVE",
       remaining=15}
   end
   if mode=="conflict" then
    return {status="READY",groupID=id,groupStatus="CONFIRMED_READY",
       remaining=12}
   end
   return {status="UNKNOWN",groupID=id,groupStatus="UNKNOWN",
      reason="item_cd_group_partial"}
  end,
 }
}
assert(loadfile("KordRotation/Core/RotationConditions.lua"))("KordRotation",KR)
local C=KR.RotationConditions
local profile={Needs={items={ids={118},families={"HEALTH_POTION"},
    cooldown=true,cooldownGroups={"POTION_SHARED"}}},Spells={}}
local S=C:Create(profile,{})
assert(calls.item==0 and calls.shared==0)
assert(S.items:cooldownActive(118)==true)
assert(S.items:cooldownActive(118)==true and calls.item==1)
assert(S:observe("items.cooldownActive",118)==true and calls.item==1)
assert(S.items:cooldownRemaining(118)==12 and calls.item==1)
assert(S.items:cooldownRemaining(118)==12 and calls.item==1)
assert(S.items:cooldownActive(999)==nil and calls.item==1)
assert(S.items:sharedCooldownRemaining("UNDECLARED")==nil and calls.shared==0)
assert(S.items:sharedCooldownRemaining("POTION_SHARED")==nil)
assert(S.items:sharedCooldownRemaining("POTION_SHARED")==nil and calls.shared==1)
mode="idle"
assert(S.items:cooldownActive(118)==true)
assert(S.items:cooldownRemaining(118)==12) -- same evaluation is immutable
local I=C:Create(profile,{})
assert(I.items:cooldownActive(118)==false)
assert(I.items:cooldownRemaining(118)==0)
mode="confirmed"
assert(C:Create(profile,{}).items:sharedCooldownRemaining("POTION_SHARED")==15)
mode="conflict"
assert(C:Create(profile,{}).items:sharedCooldownRemaining("POTION_SHARED")==nil)
for _,variant in ipairs({"unknown","wrong","scope","secret","fail"}) do
 mode=variant
 assert(C:Create(profile,{}).items:cooldownActive(118)==nil,variant)
end
local noPermission={Needs={items={ids={118},cooldown=false,
 cooldownGroups={}}},Spells={}}
local N=C:Create(noPermission,{})
local before=calls.item
assert(N.items:cooldownActive(118)==nil and calls.item==before)
assert(N.items:cooldownRemaining(118)==nil and calls.item==before)
print("item_cooldown_conditions_mock PASS")
