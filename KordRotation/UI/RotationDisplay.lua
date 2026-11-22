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
    self.testMarker=marker

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
    -- Poll ONLY if a registered profile is enabled. There are no profiles
    -- at stage 2.8, so this incurs no eligibility reads for normal installs.
    visibility:SetScript("OnUpdate",function(self,elapsed)
        self.rotationAccumulator=(self.rotationAccumulator or 0)+(elapsed or 0)
        if self.rotationAccumulator<0.4 then return end
        self.rotationAccumulator=0
        local p=ensurePosition(KR.db)
        if p.testMode then return end
        -- Even with no active profile, a previously displayed real icon
        -- must be cleared when settings/profile disappear.
        if not p.showPanel then
            if KR.RotationDisplay.productionReady
                or KR.RotationDisplay.defensiveReady then
                KR.RotationDisplay:Refresh(true)
            end
            return
        end
        local id=KR.RotationSettings and KR.RotationSettings:GetProfileID()
        local registered=id and KR.RotationProfiles
            and KR.RotationProfiles:Has(id)
        local settings=registered and KR.RotationSettings:GetProfile(false)
        if settings and settings.enabled==true then
            KR.RotationDisplay:Refresh(true)
        elseif KR.RotationDisplay.productionReady
            or KR.RotationDisplay.defensiveReady then
            KR.RotationDisplay:Refresh(true)
        end
    end)
    self.visibilityFrame = visibility
    -- EventBus batches invalidations; refresh only on relevant changes.
    -- The existing 0.4s bounded refresh remains a fallback.
    if KR.EventBus and type(KR.EventBus.Subscribe)=="function" then
        local channels={"bindings","actionbar","spellbook","identity","talents",
            "target","cooldowns","resources","cast","combat","pet","auras"}
        for _,channel in ipairs(channels) do
            KR.EventBus:Subscribe(channel,"RotationDisplay",function()
                local display=KR.RotationDisplay
                if not display.frame then return end
                local p=ensurePosition(KR.db)
                if p.testMode then return end
                -- No needless engine work in a normal install without
                -- registered profiles; still clear an already visible icon.
                local id=KR.RotationSettings and KR.RotationSettings:GetProfileID()
                local hasProfile=id and KR.RotationProfiles
                    and KR.RotationProfiles:Has(id)
                if not display.productionReady and not display.defensiveReady
                    and not hasProfile then return end
                display:Refresh(true)
            end)
        end
    end
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
    -- Defense slots host a verified, independent aura recommendation.
    -- Interrupt/resource placeholders remain test-only.
    local pref=KR.IndicatorSettings
    local testing=p.showPanel and p.testMode
    local hasDefense=p.showPanel and pref and pref:Get("defensiveEnabled")==true
    local countDefense=hasDefense and pref:Get("defensiveSlots") or 0
    local defenseSize=pref and pref:Get("defensiveSize") or 52
    for i,slot in ipairs(self.defensePreview or {}) do
        slot:ClearAllPoints()
        slot:SetSize(defenseSize,defenseSize)
        slot:SetPoint("TOPLEFT",self.frame,"BOTTOMLEFT",(i-1)*(defenseSize+5),-25)
        slot:ApplyAppearance("minimal",false,100,p)
        slot:SetShown(i<=countDefense)
    end
    local interruptEnabled=p.showPanel and pref and pref:Get("interruptEnabled")==true
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
    -- Visibility is a user layout choice, not a side effect of engine READY.
    -- Empty slots remain visible so the panel never jumps during combat.
    if not p.showPanel then return false end
    local combat = safeBoolean(InCombatLockdown)
    if combat == nil then combat = safeBoolean(UnitAffectingCombat, "player") end
    if combat == nil then
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

