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
    local body=scrolled(parent,1005)
    local intro=panel(body,-14,104)
    prose(intro,"ADV_TITLE",16,-14,510,true)
    prose(intro,"ADV_LANGUAGE_AUTO",16,-49,510)
    local options=panel(body,-136,345)
    prose(options,"ADV_OPTIONS_TITLE",16,-13,510,true)
    local flags={
        {"ADV_SHOW_LOGIN","showAtLogin"},
        {"ADV_LOAD_MESSAGE","showLoadMessage"},
        {"ADV_TOOLTIPS","showTooltips"},
        {"ADV_MINIMAP","showMinimap"},
    }
    for i,item in ipairs(flags) do
        local key=item[2]
        UI:ToggleRow(options,item[1],13,-44-(i-1)*44,505,
            function() return A:Get(key) end,
            function(v) A:Set(key,v) end)
    end
    prose(options,"ADV_UNSUPPORTED_NOTE",15,-251,506)
    local rates=panel(body,-500,250)
    prose(rates,"ADV_RATES_TITLE",15,-13,500,true)
    local items={
        {"ADV_RATE_LOGIC","updateRate",50},
        {"ADV_RATE_DRAW","visualRate",50},
        {"ADV_RATE_SCAN","scanRate",100},
    }
    for i,item in ipairs(items) do
        local key=item[2]
        UI:StepRow(rates,item[1],13,-47-(i-1)*47,505,
            function() return A:Get(key) end,
            function(v) A:Set(key,v) end,item[3])
    end
    prose(rates,"ADV_RATE_NOTE",15,-205,505)
    local reset=panel(body,-770,213)
    prose(reset,"ADV_RESET_TITLE",15,-14,510,true)
    prose(reset,"ADV_RESET_CAUTION",15,-45,510)
    local confirmation=confirm(parent,"ADV_RESET_ALL_CONFIRM",function()
        A:ResetAll()
    end)
    click(reset,"ADV_RESET_APPEARANCE",15,-96,245,function()
        A:ResetAppearance()
    end)
    click(reset,"ADV_RESET_BRANCH",270,-96,245,function()
        if not A:ResetCurrentRotation() then
            D:Log("WARN","Settings","No current tree for reset")
        end
    end)
    click(reset,"ADV_RESET_ALL",15,-148,500,function()confirmation:Show()end)
end

function KR.Pages:Diagnostics(parent)
    local body=scrolled(parent,1130)
    local summary=panel(body,-13,245)
    prose(summary,"DIAG_TITLE",15,-12,510,true)
    local status=value(summary,15,-45,520)
    local compat=panel(body,-277,213)
    prose(compat,"DIAG_API_TITLE",15,-12,520,true)
    local caps=value(compat,15,-43,515)
    local logFrame=panel(body,-508,227)
    prose(logFrame,"DIAG_EVENTS",15,-12,500,true)
    local recent=value(logFrame,15,-41,518)
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
    local function refresh()
        local snap=D:Snapshot()
        status:SetText(KR:Format("DIAG_SUMMARY",snap.class,snap.profile,snap.status,
            snap.counts,snap.trigger,snap.slots,snap.x,snap.y,snap.scale,
            snap.testMode and KR:L("UI_ENABLED") or KR:L("UI_DISABLED")))
        local matches={}
        for _,item in ipairs(D:Capabilities()) do
            matches[#matches+1]=item.name..": "..(item.available and "+" or "-")
        end
        caps:SetText(table.concat(matches,"  "))
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
