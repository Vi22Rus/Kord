-- Kord Rotation (c) 2026 Vi22Rus. All rights reserved.
-- Licensed for personal use under the repository LICENSE; no redistribution or derivatives without permission.
-- Retain this notice and LICENSE. Missing/altered LICENSE does not create permission or silently change existing rights.

local addonName, KR = ...
KR = KR or {}

local defaults = {
    schemaVersion = 1,
    window = { point = "CENTER", x = 0, y = 0, width = 880, height = 570 },
    showAtLogin = false,
    panel = {
        x = 0, y = -120, showPanel = true, testMode = false, locked = true,
        slotCount = 3, primarySize = 72, secondarySize = 52, gap = 6,
        scale = 100, alpha = 100, secondaryAlpha = 100,
        direction = "horizontal", primaryAtEnd = false,
        borderStyle = "standard", showNumbers = true,
    },
}

local function copyMissing(destination, source)
    for key, value in pairs(source) do
        if destination[key] == nil then
            if type(value) == "table" then
                destination[key] = {}
                copyMissing(destination[key], value)
            else
                destination[key] = value
            end
        elseif type(value) == "table" and type(destination[key]) == "table" then
            copyMissing(destination[key], value)
        end
    end
end

-- License notice (2/3): Copyright (c) 2026 Vi22Rus; use subject to LICENSE.
-- These settings are local to the player; they do not check, delete, or disable LICENSE.
-- Layout settings are validated both on load and on edit.
local numeric = {
    slotCount={1,5}, primarySize={32,128}, secondarySize={24,96},
    gap={0,30}, scale={50,200}, alpha={0,100}, secondaryAlpha={0,100},
}
local choices = {
    direction={horizontal=true,vertical=true},
    borderStyle={standard=true,minimal=true,none=true},
}
local booleanLayout = {primaryAtEnd=true,showNumbers=true}

local function normalize(panel)
    for key, range in pairs(numeric) do
        local n = tonumber(panel[key])
        if not n or n ~= n or n == math.huge or n == -math.huge then n = defaults.panel[key] end
        panel[key] = math.floor(math.max(range[1], math.min(range[2], n)) + 0.5)
    end
    for key, set in pairs(choices) do
        if not set[panel[key]] then panel[key] = defaults.panel[key] end
    end
    for key in pairs(booleanLayout) do
        if type(panel[key]) ~= "boolean" then panel[key] = defaults.panel[key] end
    end
    for _, key in ipairs({"showPanel","testMode","locked"}) do
        if type(panel[key]) ~= "boolean" then panel[key] = defaults.panel[key] end
    end
end

function KR:GetPanelLayout(key)
    if not self.db or not self.db.panel then return nil end
    if not numeric[key] and not choices[key] and not booleanLayout[key] then return nil end
    return self.db.panel[key]
end

function KR:SetPanelLayout(key, value)
    if not self.db or not self.db.panel then return false end
    if numeric[key] then
        if type(value) ~= "number" or value ~= value or value == math.huge or value == -math.huge then return false end
        local range = numeric[key]
        value = math.floor(math.max(range[1], math.min(range[2], value)) + 0.5)
    elseif choices[key] then
        if not choices[key][value] then return false end
    elseif booleanLayout[key] then
        if type(value) ~= "boolean" then return false end
    else return false end
    self.db.panel[key] = value
    if self.RotationDisplay and self.RotationDisplay.RefreshLayout then self.RotationDisplay:RefreshLayout() end
    if self.UpdatePanelControls then self:UpdatePanelControls() end
    return true
end

function KR:InitializeSettings()
    if type(KordRotationDB) ~= "table" then KordRotationDB = {} end
    if type(KordRotationCharDB) ~= "table" then KordRotationCharDB = {} end
    copyMissing(KordRotationDB, defaults)
    if type(KordRotationDB.window) ~= "table" then
        KordRotationDB.window = {}
        copyMissing(KordRotationDB.window, defaults.window)
    end
    if type(KordRotationDB.panel) ~= "table" then KordRotationDB.panel = {} end
    copyMissing(KordRotationDB.panel, defaults.panel)
    normalize(KordRotationDB.panel)
    self.db = KordRotationDB
    self.charDB = KordRotationCharDB
end

-- Shared UI API: commands and both settings pages update the same flags.
local panelFlags = {showPanel = true, testMode = true, locked = true}
function KR:SetPanelFlag(key, value)
    if not panelFlags[key] or type(value) ~= "boolean" or not self.db then return false end
    if type(self.db.panel) ~= "table" then self.db.panel = {} end
    self.db.panel[key] = value
    if self.RotationDisplay and self.RotationDisplay.Refresh then self.RotationDisplay:Refresh() end
    if self.UpdatePanelControls then self:UpdatePanelControls() end
    return true
end

function KR:GetPanelFlag(key)
    if not panelFlags[key] then return nil end
    local panel = self.db and self.db.panel
    if type(panel) == "table" and type(panel[key]) == "boolean" then return panel[key] end
    return defaults.panel[key]
end

function KR:GetWindowSettings()
    return self.db and self.db.window
end

-- Kord Rotation copyright notice (3/3): see LICENSE in repository root.
-- Do not remove attribution or redistribute modified builds without authorization.
