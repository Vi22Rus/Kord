-- Kord Rotation (c) 2026 Vi22Rus. All rights reserved.
-- Stage 2.5: read-only action-slot discovery. Never presses or rewrites a button.
local addonName, KR = ...
KR.ActionBarScanner = KR.ActionBarScanner or {}
local S = KR.ActionBarScanner
local MAX_SLOT, MAX_BUTTONS, TTL = 180, 1200, 0.6
local STANDARD = {
    "ActionButton", "MultiBarBottomLeftButton", "MultiBarBottomRightButton",
    "MultiBarRightButton", "MultiBarLeftButton", "MultiBar5Button",
    "MultiBar6Button", "MultiBar7Button",
}
local DOMINOS_EXTRA = {
    "MultiBarRightActionButton", "MultiBarLeftActionButton",
    "MultiBarBottomRightActionButton", "MultiBarBottomLeftActionButton",
    "MultiBar5ActionButton", "MultiBar6ActionButton", "MultiBar7ActionButton",
}
local LIBRARIES = {
    "LibActionButton-1.0", "LibActionButton-1.0-ElvUI",
    "LibActionButton-1.0-KkthnxUI", "LibActionButton-1.0-NDui",
    "LibActionButton-1.0-ls",
}
local CHANNELS = {"actionbar","bindings","identity","talents"}
local function isInteger(n,limit)
    return type(n)=="number" and n==n and n==math.floor(n)
        and n>=1 and n<=limit
end
local function safeField(object,key)
    if not KR.GameAPI or not KR.GameAPI.ReadField then return nil end
    local v=KR.GameAPI:ReadField(object,key)
    return v.status=="READY" and v.value or nil
end
local function safeMethod(object,name,...)
    local fn=safeField(object,name)
    if type(fn)~="function" then return false,nil end
    local ok,value=pcall(fn,object,...)
    if not ok then return false,nil end
    -- Method results must not contain protected/secret values.
    if KR.GameAPI and KR.GameAPI.IsSafeValue then
        if not KR.GameAPI:IsSafeValue(value) then return false,nil end
    elseif type(issecretvalue)=="function" then
        local good,secret=pcall(issecretvalue,value)
        if not good or secret then return false,nil end
    end
    return true,value
end
local function safeGlobal(name)
    if type(_G)~="table" then return nil end
    local ok,v=pcall(function() return _G[name] end)
    if not ok then return nil end
    if KR.GameAPI and KR.GameAPI.IsSafeValue
        and not KR.GameAPI:IsSafeValue(v) then return nil end
    return v
end
local function now()
    if not KR.GameAPI then return nil end
    local t=KR.GameAPI:Read("GetTime","number")
    return t.status=="READY" and t.value or nil
end
local function read(name,kind,...)
    if not KR.GameAPI then return {status="UNAVAILABLE",reason="adapter_missing"} end
    return KR.GameAPI:Read(name,kind,...)
end
local function actionSlot(button)
    local fn=safeField(button,"GetAttribute")
    if type(fn)=="function" then
        local ok,v=safeMethod(button,"GetAttribute","action")
        if not ok then return nil end
        if v~=nil then
            if isInteger(v,MAX_SLOT) then return v end
            return nil
        end
    end
    -- In some classic/modern bar implementations the actual page is provided
    -- by GetPagedID; never infer it from the button's own index.
    local getPaged=safeField(button,"GetPagedID")
    if type(getPaged)=="function" then
        local ok,paged=safeMethod(button,"GetPagedID")
        if not ok then return nil end
        if paged~=nil then
            if isInteger(paged,MAX_SLOT) then return paged end
            return nil
        end
    end
    -- LAB can expose a slot through GetAction() -> ("action", slot).
    -- Direct "spell"/"macro"/"item" buttons are deliberately not slots.
    local getAction=safeField(button,"GetAction")
    if type(getAction)=="function" then
        local ok,kind,id=pcall(getAction,button)
        if not ok then return nil end
        if not KR.GameAPI or not KR.GameAPI.IsSafeValue
            or not KR.GameAPI:IsSafeValue(kind)
            or not KR.GameAPI:IsSafeValue(id) then return nil end
        if kind=="action" and isInteger(id,MAX_SLOT) then return id end
        return nil
    end
    local raw=safeField(button,"action")
    if isInteger(raw,MAX_SLOT) then return raw end
    return nil
end
local function visible(button)
    local ok,v=safeMethod(button,"IsVisible")
    return ok and v==true
end
local function inspect(button,source)
    if not visible(button) then return nil end
    local slot=actionSlot(button)
    if not slot then return nil end
    local presence=read("C_ActionBar.HasAction","boolean",slot)
    if presence.status~="READY" then presence=read("HasAction","boolean",slot) end
    if presence.status~="READY" or presence.value~=true then return nil end
    local info=KR.GameAPI and KR.GameAPI:ReadTuple("GetActionInfo",{"string","number"},slot)
    if not info or info.status~="READY" then return nil end
    local kind,id=info.value[1],info.value[2]
    if kind~="spell" and kind~="SPELL" then return nil end
    if not isInteger(id,99999999) then return nil end
    local name
    local ok,n=safeMethod(button,"GetName")
    if ok and type(n)=="string" and #n<=120 then name=n end
    return {slot=slot,spellID=id,source=source,buttonName=name,button=button}
end
local function shallowCopy(record)
    return {slot=record.slot,spellID=record.spellID,
        source=record.source,buttonName=record.buttonName}
