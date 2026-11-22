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
function C:ListGroups()
    return {"POTION_SHARED"}
end
