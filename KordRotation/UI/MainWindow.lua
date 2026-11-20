-- Kord Rotation (c) 2026 Vi22Rus. All rights reserved.
-- Licensed for personal use under the repository LICENSE; no redistribution or derivatives without permission.
-- Retain this notice and LICENSE. Missing/altered LICENSE does not create permission or silently change existing rights.

local addonName, KR = ...
local UI = KR.UI
local C = UI.colors

local menu = {
    { "HOME", "home" },
    { "DISPLAY", "display" },
    { "ROTATION", "rotation" },
    { "ABILITIES", "abilities" },
    { "INDICATORS", "indicators" },
    { "PROFILES", "profiles" },
    { "ADVANCED", "advanced" },
    { "DIAGNOSTICS", "diagnostics" },
    { "ABOUT", "about" },
}

local function setText(parent, value, x, y, font, color, width)
    local label = UI:Label(parent, value, font, color or C.text)
    label:SetPoint("TOPLEFT", x, y)
    if width then label:SetWidth(width); label:SetWordWrap(true) end
    return label
end

local function makeCard(parent, top, height)
    local card = CreateFrame("Frame", nil, parent)
    card:SetPoint("TOPLEFT", parent, "TOPLEFT", 18, top)
    card:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -18, top)
    card:SetHeight(height)
    UI:Background(card, C.panel)
    UI:Border(card, C.line, 1)
    return card
end

