-- IT-02/2.10: end-to-end mock from event revision to profile conditions.
-- No game client or protected item use APIs are exercised.
local now=100
local mode="active"
local callCount=0
local KR={}
KR.GameAPI={
 IsSafeValue=function(_,v) return v~="SECRET" end,
 ReadValues=function(_,name,id)
  callCount=callCount+1
  assert(name=="C_Item.GetItemCooldown" and id==118)
  if mode=="missing" then return {status="UNKNOWN",reason="protected_value"} end
  if mode=="disabled" then return {status="READY",value={90,30,false}} end
  if mode=="revision_race" then
   KR.EventBus:InvalidateItemCooldown("race_during_read")
  end
  return {status="READY",value={90,30,1}}
 end,
 Read=function(_,name,kind)
  assert(name=="GetTime" and kind=="number")
  return {status="READY",value=now}
 end,
 ReadField=function(_,obj,key)
  if obj[key]==nil then return {status="UNKNOWN"} end
  return {status="READY",value=obj[key]}
 end
}
assert(loadfile("KordRotation/Core/EventBus.lua"))("KordRotation",KR)
assert(loadfile("KordRotation/Core/ItemFamilyCatalog.lua"))("KordRotation",KR)
assert(loadfile("KordRotation/Core/SharedCooldownGroupCatalog.lua"))("KordRotation",KR)
assert(loadfile("KordRotation/Core/GameState.lua"))("KordRotation",KR)
assert(loadfile("KordRotation/Core/RotationConditions.lua"))("KordRotation",KR)
local C=KR.RotationConditions
local profile={Spells={},Needs={items={
 ids={118},families={"HEALTH_POTION"},
 cooldown=true,cooldownGroups={"POTION_SHARED"}
}}}
local S=C:Create(profile,{})
assert(callCount==0)
assert(S.items:cooldownActive(118)==true)
assert(S.items:cooldownRemaining(118)==20)
assert(S.items:sharedCooldownRemaining("POTION_SHARED")==nil)
assert(S.items:cooldownActive(118)==true)
assert(callCount==1) -- active/remaining share one observation per evaluation
local first=KR.GameState:ReadItemCooldownObservation(118)
assert(first.status=="READY" and first.revision==0)
assert(first.gcdStatus=="UNKNOWN" and first.usabilityStatus=="UNKNOWN")
assert(first.cooldownScope=="ITEM_SPECIFIC")
-- Same bounded active observation is reused without a second cooldown API read.
assert(callCount==1)
local cached=KR.GameState:ReadItemCooldownObservation(118)
assert(cached~=first and cached.status=="READY" and cached.remaining==20)
assert(callCount==1)
now=100.05
local countingDown=KR.GameState:ReadItemCooldownObservation(118)
assert(countingDown.status=="READY"
    and math.abs(countingDown.remaining-19.95)<0.00001)
assert(callCount==1)
-- TTL expiry and bag revision changes both force a fresh observation.
now=100.20
assert(KR.GameState:ReadItemCooldownObservation(118).status=="READY")
assert(callCount==2)
KR.EventBus:InvalidateInventory(nil,"mock_bag_revision")
assert(KR.GameState:ReadItemCooldownObservation(118).status=="READY")
assert(callCount==3)
-- Family catalog revision is part of the key, not item-family group evidence.
local originalFamilyRevision=KR.ItemFamilyCatalog.GetRevision
KR.ItemFamilyCatalog.GetRevision=function(self)
    return originalFamilyRevision(self)+1
end
assert(KR.GameState:ReadItemCooldownObservation(118).status=="READY")
assert(callCount==4)
KR.ItemFamilyCatalog.GetRevision=originalFamilyRevision
assert(KR.EventBus:HandleEvent("BAG_UPDATE_COOLDOWN"))
assert(KR.EventBus:GetItemCooldownRevision()==1)
now=130
local nextEval=C:Create(profile,{})
assert(nextEval.items:cooldownActive(118)==false)
assert(nextEval.items:cooldownRemaining(118)==0)
assert(nextEval.items:sharedCooldownRemaining("POTION_SHARED")==nil)
mode="disabled"
assert(C:Create(profile,{}).items:cooldownActive(118)==nil)
mode="missing"
assert(C:Create(profile,{}).items:cooldownRemaining(118)==nil)
mode="revision_race"
local raced=KR.GameState:ReadItemCooldownObservation(118)
assert(raced.status=="UNKNOWN" and raced.reason=="item_cd_revision_changed")
assert(raced.active==nil and raced.remaining==nil)
assert(C:Create(profile,{}).items:cooldownActive(118)==nil)
-- Missing/broken revision provider must never become READY because
-- both pre-read and post-read revisions happen to evaluate to nil.
mode="active"
local originalBus=KR.EventBus
KR.EventBus=nil
local withoutBus=KR.GameState:ReadItemCooldownObservation(118)
assert(withoutBus.status=="UNKNOWN"
    and withoutBus.reason=="item_cd_revision_unavailable")
assert(withoutBus.active==nil and withoutBus.remaining==nil)
KR.EventBus={GetItemCooldownRevision=function() return "SECRET" end}
local secretRevision=KR.GameState:ReadItemCooldownObservation(118)
assert(secretRevision.status=="UNKNOWN"
    and secretRevision.reason=="item_cd_revision_unavailable")
KR.EventBus={GetItemCooldownRevision=function() error("simulated") end}
local failedRevision=KR.GameState:ReadItemCooldownObservation(118)
assert(failedRevision.status=="UNKNOWN"
    and failedRevision.reason=="item_cd_revision_unavailable")
-- Mid-read disappearance is also UNKNOWN rather than stale READY.
local reads=0
KR.EventBus={GetItemCooldownRevision=function()
    reads=reads+1
    if reads==1 then return 123 end
    return nil
end}
local vanishedRevision=KR.GameState:ReadItemCooldownObservation(118)
assert(vanishedRevision.status=="UNKNOWN"
    and vanishedRevision.reason=="item_cd_revision_unavailable")
assert(vanishedRevision.active==nil and vanishedRevision.remaining==nil)
KR.EventBus=originalBus
local afterRestore=KR.GameState:ReadItemCooldownObservation(118)
assert(afterRestore.status=="READY" and afterRestore.active==false)
local before=callCount
assert(C:Create(profile,{}).items:cooldownActive(999)==nil)
assert(callCount==before)
print("item_cooldown_integration_mock PASS")
