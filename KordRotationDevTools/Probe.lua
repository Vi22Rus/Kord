-- Kord Rotation DevTools (c) 2026 Vi22Rus; see root LICENSE.
-- v14 presence-only methods, not in-game capability proofs. No arbitrary calls.
local _,D=...
local methods=D.V14Registry or {}
local catalog={}
for _,item in ipairs(methods) do
    if type(item.method)=="string" and not catalog[item.method] then
        catalog[item.method]=item.id
    end
end
function D:ProbeMethod(name)
    if not self:Safe(name) or type(name)~="string"
        or not catalog[name] then
        return {status="UNAVAILABLE",reason="unlisted_method"}
    end
    local bridge=_G.KordRotationCoreObservation
    if type(bridge)~="table" or type(bridge.Probe)~="function" then
        return {status="UNAVAILABLE",reason="core_bridge_missing",matrix=catalog[name]}
    end
    local ok,value=pcall(bridge.Probe,bridge,name)
    if not ok or type(value)~="table" then
        return {status="ERROR",reason="probe_failed",matrix=catalog[name]}
    end
    local safeStatus,status=pcall(function()
        if not self:Safe(value) or not self:Safe(value.status) then
            return "UNKNOWN"
        end
        return value.status
    end)
    if not safeStatus or (status~="READY" and status~="UNAVAILABLE"
        and status~="UNKNOWN" and status~="ERROR") then
        status="UNKNOWN"
    end
    return {status=status,reason="presence_only",matrix=catalog[name]}
end
function D:ProbeAll()
    -- Explicit UI action only; no recurring scan or client state interrogation.
    local entries={}
    local present=0
    for _,item in ipairs(methods) do
        local outcome
        if type(item.method)=="string" then
            outcome=self:ProbeMethod(item.method)
        else
            outcome={status="UNKNOWN",reason="no_single_safe_probe"}
        end
        if outcome.status=="READY" then present=present+1 end
        entries[#entries+1]={name=item.method or "no_safe_probe",
            matrix=item.id,status=outcome.status}
    end
    self.lastProbe={entries=entries,present=present,total=#entries,
        evidence="presence_only_not_client_pass"}
    -- One bounded record, never serialize game values.
    if self.active then self:Record("API","READY","presence_only") end
    return self.lastProbe
end

-- Manual, bounded diagnostic report. No game-state mutation, cast, or
-- uncontrolled logging. Main addon exposes only sanitized read-only data.
function D:Why()
    local summary=self:ReadCore()
    local bridge=_G.KordRotationCoreObservation
    local diagnosis
    if type(bridge)=="table" and type(bridge.Diagnose)=="function" then
        local ok,value=pcall(bridge.Diagnose)
        if ok and type(value)=="table" and self:Safe(value) then diagnosis=value end
    end
    local actionBar
    if type(bridge)=="table" and type(bridge.ActionBar)=="function" then
        local ok,value=pcall(bridge.ActionBar)
        if ok and type(value)=="table" and self:Safe(value) then
            actionBar=value
        end
    end
    local target
    if type(bridge)=="table" and type(bridge.Target)=="function" then
        local ok,value=pcall(bridge.Target)
        if ok and type(value)=="table" and self:Safe(value) then target=value end
    end
    local function status(value)
        if self:Safe(value) and (value=="READY" or value=="BLOCKED"
            or value=="UNKNOWN" or value=="UNAVAILABLE"
            or value=="ERROR") then return value end
        return "UNKNOWN"
    end
    local function reason(value)
        if not self:Safe(value) or type(value)~="string"
            or #value>64 or not value:match("^[a-z][a-z0-9_]*$") then
            return "unknown"
        end
        return value
    end
    local function observation(st,value)
        if status(st)=="READY" and self:Safe(value)
            and type(value)=="boolean" then return tostring(value) end
        return "UNKNOWN"
    end
    local lines={
        "Kord Rotation DevTools - manual diagnosis",
        "Engine (manual evaluation): "..status(diagnosis and diagnosis.status)
            .." / "..reason(diagnosis and diagnosis.reason),
        "Priority 1: "..status(diagnosis and diagnosis.firstStatus)
            .." / "..reason(diagnosis and diagnosis.firstReason),
        "Engine (last UI evaluation): "..status(summary and summary.engineStatus)
            .." / "..reason(summary and summary.engineReason),
        "Target UnitExists (live): "..observation(target and target.liveStatus,
            target and target.liveExists),
        "Target exists (cached snapshot): "..observation(
            target and target.snapshotStatus,target and target.snapshotExists),
        "Action bar scan: "..status(actionBar and actionBar.status),
        "Confirmed spell buttons: "..(
            self:Safe(actionBar and actionBar.confirmedSpellButtons)
            and type(actionBar and actionBar.confirmedSpellButtons)=="number"
            and tostring(actionBar.confirmedSpellButtons) or "UNKNOWN"),
        "Hunter Arcane Shot rank on bar: "..(
            self:Safe(actionBar and actionBar.arcaneRankOnBar)
            and type(actionBar and actionBar.arcaneRankOnBar)=="number"
            and tostring(actionBar.arcaneRankOnBar) or "NOT CONFIRMED"),
        "Arcane Shot FindSpell: "..status(actionBar and actionBar.arcaneFindStatus)
            .." / "..reason(actionBar and actionBar.arcaneFindReason),
        "Profile (manual evaluation): "..status(diagnosis and diagnosis.profileStatus),
        "Profile (last UI evaluation): "..status(summary and summary.profileStatus),
        "Eligibility (ready/blocked/unknown): "
            ..tostring(type(summary)=="table" and summary.eligibilityReady or 0)
            .."/"..tostring(type(summary)=="table" and summary.eligibilityBlocked or 0)
            .."/"..tostring(type(summary)=="table" and summary.eligibilityUnknown or 0),
        "NOTE: diagnosis explicitly reevaluates the engine without casting."
    }
    return table.concat(lines,"\n")
end
