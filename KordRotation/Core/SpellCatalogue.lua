-- Kord Rotation (c) 2026 Vi22Rus. All rights reserved.
-- Stage 2.4. Player spellbook only; read-only and fail-closed.
local addonName, KR = ...
KR.SpellCatalogue = KR.SpellCatalogue or {}
local S = KR.SpellCatalogue
local MAX_LINES, MAX_SLOTS, MAX_ENTRIES = 40, 800, 2500
local TTL = 2

local function validID(n)
    return type(n)=="number" and n==n and n==math.floor(n)
        and n>=1 and n<=99999999
end
local function nonnegative(n, max)
    return type(n)=="number" and n==n and n==math.floor(n)
        and n>=0 and n<=max
end
local function safeField(value, key)
    if not KR.GameAPI or type(KR.GameAPI.ReadField)~="function" then return nil end
    local field=KR.GameAPI:ReadField(value,key)
    return field.status=="READY" and field.value or nil
end
local function get(name,...)
    if not KR.GameAPI or type(KR.GameAPI.ReadValues)~="function" then
        return {status="UNAVAILABLE",reason="adapter_missing"}
    end
    return KR.GameAPI:ReadValues(name,...)
end
local function single(name,expected,...)
    if not KR.GameAPI or type(KR.GameAPI.Read)~="function" then return nil end
    local value=KR.GameAPI:Read(name,expected,...)
    return value.status=="READY" and value.value or nil
end
local function clock()
    return single("GetTime","number")
end
local function freshResult(status,reason,method,entries)
    return {status=status,reason=reason,method=method,entries=entries or {}}
end
local function copy(value)
    if type(value)~="table" then return value end
    local result={}
    for k,v in pairs(value) do
        if type(v)=="table" then result[k]=copy(v) else result[k]=v end
    end
    return result
end

local function addEntry(entries,seen,id,name,texture,rankLabel,rankNumber,source)
    if not validID(id) or type(name)~="string" or name=="" then
        return false
    end
    -- Spell IDs, not localized names, are the stable keys. Different learned
    -- ranks remain independent records even when their names are identical.
    if seen[id] then return true end
    if #entries>=MAX_ENTRIES then return false end
    if type(rankLabel)~="string" or rankLabel=="" then rankLabel=nil end
    if not nonnegative(rankNumber,100) then
        local suffix=type(rankLabel)=="string" and string.match(rankLabel,"(%d+)%s*$")
        rankNumber=suffix and tonumber(suffix) or nil
        if not nonnegative(rankNumber,100) then rankNumber=nil end
    end
    if type(texture)~="string" and type(texture)~="number" then texture=nil end
    entries[#entries+1]={
        id=id,name=name,texture=texture,rank=rankLabel,
        displayName=rankLabel and (name.." ("..rankLabel..")") or name,
        rankNumber=rankNumber,
        source=source,known=true,
    }
    seen[id]=true
    return true
