-- IT-01/1.9: explicit and sanitized DevTools inventory diagnosis.
-- Run from repository root with Lua 5.1; no WoW/client actions.
local KR={GameAPI={IsSafeValue=function(_,value)
    return value~="SECRET"
end}}
local mode="zero"
local calls=0
KR.GameState={
 ReadInventoryItemObservation=function(_,id)
    calls=calls+1
    if mode=="zero" then return {status="READY",itemID=id,
        count=0,inventoryScope="BAGS_ONLY"} end
    if mode=="scope" then return {status="READY",itemID=id,
        count=2,inventoryScope="BANK"} end
    if mode=="secret" then return {status="UNKNOWN",reason="item_count_secret"} end
    return {status="UNKNOWN",reason="no_value"}
 end,
 ReadInventoryFamilyObservation=function(_,id)
    calls=calls+1
    return {status="UNKNOWN",reason="item_family_partial"}
 end,
 ReadInventoryBagSnapshot=function()
    calls=calls+1
    return {status="UNKNOWN",reason="item_bag_scan_incomplete"}
 end,
}
assert(loadfile("KordRotation/Core/CoreObservation.lua"))("KordRotation",KR)
local bridge=_G.KordRotationCoreObservation
local records={}
local D={Safe=function(_,v)return v~="SECRET" end,
    active=true,Record=function(_,kind,status,code)
        records[#records+1]={kind=kind,status=status,code=code}
        return true
    end}
assert(loadfile("KordRotationDevTools/Probe.lua"))("KordRotationDevTools",D)
local x=D:InventoryDiagnostic("item",5512)
assert(x.status=="READY" and x.code=="item_count_zero_confirmed")
assert(x.itemID==nil and x.count==nil and x.reason==nil)
mode="scope";x=D:InventoryDiagnostic("item",5512)
assert(x.status=="UNKNOWN" and x.code=="item_count_scope_unverified")
mode="secret";x=D:InventoryDiagnostic("item",5512)
assert(x.code=="item_count_secret")
x=D:InventoryDiagnostic("family","HEALTHSTONE")
assert(x.code=="item_family_partial")
x=D:InventoryDiagnostic("bag")
assert(x.code=="item_bag_scan_incomplete")
local previous=calls
x=D:InventoryDiagnostic("item","SECRET")
assert(x.status=="UNKNOWN" and calls==previous)
x=D:InventoryDiagnostic("family","not_safe")
assert(x.status=="UNKNOWN" and calls==previous)
assert(#records==7)
D.active=false
x=D:InventoryDiagnostic("item",5512)
assert(#records==7)
assert(x.itemID==nil and x.count==nil)
-- No session, persistent cache, or raw game objects in the bridge results.
print("inventory_diagnostics_mock PASS")
