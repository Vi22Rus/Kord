-- Kord Rotation (c) 2026 Vi22Rus. All rights reserved.
-- Stage 2.6: read-only binding resolver. Never sets keys or clicks buttons.
local addonName,KR=...
KR.BindingResolver=KR.BindingResolver or {}
local R=KR.BindingResolver
local channels={"bindings","actionbar","identity","talents"}
local names={
    ActionButton="ACTIONBUTTON",
    MultiBarBottomLeftButton="MULTIACTIONBAR1BUTTON",
    MultiBarBottomRightButton="MULTIACTIONBAR2BUTTON",
    MultiBarRightButton="MULTIACTIONBAR3BUTTON",
    MultiBarLeftButton="MULTIACTIONBAR4BUTTON",
    MultiBar5Button="MULTIACTIONBAR5BUTTON",
    MultiBar6Button="MULTIACTIONBAR6BUTTON",
    MultiBar7Button="MULTIACTIONBAR7BUTTON",
}
local function validID(v)
    return type(v)=="number" and v==math.floor(v) and v>=1 and v<=99999999
end
local function safeField(object,key)
    if not KR.GameAPI then return nil end
    local v=KR.GameAPI:ReadField(object,key)
    return v.status=="READY" and v.value or nil
end
local function safeCall(button,method)
    local fn=safeField(button,method)
    if type(fn)~="function" then return nil end
    local ok,result=pcall(fn,button)
    if not ok or not KR.GameAPI:IsSafeValue(result) then return nil end
    return result
end
local function validCommand(v)
    return type(v)=="string" and #v>0 and #v<=120
        and not string.find(v,"[%c]")
        and (string.match(v,"^[A-Z0-9_]+$")
            or string.match(v,"^CLICK [A-Za-z0-9_]+:LeftButton$"))
end
local function standard(base)
    local prefix,num
    for n,p in pairs(names) do
        local i=string.match(base,"^"..n.."(%d+)$")
        if i then prefix,num=p,tonumber(i) end
    end
    if prefix and num and num>=1 and num<=12 then
        return prefix..num
    end
    return nil
end
-- EllesmereUI's EABButton index is its stable physical slot, not the
-- potentially paged GetAttribute("action") value. Mapping comes from
-- EllesmereUIActionBars/EUI_ActionBars_Secure.lua BAR_SLOT_OFFSETS/BINDING_MAP.
local function ellesmere(index)
    if not index or index<1 or index>180 then return nil end
    local i=((index-1)%12)+1
    if index<=12 then return "ACTIONBUTTON"..i end
    if index<=24 then return "EUI_BAR9_BUTTON"..i end
    if index<=36 then return "MULTIACTIONBAR3BUTTON"..i end
    if index<=48 then return "MULTIACTIONBAR4BUTTON"..i end
    if index<=60 then return "MULTIACTIONBAR2BUTTON"..i end
    if index<=72 then return "MULTIACTIONBAR1BUTTON"..i end
    if index>=109 and index<=120 then return "EUI_BAR10_BUTTON"..i end
    if index>=145 and index<=156 then return "MULTIACTIONBAR5BUTTON"..i end
    if index>=157 and index<=168 then return "MULTIACTIONBAR6BUTTON"..i end
    if index>=169 and index<=180 then return "MULTIACTIONBAR7BUTTON"..i end
    return nil
end
local function commandFor(candidate)
    local button=candidate.button
    if not button then return nil,"button_unavailable" end
    local name=candidate.buttonName
    if candidate.source=="EllesmereUI" then
        local index=type(name)=="string"
            and tonumber(string.match(name,"^EABButton(%d+)$")) or nil
        -- A custom page can override the original key routing through
        -- secure clicks. A binding attribute alone cannot prove that route.
        if not index or candidate.slot~=index then
            return nil,"dynamic_routing_unverified"
        end
    end
    -- Prefer the actual button API (LAB, Dominos, Bartender) over guesses.
    local method=safeField(button,"GetBindingAction")
    if type(method)=="function" then
        local cmd=safeCall(button,"GetBindingAction")
        if validCommand(cmd) then return cmd,"button_api" end
        return nil,"button_binding_unknown"
    end
    local attrMethod=safeField(button,"GetAttribute")
    if type(attrMethod)=="function" then
        local ok,cmd=pcall(attrMethod,button,"binding")
        if not ok or not KR.GameAPI:IsSafeValue(cmd) then
            return nil,"protected_binding_attribute"
        end
        if cmd~=nil then
            if validCommand(cmd) then return cmd,"button_attribute" end
            return nil,"binding_attribute_unknown"
        end
    end
    local name=candidate.buttonName
    if type(name)~="string" then return nil,"button_name_unavailable" end
    if candidate.source=="Blizzard" then
        local cmd=standard(name)
        if cmd then return cmd,"blizzard_command" end
    elseif candidate.source=="EllesmereUI" then
        local index=tonumber(string.match(name,"^EABButton(%d+)$"))
        if index then
            -- When dynamically paged, an override binding can route to a
            -- different action. A raw GetBindingKey cannot prove the override.
            if candidate.slot~=index then return nil,"dynamic_routing_unverified" end
            local cmd=ellesmere(index)
            if cmd then return cmd,"ellesmere_command" end
        end
    end
    return nil,"button_command_unverified"
