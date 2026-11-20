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

    UI:Background(slot, C.panel)
    local image = slot:CreateTexture(nil, "ARTWORK")
    image:SetPoint("TOPLEFT", slot, "TOPLEFT", 3, -3)
    image:SetPoint("BOTTOMRIGHT", slot, "BOTTOMRIGHT", -3, 3)
    image:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    image:SetTexCoord(0.075, 0.925, 0.075, 0.925)
    local borders = UI:Border(slot, C.line, 2)

    local index = slot:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    index:SetPoint("BOTTOMRIGHT", -6, 5)
    index:SetTextColor(C.text[1], C.text[2], C.text[3])
    slot.index = index
    slot.image = image
    slot.borderPieces = borders

    function slot:SetTestSlot(number, isPrimary)
        self.index:SetText(tostring(number))
        local tone = isPrimary and C.cyan or C.line
        for _, border in ipairs(self.borderPieces) do
            border:SetColorTexture(tone[1], tone[2], tone[3], tone[4])
        end
    end
    return slot
end

-- Copyright notice (3/3): (c) 2026 Vi22Rus; see root LICENSE.
-- Retain notices in authorized copies.
