-- Kord Rotation (c) 2026 Vi22Rus. All rights reserved.
-- Stage 2.8.6d: pull-only observability for a separately installed DevTools.
-- Does not trace, log, retain, call gameplay APIs or evaluate a rotation.
local addonName,KR=...
KR.CoreObservation=KR.CoreObservation or {}
local O=KR.CoreObservation

local statuses={READY=true,BLOCKED=true,UNKNOWN=true,UNAVAILABLE=true,ERROR=true}
local function safe(v)
    local api=KR.GameAPI
    if not api or type(api.IsSafeValue)~="function" then return false end
    local ok,allowed=pcall(api.IsSafeValue,api,v)
    return ok and allowed==true
end
local function field(record,key)
    if not safe(record) or type(record)~="table" then return nil end
    local ok,value=pcall(function() return record[key] end)
    if not ok or not safe(value) then return nil end
    return value
end
local function status(v)
    if not safe(v) or type(v)~="string" or not statuses[v] then
        return "UNKNOWN"
    end
    return v
end
local function reason(v)
    if not safe(v) or type(v)~="string"
        or #v<1 or #v>64 or not string.match(v,"^[a-z][a-z0-9_]*$") then
        return nil
    end
    return v
end
local function nonnegativeInt(v)
    if not safe(v) or type(v)~="number" or v~=v
        or v<0 or v>1000000000 or v~=math.floor(v) then return nil end
    return v
end

function O:Read()
    -- Return a new scalar-only summary, not any internal table reference.
    -- Reading must never force GameState or Engine refresh.
    local display=KR.RotationDisplay
    local game=KR.GameState
    local bus=KR.EventBus
    local bindings=KR.BindingResolver
    local engineStatus=status(field(display,"lastEngineStatus"))
    local engineReason=reason(field(display,"lastEngineReason"))
    local current=field(game,"current")
    local summary=field(display,"lastSummary")
    local result={
        version=1,
        status="READY",
        engineStatus=engineStatus,
        engineReason=engineReason,
        stateRevision=nonnegativeInt(field(current,"revision")),
        eventListenerErrors=nonnegativeInt(field(bus,"listenerErrors")) or 0,
        bindingDirty=field(bindings,"dirty")==true,
        profileStatus=status(field(summary,"profileStatus")),
        eligibilityReady=nonnegativeInt(field(summary,"eligibilityReady")) or 0,
        eligibilityBlocked=nonnegativeInt(field(summary,"eligibilityBlocked")) or 0,
        eligibilityUnknown=nonnegativeInt(field(summary,"eligibilityUnknown")) or 0,
        -- Never include Spell ID, target, GUID, key, frame, timestamp or name.
    }
    return result
end
-- A deliberately tiny public bridge: callers cannot mutate the KR namespace.
-- The diagnostic extension is a separate WoW addon namespace.
_G.KordRotationCoreObservation = {
    Read=function()
        local ok,result=pcall(O.Read,O)
        if not ok then return {version=1,status="ERROR",engineStatus="UNKNOWN"} end
        return result
    end,
    Probe=function(_,name)
        -- Existing GameAPI returns presence-only results (NOT client proof).
        if not safe(name) or type(name)~="string" or #name<1 or #name>80
            or not string.match(name,"^[A-Za-z][A-Za-z0-9_.]*$") then
            return {status="UNAVAILABLE",reason="invalid_method"}
        end
        local api=KR.GameAPI
        if not api or type(api.Probe)~="function" then
            return {status="UNAVAILABLE",reason="api_missing"}
        end
        local ok,v=pcall(api.Probe,api,name)
        if not ok or type(v)~="table" then
            return {status="ERROR",reason="api_call_failed"}
        end
        local s=status(field(v,"status"))
        local why=reason(field(v,"reason"))
        return {status=s,reason=why or "presence_only"}
    end,
}
-- Copyright notice: see root LICENSE.
