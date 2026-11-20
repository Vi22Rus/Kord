-- Kord Rotation (c) 2026 Vi22Rus. All rights reserved.
-- Personal use only under root LICENSE; retain attribution.
-- No automatic protected actions or undeclared data collection.

local addonName, KR = ...
KR.Pages = KR.Pages or {}
local UI,C=KR.UI,KR.UI.colors
local A,D=KR.Advanced,KR.Diagnostics
local function panel(parent,y,height)
    local box=CreateFrame("Frame",nil,parent)
    box:SetPoint("TOPLEFT",15,y)
    box:SetPoint("TOPRIGHT",-15,y)
    box:SetHeight(height)
    UI:Background(box,C.panel)
    UI:Border(box,C.line,1)
    return box
end
local function prose(parent,key,x,y,width,title)
    local t=UI:Label(parent,KR:L(key),title and "title" or nil,
        title and C.text or C.muted)
    t:SetPoint("TOPLEFT",x,y)
    t:SetWidth(width or 490)
    t:SetWordWrap(true)
    return t
end
local function value(parent,x,y,width)
    local t=UI:Label(parent,"",nil,C.text)
    t:SetPoint("TOPLEFT",x,y)
    t:SetWidth(width or 490)
    t:SetWordWrap(true)
    return t
end
local function click(parent,key,x,y,width,callback)
    local b=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate")
    b:SetPoint("TOPLEFT",x,y)
    b:SetSize(width,27)
    b:SetText(KR:L(key))
    b:SetScript("OnClick",callback)
    return b
end
local function scrolled(parent,height)
    local frame=CreateFrame("ScrollFrame",nil,parent,"UIPanelScrollFrameTemplate")
    frame:SetPoint("TOPLEFT",5,-7)
    frame:SetPoint("BOTTOMRIGHT",-27,6)
    local child=CreateFrame("Frame",nil,frame)
    child:SetSize(560,height)
    frame:SetScrollChild(child)
    return child
end
local function confirm(parent,titleKey,action)
    local box=CreateFrame("Frame",nil,parent)
    box:SetSize(390,155)
    box:SetPoint("CENTER",parent,"CENTER")
    box:SetFrameStrata("DIALOG")
    UI:Background(box,C.panel)
    UI:Border(box,C.cyan,2)
    prose(box,titleKey,17,-21,348,true)
    click(box,"ADV_CONFIRM_YES",13,-102,175,function()
        box:Hide()
        action()
    end)
    click(box,"ADV_CONFIRM_NO",204,-102,174,function() box:Hide() end)
    box:Hide()
    return box
end
-- License notice (2/3): advanced controls do not imply a real minimap icon,
-- a running combat scheduler, or a completed protected-frame queue.
function KR.Pages:Advanced(parent)
    local body=scrolled(parent,1040)
    local intro=panel(body,-14,126)
    prose(intro,"ADV_TITLE",16,-12,510,true)
    prose(intro,"ADV_LANGUAGE_AUTO",16,-39,510)
    local choices={{"auto","ADV_LANG_AUTO"},{"ruRU","ADV_LANG_RU"},{"enUS","ADV_LANG_EN"},{"deDE","ADV_LANG_DE"},{"frFR","ADV_LANG_FR"},{"esES","ADV_LANG_ES"},{"ptBR","ADV_LANG_PT"}}
    local language=UI:ChoiceRow(intro,"ADV_LANGUAGE_LABEL",13,-76,505,
        function() return A:Get("language") end,
        function(value) A:Set("language",value) end,choices)
    local options=panel(body,-159,345)
    prose(options,"ADV_OPTIONS_TITLE",16,-13,510,true)
    local flags={
        {"ADV_SHOW_LOGIN","showAtLogin"},
        {"ADV_LOAD_MESSAGE","showLoadMessage"},
        {"ADV_TOOLTIPS","showTooltips"},
        {"ADV_MINIMAP","showMinimap"},
    }
    local rows={}
    for i,item in ipairs(flags) do
        local key=item[2]
        rows[#rows+1]=UI:ToggleRow(options,item[1],13,-44-(i-1)*44,505,
            function() return A:Get(key) end,
            function(v) A:Set(key,v) end)
    end
    prose(options,"ADV_UNSUPPORTED_NOTE",15,-251,506)

    local reset=panel(body,-524,209)
    prose(reset,"ADV_RESET_TITLE",15,-12,510,true)
    prose(reset,"ADV_RESET_CAUTION",15,-43,510)
    local status=value(reset,15,-75,510)
    local function resetAction(kind)
        local ok, result
        if kind=="appearance" then ok=A:ResetAppearance()
        elseif kind=="branch" then ok=A:ResetCurrentRotation()
        else ok,result=A:ResetAll() end
        if not ok then D:Log("WARN","Settings","Reset "..kind.." not available") end
        local queued=KR.SafeActions and KR.SafeActions:Status() or 0
        status:SetText(KR:Format("ADV_PENDING_COUNT",queued))
    end
    local appearance=confirm(parent,"ADV_CONFIRM_APPEARANCE",function()resetAction("appearance")end)
    local branch=confirm(parent,"ADV_CONFIRM_BRANCH",function()resetAction("branch")end)
    local all=confirm(parent,"ADV_RESET_ALL_CONFIRM",function()resetAction("all")end)
    click(reset,"ADV_RESET_APPEARANCE",15,-115,245,function()appearance:Show()end)
    click(reset,"ADV_RESET_BRANCH",270,-115,245,function()branch:Show()end)
    click(reset,"ADV_RESET_ALL",15,-162,500,function()all:Show()end)

    local compat=panel(body,-752,190)
    prose(compat,"ADV_COMPAT_TITLE",15,-12,510,true)
    local compatText=value(compat,15,-44,510)
    prose(compat,"ADV_COMPAT_NOTE",15,-123,510)
    local function refresh()
        language:Refresh()
        for _,row in ipairs(rows) do row:Refresh() end
        status:SetText(KR:Format("ADV_PENDING_COUNT",
            KR.SafeActions and KR.SafeActions:Status() or 0))
        compatText:SetText(D:CompatibilityText())
    end
    parent.refresh=refresh
    refresh()
