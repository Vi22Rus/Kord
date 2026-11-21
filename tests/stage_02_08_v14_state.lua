-- Kord Rotation: canonical v14 GameAPI/GameState/EventBus mock regression.
-- Run from repository root: texlua tests/stage_02_08_v14_state.lua
local KR={}
local count=0
local function eq(a,b,label)
  count=count+1
  assert(a==b,(label or "assert")..": expected "..tostring(b)..", got "..tostring(a))
end
local time=100
local petPresent=true
local petTarget=true
local currentThreat=2
local inside=true
local instanceType="party"
local playerHealth=60
local playerPower=30
local secret="__secret__"
local apiErrors=false
GetTime=function() return time end
issecretvalue=function(v) return v==secret end
UnitExists=function(u)
  if u=="player" or u=="target" then return true end
  if u=="pet" then return petPresent end
  if u=="pettarget" then return petPresent and petTarget end
  return false
end
UnitGUID=function(u) return u.."-GUID" end
UnitIsDeadOrGhost=function() return false end
UnitHealth=function(u) return u=="player" and playerHealth or 50 end
UnitHealthMax=function() return 100 end
UnitPowerType=function() return 0 end
UnitPower=function() return playerPower end
UnitPowerMax=function() return 100 end
UnitClass=function() return "Hunter","HUNTER" end
UnitLevel=function() return 40 end
UnitAffectingCombat=function() return false end
InCombatLockdown=function() return false end
IsMounted=function() return false end
UnitCanAttack=function() return true end
UnitCanAssist=function() return false end
UnitIsPlayer=function() return false end
UnitIsUnit=function(a,b) return a=="pettarget" and b=="target" end
UnitThreatSituation=function() return currentThreat end
UnitCastingInfo=function() return nil end
UnitChannelInfo=function() return nil end
IsPlayerMoving=function() return false end
IsInGroup=function() return true end
IsInRaid=function() return false end
IsInInstance=function() return inside end
GetInstanceInfo=function() return "Test Dungeon",instanceType end
UnitHealthPercent=function() if apiErrors then error("API denied") end return playerHealth end
UnitPowerPercent=function() if apiErrors then return secret end return playerPower end
C_Spell={IsAutoRepeatSpell=function() return true end,IsCurrentSpell=function() return false end}
CreateFrame=function()
  return {RegisterEvent=function() end,
    SetScript=function(self,k,f) self[k]=f end}
end
local function module(path)
  assert(loadfile("KordRotation/"..path))("KordRotation",KR)
end
module("Core/GameAPI.lua")
module("Core/EventBus.lua")
module("Core/GameState.lua")
local api,state,bus=KR.GameAPI,KR.GameState,KR.EventBus
eq(api:Read("UnitExists","boolean","other").value,false,"false retained")
eq(api:Read("CastSpellByID","boolean",1).status,"UNAVAILABLE","cast excluded")
eq(api:ReadHealthPercent("player",nil).status,"UNKNOWN","Curve required")
eq(api:ReadHealthPercent("player",{}).value,60,"plain health percent")
eq(api:ReadPowerPercent("player",0,{}).value,30,"plain power percent")
apiErrors=true
eq(api:ReadHealthPercent("player",{}).status,"ERROR","API error")
eq(api:ReadPowerPercent("player",0,{}).reason,"protected_value","secret")
apiErrors=false
playerHealth=101
eq(api:ReadHealthPercent("player",{}).reason,"percentage_out_of_range","percent bounds")
playerHealth=60
UnitHealthPercent=function() return nil end
eq(api:ReadHealthPercent("player",{}).status,"UNKNOWN","nil percent")
eq(api:ReadHealthPercent("target",secret).status,"UNKNOWN","secret Curve")
eq(api:ReadPowerPercent("player",-1,{}).status,"UNKNOWN","bad resource")
eq(bus:Initialize(),true,"event bus")
eq(state:Initialize(),true,"game state")
local snap=state:GetSnapshot()
eq(snap.player.moving.value,false,"movement false")
eq(snap.pet.exists.value,true,"pet exists")
eq(snap.pet.attackingTarget.value,true,"pet relation")
eq(snap.context.instanceType.value,"party","instance type")
eq(snap.context.status,"READY","context status")
eq(snap.target.threat.value,2,"threat")
eq(state:ReadAutoShot(0).status,"UNKNOWN","invalid Auto Shot ID")
eq(state:ReadAutoShot(75).active.value,true,"auto repeat")
eq(state:ReadAutoShot(75).current.value,false,"auto current false")
instanceType=nil
time=time+1
snap=state:GetSnapshot()
eq(snap.context.instanceType.status,"UNKNOWN","nil instance type")
eq(snap.context.status,"UNKNOWN","partial context not READY")
instanceType="party"
currentThreat=1.5
time=time+1
snap=state:GetSnapshot()
eq(snap.target.threat.status,"UNKNOWN","fractional threat")
currentThreat=2
petTarget=false
eq(bus:HandleEvent("UNIT_PET","player"),true,"pet event")
snap=state:GetSnapshot()
eq(snap.pet.targetExists.value,false,"pet target absence")
eq(snap.pet.attackingTarget.status,"UNKNOWN","pet relation unknown")
petPresent=false
time=time+1
snap=state:GetSnapshot()
eq(snap.pet.exists.value,false,"pet absence")
eq(snap.pet.attackingTarget.status,"UNKNOWN","missing pet relation")
inside=false
time=time+1
snap=state:GetSnapshot()
eq(snap.context.instanceType.value,"none","outside instance")
print("PASS canonical v14 GameState/GameAPI mock: "..count.." assertions")
