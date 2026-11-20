-- Kord Rotation (c) 2026 Vi22Rus. All rights reserved.
-- Personal use under LICENSE; no redistribution or derivatives without prior permission.
-- No license-file removal checks or concealed addon behavior.

local addonName, KR = ...
local UI, C = KR.UI, KR.UI.colors
KR.RotationDisplay = KR.RotationDisplay or {}

local function clamp(v, low, high)
    v = tonumber(v) or low
    if v < low then return low end
    if v > high then return high end
    return v
end

local function ensurePosition(db)
    if type(db.panel) ~= "table" then db.panel = {} end
    local p = db.panel
    p.x, p.y = clamp(p.x or 0, -10000, 10000), clamp(p.y or -120, -10000, 10000)
    if p.showPanel == nil then p.showPanel = true end
    if p.locked == nil then p.locked = true end
    if p.testMode == nil then p.testMode = false end
    return p
end

-- License notice (2/3): © 2026 Vi22Rus. See LICENSE.
-- Test mode presents placeholders ONLY; there is no scheduler or spell prediction here.
function KR.RotationDisplay:Create()
    if self.frame then return self.frame end
    local cfg = ensurePosition(KR.db)
    local frame = CreateFrame("Frame", "KordRotationRecommendationPanel", UIParent)
    frame:SetFrameStrata("MEDIUM")
    frame:SetSize(188, 78)
    frame:SetPoint("CENTER", UIParent, "CENTER", cfg.x, cfg.y)
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(f)
        if not ensurePosition(KR.db).locked then f:StartMoving() end
    end)
    frame:SetScript("OnDragStop", function(f)
        f:StopMovingOrSizing()
        local x, y = f:GetCenter()
        local sx, sy = UIParent:GetCenter()
        if x and y and sx and sy then
            local p = ensurePosition(KR.db)
            p.x, p.y = x - sx, y - sy
        end
    end)

    local marker = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    marker:SetPoint("BOTTOM", frame, "TOP", 0, 6)
    marker:SetTextColor(C.cyan[1], C.cyan[2], C.cyan[3])
    marker:SetText(KR:L("PANEL_TEST_BADGE"))

    local slots = {}
    for i = 1, 5 do
        local slot = KR.SpellIcon:Create(frame)
        slot:SetTestSlot(i, i == 1)
        slots[i] = slot
    end
    self.frame, self.slots = frame, slots
    local defense = {}
    for i=1,3 do
        local preview=KR.SpellIcon:Create(frame)
        preview:SetTestSlot(i,false)
        preview:Hide()
        defense[i]=preview
    end
    self.defensePreview=defense
    self.interruptPreview=KR.SpellIcon:Create(frame)
    self.interruptPreview:SetTestSlot(1,false)
    self.interruptPreview:Hide()
    local resource=CreateFrame("Frame",nil,frame)
    resource:SetSize(130,14)
    KR.UI:Background(resource,C.sidebar)
    local text=resource:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
    text:SetPoint("CENTER",0,0)
    text:SetText(KR:L("PANEL_TEST_BADGE"))
    resource:Hide()
    self.resourcePreview=resource
    frame:Hide()
    local visibility = CreateFrame("Frame", nil, UIParent)
    local events = {"PLAYER_REGEN_ENABLED", "PLAYER_REGEN_DISABLED", "PLAYER_TARGET_CHANGED",
        "PLAYER_DEAD", "PLAYER_ALIVE", "PLAYER_UNGHOST", "UNIT_FLAGS", "PLAYER_MOUNT_DISPLAY_CHANGED"}
    for _, event in ipairs(events) do
        pcall(visibility.RegisterEvent, visibility, event)
    end
    visibility:SetScript("OnEvent", function(_,event,unit)
        if event ~= "UNIT_FLAGS" or unit == "player" then KR.RotationDisplay:Refresh() end
    end)
    self.visibilityFrame = visibility
    self:RefreshLayout()
    self:Refresh()
    return frame
end

-- Reuse all five placeholder frames; only apply layout and visibility.
-- Future engine interface. A caller must supply real, verified state.
-- Setting nil clears all overlays; test slots never receive synthetic combat data.
function KR.RotationDisplay:SetSlotData(index, data)
    if not self.slots or type(index) ~= "number" or index ~= math.floor(index)
        or index < 1 or index > 5 then return false end
    local slot = self.slots[index]
    if type(data) == "table" then slot:SetDisplayData(data)
    else slot:ClearDisplayData() end
    return true
end