end
local function formatKey(key)
    if type(key)~="string" then return nil end
    local s=string.upper(key)
    if #s==0 or #s>64 or string.find(s,"[%c]") then return nil end
    s=string.gsub(s,"SHIFT%-","S+")
    s=string.gsub(s,"CTRL%-","C+")
    s=string.gsub(s,"ALT%-","A+")
    s=string.gsub(s,"META%-","M+")
    s=string.gsub(s,"BUTTON(%d+)","M%1")
    s=string.gsub(s,"MOUSEWHEELUP","MWUP")
    s=string.gsub(s,"MOUSEWHEELDOWN","MWDN")
    return s
end
local function binding(command)
    if not validCommand(command) then return {status="UNKNOWN",reason="invalid_binding_command"} end
    local read=KR.GameAPI and KR.GameAPI:ReadValues("GetBindingKey",command)
    if not read or read.status~="READY" then
        return {status="UNKNOWN",reason="binding_api_unavailable"}
    end
    local keys={}
    for i=1,2 do
        local raw=read.value[i]
        if raw~=nil then
            local label=formatKey(raw)
            if not label then return {status="UNKNOWN",reason="binding_value_invalid"} end
            keys[#keys+1]={raw=raw,label=label}
        end
    end
    if #keys==0 then return {status="UNBOUND",reason="no_binding_keys"} end
    -- When present, GetBindingAction must agree with this command. Some
    -- secure override routes are not observable and therefore remain UNKNOWN.
    if KR.GameAPI:Probe("GetBindingAction").status=="READY" then
        for _,key in ipairs(keys) do
            local result=KR.GameAPI:Read("GetBindingAction","string",key.raw)
            if result.status~="READY" or result.value~=command then
                return {status="UNKNOWN",reason="binding_reverse_mismatch"}
            end
        end
    end
    return {status="READY",keys=keys,bindingLabel=keys[1].label}
end
local function instant()
    if not KR.GameAPI then return nil end
    local v=KR.GameAPI:Read("GetTime","number")
    if v.status=="READY" then return v.value end
end
function R:Invalidate(reason)
    self.dirty=true
    self.reason=reason or "manual"
end
function R:Initialize()
    if self.initialized then return true end
    if not KR.EventBus then return false end
    for _,ch in ipairs(channels) do
        if not KR.EventBus:Subscribe(ch,"BindingResolver",function(event)
            R:Invalidate(event)
        end) then return false end
    end
    self.initialized=true
    return true
end
-- Cache only binding-command lookups. Button and slot verification is NEVER
-- cached here; ActionBarScanner rechecks live button state on every Resolve.
function R:ReadBinding(command)
    local changed=self.dirty
    local revisions=KR.EventBus and KR.EventBus.revisions or {}
    self.cacheRevisions=self.cacheRevisions or {}
    for _,channel in ipairs(channels) do
        local current=revisions[channel] or 0
        if self.cacheRevisions[channel]~=current then changed=true end
        self.cacheRevisions[channel]=current
    end
    if changed then
        self.bindingCache={}
        self.dirty=false
    end
    self.bindingCache=self.bindingCache or {}
    local time=instant()
    local stored=self.bindingCache[command]
    if stored and time and stored.time and time>=stored.time
        and time-stored.time<0.5 then
        return stored.data
    end
    local data=binding(command)
    self.bindingCache[command]={time=time,data=data}
    return data
end
function R:Resolve(spellID)
    if not validID(spellID) then
        return {status="UNKNOWN",reason="invalid_spell_id"}
    end
    if not KR.ActionBarScanner or not KR.ActionBarScanner.GetVerifiedButtons then
        return {status="UNKNOWN",reason="scanner_unavailable"}
    end
    local buttons=KR.ActionBarScanner:GetVerifiedButtons(spellID)
    if #buttons==0 then
        return {status="UNKNOWN",reason="no_confirmed_visible_button"}
    end
    -- The scanner revalidates all buttons on EVERY resolution; no stale
    -- shortcut based solely on cache TTL, manual keyLabel or spell name.
    table.sort(buttons,function(a,b)
        if a.slot~=b.slot then return a.slot<b.slot end
        return (a.buttonName or "")<(b.buttonName or "")
    end)
    local best,unbound,uncertain
    for _,candidate in ipairs(buttons) do
        local cmd,origin=commandFor(candidate)
        if cmd then
            local b=self:ReadBinding(cmd)
            if b.status=="READY" then
                local chosen={status="READY",spellID=spellID,slot=candidate.slot,
                    command=cmd,source=candidate.source,bindingSource=origin,
                    bindingLabel=b.bindingLabel,keys={},observedAt=instant()}
                for i,key in ipairs(b.keys) do
                    chosen.keys[i]={raw=key.raw,label=key.label}
                end
                if not best or chosen.slot<best.slot then best=chosen end
            elseif b.status=="UNBOUND" then
                unbound=true
            else uncertain=true end
        else uncertain=true end
    end
    if best then return best end
    if uncertain then return {status="UNKNOWN",reason="binding_not_verified"} end
    if unbound then return {status="UNBOUND",reason="confirmed_button_without_key"} end
    return {status="UNKNOWN",reason="no_binding"}
end
-- Manual RotationSettings.keyLabel is deliberately not read here.
-- Copyright notice: see LICENSE in repository root.
