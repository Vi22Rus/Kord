-- Kord Rotation (c) 2026 Vi22Rus. All rights reserved.
-- Source code use subject to root LICENSE; no unauthorized derivative distribution.
-- Copyright remains in force if a copy lacks the LICENSE file.

local addonName, KR = ...
local UI, C = KR.UI, KR.UI.colors
KR.Pages = KR.Pages or {}
local S = KR.RotationSettings

local function label(parent, key, x, y, width, isTitle)
    local text = UI:Label(parent, KR:L(key), isTitle and "title" or nil, isTitle and C.text or C.muted)
    text:SetPoint("TOPLEFT", x, y)
    text:SetWidth(width or 500)
    text:SetWordWrap(true)
    return text
end

local function rawLabel(parent, x, y, width)
    local text = UI:Label(parent, "", nil, C.text)
    text:SetPoint("TOPLEFT", x, y)
    text:SetWidth(width or 500)
    text:SetWordWrap(true)
    return text
end

local function card(parent, y, height)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetPoint("TOPLEFT", 15, y)
    frame:SetPoint("TOPRIGHT", -15, y)
    frame:SetHeight(height)
    UI:Background(frame, C.panel)
    UI:Border(frame, C.line, 1)
    return frame
end

local function scroller(parent, height)
    local scroll = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 5, -7)
    scroll:SetPoint("BOTTOMRIGHT", -27, 6)
    local body = CreateFrame("Frame", nil, scroll)
    body:SetSize(560, height)
    scroll:SetScrollChild(body)
    return body
end

local function button(parent, x, y, width, key, action)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetSize(width, 26)
    b:SetPoint("TOPLEFT", x, y)
    b:SetText(KR:L(key))
    b:SetScript("OnClick", action)
    b:SetScript("OnEnter",function(self) UI:ShowSettingTip(self,key) end)
    b:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
    return b
end

local function profileRead()
    return S:GetProfile(true)
end

local function categoryLabel(category)
    return KR:L(category == "unclassified" and "SPELL_FILTER_UNCLASSIFIED" or "ROT_CAT_" .. string.upper(category))
end

local modeOptions = {
    {"auto", "ROT_TARGET_AUTO"},
    {"single", "ROT_TARGET_SINGLE"},
    {"aoe", "ROT_TARGET_AOE"},
}

-- License notice (2/3): UI-only settings editor, never executes or auto-casts abilities.
-- An unavailable class/tree must never be mistaken for a valid profile.
function KR.Pages:Rotation(parent)
    local body = scroller(parent, 1070)
    local summary = card(body, -14, 158)
    label(summary, "ROT_PROFILE_TITLE", 16, -14, 500, true)
    local status = rawLabel(summary, 16, -48, 510)
    local notes = label(summary, "ROT_PROFILE_UNAVAILABLE", 16, -89, 510)
    local enableRow = UI:ToggleRow(summary, "ROT_PREFERENCE_ENABLE", 12, -108, 500,
        function() return S:GetFlag("enabled") or false end,
        function(value) S:SetFlag("enabled", value) end)

    local target = card(body, -189, 155)
    label(target, "ROT_TARGET_TITLE", 16, -14, 510, true)
    local mode = UI:ChoiceRow(target, "ROT_TARGET_LABEL", 12, -49, 500,
        function() return S:GetTargetMode() end,
        function(value) S:SetTargetMode(value) end,
        modeOptions)
    label(target, "ROT_TARGET_WARNING", 16, -104, 506)

    local cat = card(body, -361, 450)
    label(cat, "ROT_CATEGORIES_TITLE", 16, -14, 510, true)
    local catRows = {}
    for i, name in ipairs(S:Categories()) do
        local category = name
        catRows[#catRows+1] = UI:ToggleRow(cat, "ROT_CAT_"..string.upper(name),
            12, -42-(i-1)*43, 500,
            function() return S:GetCategory(category) or false end,
            function(value) S:SetCategory(category, value) end)
    end

    local conditions = card(body, -829, 226)
    label(conditions, "ROT_CONDITIONS_TITLE", 16, -13, 510, true)
    local options = {
        {"ROT_ONLY_COMBAT", "cooldownsOnlyInCombat"},
        {"ROT_SAVE_RESOURCES", "conserveResources"},
        {"ROT_PREBUFFS", "prebuffs"},
    }
    local rows = {}
    for i, item in ipairs(options) do
        local option = item[2]
        rows[#rows+1] = UI:ToggleRow(conditions, item[1], 12, -41-(i-1)*43, 500,
            function() return S:GetFlag(option) end,
            function(value) S:SetFlag(option, value) end)
    end
    local experimentalRow = UI:ToggleRow(conditions, "ROT_EXPERIMENTAL_OPTIN",
        12, -172, 500,
        function() return S:GetFlag("allowUnverifiedProfiles") or false end,
        function(value) S:SetFlag("allowUnverifiedProfiles", value) end)
    local function refresh()
        local p, id = profileRead()
        local state = KR.characterState
        local counts = state and state.talents and state.talents.counts
        local total = counts and table.concat(counts, "/") or "-"
        if p then
            status:SetText(KR:Format("ROT_PROFILE_SUMMARY", id, total))
            notes:SetText(KR:L("ROT_PROFILE_UNAVAILABLE"))
        else
            status:SetText(KR:L("ROT_NO_PROFILE"))
            notes:SetText(KR:L("ROT_PROFILE_UNAVAILABLE"))
        end
        enableRow:SetEnabled(p ~= nil)
        enableRow:Refresh()
        mode:SetEnabled(p ~= nil)
        for _, row in ipairs(catRows) do row:SetEnabled(p ~= nil) end
        for _, row in ipairs(rows) do row:SetEnabled(p ~= nil) end
        experimentalRow:SetEnabled(p ~= nil)
        experimentalRow:Refresh()
        mode:Refresh()
        for _, row in ipairs(catRows) do row:Refresh() end
        for _, row in ipairs(rows) do row:Refresh() end
    end
    KR.rotationPageRefresh = refresh
    refresh()
