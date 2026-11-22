-- Kord Rotation (c) 2026 Vi22Rus. All rights reserved.
-- IT-01/1.4: one source-backed, versioned functional item-family catalog.
-- Item families are NOT GetItemFamily bag-type bitmasks. No WoW API calls.
local addonName, KR = ...
KR.ItemFamilyCatalog = KR.ItemFamilyCatalog or {}
local C = KR.ItemFamilyCatalog

local SOURCE = "JustAC/Data/Forever/Consumables.lua (Forever client generated data)"
local MANA_SOURCE = "Forever item listings (source-only; in-game verification pending)"
local MAX_ITEMS_PER_FAMILY = 256
local catalogRevision = 1

-- The initial entries come from an explicitly Forever-specific reference.
-- These are itemIDs, not spellIDs. Client validation of identity is NOT RUN.
-- Every rank/variant is represented by its own itemID; there is no guessing
-- of rank offsets, labels, or unavailable/custom client IDs.
local families = {
    HEALTH_POTION = {
        source=SOURCE,
        items={118,858,929,1710,3928,13446,223913,223914,287966,287967,287977,288896},
        rankVariants={
            MINOR={118,287966}, LESSER={858,287967},
            NORMAL={929}, GREATER={1710,223914,287977},
            SUPERIOR={3928,288896}, MAJOR={13446,223913},
        },
    },
    MANA_POTION = {
        source=MANA_SOURCE,
        items={2455,3385,3827,6149,13443,13444,288897},
        rankVariants={
            MINOR={2455}, LESSER={3385}, NORMAL={3827},
            GREATER={6149}, SUPERIOR={13443,288897}, MAJOR={13444},
        },
    },
    HEALTHSTONE = {
        source=SOURCE,
        items={5512,19004,19005,5511,19006,19007,5509,19008,19009,
            5510,19010,19011,9421,19012,19013},
        rankVariants={
            MINOR={5512,19004,19005}, LESSER={5511,19006,19007},
            NORMAL={5509,19008,19009}, GREATER={5510,19010,19011},
            MAJOR={9421,19012,19013},
        },
    },
    BANDAGE = {
        source=SOURCE,
        items={1251,2581,3530,3531,6450,6451,8544,8545,14529,14530,
            23684,19307,272058},
    },
    FOOD = {
        source=SOURCE,
        items={262433,19301,8932,13935,21023,22895,20031,8076,8952,
            13932,250067,287963},
    },
    DRINK = {
        source=SOURCE,
        items={159,1179,1205,1708,1645,8766,8077,8078,8079,
            19301,262433,231778,287964},
    },
}

local function safe(value)
    local api=KR.GameAPI
    if api and type(api.IsSafeValue)=="function" then
        local ok,result=pcall(api.IsSafeValue,api,value)
        return ok and result==true
    end
    -- No secret inspector: only hardcoded scalar IDs are safe candidates.
    return type(value)=="number" or type(value)=="string"
end

local function goodID(value)
    if not safe(value) or type(value)~="number" then return false end
    return value==value and value>0 and value<math.huge
        and value==math.floor(value)
end

local function goodFamilyID(value)
    return safe(value) and type(value)=="string"
        and #value>0 and #value<=64
        and string.match(value,"^[A-Z][A-Z0-9_]*$")~=nil
end

local function normalize(items)
    if type(items)~="table" or not safe(items) then return nil,"invalid_family_items" end
    local ok,result=pcall(function()
        local count=#items
        if count<1 or count>MAX_ITEMS_PER_FAMILY then return nil end
        local seen,unique={},{}
        for index=1,count do
            local itemID=items[index]
            if not goodID(itemID) then return nil end
            if not seen[itemID] then
                seen[itemID]=true
                unique[#unique+1]=itemID
            end
        end
        -- Holes, non-array keys, and unexpected fields are rejected.
        for key in pairs(items) do
            if type(key)~="number" or key~=math.floor(key)
                or key<1 or key>count then return nil end
        end
        table.sort(unique)
        return unique
    end)
    if not ok or not result then return nil,"invalid_family_items" end
    return result
end

local function copyList(items)
    local result={}
    for i=1,#items do result[i]=items[i] end
    return result
end

local function equivalent(a,b)
    if #a~=#b then return false end
    for i=1,#a do if a[i]~=b[i] then return false end end
    return true
end

-- Normalize built-ins once. Bad source data must never become a usable
-- family: do not quietly drop invalid entries.
for familyID,entry in pairs(families) do
    local ids,reason=normalize(entry.items)
    if not ids then error("Invalid built-in item family "..familyID..": "..reason) end
    entry.items=ids
    if entry.rankVariants then
        local rankSeen={}
        for rank,rankItems in pairs(entry.rankVariants) do
            local variant,why=normalize(rankItems)
            if not variant then error("Invalid rank variant "..rank..": "..why) end
            for _,itemID in ipairs(variant) do
                if rankSeen[itemID] then error("Duplicate rank item "..familyID) end
                rankSeen[itemID]=true
                local listed=false
                for _,id in ipairs(ids) do if id==itemID then listed=true;break end end
                if not listed then error("Rank item missing from family "..familyID) end
            end
            entry.rankVariants[rank]=variant
        end
    end
end

function C:GetRevision()
    return catalogRevision
end

function C:GetFamily(familyID)
    if not goodFamilyID(familyID) then
        return {status="UNKNOWN",reason="item_family_id_unverified"}
    end
    local entry=families[familyID]
    if not entry then
        return {status="UNKNOWN",familyID=familyID,reason="item_family_unknown"}
    end
    local ranks={}
    if entry.rankVariants then
        for rank,items in pairs(entry.rankVariants) do
            ranks[rank]=copyList(items)
        end
    end
    return {status="READY",familyID=familyID,itemIDs=copyList(entry.items),
        rankVariants=ranks,source=entry.source,revision=catalogRevision,
        verification="SOURCE_ONLY",inventoryScope="BAGS_ONLY"}
end

function C:ListFamilies()
    local names={}
    for familyID in pairs(families) do names[#names+1]=familyID end
    table.sort(names)
    return names
end

-- Validated atomic replacement for user-configurable Forever item families.
-- Existing built-in families can be extended or corrected in one transaction.
-- A custom family has no fabricated rank metadata; rank variants are
-- source-defined only until a separately verified rank mapping is available.
function C:ReplaceFamily(familyID,itemIDs)
    if not goodFamilyID(familyID) then
        return {status="UNKNOWN",reason="item_family_id_unverified"}
    end
    local normalized,reason=normalize(itemIDs)
    if not normalized then
        return {status="UNKNOWN",reason=reason,revision=catalogRevision}
    end
    local old=families[familyID]
    if old and equivalent(old.items,normalized) then
        return {status="READY",changed=false,revision=catalogRevision}
    end
    -- No stale rank variants after replacement: rank data requires explicit
    -- evidence, which a list of IDs alone cannot provide.
    families[familyID]={items=normalized,source="Kord user-configured itemIDs"}
    catalogRevision=catalogRevision+1
    return {status="READY",changed=true,revision=catalogRevision}
end
