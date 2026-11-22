-- IT-01/1.4, Lua 5.1 compatible standalone catalog test.
local KR={GameAPI={IsSafeValue=function(_,v)
    return type(v)=="string" or type(v)=="number" or type(v)=="table"
end}}
assert(loadfile("KordRotation/Core/ItemFamilyCatalog.lua"))("KordRotation",KR)
local C=KR.ItemFamilyCatalog
local function member(items,id)
    for _,value in ipairs(items) do if value==id then return true end end
    return false
end
local names=C:ListFamilies()
assert(#names>=6)
for _,familyID in ipairs({"HEALTH_POTION","MANA_POTION","HEALTHSTONE","BANDAGE","FOOD","DRINK"}) do
    local group=C:GetFamily(familyID)
    assert(group.status=="READY" and group.familyID==familyID)
    assert(group.inventoryScope=="BAGS_ONLY" and group.verification=="SOURCE_ONLY")
    assert(#group.itemIDs>0 and group.revision==1)
    local seen={}
    for _,id in ipairs(group.itemIDs) do
        assert(type(id)=="number" and id>0 and not seen[id])
        seen[id]=true
    end
end
local stones=C:GetFamily("HEALTHSTONE")
assert(member(stones.rankVariants.MINOR,5512))
assert(member(stones.rankVariants.MAJOR,9421))
assert(#stones.itemIDs==15)
assert(member(C:GetFamily("HEALTH_POTION").itemIDs,223913))
assert(member(C:GetFamily("MANA_POTION").itemIDs,288897))
assert(member(C:GetFamily("BANDAGE").itemIDs,14530))
assert(member(C:GetFamily("FOOD").itemIDs,262433))
assert(member(C:GetFamily("DRINK").itemIDs,262433))
local rev=C:GetRevision()
local before=C:GetFamily("FOOD")
before.itemIDs[1]=-1
before.rankVariants["INVENTED"]={1}
assert(C:GetFamily("FOOD").itemIDs[1]~=-1)
assert(C:GetFamily("FOOD").rankVariants["INVENTED"]==nil)
local changed=C:ReplaceFamily("CUSTOM_FOREVER",{900001,900002,900001})
assert(changed.status=="READY" and changed.changed and changed.revision==rev+1)
assert(#C:GetFamily("CUSTOM_FOREVER").itemIDs==2)
local again=C:ReplaceFamily("CUSTOM_FOREVER",{900002,900001})
assert(again.changed==false and C:GetRevision()==rev+1)
for _,invalid in ipairs({{0},{1.1},{math.huge},{false},{[2]=123}}) do
    local result=C:ReplaceFamily("CUSTOM_FOREVER",invalid)
    assert(result.status=="UNKNOWN" and C:GetRevision()==rev+1)
end
assert(C:GetFamily("UNKNOWN_FAMILY").status=="UNKNOWN")
assert(C:GetFamily("UNKNOWN_FAMILY").reason=="item_family_unknown")
assert(C:ReplaceFamily("bad",{123}).status=="UNKNOWN")
local swap=C:ReplaceFamily("HEALTH_POTION",{118,118,858})
assert(swap.status=="READY" and swap.changed)
local pot=C:GetFamily("HEALTH_POTION")
assert(#pot.itemIDs==2 and next(pot.rankVariants)==nil)
assert(C:GetFamily("HEALTHSTONE").rankVariants.MINOR[1]==5512)
print("item_family_catalog_mock PASS")
