-- Kord Rotation (c) 2026 Vi22Rus. All rights reserved.
-- Personal use is permitted only under the root LICENSE. Do not redistribute derivative builds.
-- Missing/altered LICENSE does not grant permission or disable this addon.

local addonName, KR = ...
KR.SpellCatalogue = KR.SpellCatalogue or {}

local function safeCall(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, a, b, c, d, e = pcall(fn, ...)
    if ok then return a, b, c, d, e end
    return nil
end

-- Licence notice (2/3): this adapter contains no copied or invented spell catalogue.
-- It reads only the player's spellbook when the client's public API supports it.
function KR.SpellCatalogue:Read()
    local result = {status = "unavailable", reason = "spellbook_api_missing", entries = {}}
    if type(GetNumSpellTabs) ~= "function" or type(GetSpellTabInfo) ~= "function"
        or type(GetSpellBookItemInfo) ~= "function" then return result end
    local numTabs = safeCall(GetNumSpellTabs)
    if type(numTabs) ~= "number" or numTabs < 1 then
        result.reason = "spellbook_tabs_missing"
        return result
    end
    local bookType = BOOKTYPE_SPELL or "spell"
    local found = {}
    for tab = 1, math.min(numTabs, 25) do
        local _, _, offset, count = safeCall(GetSpellTabInfo, tab)
        if type(offset) == "number" and type(count) == "number" then
            for slot = offset + 1, offset + math.min(count, 450) do
                local itemType, spellID = safeCall(GetSpellBookItemInfo, slot, bookType)
                if itemType == "SPELL" and type(spellID) == "number" and spellID > 0 then
                    if not found[spellID] then
                        local name = safeCall(GetSpellBookItemName, slot, bookType)
                        if not name and type(GetSpellInfo) == "function" then
                            name = safeCall(GetSpellInfo, spellID)
                        end
                        local icon
                        if type(GetSpellBookItemTexture) == "function" then
                            icon = safeCall(GetSpellBookItemTexture, slot, bookType)
                        end
                        if not icon and type(GetSpellTexture) == "function" then
                            icon = safeCall(GetSpellTexture, spellID)
                        end
                        if type(name) == "string" and name ~= "" then
                            result.entries[#result.entries+1] = {
                                id = spellID, name = name, texture = icon,
                            }
                            found[spellID] = true
                        end
                    end
                end
            end
        end
    end
    table.sort(result.entries, function(a,b)
        if a.name ~= b.name then return a.name < b.name end
        return a.id < b.id
    end)
    result.status = "ready"
    result.reason = #result.entries == 0 and "spellbook_empty" or nil
    return result
end

function KR.SpellCatalogue:Filter(entries, query, category, profile)
    local matched = {}
    query = type(query) == "string" and string.lower(query) or ""
    for _, item in ipairs(entries or {}) do
        local record = profile and profile.spells and profile.spells[item.id] or nil
        local classified = record and record.category or "unclassified"
        local sameCategory = category == "all" or category == classified
        local name = type(item.name) == "string" and string.lower(item.name) or ""
        local sameQuery = query == "" or string.find(name, query, 1, true)
            or string.find(tostring(item.id), query, 1, true)
        if sameCategory and sameQuery then matched[#matched+1] = item end
    end
    return matched
end

-- Kord Rotation copyright notice (3/3): see LICENSE in the repository root.
-- Retain ownership notices in authorized copies.
