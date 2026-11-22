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