local function makeHome(parent)
    local scroll = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 5, -7)
    scroll:SetPoint("BOTTOMRIGHT", -27, 6)
    local body = CreateFrame("Frame", nil, scroll)
    body:SetSize(565, 775)
    scroll:SetScrollChild(body)
    parent = body
    local card = makeCard(parent, -19, 190)
    local logoPane = CreateFrame("Frame", nil, card)
    logoPane:SetPoint("TOPLEFT", 16, -14)
    logoPane:SetSize(205, 156)
    UI:Background(logoPane, C.sidebar)
    UI:Border(logoPane, C.line, 1)

    -- Approved KR artwork, pre-encoded as a WoW BLP2 texture.
    -- Keep the asset at Media/Logo.blp; JPEG is not a valid WoW UI texture.
    local logo = logoPane:CreateTexture(nil, "ARTWORK")
    logo:SetTexture("Interface\\AddOns\\KordRotation\\Media\\Logo.blp")
    logo:SetPoint("CENTER", logoPane, "CENTER", 0, 0)
    logo:SetSize(136, 136)
    logo:SetTexCoord(0, 1, 0, 1)

    setText(card, "Kord Rotation", 241, -25, "title", C.text, 355)
    setText(card, "World of Warcraft Forever", 241, -60, nil, C.cyan, 355)
    setText(card, KR:L("DESCRIPTION"), 241, -91, nil, C.muted, 340)

    local status = makeCard(parent, -213, 136)
    setText(status, KR:L("PROJECT_STATUS"), 16, -17, "title", C.text, 460)
    setText(status, KR:Format("VERSION_STATUS", KR.version), 16, -52, nil, C.cyan, 440)
    KR.homeIdentityLabel = setText(status, KR:L("IDENTITY_PENDING"), 16, -74, nil, C.muted, 535)
    KR.homeTalentsLabel = setText(status, KR:L("IDENTITY_PENDING"), 16, -96, nil, C.muted, 535)
    KR.homeProfileLabel = setText(status, KR:L("PROFILE_NOT_IMPLEMENTED"), 16, -116, nil, C.muted, 535)

    local footer = makeCard(parent, -356, 120)
    setText(footer, KR:L("HELP"), 16, -11, "title", C.text, 430)
    setText(footer, KR:L("HOME_COMMANDS"), 16, -41, nil, C.muted, 475)
    local actions = {
        { "PANEL_TEST_ON", "PANEL_TEST_OFF", function() KR.RotationDisplay:ToggleTest() end },
        { "PANEL_UNLOCK", "PANEL_LOCK", function() KR.RotationDisplay:ToggleLock() end },
        { "PANEL_RESET", nil, function() KR.RotationDisplay:ResetPosition() end },
    }
    KR.panelButtons = {}
    for i, action in ipairs(actions) do
        local b = CreateFrame("Button", nil, footer, "UIPanelButtonTemplate")
        b:SetSize(162, 27)
        b:SetPoint("TOPLEFT", 11 + (i-1)*169, -76)
        b:SetScript("OnClick", action[3])
        KR.panelButtons[i] = b
    end
    local quick = makeCard(parent, -494, 259)
    setText(quick, KR:L("HOME_QUICK_TITLE"), 16, -12, "title", C.text, 500)
    setText(quick, KR:L("HOME_QUICK_NOTE"), 16, -42, nil, C.muted, 510)
    KR.homeQuickRows = {}
    local actions = {
        {"HOME_ENABLE_RECOMMENDATIONS", "rotationEnabled"},
        {"DISPLAY_SHOW_PANEL", "showPanel"},
        {"DISPLAY_TEST_MODE", "testMode"},
        {"DISPLAY_PANEL_LOCK", "locked"},
    }
    for i, item in ipairs(actions) do
        local key = item[2]
        local useRotation = key == "rotationEnabled"
        local row = UI:ToggleRow(quick, item[1], 12, -66-(i-1)*41, 510,
            function()
                if useRotation then return KR.RotationSettings:GetFlag("enabled") or false end
                return KR:GetPanelFlag(key)
            end,
            function(value)
                if useRotation then KR.RotationSettings:SetFlag("enabled",value)
                else KR:SetPanelFlag(key,value) end
            end)
        KR.homeQuickRows[#KR.homeQuickRows+1] = row
    end
    local jump = CreateFrame("Button",nil,quick,"UIPanelButtonTemplate")
    jump:SetSize(202,26)
    jump:SetPoint("TOPRIGHT",-16,-222)
    jump:SetText(KR:L("HOME_GO_DISPLAY"))
    jump:SetScript("OnClick",function() KR:SelectPage("display") end)
    KR:UpdatePanelControls()
end

local function makePlanned(parent, name)
    local card = makeCard(parent, -19, 178)
    setText(card, name, 23, -24, "title", C.text, 450)
    setText(card, KR:L("PLANNED"), 23, -65, nil, C.cyan, 480)
    setText(card, KR:L("PLANNED_MORE"), 23, -101, nil, C.muted, 480)
end

-- Home test-mode controls share the same API as slash commands; no fake live queue.
function KR:UpdatePanelControls()
    local btn = self.panelButtons
    if not btn or not self.db then return end
    local p = self.db.panel or {}
    btn[1]:SetText(self:L(p.testMode and "PANEL_TEST_OFF" or "PANEL_TEST_ON"))
    btn[2]:SetText(self:L(p.locked ~= false and "PANEL_UNLOCK" or "PANEL_LOCK"))
    btn[3]:SetText(self:L("PANEL_RESET"))
    for _, row in ipairs(self.displayRows or {}) do row:Refresh() end
    for _, row in ipairs(self.homeQuickRows or {}) do row:Refresh() end
    if self.displayPositionLabel then
        local x, y = tonumber(p.x) or 0, tonumber(p.y) or -120
        self.displayPositionLabel:SetText(self:Format("DISPLAY_POSITION_VALUES",
            math.floor(x + 0.5), math.floor(y + 0.5)))
    end
end

-- Functional display-page toggles (layout/alpha controls follow in 0.1.4).
local function makeDisplay(parent)
    local scroll = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", parent, "TOPLEFT", 5, -7)
    scroll:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -27, 6)
    local body = CreateFrame("Frame", nil, scroll)
    body:SetSize(565, 2190)
    scroll:SetScrollChild(body)

    local control = makeCard(body, -16, 228)
    setText(control, KR:L("DISPLAY_PANEL_TITLE"), 17, -16, "title", C.text, 510)
    setText(control, KR:L("DISPLAY_PANEL_NOTE"), 17, -45, nil, C.muted, 507)
    local flags = {
        {"DISPLAY_SHOW_PANEL", "showPanel"},
        {"DISPLAY_TEST_MODE", "testMode"},
        {"DISPLAY_PANEL_LOCK", "locked"},
        {"LAYOUT_NUMBERS", "showNumbers"},
    }
    KR.displayRows = {}
    for i, item in ipairs(flags) do
        local key = item[2]
        local isPanelFlag = key == "showPanel" or key == "testMode" or key == "locked"
        KR.displayRows[#KR.displayRows+1] = UI:ToggleRow(control, item[1],
            15, -67-(i-1)*39, 510,
            function()
                if isPanelFlag then return KR:GetPanelFlag(key) end
                return KR:GetPanelLayout(key)
            end,
            function(value)
                if isPanelFlag then KR:SetPanelFlag(key, value)
                else KR:SetPanelLayout(key, value) end
            end)
    end

    local layout = makeCard(body, -261, 404)
    setText(layout, KR:L("LAYOUT_TITLE"), 17, -16, "title", C.text, 510)
    local rows = {
        {"LAYOUT_COUNT","slotCount",1},
        {"LAYOUT_MAIN_SIZE","primarySize",4},
        {"LAYOUT_OTHER_SIZE","secondarySize",4},
        {"LAYOUT_GAP","gap",1},
        {"LAYOUT_SCALE","scale",5},
        {"LAYOUT_ALPHA","alpha",5},
        {"LAYOUT_OTHER_ALPHA","secondaryAlpha",5},
    }
    for i, item in ipairs(rows) do
        local key = item[2]
        local step = item[3]
        KR.displayRows[#KR.displayRows+1] = UI:StepRow(layout, item[1],
            15, -47-(i-1)*47, 510,
            function() return KR:GetPanelLayout(key) end,
            function(value) KR:SetPanelLayout(key, value) end, step)
    end

    local options = makeCard(body, -683, 317)
    setText(options, KR:L("LAYOUT_DIRECTION_TITLE"), 17, -16, "title", C.text, 510)
    local choices = {
        {"LAYOUT_DIRECTION","direction",{{"horizontal","LAYOUT_HORIZONTAL"},{"vertical","LAYOUT_VERTICAL"}}},
        {"LAYOUT_FIRST_LAST","primaryAtEnd",{{false,"LAYOUT_MAIN_FIRST"},{true,"LAYOUT_MAIN_LAST"}}},
        {"LAYOUT_BORDER","borderStyle",{{"standard","LAYOUT_BORDER_STANDARD"},{"minimal","LAYOUT_BORDER_MINIMAL"},{"none","LAYOUT_BORDER_NONE"}}},
    }
    for i, entry in ipairs(choices) do
        local key = entry[2]
        KR.displayRows[#KR.displayRows+1] = UI:ChoiceRow(options, entry[1],
            15, -46-(i-1)*45, 510,
            function() return KR:GetPanelLayout(key) end,
            function(value) KR:SetPanelLayout(key, value) end, entry[3])
    end
    setText(options, KR:L("DISPLAY_POSITION_TITLE"), 17, -196, "title", C.text, 485)
    KR.displayPositionLabel = setText(options, KR:L("DISPLAY_POSITION_DEFAULT"),
        17, -221, nil, C.muted, 485)
    local reset = CreateFrame("Button", nil, options, "UIPanelButtonTemplate")
    reset:SetPoint("TOPLEFT", 16, -260)
    reset:SetSize(185, 28)
    reset:SetText(KR:L("PANEL_RESET"))
    reset:SetScript("OnClick", function()
        KR.RotationDisplay:ResetPosition()
        KR:UpdatePanelControls()
    end)
    local visibility = makeCard(body, -1015, 267)
    setText(visibility, KR:L("DISPLAY_VISIBILITY_TITLE"), 17, -16, "title", C.text, 510)
    local flags = {
        {"DISPLAY_IN_COMBAT", "showInCombat"},
        {"DISPLAY_OUT_COMBAT", "showOutOfCombat"},
        {"DISPLAY_TARGET_REQUIRED", "requireTarget"},
        {"DISPLAY_HIDE_DEAD", "hideWhenDead"},
        {"DISPLAY_HIDE_MOUNTED", "hideMounted"},
    }
    for i,item in ipairs(flags) do
        local key = item[2]
        KR.displayRows[#KR.displayRows+1] = UI:ToggleRow(visibility,item[1],15,
            -43-(i-1)*43,510,
            function()return KR:GetPanelFlag(key)end,
            function(value)KR:SetPanelFlag(key,value)end)
    end

    local layers = makeCard(body, -1305, 415)
    setText(layers, KR:L("LAYER_TITLE"), 17, -16, "title", C.text, 510)
    setText(layers, KR:L("LAYER_NOTE"), 17, -47, nil, C.muted, 510)
    local layerRows = {
        {"LAYER_BACKGROUND","showIconBackground"},
        {"LAYER_KEYBIND","showKeybind"},
        {"LAYER_SPELL_NAME","showSpellName"},
        {"LAYER_COOLDOWN","showCooldown"},
        {"LAYER_CHARGES","showCharges"},
        {"LAYER_UNAVAILABLE","showUnavailable"},
        {"LAYER_GCD","showGCD"},
    }
    for i, entry in ipairs(layerRows) do
        local key = entry[2]
        KR.displayRows[#KR.displayRows+1] = UI:ToggleRow(layers,entry[1],
            15,-71-(i-1)*41,510,
            function() return KR:GetPanelLayout(key) end,
            function(value) KR:SetPanelLayout(key,value) end)
    end
    KR.displayRows[#KR.displayRows+1] = UI:StepRow(layers,"LAYER_FONT_SIZE",
        15,-366,510,
        function() return KR:GetPanelLayout("textSize") end,
        function(value) KR:SetPanelLayout("textSize",value) end,1)

    local style=makeCard(body,-1740,397)
    setText(style,KR:L("STYLE_TITLE"),17,-14,"title",C.text,510)
    local rows={
        {"STYLE_BACKGROUND_ALPHA","backgroundAlpha",5},
        {"STYLE_BORDER_THICKNESS","borderThickness",1},
        {"STYLE_HIGHLIGHT_STRENGTH","highlightStrength",5},
    }
    for i,item in ipairs(rows) do
        local key=item[2]
        KR.displayRows[#KR.displayRows+1]=UI:StepRow(style,item[1],
            13,-47-(i-1)*43,505,
            function()return KR:GetPanelLayout(key)end,
            function(v)KR:SetPanelLayout(key,v)end,item[3])
    end
    KR.displayRows[#KR.displayRows+1]=UI:ToggleRow(style,"STYLE_HIGHLIGHT",
        13,-177,505,function()return KR:GetPanelLayout("highlightMain")end,
        function(v)KR:SetPanelLayout("highlightMain",v)end)
    local palette={{"cyan","STYLE_CYAN"},{"gold","STYLE_GOLD"},{"white","STYLE_WHITE"}}
    KR.displayRows[#KR.displayRows+1]=UI:ChoiceRow(style,"STYLE_HIGHLIGHT_COLOR",
        13,-220,505,function()return KR:GetPanelLayout("highlightColor")end,
        function(v)KR:SetPanelLayout("highlightColor",v)end,palette)
    KR.displayRows[#KR.displayRows+1]=UI:ChoiceRow(style,"STYLE_TEXT_COLOR",
        13,-263,505,function()return KR:GetPanelLayout("textColor")end,
        function(v)KR:SetPanelLayout("textColor",v)end,palette)
    local positions={{"standard","STYLE_STANDARD"},{"centered","STYLE_CENTERED"}}
    KR.displayRows[#KR.displayRows+1]=UI:ChoiceRow(style,"STYLE_TEXT_POSITION",
        13,-306,505,function()return KR:GetPanelLayout("textPlacement")end,
        function(v)KR:SetPanelLayout("textPlacement",v)end,positions)
    KR.displayRows[#KR.displayRows+1]=UI:ToggleRow(style,"STYLE_TEXT_SHADOW",
        13,-349,505,function()return KR:GetPanelLayout("textShadow")end,
        function(v)KR:SetPanelLayout("textShadow",v)end)
