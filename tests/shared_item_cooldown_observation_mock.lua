-- IT-02/2.6 partial mock: catalog identity != cooldown evidence.
local KR={GameAPI={IsSafeValue=function(_,v) return v~="SECRET" end}}
assert(loadfile("KordRotation/Core/ItemFamilyCatalog.lua"))("KordRotation",KR)
assert(loadfile("KordRotation/Core/SharedCooldownGroupCatalog.lua"))("KordRotation",KR)
assert(loadfile("KordRotation/Core/GameState.lua"))("KordRotation",KR)
local S=KR.GameState
local group=S:ReadSharedItemCooldownObservation("POTION_SHARED")
assert(group.status=="UNKNOWN" and group.groupStatus=="UNKNOWN")
assert(group.reason=="item_cd_group_partial")
assert(group.catalogSource=="SharedCooldownGroupCatalog")
assert(group.verification=="PENDING_FOREVER")
assert(group.remaining==nil and group.active==nil and group.revision==nil)
assert(S:ReadSharedItemCooldownObservation("OTHER").reason=="item_cd_group_unknown")
assert(S:ReadSharedItemCooldownObservation("SECRET").groupID==nil)
local old=KR.SharedCooldownGroupCatalog
KR.SharedCooldownGroupCatalog=nil
assert(S:ReadSharedItemCooldownObservation("POTION_SHARED").reason=="item_cd_group_catalog_missing")
KR.SharedCooldownGroupCatalog={GetGroup=function() error("simulated") end}
assert(S:ReadSharedItemCooldownObservation("POTION_SHARED").reason=="item_cd_group_catalog_invalid")
KR.SharedCooldownGroupCatalog={GetGroup=function() return {status="READY",groupID="POTION_SHARED",remaining=0} end}
assert(S:ReadSharedItemCooldownObservation("POTION_SHARED").status=="UNKNOWN")
KR.SharedCooldownGroupCatalog=old
print("shared_item_cooldown_observation_mock PASS")
