-- Kord Rotation (c) 2026 Vi22Rus. All rights reserved.
-- Stage 2.7: conservative, read-only candidate gate; no cast/priority decisions.
local addonName, KR = ...
KR.AbilityEligibility = KR.AbilityEligibility or {}
local A = KR.AbilityEligibility
local GCD_SPELL_ID = 61304
local watched = {"spellbook","actionbar","identity","talents","target","resources","cast","combat","cooldowns"}
local function validID(n)
    -- Check secrecy BEFORE type checks, math.floor or numeric comparisons.
    local api=KR.GameAPI
    if not api or type(api.IsSafeValue)~="function" or not api:IsSafeValue(n) then
        return false
    end
    return type(n)=="number" and n==n and n==math.floor(n) and n>=1 and n<=99999999
end
local function number(n)
    return type(n)=="number" and n==n and n~=math.huge and n~=-math.huge
end
local function field(record,key)
    local api=KR.GameAPI
    if not api or not api.ReadField then return nil end
    local v=api:ReadField(record,key)
    if v.status=="READY" then return v.value end
    return nil
end
local function get(name,typ,...)
    if not KR.GameAPI then return {status="UNAVAILABLE"} end
    return KR.GameAPI:Read(name,typ,...)
end
local function multi(name,...)
    if not KR.GameAPI then return {status="UNAVAILABLE"} end
    return KR.GameAPI:ReadValues(name,...)
end
local function candidate(status,reason,id)
    -- Never forward untrusted/secret ID into UI or future DevTools traces.
    -- validID rejects protected values before math and comparisons.
    return {status=status,reason=reason,
        spellID=validID(id) and id or nil,source="AbilityEligibility"}
end
local function choose(unknown,reason)
    if not unknown then return reason end
    return unknown
end
-- Matrix v14 #19/#81: catalogue absence is not proof of an unknown spell.
-- Talent/passive spells may be known but absent from a scanned book.
-- Never guess the player spell-book bank or silently treat nil as false.
local function spellKnown(id,catalogue)
    if not catalogue or catalogue.status~="ready" then
        return "UNKNOWN","spellbook_unavailable"
    end
    for _,item in ipairs(catalogue.entries or {}) do
        if item.id==id and item.known==true then return "READY" end
    end
    local api=KR.GameAPI
    local enum=type(Enum)=="table" and Enum.SpellBookSpellBank
    local bank=type(enum)=="table" and enum.Player
    if not api or type(api.Probe)~="function" or type(api.Read)~="function"
        or type(api.IsSafeValue)~="function" or not api:IsSafeValue(bank)
        or type(bank)~="number" or bank~=math.floor(bank)
        or api:Probe("C_SpellBook.IsSpellKnown").status~="READY" then
        return "UNKNOWN","spell_known_unverified"
    end
    local r=api:Read("C_SpellBook.IsSpellKnown","boolean",id,bank)
    if r.status~="READY" then return "UNKNOWN","spell_known_unverified" end
    if r.value==false then return "BLOCKED","not_learned" end
    return "READY"
end

local function cooldown(id)
    local api=KR.GameAPI
    if not api then return "UNKNOWN","api_missing" end
    if api:Probe("C_Spell.GetSpellCooldown").status=="READY" then
        local r=get("C_Spell.GetSpellCooldown","table",id)
        if r.status~="READY" then return "UNKNOWN","cooldown_unavailable" end
        local active=field(r.value,"isActive")
        if type(active)~="boolean" then return "UNKNOWN","cooldown_activity_unknown" end
        if active==false then return "READY" end
        -- Canonical v14 #83: isOnGCD is reliable only during the
        -- SPELL_UPDATE_COOLDOWN event. This path is a snapshot poll;
        -- do NOT infer 'ready' from isOnGCD=true outside that event.
        -- An active cooldown is not safe to recommend, but its category
        -- (individual/shared/GCD) remains unknown in this context.
        return "BLOCKED","cooldown_active_unclassified"
    end
    local r=multi("GetSpellCooldown",id)
    if r.status~="READY" then return "UNKNOWN","cooldown_unavailable" end
    local start,duration,enabled=r.value[1],r.value[2],r.value[3]
    if not number(start) or not number(duration) or duration<0 or start<0
        or (enabled~=nil and enabled~=0 and enabled~=1) then
        return "UNKNOWN","cooldown_invalid"
    end
    if enabled==0 then return "BLOCKED","cooldown_disabled" end
    if start==0 or duration==0 then return "READY" end
    local now=get("GetTime","number")
    if now.status~="READY" then return "UNKNOWN","cooldown_clock_unknown" end
    if start+duration<=now.value then return "READY" end
    return "BLOCKED","individual_cooldown"
