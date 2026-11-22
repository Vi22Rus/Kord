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
        -- The engine stops at the first UNKNOWN or READY. Expose only
        -- the final evaluated priority number and safe status/reason.
        local count=#diagnostics
        if count>=1 and count<=64 then
            local decisive=field(diagnostics,count)
            if type(decisive)=="table" then
                out.decisivePriority=count
                out.decisiveStatus=status(field(decisive,"status"))
                out.decisiveReason=reason(field(decisive,"reason")) or "unknown"
            end
        end
        local first=field(diagnostics,1)
        if type(first)=="table" then
            out.firstStatus=status(field(first,"status"))
            out.firstReason=reason(field(first,"reason")) or "unknown"
        end
        -- Hunter BM pilot declares eight ranks from highest to lowest.
        -- At level 30, rule 5 is the level-28 / rank-4 Arcane Shot rule.
        -- Only its status and reason cross the diagnostic bridge.
        if #diagnostics>=5 and profileID=="HUNTER_BM_PILOT_EXPERIMENTAL" then
            local fourthRank=field(diagnostics,5)
            if type(fourthRank)=="table" then
                out.arcaneR4Status=status(field(fourthRank,"status"))
                out.arcaneR4Reason=reason(field(fourthRank,"reason")) or "unknown"
                out.arcaneR4BarReason=reason(field(fourthRank,"barReason"))
                local checks=field(fourthRank,"checks")
                local validNames={
                    cast=true,usability=true,charges=true,
                    cooldown=true,gcd=true,range=true
                }
                if type(checks)=="table" and #checks<=6 then
                    local summary={}
                    for i=1,#checks do
                        local check=field(checks,i)
                        local name=field(check,"name")
                        if type(name)=="string" and validNames[name] then
                            summary[#summary+1]={
                                name=name,status=status(field(check,"status")),
                                reason=reason(field(check,"reason")) or "none"
                            }
                        end
                    end
                    out.arcaneR4Checks=summary
                end
            end
        end
    end
    return out
end