end
local function legacy()
    local tabs=single("GetNumSpellTabs","number")
    if not tabs then return nil,"legacy_api_unavailable" end
    if not nonnegative(tabs,MAX_LINES) then return nil,"invalid_spellbook_tabs" end
    if tabs==0 then return nil,"legacy_zero_tabs_unverified" end
    if not KR.GameAPI or KR.GameAPI:Probe("GetSpellTabInfo").status~="READY"
        or KR.GameAPI:Probe("GetSpellBookItemInfo").status~="READY" then
        return nil,"legacy_api_unavailable"
    end
    local entries,seen,scanned={}, {},0
    local bookType=type(BOOKTYPE_SPELL)=="string" and BOOKTYPE_SPELL or "spell"
    for tab=1,tabs do
        local tabInfo=get("GetSpellTabInfo",tab)
        if tabInfo.status~="READY" then return nil,"spellbook_tab_read_failed" end
        local values=tabInfo.value
        local offset,count=values[3],values[4]
        if not nonnegative(offset,MAX_SLOTS) or not nonnegative(count,MAX_SLOTS)
            or offset+count>MAX_SLOTS then
            return nil,"spellbook_tab_invalid"
        end
        for slot=offset+1,offset+count do
            scanned=scanned+1
            if scanned>MAX_SLOTS then return nil,"spellbook_limit_exceeded" end
            local info=get("GetSpellBookItemInfo",slot,bookType)
            if info.status~="READY" then return nil,"spellbook_item_read_failed" end
            local kind,id=info.value[1],info.value[2]
            if type(kind)~="string" then return nil,"spellbook_item_type_unknown" end
            if kind=="SPELL" then
                if not validID(id) then return nil,"spellbook_spell_id_invalid" end
                local names=get("GetSpellBookItemName",slot,bookType)
                local name,rank
                if names.status=="READY" then
                    name,rank=names.value[1],names.value[2]
                end
                if type(name)~="string" or name=="" then
                    local spell=get("GetSpellInfo",id)
                    if spell.status=="READY" then
                        name=spell.value[1]
                        if type(rank)~="string" then rank=spell.value[2] end
                    end
                end
                if type(name)~="string" or name=="" then
                    return nil,"spellbook_name_unavailable"
                end
                local texture=single("GetSpellBookItemTexture","string",slot,bookType)
                    or single("GetSpellBookItemTexture","number",slot,bookType)
                    or single("GetSpellTexture","string",id)
                    or single("GetSpellTexture","number",id)
                if not addEntry(entries,seen,id,name,texture,rank,nil,"legacy") then
                    return nil,"spellbook_entry_invalid"
                end
            elseif kind~="FUTURESPELL" and kind~="FLYOUT" and kind~="PETACTION"
                and kind~="NONE" then
                -- Unknown item semantics cannot prove the catalogue is complete.
                return nil,"spellbook_item_type_unknown"
            end
        end
    end
    if #entries==0 then return nil,"legacy_empty_unverified" end
    return freshResult("ready",nil,"legacy",entries)
end

local function modern()
    local count=single("C_SpellBook.GetNumSpellBookSkillLines","number")
    if count==nil then return nil,"modern_api_unavailable" end
    if not nonnegative(count,MAX_LINES) then return nil,"invalid_skill_line_count" end
    if count==0 then return nil,"modern_zero_lines_unverified" end
    local enum=type(Enum)=="table" and safeField(Enum,"SpellBookSpellBank")
    local bank=enum and safeField(enum,"Player")
    if bank==nil then return nil,"modern_bank_unavailable" end
    local entries,seen,scanned={}, {},0
    for i=1,count do
        local line=single("C_SpellBook.GetSpellBookSkillLineInfo","table",i)
        if not line then return nil,"skill_line_unavailable" end
        local offset=safeField(line,"itemIndexOffset")
        local amount=safeField(line,"numSpellBookItems")
        if not nonnegative(offset,MAX_SLOTS) or not nonnegative(amount,MAX_SLOTS)
            or offset+amount>MAX_SLOTS then return nil,"skill_line_invalid" end
        for slot=offset+1,offset+amount do
            scanned=scanned+1
            if scanned>MAX_SLOTS then return nil,"spellbook_limit_exceeded" end
            local item=single("C_SpellBook.GetSpellBookItemInfo","table",slot,bank)
            if not item then return nil,"modern_item_unavailable" end
            local kind=safeField(item,"itemType")
            local id=safeField(item,"spellID")
            local enumType=type(Enum)=="table" and safeField(Enum,"SpellBookItemType")
            local spellType=enumType and safeField(enumType,"Spell")
            if spellType==nil then return nil,"modern_item_enum_unavailable" end
            if kind==spellType then
                if not validID(id) then return nil,"modern_spell_id_invalid" end
                local name=single("C_SpellBook.GetSpellBookItemName","string",slot,bank)
                local texture=single("C_SpellBook.GetSpellBookItemTexture","string",slot,bank)
                    or single("C_SpellBook.GetSpellBookItemTexture","number",slot,bank)
                local rank
                if not name then
                    local details=single("C_Spell.GetSpellInfo","table",id)
                    name=safeField(details,"name")
                    rank=safeField(details,"subName")
                    if texture==nil then texture=safeField(details,"iconID") end
                end
                if not addEntry(entries,seen,id,name,texture,rank,nil,"modern") then
                    return nil,"modern_entry_invalid"
                end
            else
                -- Only explicitly recognized non-spell entries may be skipped.
                -- Future spells are NOT learned; other client-specific types are
                -- rejected rather than silently producing a partial "ready" book.
                local future=enumType and safeField(enumType,"FutureSpell")
                local flyout=enumType and safeField(enumType,"Flyout")
                if kind==nil or (kind~=future and kind~=flyout) then
                    return nil,"modern_item_type_unknown"
                end
            end
        end
    end
    if #entries==0 then return nil,"modern_empty_unverified" end
    return freshResult("ready",nil,"modern",entries)