end
local function gcd()
    local api=KR.GameAPI
    if not api then return "UNKNOWN","api_missing" end
    if api:Probe("C_Spell.GetSpellCooldown").status=="READY" then
        local r=get("C_Spell.GetSpellCooldown","table",GCD_SPELL_ID)
        if r.status~="READY" then return "UNKNOWN","gcd_unavailable" end
        local active=field(r.value,"isActive")
        -- Matrix v14 #25/#80: only a confirmed plain boolean can
        -- establish GCD state. Never derive it from startTime/duration,
        -- which may be protected in combat.
        if type(active)~="boolean" then return "UNKNOWN","gcd_activity_unknown" end
        if active==true then return "BLOCKED","global_cooldown" end
        return "READY"
    end
    local r=multi("GetSpellCooldown",GCD_SPELL_ID)
    if r.status~="READY" then return "UNKNOWN","gcd_unavailable" end
    local start,duration=r.value[1],r.value[2]
    if not number(start) or not number(duration) or start<0 or duration<0 then
        return "UNKNOWN","gcd_invalid"
    end
    if start==0 or duration==0 then return "READY" end
    local now=get("GetTime","number")
    if now.status~="READY" then return "UNKNOWN","gcd_clock_unknown" end
    if start+duration<=now.value then return "READY" end
    return "BLOCKED","global_cooldown"
end
local function charges(id,required)
    if not required then return "READY" end
    local api=KR.GameAPI
    if not api then return "UNKNOWN","charges_api_missing" end
    local current,max
    if api:Probe("C_Spell.GetSpellCharges").status=="READY" then
        local r=get("C_Spell.GetSpellCharges","table",id)
        if r.status~="READY" then return "UNKNOWN","charges_unavailable" end
        -- Matrix v14 #26: currentCharges may be secret. maxCharges
        -- and isActive are NOT substitutes for a known usable count.
        -- In particular isActive=true describes recharge, not 0 charges.
        current,max=field(r.value,"currentCharges"),field(r.value,"maxCharges")
    else
        local r=multi("GetSpellCharges",id)
        if r.status~="READY" then return "UNKNOWN","charges_unavailable" end
        current,max=r.value[1],r.value[2]
    end
    -- The legacy and modern readers must both deliver ordinary,
    -- finite integers. Zero is confirmed exhaustion, not a nil proxy.
    if not number(current) or not number(max) then
        return "UNKNOWN","charges_invalid"
    end
    if current<0 or max<1 or current>max
        or current~=math.floor(current) or max~=math.floor(max) then
        return "UNKNOWN","charges_invalid"
    end
    if current==0 then return "BLOCKED","no_charges" end
    return "READY"
end
local function usability(id)
    local api=KR.GameAPI
    if not api then return "UNKNOWN","api_missing" end
    local r
    if api:Probe("C_Spell.IsSpellUsable").status=="READY" then
        r=multi("C_Spell.IsSpellUsable",id)
    else r=multi("IsUsableSpell",id) end
    if r.status~="READY" then return "UNKNOWN","usability_unavailable" end
    local usable,noPower=r.value[1],r.value[2]
    if type(usable)~="boolean" or type(noPower)~="boolean" then
        return "UNKNOWN","usability_invalid"
    end
    if noPower then return "BLOCKED","insufficient_resources" end
    if not usable then return "BLOCKED","spell_unusable" end
    return "READY"
