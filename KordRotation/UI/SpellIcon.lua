-- Kord Rotation (c) 2026 Vi22Rus. All rights reserved.
-- Personal use under LICENSE; no redistribution or derivatives without prior permission.
-- No license-file removal checks or concealed addon behavior.

local addonName, KR = ...
local UI, C = KR.UI, KR.UI.colors
KR.SpellIcon = KR.SpellIcon or {}

-- License notice (2/3): this visual widget belongs to Kord Rotation (see LICENSE).
-- A question-mark test texture is not a spell recommendation.
function KR.SpellIcon:Create(parent)
    local slot = CreateFrame("Frame", nil, parent)
    slot:SetSize(52, 52)
    slot:EnableMouse(false)

    local background = UI:Background(slot, C.panel)
    local image = slot:CreateTexture(nil, "ARTWORK")
    image:SetPoint("TOPLEFT", slot, "TOPLEFT", 3, -3)
    image:SetPoint("BOTTOMRIGHT", slot, "BOTTOMRIGHT", -3, 3)
    image:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    image:SetTexCoord(0.075, 0.925, 0.075, 0.925)
    local borders = UI:Border(slot, C.line, 2)

    local index = slot:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    index:SetPoint("BOTTOMRIGHT", -6, 5)
    index:SetTextColor(C.text[1], C.text[2], C.text[3])
    local keybind = slot:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    keybind:SetPoint("TOPRIGHT", -4, -4)
    local name = slot:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    name:SetPoint("BOTTOM", 0, 5)
    name:SetWidth(110)
    local charges = slot:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    charges:SetPoint("BOTTOMLEFT", 5, 4)
    local cooldownText = slot:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    cooldownText:SetPoint("CENTER", 0, 0)
    local unavailable = slot:CreateTexture(nil, "OVERLAY")
    unavailable:SetAllPoints(image)
    unavailable:SetColorTexture(0, 0, 0, 0.55)
    local gcd = slot:CreateTexture(nil, "OVERLAY")
    gcd:SetPoint("TOPLEFT", image)
    gcd:SetPoint("BOTTOMRIGHT", image)
    gcd:SetColorTexture(0.1, 0.6, 0.85, 0.22)
    slot.index = index
    slot.image = image
    slot.borderPieces = borders
    slot.keybind = keybind
    slot.nameText = name
    slot.chargesText = charges
    slot.cooldownText = cooldownText
    slot.unavailableShade = unavailable
    slot.gcdShade = gcd
    slot.iconBackground = background
    slot.displayFlags = {}
    slot.isPrimary = false

    -- Every combat field is supplied explicitly by a future verified data provider.
    -- Nil/unknown fields hide their layer; they are never interpreted as live values.
    function slot:SetDisplayData(data)
        if type(data) ~= "table" then data = {} end
        self.currentData = data
        local flags = self.displayFlags or {}
        local function shownText(text, value, enabled)
            text:SetText(value or "")
            text:SetShown(enabled and type(value) == "string" and value ~= "")
        end
        shownText(self.keybind, data.keybind, flags.showKeybind)
        shownText(self.nameText, data.name, flags.showSpellName)
        shownText(self.cooldownText, data.cooldownText, flags.showCooldown)
        if type(data.charges) == "number" and data.charges >= 0 then
            shownText(self.chargesText, tostring(data.charges), flags.showCharges)
        else
            shownText(self.chargesText, nil, false)
        end
        self.unavailableShade:SetShown(flags.showUnavailable and data.unavailable == true)
        self.gcdShade:SetShown(flags.showGCD and data.gcdActive == true)
        if data.texture then self.image:SetTexture(data.texture)
        else self.image:SetTexture(nil) end
    end

    function slot:ApplyAppearance(style, showNumbers, opacity, flags)
        self.displayFlags = flags or self.displayFlags
        self.index:SetShown(showNumbers)
        self:SetAlpha((opacity or 100) / 100)

        local options = self.displayFlags or {}
        local colors={white={1,1,1},cyan={0.06,0.79,0.98},gold={1,0.78,0.28}}
        local selected=colors[options.textColor] or colors.white
        local tone=self.isPrimary and options.highlightMain~=false and
            (colors[options.highlightColor] or colors.cyan) or C.line
        local intensity=self.isPrimary and (options.highlightStrength or 100)/100 or 1
        local thickness=options.borderThickness or 2
        for i, edge in ipairs(self.borderPieces) do
            edge:SetShown(style~="none" and thickness>0)
            edge:SetAlpha((style=="minimal" and 0.5 or 1)*intensity)
            edge:SetColorTexture(tone[1],tone[2],tone[3],1)
            if i<=2 then edge:SetHeight(thickness) else edge:SetWidth(thickness) end
        end
        self.iconBackground:SetShown(options.showIconBackground ~= false)
        self.iconBackground:SetAlpha((options.backgroundAlpha or 100)/100)
        local size = options.textSize or 12
        local centered=options.textPlacement=="centered"
        self.keybind:ClearAllPoints()
        self.keybind:SetPoint(centered and "TOP" or "TOPRIGHT", self,
            centered and "TOP" or "TOPRIGHT",centered and 0 or -4,-4)
        self.nameText:ClearAllPoints()
        self.nameText:SetPoint(centered and "TOP" or "BOTTOM",self,
            centered and "TOP" or "BOTTOM",0,centered and -18 or 5)
        self.chargesText:ClearAllPoints()
        self.chargesText:SetPoint(centered and "BOTTOM" or "BOTTOMLEFT",self,
            centered and "BOTTOM" or "BOTTOMLEFT",centered and 0 or 5,4)
        for _, f in ipairs({self.index,self.keybind,self.nameText,self.cooldownText,self.chargesText}) do
            f:SetTextColor(selected[1],selected[2],selected[3],1)
            if f.SetShadowOffset then
                f:SetShadowOffset(options.textShadow == false and 0 or 1,
                    options.textShadow == false and 0 or -1)
            end
        end
        for _, fontString in ipairs({self.keybind, self.nameText, self.chargesText, self.cooldownText}) do
            local font, _, styleFlags = fontString:GetFont()
            if font then fontString:SetFont(font, size, styleFlags or "") end
        end
        self:SetDisplayData(self.currentData)
    end

    function slot:ClearDisplayData()
        self:SetDisplayData(nil)
    end

    function slot:SetTestSlot(number, isPrimary)
        self.isPrimary=isPrimary
        self.index:SetText(tostring(number))
        self:ClearDisplayData()
        -- Preview only: a question mark signals a synthetic test slot.
        self.image:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    end
    return slot
end

-- Copyright notice (3/3): (c) 2026 Vi22Rus; see root LICENSE.
-- Retain notices in authorized copies.
