-- IT-02/2.5 mock: no false source-only shared cooldown evidence.
local KR={GameAPI={IsSafeValue=function(_,v) return v~="SECRET" end}}
assert(loadfile("KordRotation/Core/ItemFamilyCatalog.lua"))("KordRotation",KR)
assert(loadfile("KordRotation/Core/SharedCooldownGroupCatalog.lua"))("KordRotation",KR)
local c=KR.SharedCooldownGroupCatalog
local found=c:ListGroups()
assert(#found==1 and found[1]=="POTION_SHARED")
found[1]="CHANGED"
assert(c:ListGroups()[1]=="POTION_SHARED")
local g=c:GetGroup("POTION_SHARED")
assert(g.status=="UNKNOWN" and g.reason=="item_cd_group_unverified")
assert(g.verification=="PENDING_FOREVER" and g.groupID=="POTION_SHARED")
assert(#g.candidateFamilies==2 and g.candidateFamilies[1]=="HEALTH_POTION")
assert(g.candidateFamilies[2]=="MANA_POTION")
assert(g.familyRevision==KR.ItemFamilyCatalog:GetRevision())
assert(g.remaining==nil and g.active==nil and g.itemIDs==nil)
local exclusions={}
for _,id in ipairs(g.excludedFamilies) do exclusions[id]=true end
assert(exclusions.HEALTHSTONE and exclusions.BANDAGE
    and exclusions.FOOD and exclusions.DRINK
    and exclusions.MANA_GEM and exclusions.TRINKET)
g.candidateFamilies[1]="CHANGED"
assert(c:GetGroup("POTION_SHARED").candidateFamilies[1]=="HEALTH_POTION")
assert(c:GetGroup("UNKNOWN").status=="UNKNOWN")
assert(c:GetGroup("SECRET").groupID==nil)
assert(c:GetGroup(3).status=="UNKNOWN")
print("shared_cooldown_group_catalog_mock PASS")