end

function KR:CreateMainWindow()
    if self.mainWindow then return self.mainWindow end
    local db = self:GetWindowSettings()
    local frame = CreateFrame("Frame", "KordRotationMainFrame", UIParent)
    frame:SetSize(db.width or 880, db.height or 570)
    frame:SetPoint(db.point or "CENTER", UIParent, db.point or "CENTER", db.x or 0, db.y or 0)
    frame:SetFrameStrata("DIALOG")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local _, _, point, x, y = self:GetPoint(1)
        db.point = "CENTER"
        -- Save center displacement regardless of selected anchor.
        local centerX, centerY = self:GetCenter()
        local screenX, screenY = UIParent:GetCenter()
        if centerX and screenX then
            db.x = centerX - screenX
            db.y = centerY - screenY
        end
    end)
    UI:Background(frame, C.background)
    UI:Border(frame, C.cyan, 2)

    local titlebar = CreateFrame("Frame", nil, frame)
    titlebar:SetPoint("TOPLEFT", 2, -2)
    titlebar:SetPoint("TOPRIGHT", -2, -2)
    titlebar:SetHeight(60)
    UI:Background(titlebar, C.sidebar)
    local title = setText(titlebar, "KORD ROTATION", 23, -15, "title", C.text, 420)
    local subtitle = setText(titlebar, "Modern Dark - "..KR.version, 25, -39, nil, C.cyan, 350)
    subtitle:SetFontObject("GameFontDisableSmall")

    local close = CreateFrame("Button", nil, titlebar, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", titlebar, "TOPRIGHT", -8, -7)
    close:SetScript("OnClick", function() frame:Hide() end)

    local sidebar = CreateFrame("Frame", nil, frame)
    sidebar:SetPoint("TOPLEFT", frame, "TOPLEFT", 11, -70)
    sidebar:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 11, 13)
    sidebar:SetWidth(197)
    UI:Background(sidebar, C.sidebar)
    UI:Border(sidebar, C.line, 1)

    local content = CreateFrame("Frame", nil, frame)
    content:SetPoint("TOPLEFT", sidebar, "TOPRIGHT", 11, 0)
    content:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -12, 13)
    UI:Background(content, C.background)
    UI:Border(content, C.line, 1)

    local pages, buttons = {}, {}
    for index, info in ipairs(menu) do
        local key, name = info[2], KR:L(info[1])
        local button = CreateFrame("Button", nil, sidebar)
        button:SetPoint("TOPLEFT", 10, -13 - (index - 1) * 51)
        button:SetPoint("TOPRIGHT", -10, -13 - (index - 1) * 51)
        button:SetHeight(43)
        button.bg = UI:Background(button, C.sidebar)
        button.label = setText(button, name, 15, -12, nil, C.muted, 159)
        buttons[key] = button

        local page = CreateFrame("Frame", nil, content)
        page:SetAllPoints(content)
        page:Hide()
        pages[key] = page

        -- Register all nine pages; build their contents on first selection only.
        if key == "home" then page.build = makeHome
        elseif key == "about" then page.build = function(container) KR.Pages:About(container) end
        elseif key == "diagnostics" then page.build = function(container) KR.Pages:Diagnostics(container) end
        elseif key == "display" then page.build = makeDisplay
        elseif key == "rotation" then page.build = function(container) KR.Pages:Rotation(container) end
        elseif key == "abilities" then page.build = function(container) KR.Pages:Abilities(container) end
        elseif key == "indicators" then page.build = function(container) KR.Pages:Indicators(container) end
        elseif key == "profiles" then page.build = function(container) KR.Pages:Profiles(container) end
        elseif key == "advanced" then page.build = function(container) KR.Pages:Advanced(container) end
        else
            local plannedName = name
            page.build = function(container) makePlanned(container, plannedName) end
        end

        button:SetScript("OnClick", function() KR:SelectPage(key) end)
    end

    self.mainWindow = frame
    self.pages = pages
    self.pageButtons = buttons
    self:UpdatePanelControls()
    self:SelectPage("home")
    self:RefreshCharacterUI()
    frame:Hide()
    return frame