end

local function sortEntries(entries)
    table.sort(entries,function(a,b)
        if a.name~=b.name then return a.name<b.name end
        if a.rankNumber and b.rankNumber and a.rankNumber~=b.rankNumber then
            return a.rankNumber<b.rankNumber
        end
        return a.id<b.id
    end)
end
function S:Invalidate(reason)
    self.dirty=true
    self.lastInvalidation=type(reason)=="string" and reason or "manual"
end
function S:Initialize()
    if self.initialized then return true end
    if not KR.EventBus or type(KR.EventBus.Subscribe)~="function" then
        return false
    end
    for _,channel in ipairs({"spellbook","talents","identity"}) do
        if not KR.EventBus:Subscribe(channel,"SpellCatalogue",function(ch)
            S:Invalidate(ch)
        end) then return false end
    end
    self.initialized=true
    self:Invalidate("initialize")
    return true
end
function S:Read(force)
    local now=clock()
    if not force and self.cache and not self.dirty
        and now and self.lastReadAt and now>=self.lastReadAt
        and now-self.lastReadAt<TTL then
        return copy(self.cache)
    end
    local result,why=legacy()
    if not result then
        local alternative,modernWhy=modern()
        if alternative then result=alternative
        else
            result=freshResult("unavailable",why or modernWhy or "spellbook_unavailable")
            result.fallbackReason=modernWhy
        end
    end
    -- Do not publish partial scans as a ready spellbook.
    if result.status=="ready" then sortEntries(result.entries) end
    self.revision=(self.revision or 0)+1
    result.revision=self.revision
    result.observedAt=now
    self.cache=result
    self.lastReadAt=now
    self.dirty=false
    if KR.EventBus and KR.EventBus.revisions then
        self.busRevisions=self.busRevisions or {}
        for _,channel in ipairs({"spellbook","talents","identity"}) do
            self.busRevisions[channel]=KR.EventBus.revisions[channel] or 0
        end
    end
    return copy(result)
end
function S:GetSnapshot()
    if KR.EventBus and KR.EventBus.revisions then
        for _,channel in ipairs({"spellbook","talents","identity"}) do
            if (KR.EventBus.revisions[channel] or 0)~=
                ((self.busRevisions or {})[channel] or 0) then
                self:Invalidate(channel)
                break
            end
        end
    end
    return self:Read(false)
end
function S:Filter(entries,query,category,profile)
    local matched={}
    query=type(query)=="string" and string.lower(query) or ""
    for _,item in ipairs(entries or {}) do
        local record=profile and profile.spells and profile.spells[item.id] or nil
        local classified=record and record.category or "unclassified"
        local name=type(item.name)=="string" and string.lower(item.name) or ""
        if (category=="all" or category==classified)
            and (query=="" or string.find(name,query,1,true)
                or string.find(tostring(item.id),query,1,true)
                or (type(item.rank)=="string"
                    and string.find(string.lower(item.rank),query,1,true))) then
            matched[#matched+1]=item
        end
    end
    return matched
end
-- Kord Rotation copyright notice (c) 2026 Vi22Rus. See LICENSE.