end
local function list()
    local results,seen={},{}
    local function add(button,kind)
        if not button or #results>=MAX_BUTTONS then return end
        if KR.GameAPI and KR.GameAPI.IsSafeValue
            and not KR.GameAPI:IsSafeValue(button) then return end
        if seen[button] then return end
        seen[button]=true
        results[#results+1]={button=button,source=kind}
    end
    for _,prefix in ipairs(STANDARD) do
        for i=1,12 do add(safeGlobal(prefix..i),"Blizzard") end
    end
    for i=1,180 do
        add(safeGlobal("BT4Button"..i),"Bartender4")
        add(safeGlobal("DominosActionButton"..i),"Dominos")
    end
    for _,prefix in ipairs(DOMINOS_EXTRA) do
        for i=1,12 do add(safeGlobal(prefix..i),"Dominos") end
    end
    for bar=1,15 do
        for i=1,12 do add(safeGlobal("ElvUI_Bar"..bar.."Button"..i),"ElvUI") end
    end
    -- Use a library already loaded by the other UI addon. Never load or
    -- bundle LibActionButton and never register hooks or protected actions.
    local stub=safeGlobal("LibStub")
    if type(stub)=="function" or type(stub)=="table" then
        for _,library in ipairs(LIBRARIES) do
            local ok,lab=pcall(stub,library,true)
            if ok and lab and type(lab)=="table" then
                local found,buttons=safeMethod(lab,"GetAllButtons")
                if found and type(buttons)=="table" then
                    local success=pcall(function()
                        for key,value in pairs(buttons) do
                            local button
                            if (type(key)=="table" or type(key)=="userdata") then
                                button=key
                            elseif type(value)=="table" or type(value)=="userdata" then
                                button=value
                            end
                            add(button,"LibActionButton")
                        end
                    end)
                    if not success then return nil,"lab_scan_failed" end
                end
            end
        end
    end
    return results
end
function S:Invalidate(reason)
    self.dirty=true
    self.lastInvalidation=reason or "manual"
end
function S:Initialize()
    if self.initialized then return true end
    if not KR.EventBus or type(KR.EventBus.Subscribe)~="function" then return false end
    for _,ch in ipairs(CHANNELS) do
        if not KR.EventBus:Subscribe(ch,"ActionBarScanner",function(event)
            S:Invalidate(event)
        end) then return false end
    end
    self.initialized=true
    self:Invalidate("initialize")
    return true
end
function S:ReadNow()
    local candidates,reason=list()
    local entries,private={},{}
    if candidates then
        for _,candidate in ipairs(candidates) do
            local found=inspect(candidate.button,candidate.source)
            if found then
                private[#private+1]=found
                entries[#entries+1]=shallowCopy(found)
            end
        end
    end
    table.sort(entries,function(a,b)
        if a.spellID~=b.spellID then return a.spellID<b.spellID end
        if a.slot~=b.slot then return a.slot<b.slot end
        return (a.buttonName or "")<(b.buttonName or "")
    end)
    self.entries=private
    self.revision=(self.revision or 0)+1
    self.timestamp=now()
    self.dirty=false
    self.busRevisions={}
    for _,ch in ipairs(CHANNELS) do
        self.busRevisions[ch]=KR.EventBus and KR.EventBus.revisions
            and (KR.EventBus.revisions[ch] or 0) or 0
    end
    -- No visible, verifiable button does NOT establish an empty bar.
    self.snapshot={status=#entries>0 and "READY" or "UNKNOWN",
        reason=reason or (#entries==0 and "no_confirmed_visible_slots" or nil),
        coverage="CONFIRMED_BUTTONS_ONLY",method="visible_buttons",
        revision=self.revision,observedAt=self.timestamp,entries=entries}
    return self:GetSnapshot(false)
end
function S:GetSnapshot(rebuild)
    if rebuild==nil then rebuild=true end
    if rebuild then
        local time=now()
        if not self.snapshot or self.dirty or not time or not self.timestamp
            or time<self.timestamp or time-self.timestamp>=TTL then
            return self:ReadNow()
        end
        for _,ch in ipairs(CHANNELS) do
            local revision=KR.EventBus and KR.EventBus.revisions
                and (KR.EventBus.revisions[ch] or 0) or 0
            if revision~=(self.busRevisions[ch] or 0) then return self:ReadNow() end
        end
    end
    local data=self.snapshot or {status="UNKNOWN",entries={},reason="not_initialized"}
    local result={}
    for k,v in pairs(data) do
        if k=="entries" then
            result.entries={}
            for i,item in ipairs(v) do
                result.entries[i]={slot=item.slot,spellID=item.spellID,
                    source=item.source,buttonName=item.buttonName}
            end
        else result[k]=v end
    end
    return result
end
function S:FindSpell(id)
    if not isInteger(id,99999999) then
        return {status="UNKNOWN",reason="invalid_spell_id"}
    end
    self:GetSnapshot()
    local selected
    for _,item in ipairs(self.entries or {}) do
        if item.spellID==id then
            -- Strict revalidation even before TTL: macro, paging, visibility
            -- and slot reassignment can change without a Blizzard event.
            local live=inspect(item.button,item.source)
            if live and live.slot==item.slot and live.spellID==id then
                if not selected or live.slot<selected.slot then selected=live end
            else
                self:Invalidate("button_changed")
            end
        end
    end
    if selected then
        local copy=shallowCopy(selected)
        copy.status="READY"
        return copy
    end
    return {status="UNKNOWN",reason="spell_not_confirmed_on_visible_bar"}
end
-- Copyright notice: see root LICENSE.
