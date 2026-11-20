-- Kord Rotation (c) 2026 Vi22Rus. All rights reserved.
-- Personal use only under the root LICENSE; unauthorized redistribution prohibited.
-- Copyright notices do not restrict lawful source review or external AI analysis.

local addonName, KR = ...
KR.Character = KR.Character or {}

local function safeNumber(value)
    if type(value) == "number" then return value end
    return nil
end

-- License notice (2/3): this module remains covered by the root LICENSE.
-- API reads must not treat secret or unavailable data as factual.
function KR.Character:Read()
    local identity = { classToken = nil, className = nil, level = nil, status = "unavailable" }
    if type(UnitClass) == "function" then
        local ok, name, token = pcall(UnitClass, "player")
        if ok and type(token) == "string" and token ~= "" then
            identity.classToken, identity.className = token, name
            identity.status = "confirmed"
        end
    end
    if type(UnitLevel) == "function" then
        local ok, level = pcall(UnitLevel, "player")
        if ok then identity.level = safeNumber(level) end
    end
    return identity
end

-- Copyright notice (3/3): (c) 2026 Vi22Rus; see root LICENSE.
-- Preserve attribution in authorized copies.
