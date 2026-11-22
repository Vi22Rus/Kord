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


-- IT-02/2.6: on-demand mapping from the actual Forever reference signature:
-- C_Item.GetItemSpell(itemID) -> spellName, spellID (JustAC StateHelpers).
-- Only a COMPLETE, UNIQUE map may attribute an observed player spell.
-- A mapping alone never proves an item was used or a group cooldown started.
local useSpellIndex=nil
local useSpellRevision=nil
function C:PrepareUseSpellIndex(groupID)
    local candidatesOK,candidates=pcall(self.GetCandidateMembers,self,groupID)
    if not candidatesOK or type(candidates)~="table" then
        return {status="UNKNOWN",reason="item_cd_use_spell_members_unverified"}
    end
    if candidates.status~="UNKNOWN"
        or candidates.reason~="item_cd_use_attribution_unknown"
        or type(candidates.candidateItemIDs)~="table" then
        return {status="UNKNOWN",reason="item_cd_use_spell_members_unverified"}
    end
    local api=KR.GameAPI
    if not api or type(api.ReadValues)~="function" then
        return {status="UNKNOWN",reason="item_cd_use_spell_api_missing"}
    end
    local revision=candidates.familyRevision
    local ids=candidates.candidateItemIDs
    if useSpellIndex and useSpellRevision==revision then
        return {status="UNKNOWN",reason="item_cd_use_spell_index_prepared",
            mappedCount=#ids,verification="SOURCE_ONLY"}
    end
    useSpellIndex,useSpellRevision=nil,nil
    local ok,index=pcall(function()
        if not safe(revision) or type(revision)~="number" then return nil end
        if #ids<1 or #ids>32 then return nil end
        local mapping={}
        for i=1,#ids do
            local id=ids[i]
            if not safe(id) or type(id)~="number" then return nil end
            local read=api:ReadValues("C_Item.GetItemSpell",id)
            if type(read)~="table" or not safe(read)
                or read.status~="READY"
                or type(read.value)~="table" or not safe(read.value) then
                return nil
            end
            local name,spellID=read.value[1],read.value[2]
            if not safe(name) or type(name)~="string" or name==""
                or not safe(spellID) or type(spellID)~="number"
                or spellID~=math.floor(spellID) or spellID<1
                or spellID>99999999 then return nil end
            if mapping[spellID] then return nil end -- collision: ambiguous
            mapping[spellID]=id
        end
        if KR.ItemFamilyCatalog:GetRevision()~=revision then return nil end
        return mapping
    end)
    if not ok or not index then
        return {status="UNKNOWN",reason="item_cd_use_spell_mapping_unverified"}
    end
    useSpellIndex,useSpellRevision=index,revision
    return {status="UNKNOWN",reason="item_cd_use_spell_index_prepared",
        mappedCount=#ids,verification="SOURCE_ONLY"}
end
function C:FindObservedUseSpell(spellID)
    if not safe(spellID) or type(spellID)~="number"
        or spellID<1 or spellID>99999999
        or spellID~=math.floor(spellID) then
        return {status="UNKNOWN",reason="item_cd_use_spell_invalid"}
    end
    if not useSpellIndex or not KR.ItemFamilyCatalog
        or type(KR.ItemFamilyCatalog.GetRevision)~="function" then
        return {status="UNKNOWN",reason="item_cd_use_spell_index_missing"}
    end
    local ok,revision=pcall(KR.ItemFamilyCatalog.GetRevision,KR.ItemFamilyCatalog)
    if not ok or not safe(revision) or revision~=useSpellRevision then
        useSpellIndex,useSpellRevision=nil,nil
        return {status="UNKNOWN",reason="item_cd_use_spell_index_stale"}
    end
    local itemID=useSpellIndex[spellID]
    if not itemID then
        return {status="UNKNOWN",reason="item_cd_use_spell_not_mapped"}
    end
    -- This is source-only identity attribution, not proof of use or lockout.
    return {status="UNKNOWN",reason="item_cd_use_spell_source_match",
        itemID=itemID,groupID="POTION_SHARED",familyRevision=revision}
end

function C:ListGroups()
    return {"POTION_SHARED"}
end
