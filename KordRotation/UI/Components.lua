-- Kord Rotation (c) 2026 Vi22Rus. All rights reserved.
-- This file is licensed under the root LICENSE: personal use only, no unauthorized redistribution.
-- Do not remove attribution in authorized copies.

local addonName, KR = ...
KR.UI = KR.UI or {}
local UI = KR.UI
local C = UI.colors

function UI:ShowSettingTip(frame,key)
    if not KR.Advanced or not KR.Advanced:Get("showTooltips") or not GameTooltip then return end
    GameTooltip:SetOwner(frame,"ANCHOR_RIGHT")
    GameTooltip:AddLine(KR:L(key))
    local description=KR:L("TIP_"..key)
    if description=="TIP_"..key then description=KR:L("UI_TIP_NOTE") end
    GameTooltip:AddLine(description,1,1,1,true)
    GameTooltip:Show()
end

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
    row:SetScript("OnEnter", function(self)
        UI:ShowSettingTip(self,labelKey)
        background:SetColorTexture(C.panel[1], C.panel[2], C.panel[3], C.panel[4])
    end)
    row:SetScript("OnLeave", function()
        if GameTooltip then GameTooltip:Hide() end
        background:SetColorTexture(C.sidebar[1], C.sidebar[2], C.sidebar[3], C.sidebar[4])
    end)
    row:Refresh()
    return row
end


-- Every numeric setting has a validated range, slider and numeric input.
function UI:StepRow(parent,labelKey,x,y,width,getter,setter,step,formatter,minimum,maximum)
    if type(minimum)~="number" or type(maximum)~="number" then
        error("Missing numeric bounds for "..tostring(labelKey))
    end
    return self:SliderInputRow(parent,labelKey,x,y,width,getter,setter,minimum,maximum,step or 1)
end

-- Range slider and numeric edit share the same validated settings setter.
function UI:SliderInputRow(parent,labelKey,x,y,width,getter,setter,minValue,maxValue,step)
    local row=CreateFrame("Frame",nil,parent)
    row:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
    row:SetSize(width or 505,42)
    self:Background(row,C.sidebar)
    local caption=self:Label(row,KR:L(labelKey),nil,C.text)
    caption:SetPoint("LEFT",12,0)
    caption:SetWidth(190)
    local slider=CreateFrame("Slider",nil,row,"OptionsSliderTemplate")
    slider:SetPoint("LEFT",caption,"RIGHT",8,0)
    slider:SetSize(165,18)
    slider:SetMinMaxValues(minValue,maxValue)
    slider:SetValueStep(step or 1)
    if slider.SetObeyStepOnDrag then slider:SetObeyStepOnDrag(true) end
    if slider.Low then slider.Low:Hide() end
    if slider.High then slider.High:Hide() end
    if slider.Text then slider.Text:Hide() end
    local input=CreateFrame("EditBox",nil,row,"InputBoxTemplate")
    input:SetPoint("LEFT",slider,"RIGHT",14,0)
    input:SetSize(57,25)
    input:SetAutoFocus(false)
    input:SetMaxLetters(5)
    local updating=false
    local function normalize(n)
        if type(n)~="number" or n~=n then return nil end
        n=math.floor(n/(step or 1)+0.5)*(step or 1)
        return math.max(minValue,math.min(maxValue,n))
    end
    function row:Refresh()
        local n=normalize(getter()) or minValue
        updating=true
        slider:SetValue(n)
        input:SetText(tostring(n))
        updating=false
    end
    slider:SetScript("OnValueChanged",function(_,value)
        if updating then return end
        local n=normalize(value)
        if n then setter(n) end
        row:Refresh()
    end)
    local function commit()
        local n=normalize(tonumber(input:GetText()))
        if n then setter(n) end
        row:Refresh()
        input:ClearFocus()
    end
    input:SetScript("OnEnterPressed",commit)
    slider:SetScript("OnEnter",function(self) UI:ShowSettingTip(self,labelKey) end)
    slider:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
    input:SetScript("OnEnter",function(self) UI:ShowSettingTip(self,labelKey) end)
    input:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
    input:SetScript("OnEditFocusLost",function() row:Refresh() end)
    input:SetScript("OnEscapePressed",function() row:Refresh();input:ClearFocus() end)
    row:EnableMouse(true)
    row:SetScript("OnEnter",function(self) UI:ShowSettingTip(self,labelKey) end)
    row:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
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
    row:SetScript("OnEnter",function(self) UI:ShowSettingTip(self,labelKey) end)
    row:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
    row:Refresh()
    return row
end

-- Kord Rotation copyright notice (3/3): see root LICENSE.
-- Original UI component code (c) 2026 Vi22Rus.
