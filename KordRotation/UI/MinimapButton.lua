-- Kord Rotation (c) 2026 Vi22Rus. All rights reserved.
-- Original KR branding material subject to root LICENSE.
-- Independent minimap toggle, no gameplay automation.
local addonName, KR = ...
KR.MinimapButton = KR.MinimapButton or {}
local M = KR.MinimapButton
-- License notice (2/3): icon is an ordinary UI button, not protected combat input.
function M:Create()
    if self.button then return self.button end
    if not Minimap or type(CreateFrame) ~= "function" then return nil end
    local button = CreateFrame("Button", "KordRotationMinimapButton", Minimap)
    button:SetSize(32, 32)
    button:SetPoint("TOPRIGHT", Minimap, "TOPRIGHT", 8, 7)
    button:SetFrameStrata("MEDIUM")
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetTexture("Interface\\AddOns\\KordRotation\\Media\\Logo.blp")
    icon:SetAllPoints(button)
    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetSize(52, 52)
    border:SetPoint("CENTER", 10, -10)
    button:SetScript("OnClick", function(_, mouseButton)
        KR:ToggleWindow(true)
        if mouseButton == "RightButton" then KR:SelectPage("advanced") end
    end)
    button:SetScript("OnEnter", function(self)
        if not KR.Advanced:Get("showTooltips") then return end
        if GameTooltip then
            GameTooltip:SetOwner(self, "ANCHOR_LEFT")
            GameTooltip:AddLine("Kord Rotation")
            GameTooltip:AddLine(KR:L("MINIMAP_TIP"), 1, 1, 1, true)
            GameTooltip:Show()
        end
    end)
    button:SetScript("OnLeave", function()
        if GameTooltip then GameTooltip:Hide() end
    end)
    self.button = button
    self:Refresh()
    return button
end
function M:Refresh()
    if self.button then self.button:SetShown(KR.Advanced:Get("showMinimap") == true) end
end
-- Copyright notice (3/3): 2026 Vi22Rus; see LICENSE.