function KR.RotationDisplay:RefreshLayout()
    if not self.frame then return end
    local p = ensurePosition(KR.db)
    local count = p.slotCount or 3
    local vertical = p.direction == "vertical"
    local mainSize = p.primarySize or 72
    local otherSize = p.secondarySize or 52
    local gap = p.gap or 6
    local order = {}
    for i = 1, count do
        order[i] = self.slots[(p.primaryAtEnd and count > 1) and (count - i + 1) or i]
    end
    local extent = mainSize + otherSize * (count - 1) + gap * (count - 1)
    self.frame:SetSize(vertical and math.max(mainSize, otherSize) or extent,
        vertical and extent or math.max(mainSize, otherSize))
    self.frame:SetScale((p.scale or 100) / 100)
    self.frame:SetAlpha((p.alpha or 100) / 100)
    for i, slot in ipairs(self.slots) do
        slot:ClearAllPoints()
        if i <= count then
            local size = i == 1 and mainSize or otherSize
            slot:SetSize(size, size)
            slot:ApplyAppearance(p.borderStyle or "standard", p.showNumbers ~= false,
                i == 1 and 100 or (p.secondaryAlpha or 100), p)
            slot:Show()
        else slot:Hide() end
    end
    -- Extra areas are TEST-only empty previews, not actual defensive recommendations.
    local pref=KR.IndicatorSettings
    local testing=p.showPanel and p.testMode
    local hasDefense=testing and pref and pref:Get("defensiveEnabled")==true
    local countDefense=hasDefense and pref:Get("defensiveSlots") or 0
    local defenseSize=pref and pref:Get("defensiveSize") or 52
    for i,slot in ipairs(self.defensePreview or {}) do
        slot:ClearAllPoints()
        slot:SetSize(defenseSize,defenseSize)
        slot:SetPoint("TOPLEFT",self.frame,"BOTTOMLEFT",(i-1)*(defenseSize+5),-25)
        slot:ApplyAppearance("minimal",false,100,p)
        slot:SetShown(i<=countDefense)
    end
    local interruptEnabled=testing and pref and pref:Get("interruptEnabled")==true
    local interruptSize=pref and pref:Get("interruptSize") or 52
    if self.interruptPreview then
        self.interruptPreview:ClearAllPoints()
        self.interruptPreview:SetSize(interruptSize,interruptSize)
        self.interruptPreview:SetPoint("TOPLEFT",self.frame,"BOTTOMLEFT",0,
            -(hasDefense and defenseSize+33 or 25))
        self.interruptPreview:ApplyAppearance("minimal",false,100,p)
        self.interruptPreview:SetShown(interruptEnabled)
    end
    if self.resourcePreview then
        self.resourcePreview:ClearAllPoints()
        self.resourcePreview:SetPoint("TOPLEFT",self.frame,"BOTTOMLEFT",0,
            -(hasDefense and defenseSize+44 or 25)
            -(interruptEnabled and interruptSize+10 or 0))
        self.resourcePreview:SetShown(testing and pref and pref:Get("resourceEnabled")==true)
    end
    for i, slot in ipairs(order) do
        if i == 1 then
            slot:SetPoint(vertical and "TOP" or "LEFT", self.frame, vertical and "TOP" or "LEFT", 0, 0)
        elseif vertical then
            slot:SetPoint("TOP", order[i-1], "BOTTOM", 0, -gap)
        else
            slot:SetPoint("LEFT", order[i-1], "RIGHT", gap, 0)
        end
    end
end

local function safeBoolean(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok,value = pcall(fn, ...)
    if ok and type(value) == "boolean" then return value end
    return nil
end

function KR.RotationDisplay:ShouldShow()
    local p = ensurePosition(KR.db)
    if not p.showPanel or not p.testMode then return false end
    local combat = safeBoolean(InCombatLockdown)
    if combat == nil then combat = safeBoolean(UnitAffectingCombat, "player") end
    if combat == nil then
        -- Missing combat APIs must not bypass an explicitly restricted visibility mode.
        if not p.showInCombat or not p.showOutOfCombat then return false end
    else
        if combat and not p.showInCombat then return false end
        if not combat and not p.showOutOfCombat then return false end
    end
    if p.requireTarget and safeBoolean(UnitExists, "target") ~= true then return false end
    if p.hideWhenDead and safeBoolean(UnitIsDeadOrGhost, "player") == true then return false end
    if p.hideMounted and safeBoolean(IsMounted) == true then return false end
    return true
end

function KR.RotationDisplay:Refresh()
    if not self.frame then return end
    local p = ensurePosition(KR.db)
    self:RefreshLayout()
    -- Without a real rotation engine, NEVER show a fictitious production queue.
    if self:ShouldShow() then self.frame:Show() else self.frame:Hide() end
end

function KR.RotationDisplay:ToggleTest()
    self:Create()
    local p = ensurePosition(KR.db)
    KR:SetPanelFlag("testMode", not p.testMode)
    return p.testMode
end

function KR.RotationDisplay:ToggleLock()
    self:Create()
    local p = ensurePosition(KR.db)
    KR:SetPanelFlag("locked", not p.locked)
    return p.locked
end

function KR.RotationDisplay:ResetPosition()
    self:Create()
    local p = ensurePosition(KR.db)
    p.x, p.y = 0, -120
    self.frame:ClearAllPoints()
    self.frame:SetPoint("CENTER", UIParent, "CENTER", p.x, p.y)
    if KR.UpdatePanelControls then KR:UpdatePanelControls() end
end

-- Copyright notice (3/3): (c) 2026 Vi22Rus; see root LICENSE.
-- Retain notices in authorized copies.
