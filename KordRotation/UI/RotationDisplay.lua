-- Kord Rotation (c) 2026 Vi22Rus. All rights reserved.
-- Personal use under LICENSE; no redistribution or derivatives without prior permission.
-- No license-file removal checks or concealed addon behavior.

local addonName, KR = ...
local UI, C = KR.UI, KR.UI.colors
KR.RotationDisplay = KR.RotationDisplay or {}

local function clamp(v, low, high)
    v = tonumber(v) or low
    if v < low then return low end
    if v > high then return high end
    return v
end

local function ensurePosition(db)
    if type(db.panel) ~= "table" then db.panel = {} end
    local p = db.panel
    p.x, p.y = clamp(p.x or 0, -10000, 10000), clamp(p.y or -120, -10000, 10000)
    if p.showPanel == nil then p.showPanel = true end
    if p.locked == nil then p.locked = true end
    if p.testMode == nil then p.testMode = false end
    return p
end

-- License notice (2/3): © 2026 Vi22Rus. See LICENSE.
-- Test mode presents placeholders ONLY; there is no scheduler or spell prediction here.
function KR.RotationDisplay:Create()
    if self.frame then return self.frame end
    local cfg = ensurePosition(KR.db)
    local frame = CreateFrame("Frame", "KordRotationRecommendationPanel", UIParent)
    frame:SetFrameStrata("MEDIUM")
    frame:SetSize(188, 78)
    frame:SetPoint("CENTER", UIParent, "CENTER", cfg.x, cfg.y)
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(f)
        if not ensurePosition(KR.db).locked then f:StartMoving() end
    end)
    frame:SetScript("OnDragStop", function(f)
        f:StopMovingOrSizing()
        local x, y = f:GetCenter()
        local sx, sy = UIParent:GetCenter()
        if x and y and sx and sy then
            local p = ensurePosition(KR.db)
            p.x, p.y = x - sx, y - sy
        end
    end)

    local marker = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    marker:SetPoint("BOTTOM", frame, "TOP", 0, 6)
    marker:SetTextColor(C.cyan[1], C.cyan[2], C.cyan[3])
    marker:SetText(KR:L("PANEL_TEST_BADGE"))

    local slots = {}
    for i = 1, 3 do
        local slot = KR.SpellIcon:Create(frame)
        local size = i == 1 and 72 or 52
        slot:SetSize(size, size)
        if i == 1 then
            slot:SetPoint("LEFT", frame, "LEFT", 0, 0)
        else
            slot:SetPoint("LEFT", slots[i - 1], "RIGHT", 6, 0)
        end
        slot:SetTestSlot(i, i == 1)
        slots[i] = slot
    end
    self.frame, self.slots = frame, slots
    frame:Hide()
    self:Refresh()
    return frame
end

function KR.RotationDisplay:Refresh()
    if not self.frame then return end
    local p = ensurePosition(KR.db)
    -- Without a real rotation engine, NEVER show a fictitious production queue.
    if p.showPanel and p.testMode then self.frame:Show() else self.frame:Hide() end
end

function KR.RotationDisplay:ToggleTest()
    self:Create()
    local p = ensurePosition(KR.db)
    KR:SetPanelFlag("testMode", not p.testMode)
    return p.testMode
end

function KR.RotationDisplay:ToggleLock()
    self:Create()
    local p = ensurePosition(KR.db)
    KR:SetPanelFlag("locked", not p.locked)
    return p.locked
end

function KR.RotationDisplay:ResetPosition()
    self:Create()
    local p = ensurePosition(KR.db)
    p.x, p.y = 0, -120
    self.frame:ClearAllPoints()
    self.frame:SetPoint("CENTER", UIParent, "CENTER", p.x, p.y)
    if KR.UpdatePanelControls then KR:UpdatePanelControls() end
end

-- Copyright notice (3/3): (c) 2026 Vi22Rus; see root LICENSE.
-- Retain notices in authorized copies.
