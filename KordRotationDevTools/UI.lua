-- Kord Rotation DevTools (c) 2026 Vi22Rus; see root LICENSE.
-- Only installed in the optional diagnostic addon; no UI elements in KordRotation.
local _,D=...
local function button(parent,key,x,y,w,fn)
    local b=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate")
    b:SetSize(w,27)
    b:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
    b:SetText(D:L(key))
    b:SetScript("OnClick",fn)
    b:SetScript("OnEnter",function(self)
        if GameTooltip then
            GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
            GameTooltip:SetText(D:L("TIP_"..key))
            GameTooltip:Show()
        end
    end)
    b:SetScript("OnLeave",function()
        if GameTooltip then GameTooltip:Hide() end
    end)
    return b
end
function D:RefreshUI()
    if not self.ui then return end
    local s=self.active and self:L("STATE_ON") or self:L("STATE_OFF")
    self.ui.status:SetText(self:Format("STATUS",s,#(self.records or {}),self.dropped or 0))
end
-- Optional public UI-only entry point for KordRotation's Diagnostics tab.
-- Never starts a recording, probes APIs, or mutates rotation settings.
function D:OpenUI()
    local frame=self.ui and self.ui.frame
    if not frame and type(self.CreateUI)=="function" then
        local ok,value=pcall(self.CreateUI,self)
        if ok then frame=value end
    end
    if not frame or type(frame.Show)~="function" then return false end
    local ok=pcall(frame.Show,frame)
    if not ok then return false end
    if type(self.RefreshUI)=="function" then
        pcall(self.RefreshUI,self)
    end
    return true
end

function D:CreateUI()
    if self.ui then return self.ui.frame end
    local frame=CreateFrame("Frame","KordRotationDevToolsWindow",UIParent,"BasicFrameTemplateWithInset")
    frame:SetSize(640,510)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart",function(f) f:StartMoving() end)
    frame:SetScript("OnDragStop",function(f) f:StopMovingOrSizing() end)
    local title=frame:CreateFontString(nil,"OVERLAY","GameFontNormalLarge")
    title:SetPoint("TOP",frame,"TOP",0,-14)
    title:SetText(self:L("TITLE"))
    local status=frame:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    status:SetPoint("TOPLEFT",frame,"TOPLEFT",20,-50)
    status:SetWidth(600)
    status:SetJustifyH("LEFT")
    local report=CreateFrame("EditBox",nil,frame,"InputBoxTemplate")
    report:SetMultiLine(true)
    report:SetAutoFocus(false)
    report:SetSize(576,250)
    report:SetPoint("TOPLEFT",frame,"TOPLEFT",22,-163)
    report:SetScript("OnEscapePressed",function(self)self:ClearFocus()end)
    report:SetMaxLetters(0)
    local help=frame:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    help:SetPoint("TOPLEFT",frame,"TOPLEFT",23,-429)
    help:SetWidth(588)
    help:SetJustifyH("LEFT")
    help:SetText(self:L("HELP"))
    self.ui={frame=frame,report=report,status=status}
    button(frame,"START",20,-76,125,function()
        D:Start()
        D:RefreshUI()
    end)
    button(frame,"STOP",155,-76,125,function()
        D:Stop()
        D:RefreshUI()
    end)
    button(frame,"PROBE",290,-76,145,function()
        local result=D:ProbeAll()
        report:SetText(D:Format("RESULT",result.present,result.total))
        D:RefreshUI()
    end)
    button(frame,"MEASURE",445,-76,170,function()
        local result=D:Measure()
        if result.status=="READY" then
            report:SetText(D:Format("METRIC",result.durationMs))
        else
            report:SetText(D:L("UNAVAILABLE"))
        end
        D:RefreshUI()
    end)
    button(frame,"EXPORT",20,-116,190,function()
        -- Each click advances one complete export page. After the final
        -- page, start again at 1. Pages are bounded for the WoW EditBox.
        local page=(D.exportPage or 0)+1
        local output,current,total=D:Export(page)
        if page>total then
            output,current,total=D:Export(1)
        end
        D.exportPage=current
        report:SetText(output)
        report:SetFocus()
        report:HighlightText()
        D:RefreshUI()
    end)
    button(frame,"CLEAR",220,-116,190,function()
        if D:Clear() then report:SetText("") end
        D:RefreshUI()
    end)
    button(frame,"CLOSE",420,-116,195,function()
        frame:Hide()
    end)
    frame:Hide()
    self:RefreshUI()
    SLASH_KORDROTATIONDEVTOOLS1="/krdev"
    SlashCmdList["KORDROTATIONDEVTOOLS"]=function(message)
        message=type(message)=="string" and message:lower():match("^%s*(.-)%s*$") or ""
        -- Explicit manual item/family/bag diagnosis; no automatic polling.
        local kind,identifier=message:match("^inventory%s+([a-z]+)%s+([%w_]+)$")
        if not kind then
            if message=="inventory bag" then kind="bag" end
        end
        if kind~="item" and kind~="family" and kind~="bag" then kind=nil end
        if kind and type(D.InventoryDiagnostic)=="function" then
            local item=identifier
            if kind=="item" then
                item=tonumber(identifier)
            end
            local result=D:InventoryDiagnostic(kind,item)
            if D.ui and D.ui.report then
                D.ui.report:SetText("Inventory: "..result.status.." / "..result.code)
                D.ui.frame:Show()
                D:RefreshUI()
            end
            return
        end
        -- Explicit item-specific cooldown inspection; the supplied ID
        -- is never written to the report or diagnostic records.
        local cooldownItem=message:match("^cooldown%s+item%s+(%d+)$")
        if cooldownItem and type(D.ItemCooldownDiagnostic)=="function" then
            local result=D:ItemCooldownDiagnostic(tonumber(cooldownItem))
            if D.ui and D.ui.report then
                D.ui.report:SetText("Item-specific cooldown: "..result.status
                    .." / "..result.code
                    .."\nActivity / source: "..result.activity
                    .." / "..result.source
                    .."\nOnly item-specific cooldown; NOT final item usability or shared READY")
                D.ui.frame:Show()
                D:RefreshUI()
            end
            return
        end
        if message=="cooldown" and type(D.SharedCooldownDiagnostic)=="function" then
            local result=D:SharedCooldownDiagnostic()
            if D.ui and D.ui.report then
                local counts=result.candidates and (tostring(result.active)
                    .."/"..tostring(result.inactive).."/"
                    ..tostring(result.unknown)) or "UNKNOWN"
                D.ui.report:SetText("POTION_SHARED: "..result.status
                    .." / "..result.code
                    .."\nItem / Lockout / Ready: "..result.itemConfidence
                    .." / "..result.lockoutConfidence
                    .." / "..result.readyConfidence
                    .."\nUse / propagation: "..result.useCorrelation
                    .." / "..result.propagation
                    .."\nKnown active / inactive / unknown: "..counts
                    .."\nDiagnostic only: not proof of shared READY")
                D.ui.frame:Show()
                D:RefreshUI()
            end
            return
        end
        if message=="why" then
            if D.ui and D.ui.report and type(D.Why)=="function" then
                local ok,report=pcall(D.Why,D)
                D.ui.report:SetText(ok and type(report)=="string"
                    and report or D:L("UNAVAILABLE"))
                D.ui.frame:Show()
                D:RefreshUI()
            end
            return
        end
        if D.ui and D.ui.frame:IsShown() then D.ui.frame:Hide()
        else D.ui.frame:Show();D:RefreshUI() end
    end
    return frame
end
