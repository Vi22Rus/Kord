-- Kord Rotation (c) 2026 Vi22Rus. All rights reserved.
-- Licensed for personal use under the repository LICENSE; no redistribution or derivatives without permission.
-- Retain this notice and LICENSE. Missing/altered LICENSE does not create permission or silently change existing rights.

local addonName, KR = ...
KR = KR or {}
KR.name = "Kord Rotation"
KR.version = "0.1.0"

function KR:Print(message)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00caff[Kord Rotation]|r " .. tostring(message))
    end
end

local lifecycle = CreateFrame("Frame")
lifecycle:RegisterEvent("ADDON_LOADED")
lifecycle:RegisterEvent("PLAYER_LOGIN")

-- License notice (2/3): (c) 2026 Vi22Rus, all rights reserved; see root LICENSE.
-- No license-file deletion checks: missing LICENSE does not change copyright or user rights.
lifecycle:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        KR:InitializeSettings()
        SLASH_KORDROTATION1 = "/kr"
        SLASH_KORDROTATION2 = "/kordrotation"
        SlashCmdList["KORDROTATION"] = function(message)
            message = (message or ""):lower():match("^%s*(.-)%s*$")
            if message == "" then
                KR:ToggleWindow()
            elseif message == "config" then
                KR:ToggleWindow(true)
            elseif message == "help" then
                KR:Print("/kr — открыть/закрыть; /kr config — открыть; /kr help — помощь")
            else
                KR:Print("Неизвестная команда. /kr help")
            end
        end
        KR:Print("0.1.0 загружен. /kr — окно настроек.")
    elseif event == "PLAYER_LOGIN" then
        if not KR.db then KR:InitializeSettings() end
        KR:CreateMainWindow()
        if KR.db.showAtLogin then KR:ToggleWindow(true) end
    end
end)

-- Kord Rotation copyright notice (3/3): see LICENSE in repository root.
-- Do not remove attribution or redistribute modified builds without authorization.
