-- Kord Rotation (c) 2026 Vi22Rus. All rights reserved.
-- Personal use is permitted only under the root LICENSE. Do not redistribute derivative builds.
-- Missing/altered LICENSE does not grant permission or disable this addon.

local addonName, KR = ...
KR.RotationSettings = KR.RotationSettings or {}

local categories = {
    "damage", "cooldowns", "buffs", "racial", "trinkets",
    "consumables", "defensive", "interrupts", "movement",
}
local defaults = {
    enabled = false, targetMode = "auto", cooldownsOnlyInCombat = true,
    conserveResources = false, prebuffs = false,
    categories = {
        damage = true, cooldowns = true, buffs = true, racial = false,
        trinkets = false, consumables = false, defensive = false,
        interrupts = false, movement = false,
    },
    spells = {},
}
local validTargets = {auto = true, single = true, aoe = true}
local validCategory = {}
for _, name in ipairs(categories) do validCategory[name] = true end

local function clone(source)
    local out = {}
    for key, value in pairs(source) do
        out[key] = type(value) == "table" and clone(value) or value
    end
    return out
end

local function normalize(profile)
    if type(profile.categories) ~= "table" then profile.categories = {} end
    if type(profile.spells) ~= "table" then profile.spells = {} end
    for key, value in pairs(defaults) do
        if key ~= "categories" and key ~= "spells" and type(profile[key]) ~= type(value) then
            profile[key] = value
        end
    end
    if not validTargets[profile.targetMode] then profile.targetMode = "auto" end
    for key, value in pairs(defaults.categories) do
        if type(profile.categories[key]) ~= "boolean" then profile.categories[key] = value end
    end
    for spellID, item in pairs(profile.spells) do
        if type(spellID) ~= "number" or spellID < 1 or spellID ~= math.floor(spellID)
            or type(item) ~= "table" then
            profile.spells[spellID] = nil
        else
            if type(item.enabled) ~= "boolean" then item.enabled = true end
            if type(item.separate) ~= "boolean" then item.separate = false end
            if type(item.keyLabel) ~= "string" then item.keyLabel = "" end
            if #item.keyLabel > 32 then item.keyLabel = string.sub(item.keyLabel, 1, 32) end
            if type(item.category) ~= "string" or not validCategory[item.category] then
                item.category = nil
            end
        end
    end
    return profile
end

function KR.RotationSettings:GetProfileID()
    local state = KR.characterState
    if type(state) ~= "table" then return nil end
    local token, index = state.classToken, state.index
    if type(token) ~= "string" or type(index) ~= "number" or index < 1 or index > 3 then
        return nil
    end
    return token .. "_TREE_" .. tostring(index)
end

-- License notice (2/3): original class/tree settings adapter is under LICENSE.
-- A missing or ambiguous specialization must NEVER silently write to another profile.
function KR.RotationSettings:GetProfile(create)
    local id = self:GetProfileID()
    if not id or not KR.db then return nil, nil end
    if type(KR.db.rotationProfiles) ~= "table" then
        if not create then return nil, id end
        KR.db.rotationProfiles = {}
    end
    local saved = KR.db.rotationProfiles
    if type(saved[id]) ~= "table" then
        if not create then return nil, id end
        saved[id] = clone(defaults)
    end
    return normalize(saved[id]), id
end

function KR.RotationSettings:GetFlag(key)
    local profile = self:GetProfile(true)
    if not profile or defaults[key] == nil or type(defaults[key]) == "table" then return nil end
    return profile[key]
end

function KR.RotationSettings:SetFlag(key, value)
    local profile = self:GetProfile(true)
    if not profile or defaults[key] == nil or type(defaults[key]) ~= "boolean"
        or type(value) ~= "boolean" then return false end
    profile[key] = value
    return true
end

function KR.RotationSettings:GetTargetMode()
    local profile = self:GetProfile(true)
    return profile and profile.targetMode or "auto"
end

function KR.RotationSettings:SetTargetMode(value)
    if not validTargets[value] then return false end
    local profile = self:GetProfile(true)
    if not profile then return false end
    profile.targetMode = value
    return true
end

function KR.RotationSettings:GetCategory(key)
    local profile = self:GetProfile(true)
    if not profile or not validCategory[key] then return nil end
    return profile.categories[key]
end

function KR.RotationSettings:SetCategory(key, value)
    local profile = self:GetProfile(true)
    if not profile or not validCategory[key] or type(value) ~= "boolean" then return false end
    profile.categories[key] = value
    return true
end

function KR.RotationSettings:Categories()
    return categories
end

function KR.RotationSettings:GetSpell(spellID)
    local profile = self:GetProfile(true)
    if not profile or type(spellID) ~= "number" then return nil end
    return profile.spells[spellID]
end

function KR.RotationSettings:SetSpell(spellID, key, value)
    if type(spellID) ~= "number" or spellID < 1 or spellID ~= math.floor(spellID) then return false end
    local profile = self:GetProfile(true)
    if not profile then return false end
    if key == "enabled" or key == "separate" then
        if type(value) ~= "boolean" then return false end
    elseif key == "category" then
        if value ~= nil and not validCategory[value] then return false end
    elseif key == "keyLabel" then
        if type(value) ~= "string" or #value > 32 then return false end
    else return false end
    local record = profile.spells[spellID]
    if type(record) ~= "table" then
        record = {enabled = true, separate = false, keyLabel = ""}
        profile.spells[spellID] = record
    end
    record[key] = value
    return true
end

function KR.RotationSettings:ResetSpell(spellID)
    local profile = self:GetProfile(true)
    if not profile or type(spellID) ~= "number" then return false end
    profile.spells[spellID] = nil
    return true
end

-- No combat rotation consumes these settings in stage 1. Settings exist for future contracts.

-- Kord Rotation copyright notice (3/3): see LICENSE in the repository root.
-- Retain ownership notices in authorized copies.
