-- Canonical v14 input guards: make no game calls for secret/unverified args.
-- Run: lua5.1 tests/stage_02_08_v14_argument_guards.lua
local KR={}
local calls=0
GetTime=function() return 10 end
local secret=setmetatable({},{
    __lt=function() error("secret compared") end,
    __le=function() error("secret compared") end,
    __eq=function() error("secret compared") end,
})
issecretvalue=function(v) return rawequal(v,secret) end
local badCurve=setmetatable({},{
    __eq=function() error("curve compared") end
})
local function inc(value) calls=calls+1 return value end
UnitHealthPercent=function() return inc(50) end
UnitPowerPercent=function() return inc(30) end
C_Spell={IsCurrentSpell=function() return inc(false) end,
    IsAutoRepeatSpell=function() return inc(true) end}
local function load(path)
    assert(loadfile("KordRotation/"..path))("KordRotation",KR)
end
load("Core/GameAPI.lua")
load("Core/GameState.lua")
local api,state=KR.GameAPI,KR.GameState
local n=0
local function expect(read,status,reason)
    n=n+1
    assert(type(read)=="table" and read.status==status,
        "assert "..n..": "..tostring(read and read.status))
    if reason then n=n+1; assert(read.reason==reason,"reason "..n) end
end
expect(api:ReadHealthPercent(secret,{}),"UNKNOWN","curve_or_unit_unverified")
expect(api:ReadHealthPercent("player",secret),"UNKNOWN","curve_or_unit_unverified")
expect(api:ReadPowerPercent(secret,0,{}),"UNKNOWN","curve_or_power_unverified")
expect(api:ReadPowerPercent("player",secret,{}),"UNKNOWN","curve_or_power_unverified")
expect(api:ReadPowerPercent("player",0,secret),"UNKNOWN","curve_or_power_unverified")
expect(state:ReadAutoShot(secret),"UNKNOWN","auto_shot_spell_id_unverified")
expect(state:ReadAutoShot(nil),"UNKNOWN","auto_shot_spell_id_unverified")
expect(state:ReadAutoShot(0),"UNKNOWN","auto_shot_spell_id_unverified")
expect(api:ReadHealthPercent("player",nil),"UNKNOWN","curve_or_unit_unverified")
expect(api:ReadPowerPercent("player",nil,{}),"UNKNOWN","curve_or_power_unverified")
n=n+1;assert(calls==0,"invalid inputs must not call game API")
expect(api:ReadHealthPercent("player",badCurve),"READY")
expect(api:ReadPowerPercent("player",0,badCurve),"READY")
local as=state:ReadAutoShot(75)
expect(as,"READY")
n=n+1;assert(as.active.value==true and as.current.value==false)
n=n+1;assert(calls==4,"4 valid API reads only")
print("PASS v14 input guard regression: "..n.." assertions")