-- Reject malformed or protected recommendations before touching UI textures.
local function verifiedRecommendation(result)
    if type(result)~="table" or result.status~="READY"
        or result.source~="RotationEngine" or type(result.queue)~="table"
        or #result.queue~=1 then return nil end
    local item=result.queue[1]
    if type(item)~="table" then return nil end
    if item.source=="experimental_profile" then
        -- No implicit activation via a SavedVariables migration.
        local settings=KR.RotationSettings and KR.RotationSettings:GetProfile(false)
        if type(settings)~="table" or settings.allowUnverifiedProfiles~=true then
            return nil
        end
    elseif item.source~="verified_profile" then return nil end
    local api=KR.GameAPI
    if not api or type(api.IsSafeValue)~="function" then return nil end
    local function safe(v) return api:IsSafeValue(v) end
    if not safe(item.spellID) or not safe(item.texture)
        or not safe(item.name) then return nil end
    local id=item.spellID
    if type(id)~="number" or id~=id or id<1 or id>99999999
        or id~=math.floor(id) then return nil end
    local tex=item.texture
    if not ((type(tex)=="number" and tex==tex and tex>0
            and tex<math.huge)
        or (type(tex)=="string" and #tex>0 and #tex<=255)) then return nil end
    if type(item.name)~="string" or item.name=="" then return nil end
    return item
end

-- Aggregate-only diagnostics from the already computed outcome.
-- Never retain candidate spell IDs, target identities or secret field values.
local function summarizeOutcome(result)
    local out={profileStatus="UNKNOWN",eligibilityReady=0,
        eligibilityBlocked=0,eligibilityUnknown=0}
    local api=KR.GameAPI
    if type(result)~="table" or not api
        or type(api.IsSafeValue)~="function"
        or not api:IsSafeValue(result) then return out end
    local profile=result.profileID
    if api:IsSafeValue(profile) and type(profile)=="string"
        and #profile>0 and #profile<=48 then
        out.profileStatus="READY"
    else
        local why=result.reason
        if api:IsSafeValue(why) and why=="profile_not_registered" then
            out.profileStatus="UNAVAILABLE"
        elseif api:IsSafeValue(why) and why=="rotation_disabled" then
            out.profileStatus="BLOCKED"
        end
    end
    local diagnostics=result.diagnostics
    if type(diagnostics)~="table"
        or not api:IsSafeValue(diagnostics) or #diagnostics>64 then
        return out
    end
    for i=1,#diagnostics do
        local record=diagnostics[i]
        if not api:IsSafeValue(record) or type(record)~="table" then
            out.eligibilityUnknown=out.eligibilityUnknown+1
        else
            local status=record.status
            if not api:IsSafeValue(status) then
                out.eligibilityUnknown=out.eligibilityUnknown+1
            elseif status=="READY" then
                out.eligibilityReady=out.eligibilityReady+1
            elseif status=="BLOCKED" then
                out.eligibilityBlocked=out.eligibilityBlocked+1
            else
                out.eligibilityUnknown=out.eligibilityUnknown+1
            end
        end
    end
    return out
end

function KR.RotationDisplay:Refresh(skipLayout)
    if not self.frame then return end
    local p = ensurePosition(KR.db)
    if not skipLayout then self:RefreshLayout() end
    self.productionReady=false
    self.defensiveReady=false
    self.lastSummary={profileStatus="UNKNOWN",eligibilityReady=0,
        eligibilityBlocked=0,eligibilityUnknown=0}
    if p.testMode then
        -- Preserve preview artwork and numbers, never mark it live.
        for i,slot in ipairs(self.slots or {}) do
            slot:SetTestSlot(i,i==1)
        end
        for _,slot in ipairs(self.defensePreview or {}) do
            slot:ClearDisplayData()
        end
    else
        local result
        if p.showPanel and KR.RotationEngine and KR.RotationEngine.Evaluate then
            local ok,read=pcall(KR.RotationEngine.Evaluate,KR.RotationEngine)
            if ok and type(read)=="table" then result=read end
        end
        -- Even the shape of an addon/plugin supplied record may be protected.
        -- No bad payload can escape the UI refresh path.
        local okMeta,status,reason=pcall(function()
            local api=KR.GameAPI
            if type(result)~="table" or not api
                or type(api.IsSafeValue)~="function"
                or not api:IsSafeValue(result) then
                return "UNKNOWN","engine_unavailable"
            end
            return result.status,result.reason
        end)
        self.lastEngineStatus=okMeta and status or "UNKNOWN"
        self.lastEngineReason=okMeta and reason or "engine_unavailable"
        local okSummary,summary=pcall(summarizeOutcome,result)
        if okSummary and type(summary)=="table" then self.lastSummary=summary end
        local okItem,item=pcall(verifiedRecommendation,result)
        if not okItem then item=nil end
        if item then
            self.productionReady=true
            self:SetSlotData(1,{texture=item.texture,name=item.name,
                keybind=item.keybind})
        else self:SetSlotData(1,nil) end
        -- Never fabricate future recommendations. Keep the configured
        -- slot shells visible, but clear icons when engine provides no data.
        for i=2,5 do self:SetSlotData(i,nil) end
        if self.slots then
            for i=1,5 do
                local slot=self.slots[i]
                if i<=(p.slotCount or 3) then slot:Show() end
            end
        end
        -- Evaluate defensive independently so an UNKNOWN earlier DPS
        -- condition cannot suppress verified aura upkeep. Never route
        -- the same aura to main and defense in a single snapshot.
        local pref=KR.IndicatorSettings
        local defenseEnabled=p.showPanel and pref
            and pref:Get("defensiveEnabled")==true
        local defensiveOnlyCombat=pref
            and pref:Get("defensiveCombatOnly")==true
        local combat
        if defensiveOnlyCombat then
            combat=safeBoolean(UnitAffectingCombat,"player")
        end
        local defensiveItem
        if defenseEnabled and (not defensiveOnlyCombat or combat==true)
            and KR.RotationEngine
            and type(KR.RotationEngine.EvaluateDefensive)=="function" then
            local ok,defResult=pcall(KR.RotationEngine.EvaluateDefensive,
                KR.RotationEngine)
            if ok then
                local checked,record=pcall(verifiedRecommendation,defResult)
                if checked then defensiveItem=record end
            end
        end
        local mainID=item and item.spellID
        if defensiveItem and defensiveItem.spellID==mainID then
            defensiveItem=nil
        end
        self.defensiveReady=defensiveItem~=nil
        for i,slot in ipairs(self.defensePreview or {}) do
            if i==1 and defensiveItem then
                slot:SetDisplayData({texture=defensiveItem.texture,
                    name=defensiveItem.name,keybind=defensiveItem.keybind})
            else
                slot:ClearDisplayData()
            end
        end
        if self.interruptPreview then self.interruptPreview:ClearDisplayData() end
    end
    -- In preview the marker explains synthetic icons; in live mode it must
    -- not imply that empty shells are actual spell recommendations.
    if self.testMarker then self.testMarker:SetShown(p.testMode) end
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