end

function KR:SelectPage(key)
    if not self.pages or not self.pages[key] then return end
    local target = self.pages[key]
    if not target.initialized then
        target.build(target)
        target.initialized = true
        self:UpdatePanelControls()
        self:RefreshCharacterUI()
    end
    for pageKey, page in pairs(self.pages) do
        if pageKey == key then page:Show() else page:Hide() end
        local button = self.pageButtons[pageKey]
        local color = (pageKey == key) and C.panel or C.sidebar
        button.bg:SetColorTexture(color[1], color[2], color[3], color[4])
        local textColor = (pageKey == key) and C.cyan or C.muted
        button.label:SetTextColor(textColor[1], textColor[2], textColor[3], 1)
    end
    self.selectedPage = key
    -- Lazy pages may have changed while hidden; update on every selection.
    if target.refresh then target.refresh() end
end

-- Presents the last safely classified state; no combat rotation is started here.
function KR:RefreshCharacterUI()
    local s = self.characterState
    if not s then return end
    local c, t = s.character, s.talents
    local class = c.className or c.classToken or "—"
    local spec = s.index and self:GetLocalizedTree(s.classToken, s.index) or self:L("SPEC_UNKNOWN")
    local counts = t.counts and table.concat(t.counts, " / ") or self:L("NO_DATA")
    if self.homeIdentityLabel then
        self.homeIdentityLabel:SetText(self:Format("CHARACTER_LINE", class, spec, self:L("STATUS_"..s.status)))
    end
    if self.homeTalentsLabel then
        self.homeTalentsLabel:SetText(self:Format("HOME_TALENT_TOTAL", counts, self:L(t.method and "METHOD_"..t.method or "NOT_AVAILABLE")))
    end
    if self.homeProfileLabel then
        self.homeProfileLabel:SetText(self:Format("HOME_PROFILE_UNAVAILABLE", s.profileID or "-"))
    end
    if self.AppearanceProfiles and self.AppearanceProfiles.OnCharacterRefresh then
        self.AppearanceProfiles:OnCharacterRefresh()
    end
    if self.rotationPageRefresh then self.rotationPageRefresh() end
    if self.abilitiesPageRefresh then self.abilitiesPageRefresh() end
    if self.RefreshDiagnosticsPage then self:RefreshDiagnosticsPage() end
    local l = self.diagnosticLabels
    if l then
        local values = {
            self:L("CLASS")..": "..class.." ["..(c.classToken or "?").."]",
            self:L("LEVEL")..": "..tostring(c.level or "-"),
            self:L("CONFIG")..": "..tostring(t.configID or "-"),
            self:L("POINTS")..": "..counts,
            self:L("GROUP_METHOD")..": "..(t.method and self:L("METHOD_"..t.method) or "-"),
            self:L("LEADING_TREE")..": "..spec.." ["..(s.profileID or "-").."]",
            self:L("STATUS")..": "..self:L("STATUS_"..s.status),
            self:L("REASON")..": "..(s.reason and self:L("REASON_"..s.reason) or s.detection and self:L("REASON_"..s.detection) or "-"),
        }
        for i, value in ipairs(values) do l[i]:SetText(value) end
    end
end

function KR:ToggleWindow(forceOpen)
    local frame = self:CreateMainWindow()
    if forceOpen or not frame:IsShown() then frame:Show() else frame:Hide() end
end

-- Kord Rotation copyright notice (3/3): see LICENSE in repository root.
-- Do not remove attribution or redistribute modified builds without authorization.
