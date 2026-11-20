-- Kord Rotation (c) 2026 Vi22Rus. All rights reserved.
-- Stage 2.2: read-only, fail-closed adapter. No cast, action or automation APIs.
local addonName, KR = ...
KR.GameAPI = KR.GameAPI or {}
local API = KR.GameAPI

-- Explicit allowlist prevents callers from invoking protected actions via this adapter.
local allowed = {
    GetBuildInfo=true, UnitClass=true, UnitLevel=true,
    UnitExists=true, UnitIsDeadOrGhost=true, UnitAffectingCombat=true,
    UnitCanAttack=true, UnitPower=true, UnitPowerMax=true,
    UnitCastingInfo=true, UnitChannelInfo=true, UnitAura=true,
    InCombatLockdown=true, IsMounted=true,
    GetNumSpellTabs=true, GetSpellTabInfo=true,
    GetSpellBookItemInfo=true, GetSpellBookItemName=true,
    GetSpellInfo=true, GetSpellTexture=true, GetSpellCooldown=true,
    IsUsableSpell=true, IsSpellInRange=true,
    HasAction=true, GetActionInfo=true, GetActionCooldown=true,
    GetActionBarPage=true, GetBonusBarOffset=true,
    GetBindingKey=true, GetBindingAction=true,
    GetMacroInfo=true,
    ["C_ActionBar.HasAction"]=true,
    ["C_ActionBar.FindSpellActionButtons"]=true,
    ["C_Spell.GetSpellCooldown"]=true,
    ["C_SpellBook.GetSpellBookItemInfo"]=true,
    ["C_UnitAuras.GetAuraDataByIndex"]=true,
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

local function secret(value)
    local detect = type(_G) == "table" and _G.issecretvalue or nil
    if type(detect) ~= "function" then return false end
    local ok, result = pcall(detect, value)
    -- A broken security probe cannot establish safe data.
    return not ok or result == true
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

function API:Probe(name)
    if type(name) ~= "string" or not allowed[name] then
        return {status="UNAVAILABLE", source=name, reason="unsupported_contract"}
    end
    return {status=type(resolve(name))=="function" and "READY" or "UNAVAILABLE",
        source=name, reason="presence_only_not_game_verified"}
end

-- Return a standalone list, not the mutable allowlist table.
function API:SupportedNames()
    local names={}
    for name in pairs(allowed) do names[#names+1]=name end
    table.sort(names)
    return names
end
-- Copyright notice: see repository LICENSE.