-- Kord Rotation (c) 2026 Vi22Rus. All rights reserved.
-- Stage 2.7: conservative, read-only candidate gate; no cast/priority decisions.
local addonName, KR = ...
KR.AbilityEligibility = KR.AbilityEligibility or {}
local A = KR.AbilityEligibility
local GCD_SPELL_ID = 61304
local watched = {"spellbook","actionbar","identity","talents","target","resources","cast","combat","cooldowns"}
local function validID(n)
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
    return {status=status,reason=reason,spellID=id,source="AbilityEligibility"}
end
local function choose(unknown,reason)
    if not unknown then return reason end
    return unknown
end
local function cooldown(id)
    local api=KR.GameAPI
    if not api then return "UNKNOWN","api_missing" end
    if api:Probe("C_Spell.GetSpellCooldown").status=="READY" then
        local r=get("C_Spell.GetSpellCooldown","table",id)
        if r.status~="READY" then return "UNKNOWN","cooldown_unavailable" end
        local active=field(r.value,"isActive")
        local onGCD=field(r.value,"isOnGCD")
        if type(active)~="boolean" then return "UNKNOWN","cooldown_activity_unknown" end
        if active==false then return "READY" end
        if onGCD==true then return "READY" end -- GCD is evaluated separately
        if onGCD==false then return "BLOCKED","individual_cooldown" end
        return "UNKNOWN","cooldown_gcd_ambiguous"
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
        if type(active)~="boolean" then return "UNKNOWN","gcd_activity_unknown" end
        if active then return "BLOCKED","global_cooldown" end
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
        current,max=field(r.value,"currentCharges"),field(r.value,"maxCharges")
    else
        local r=multi("GetSpellCharges",id)
        if r.status~="READY" then return "UNKNOWN","charges_unavailable" end
        current,max=r.value[1],r.value[2]
    end
    if not number(current) or not number(max) or current<0 or max<1
        or current>max or current~=math.floor(current) or max~=math.floor(max) then
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
local function targetAndRange(id,policy)
    if policy=="none" or policy=="self" then return "READY" end
    if policy~="enemy" and policy~="friendly" then
        return "UNKNOWN","target_policy_required"
    end
    local state=KR.GameState and KR.GameState:GetSnapshot()
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
    if not validID(id) then return candidate("UNKNOWN","invalid_spell_id",id) end
    options=type(options)=="table" and options or {}
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
    local catalogue=KR.SpellCatalogue and KR.SpellCatalogue:Read()
    if not catalogue or catalogue.status~="ready" then
        return candidate("UNKNOWN","spellbook_unavailable",id)
    end
    local known=false
    for _,item in ipairs(catalogue.entries or {}) do
        if item.id==id and item.known==true then known=true;break end
    end
    if not known then return candidate("BLOCKED","not_learned",id) end
    if not KR.ActionBarScanner or not KR.ActionBarScanner.FindSpell then
        return candidate("UNKNOWN","scanner_unavailable",id)
    end
    local bar=KR.ActionBarScanner:FindSpell(id)
    if not bar or bar.status~="READY" then
        return candidate("UNKNOWN","action_slot_unconfirmed",id)
    end
    local state=KR.GameState and KR.GameState:GetSnapshot()
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
    local unknown
    local checks={
        {castStatus,options.cast},
        {usability,id},
        {charges,id,options.chargesRequired==true},
        {cooldown,id},
        {gcd},
        {targetAndRange,id,options.target},
    }
    -- A definite BLOCKED beats UNKNOWN; UNKNOWN never becomes READY.
    for _,entry in ipairs(checks) do
        local status,reason=entry[1](entry[2],entry[3])
        if status=="BLOCKED" then return candidate("BLOCKED",reason,id) end
        if status~="READY" then unknown=choose(unknown,reason or "unverified") end
    end
    if unknown then return candidate("UNKNOWN",unknown,id) end
    local result=candidate("READY",nil,id)
    result.slot=bar.slot
    result.target=options.target
    return result
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
