-- Kord Rotation (c) 2026 Vi22Rus. All rights reserved.
-- Licensed for personal use under the repository LICENSE; no redistribution or derivatives without permission.
-- Retain this notice and LICENSE. Missing/altered LICENSE does not create permission or silently change existing rights.

local addonName, KR = ...
local UI = KR.UI
local C = UI.colors

local menu = {
    { "Главная", "home" },
    { "Отображение", "display" },
    { "Ротация", "rotation" },
    { "Способности", "abilities" },
    { "Индикаторы", "indicators" },
    { "Профили", "profiles" },
    { "Дополнительно", "advanced" },
    { "Диагностика", "diagnostics" },
    { "О проекте", "about" },
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
    local card = makeCard(parent, -19, 190)
    local logoPane = CreateFrame("Frame", nil, card)
    logoPane:SetPoint("TOPLEFT", 16, -14)
    logoPane:SetSize(205, 156)
    UI:Background(logoPane, C.sidebar)
    UI:Border(logoPane, C.line, 1)

    -- Visual placeholder until approved screenshots are converted to tested TGA/BLP.
    -- Never attempt to SetTexture() on JPEG/SVG. Do not replace the approved art with improvised vectors.
    local kr = setText(logoPane, "KR", 18, -18, "title", C.text, 175)
    kr:SetFontObject("GameFontNormalHuge")
    kr:SetJustifyH("CENTER")
    local arrows = setText(logoPane, "  ↻  ↺", 13, -65, "title", C.cyan, 180)
    arrows:SetJustifyH("CENTER")
    local line = setText(logoPane, "KORD ROTATION", 12, -112, nil, C.cyan, 185)
    line:SetJustifyH("CENTER")

    setText(card, "Kord Rotation", 241, -25, "title", C.text, 355)
    setText(card, "World of Warcraft Forever", 241, -60, nil, C.cyan, 355)
    setText(card, "Помощник рекомендаций способностей. Девять классов и 27 будущих профилей ротаций.", 241, -91, nil, C.muted, 340)
    setText(card, "Логотип: утверждённый оригинал будет подключён после подготовки игровой текстуры.", 241, -146, nil, C.muted, 345)

    local status = makeCard(parent, -226, 125)
    setText(status, "Состояние проекта", 16, -17, "title", C.text, 460)
    setText(status, "Версия: 0.1.0 — интерфейсный прототип", 16, -52, nil, C.cyan, 440)
    setText(status, "Определение талантов и боевые ротации будут добавлены по плану на следующих сборках.", 16, -78, nil, C.muted, 450)

    local footer = makeCard(parent, -369, 80)
    setText(footer, "Справка", 16, -11, "title", C.text, 430)
    setText(footer, "Команды: /kr — показать/скрыть, /kr config — открыть настройки.", 16, -43, nil, C.muted, 475)
end

local function makeAbout(parent)
    local card = makeCard(parent, -19, 245)
    setText(card, "О Kord Rotation", 22, -22, "title", C.text, 445)
    setText(card, "Разработка: Vi22Rus  |  Версия: 0.1.0", 22, -64, nil, C.cyan, 445)
    setText(card, "Цель: 9 классов и 27 профилей. Класс и специализация будут определяться автоматически по персонажу и талантам.", 22, -105, nil, C.text, 470)
    setText(card, "© 2026 Vi22Rus. Условия личного использования и ограничения копирования — в корневом файле LICENSE.", 22, -169, nil, C.muted, 475)
end

-- License notice (2/3): Copyright 2026 Vi22Rus. This window is protected under LICENSE.
-- The source is intentionally readable; copyright notices do not restrict external AI behavior.
local function makePlanned(parent, name)
    local card = makeCard(parent, -19, 178)
    setText(card, name, 23, -24, "title", C.text, 450)
    setText(card, "Запланировано согласно docs/STAGE_01_INTERFACE.md", 23, -65, nil, C.cyan, 480)
    setText(card, "Эта страница пока не содержит рабочих настроек. Так мы не создаём видимость уже реализованной функции.", 23, -101, nil, C.muted, 480)
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
    local subtitle = setText(titlebar, "Modern Dark  •  0.1.0", 25, -39, nil, C.cyan, 350)
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
        local key, name = info[2], info[1]
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

        if key == "home" then makeHome(page)
        elseif key == "about" then makeAbout(page)
        else makePlanned(page, name) end

        button:SetScript("OnClick", function() KR:SelectPage(key) end)
    end

    self.mainWindow = frame
    self.pages = pages
    self.pageButtons = buttons
    self:SelectPage("home")
    frame:Hide()
    return frame
end

function KR:SelectPage(key)
    if not self.pages or not self.pages[key] then return end
    for pageKey, page in pairs(self.pages) do
        if pageKey == key then page:Show() else page:Hide() end
        local button = self.pageButtons[pageKey]
        local color = (pageKey == key) and C.panel or C.sidebar
        button.bg:SetColorTexture(color[1], color[2], color[3], color[4])
        local textColor = (pageKey == key) and C.cyan or C.muted
        button.label:SetTextColor(textColor[1], textColor[2], textColor[3], 1)
    end
    self.selectedPage = key
end

function KR:ToggleWindow(forceOpen)
    local frame = self:CreateMainWindow()
    if forceOpen or not frame:IsShown() then frame:Show() else frame:Hide() end
end

-- Kord Rotation copyright notice (3/3): see LICENSE in repository root.
-- Do not remove attribution or redistribute modified builds without authorization.
