-- Kord Rotation (c) 2026 Vi22Rus. All rights reserved.
-- Stage 2.2: read-only, fail-closed adapter. No cast, action or automation APIs.
local addonName, KR = ...
KR.GameAPI = KR.GameAPI or {}
local API = KR.GameAPI

-- Explicit allowlist prevents callers from invoking protected actions via this adapter.
local allowed = {
    GetBuildInfo=true, GetTime=true, UnitClass=true, UnitLevel=true,
    UnitGUID=true, UnitIsUnit=true, UnitCanAssist=true,
    UnitHealth=true, UnitHealthMax=true, UnitHealthPercent=true,
    UnitPowerPercent=true, UnitPowerType=true,
    UnitExists=true, UnitIsDeadOrGhost=true, UnitIsPlayer=true, UnitAffectingCombat=true,
    IsPlayerMoving=true, IsInGroup=true, IsInRaid=true, IsInInstance=true,
    GetInstanceInfo=true, UnitThreatSituation=true, UnitDetailedThreatSituation=true,
    UnitCanAttack=true, UnitClassification=true, UnitPower=true, UnitPowerMax=true,
    UnitCastingInfo=true, UnitChannelInfo=true, UnitAura=true,
    InCombatLockdown=true, IsMounted=true,
    GetNumSpellTabs=true, GetSpellTabInfo=true,
    GetSpellBookItemInfo=true, GetSpellBookItemName=true,
    GetSpellBookItemTexture=true,
    GetSpellInfo=true, GetSpellTexture=true, GetSpellCooldown=true,
    GetSpellCharges=true,
    IsUsableSpell=true, IsSpellInRange=true,
    HasAction=true, GetActionInfo=true, GetActionCooldown=true,
    GetActionBarPage=true, GetBonusBarOffset=true,
    GetBindingKey=true, GetBindingAction=true,
    GetMacroInfo=true,
    ["C_ActionBar.HasAction"]=true,
    ["C_ActionBar.FindSpellActionButtons"]=true,
    ["C_Spell.GetSpellCooldown"]=true,
    ["C_Spell.GetSpellCharges"]=true,
    ["C_Spell.IsSpellUsable"]=true,
    ["C_Spell.IsSpellInRange"]=true,
    ["C_SpellBook.GetSpellBookItemInfo"]=true,
    ["C_SpellBook.GetNumSpellBookSkillLines"]=true,
    ["C_SpellBook.GetSpellBookSkillLineInfo"]=true,
    ["C_SpellBook.GetSpellBookItemName"]=true,
    ["C_SpellBook.GetSpellBookItemTexture"]=true,
    ["C_Spell.GetSpellInfo"]=true,
    ["C_UnitAuras.GetUnitAuras"]=true,
    ["C_UnitAuras.GetAuraDataByIndex"]=true,
    ["C_UnitAuras.GetPlayerAuraBySpellID"]=true,
    ["C_UnitAuras.GetUnitAuraBySpellID"]=true,
    ["C_UnitAuras.GetAuraDuration"]=true,
    ["C_Spell.IsCurrentSpell"]=true,
    ["C_Spell.IsAutoRepeatSpell"]=true,
    ["C_SpellBook.IsSpellKnown"]=true,
    ["C_SpellBook.FindSpellBookSlotForSpell"]=true,
    ["C_Spell.GetSpellPowerCost"]=true,
    ["C_NamePlate.GetNamePlates"]=true,
}
local validTypes = {boolean=true, number=true, string=true, table=true}

local function resolve(name)
    if type(name) ~= "string" or not allowed[name] then return nil end
    if type(_G) ~= "table" then return nil end
    local dot = string.find(name, ".", 1, true)
    if dot then
        local object = _G[string.sub(name, 1, dot - 1)]
        return type(object) == "table" and object[string.sub(name, dot + 1)] or nil
    end
    return _G[name]
end

