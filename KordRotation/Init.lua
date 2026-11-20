-- Kord Rotation (c) 2026 Vi22Rus. All rights reserved.
-- Licensed for personal use under the repository LICENSE; no redistribution or derivatives without permission.
-- Retain this notice and LICENSE. Missing/altered LICENSE does not create permission or silently change existing rights.

local addonName, KR = ...
KR = KR or {}
KR.name = "Kord Rotation"
KR.version = "0.1.7.4"

function KR:Print(message)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00caff[Kord Rotation]|r " .. tostring(message))
    end
end

local lifecycle = CreateFrame("Frame")
lifecycle:RegisterEvent("ADDON_LOADED")
lifecycle:RegisterEvent("PLAYER_LOGIN")
lifecycle:RegisterEvent("TRAIT_CONFIG_UPDATED")
lifecycle:RegisterEvent("PLAYER_TALENT_UPDATE")
lifecycle:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
lifecycle:RegisterEvent("PLAYER_LEVEL_UP")

-- License notice (2/3): (c) 2026 Vi22Rus, all rights reserved; see root LICENSE.
-- No license-file deletion checks: missing LICENSE does not change copyright or user rights.
lifecycle:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        KR:InitializeSettings()
        KR.IndicatorSettings:Initialize()
        KR.Advanced:Initialize()
        SLASH_KORDROTATION1 = "/kr"
        SLASH_KORDROTATION2 = "/kordrotation"
        SlashCmdList["KORDROTATION"] = function(message)
            message = (message or ""):lower():match("^%s*(.-)%s*$")
            if message == "" then
                KR:ToggleWindow()
            elseif message == "config" then
                KR:ToggleWindow(true)
            elseif message == "debug" then
                KR:RefreshCharacter("slash_debug")
                KR:ToggleWindow(true)
                KR:SelectPage("diagnostics")
            elseif message == "test" then
                local enabled = KR.RotationDisplay:ToggleTest()
                KR:Print(KR:L(enabled and "CHAT_TEST_ON" or "CHAT_TEST_OFF"))
            elseif message == "lock" then
                local locked = KR.RotationDisplay:ToggleLock()
                KR:Print(KR:L(locked and "CHAT_PANEL_LOCKED" or "CHAT_PANEL_UNLOCKED"))
            elseif message == "resetposition" then
                KR.RotationDisplay:ResetPosition()
                KR:Print(KR:L("CHAT_PANEL_RESET"))
            elseif message == "refresh" then
                local state = KR:RefreshCharacter("slash_refresh")
                KR:Print(KR:Format("CHAT_SUMMARY", tostring(state.classToken or "?"), state.index and KR:GetLocalizedTree(state.classToken, state.index) or KR:L("SPEC_UNKNOWN"), state.talents.counts and table.concat(state.talents.counts, "/") or "?", KR:L("STATUS_"..state.status)))
            elseif message == "help" then
                KR:Print(KR:L("CHAT_HELP"))
            else
                KR:Print(KR:L("CHAT_UNKNOWN"))
            end
        end
        if KR.Advanced:Get("showLoadMessage") then KR:Print(KR:Format("CHAT_LOADED", KR.version)) end
    elseif event == "PLAYER_LOGIN" then
        if not KR.db then KR:InitializeSettings() end
        KR:CreateMainWindow()
        KR.RotationDisplay:Create()
        KR:RefreshCharacter("PLAYER_LOGIN")
        if KR.db.showAtLogin then KR:ToggleWindow(true) end
    elseif event == "TRAIT_CONFIG_UPDATED" or event == "PLAYER_TALENT_UPDATE"
        or event == "ACTIVE_TALENT_GROUP_CHANGED" or event == "PLAYER_LEVEL_UP" then
        if KR.db then KR:RefreshCharacter(event) end
    end
end)

-- Kord Rotation copyright notice (3/3): see LICENSE in repository root.
-- Do not remove attribution or redistribute modified builds without authorization.
