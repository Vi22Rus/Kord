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
-- Explicit DevTools-only, pull-based target comparison. No raw unit data,
-- GUIDs, health, spell IDs or internal table references cross the bridge.
function O:ReadTarget()
    local api=KR.GameAPI
    local function boolRecord(r)
        local v=field(r,"value")
        if field(r,"status")=="READY" and type(v)=="boolean" then return v end
        return nil
    end
    local live
    if api and type(api.Read)=="function" then
        local ok,result=pcall(api.Read,api,"UnitExists","boolean","target")
        if ok then live=boolRecord(result) end
    end
    local game=KR.GameState
    local snapshot=field(game,"current")
    local target=field(snapshot,"target")
    local cached=boolRecord(field(target,"exists"))
    local out={liveStatus=live==nil and "UNKNOWN" or "READY",
        snapshotStatus=cached==nil and "UNKNOWN" or "READY"}
    if live~=nil then out.liveExists=live end
    if cached~=nil then out.snapshotExists=cached end
    return out
end

-- Explicit DevTools-only diagnostic. Evaluate only when a user starts
-- recording or requests /krdev why. Never return a raw queue, spell ID,
-- GUID, protected game value or mutable engine object.
function O:ReadEngineDiagnostic()
    local engine=KR.RotationEngine
    if not engine or type(engine.Evaluate)~="function" then
        return {status="UNAVAILABLE",reason="engine_unavailable"}
    end
    local ok,result=pcall(engine.Evaluate,engine)
    if not ok or not safe(result) or type(result)~="table" then
        return {status="UNKNOWN",reason="engine_exception"}
    end
    local refusal=reason(field(result,"reason")) or "unknown"
    local profileID=field(result,"profileID")
    local profileStatus="UNKNOWN"
    if type(profileID)=="string" and #profileID>0 and #profileID<=64 then
        profileStatus="READY"
    elseif refusal=="profile_not_registered" then
        profileStatus="UNAVAILABLE"
    elseif refusal=="rotation_disabled" or refusal=="profile_unverified" then
        profileStatus="BLOCKED"
    end
    local out={status=status(field(result,"status")),reason=refusal,
        profileStatus=profileStatus}
    local diagnostics=field(result,"diagnostics")
    if type(diagnostics)=="table" then
        local first=field(diagnostics,1)
        if type(first)=="table" then
            out.firstStatus=status(field(first,"status"))
            out.firstReason=reason(field(first,"reason")) or "unknown"
        end
    end
    return out
end

-- A deliberately tiny public bridge: callers cannot mutate the KR namespace.
-- The diagnostic extension is a separate WoW addon namespace.
_G.KordRotationCoreObservation = {
    Read=function()
        local ok,result=pcall(O.Read,O)
        if not ok then return {version=1,status="ERROR",engineStatus="UNKNOWN"} end
        return result
    end,
    Diagnose=function()
        local ok,result=pcall(O.ReadEngineDiagnostic,O)
        if not ok then return {status="UNKNOWN",reason="engine_exception"} end
        return result
    end,
    Target=function()
        local ok,result=pcall(O.ReadTarget,O)
        if not ok then return {liveStatus="UNKNOWN",snapshotStatus="UNKNOWN"} end
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
