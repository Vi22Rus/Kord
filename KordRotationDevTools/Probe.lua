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
            matrix=item.id,status=outcome.status,reason=outcome.reason}
        -- All 101 canonical matrix rows are accounted for in the
        -- persisted journal. Presence is NOT execution or client PASS.
        -- Each row has a stable numeric matrix ID and bounded reason.
        if self.active then
            local diagnostic=type(item.method)~="string"
                and "no_single_safe_probe"
                or (outcome.status=="READY" and "presence_only"
                    or outcome.status=="UNAVAILABLE" and "api_missing"
                    or outcome.reason or "unknown")
            self:Record("API",outcome.status,"matrix_probe",item.id,
                nil,diagnostic)
        end
    end
    self.lastProbe={entries=entries,present=present,total=#entries,
        evidence="presence_only_not_client_pass"}
    -- The 101 row-specific scalar records above replace the old
    -- single aggregate marker, which concealed missing methods.
    return self.lastProbe
end

-- IT-01/1.9: explicit bounded inventory check. DevTools records only
-- approved diagnostic tokens; no item IDs, names or bag counts persist.
local inventoryReasons={
    none=true,
    item_count_unknown=true,item_count_secret=true,
    item_count_scope_unverified=true,item_bag_scan_incomplete=true,
    item_family_unknown=true,item_family_partial=true,
    item_family_duplicate_id=true,item_catalog_revision_changed=true,
    item_bag_revision_changed=true,item_soulwell_refresh_missing_event=true,
    item_count_zero_confirmed=true,
}
function D:InventoryDiagnostic(kind,id)
    if not self:Safe(kind) or type(kind)~="string"
        or (kind~="item" and kind~="family" and kind~="bag") then
        return {status="UNKNOWN",code="item_count_unknown"}
    end
    local bridge=_G.KordRotationCoreObservation
    if type(bridge)~="table" or type(bridge.InventoryDiagnostic)~="function" then
        return {status="UNAVAILABLE",code="item_count_unknown"}
    end
    local ok,record=pcall(bridge.InventoryDiagnostic,bridge,kind,id)
    if not ok or type(record)~="table" or not self:Safe(record) then
        return {status="UNKNOWN",code="item_count_unknown"}
    end
    local valid,status,code=pcall(function()
        if not self:Safe(record.status) or not self:Safe(record.code) then
            return "UNKNOWN","item_count_unknown"
        end
        if record.status~="READY" and record.status~="UNKNOWN" then
            return "UNKNOWN","item_count_unknown"
        end
        if type(record.code)~="string" or not inventoryReasons[record.code] then
            return "UNKNOWN","item_count_unknown"
        end
        return record.status,record.code
    end)
    if not valid then status,code="UNKNOWN","item_count_unknown" end
    if self.active and type(self.Record)=="function" then
        self:Record("CHECK",status,code)
    end
    return {status=status,code=code}
end


-- Explicit manual item-specific snapshot; no item ID is recorded or
-- returned. Unlike the shared-group diagnostic, this has no group inference.
function D:ItemCooldownDiagnostic(itemID)
    local fallback={status="UNKNOWN",code="item_cd_remaining_unknown",
        source="UNKNOWN",activity="UNKNOWN"}
    if not self:Safe(itemID) or type(itemID)~="number"
        or itemID~=math.floor(itemID) or itemID<=0
        or itemID>1000000000 then
        fallback.code="item_cd_id_unverified"
        return fallback
    end
    local bridge=_G.KordRotationCoreObservation
    if type(bridge)~="table"
        or type(bridge.ItemCooldownDiagnostic)~="function" then
        fallback.code="item_cd_api_missing"
        return fallback
    end
    local ok,response=pcall(bridge.ItemCooldownDiagnostic,bridge,itemID)
    if not ok or type(response)~="table" or not self:Safe(response) then
        return fallback
    end
    local valid,clean=pcall(function()
        local codes={item_cd_item_active=true,item_cd_ready_confirmed=true,
            item_cd_api_missing=true,item_cd_secret=true,
            item_cd_disabled=true,item_cd_invalid_tuple=true,
            item_cd_remaining_unknown=true,item_cd_revision_unavailable=true,
            item_cd_revision_changed=true,
            item_cd_dependency_revision_changed=true,item_cd_read_failed=true,
            item_cd_id_unverified=true,item_cd_identity_unverified=true}
        local sources={UNKNOWN=true,["C_Item.GetItemCooldown"]=true,
            ["GetItemCooldown"]=true}
        local activities={UNKNOWN=true,ACTIVE=true,IDLE=true}
        if not self:Safe(response.status) or not self:Safe(response.code)
            or not self:Safe(response.source) or not self:Safe(response.activity)
            or not codes[response.code] or not sources[response.source]
            or not activities[response.activity] then return nil end
        local expectedStatus=response.code=="item_cd_ready_confirmed"
            and "READY" or "UNKNOWN"
        if response.status~=expectedStatus then return nil end
        if response.activity=="IDLE"
            and response.code~="item_cd_ready_confirmed" then return nil end
        if response.activity=="ACTIVE"
            and response.code~="item_cd_item_active" then return nil end
        if response.code=="item_cd_ready_confirmed"
            and response.activity~="IDLE" then return nil end
        return {status=response.status,code=response.code,
            source=response.source,activity=response.activity}
    end)
    if not valid or not clean then return fallback end
    if self.active and type(self.RecordItemCooldownDiagnostic)=="function" then
        self:RecordItemCooldownDiagnostic(clean.code)
    end
    return clean
