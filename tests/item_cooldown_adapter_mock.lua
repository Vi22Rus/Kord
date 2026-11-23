-- IT-02/2.3 synthetic Lua 5.1 adapter tests: no in-game claims.
local mode="missing"
local now=100
local calls={}
local function readValues(_,name,id)
    calls[#calls+1]=name
    assert(id==5512)
    if mode=="missing" then
        return {status="UNAVAILABLE",reason="api_missing"}
    end
    if mode=="fallback" and name=="C_Item.GetItemCooldown" then
        return {status="UNAVAILABLE",reason="api_missing"}
    end
    if mode=="secret" then return {status="UNKNOWN",reason="protected_value"} end
    if mode=="broken" then return {status="ERROR",reason="api_call_failed"} end
    if mode=="invalid" then
        return {status="READY",value={0/0,10,1}}
    end
    if mode=="disabled" then
        return {status="READY",value={90,30,false}}
    end
    if mode=="bad_enabled" then
        return {status="READY",value={90,30,2}}
    end
    if mode=="future" then
        return {status="READY",value={200,30,1}}
    end
    if mode=="zero" then
        return {status="READY",value={0,0,1}}
    end
    if mode=="mixed_zero_start" then
        return {status="READY",value={0,30,1}}
    end
    if mode=="mixed_zero_duration" then
        return {status="READY",value={90,0,1}}
    end
    if mode=="struct" then
        return {status="READY",value={{startTime=90,duration=30,isEnabled=true}}}
    end
    if mode=="struct_read_fault" then
        return {status="READY",value={{startTime=90,duration=30,isEnabled=true}}}
    end
    return {status="READY",value={90,30,1}}
end
local api={
    IsSafeValue=function() return true end,
    ReadValues=readValues,
    Read=function(_,name,kind)
        assert(name=="GetTime" and kind=="number")
        if mode=="clock_throw" then error("synthetic clock adapter failure") end
        if mode=="clock_fault" then
            return setmetatable({}, {__index=function() error("protected clock") end})
        end
        if mode=="clock_unknown" then return {status="UNKNOWN"} end
        return {status="READY",value=now}
    end,
    ReadField=function(_,record,key)
        if mode=="struct_read_fault" then error("synthetic protected field") end
        if record[key]==nil then return {status="UNKNOWN"} end
        return {status="READY",value=record[key]}
    end
}
local KR={GameAPI=api,EventBus={GetItemCooldownRevision=function() return 0 end}}
assert(loadfile("KordRotation/Core/GameState.lua"))("KordRotation",KR)
local S=KR.GameState
local function observe(selected)
    mode=selected
    calls={}
    return S:ReadItemCooldownObservation(5512)
end
local unknown=observe("missing")
assert(unknown.status=="UNKNOWN" and unknown.reason=="item_cd_api_missing")
assert(#calls==2)
local active=observe("active")
assert(active.status=="READY" and active.active==true)
assert(active.remaining==20 and active.startTime==90 and active.duration==30)
assert(active.enabled==true and active.revision==0)
-- Item-only READY must not launder unrelated gates into READY.
assert(active.cooldownScope=="ITEM_SPECIFIC")
for _,key in ipairs({"gcdStatus","combatUseStatus","inventoryStatus",
        "chargesStatus","usabilityStatus"}) do
    assert(active[key]=="UNKNOWN",key)
end
assert(active.source=="C_Item.GetItemCooldown" and #calls==1)
local fallback=observe("fallback")
assert(fallback.status=="READY" and fallback.remaining==20 and #calls==2)
assert(fallback.source=="GetItemCooldown")
local expired=observe("zero")
assert(expired.status=="READY" and expired.active==false and expired.remaining==0)
local structured=observe("struct")
assert(structured.status=="READY" and structured.remaining==20)
for _,selected in ipairs({"secret","broken","invalid","disabled","bad_enabled","future",
        "clock_unknown","clock_throw","clock_fault","struct_read_fault",
        "mixed_zero_start","mixed_zero_duration"}) do
    local got=observe(selected)
    assert(got.status=="UNKNOWN" and got.active==nil and got.remaining==nil,
        selected.." must remain UNKNOWN")
    assert(#calls==1,selected.." must not trigger fallback")
end
assert(observe("secret").reason=="item_cd_secret")
assert(observe("disabled").reason=="item_cd_disabled")
assert(observe("future").reason=="item_cd_remaining_unknown")
assert(observe("clock_fault").reason=="item_cd_remaining_unknown")
assert(S:ReadItemCooldownObservation("bad").status=="UNKNOWN")
assert(S:ReadSharedItemCooldownObservation("POTION_SHARED").status=="UNKNOWN")
print("item_cooldown_adapter_mock PASS")
