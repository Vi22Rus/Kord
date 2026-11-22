-- PLAN IT-01 / 1.1: fail-closed contract smoke test for Lua 5.1.
-- Does not probe or emulate WoW inventory APIs. Tests observation only.
local KR = {GameAPI={IsSafeValue=function(_,value)
    return type(value)=="number" or type(value)=="string"
end}}
assert(loadfile("KordRotation/Core/GameState.lua"))("KordRotation",KR)
local S=KR.GameState
local inv=S:ReadInventoryObservation()
assert(inv.status=="UNKNOWN" and inv.scope=="BAGS_ONLY")
assert(inv.inventoryScope=="BAGS_ONLY")
assert(inv.source=="GameState.InventoryObservation")
assert(inv.reason=="inventory_reader_unverified")
assert(inv.revision==nil and inv.bagRevision==nil and inv.catalogRevision==nil)
assert(inv.count==nil and inv.observedAt==nil)
assert(next(inv.items)==nil and next(inv.families)==nil)

local item=S:ReadInventoryItemObservation(5512)
local family=S:ReadInventoryFamilyObservation("HEALTHSTONE")
for _,record in ipairs({item,family}) do
    assert(record.status=="UNKNOWN")
    assert(record.scope=="BAGS_ONLY" and record.inventoryScope=="BAGS_ONLY")
    assert(record.count==nil and record.revision==nil)
    assert(record.bagRevision==nil and record.catalogRevision==nil)
end
assert(item.itemID==5512 and item.source=="GameState.InventoryItemObservation")
assert(family.familyID=="HEALTHSTONE")
assert(family.source=="GameState.InventoryFamilyObservation")
assert(item.knownItemIDs==nil and family.countsByID==nil)
for _,id in ipairs({0,-1,1.5,math.huge}) do
    local r=S:ReadInventoryItemObservation(id)
    assert(r.status=="UNKNOWN" and r.itemID==nil)
    assert(r.reason=="item_id_unverified")
end
assert(S:ReadInventoryItemObservation(nil).reason=="item_id_unverified")
assert(S:ReadInventoryFamilyObservation("").reason=="item_family_id_unverified")
assert(S:ReadInventoryFamilyObservation(nil).status=="UNKNOWN")
-- No cross-call mutable aliasing: caller modifications cannot create fake
-- cached READY for a second read.
inv.status="READY"
inv.items[5512]={count=1}
assert(S:ReadInventoryObservation().status=="UNKNOWN")
assert(S:ReadInventoryObservation().items[5512]==nil)
print("inventory_observation_contract PASS")

-- IT-01/1.2 mock tests (not evidence of compatibility with Forever).
assert(loadfile("KordRotation/Core/GameAPI.lua"))("KordRotation",KR)
local savedItem,savedSecret=_G.C_Item,_G.issecretvalue
local calls=0
_G.C_Item={GetItemCount=function(id,bank,uses)
    calls=calls+1
    assert(id==5512 and bank==false and uses==false)
    return 4
end}
local found=S:ReadInventoryItemObservation(5512)
assert(found.status=="READY" and found.count==4 and found.scope=="BAGS_ONLY")
assert(found.itemID==5512 and calls==1 and found.apiSource=="C_Item.GetItemCount")
_G.C_Item.GetItemCount=function() return 0 end
assert(S:ReadInventoryItemObservation(5512).count==0)
_G.C_Item.GetItemCount=function() return nil end
local missingValue=S:ReadInventoryItemObservation(5512)
assert(missingValue.status=="UNKNOWN" and missingValue.count==nil and missingValue.reason=="no_value")
_G.C_Item.GetItemCount=function() error("mock") end
assert(S:ReadInventoryItemObservation(5512).reason=="api_call_failed")
for _,invalidValue in ipairs({-1,0.5,math.huge,true,"4"}) do
    _G.C_Item.GetItemCount=function() return invalidValue end
    local r=S:ReadInventoryItemObservation(5512)
    assert(r.status=="UNKNOWN" and r.count==nil)
end
_G.C_Item=nil
local legacy=_G.GetItemCount
_G.GetItemCount=function() error("legacy API is forbidden here") end
local unavailable=S:ReadInventoryItemObservation(5512)
assert(unavailable.status=="UNKNOWN" and unavailable.count==nil and unavailable.reason=="api_missing")
_G.GetItemCount=legacy
_G.C_Item={GetItemCount=function() return 7 end}
_G.issecretvalue=function(v) return v==7 end
local protected=S:ReadInventoryItemObservation(5512)
assert(protected.status=="UNKNOWN" and protected.count==nil and protected.reason=="item_count_secret")
_G.issecretvalue=savedSecret
_G.C_Item=savedItem
print("inventory_item_count_api_mock PASS")
