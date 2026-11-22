-- Kord Rotation (c) 2026 Vi22Rus. All rights reserved.
-- IT-02/2.5: source-backed candidate shared cooldown group catalog.
-- Functional item families are NOT evidence of shared cooldown behavior.
-- Until Forever client evidence confirms group semantics, UNKNOWN is required.
local addonName, KR = ...
KR.SharedCooldownGroupCatalog = KR.SharedCooldownGroupCatalog or {}
local C = KR.SharedCooldownGroupCatalog

local CANDIDATES={"HEALTH_POTION","MANA_POTION"}
local EXCLUDED={"HEALTHSTONE","BANDAGE","FOOD","DRINK","MANA_GEM","TRINKET"}
local function copy(items)
    local out={}
    for i=1,#items do out[i]=items[i] end
    return out
end
local function safe(value)
    local api=KR.GameAPI
    if not api or type(api.IsSafeValue)~="function" then return false end
    local ok,allowed=pcall(api.IsSafeValue,api,value)
    return ok and allowed==true
end
function C:GetGroup(groupID)
    if not safe(groupID) or type(groupID)~="string"
        or #groupID<1 or #groupID>64 then
        return {status="UNKNOWN",reason="item_cd_group_id_unverified"}
    end
    if groupID~="POTION_SHARED" then
        return {status="UNKNOWN",groupID=groupID,
            reason="item_cd_group_unknown"}
    end
    -- Family lists are a *candidate set*, never a verified shared lockout.
    -- No member IDs, last-use timer, duration or READY claim is emitted.
    local families=KR.ItemFamilyCatalog
    local rev=nil
    if families and type(families.GetRevision)=="function" then
        local ok,value=pcall(families.GetRevision,families)
        if ok and safe(value) and type(value)=="number"
            and value==value and value>=1 and value<math.huge
            and value==math.floor(value) then rev=value end
    end
    return {status="UNKNOWN",groupID=groupID,
        reason="item_cd_group_unverified",
        verification="PENDING_FOREVER",
        source="SharedCooldownGroupCatalog",
        candidateFamilies=copy(CANDIDATES),
        excludedFamilies=copy(EXCLUDED),
        familyRevision=rev}
end

-- IT-02/2.6: resolve bounded source-only item candidates, not shared CD proof.
-- Must never return READY: a functional item family proves no common lockout.
function C:GetCandidateMembers(groupID)
    local result={status="UNKNOWN",reason="item_cd_group_unverified",groupID=groupID}
    local groupOK,group=pcall(self.GetGroup,self,groupID)
    if not groupOK or type(group)~="table" or not safe(group) then
        result.reason="item_cd_group_catalog_invalid"
        return result
    end
    local valid,known=pcall(function()
        return group.groupID==groupID and group.status=="UNKNOWN"
            and group.reason=="item_cd_group_unverified"
            and group.verification=="PENDING_FOREVER"
    end)
    if not valid or not known then
        result.reason="item_cd_group_unknown"
        return result
    end
    local families=KR.ItemFamilyCatalog
    if not families or type(families.GetFamily)~="function"
        or type(families.GetRevision)~="function" then
        result.reason="item_cd_group_family_missing"
        return result
    end
    local ok,items,revision=pcall(function()
        local rev=families:GetRevision()
        if not safe(rev) or type(rev)~="number" or rev~=math.floor(rev)
            or rev<1 or rev==math.huge then return nil end
        local seen,out={},{}
        for _,familyID in ipairs(CANDIDATES) do
            local family=families:GetFamily(familyID)
            if type(family)~="table" or not safe(family)
                or not safe(family.status) or family.status~="READY"
                or not safe(family.familyID) or family.familyID~=familyID
                or not safe(family.verification) or family.verification~="SOURCE_ONLY"
                or not safe(family.revision) or family.revision~=rev
                or not safe(family.inventoryScope) or family.inventoryScope~="BAGS_ONLY"
                or type(family.itemIDs)~="table" or not safe(family.itemIDs) then
                return nil
            end
            local list=family.itemIDs
            local count=#list
            if count<1 or count>32 then return nil end
            for i=1,count do
                local itemID=list[i]
                if not safe(itemID) or type(itemID)~="number"
                    or itemID~=math.floor(itemID) or itemID<1
                    or itemID>99999999 then return nil end
                if not seen[itemID] then
                    if #out>=32 then return nil end
                    out[#out+1]=itemID
                    seen[itemID]=true
                end
            end
            for key in pairs(list) do
                if type(key)~="number" or key~=math.floor(key)
                    or key<1 or key>count then return nil end
            end
        end
        if families:GetRevision()~=rev then return nil end
        table.sort(out)
        return out,rev
    end)
    if not ok or not items then
        result.reason="item_cd_group_members_unverified"
        return result
    end
    result.reason="item_cd_use_attribution_unknown"
    result.verification="SOURCE_ONLY"
    result.candidateItemIDs=items
    result.candidateCount=#items
    result.familyRevision=revision
    return result
end

function C:ListGroups()
    return {"POTION_SHARED"}
end
