-- Kord Rotation (c) 2026 Vi22Rus. All rights reserved.
-- Personal use under the root LICENSE; no unauthorized redistribution or derivatives.
-- Missing license file does not change existing lawful rights.

local addonName, KR = ...
KR.AppearanceProfiles = KR.AppearanceProfiles or {}
local M=KR.AppearanceProfiles
local panelKeys={"slotCount","primarySize","secondarySize","gap","scale","alpha",
    "secondaryAlpha","direction","primaryAtEnd","borderStyle","showNumbers"}
local presets={
    Classic={slotCount=3,primarySize=72,secondarySize=52,gap=6,scale=100,
        alpha=100,secondaryAlpha=100,direction="horizontal",primaryAtEnd=false,
        borderStyle="standard",showNumbers=true},
    Minimal={slotCount=1,primarySize=60,secondarySize=44,gap=4,scale=100,
        alpha=90,secondaryAlpha=90,direction="horizontal",primaryAtEnd=false,
        borderStyle="none",showNumbers=false},
    Compact={slotCount=3,primarySize=52,secondarySize=38,gap=3,scale=90,
        alpha=95,secondaryAlpha=95,direction="horizontal",primaryAtEnd=false,
        borderStyle="minimal",showNumbers=false},
}
local function snapshot()
    local panel=KR.db and KR.db.panel or {}
    local copy={}
    for _,key in ipairs(panelKeys) do
        copy[key]=panel[key]
    end
    return copy
end
local function normalizedName(name)
    if type(name)~="string" then return nil end
    name=name:match("^%s*(.-)%s*$")
    if name=="" or #name>32 or name:find("[%c/]") or name:find(string.char(92),1,true) then return nil end
    return name
end
local function storage()
    if not KR.db then return nil end
    if type(KR.db.appearanceProfiles)~="table" then KR.db.appearanceProfiles={} end
    return KR.db.appearanceProfiles
end
local function validID(id)
    return type(id)=="string" and #id>0 and #id<=40
        and (id:match("^custom:[%w_%-]+$") or presets[id]~=nil)
end
local function payload(id)
    if presets[id] then return presets[id] end
    local saved=storage()
    local entry=saved and saved[id]
    return type(entry)=="table" and type(entry.panel)=="table" and entry.panel or nil
end
local function newID()
    local saved=storage()
    for i=1,9999 do
        local id="custom:"..i
        if not saved[id] then return id end
    end
end

-- License notice (2/3): appearance presets are not rotation profiles; never overwrite
-- class/tree spell preferences when applying or deleting an appearance preset.
function M:List()
    local out={{id="Classic",name="Classic",builtIn=true},
        {id="Minimal",name="Minimal",builtIn=true},
        {id="Compact",name="Compact",builtIn=true}}
    local saved=storage() or {}
    for id,item in pairs(saved) do
        if type(id)=="string" and id:match("^custom:%d+$") and type(item)=="table"
            and type(item.name)=="string" then
            out[#out+1]={id=id,name=item.name,builtIn=false}
        end
    end
    table.sort(out,function(a,b)
        if a.builtIn~=b.builtIn then return a.builtIn end
        return a.name < b.name or (a.name==b.name and a.id < b.id)
    end)
    return out
end
function M:Create(name,fromID)
    local valid=normalizedName(name)
    local saved=storage()
    if not valid or not saved then return nil,"invalid_name" end
    local source=fromID and payload(fromID) or snapshot()
    if not source then return nil,"missing_source" end
    local id=newID()
    if not id then return nil,"limit" end
    local copy={}
    for _,key in ipairs(panelKeys) do copy[key]=source[key] end
    saved[id]={name=valid,panel=copy}
    return id
end
function M:Rename(id,name)
    local saved=storage()
    local valid=normalizedName(name)
    if not saved or not saved[id] or not valid or presets[id] then return false end
    saved[id].name=valid
    return true
end
function M:Delete(id)
    local saved=storage()
    if not saved or not saved[id] or presets[id] then return false end
    saved[id]=nil
    if KR.db.activeAppearance==id then KR.db.activeAppearance="Classic" end
    return true
end
function M:Apply(id)
    if not validID(id) then return false end
    local source=payload(id)
    if not source or not KR.db then return false end
    for _,key in ipairs(panelKeys) do
        if source[key]~=nil then KR:SetPanelLayout(key,source[key]) end
    end
    KR.db.activeAppearance=id
    return true
end
function M:Active()
    if not KR.db then return "Classic" end
    local id=KR.db.activeAppearance
    return validID(id) and payload(id) and id or "Classic"
end
function M:GetAutoSpec()
    return KR.db and KR.db.appearancePerSpec==true or false
end
function M:SetAutoSpec(value)
    if type(value)~="boolean" or not KR.db then return false end
    KR.db.appearancePerSpec=value
    return true
end
function M:AssignCurrent(id)
    if not validID(id) or not payload(id) or not KR.charDB then return false end
    local profile=KR.RotationSettings and KR.RotationSettings:GetProfileID()
    if not profile then return false end
    if type(KR.charDB.appearanceBindings)~="table" then KR.charDB.appearanceBindings={} end
    KR.charDB.appearanceBindings[profile]=id
    return true
end
function M:OnCharacterRefresh()
    if not self:GetAutoSpec() or not KR.charDB then return end
    local profile=KR.RotationSettings and KR.RotationSettings:GetProfileID()
    local bindings=KR.charDB.appearanceBindings
    local id=profile and type(bindings)=="table" and bindings[profile]
    if id and id~=KR.db.activeAppearance then self:Apply(id) end
end
function M:ResetAppearance()
    return self:Apply("Classic")
end

-- Copyright notice (3/3): (c) 2026 Vi22Rus; root LICENSE governs use.
-- Retain attribution in all authorized copies.