end

local filterValues = {
    {"all","SPELL_FILTER_ALL"},
    {"unclassified","SPELL_FILTER_UNCLASSIFIED"},
    {"damage","ROT_CAT_DAMAGE"},
    {"cooldowns","ROT_CAT_COOLDOWNS"},
    {"buffs","ROT_CAT_BUFFS"},
    {"defensive","ROT_CAT_DEFENSIVE"},
    {"interrupts","ROT_CAT_INTERRUPTS"},
    {"movement","ROT_CAT_MOVEMENT"},
    {"racial","ROT_CAT_RACIAL"},
    {"trinkets","ROT_CAT_TRINKETS"},
    {"consumables","ROT_CAT_CONSUMABLES"},
}
local spellCategories = {
    {"unclassified","SPELL_FILTER_UNCLASSIFIED"},
    {"damage","ROT_CAT_DAMAGE"},
    {"cooldowns","ROT_CAT_COOLDOWNS"},
    {"buffs","ROT_CAT_BUFFS"},
    {"racial","ROT_CAT_RACIAL"},
    {"trinkets","ROT_CAT_TRINKETS"},
    {"consumables","ROT_CAT_CONSUMABLES"},
    {"defensive","ROT_CAT_DEFENSIVE"},
    {"interrupts","ROT_CAT_INTERRUPTS"},
    {"movement","ROT_CAT_MOVEMENT"},
}

