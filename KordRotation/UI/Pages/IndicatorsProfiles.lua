-- Kord Rotation (c) 2026 Vi22Rus. All rights reserved.
-- Personal use only under root LICENSE; no unauthorized redistribution.
-- Missing or modified LICENSE does not create permission.

local addonName, KR = ...
local UI, C = KR.UI, KR.UI.colors
KR.Pages = KR.Pages or {}
local IS, AP = KR.IndicatorSettings, KR.AppearanceProfiles

local function label(parent,key,x,y,width,title)
    local l=UI:Label(parent,KR:L(key),title and "title" or nil,title and C.text or C.muted)
    l:SetPoint("TOPLEFT",x,y); l:SetWidth(width or 500); l:SetWordWrap(true)
    return l
end
local function raw(parent,x,y,width)
    local l=UI:Label(parent,"",nil,C.text)
    l:SetPoint("TOPLEFT",x,y); l:SetWidth(width or 490); l:SetWordWrap(true)
    return l
end
local function card(parent,y,height)
    local b=CreateFrame("Frame",nil,parent)
    b:SetPoint("TOPLEFT",15,y);b:SetPoint("TOPRIGHT",-15,y);b:SetHeight(height)
    UI:Background(b,C.panel);UI:Border(b,C.line,1)
    return b
end
local function scroll(parent,height)
    local s=CreateFrame("ScrollFrame",nil,parent,"UIPanelScrollFrameTemplate")
    s:SetPoint("TOPLEFT",5,-7);s:SetPoint("BOTTOMRIGHT",-27,6)
    local b=CreateFrame("Frame",nil,s);b:SetSize(565,height);s:SetScrollChild(b)
    return b
end
local function button(parent,key,x,y,w,callback)
    local b=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate")
    b:SetPoint("TOPLEFT",x,y);b:SetSize(w,27)
    b:SetText(KR:L(key));b:SetScript("OnClick",callback)
    return b
end
local function boolRow(parent,key,value,y)
    return UI:ToggleRow(parent,key,12,y,505,
        function() return IS:Get(value) end,
        function(v) IS:Set(value,v) end)
end
local function stepRow(parent,key,value,y,step)
    return UI:StepRow(parent,key,12,y,505,
        function() return IS:Get(value) end,
        function(v) IS:Set(value,v) end,step or 1)
end

