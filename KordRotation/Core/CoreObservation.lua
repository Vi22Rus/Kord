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

-- Manual DevTools-only action-bar coverage inspection. No spell IDs,
-- keys, button objects or action-slot numbers leave the core namespace.
function O:ReadActionBar()
    local scanner=KR.ActionBarScanner
    if not scanner or type(scanner.GetSnapshot)~="function" then
        return {status="UNAVAILABLE",reason="scanner_unavailable"}
    end
    local ok,snapshot=pcall(scanner.GetSnapshot,scanner,true)
    if not ok or not safe(snapshot) or type(snapshot)~="table" then
        return {status="UNKNOWN",reason="scan_unavailable"}
    end
    local entries=field(snapshot,"entries")
    if type(entries)~="table" then
        return {status="UNKNOWN",reason="scan_unavailable"}
    end
    local count=0
    local detected={}
    for _,entry in ipairs(entries) do
        if count>=1200 then break end
        local id=field(entry,"spellID")
        if type(id)=="number" and id==id and id>0 and id<=99999999 then
            count=count+1
            detected[id]=true
        end
    end
    local rank=nil
    local profileModule=KR.RotationProfiles
    local identity=KR.characterState
    if type(profileModule)=="table"
        and type(profileModule.ResolveForEngine)=="function"
        and safe(identity) and type(identity)=="table" then
        local class=field(identity,"classToken")
        local tree=field(identity,"index")
        if class=="HUNTER" and tree==1 then
            local level=KR.GameState and KR.GameState.current
            local player=field(level,"player")
            local levelRecord=field(player,"level")
            local lv=field(levelRecord,"value")
            if type(lv)=="number" and lv==math.floor(lv)
                and lv>=1 and lv<=100 then
                local okProfile,p=pcall(profileModule.ResolveForEngine,
                    profileModule,"HUNTER_TREE_1",lv)
                if okProfile and safe(p) and type(p)=="table" then
                    local spells=field(p,"Spells")
                    if type(spells)=="table" then
                        for i=8,1,-1 do
                            local id=field(spells,"ArcaneShotR"..i)
                            if type(id)=="number" and detected[id] then
                                rank=i
                                break
                            end
                        end
                    end
                end
            end
        end
    end
    -- The snapshot confirms a candidate once; Eligibility calls FindSpell
    -- which revalidates the actual button. Report the difference explicitly.
    local findStatus="UNKNOWN"
    local findReason="rank_not_confirmed"
    if rank and scanner and type(scanner.FindSpell)=="function"
        and type(profileModule)=="table" then
        local levelSnapshot=KR.GameState and KR.GameState.current
        local levelRec=field(field(levelSnapshot,"player"),"level")
        local levelValue=field(levelRec,"value")
        if type(levelValue)=="number" and levelValue>=1 and levelValue<=100 then
            local okProfile,p=pcall(profileModule.ResolveForEngine,
                profileModule,"HUNTER_TREE_1",levelValue)
            local id=okProfile and field(field(p,"Spells"),"ArcaneShotR"..rank)
            if type(id)=="number" and safe(id) then
                local okFound,found=pcall(scanner.FindSpell,scanner,id)
                if okFound and safe(found) and type(found)=="table" then
                    findStatus=status(field(found,"status"))
                    findReason=reason(field(found,"reason"))
                        or (findStatus=="READY" and "confirmed" or "unknown")
                else findReason="find_spell_exception" end
            end
        end
    end
    return {status=count>0 and "READY" or "UNKNOWN",
        reason=count>0 and "scan_has_spells" or "no_confirmed_visible_slots",
        confirmedSpellButtons=count,arcaneRankOnBar=rank,
        arcaneFindStatus=findStatus,arcaneFindReason=findReason}
end

-- DevTools-only read of the FINAL UI stage. No test icons are inserted,
-- no game values are exposed and no display state is changed.
function O:ReadDisplay()
    local display=KR.RotationDisplay
    if not display then return {status="UNAVAILABLE",reason="display_unavailable"} end
    local frame=field(display,"frame")
    local ready=field(display,"productionReady")
    local out={
        status="READY",
        frameCreated=frame~=nil,
        recommendationAccepted=ready==true,
        lastEngineStatus=status(field(display,"lastEngineStatus")),
        lastEngineReason=reason(field(display,"lastEngineReason")) or "unknown",
    }
    if frame and safe(frame) then
        local fn=field(frame,"IsShown")
        if type(fn)=="function" then
            local ok,value=pcall(fn,frame)
            if ok and safe(value) and type(value)=="boolean" then
                out.frameShown=value
            end
        end
    end
    if type(display.ShouldShow)=="function" then
        local ok,value=pcall(display.ShouldShow,display)
        if ok and safe(value) and type(value)=="boolean" then
            out.visibilityAllowed=value
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
    Display=function()
        local ok,result=pcall(O.ReadDisplay,O)
        if not ok then return {status="UNKNOWN",reason="display_read_failed"} end
        return result
    end,
    ActionBar=function()
        local ok,result=pcall(O.ReadActionBar,O)
        if not ok then return {status="UNKNOWN",reason="scan_unavailable"} end
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
