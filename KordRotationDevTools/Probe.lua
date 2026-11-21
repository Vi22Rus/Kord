-- Kord Rotation DevTools (c) 2026 Vi22Rus; see root LICENSE.
-- v14 presence-only methods, not in-game capability proofs. No arbitrary calls.
local _,D=...
local methods={
 {"UnitExists",1},{"UnitCanAttack",2},{"UnitHealthPercent",3},
 {"UnitPowerPercent",6},{"UnitLevel",7},{"UnitClass",8},
 {"IsPlayerMoving",9},{"C_Spell.IsSpellInRange",10},
 {"C_Spell.GetSpellCooldown",11},{"C_UnitAuras.GetAuraDataByIndex",12},
 {"UnitThreatSituation",14},{"UnitCastingInfo",15},
 {"IsInGroup",17},{"IsInInstance",18},
 {"C_SpellBook.IsSpellKnown",19},
 {"C_SpellBook.GetSpellBookItemInfo",20},
 {"C_Spell.IsSpellUsable",21},{"C_Spell.IsCurrentSpell",24},
 {"C_Spell.GetSpellCharges",26},{"GetActionInfo",32},
 {"GetBindingKey",33},{"GetBindingAction",33}
}
local catalog={}
for _,pair in ipairs(methods) do catalog[pair[1]]=pair[2] end
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
    for _,m in ipairs(methods) do
        local outcome=self:ProbeMethod(m[1])
        if outcome.status=="READY" then present=present+1 end
        entries[#entries+1]={name=m[1],matrix=m[2],status=outcome.status}
    end
    self.lastProbe={entries=entries,present=present,total=#entries,
        evidence="presence_only_not_client_pass"}
    -- One bounded record, never serialize game values.
    if self.active then self:Record("API","READY","presence_only") end
    return self.lastProbe
end