-- License notice (2/3): stage-1 UI stores options, not protected combat hooks.
-- Never represent action bar glow, interrupt detection, or audio as operational.
function KR.Pages:Indicators(parent)
    local body=scroll(parent,1510)
    local warning=card(body,-12,105)
    label(warning,"IND_TITLE",15,-14,500,true)
    label(warning,"IND_NOT_ACTIVE",15,-44,515)

    local highlight=card(body,-132,280)
    label(highlight,"IND_HIGHLIGHT_TITLE",15,-13,510,true)
    boolRow(highlight,"IND_HIGHLIGHT_ENABLE","actionHighlight",-41)
    local style={{"border","IND_STYLE_BORDER"},{"glow","IND_STYLE_GLOW"}}
    local kind={{"first","IND_FIRST"},{"multiple","IND_MULTIPLE"}}
    UI:ChoiceRow(highlight,"IND_HIGHLIGHT_STYLE",12,-88,505,
        function() return IS:Get("highlightStyle") end,
        function(v) IS:Set("highlightStyle",v) end,style)
    UI:ChoiceRow(highlight,"IND_HIGHLIGHT_COUNT",12,-131,505,
        function() return IS:Get("highlightCount") end,
        function(v) IS:Set("highlightCount",v) end,kind)
    stepRow(highlight,"IND_HIGHLIGHT_STRENGTH","highlightStrength",-177,10)
    label(highlight,"IND_HIGHLIGHT_UNSUPPORTED",14,-222,500)

    local defensive=card(body,-432,291)
    label(defensive,"IND_DEFENSIVE_TITLE",15,-13,510,true)
    boolRow(defensive,"IND_DEFENSIVE_ENABLE","defensiveEnabled",-41)
    boolRow(defensive,"IND_DEFENSIVE_COMBAT","defensiveCombatOnly",-83)
    stepRow(defensive,"IND_DEFENSIVE_SLOTS","defensiveSlots",-125,1)
    stepRow(defensive,"IND_DEFENSIVE_SIZE","defensiveSize",-168,4)
    stepRow(defensive,"IND_DEFENSIVE_ALPHA","defensiveAlpha",-211,5)
    label(defensive,"IND_DEFENSIVE_PENDING",15,-252,490)

    local interrupt=card(body,-745,295)
    label(interrupt,"IND_INTERRUPT_TITLE",15,-13,510,true)
    boolRow(interrupt,"IND_INTERRUPT_ENABLE","interruptEnabled",-41)
    boolRow(interrupt,"IND_INTERRUPT_TEXT","interruptText",-83)
    boolRow(interrupt,"IND_INTERRUPT_SOUND","interruptSound",-125)
    stepRow(interrupt,"IND_INTERRUPT_SIZE","interruptSize",-168,4)
    stepRow(interrupt,"IND_INTERRUPT_SPELL","interruptSpellID",-211,1)
    label(interrupt,"IND_INTERRUPT_PENDING",15,-252,490)

    local sound=card(body,-1061,246)
    label(sound,"IND_SOUND_TITLE",15,-13,510,true)
    boolRow(sound,"IND_SOUND_ENABLE","audioEnabled",-40)
    boolRow(sound,"IND_SOUND_IMPORTANT","audioImportant",-80)
    boolRow(sound,"IND_SOUND_DEFENSIVE","audioDefensive",-120)
    boolRow(sound,"IND_SOUND_INTERRUPT","audioInterrupt",-160)
    stepRow(sound,"IND_SOUND_THROTTLE","audioCooldown",-200,1)

    local future=card(body,-1325,165)
    label(future,"IND_WIDGET_TITLE",15,-13,510,true)
    label(future,"IND_WIDGET_PENDING",15,-48,510)
    label(future,"IND_SOUND_NO_PLAY",15,-97,510)
end