-- Secret checks are deliberately conservative: never inspect a secret table
-- or a value rejected by the client. Missing probes do not imply safety.
local function secret(value)
    if type(value) == "nil" then return false end
    local probe = type(_G) == "table" and _G.issecretvalue or nil
    if type(probe) == "function" then
        local ok, protected = pcall(probe, value)
        if not ok or protected == true then return true end
    end
    if type(value) == "table" then
        local tableProbe = type(_G) == "table" and _G.issecrettable or nil
        if type(tableProbe) == "function" then
            local ok, protected = pcall(tableProbe, value)
            if not ok or protected == true then return true end
        end
    end
    local accessible = type(_G) == "table" and _G.canaccessvalue or nil
    if type(accessible) == "function" then
        local ok, permitted = pcall(accessible, value)
        if not ok or permitted ~= true then return true end
    end
    return false
end

local function safeTime()
    local getter = type(_G) == "table" and _G.GetTime or nil
    if type(getter) ~= "function" then return nil end
    local ok, now = pcall(getter)
    if ok and not secret(now) and type(now) == "number"
        and now == now and now ~= math.huge and now ~= -math.huge then
        return now
    end
    return nil
end

local function outcome(status, name, reason, value)
    local data = {status=status, source=name, reason=reason, observedAt=safeTime()}
    if status == "READY" then data.value=value end
    return data
end

-- Read(name, expectedType, ...): single-result getter.
-- For functions returning multiple values, use ReadTuple with an expected-type list.
function API:Read(name, expectedType, ...)
    if type(name) ~= "string" or not allowed[name]
        or not validTypes[expectedType] then
        return outcome("UNAVAILABLE", name, "unsupported_contract")
    end
    local fn = resolve(name)
    if type(fn) ~= "function" then
        return outcome("UNAVAILABLE", name, "api_missing")
    end
    local ok, value = pcall(fn, ...)
    if not ok then return outcome("ERROR", name, "api_call_failed") end
    if secret(value) then return outcome("UNKNOWN", name, "protected_value") end
    if value == nil then return outcome("UNKNOWN", name, "no_value") end
    if type(value) ~= expectedType then
        return outcome("UNKNOWN", name, "unexpected_type")
    end
    if expectedType == "number" and
        (value ~= value or value == math.huge or value == -math.huge) then
        return outcome("UNKNOWN", name, "invalid_number")
    end
    return outcome("READY", name, nil, value)
end

function API:ReadTuple(name, types, ...)
    if type(types) ~= "table" or #types < 1 or #types > 4
        or type(name) ~= "string" or not allowed[name] then
        return outcome("UNAVAILABLE", name, "unsupported_contract")
    end
    for i=1,#types do
        if not validTypes[types[i]] then
            return outcome("UNAVAILABLE", name, "unsupported_contract")
        end
    end
    local fn=resolve(name)
    if type(fn) ~= "function" then return outcome("UNAVAILABLE", name, "api_missing") end
    local ok, a,b,c,d=pcall(fn,...)
    if not ok then return outcome("ERROR", name, "api_call_failed") end
    local values={a,b,c,d}
    for i=1,#types do
        local value=values[i]
        if secret(value) then return outcome("UNKNOWN", name, "protected_value") end
        if value==nil then return outcome("UNKNOWN", name, "no_value") end
        if type(value)~=types[i] then return outcome("UNKNOWN", name, "unexpected_type") end
        if types[i]=="number" and
            (value~=value or value==math.huge or value==-math.huge) then
            return outcome("UNKNOWN", name, "invalid_number")
        end
    end
    local copy={}
    for i=1,#types do copy[i]=values[i] end
    return outcome("READY", name, nil, copy)
end


-- A bounded raw multi-return read for APIs whose useful fields are not first.
-- Only names on the read-only allowlist are callable. Returned values must still
-- be validated against each API's client-specific schema by the consumer.
function API:ReadValues(name, ...)
    if type(name)~="string" or not allowed[name] then
        return outcome("UNAVAILABLE", name, "unsupported_contract")
    end
    local fn=resolve(name)
    if type(fn)~="function" then
        return outcome("UNAVAILABLE", name, "api_missing")
    end
    local ok,a,b,c,d,e,f=pcall(fn,...)
    if not ok then return outcome("ERROR", name, "api_call_failed") end
    local values={a,b,c,d,e,f}
    for i=1,6 do
        if secret(values[i]) then return outcome("UNKNOWN", name, "protected_value") end
        if type(values[i])=="number" and
            (values[i]~=values[i] or values[i]==math.huge or values[i]==-math.huge) then
            return outcome("UNKNOWN", name, "invalid_number")
        end
    end
    return outcome("READY", name, nil, values)
