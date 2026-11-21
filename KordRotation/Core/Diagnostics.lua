-- Kord Rotation (c) 2026 Vi22Rus. All rights reserved.
-- Basic user support state ONLY. Developer probes/logs/export live in KordRotationDevTools.
local addonName, KR = ...
KR.Diagnostics = KR.Diagnostics or {}
local D = KR.Diagnostics
function D:Log(level,module,message)
    -- Keep legacy callers harmless; no developer event/message retention
    -- in the ordinary user addon.
    if level=="ERROR" then self.errorCount=math.min((self.errorCount or 0)+1,1000) end
end
function D:Clear()
    self.errorCount=0
end
function D:Snapshot()
    local s=KR.characterState or {}
    local panel=KR.db and KR.db.panel or {}
    local result={
        version=KR.version or "?",locale=KR.locale or "?",
        class=s.classToken or "?",level=s.level or "?",profile=s.profileID or "?",
        config=s.talents and s.talents.configID or "?",
        method=s.talents and s.talents.method or "?",
        certainty=KR:L(s.status=="confirmed" and "DIAG_CERT_CONFIRMED" or "DIAG_CERT_UNVERIFIED"),
        branch=s.index or "?",
        status=s.status or "unavailable",reason=s.reason or "-",
        counts=s.talents and s.talents.counts and table.concat(s.talents.counts,"/") or "?",
        trigger=s.lastTrigger or "?",slots=panel.slotCount or 3,
        x=panel.x or 0,y=panel.y or -120,scale=panel.scale or 100,
        testMode=panel.testMode==true,
    }
    return result
end
-- Each probe calls only read-only, documented API where available.
function D:CompatibilityText()
    local version, build, interface = "?", "?", "?"
    if type(GetBuildInfo)=="function" then
        local ok, v, b, _, number = pcall(GetBuildInfo)
        if ok then
            version=tostring(v or "?")
            build=tostring(b or "?")
            interface=tostring(number or "?")
        end
    end
    local lockdown="unknown"
    if type(InCombatLockdown)=="function" then
        local ok, active=pcall(InCombatLockdown)
        if ok then lockdown=active and "combat" or "out of combat" end
    end
    local queued=KR.SafeActions and KR.SafeActions:Status() or 0
    local key=lockdown=="combat" and "ADV_COMPAT_COMBAT" or
        lockdown=="out of combat" and "ADV_COMPAT_OUT" or "ADV_COMPAT_UNKNOWN"
    return KR:Format("ADV_COMPAT_LINE",version,build,interface,
        tostring(KR.version),KR:L(key),queued)
end

function D:RecordCharacter(state)
    -- Legacy compatibility: developer trace is confined to DevTools.
    return state~=nil
end
-- Copyright notice: see root LICENSE.
