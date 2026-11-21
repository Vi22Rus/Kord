-- Kord Rotation (c) 2026 Vi22Rus. All rights reserved.
-- Stage 2.8: one currently eligible recommendation, not a predicted future queue.
local addonName, KR = ...
KR.RotationEngine = KR.RotationEngine or {}
local E=KR.RotationEngine
local function empty(reason)
    return {status="UNKNOWN",reason=reason,queue={},source="RotationEngine"}
end
local function safeAsset(value)
    return (type(value)=="number" and value==value and value>0)
        or (type(value)=="string" and value~="" and #value<=255)
end
local function validID(n)
    return type(n)=="number" and n==math.floor(n) and n>=1 and n<=99999999
end
local function identity()
    local s=KR.characterState
    if type(s)~="table" or type(s.classToken)~="string"
        or type(s.index)~="number" or s.index~=math.floor(s.index)
        or s.index<1 or s.index>3 then return nil end
    return s.classToken.."_TREE_"..s.index
end
-- A strict v14 GameData subset: no dynamic field paths or truthiness coercion.
local requirementPaths={["player.moving"]={"player","moving"},
    ["target.isPlayer"]={"target","isPlayer"},["pet.exists"]={"pet","exists"},
    ["pet.dead"]={"pet","dead"},["context.inGroup"]={"context","inGroup"},
    ["context.inRaid"]={"context","inRaid"},
    ["context.inInstance"]={"context","inInstance"}}
local function requirementStatus(snapshot,requires)
    if not requires then return "READY" end
    for _,condition in ipairs(requires) do
        local path=requirementPaths[condition.field]
        if not path then return "UNKNOWN","requirement_unsupported" end
        local ok,signal=pcall(function()
            local section=snapshot[path[1]]
            return type(section)=="table" and section[path[2]] or nil
        end)
        if not ok or type(signal)~="table" then
            return "UNKNOWN","requirement_unavailable"
        end
        local safe,value=pcall(function() return signal.value end)
        local statusOK,status=pcall(function() return signal.status end)
        if not safe or not statusOK or status~="READY"
            or type(value)~="boolean"
            or not KR.GameAPI or type(KR.GameAPI.IsSafeValue)~="function"
            or not KR.GameAPI:IsSafeValue(value) then
            return "UNKNOWN","requirement_unverified"
        end
        if value~=condition.equals then return "BLOCKED","requirement_not_met" end
    end
    return "READY"
end
function E:Evaluate()
    if not KR.RotationProfiles or not KR.RotationSettings
        or not KR.AbilityEligibility or not KR.SpellCatalogue then
        return empty("engine_dependency_missing")
    end
    local profileID=identity()
    if not profileID then return empty("specialization_unknown") end
    local ruleset=KR.RotationProfiles:Get(profileID)
    if not ruleset then return empty("profile_not_registered") end
    local settings,id=KR.RotationSettings:GetProfile(false)
    if id~=profileID or not settings then return empty("rotation_settings_unavailable") end
    if settings.enabled~=true then return empty("rotation_disabled") end
    local mode=settings.targetMode
    if mode=="auto" then
        -- No proven hostile target-count API yet. Never guess ST or AoE.
        return empty("auto_target_count_unverified")
    end
    if mode~="single" and mode~="aoe" then return empty("target_mode_invalid") end
    local rules=ruleset[mode]
    if type(rules)~="table" or #rules==0 then return empty("no_rules_for_mode") end
    -- One GameState snapshot per pass; per-field UNKNOWN remains valid.
    if not KR.GameState or type(KR.GameState.GetSnapshot)~="function" then
        return empty("game_state_missing")
    end
    local ok,snapshot=pcall(KR.GameState.GetSnapshot,KR.GameState)
    if not ok or type(snapshot)~="table"
        or type(snapshot.player)~="table" or type(snapshot.target)~="table" then
        return empty("game_state_unavailable")
    end
    local book=KR.SpellCatalogue:Read()
    if not book or book.status~="ready" then return empty("spellbook_unavailable") end
    local catalogue={}
    for _,entry in ipairs(book.entries or {}) do
        if validID(entry.id) and entry.known==true then catalogue[entry.id]=entry end
    end
    local diagnostics={}
    for i,rule in ipairs(rules) do
        local override=type(settings.spells)=="table" and settings.spells[rule.spellID] or nil
        local enabled=rule.enabled~=false and (type(override)~="table" or override.enabled~=false)
        local category=rule.category
        if type(override)=="table" and type(override.category)=="string" then
            category=override.category
        end
        local status,reason
        if not enabled then status,reason="BLOCKED","rule_disabled"
        elseif type(settings.categories)~="table" or settings.categories[category]~=true then
            status,reason="BLOCKED","category_disabled"
        else
            local requirement,requirementReason=requirementStatus(snapshot,rule.requires)
            if requirement~="READY" then
                status,reason=requirement,requirementReason
            else
            local ok,value=pcall(KR.AbilityEligibility.Evaluate,KR.AbilityEligibility,
                rule.spellID,{target=rule.target,cast=rule.cast,
                    chargesRequired=rule.chargesRequired,stateSnapshot=snapshot})
            if not ok or type(value)~="table" then
                status,reason="UNKNOWN","eligibility_error"
            elseif value.status~="READY" and value.status~="BLOCKED"
                and value.status~="UNKNOWN" then
                status,reason="UNKNOWN","eligibility_status_invalid"
            elseif value.spellID~=rule.spellID then
                status,reason="UNKNOWN","eligibility_spell_mismatch"
            else status,reason=value.status,value.reason end
            end
        end
        diagnostics[#diagnostics+1]={priority=i,spellID=rule.spellID,status=status,reason=reason}
        if status=="READY" then
            local info=catalogue[rule.spellID]
            if not info or not safeAsset(info.texture)
                or type(info.name)~="string" or info.name=="" then
                diagnostics[#diagnostics].status="UNKNOWN"
                diagnostics[#diagnostics].reason="spell_visual_data_unverified"
                return {status="UNKNOWN",reason="spell_visual_data_unverified",
                    source="RotationEngine",profileID=profileID,mode=mode,
                    queue={},diagnostics=diagnostics}
            else
                local label=nil
                local bindingSource=nil
                if KR.BindingResolver and KR.BindingResolver.Resolve then
                    local ok,binding=pcall(KR.BindingResolver.Resolve,KR.BindingResolver,rule.spellID)
                    -- A key is shown only when Resolve confirms this exact
                    -- spell and an ordinary, nonempty label.
                    local api=KR.GameAPI
                    if ok and type(binding)=="table" and binding.status=="READY"
                        and binding.spellID==rule.spellID
                        and type(binding.bindingLabel)=="string"
                        and #binding.bindingLabel>0 and #binding.bindingLabel<=64
                        and api and type(api.IsSafeValue)=="function"
                        and api:IsSafeValue(binding.bindingLabel)
                        and (binding.bindingSource==nil or
                            (type(binding.bindingSource)=="string"
                             and api:IsSafeValue(binding.bindingSource))) then
                        label=binding.bindingLabel
                        bindingSource=binding.bindingSource
                    end
                end
                local record={spellID=rule.spellID,texture=info.texture,
                    name=info.name,keybind=label,bindingSource=bindingSource,
                    source="verified_profile",priority=i,category=category,
                    mode=mode}
                return {status="READY",reason=nil,source="RotationEngine",
                    profileID=profileID,mode=mode,queue={record},
                    diagnostics=diagnostics}
            end
        elseif status=="UNKNOWN" then
            -- Higher-priority UNKNOWN means we cannot safely recommend
            -- a lower-priority ability as though the earlier rule were false.
            return {status="UNKNOWN",reason=reason or "higher_priority_unknown",
                source="RotationEngine",profileID=profileID,mode=mode,
                queue={},diagnostics=diagnostics}
        end
    end
    return {status="BLOCKED",reason="no_eligible_rule",
        source="RotationEngine",profileID=profileID,mode=mode,
        queue={},diagnostics=diagnostics}
end
-- Not installed as an OnUpdate rule evaluator: the display triggers bounded reads.
-- Copyright notice: see repository LICENSE.