end
local function targetAndRange(id,policy,stateSnapshot)
    if policy=="none" or policy=="self" then return "READY" end
    if policy~="enemy" and policy~="friendly" then
        return "UNKNOWN","target_policy_required"
    end
    local state=stateSnapshot
    if not state then state=KR.GameState and KR.GameState:GetSnapshot() end
    local target=state and state.target
    if not target or not target.exists or target.exists.status~="READY" then
        return "UNKNOWN","target_unknown"
    end
    if target.exists.value==false then return "BLOCKED","target_missing" end
    if not target.dead or target.dead.status~="READY" then
        return "UNKNOWN","target_life_unknown"
    end
    if target.dead.value then return "BLOCKED","target_dead" end
    local condition
    if policy=="enemy" then condition=target.attackable
    else condition=target.assistable end
    if not condition or condition.status~="READY" then
        return "UNKNOWN","target_relation_unknown"
    end
    if condition.value==false then return "BLOCKED","target_relation_invalid" end
    local api=KR.GameAPI
    local result
    if api and api:Probe("C_Spell.IsSpellInRange").status=="READY" then
        result=get("C_Spell.IsSpellInRange","boolean",id,"target")
    else
        result=multi("IsSpellInRange",id,"target")
        if result.status=="READY" then
            local value=result.value[1]
            if value==true or value==1 then return "READY" end
            if value==false or value==0 then return "BLOCKED","out_of_range" end
        end
        return "UNKNOWN","range_unavailable"
    end
    if result.status~="READY" then return "UNKNOWN","range_unavailable" end
    if result.value==false then return "BLOCKED","out_of_range" end
    return "READY"
end
local function castStatus(policy)
    if policy=="allow" then return "READY" end
    if policy~="idle" then return "UNKNOWN","cast_policy_required" end
    local api=KR.GameAPI
    if not api or api:Probe("UnitCastingInfo").status~="READY"
        or api:Probe("UnitChannelInfo").status~="READY" then
        return "UNKNOWN","cast_api_unavailable"
    end
    local cast=multi("UnitCastingInfo","player")
    local channel=multi("UnitChannelInfo","player")
    if cast.status~="READY" or channel.status~="READY" then
        return "UNKNOWN","cast_unknown"
    end
    if cast.value[1]~=nil or channel.value[1]~=nil then
        return "BLOCKED","already_casting"
    end
    return "READY"
end
function A:Evaluate(id,options)
    if not validID(id) then return candidate("UNKNOWN","invalid_spell_id",nil) end
    local api=KR.GameAPI
    -- Policy tables and their fields must be safe before indexing/comparison.
    if not api or not api:IsSafeValue(options) then
        return candidate("UNKNOWN","options_protected",id)
    end
    options=type(options)=="table" and options or {}
    if not api:IsSafeValue(options.stateSnapshot)
        or not api:IsSafeValue(options.target)
        or not api:IsSafeValue(options.cast)
        or not api:IsSafeValue(options.chargesRequired)
        or not api:IsSafeValue(options.minLevel) then
        return candidate("UNKNOWN","policy_protected",id)
    end
    if options.target~="enemy" and options.target~="friendly"
        and options.target~="self" and options.target~="none" then
        return candidate("UNKNOWN","target_policy_required",id)
    end
    if options.cast~="idle" and options.cast~="allow" then
        return candidate("UNKNOWN","cast_policy_required",id)
    end
    if type(options.chargesRequired)~="boolean" then
        return candidate("UNKNOWN","charge_policy_required",id)
    end
    -- Canonical v14 #82: minimum character level is an explicit rule
    -- precondition, distinct from known spell, rank and usable spell.
    -- No implicit required level can be guessed from a spellbook entry.
    if options.minLevel~=nil and
        (type(options.minLevel)~="number"
        or options.minLevel~=options.minLevel
        or options.minLevel~=math.floor(options.minLevel)
        or options.minLevel<1 or options.minLevel>100) then
        return candidate("UNKNOWN","level_policy_invalid",id)
    end
    local catalogue=KR.SpellCatalogue and KR.SpellCatalogue:Read()
    local knownStatus,knownReason=spellKnown(id,catalogue)
    if knownStatus~="READY" then return candidate(knownStatus,knownReason,id) end
    if not KR.ActionBarScanner or not KR.ActionBarScanner.FindSpell then
        return candidate("UNKNOWN","scanner_unavailable",id)
    end
    local bar=KR.ActionBarScanner:FindSpell(id)
    if not bar or bar.status~="READY" then
        return candidate("UNKNOWN","action_slot_unconfirmed",id)
    end
    local state=options.stateSnapshot
    if state==nil then state=KR.GameState and KR.GameState:GetSnapshot() end
    if not state or not state.player or not state.player.exists
        or state.player.exists.status~="READY" then
        return candidate("UNKNOWN","player_unknown",id)
    end
    if state.player.exists.value==false then
        return candidate("BLOCKED","player_missing",id)
    end
    if not state.player.dead or state.player.dead.status~="READY" then
        return candidate("UNKNOWN","player_life_unknown",id)
    end
    if state.player.dead.value then
        return candidate("BLOCKED","player_dead",id)
    end
    if options.minLevel~=nil then
        local level=state.player.level
        if not level or level.status~="READY"
            or not api:IsSafeValue(level.value)
            or type(level.value)~="number"
            or level.value~=level.value
            or level.value~=math.floor(level.value)
            or level.value<1 or level.value>100 then
            return candidate("UNKNOWN","player_level_unknown",id)
        end
        if level.value<options.minLevel then
            return candidate("BLOCKED","player_level_too_low",id)
        end
    end
    local unknown
    local checks={
        {castStatus,options.cast},
        {usability,id},
        {charges,id,options.chargesRequired==true},
        {cooldown,id},
        {gcd},
        {targetAndRange,id,options.target,state},
    }
    -- A definite BLOCKED beats UNKNOWN; UNKNOWN never becomes READY.
    for _,entry in ipairs(checks) do
        local status,reason=entry[1](entry[2],entry[3],entry[4])
        if status=="BLOCKED" then return candidate("BLOCKED",reason,id) end
        if status~="READY" then unknown=choose(unknown,reason or "unverified") end
    end
    if unknown then return candidate("UNKNOWN",unknown,id) end
    local result=candidate("READY",nil,id)
    result.slot=bar.slot
    result.target=options.target
    return result