end

-- All structured data must pass this reader before consumers inspect fields.
-- expectedType can be omitted for optional fields, but missing/secret is UNKNOWN.
function API:ReadField(record, key, expectedType)
    -- WoW UI frames/buttons may be userdata rather than Lua tables.
    -- Protected userdata still fails closed; field indexing is guarded by
    -- pcall and never invokes the value as a gameplay action.
    local recordType=type(record)
    if (recordType~="table" and recordType~="userdata") or secret(record) then
        return outcome("UNKNOWN", "GameAPI.ReadField", "protected_or_invalid_table")
    end
    if type(key) ~= "string" and type(key) ~= "number" then
        return outcome("UNAVAILABLE", "GameAPI.ReadField", "unsupported_key")
    end
    local ok, value = pcall(function() return record[key] end)
    if not ok then return outcome("UNKNOWN", "GameAPI.ReadField", "field_access_failed") end
    if secret(value) then return outcome("UNKNOWN", "GameAPI.ReadField", "protected_value") end
    if value == nil then return outcome("UNKNOWN", "GameAPI.ReadField", "no_value") end
    if expectedType and type(value) ~= expectedType then
        return outcome("UNKNOWN", "GameAPI.ReadField", "unexpected_type")
    end
    if type(value) == "number" and
        (value ~= value or value == math.huge or value == -math.huge) then
        return outcome("UNKNOWN", "GameAPI.ReadField", "invalid_number")
    end
    return outcome("READY", "GameAPI.ReadField", nil, value)
end

-- Reusable guard for frame method returns and LibActionButton tables.
-- Safe means no security probe rejected the value; it does not assert game support.
function API:IsSafeValue(value)
    return not secret(value)
end

function API:Probe(name)
    if type(name) ~= "string" or not allowed[name] then
        return {status="UNAVAILABLE", source=name, reason="unsupported_contract"}
    end
    return {status=type(resolve(name))=="function" and "READY" or "UNAVAILABLE",
        source=name, reason="presence_only_not_game_verified"}
end

-- Canonical Matrix v14 #3-6/#41/#49-51: safe numeric *read*, not
-- a way to unwrap secret health/power or an automatic 5%-band converter.
-- Caller must provide a non-secret client-supported curve object. Without
-- it we refuse to guess. A plain numeric percentage is accepted only 0..100.
local function validatedPercent(result)
    if result.status~="READY" then return result end
    local value=result.value
    if type(value)~="number" or value~=value or value<0 or value>100 then
        return {status="UNKNOWN",source=result.source,
            reason="percentage_out_of_range",observedAt=result.observedAt}
    end
    return result
end

function API:ReadHealthPercent(unit,curve)
    -- Secret arguments must be rejected BEFORE any equality/ordering.
    if not self:IsSafeValue(unit) or not self:IsSafeValue(curve)
        or (unit~="player" and unit~="target" and unit~="pet")
        or curve==nil then
        return outcome("UNKNOWN","UnitHealthPercent","curve_or_unit_unverified")
    end
    return validatedPercent(self:Read("UnitHealthPercent","number",unit,false,curve))
end

function API:ReadPowerPercent(unit,powerType,curve)
    if not self:IsSafeValue(unit) or not self:IsSafeValue(powerType)
        or not self:IsSafeValue(curve)
        or (unit~="player" and unit~="target" and unit~="pet")
        or type(powerType)~="number" or powerType~=math.floor(powerType)
        or powerType<0 or powerType>100 or curve==nil then
        return outcome("UNKNOWN","UnitPowerPercent","curve_or_power_unverified")
    end
    return validatedPercent(self:Read("UnitPowerPercent","number",
        unit,powerType,false,curve))
end

