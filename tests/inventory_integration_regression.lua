-- IT-01/1.10: item/family/event integration at the shared contract.
-- Lua 5.1 mock only. No WoW client, no item use or protected commands.
local KR={}
local counts={[5512]=2,[5511]=3,[19004]=1}
local requested={}
local raceID=nil
local unavailableID=nil
KR.GameAPI={
 IsSafeValue=function(_,value) return value~="SECRET" end,
 Read=function(_,method,kind,itemID,includeBank,includeUses)
    assert(method=="C_Item.GetItemCount" and kind=="number")
    assert(includeBank==false and includeUses==false)
    requested[#requested+1]=itemID
    if raceID==itemID then KR.EventBus:HandleEvent("BAG_UPDATE",1) end
    if unavailableID==itemID then
        return {status="UNKNOWN",reason="protected_value"}
    end
    return {status="READY",value=counts[itemID] or 0,source=method}
 end
}
assert(loadfile("KordRotation/Core/EventBus.lua"))("KordRotation",KR)
assert(loadfile("KordRotation/Core/ItemFamilyCatalog.lua"))("KordRotation",KR)
assert(loadfile("KordRotation/Core/GameState.lua"))("KordRotation",KR)
local E,S,C=KR.EventBus,KR.GameState,KR.ItemFamilyCatalog
assert(C:ReplaceFamily("IT01_INTEGRATION",{5512,5511,5512}).status=="READY")
local zero=S:ReadInventoryItemObservation(19005)
assert(zero.status=="READY" and zero.count==0)
assert(zero.inventoryScope=="BAGS_ONLY" and zero.bagRevision==0)
assert(S:ReadInventoryItemObservation("SECRET").status=="UNKNOWN")
assert(#requested==1)
local item=S:ReadInventoryItemObservation(5512)
assert(item.status=="READY" and item.count==2)
local family=S:ReadInventoryFamilyObservation("IT01_INTEGRATION")
assert(family.status=="READY" and family.count==5)
assert(family.knownComponents==2 and #family.knownItemIDs==2)
assert(family.bagRevision==E:GetInventoryRevision())
unavailableID=5511
local partial=S:ReadInventoryFamilyObservation("IT01_INTEGRATION")
assert(partial.status=="UNKNOWN" and partial.reason=="item_family_partial")
assert(partial.knownMinimum==2 and partial.count==nil)
unavailableID=nil
raceID=5512
local unstable=S:ReadInventoryItemObservation(5512)
assert(unstable.status=="UNKNOWN" and unstable.reason=="item_bag_revision_changed")
local familyRace=S:ReadInventoryFamilyObservation("IT01_INTEGRATION")
assert(familyRace.status=="UNKNOWN")
assert(familyRace.reason=="item_bag_revision_changed")
assert(familyRace.count==nil and familyRace.knownMinimum==nil)
raceID=nil
local previous=E:GetInventoryRevision()
assert(E:RequestInventoryRefresh("explicit_soulwell_recheck")==previous+1)
local refreshed=S:ReadInventoryFamilyObservation("IT01_INTEGRATION")
assert(refreshed.status=="READY" and refreshed.count==5)
assert(refreshed.bagRevision==previous+1)
-- A second family may reuse IDs but must not multiply within a family.
assert(C:ReplaceFamily("IT01_OVERLAP",{5512,19004}).status=="READY")
assert(S:ReadInventoryFamilyObservation("IT01_OVERLAP").count==3)
-- The tests do not infer usability, cooldown or shared potion locks.
assert(KR.GameState.ReadItemCooldownObservation==nil)
assert(KR.GameState.ReadItemUsabilityObservation==nil)
print("inventory_integration_regression PASS")
