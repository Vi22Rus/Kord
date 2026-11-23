-- IT-02/2.6 synthetic member-evidence contract; no WoW Forever assertions.
local KR={GameAPI={IsSafeValue=function(_,v) return v~="SECRET" end}}
assert(loadfile("KordRotation/Core/ItemFamilyCatalog.lua"))("KordRotation",KR)
assert(loadfile("KordRotation/Core/SharedCooldownGroupCatalog.lua"))("KordRotation",KR)
local bus={cooldown=5,inventory=7}
function bus:GetItemCooldownRevision() return self.cooldown end
function bus:GetInventoryRevision() return self.inventory end
KR.EventBus=bus
assert(loadfile("KordRotation/Core/SharedCooldownConfidence.lua"))("KordRotation",KR)
assert(loadfile("KordRotation/Core/GameState.lua"))("KordRotation",KR)
local S=KR.GameState
local original=S.ReadItemCooldownObservation
local originalUse=S.ReadObservedItemUse
local calls=0
local mode="partial"
function S:ReadObservedItemUse(groupID)
    if groupID~="POTION_SHARED" then
        return {status="UNKNOWN",reason="item_cd_use_attribution_unknown"}
    end
    if mode=="wrong_time" then
        return {status="UNKNOWN",reason="item_cd_use_attribution_estimated",
            confidence="ESTIMATED",candidateItemID=118,observedAt=80,
            familyRevision=KR.ItemFamilyCatalog:GetRevision()}
    elseif mode=="wrong_id" then
        return {status="UNKNOWN",reason="item_cd_use_attribution_estimated",
            confidence="ESTIMATED",candidateItemID=929,observedAt=90,
            familyRevision=KR.ItemFamilyCatalog:GetRevision()}
    elseif mode=="secret_use" then
        return {status="UNKNOWN",reason="item_cd_use_attribution_estimated",
            confidence="ESTIMATED",candidateItemID="SECRET",observedAt=90,
            familyRevision=KR.ItemFamilyCatalog:GetRevision()}
    end
    return {status="UNKNOWN",reason="item_cd_use_attribution_estimated",
        confidence="ESTIMATED",groupStatus="UNKNOWN",
        source=mode=="spoofed_source" and "SYNTHETIC" or "UNIT_SPELLCAST_SUCCEEDED",
        candidateItemID=118,observedAt=90,
        familyRevision=KR.ItemFamilyCatalog:GetRevision()}
