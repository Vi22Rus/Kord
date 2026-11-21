-- Kord Rotation (c) 2026 Vi22Rus. All rights reserved.
-- Stage 2.8: validated in-memory rotation profile registry, intentionally empty.
local addonName, KR = ...
KR.RotationProfiles = KR.RotationProfiles or {}
local P = KR.RotationProfiles
local registry = {}
local categories = {damage=true,cooldowns=true,buffs=true,racial=true,
    trinkets=true,consumables=true,defensive=true,interrupts=true,movement=true}
local targets = {enemy=true,friendly=true,self=true,none=true}
local casts = {idle=true,allow=true}
local function id(n)
    return type(n)=="number" and n==math.floor(n) and n>=1 and n<=99999999
end
local function validGroup(group)
    if type(group)~="table" or #group>64 then return false end
    local count=0
    for key in pairs(group) do
        if type(key)~="number" or key<1 or key>64 or key~=math.floor(key) then return false end
        count=count+1
    end
    if count~=#group then return false end
    for _,rule in ipairs(group) do
        if type(rule)~="table" or not id(rule.spellID)
            or not categories[rule.category]
            or not targets[rule.target]
            or not casts[rule.cast]
            or type(rule.chargesRequired)~="boolean"
            or (rule.enabled~=nil and type(rule.enabled)~="boolean") then
            return false
        end
    end
    return true
end
local function copyGroup(group)
    local copy={}
    for i,rule in ipairs(group) do
        copy[i]={spellID=rule.spellID,category=rule.category,
            target=rule.target,cast=rule.cast,
            chargesRequired=rule.chargesRequired,
            enabled=rule.enabled~=false}
    end
    return copy
end
function P:Register(classToken,specIndex,profile)
    if type(classToken)~="string"
        or not classToken:match("^[A-Z]+$")
        or #classToken>16
        or type(specIndex)~="number" or specIndex~=math.floor(specIndex)
        or specIndex<1 or specIndex>3 or type(profile)~="table"
        or profile.verified~=true
        or not validGroup(profile.single) or not validGroup(profile.aoe)
        or #profile.single+#profile.aoe==0 then
        return false,"invalid_or_unverified_profile"
    end
    local key=classToken.."_TREE_"..specIndex
    -- No user SavedVariables may silently activate a new combat profile.
    if registry[key] then return false,"profile_already_registered" end
    registry[key]={id=key,classToken=classToken,specIndex=specIndex,
        single=copyGroup(profile.single),aoe=copyGroup(profile.aoe)}
    return true,key
end
function P:Get(id)
    if type(id)~="string" then return nil end
    local profile=registry[id]
    if not profile then return nil end
    return {id=profile.id,classToken=profile.classToken,
        specIndex=profile.specIndex,
        single=copyGroup(profile.single),aoe=copyGroup(profile.aoe)}
end
function P:Has(id)
    return type(id)=="string" and registry[id]~=nil
end
-- No default spec is registered at stage 2.8.
-- Copyright notice: see repository LICENSE.