-- Return a standalone list, not the mutable allowlist table.
function API:SupportedNames()
    local names={}
    for name in pairs(allowed) do names[#names+1]=name end
    table.sort(names)
    return names
end
-- Opt-in, scalar-only diagnostic counters. The consumer is the separate
-- DevTools recorder; there is no logging or SavedVariables in production.
-- Count every actual invocation of the read-only adapter, not just API presence.
local traceMethods={
    Read=true,ReadTuple=true,ReadValues=true,ReadField=true,
    Probe=true,ReadHealthPercent=true,ReadPowerPercent=true,
}
local traceStatuses={READY=true,BLOCKED=true,UNKNOWN=true,
    UNAVAILABLE=true,ERROR=true}
local TRACE_LIMIT=2048
local function traceToken(value,fallback)
    if type(value)=="string" and #value>=1 and #value<=80
        and string.match(value,"^[A-Za-z][A-Za-z0-9_.]*$") then
        return value
    end
    return fallback
end
local function traceReason(value)
    if type(value)=="string" and #value>=1 and #value<=64
        and string.match(value,"^[a-z][a-z0-9_]*$") then
        return value
    end
    return "reason_unavailable"
end
function API:BeginDiagnosticTrace()
    self.traceActive=true
    self.traceEntries={}
    self.traceIndex={}
    self.traceCount=0
    self.traceOverflow=0
    return true
end
function API:EndDiagnosticTrace()
    self.traceActive=false
    self.traceEntries=nil
    self.traceIndex=nil
    self.traceCount=nil
    self.traceOverflow=nil
    return true
end
function API:DrainDiagnosticTrace()
    if self.traceActive~=true then return {active=false,entries={}} end
    local entries={}
    for _,item in ipairs(self.traceEntries or {}) do
        entries[#entries+1]={method=item.method,status=item.status,
            reason=item.reason,count=item.count}
    end
    local overflow=self.traceOverflow or 0
    self.traceEntries={}
    self.traceCount=0
    self.traceOverflow=0
    return {active=true,entries=entries,overflow=overflow}
end
local function observe(self,name,result)
    if self.traceActive~=true then return end
    -- No API argument, game return value, spellID, target, player or key
    -- ever reaches the diagnostic buffer.
    local method=traceToken(name,"GameAPI.unsupported")
    if not allowed[method] and string.sub(method,1,8)~="GameAPI." then
        method="GameAPI.unsupported"
    end
    local status=type(result)=="table" and result.status
    if not traceStatuses[status] then status="UNKNOWN" end
    local why=type(result)=="table" and result.reason
    why=traceReason(why)
    if status=="READY" then why="none" end
    local entries=self.traceEntries
    if type(entries)~="table" then return end
    local key=method.."|"..status.."|"..why
    local index=self.traceIndex and self.traceIndex[key]
    if index then
        local entry=entries[index]
        if entry then
            entry.count=math.min(entry.count+1,1000000000)
            return
        end
    end
    if #entries>=TRACE_LIMIT then
        self.traceOverflow=(self.traceOverflow or 0)+1
        return
    end
    entries[#entries+1]={method=method,status=status,reason=why,count=1}
    self.traceIndex=self.traceIndex or {}
    self.traceIndex[key]=#entries
end
-- Fixed internal checkpoints for scanners that use frame methods
-- outside the GameAPI getter allowlist. No raw frame or slot is logged.
function API:ObserveDiagnostic(name,st,why)
    if type(name)~="string" or
       (name~="GameAPI.ActionBarScanner.inspect"
       and name~="GameAPI.ActionBarScanner.findspell") then return end
    if not traceStatuses[st] then st="UNKNOWN" end
    observe(self,name,{status=st,reason=why})
end
for name in pairs(traceMethods) do
    local original=API[name]
    if type(original)=="function" then
        API[name]=function(self,...)
            -- ReadField key names may be user/game data. Its method
            -- identity is fixed rather than derived from the key.
            local methodName=name
            if name=="Read" or name=="ReadTuple" or name=="ReadValues"
                or name=="Probe" then
                methodName=select(1,...)
            else
                methodName="GameAPI."..name
            end
            local result=original(self,...)
            observe(self,methodName,result)
            return result
        end
    end
end

-- Copyright notice: see repository LICENSE.