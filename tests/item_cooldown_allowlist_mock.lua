-- IT-02/2.2 Lua 5.1 mock: read-only allowlist and fail-closed probes.
-- No client compatibility claim: these are synthetic API stubs only.
local oldItem=_G.C_Item
local oldContainer=_G.C_Container
local oldLegacy=_G.GetItemCooldown
local oldTime=_G.GetTime
local oldSecret=_G.issecretvalue
_G.C_Item={GetItemCooldown=function(id)
    assert(id==5512)
    return 100,30,1
end}
_G.C_Container={GetItemCooldown=function(bag,slot)
    assert(bag==0 and slot==1)
    return 101,28,true
end}
_G.GetItemCooldown=function(id)
    assert(id==5512)
    return 102,27,0
end
_G.GetTime=function() return 105 end
_G.issecretvalue=function(v) return v=="PROTECTED" end
local KR={}
assert(loadfile("KordRotation/Core/GameAPI.lua"))("KordRotation",KR)
local API=KR.GameAPI
local names={"C_Item.GetItemCooldown","C_Container.GetItemCooldown","GetItemCooldown"}
for _,name in ipairs(names) do
    assert(API:Probe(name).status=="READY")
end
local one=API:ReadTuple("C_Item.GetItemCooldown",{"number","number","number"},5512)
assert(one.status=="READY" and one.value[1]==100 and one.value[2]==30 and one.value[3]==1)
local two=API:ReadTuple("C_Container.GetItemCooldown",{"number","number","boolean"},0,1)
assert(two.status=="READY" and two.value[3]==true)
local three=API:ReadTuple("GetItemCooldown",{"number","number","number"},5512)
assert(three.status=="READY" and three.value[3]==0)
-- Stub only: do not interpret returned tuple as in-game cooldown ready.
_G.C_Item.GetItemCooldown=function() return "PROTECTED" end
assert(API:ReadValues("C_Item.GetItemCooldown",5512).status=="UNKNOWN")
_G.C_Item.GetItemCooldown=function() return 0/0,10,1 end
assert(API:ReadValues("C_Item.GetItemCooldown",5512).status=="UNKNOWN")
_G.C_Item.GetItemCooldown=nil
assert(API:Probe("C_Item.GetItemCooldown").status=="UNAVAILABLE")
assert(API:ReadValues("C_Item.GetItemCooldown",5512).status=="UNAVAILABLE")
assert(API:Probe("UseItemByName").status=="UNAVAILABLE")
_G.C_Item=oldItem
_G.C_Container=oldContainer
_G.GetItemCooldown=oldLegacy
_G.GetTime=oldTime
_G.issecretvalue=oldSecret
print("item_cooldown_allowlist_mock PASS")
