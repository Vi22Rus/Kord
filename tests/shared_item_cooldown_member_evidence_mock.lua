-- IT-02/2.6 synthetic member-evidence contract; no WoW Forever assertions.
local KR={GameAPI={IsSafeValue=function(_,v) return v~="SECRET" end}}
assert(loadfile("KordRotation/Core/ItemFamilyCatalog.lua"))("KordRotation",KR)
assert(loadfile("KordRotation/Core/SharedCooldownGroupCatalog.lua"))("KordRotation",KR)
local bus={cooldown=5,inventory=7}
function bus:GetItemCooldownRevision() return self.cooldown end
function bus:GetInventoryRevision() return self.inventory end
KR.EventBus=bus
assert(loadfile("KordRotation/Core/GameState.lua"))("KordRotation",KR)
local S=KR.GameState
local original=S.ReadItemCooldownObservation
local calls=0
local mode="partial"
function S:ReadItemCooldownObservation(id)
    calls=calls+1
    if mode=="race" and calls==2 then bus.cooldown=bus.cooldown+1 end
    if mode=="all_zero" then
        return {status="READY",itemID=id,cooldownScope="ITEM_SPECIFIC",
            active=false,remaining=0,startTime=0,duration=0,revision=bus.cooldown}
    end
    if id==118 or id==858 then
        if mode=="secret" and id==118 then
            return {status="READY",itemID=id,cooldownScope="ITEM_SPECIFIC",
                active="SECRET",remaining=20,revision=bus.cooldown}
        end
        return {status="READY",itemID=id,cooldownScope="ITEM_SPECIFIC",
            active=true,remaining=20,startTime=90,duration=30,revision=bus.cooldown}
    end
    if id==929 then
        return {status="READY",itemID=id,cooldownScope="ITEM_SPECIFIC",
            active=false,remaining=0,startTime=0,duration=0,revision=bus.cooldown}
    end
    return {status="UNKNOWN",reason="item_cd_unverified"}
end
local result=S:ReadSharedItemCooldownMemberEvidence("POTION_SHARED")
assert(result.status=="UNKNOWN" and result.groupStatus=="UNKNOWN")
assert(result.reason=="item_cd_use_attribution_unknown")
assert(result.candidateCount==19 and calls==19)
assert(result.knownActiveCount==2 and result.knownInactiveCount==1)
assert(result.unknownCount==16 and result.coincidentActiveCount==2)
assert(result.candidateMaxRemaining==20)
assert(result.itemCooldownRevision==5 and result.inventoryRevision==7)
assert(result.familyRevision==KR.ItemFamilyCatalog:GetRevision())
assert(result.remaining==nil and result.active==nil)
assert(result.evidenceItemIDs==nil)
mode="all_zero"
calls=0
local zero=S:ReadSharedItemCooldownMemberEvidence("POTION_SHARED")
assert(zero.candidateCount==19 and zero.knownInactiveCount==19)
assert(zero.knownActiveCount==0 and zero.candidateMaxRemaining==nil)
assert(zero.status=="UNKNOWN" and zero.groupStatus=="UNKNOWN" and zero.remaining==nil)
mode="secret"
calls=0
local protected=S:ReadSharedItemCooldownMemberEvidence("POTION_SHARED")
assert(protected.knownActiveCount==1 and protected.unknownCount==17)
assert(protected.groupStatus=="UNKNOWN" and protected.remaining==nil)
mode="race"
calls=0
local raced=S:ReadSharedItemCooldownMemberEvidence("POTION_SHARED")
assert(raced.status=="UNKNOWN" and raced.reason=="item_cd_revision_changed")
assert(raced.candidateCount==nil and raced.candidateMaxRemaining==nil)
bus.cooldown=5
mode="partial"
KR.EventBus=nil
local missing=S:ReadSharedItemCooldownMemberEvidence("POTION_SHARED")
assert(missing.reason=="item_cd_revision_unavailable" and missing.candidateCount==nil)
KR.EventBus=bus
local bogus=S:ReadSharedItemCooldownMemberEvidence("OTHER")
assert(bogus.status=="UNKNOWN" and bogus.candidateCount==nil)
local originalCatalog=KR.SharedCooldownGroupCatalog
KR.SharedCooldownGroupCatalog={GetCandidateMembers=function()
    return {status="UNKNOWN",groupID="POTION_SHARED",
        reason="item_cd_use_attribution_unknown",familyRevision=1,
        candidateItemIDs={118,118},candidateCount=2}
end}
local duplicate=S:ReadSharedItemCooldownMemberEvidence("POTION_SHARED")
assert(duplicate.reason=="item_cd_group_members_unverified")
KR.SharedCooldownGroupCatalog=originalCatalog
S.ReadItemCooldownObservation=original
print("shared_item_cooldown_member_evidence_mock PASS")
