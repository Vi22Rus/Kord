-- Kord Rotation (c) 2026 Vi22Rus. All rights reserved.
-- Licensed for personal use under the root LICENSE.
-- Never erase user data or inspect protected combat state without explicit permission.

local addonName, KR = ...
KR.Diagnostics = KR.Diagnostics or {}
local D = KR.Diagnostics
local maximum = 80
local function timeNow()
    if type(date) == "function" then
        local ok,value=pcall(date,"%H:%M:%S")
        if ok and type(value)=="string" then return value end
    end
    return "--:--:--"
end
local function safeText(value)
    local text=tostring(value or "")
    if #text>250 then return string.sub(text,1,250) end
    return text
end

-- License notice (2/3): bounded in-memory diagnostic history, no external reporting.
function D:Log(level,module,message)
    if not self.lines then self.lines={} end
    local entry={time=timeNow(),level=safeText(level),module=safeText(module),text=safeText(message)}
    table.insert(self.lines,entry)
    if #self.lines>maximum then table.remove(self.lines,1) end
    if level=="ERROR" then self.lastError=entry end
    if KR.RefreshDiagnosticsPage then KR:RefreshDiagnosticsPage() end
end

function D:Clear()
    self.lines={}
    self.lastError=nil
    if KR.RefreshDiagnosticsPage then KR:RefreshDiagnosticsPage() end
end

local probes={
    {"UnitClass",function()
        if type(UnitClass)~="function" then return false end
        local ok, _, token=pcall(UnitClass,"player")
        return ok and type(token)=="string" and token~=""
    end},
    {"UnitLevel",function()
        if type(UnitLevel)~="function" then return false end
        local ok, level=pcall(UnitLevel,"player")
        return ok and type(level)=="number"
    end},
    {"C_Traits",function() return type(C_Traits)=="table" and type(C_Traits.GetNodeInfo)=="function" end},
    {"C_ClassTalents",function() return type(C_ClassTalents)=="table" and type(C_ClassTalents.GetActiveConfigID)=="function" end},
    {"C_SpecializationInfo",function() return type(C_SpecializationInfo)=="table" end},
    {"C_Spell",function() return type(C_Spell)=="table" end},
    {"SpellBook",function() return type(GetSpellBookItemInfo)=="function" end},
    {"KeyBindings",function()
        if type(GetBindingKey)~="function" then return false end
        local ok=pcall(GetBindingKey,"ACTIONBUTTON1")
        return ok
    end},
    {"ActionButtons",function() return type(ActionButton1)=="table" end},
    {"CombatLockdown",function()
        if type(InCombatLockdown)~="function" then return false end
        local ok,v=pcall(InCombatLockdown)
        return ok and type(v)=="boolean"
    end},
}
function D:Capabilities()
    local result={}
    for _,probe in ipairs(probes) do
        local ok,available=pcall(probe[2])
        result[#result+1]={name=probe[1],available=ok and available or false,
            status=not ok and "error" or available and "present" or "unavailable"}
    end
    return result
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
function D:ProbeReport()
    local output={}
    for _,item in ipairs(self:Capabilities()) do
        output[#output+1]=item.name..": "..KR:L("DIAG_PROBE_"..string.upper(item.status))
    end
    return table.concat(output, " | ")
end

function D:Report()
    local s=self:Snapshot()
    local out={
        "Kord Rotation "..s.version.." | locale "..s.locale,
        "Class "..s.class.." | level "..s.level.." | profile "..s.profile.." | "..s.status,
        "Talents "..s.counts.." | config "..tostring(s.config).." | branch "..tostring(s.branch)..
            " | method "..tostring(s.method).." | certainty "..s.certainty,
        "Reason "..s.reason.." | update "..s.trigger,
        "Panel slots "..s.slots.." | x "..s.x.." y "..s.y..
            " | scale "..s.scale.." | test "..tostring(s.testMode),
        "Capabilities:",
    }
    for _,item in ipairs(self:Capabilities()) do
        out[#out+1]=item.name..": "..(item.available and "present" or "missing")
    end
    out[#out+1]="Last error: "..(self.lastError and self.lastError.text or "none")
    out[#out+1]="Compatibility: "..self:CompatibilityText()
    out[#out+1]="Recent events:"
    for _,line in ipairs(self.lines or {}) do
        out[#out+1]=line.time.." "..line.level.." ["..line.module.."] "..line.text
    end
    return table.concat(out,"\n")
end
function D:RecordCharacter(state)
    if not state then return end
    self:Log("INFO","Talents",tostring(state.classToken or "?")..
        " "..tostring(state.profileID or "none").." "..tostring(state.status or "?"))
end
-- Copyright notice (3/3): 2026 Vi22Rus; see LICENSE.