end

-- IT-02: user-initiated, aggregate-only evidence collection for Forever.
-- No persistent itemIDs, names, raw API results or automated polling.
function D:SharedCooldownDiagnostic()
    local fallback={status="UNKNOWN",code="item_cd_group_partial",
        itemConfidence="UNKNOWN",lockoutConfidence="UNKNOWN",
        readyConfidence="UNKNOWN",useCorrelation="UNKNOWN",
        propagation="UNKNOWN"}
    local bridge=_G.KordRotationCoreObservation
    if type(bridge)~="table" or type(bridge.SharedCooldownDiagnostic)~="function" then
        return fallback
    end
    local ok,record=pcall(bridge.SharedCooldownDiagnostic)
    if not ok or type(record)~="table" or not self:Safe(record) then
        return fallback
    end
    local valid,clean=pcall(function()
        local allowed={item_cd_group_partial=true,
            item_cd_group_estimated=true,item_cd_group_conflict=true}
        local conf={UNKNOWN=true,CONFIRMED=true,ESTIMATED=true}
        local propagation={UNKNOWN=true,ALIGNED_CANDIDATES=true,
            SINGLE_CANDIDATE=true,MIXED_CANDIDATES=true}
        local function number(v)
            return self:Safe(v) and type(v)=="number"
                and v==math.floor(v) and v>=0 and v<=32
        end
        if record.status~="UNKNOWN" or not self:Safe(record.code)
            or not allowed[record.code] or not self:Safe(record.itemConfidence)
            or not conf[record.itemConfidence] or not self:Safe(record.lockoutConfidence)
            or not conf[record.lockoutConfidence]
            or record.lockoutConfidence=="CONFIRMED"
            or not self:Safe(record.readyConfidence)
            or record.readyConfidence~="UNKNOWN"
            or not self:Safe(record.useCorrelation)
            or (record.useCorrelation~="UNKNOWN"
                and record.useCorrelation~="ESTIMATED")
            or not self:Safe(record.propagation)
            or not propagation[record.propagation] then return nil end
        local values={"candidates","active","inactive","unknown"}
        local any=record.candidates~=nil
        if any then
            for _,name in ipairs(values) do
                if not number(record[name]) then return nil end
            end
            if record.candidates<1
                or record.active+record.inactive+record.unknown
                    ~=record.candidates then return nil end
        end
        if record.lockoutConfidence=="ESTIMATED"
            and (record.useCorrelation~="ESTIMATED"
                or record.propagation~="ALIGNED_CANDIDATES"
                or record.code~="item_cd_group_estimated") then return nil end
        local out={status="UNKNOWN",code=record.code,
            itemConfidence=record.itemConfidence,
            lockoutConfidence=record.lockoutConfidence,
            readyConfidence="UNKNOWN",useCorrelation=record.useCorrelation,
            propagation=record.propagation}
        if any then
            for _,name in ipairs(values) do out[name]=record[name] end
        end
        return out
    end)
    if not valid or not clean then return fallback end
    if self.active and type(self.RecordItemCooldownDiagnostic)=="function" then
        self:RecordItemCooldownDiagnostic(clean.code)
    end
    return clean
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
    local display
    if type(bridge)=="table" and type(bridge.Display)=="function" then
        local ok,value=pcall(bridge.Display)
        if ok and type(value)=="table" and self:Safe(value) then
            display=value
        end
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
        "Priority 1 (Arcane rank 8): "..status(diagnosis and diagnosis.firstStatus)
            .." / "..reason(diagnosis and diagnosis.firstReason),
        "Priority 5 (Arcane rank 4): "..status(diagnosis and diagnosis.arcaneR4Status)
            .." / "..reason(diagnosis and diagnosis.arcaneR4Reason),
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
        "Display panel enabled: "..observation("READY",display and display.panelEnabled),
        "Display test mode: "..observation("READY",display and display.testMode),
        "Display last engine: "..status(display and display.lastEngineStatus)
            .." / "..reason(display and display.lastEngineReason),
        "Display accepts recommendation: "..observation("READY",
            display and display.recommendationAccepted),
        "Display visibility allowed: "..observation("READY",
            display and display.visibilityAllowed),
        "Display frame created: "..observation("READY",
            display and display.frameCreated),
        "Display frame shown: "..observation("READY",
            display and display.frameShown),
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
