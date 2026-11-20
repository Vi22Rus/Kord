-- Kord Rotation (c) 2026 Vi22Rus. All rights reserved.
-- This file is licensed under the root LICENSE: personal use only, no unauthorized redistribution.
-- Do not remove attribution in authorized copies.

local addonName, KR = ...
KR.UI = KR.UI or {}
local UI = KR.UI
local C = UI.colors

-- License notice (2/3): Vi22Rus copyright applies to reusable UI components.
-- Visual controls never cast spells or perform protected combat actions.
function UI:ToggleRow(parent, labelKey, x, y, width, getValue, setValue)
    local row = CreateFrame("Button", nil, parent)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    row:SetSize(width or 470, 39)
    row:EnableMouse(true)
    local background = self:Background(row, C.sidebar)
    local caption = self:Label(row, KR:L(labelKey), nil, C.text)
    caption:SetPoint("LEFT", 12, 0)
    caption:SetWidth((width or 470) - 105)
    local indicator = self:Label(row, "", nil, C.cyan)
    indicator:SetPoint("RIGHT", -12, 0)
    indicator:SetWidth(85)
    indicator:SetJustifyH("RIGHT")
    function row:Refresh()
        local enabled = not not getValue()
        indicator:SetText(KR:L(enabled and "UI_ENABLED" or "UI_DISABLED"))
        local c = enabled and C.cyan or C.muted
        indicator:SetTextColor(c[1], c[2], c[3], c[4])
    end
    row:SetScript("OnClick", function()
        setValue(not getValue())
        row:Refresh()
    end)
    row:SetScript("OnEnter", function()
        background:SetColorTexture(C.panel[1], C.panel[2], C.panel[3], C.panel[4])
    end)
    row:SetScript("OnLeave", function()
        background:SetColorTexture(C.sidebar[1], C.sidebar[2], C.sidebar[3], C.sidebar[4])
    end)
    row:Refresh()
    return row
end

-- Kord Rotation copyright notice (3/3): see root LICENSE.
-- Original UI component code (c) 2026 Vi22Rus.