-- The optional recorder requests a complete, bounded profile audit.
-- This bridge strips spell IDs, GUIDs, player strings and all raw values;
-- only fixed signal names, statuses, priorities and safe reason codes pass.
local BM_SIGNALS={
 ["player.level"]=true,["player.moving"]=true,
 ["player.combat"]=true,["player.health.percent"]=true,
 ["player.mounted"]=true,["player.hasAggro"]=true,
 ["player.travelAspect"]=true,["target.exists"]=true,
 ["target.dead"]=true,["target.attackable"]=true,
 ["target.isPlayer"]=true,["target.threat"]=true,
 ["target.classification"]=true,["target.melee"]=true,
 ["pull.remaining"]=true,
 ["target.targetsPlayer"]=true,["target.approaching"]=true,
 ["target.slowed"]=true,["target.wingClip"]=true,
 ["target.willSurviveBurst"]=true,["target.dyingSoon"]=true,
 ["target.stingRemaining"]=true,["target.ttd"]=true,
 ["target.debuff"]=true,["player.buff"]=true,
 ["pet.exists"]=true,["pet.dead"]=true,
 ["pet.health.percent"]=true,["pet.attackingTarget"]=true,
 ["pet.mendActive"]=true,["context.inGroup"]=true,
 ["context.inRaid"]=true,["context.inInstance"]=true,
 ["context.instanceType"]=true,["resources.percent"]=true,
 ["trap.profitable"]=true,["need.distance"]=true,
 ["mongoose.usable"]=true,["autoShot.active"]=true,
 ["autoShot.swing"]=true,["intimidation.profitable"]=true,
 ["aoe.safe"]=true,["volley.profitable"]=true,
 ["multi.profitable"]=true,["enemy.count"]=true,
 ["hawk.count"]=true,["hawk.oldestRemaining"]=true,
 ["aimed.profitable"]=true,["sting.profitable"]=true,
 ["spell.range"]=true,["fact.known"]=true,
 ["fact.inRange"]=true,["fact.cooldownActive"]=true
}
local BM_CHECKS={
 cast=true,usability=true,charges=true,cooldown=true,gcd=true,range=true
}
function O:ReadFullAudit()
    local engine=KR.RotationEngine
    if not engine or type(engine.AuditFull)~="function" then
        return {status="UNAVAILABLE",reason="engine_unavailable",rules={}}
    end
    local ok,audit=pcall(engine.AuditFull,engine)
    if not ok or not safe(audit) or type(audit)~="table" then
        return {status="UNKNOWN",reason="engine_exception",rules={}}
    end
    local result={status=status(field(audit,"status")),
        reason=reason(field(audit,"reason")) or "unknown",rules={}}
    local source=field(audit,"rules")
    if type(source)~="table" then return result end
    local n=math.min(#source,64)
    result.ruleCount=n
    local module=field(audit,"profileID")
    if module=="HUNTER_BM_LEVELING_PVE" then result.module="bm_leveling"
    elseif module=="HUNTER_BM_PILOT_EXPERIMENTAL" then
        result.module="bm_pilot"
    elseif module=="HUNTER_BM_60_PVE" then result.module="bm_60"
    else result.module="unavailable" end
    for i=1,n do
        local original=field(source,i)
        if type(original)=="table" then
            local item={priority=i,status=status(field(original,"status")),
                reason=reason(field(original,"reason")) or "unknown",
                signals={},checks={}}
            local inputs=field(original,"signals")
            if type(inputs)=="table" then
                for j=1,math.min(#inputs,24) do
                    local inp=field(inputs,j)
                    local name=field(inp,"field")
                    if BM_SIGNALS[name] then
                        item.signals[#item.signals+1]={
                            name=name,status=status(field(inp,"status")),
                            reason=reason(field(inp,"reason")) or "unknown"}
                    end
                end
            end
            local checks=field(original,"checks")
            if type(checks)=="table" then
                for j=1,math.min(#checks,6) do
                    local ch=field(checks,j)
                    local name=field(ch,"name")
                    if BM_CHECKS[name] then
                        item.checks[#item.checks+1]={
                            name=name,status=status(field(ch,"status")),
                            reason=reason(field(ch,"reason")) or "none"}
                    end
                end
            end
            item.barReason=reason(field(original,"barReason"))
            result.rules[#result.rules+1]=item
        end
    end
    return result
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
    local arcaneChosenID=nil
    local rankIDs={
        [3044]=1,[14281]=2,[14282]=3,[14283]=4,
        [14284]=5,[14285]=6,[14286]=7,[14287]=8
    }
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
                        local selected=field(spells,"Arcane")
                        if type(selected)=="number" and detected[selected]
                            and rankIDs[selected] then
                            rank=rankIDs[selected]
                            arcaneChosenID=selected
                        else
                            for i=8,1,-1 do
                                local id=field(spells,"ArcaneShotR"..i)
                                if type(id)=="number" and detected[id] then
                                    rank=i
                                    arcaneChosenID=id
                                    break
                                end
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
            local id=arcaneChosenID
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
    local panel=field(KR.db,"panel")
    local out={
        status="READY",
        panelEnabled=field(panel,"showPanel")==true,
        testMode=field(panel,"testMode")==true,
        frameCreated=frame~=nil,
        recommendationAccepted=ready==true,
        defensiveEnabled=field(KR.IndicatorSettings and KR.db and KR.db.indicators,
            "defensiveEnabled")==true or
            (KR.IndicatorSettings and KR.IndicatorSettings:Get("defensiveEnabled")==true)
            or false,
        defensiveCombatOnly=KR.IndicatorSettings and
            KR.IndicatorSettings:Get("defensiveCombatOnly")==true or false,
        auraPromotion=KR.RotationSettings and
            KR.RotationSettings:GetFlag("buffsInCombatMain")==true or false,
        defensiveRecommendation=field(display,"defensiveReady")==true,
        defensiveStatus=status(field(display,"lastDefensiveStatus")),
        defensiveReason=reason(field(display,"lastDefensiveReason")) or "unknown",
        lastEngineStatus=status(field(display,"lastEngineStatus")),
        lastEngineReason=reason(field(display,"lastEngineReason")) or "unknown",
    }
    local defensiveFrame=field(display,"defenseFrame")
    out.defensiveFrameCreated=defensiveFrame~=nil
    if defensiveFrame and safe(defensiveFrame) then
        local api=KR.GameAPI
        local method=api and type(api.ReadField)=="function"
            and api:ReadField(defensiveFrame,"IsShown","function")
        local fn=method and method.status=="READY" and method.value
        if type(fn)=="function" then
            local ok,value=pcall(fn,defensiveFrame)
            if ok and safe(value) and type(value)=="boolean" then
                out.defensiveFrameShown=value
            end
        end
    end
    if type(display.ShouldShowDefensive)=="function" then
        local ok,value=pcall(display.ShouldShowDefensive,display)
        if ok and safe(value) and type(value)=="boolean" then
            out.defensiveVisibilityAllowed=value
        end
    end
    if frame and safe(frame) then
        local api=KR.GameAPI
        local method=api and type(api.ReadField)=="function"
            and api:ReadField(frame,"IsShown","function")
        local fn=method and method.status=="READY" and method.value
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
    Audit=function()
        local ok,result=pcall(O.ReadFullAudit,O)
        if not ok then return {status="UNKNOWN",
            reason="engine_exception",rules={}} end
        return result
    end,
    Target=function()
        local ok,result=pcall(O.ReadTarget,O)
        if not ok then return {liveStatus="UNKNOWN",snapshotStatus="UNKNOWN"} end
        return result
    end,
    BeginAPITrace=function()
        local ok,enabled=pcall(O.BeginAPITrace,O)
        return ok and enabled==true
    end,
    EndAPITrace=function()
        local ok,disabled=pcall(O.EndAPITrace,O)
        return ok and disabled==true
    end,
    APITrace=function()
        local ok,result=pcall(O.ReadAPITrace,O)
        if not ok then return {active=false,entries={},overflow=0} end
        return result
    end,
    APIMethodNames=function()
        local ok,result=pcall(O.ReadAPIMethodNames,O)
        if not ok then return {} end
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
-- Opt-in read-only method tracing. The core never writes logs, and the
-- bridge only exposes the fixed API adapter method names and scalar results.
function O:BeginAPITrace()
    local api=KR.GameAPI
    if not api or type(api.BeginDiagnosticTrace)~="function" then
        return false
    end
    return api:BeginDiagnosticTrace()
end
function O:EndAPITrace()
    local api=KR.GameAPI
    if not api or type(api.EndDiagnosticTrace)~="function" then
        return false
    end
    return api:EndDiagnosticTrace()
end
function O:ReadAPITrace()
    local api=KR.GameAPI
    if not api or type(api.DrainDiagnosticTrace)~="function" then
        return {active=false,entries={}}
    end
    return api:DrainDiagnosticTrace()
end
function O:ReadAPIMethodNames()
    local api=KR.GameAPI
    if not api or type(api.SupportedNames)~="function" then
        return {}
    end
    local names=api:SupportedNames()
    -- Each presence-only probe is a distinct observation from a real
    -- call of the corresponding game method.
    local count=#names
    for i=1,count do
        names[#names+1]="GameAPI.Probe."..names[i]
    end
    names[#names+1]="GameAPI.ActionBarScanner.inspect"
    names[#names+1]="GameAPI.ActionBarScanner.findspell"
    names[#names+1]="GameAPI.ReadField"
    names[#names+1]="GameAPI.ReadHealthPercent"
    names[#names+1]="GameAPI.ReadPowerPercent"
    names[#names+1]="GameAPI.unsupported"
    return names
end
-- Copyright notice: see root LICENSE.
