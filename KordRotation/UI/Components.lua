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


-- Slider-free numeric stepper for supported UI builds; each click validates through Settings.
function UI:StepRow(parent, labelKey, x, y, width, getter, setter, step, formatter)
    local row = CreateFrame("Frame", nil, parent)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    row:SetSize(width or 470, 39)
    self:Background(row, C.sidebar)
    local caption = self:Label(row, KR:L(labelKey), nil, C.text)
    caption:SetPoint("LEFT", 12, 0)
    caption:SetWidth((width or 470) - 190)
    local value = self:Label(row, "", nil, C.cyan)
    value:SetPoint("RIGHT", -79, 0)
    value:SetWidth(78)
    value:SetJustifyH("RIGHT")
    function row:Refresh()
        local n = getter()
        value:SetText(formatter and formatter(n) or tostring(n))
    end
    local function addButton(label, offset, delta)
        local button = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        button:SetSize(29, 28)
        button:SetPoint("RIGHT", offset, 0)
        button:SetText(label)
        button:SetScript("OnClick", function()
            local current = getter()
            if type(current) ~= "number" or current ~= current
                or current == math.huge or current == -math.huge then
                row:Refresh()
                return
            end
            setter(current + delta)
            row:Refresh()
        end)
    end
    addButton("-", -42, -(step or 1))
    addButton("+", -8, step or 1)
    row:Refresh()
    return row
end

function UI:ChoiceRow(parent, labelKey, x, y, width, getter, setter, choices)
    local row = CreateFrame("Button", nil, parent)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    row:SetSize(width or 470, 39)
    self:Background(row, C.sidebar)
    local caption = self:Label(row, KR:L(labelKey), nil, C.text)
    caption:SetPoint("LEFT", 12, 0)
    caption:SetWidth((width or 470) - 220)
    local chosen = self:Label(row, "", nil, C.cyan)
    chosen:SetPoint("RIGHT", -13, 0)
    chosen:SetWidth(205)
    chosen:SetJustifyH("RIGHT")
    function row:Refresh()
        local selected = getter()
        for _, entry in ipairs(choices) do
            if entry[1] == selected then chosen:SetText(KR:L(entry[2])); return end
        end
        chosen:SetText("-")
    end
    row:SetScript("OnClick", function()
        local selected = getter()
        for i, entry in ipairs(choices) do
            if entry[1] == selected then setter(choices[i % #choices + 1][1]); break end
        end
        row:Refresh()
    end)
    row:Refresh()
    return row
end

-- Kord Rotation copyright notice (3/3): see root LICENSE.
-- Original UI component code (c) 2026 Vi22Rus.
