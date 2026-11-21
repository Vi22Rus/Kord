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
        report:SetText(D:Export())
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
