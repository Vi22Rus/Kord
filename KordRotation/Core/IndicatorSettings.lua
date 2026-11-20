-- Kord Rotation (c) 2026 Vi22Rus. All rights reserved.
-- Personal use under the root LICENSE; no unauthorized redistribution or derivatives.
-- Missing license file does not change existing lawful rights.

local addonName, KR = ...
KR.IndicatorSettings = KR.IndicatorSettings or {}
local M = KR.IndicatorSettings
local defaults = {
    actionHighlight=false, highlightStyle="border", highlightStrength=70,
    highlightCount="first", defensiveEnabled=false, defensiveSlots=2,
    defensiveSize=52, defensiveAlpha=100, defensiveCombatOnly=true,
    interruptEnabled=false, interruptSpellID=0, interruptSize=52,
    interruptSound=false, interruptText=true, audioEnabled=false,
    audioImportant=false, audioDefensive=false, audioInterrupt=false,
    audioCooldown=3, resourceEnabled=false, targetHealthEnabled=false,
    castbarEnabled=false, gcdEnabled=false,
}
local numbers={highlightStrength={0,100},defensiveSlots={1,3},
    defensiveSize={24,128},defensiveAlpha={0,100},interruptSpellID={0,9999999},
    interruptSize={24,128},audioCooldown={1,30}}
local options={highlightStyle={border=true,glow=true},
    highlightCount={first=true,multiple=true}}
local function valid(key,value)
    if defaults[key]==nil then return false end
    if numbers[key] then
        return type(value)=="number" and value==value and value~=math.huge
            and value~=-math.huge
    end
    if options[key] then return type(value)=="string" and options[key][value] == true end
    return type(value)=="boolean"
end

local function copySettings(source)
    local new={}
    source=type(source)=="table" and source or {}
    for key, original in pairs(defaults) do
        local value=source[key]
        if not valid(key,value) then value=original end
        if numbers[key] then
            local range=numbers[key]
            value=math.floor(math.max(range[1],math.min(range[2],value))+0.5)
        end
        new[key]=value
    end
    return new
end

-- License notice (2/3): UI configuration only; these flags do not register action-bar
-- hooks, read combat secrets, play sounds, or claim working combat indicators.
function M:Initialize()
    if not KR.db then return end
    KR.db.indicators=copySettings(KR.db.indicators)
end
function M:Get(key)
    if defaults[key]==nil then return nil end
    local saved=KR.db and KR.db.indicators
    if type(saved)=="table" and saved[key]~=nil then return saved[key] end
    return defaults[key]
end
function M:Set(key,value)
    if not valid(key,value) or not KR.db then return false end
    if type(KR.db.indicators)~="table" then self:Initialize() end
    if numbers[key] then
        local range=numbers[key]
        value=math.floor(math.max(range[1],math.min(range[2],value))+0.5)
    end
    KR.db.indicators[key]=value
    if KR.RotationDisplay and KR.RotationDisplay.Refresh then KR.RotationDisplay:Refresh() end
    if KR.indicatorsPageRefresh then KR.indicatorsPageRefresh() end
    return true
end
function M:Reset()
    if not KR.db then return false end
    KR.db.indicators=copySettings(defaults)
    if KR.indicatorsPageRefresh then KR.indicatorsPageRefresh() end
    return true
end
function M:Keys() return defaults end

-- Copyright notice (3/3): (c) 2026 Vi22Rus; root LICENSE governs use.
-- Retain attribution in all authorized copies.
