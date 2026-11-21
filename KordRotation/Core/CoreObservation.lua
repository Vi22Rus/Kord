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
    if type(v)~="string" or not safe(v) or not statuses[v] then
        return "UNKNOWN"
    end
    return v
end
local function reason(v)
    if type(v)~="string" or not safe(v)
        or #v<1 or #v>64 or not string.match(v,"^[a-z][a-z0-9_]*$") then
        return nil
    end
    return v
end
local function nonnegativeInt(v)
    if type(v)~="number" or not safe(v) or v~=v
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
    local result={
        version=1,
        status="READY",
        engineStatus=engineStatus,
        engineReason=engineReason,
        stateRevision=nonnegativeInt(field(current,"revision")),
        eventListenerErrors=nonnegativeInt(field(bus,"listenerErrors")) or 0,
        bindingDirty=field(bindings,"dirty")==true,
        -- Never include Spell ID, target, GUID, key, frame, timestamp or name.
    }
    return result
end
-- Copyright notice: see root LICENSE.