end

function KR.Pages:Diagnostics(parent)
    local body=scrolled(parent,1130)
    local summary=panel(body,-13,245)
    prose(summary,"DIAG_TITLE",15,-12,510,true)
    local status=value(summary,15,-45,520)
    local details=value(summary,15,-147,520)
    local compat=panel(body,-277,213)
    prose(compat,"DIAG_API_TITLE",15,-12,520,true)
    local caps=value(compat,15,-43,515)
    local logFrame=panel(body,-508,227)
    local refresh
    prose(logFrame,"DIAG_EVENTS",15,-12,500,true)
    local recent=value(logFrame,15,-41,518)
    click(logFrame,"DIAG_TEST_UI",15,-185,170,function()
        KR.RotationDisplay:ToggleTest()
        refresh()
    end)
    local export=panel(body,-754,346)
    prose(export,"DIAG_EXPORT_TITLE",15,-13,510,true)
    prose(export,"DIAG_COPY_HELP",15,-40,505)
    local field=CreateFrame("EditBox",nil,export,"InputBoxTemplate")
    field:SetPoint("TOPLEFT",22,-92)
    field:SetSize(474,177)
    field:SetMultiLine(true)
    field:SetAutoFocus(false)
    field:SetMaxLetters(0)
    field:SetScript("OnEscapePressed",function(self)self:ClearFocus()end)
    refresh=function()
        local snap=D:Snapshot()
        status:SetText(KR:Format("DIAG_SUMMARY",snap.class,snap.profile,snap.status,
            snap.counts,snap.trigger,snap.slots,snap.x,snap.y,snap.scale,
            snap.testMode and KR:L("UI_ENABLED") or KR:L("UI_DISABLED")))
        details:SetText(KR:Format("DIAG_DETAILS",tostring(snap.config),
            tostring(snap.branch),tostring(snap.method),snap.certainty))
        caps:SetText(D:ProbeReport())
        local lines=D.lines or {}
        local recentLines={}
        for i=math.max(1,#lines-5),#lines do
            local entry=lines[i]
            if entry then recentLines[#recentLines+1]=entry.time.." ["..entry.module.."] "..entry.text end
        end
        recent:SetText(table.concat(recentLines,"\n"))
        field:SetText(D:Report())
    end
    click(export,"DIAG_RESCAN",15,-295,156,function()
        KR:RefreshCharacter("diagnostic_manual")
        refresh()
    end)
    click(export,"DIAG_CLEAR",183,-295,136,function()
        D:Clear()
        refresh()
    end)
    click(export,"DIAG_SELECT",331,-295,180,function()
        field:SetText(D:Report())
        field:SetFocus()
        field:HighlightText()
    end)
    parent.refresh=refresh
    KR.RefreshDiagnosticsPage=function()
        if parent:IsShown() then refresh() end
    end
    refresh()
end

function KR.Pages:About(parent)
    local box=panel(parent,-18,432)
    prose(box,"ABOUT_TITLE",20,-20,510,true)
    local version=value(box,20,-69,510)
    version:SetText(KR:Format("ABOUT_VERSION",KR.version))
    prose(box,"ABOUT_TEXT",20,-115,510)
    prose(box,"ABOUT_IMPLEMENTATION",20,-190,510)
    prose(box,"ABOUT_LICENSE",20,-268,510)
    prose(box,"ABOUT_COMMANDS",20,-350,510)
end
-- Copyright notice (3/3): 2026 Vi22Rus; see root LICENSE.
