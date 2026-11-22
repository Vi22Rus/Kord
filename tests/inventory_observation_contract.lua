-- PLAN IT-01 / step 1.1: contract smoke test (Lua 5.1).
-- No WoW calls and no bag scan are permitted by the initial model.
local KR = {GameAPI={IsSafeValue=function(_,value)
    return type(value)=="number" or type(value)=="string"
end}}
assert(loadfile("KordRotation/Core/GameState.lua"))("KordRotation",KR)
local S=KR.GameState
local inventory=S:ReadInventoryObservation()
assert(inventory.status=="UNKNOWN")
assert(inventory.scope=="BAGS_ONLY")
assert(inventory.revision==nil)
assert(inventory.items and next(inventory.items)==nil)
assert(inventory.families and next(inventory.families)==nil)
local item=S:ReadInventoryItemObservation(5512)
assert(item.status=="UNKNOWN" and item.itemID==5512)
assert(item.revision==nil and item.count==nil)
local bad=S:ReadInventoryItemObservation(nil)
assert(bad.status=="UNKNOWN" and bad.itemID==nil)
local family=S:ReadInventoryFamilyObservation("HEALTHSTONE")
assert(family.status=="UNKNOWN" and family.familyID=="HEALTHSTONE")
assert(family.count==nil and family.revision==nil)
print("inventory_observation_contract PASS")
