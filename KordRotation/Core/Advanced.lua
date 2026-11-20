-- Kord Rotation (c) 2026 Vi22Rus. All rights reserved.
-- Personal use subject to root LICENSE; keep attribution in authorized copies.
-- Reset operations require explicit confirmation from the player.

local addonName, KR = ...
KR.Advanced = KR.Advanced or {}
local A=KR.Advanced
local defaults={
    showAtLogin=false,showLoadMessage=true,showTooltips=true,
    showMinimap=false,updateRate=150,visualRate=100,scanRate=500,
}
local numeric={updateRate={50,1000},visualRate={50,1000},scanRate={200,5000}}
local function defaultValue(key,value)
    local original=defaults[key]
    if original==nil then return nil end
    if numeric[key] then
        if type(value)~="number" or value~=value
            or value==math.huge or value==-math.huge then value=original end
        local limits=numeric[key]
        return math.floor(math.max(limits[1],math.min(limits[2],value))+0.5)
    end
    if type(value)~="boolean" then return original end
    return value
end
-- License notice (2/3): update rates are preferences only; no rotation scheduler
-- or minimap integration is claimed to exist in stage 1.
function A:Initialize()
    if not KR.db then return end
    if type(KR.db.advanced)~="table" then KR.db.advanced={} end
    for key,value in pairs(defaults) do
        KR.db.advanced[key]=defaultValue(key,KR.db.advanced[key])
    end
    -- Preserve existing showAtLogin in the historical location.
    KR.db.showAtLogin=type(KR.db.showAtLogin)=="boolean" and KR.db.showAtLogin or false
end
function A:Get(key)
    if key=="showAtLogin" then return KR.db and KR.db.showAtLogin or false end
    if defaults[key]==nil then return nil end
    local saved=KR.db and KR.db.advanced
    if type(saved)=="table" and saved[key]~=nil then return saved[key] end
    return defaults[key]
end
function A:Set(key,value)
    if not KR.db then return false end
    if key=="showAtLogin" then
        if type(value)~="boolean" then return false end
        KR.db.showAtLogin=value
        return true
    end
    if defaults[key]==nil then return false end
    if numeric[key] then
        if type(value)~="number" or value~=value then return false end
    elseif type(value)~="boolean" then return false end
    if type(KR.db.advanced)~="table" then self:Initialize() end
    KR.db.advanced[key]=defaultValue(key,value)
    return true
end
function A:ResetAppearance()
    if KR.AppearanceProfiles then
        local ok=KR.AppearanceProfiles:ResetAppearance()
        if ok and KR.Diagnostics then KR.Diagnostics:Log("INFO","Settings","Appearance reset") end
        return ok
    end
    return false
end
function A:ResetCurrentRotation()
    local id=KR.RotationSettings and KR.RotationSettings:GetProfileID()
    if not id or not KR.db then return false end
    if type(KR.db.rotationProfiles)=="table" then KR.db.rotationProfiles[id]=nil end
    if KR.Diagnostics then KR.Diagnostics:Log("INFO","Settings","Current rotation settings reset") end
    if KR.RefreshCharacterUI then KR:RefreshCharacterUI() end
    return true
end
function A:ResetAll()
    -- Caller must present the dedicated confirmation dialog first.
    -- Do not discard data if the client cannot reload to release stale UI references.
    if not KR.db or type(ReloadUI)~="function" then return false end
    KordRotationDB={}
    KordRotationCharDB={}
    KR:InitializeSettings()
    self:Initialize()
    if KR.IndicatorSettings then KR.IndicatorSettings:Initialize() end
    ReloadUI()
    return true
end
-- Copyright notice (3/3): 2026 Vi22Rus; governed by root LICENSE.
