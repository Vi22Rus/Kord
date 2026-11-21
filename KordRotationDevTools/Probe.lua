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
    local status=value.status
    if status~="READY" and status~="UNAVAILABLE" and status~="UNKNOWN"
        and status~="ERROR" then status="UNKNOWN" end
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