end
function S:ReadItemCooldownObservation(id)
    calls=calls+1
    if mode=="race" and calls==2 then bus.cooldown=bus.cooldown+1 end
    local sampleAt=100
    if mode=="stale_sample" and id==858 then sampleAt=104 end
    if mode=="backward_sample" and id==858 then sampleAt=98 end
    if mode=="all_zero" then
        return {status="READY",itemID=id,cooldownScope="ITEM_SPECIFIC",
            active=false,remaining=0,startTime=0,duration=0,revision=bus.cooldown,observedAt=sampleAt}
    end
    if (mode=="cross_family" and id==2455) or id==118 or id==858 then
        if (mode=="cross_family" and id==858)
            or (mode=="single" and id==858) then
            return {status="UNKNOWN",reason="item_cd_unverified"}
        end
        if mode=="secret" and id==118 then
            return {status="READY",itemID=id,cooldownScope="ITEM_SPECIFIC",
                active="SECRET",remaining=20,revision=bus.cooldown,observedAt=sampleAt}
        end
        if mode=="short_gcd" then
            return {status="READY",itemID=id,cooldownScope="ITEM_SPECIFIC",
                active=true,remaining=1,startTime=99,duration=1,
                revision=bus.cooldown,observedAt=sampleAt}
        end
        if mode=="divergent" and id==858 then
            return {status="READY",itemID=id,cooldownScope="ITEM_SPECIFIC",
                active=true,remaining=20,startTime=70,duration=50,
                revision=bus.cooldown,observedAt=sampleAt}
        end
        return {status="READY",itemID=id,cooldownScope="ITEM_SPECIFIC",
            active=true,remaining=20,startTime=90,duration=30,revision=bus.cooldown,observedAt=sampleAt}
    end
    if id==929 then
        if mode=="aligned_only" or mode=="single" or mode=="cross_family" then
            return {status="UNKNOWN",reason="item_cd_unverified"}
        end
        return {status="READY",itemID=id,cooldownScope="ITEM_SPECIFIC",
            active=false,remaining=0,startTime=0,duration=0,revision=bus.cooldown,observedAt=sampleAt}
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
assert(result.useCorrelation=="ESTIMATED")
assert(result.useCorrelationReason=="item_cd_use_member_time_match")
assert(result.propagationEvidence=="MIXED_CANDIDATES")
assert(result.alignedCandidateCount==2 and result.divergentActiveCount==0)
assert(result.inactiveCandidateCount==1)
assert(result.itemCooldownConfidence=="CONFIRMED")
assert(result.groupLockoutConfidence=="UNKNOWN")
assert(result.groupReadyConfidence=="UNKNOWN")
mode="aligned_only"
local aligned=S:ReadSharedItemCooldownMemberEvidence("POTION_SHARED")
assert(aligned.propagationEvidence=="ALIGNED_CANDIDATES")
assert(aligned.alignedCandidateCount==2 and aligned.unknownCount==17)
assert(aligned.status=="UNKNOWN" and aligned.remaining==nil)
assert(aligned.itemCooldownConfidence=="CONFIRMED")
assert(aligned.alignedFamilyCount==1)
assert(aligned.groupLockoutConfidence=="UNKNOWN")
assert(aligned.groupReadyConfidence=="UNKNOWN")
local publicAligned=S:ReadSharedItemCooldownObservation("POTION_SHARED")
assert(publicAligned.groupLockoutConfidence=="UNKNOWN")
assert(publicAligned.useCorrelation=="ESTIMATED")
assert(publicAligned.propagationEvidence=="ALIGNED_CANDIDATES")
assert(publicAligned.itemCooldownConfidence=="CONFIRMED")
assert(publicAligned.groupReadyConfidence=="UNKNOWN")
assert(publicAligned.groupStatus=="UNKNOWN" and publicAligned.status=="UNKNOWN")
assert(publicAligned.groupRemaining==nil and publicAligned.active==nil)
assert(publicAligned.itemCooldownRevision==5 and publicAligned.inventoryRevision==7)
mode="cross_family"
local crossFamily=S:ReadSharedItemCooldownMemberEvidence("POTION_SHARED")
assert(crossFamily.alignedCandidateCount==2 and crossFamily.alignedFamilyCount==2)
assert(crossFamily.groupLockoutConfidence=="ESTIMATED")
assert(crossFamily.groupReadyConfidence=="UNKNOWN" and crossFamily.remaining==nil)
local publicCross=S:ReadSharedItemCooldownObservation("POTION_SHARED")
assert(publicCross.groupLockoutConfidence=="ESTIMATED")
assert(publicCross.groupStatus=="UNKNOWN" and publicCross.groupRemaining==nil)
assert(publicCross.useAttribution=="ESTIMATED" and publicCross.useObservedAt==90)
assert(crossFamily.matchedUseObservedAt==90)
-- A second valid player-use event may arrive between public attribution
-- and the member-evidence read. Its own matching cooldown must not
-- launder the older timestamp into the public attribution.
local realUseReader=S.ReadObservedItemUse
local eventReads=0
S.ReadObservedItemUse=function(self,groupID)
    eventReads=eventReads+1
    local evidence=realUseReader(self,groupID)
    if eventReads==2 then evidence.observedAt=91 end
    return evidence
end
local shiftedEvent=S:ReadSharedItemCooldownObservation("POTION_SHARED")
S.ReadObservedItemUse=realUseReader
assert(eventReads==2)
assert(shiftedEvent.useCorrelation=="ESTIMATED")
assert(shiftedEvent.useAttribution==nil and shiftedEvent.useObservedAt==nil)
assert(shiftedEvent.groupStatus=="UNKNOWN" and shiftedEvent.remaining==nil)
-- Same timestamp is insufficient: the two reads may refer to different
-- items sharing a cooldown start. Bind the attribution to the itemID too.
mode="aligned_only"
eventReads=0
S.ReadObservedItemUse=function(self,groupID)
    eventReads=eventReads+1
    local evidence=realUseReader(self,groupID)
    if eventReads==2 then evidence.candidateItemID=858 end
    return evidence
end
local shiftedItem=S:ReadSharedItemCooldownObservation("POTION_SHARED")
S.ReadObservedItemUse=realUseReader
assert(eventReads==2 and shiftedItem.useCorrelation=="ESTIMATED")
assert(shiftedItem.useAttribution==nil and shiftedItem.useObservedAt==nil)
assert(shiftedItem.groupStatus=="UNKNOWN" and shiftedItem.remaining==nil)
mode="cross_family"
-- A revision may change after the internal reader returns its stable record.
-- Public observation must refuse the now-stale confidence (no false READY).
local actualMemberReader=S.ReadSharedItemCooldownMemberEvidence
local function postReadRace(field)
    S.ReadSharedItemCooldownMemberEvidence=function(self,groupID)
        local sample=actualMemberReader(self,groupID)
        bus[field]=bus[field]+1
        return sample
    end
    local public=S:ReadSharedItemCooldownObservation("POTION_SHARED")
    S.ReadSharedItemCooldownMemberEvidence=actualMemberReader
    bus[field]=bus[field]-1
    assert(public.groupLockoutConfidence==nil and public.itemCooldownConfidence==nil)
    assert(public.useCorrelation==nil and public.propagationEvidence==nil)
    assert(public.groupStatus=="UNKNOWN" and public.remaining==nil)
    assert(public.useAttribution==nil and public.useObservedAt==nil)
