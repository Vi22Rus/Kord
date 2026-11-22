-- IT-01/1.3 on-demand bounded bag snapshot mocks (Lua 5.1).
-- No direct game commands and no assertion of actual Forever compatibility.
local KR={}
assert(loadfile("KordRotation/Core/GameAPI.lua"))("KordRotation",KR)
assert(loadfile("KordRotation/Core/GameState.lua"))("KordRotation",KR)
local S=KR.GameState
local originalContainer=_G.C_Container
local bagCalls={}
local slotsByBag={[0]=3,[1]=2,[2]=0,[3]=0,[4]=0}
local items={
    ["0:1"]={itemID=5512,stackCount=2},
    ["0:2"]={itemID=5512,stackCount=3},
    ["1:1"]={itemID=1710,stackCount=1},
}
local function slotKey(bag,slot) return tostring(bag)..":"..tostring(slot) end
local function reset()
    bagCalls={}
    _G.C_Container={
        GetContainerNumSlots=function(bag)
            assert(type(bag)=="number" and bag>=0 and bag<=4)
            bagCalls[#bagCalls+1]=bag
            return slotsByBag[bag]
        end,
        GetContainerItemID=function(bag,slot)
            local item=items[slotKey(bag,slot)]
            return item and item.itemID or nil
        end,
        GetContainerItemInfo=function(bag,slot)
            return items[slotKey(bag,slot)]
        end,
    }
end
reset()
local snap=S:ReadInventoryBagSnapshot()
assert(snap.status=="READY" and snap.complete==true)
assert(snap.inventoryScope=="BAGS_ONLY" and #snap.bagIDs==5)
assert(snap.countsByID[5512]==5 and snap.countsByID[1710]==1)
assert(snap.visitedSlots==5 and #bagCalls==5)
assert(snap.countsByID[1]==nil)
-- No scan outside explicitly enumerated 0..4 bag IDs.
for _,bag in ipairs(bagCalls) do assert(bag>=0 and bag<=4) end
-- No mutable cache or retained counts across requests.
snap.countsByID[5512]=1000
assert(S:ReadInventoryBagSnapshot().countsByID[5512]==5)
-- A failure or secret/partial slot cannot yield a complete snapshot or zero.
local oldInfo=_G.C_Container.GetContainerItemInfo
_G.C_Container.GetContainerItemInfo=function(bag,slot)
    if bag==0 and slot==1 then return nil end
    return oldInfo(bag,slot)
end
local partial=S:ReadInventoryBagSnapshot()
assert(partial.status=="UNKNOWN" and partial.complete==false)
assert(partial.reason=="item_bag_scan_incomplete" and partial.countsByID==nil)
reset()
_G.C_Container.GetContainerNumSlots=function() return nil end
local noSlots=S:ReadInventoryBagSnapshot()
assert(noSlots.status=="UNKNOWN" and noSlots.countsByID==nil)
reset()
_G.C_Container.GetContainerNumSlots=function(bag)
    if bag==0 then return 81 end
    return 0
end
assert(S:ReadInventoryBagSnapshot().status=="UNKNOWN")
reset()
_G.C_Container.GetContainerItemInfo=function(bag,slot)
    local x=items[slotKey(bag,slot)]
    if bag==0 and slot==1 then return {itemID=999,stackCount=2} end
    return x
end
assert(S:ReadInventoryBagSnapshot().countsByID==nil)
reset()
_G.C_Container.GetContainerItemInfo=function(bag,slot)
    if bag==0 and slot==1 then return {itemID=5512,stackCount=0} end
    return items[slotKey(bag,slot)]
end
assert(S:ReadInventoryBagSnapshot().status=="UNKNOWN")
reset()
_G.C_Container.GetContainerItemInfo=function() error("protected or API error") end
assert(S:ReadInventoryBagSnapshot().status=="UNKNOWN")
_G.C_Container=nil
local missing=S:ReadInventoryBagSnapshot()
assert(missing.status=="UNKNOWN" and missing.reason=="bag_api_missing")
_G.C_Container=originalContainer
print("inventory_bag_snapshot_mock PASS")