function KR.Pages:Profiles(parent)
    local body=scroll(parent,900)
    local intro=card(body,-14,140)
    label(intro,"APP_TITLE",15,-14,500,true)
    label(intro,"APP_EXPLANATION",15,-46,505)
    local current=raw(intro,15,-108,500)

    local listing=card(body,-176,300)
    label(listing,"APP_SELECT_TITLE",15,-13,500,true)
    local items={}
    local selected="Classic"
    local listButtons={}
    local selectRefresh
    for i=1,5 do
        local b=button(listing,"APP_SELECT",13,-40-(i-1)*41,244,function()
            local entry=items[(i-1)+listing.offset]
            if entry then selected=entry.id;selectRefresh() end
        end)
        listButtons[#listButtons+1]=b
    end
    listing.offset=1
    button(listing,"SPELL_PREVIOUS",279,-45,111,function()
        listing.offset=math.max(1,listing.offset-5);selectRefresh()
    end)
    button(listing,"SPELL_NEXT",397,-45,110,function()
        listing.offset=math.min(math.max(1,#items-4),listing.offset+5);selectRefresh()
    end)
    local function updateList()
        local shown=items
        local activeName=AP:Active()
        for _,entry in ipairs(items) do
            if entry.id==activeName then activeName=entry.name;break end
        end
        current:SetText(KR:Format("APP_CURRENT",activeName))
        for i,b in ipairs(listButtons) do
            local item=shown[listing.offset+i-1]
            if item then
                b:SetText((item.id==selected and "[*] " or "")..item.name)
                b:Show()
            else b:Hide() end
        end
    end
    selectRefresh=function()
        items=AP:List()
        local found=false
        for _,item in ipairs(items) do if item.id==selected then found=true end end
        if not found then selected="Classic" end
        listing.offset=math.min(listing.offset,math.max(1,#items-4))
        updateList()
    end

    local actions=card(body,-494,267)
    label(actions,"APP_ACTIONS",15,-13,510,true)
    label(actions,"APP_NAME_HINT",15,-45,510)
    local name=CreateFrame("EditBox",nil,actions,"InputBoxTemplate")
    name:SetPoint("TOPLEFT",20,-77);name:SetSize(470,26)
    name:SetAutoFocus(false);name:SetMaxLetters(32)
    name:SetScript("OnEnterPressed",function(self)self:ClearFocus()end)
    name:SetScript("OnEscapePressed",function(self)self:ClearFocus()end)
    local feedback=raw(actions,15,-216,505)
    local function operation(kind)
        local input=name:GetText() or ""
        local ok, reason
        if kind=="create" then
            local id
            id,reason=AP:Create(input)
            ok=id~=nil
            if id then selected=id end
        elseif kind=="duplicate" then
            local id
            id,reason=AP:Create(input,selected)
            ok=id~=nil
            if id then selected=id end
        elseif kind=="rename" then ok=AP:Rename(selected,input)
        elseif kind=="apply" then ok=AP:Apply(selected)
        elseif kind=="reset" then ok=AP:ResetAppearance()
        elseif kind=="bind" then ok=AP:AssignCurrent(selected) end
        feedback:SetText(KR:L(ok and "APP_SUCCESS" or "APP_FAILURE"))
        selectRefresh()
    end
    button(actions,"APP_CREATE",14,-119,153,function()operation("create")end)
    button(actions,"APP_DUPLICATE",180,-119,153,function()operation("duplicate")end)
    button(actions,"APP_RENAME",345,-119,159,function()operation("rename")end)
    button(actions,"APP_APPLY",14,-158,153,function()operation("apply")end)
    button(actions,"APP_RESET",180,-158,153,function()operation("reset")end)
    button(actions,"APP_BIND",345,-158,159,function()operation("bind")end)

    local settings=card(body,-781,102)
    label(settings,"APP_AUTOSPEC_NOTE",15,-14,500)
    UI:ToggleRow(settings,"APP_AUTOSPEC",12,-51,505,
        function()return AP:GetAutoSpec()end,
        function(v)AP:SetAutoSpec(v)end)

    local confirmation=CreateFrame("Frame",nil,parent)
    confirmation:SetSize(390,153)
    confirmation:SetPoint("CENTER",parent,"CENTER",0,0)
    confirmation:SetFrameStrata("DIALOG")
    UI:Background(confirmation,C.panel);UI:Border(confirmation,C.cyan,2)
    label(confirmation,"APP_DELETE_CONFIRM",17,-18,340,true)
    local confirmationLabel=raw(confirmation,17,-55,350)
    local pending
    button(confirmation,"APP_DELETE_YES",16,-103,167,function()
        if pending then
            local ok=AP:Delete(pending)
            feedback:SetText(KR:L(ok and "APP_SUCCESS" or "APP_FAILURE"))
        end
        pending=nil;confirmation:Hide();selectRefresh()
    end)
    button(confirmation,"APP_DELETE_NO",200,-103,168,function()
        pending=nil;confirmation:Hide()
    end)
    confirmation:Hide()
    button(actions,"APP_DELETE",14,-191,153,function()
        if selected=="Classic" or selected=="Minimal" or selected=="Compact" then
            feedback:SetText(KR:L("APP_CANNOT_DELETE"))
            return
        end
        pending=selected
        confirmationLabel:SetText(selected)
        confirmation:Show()
    end)
    KR.appearancePageRefresh=selectRefresh
    selectRefresh()
end

-- Copyright notice (3/3): Vi22Rus (c) 2026; see LICENSE in repository root.
-- Preserve copyright notices in authorized copies.