end
postReadRace("cooldown")
postReadRace("inventory")
mode="single"
local single=S:ReadSharedItemCooldownMemberEvidence("POTION_SHARED")
assert(single.propagationEvidence=="SINGLE_CANDIDATE")
assert(single.alignedCandidateCount==1)
assert(single.groupLockoutConfidence=="UNKNOWN")
mode="divergent"
local divergence=S:ReadSharedItemCooldownMemberEvidence("POTION_SHARED")
assert(divergence.propagationEvidence=="MIXED_CANDIDATES")
assert(divergence.alignedCandidateCount==1 and divergence.divergentActiveCount==1)
assert(divergence.groupStatus=="UNKNOWN" and divergence.remaining==nil)
assert(divergence.groupLockoutConfidence=="UNKNOWN")
local publicMixed=S:ReadSharedItemCooldownObservation("POTION_SHARED")
assert(publicMixed.groupLockoutConfidence=="UNKNOWN")
assert(publicMixed.useCorrelation=="ESTIMATED")
assert(publicMixed.propagationEvidence=="MIXED_CANDIDATES")
assert(publicMixed.groupReadyConfidence=="UNKNOWN")
mode="short_gcd"
local shortGcd=S:ReadSharedItemCooldownMemberEvidence("POTION_SHARED")
assert(shortGcd.knownActiveCount==0 and shortGcd.unknownCount==18)
assert(shortGcd.useCorrelation=="UNKNOWN" and shortGcd.propagationEvidence=="UNKNOWN")
assert(shortGcd.groupLockoutConfidence=="UNKNOWN" and shortGcd.groupReadyConfidence=="UNKNOWN")
mode="stale_sample"
local staleSample=S:ReadSharedItemCooldownMemberEvidence("POTION_SHARED")
assert(staleSample.reason=="item_cd_sample_time_incoherent")
assert(staleSample.groupLockoutConfidence==nil and staleSample.candidateCount==nil)
mode="backward_sample"
local backwardSample=S:ReadSharedItemCooldownMemberEvidence("POTION_SHARED")
assert(backwardSample.reason=="item_cd_sample_time_incoherent")
assert(backwardSample.groupLockoutConfidence==nil)
mode="spoofed_source"
local publicForged=S:ReadSharedItemCooldownObservation("POTION_SHARED")
assert(publicForged.useAttribution==nil and publicForged.useObservedAt==nil)
assert(publicForged.groupStatus=="UNKNOWN" and publicForged.remaining==nil)
local forged=S:ReadSharedItemCooldownMemberEvidence("POTION_SHARED")
assert(forged.useCorrelation=="UNKNOWN" and forged.propagationEvidence=="UNKNOWN")
assert(forged.groupLockoutConfidence=="UNKNOWN" and forged.groupReadyConfidence=="UNKNOWN")
mode="wrong_time"
local publicWrongTime=S:ReadSharedItemCooldownObservation("POTION_SHARED")
assert(publicWrongTime.useAttribution==nil and publicWrongTime.useObservedAt==nil)
local wrongTime=S:ReadSharedItemCooldownMemberEvidence("POTION_SHARED")
assert(wrongTime.useCorrelation=="UNKNOWN")
assert(wrongTime.propagationEvidence=="UNKNOWN")
assert(wrongTime.alignedCandidateCount==nil)
mode="wrong_id"
local wrongID=S:ReadSharedItemCooldownMemberEvidence("POTION_SHARED")
assert(wrongID.useCorrelation=="UNKNOWN")
mode="secret_use"
local secretUse=S:ReadSharedItemCooldownMemberEvidence("POTION_SHARED")
assert(secretUse.useCorrelation=="UNKNOWN")
mode="all_zero"
calls=0
local zero=S:ReadSharedItemCooldownMemberEvidence("POTION_SHARED")
assert(zero.candidateCount==19 and zero.knownInactiveCount==19)
assert(zero.knownActiveCount==0 and zero.candidateMaxRemaining==nil)
assert(zero.status=="UNKNOWN" and zero.groupStatus=="UNKNOWN" and zero.remaining==nil)
assert(zero.useCorrelation=="UNKNOWN")
assert(zero.propagationEvidence=="UNKNOWN" and zero.divergentActiveCount==nil)
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
local publicRace=S:ReadSharedItemCooldownObservation("POTION_SHARED")
-- The first read changed the revision; a subsequent stable read remains UNKNOWN.
assert(publicRace.groupLockoutConfidence=="UNKNOWN")
assert(publicRace.propagationEvidence=="MIXED_CANDIDATES")
assert(publicRace.groupStatus=="UNKNOWN" and publicRace.remaining==nil)
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
        candidateItemIDs={118,118},candidateFamilyByItemID={[118]="HEALTH_POTION"},
        candidateCount=2}
end}
local duplicate=S:ReadSharedItemCooldownMemberEvidence("POTION_SHARED")
assert(duplicate.reason=="item_cd_group_members_unverified")
KR.SharedCooldownGroupCatalog=originalCatalog
S.ReadItemCooldownObservation=original
S.ReadObservedItemUse=originalUse
print("shared_item_cooldown_member_evidence_mock PASS")
