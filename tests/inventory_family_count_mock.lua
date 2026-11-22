-- IT-01/1.5: family count, partial observations, dedup, revisions.
-- Source/mock test only. No WoW client and no protected gameplay actions.
local KR={GameAPI={IsSafeValue=function(_,value)
    return type(value)=="number" or type(value)=="string" or type(value)=="table"
end}}
assert(loadfile("KordRotation/Core/ItemFamilyCatalog.lua"))("KordRotation",KR)
assert(loadfile("KordRotation/Core/GameState.lua"))("KordRotation",KR)
local S,C=KR.GameState,KR.ItemFamilyCatalog
local calls,answers={},{}
local function setFamily(name,ids)
    assert(C:ReplaceFamily(name,ids).status=="READY")
end
setFamily("IT01_TEST",{5512,5512,5511,19004})
local function read(itemID)
    calls[#calls+1]=itemID
    local answer=answers[itemID]
    if answer=="throw" then error("mock item reader failure") end
    if answer=="missing" then
        return {status="UNKNOWN",itemID=itemID,inventoryScope="BAGS_ONLY"}
    end
    if answer=="bad-scope" then
        return {status="READY",itemID=itemID,inventoryScope="BANK",count=4}
    end
    if answer=="bad-type" then
        return {status="READY",itemID=itemID,inventoryScope="BAGS_ONLY",count="4"}
    end
    return {status="READY",itemID=itemID,inventoryScope="BAGS_ONLY",count=answer}
end
S.ReadInventoryItemObservation=function(_,itemID) return read(itemID) end
answers={[5512]=2,[5511]=3,[19004]=0}
local all=S:ReadInventoryFamilyObservation("IT01_TEST")
assert(all.status=="READY" and all.count==5 and all.knownMinimum==nil)
assert(all.catalogRevision==C:GetRevision() and all.inventoryScope=="BAGS_ONLY")
assert(all.countsByID[5512]==2 and all.countsByID[5511]==3)
assert(all.countsByID[19004]==0 and all.knownComponents==3)
assert(#all.knownItemIDs==3 and #calls==3)
assert(all.bagRevision==nil)
-- A confirmed zero is not a failed/no-data result.
calls={};answers={[5512]=0,[5511]=0,[19004]=0}
local zero=S:ReadInventoryFamilyObservation("IT01_TEST")
assert(zero.status=="READY" and zero.count==0 and #calls==3)
-- A secret, nil, error or incomplete component cannot authorize family READY.
for _,bad in ipairs({"missing","throw","bad-scope","bad-type"}) do
    calls={}
    answers={[5512]=2,[5511]=bad,[19004]=1}
    local partial=S:ReadInventoryFamilyObservation("IT01_TEST")
    assert(partial.status=="UNKNOWN" and partial.count==nil)
    assert(partial.reason=="item_family_partial" and partial.knownMinimum==3)
    assert(partial.countsByID[5512]==2 and partial.countsByID[19004]==1)
    assert(partial.countsByID[5511]==nil and #calls==3)
end
answers={[5512]="missing",[5511]="throw",[19004]="missing"}
local totallyUnknown=S:ReadInventoryFamilyObservation("IT01_TEST")
assert(totallyUnknown.status=="UNKNOWN" and totallyUnknown.count==nil)
assert(totallyUnknown.knownMinimum==nil and totallyUnknown.knownComponents==0)
assert(S:ReadInventoryFamilyObservation("DOES_NOT_EXIST").status=="UNKNOWN")
assert(S:ReadInventoryFamilyObservation("").reason=="item_family_id_unverified")
-- Distinct families may overlap, without sharing results or mutable tables.
setFamily("IT01_OVERLAP",{5512,19004})
answers={[5512]=3,[5511]=1,[19004]=1}
local one=S:ReadInventoryFamilyObservation("IT01_TEST")
local other=S:ReadInventoryFamilyObservation("IT01_OVERLAP")
assert(one.count==5 and other.count==4)
one.countsByID[5512]=999
assert(S:ReadInventoryFamilyObservation("IT01_TEST").countsByID[5512]==3)
-- If catalog changes during reads, never return stale READY or stale lower bound.
local prior=S.ReadInventoryItemObservation
S.ReadInventoryItemObservation=function(self,itemID)
    local out=prior(self,itemID)
    if itemID==5512 then C:ReplaceFamily("IT01_TEST",{5512,5511}) end
    return out
end
local unstable=S:ReadInventoryFamilyObservation("IT01_TEST")
assert(unstable.status=="UNKNOWN" and unstable.count==nil)
assert(unstable.reason=="item_catalog_revision_changed")
assert(unstable.knownMinimum==nil and unstable.countsByID==nil)
print("inventory_family_count_mock PASS")
