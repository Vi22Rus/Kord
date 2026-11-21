-- Kord Rotation DevTools (c) 2026 Vi22Rus; see root LICENSE.
-- Explicit opt-in, bounded memory, no unknown input serialization.
local _,D=...
local kinds={EVENT=true,ENGINE=true,ELIGIBILITY=true,PROFILE=true,TARGET=true,ERROR=true,API=true,PERFORMANCE=true}
local statuses={READY=true,BLOCKED=true,UNKNOWN=true,UNAVAILABLE=true,ERROR=true}
local reasons={none=true,unknown=true,unavailable=true,protected_value=true,
    cooldown_unavailable=true,spellbook_unavailable=true,api_missing=true,
    engine_unavailable=true,profile_not_registered=true,rotation_disabled=true,
    already_casting=true,global_cooldown=true,not_learned=true,
    invalid_method=true,api_call_failed=true,presence_only=true,
    target_missing=true,no_eligible_rule=true,invalid_status=true,
    snapshot_unavailable=true,manual_sample=true,game_state_unavailable=true,
    action_slot_unconfirmed=true,spell_visual_data_unverified=true,
    condition_unknown=true,condition_false=true,no_confirmed_visible_slots=true,
    profile_unverified=true,rotation_settings_unavailable=true,
    player_level_unverified=true,spellbook_unavailable=true,
    target_present=true,target_absent=true,target_unverified=true,
    player_target_changed=true,update_bindings=true,spell_update_cooldown=true,
    actionbar_slot_changed=true,spells_changed=true,player_regen_enabled=true,
    player_regen_disabled=true,player_entering_world=true,
    unit_spellcast_succeeded=true,unit_spellcast_start=true,
    unit_spellcast_failed=true,unit_spellcast_interrupted=true,
    target_observed=true}
local function now()
    if type(GetTime)~="function" then return nil end
    local ok,t=pcall(GetTime)
    if not ok or not D:Safe(t) or type(t)~="number"
        or t~=t or t==math.huge or t<0 then return nil end
    return t
end
local function enum(value,allowed,unknown)
    if not D:Safe(value) or type(value)~="string" or not allowed[value] then
        return unknown
    end
    return value
end
local function int(v,min,max)
    if not D:Safe(v) or type(v)~="number" or v~=v
        or v~=math.floor(v) or v<min or v>max then return nil end
    return v
end
local function sanitizeReason(v)
    if not D:Safe(v) or type(v)~="string" or #v<1 or #v>64
        or not string.match(v,"^[a-z][a-z0-9_]*$") then return "unknown" end
    -- Never record arbitrary user data as a reason.
    return reasons[v] and v or "unknown"
end
function D:Start()
    if self.active then return false,"already_recording" end
    self.active=true
    self.records={}
    self.sequence=0
    self.dropped=0
    self.started=now()
    self.lastTick=nil
    self.session={matrix=self.matrix,version=self.version,
        started=self.started or 0,records=self.records}
    if self.TraceStart then self:TraceStart() end
    return true
end
function D:Stop()
    if not self.active then return false,"not_recording" end
    if self.TraceStop then self:TraceStop() end
    self.active=false
    if self.session then
        self.session.dropped=self.dropped
        self.session.stopped=now() or 0
        -- Store a sanitized scalar-only bounded copy, never raw references.
        local kept={matrix=self.matrix,version=self.version,
            started=self.session.started,stopped=self.session.stopped,
            dropped=self.dropped,records={}}
        for i,item in ipairs(self.records) do
            kept.records[i]={sequence=item.sequence,kind=item.kind,
                status=item.status,reason=item.reason,
                matrix=item.matrix,elapsed=item.elapsed,time=item.time}
        end
        local db=self.settings
        db.sessions=type(db.sessions)=="table" and db.sessions or {}
        table.insert(db.sessions,kept)
        while #db.sessions>self.maxSessions do table.remove(db.sessions,1) end
        KordRotationDevToolsDB=db
    end
    self.session=nil
    return true
end
function D:Record(kind,status,reason,matrix,elapsed)
    if not self.active then return false,"not_recording" end
    local current=now()
    if self.started and current and current-self.started>self.maxDuration then
        self:Stop()
        return false,"session_limit"
    end
    if #self.records>=self.maxRecords then
        self.dropped=self.dropped+1
        return false,"buffer_full"
    end
    if not D:Safe(kind) or not D:Safe(status) or not D:Safe(reason)
        or not D:Safe(matrix) or not D:Safe(elapsed) then
        self.dropped=self.dropped+1
        return false,"protected_value"
    end
    kind=enum(kind,kinds,"ERROR")
    status=enum(status,statuses,"UNKNOWN")
    reason=sanitizeReason(reason)
    local v14=int(matrix,1,101)
    local latency=int(elapsed,0,1000000)
    if self.lastTick and current and current-self.lastTick<0.05 then
        self.dropped=self.dropped+1
        return false,"rate_limited"
    end
    self.sequence=self.sequence+1
    self.records[#self.records+1]={sequence=self.sequence,kind=kind,
        status=status,reason=reason,matrix=v14,elapsed=latency,time=current}
    self.lastTick=current
    return true
end
function D:Clear()
    if self.active then return false,"stop_first" end
    self.records={}
    self.session=nil
    self.sequence=0
    self.dropped=0
    self.settings.sessions={}
    KordRotationDevToolsDB=self.settings
    return true
end
local function encode(v)
    if v==nil then return "" end
    if type(v)=="number" then return string.format("%.0f",v) end
    return type(v)=="string" and v or ""
end
function D:Export()
    -- Strict whitelist, never tostring unknown game payloads.
    local lines={"KordRotationDevTools\tmatrix="..self.matrix.."\tversion="..self.version}
    local list=self.records
    for _,v in ipairs(list) do
        local line=table.concat({encode(v.sequence),encode(v.kind),
            encode(v.status),encode(v.reason),encode(v.matrix),
            encode(v.elapsed),encode(v.time)},"\t")
        if #table.concat(lines,"\n")+#line+1>self.maxExport then break end
        lines[#lines+1]=line
    end
    lines[#lines+1]="dropped="..encode(self.dropped)
    return table.concat(lines,"\n")
end