function KR.Pages:Abilities(parent)
    local body = scroller(parent, 880)
    local header = card(body, -14, 166)
    label(header, "SPELL_TITLE", 16, -14, 500, true)
    local hint = label(header, "SPELL_UNAVAILABLE", 16, -45, 510)
    label(header, "SPELL_SEARCH_HINT", 20, -71, 500)
    local search = CreateFrame("EditBox", nil, header, "InputBoxTemplate")
    search:SetPoint("TOPLEFT", 21, -91)
    search:SetSize(284, 26)
    search:SetAutoFocus(false)
    search:SetMaxLetters(70)
    search:SetScript("OnEnter",function(self) UI:ShowSettingTip(self,"SPELL_SEARCH_HINT") end)
    search:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
    local filter = "all"
    local query = ""
    local chosenID
    local collection = {entries={},status="unavailable"}

    local list = card(body, -198, 408)
    label(list, "SPELL_LIST_TITLE", 16, -14, 500, true)
    local rows, page = {}, 0
    local detail = card(body, -624, 238)
    label(detail, "SPELL_DETAILS_TITLE", 16, -14, 510, true)
    local info = rawLabel(detail, 16, -42, 520)
    local categoryButton = button(detail, 16, -74, 220, "SPELL_CHANGE_CATEGORY", function() end)
    local toggleButton = button(detail, 246, -74, 230, "SPELL_TOGGLE", function() end)
    local separateButton = button(detail, 16, -108, 220, "SPELL_SEPARATE", function() end)
    local reset = button(detail, 246, -108, 230, "SPELL_RESET", function() end)
    label(detail, "SPELL_KEY_LABEL", 16, -154, 210)
    local keyEdit = CreateFrame("EditBox", nil, detail, "InputBoxTemplate")
    keyEdit:SetPoint("TOPLEFT", 223, -144)
    keyEdit:SetSize(218, 25)
    keyEdit:SetMaxLetters(32)
    keyEdit:SetAutoFocus(false)
    keyEdit:SetScript("OnEnter",function(self) UI:ShowSettingTip(self,"SPELL_KEY_LABEL") end)
    keyEdit:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)

    local filtered = {}
    local function refreshDetail()
        local profile = profileRead()
        local item
        for _, entry in ipairs(collection.entries) do
            if chosenID == entry.id then item = entry; break end
        end
        local available = item ~= nil and profile ~= nil
        categoryButton:SetEnabled(available)
        toggleButton:SetEnabled(available)
        separateButton:SetEnabled(available)
        reset:SetEnabled(available)
        keyEdit:SetEnabled(available)
        if not available then
            info:SetText(KR:L("SPELL_NOT_SELECTED"))
            keyEdit:SetText("")
            return
        end
        local override = S:GetSpell(chosenID) or {}
        local category = override.category or "unclassified"
        info:SetText(KR:Format("SPELL_DETAIL_LINE", (item.displayName or item.name), chosenID, categoryLabel(category)))
        categoryButton:SetText(KR:Format("SPELL_CATEGORY_BUTTON", categoryLabel(category)))
        toggleButton:SetText(KR:L(override.enabled == false and "SPELL_ENABLE" or "SPELL_DISABLE"))
        separateButton:SetText(KR:L(override.separate and "SPELL_UNSEPARATE" or "SPELL_SEPARATE"))
        keyEdit:SetText(override.keyLabel or "")
    end

    local function refreshList()
        local profile = profileRead()
        filtered = KR.SpellCatalogue:Filter(collection.entries, query, filter, profile)
        local pages = math.max(1, math.ceil(#filtered / 7))
        page = math.max(0, math.min(page, pages-1))
        for index, row in ipairs(rows) do
            local item = filtered[page * 7 + index]
            row.data = item
            if item then
                row.text:SetText(KR:Format("SPELL_ROW", (item.displayName or item.name), item.id))
                if item.texture then row.icon:SetTexture(item.texture)
                else row.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark") end
                row:Show()
            else row:Hide() end
        end
        if collection.status ~= "ready" then
            hint:SetText(KR:L("SPELL_UNAVAILABLE"))
        elseif #collection.entries == 0 then
            hint:SetText(KR:L("SPELL_EMPTY"))
        else
            hint:SetText(KR:Format("SPELL_LIST_STATUS", #filtered, #collection.entries))
        end
        refreshDetail()
    end

    for i=1,7 do
        local row = CreateFrame("Button", nil, list)
        row:SetPoint("TOPLEFT", 15, -43-(i-1)*44)
        row:SetSize(502, 39)
        UI:Background(row, C.sidebar)
        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetPoint("LEFT", 6, 0)
        row.icon:SetSize(32,32)
        row.text = UI:Label(row, "", nil, C.text)
        row.text:SetPoint("LEFT", 45, 0)
        row.text:SetWidth(452)
        row:SetScript("OnEnter",function(self) UI:ShowSettingTip(self,"SPELL_LIST_TITLE") end)
    row:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
        row:SetScript("OnClick", function()
            if row.data then chosenID = row.data.id; refreshDetail() end
        end)
        rows[#rows+1] = row
    end

    local filterButton
    filterButton = button(header, 324, -91, 194, "SPELL_FILTER_ALL", function()
        for i, entry in ipairs(filterValues) do
            if entry[1] == filter then
                local nextItem = filterValues[i % #filterValues + 1]
                filter = nextItem[1]
                filterButton:SetText(KR:L(nextItem[2]))
                page=0
                refreshList()
                return
            end
        end
    end)
    search:SetScript("OnTextChanged", function(self)
        query = self:GetText() or ""
        page=0
        refreshList()
    end)
    search:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    search:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)

    button(list, 15, -362, 122, "SPELL_PREVIOUS", function()
        page=math.max(0,page-1); refreshList()
    end)
    button(list, 152, -362, 122, "SPELL_NEXT", function()
        page=page+1; refreshList()
    end)
    button(list, 292, -362, 200, "SPELL_RESCAN", function()
        collection=KR.SpellCatalogue:Read()
        chosenID=nil
        page=0
        refreshList()
    end)
    categoryButton:SetScript("OnClick", function()
        if not chosenID then return end
        local current = (S:GetSpell(chosenID) or {}).category or "unclassified"
        for i, value in ipairs(spellCategories) do
            if value[1] == current then
                local nextValue=spellCategories[i % #spellCategories+1][1]
                S:SetSpell(chosenID,"category",nextValue == "unclassified" and nil or nextValue)
                refreshList()
                return
            end
        end
    end)
    toggleButton:SetScript("OnClick", function()
        if chosenID then
            local setting = S:GetSpell(chosenID) or {}
            S:SetSpell(chosenID,"enabled",setting.enabled == false)
            refreshDetail()
        end
    end)
    separateButton:SetScript("OnClick", function()
        if chosenID then
            local setting=S:GetSpell(chosenID) or {}
            S:SetSpell(chosenID,"separate",not setting.separate)
            refreshDetail()
        end
    end)
    reset:SetScript("OnClick", function()
        if chosenID then S:ResetSpell(chosenID); refreshList() end
    end)
    keyEdit:SetScript("OnEnterPressed", function(self)
        if chosenID then S:SetSpell(chosenID,"keyLabel",self:GetText() or "") end
        self:ClearFocus()
    end)
    keyEdit:SetScript("OnEscapePressed", function(self) self:ClearFocus(); refreshDetail() end)

    local function refresh()
        collection = KR.SpellCatalogue:Read()
        chosenID=nil
        page=0
        refreshList()
    end
    KR.abilitiesPageRefresh = refresh
    refresh()
end

-- Copyright notice (3/3): (c) 2026 Vi22Rus. See repository LICENSE.
-- Retain attribution in authorized copies.
