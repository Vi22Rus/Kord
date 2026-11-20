-- Kord Rotation (c) 2026 Vi22Rus. All rights reserved.
-- Licensed for personal use under the repository LICENSE; no redistribution or derivatives without permission.
-- Retain this notice and LICENSE. Missing/altered LICENSE does not create permission or silently change existing rights.

local addonName, KR = ...
KR = KR or {}

local defaults = {
    schemaVersion = 1,
    window = { point = "CENTER", x = 0, y = 0, width = 880, height = 570 },
    showAtLogin = false,
    panel = { x = 0, y = -120, showPanel = true, testMode = false, locked = true },
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