end
-- Profile Contract v1 facts are narrow observations, never a READY recommendation.
-- Only a proven, ordinary boolean is exposed; missing/secret data stays UNKNOWN.
function A:Fact(id,kind,options)
    if not validID(id) then return {status="UNKNOWN",reason="invalid_spell_id"} end
    local api=KR.GameAPI
    if not api or type(api.IsSafeValue)~="function" then
        return {status="UNKNOWN",reason="api_missing"}
    end
    local ok,safeKind=pcall(api.IsSafeValue,api,kind)
    if not ok or safeKind~=true or type(kind)~="string" then
        return {status="UNKNOWN",reason="fact_kind_unverified"}
    end
    if options~=nil then
        local okOptions,safeOptions=pcall(api.IsSafeValue,api,options)
        if not okOptions or safeOptions~=true or type(options)~="table" then
            return {status="UNKNOWN",reason="fact_options_unverified"}
        end
    end
    local function answer(value)
        if type(value)~="boolean" then
            return {status="UNKNOWN",reason="fact_value_unverified"}
        end
        return {status="READY",value=value,source="AbilityEligibility.Fact"}
    end
    if kind=="cooldownActive" then
        -- v14 #83: isActive is a fact; isOnGCD is NOT authoritative in a poll.
        if type(api.Probe)~="function" or
            api:Probe("C_Spell.GetSpellCooldown").status~="READY" then
            return {status="UNKNOWN",reason="cooldown_fact_unavailable"}
        end
        local r=get("C_Spell.GetSpellCooldown","table",id)
        if not r or r.status~="READY" then
            return {status="UNKNOWN",reason="cooldown_fact_unavailable"}
        end
        return answer(field(r.value,"isActive"))
    elseif kind=="inRange" then
        -- This fact always refers to the current target; never guess the unit.
        if type(api.Probe)=="function" and
            api:Probe("C_Spell.IsSpellInRange").status=="READY" then
            local r=get("C_Spell.IsSpellInRange","boolean",id,"target")
            if not r or r.status~="READY" then
                return {status="UNKNOWN",reason="range_fact_unavailable"}
            end
            return answer(r.value)
        end
        local r=multi("IsSpellInRange",id,"target")
        if not r or r.status~="READY" or type(r.value)~="table" then
            return {status="UNKNOWN",reason="range_fact_unavailable"}
        end
        local v=r.value[1]
        if v==1 or v==true then return answer(true) end
        if v==0 or v==false then return answer(false) end
        return {status="UNKNOWN",reason="range_fact_unavailable"}
    end
    -- 'known' requires a separately audited fact-only spellbook path.
    -- 'chargesAtLeast' has no threshold parameter in Profile Contract v1.
    return {status="UNKNOWN",reason="fact_provider_unimplemented"}
end
function A:Invalidate(reason) self.lastInvalidation=reason or "manual" end
function A:Initialize()
    if self.initialized then return true end
    if not KR.EventBus then return false end
    for _,channel in ipairs(watched) do
        if not KR.EventBus:Subscribe(channel,"AbilityEligibility",function(ch)
            A:Invalidate(ch)
        end) then return false end
    end
    self.initialized=true
    return true
end
-- Copyright notice: see root LICENSE.
