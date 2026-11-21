-- Stage 2.8.5 UI contract mock. Run locally: texlua tests/stage_02_08_v14_display.lua
-- Real RotationDisplay module; mock-only WoW frames/events, no client assertions.
local frames={}
local function frame()
 local f={scripts={},visible=false,cleared=0}
 local function nop() end
 setmetatable(f,{__index=function(_,key)
  if key=="CreateFontString" then return function() return frame() end end
  if key=="GetCenter" then return function() return 200,200 end end
  if key=="SetScript" then return function(self,kind,fn) self.scripts[kind]=fn end end
  if key=="Show" then return function(self) self.visible=true end end
  if key=="Hide" then return function(self) self.visible=false end end
  if key=="SetShown" then return function(self,v) self.visible=v end end
  if key=="ClearDisplayData" then return function(self) self.data=nil;self.cleared=self.cleared+1 end end
  if key=="SetDisplayData" then return function(self,d) self.data=d end end
  return nop
 end})
 return f
end
UIParent=frame()
CreateFrame=function()
 local f=frame()
 frames[#frames+1]=f
 return f
end
InCombatLockdown=function()return false end
UnitAffectingCombat=function()return false end
UnitExists=function()return true end
UnitIsDeadOrGhost=function()return false end
IsMounted=function()return false end
local opts={showPanel=true,testMode=false,slotCount=3,showInCombat=true,showOutOfCombat=true}
local callbacks={}
local active=true
local registered=true
local selected=true
local KR={db={panel=opts},UI={colors={cyan={0,1,1},sidebar={}}}}
function KR.UI:Background() end
function KR:L()return "Test" end
KR.SpellIcon={Create=function()return frame()end}
KR.IndicatorSettings={Get=function()return false end}
KR.GameAPI={IsSafeValue=function(_,value)return value~="SECRET" end}
KR.EventBus={Subscribe=function(_,channel,_,fn)callbacks[channel]=fn;return true end}
KR.RotationProfiles={Has=function()return registered end}
KR.RotationSettings={
 GetProfileID=function()return selected and "WARRIOR_TREE_1" or nil end,
 GetProfile=function()return {enabled=active},"WARRIOR_TREE_1" end
}
local engineResult
KR.RotationEngine={Evaluate=function()
 if not active or not registered or not selected then
  return {status="UNKNOWN",source="RotationEngine",queue={}}
 end
 return engineResult
end}
local function ready()
 return {status="READY",source="RotationEngine",queue={{
    spellID=101,texture=101,name="Valid spell",source="verified_profile",keybind="1"
 }}}
end
assert(loadfile("KordRotation/UI/RotationDisplay.lua"))("KordRotation",KR)
local n=0
local function eq(got,want,msg)
 n=n+1
 assert(got==want,(msg or "check")..": got "..tostring(got)..", expected "..tostring(want))
end
local D=KR.RotationDisplay
engineResult=ready()
D:Create()
eq(D.productionReady,true,"valid recommendation accepted")
eq(D.frame.visible,true,"live frame visible")
eq(D.slots[1].data.name,"Valid spell","verified name")
eq(D.slots[1].data.keybind,"1","verified key")
for i=2,5 do eq(D.slots[i].data,nil,"no predicted icon") end
engineResult={status="BLOCKED",source="RotationEngine",queue={}}
D:Refresh(true)
eq(D.frame.visible,false,"blocked panel hidden")
eq(D.slots[1].data,nil,"blocked clears current")
engineResult=ready();engineResult.queue[1].spellID=0
D:Refresh(true)
eq(D.productionReady,false,"invalid ID rejected")
engineResult=ready();engineResult.queue[1].texture="SECRET"
D:Refresh(true)
eq(D.productionReady,false,"protected texture rejected")
engineResult=ready();engineResult.queue[1].name=""
D:Refresh(true)
eq(D.productionReady,false,"empty name rejected")
engineResult=ready();engineResult.queue[1].source="unknown_source"
D:Refresh(true)
eq(D.productionReady,false,"unknown source rejected")
engineResult=ready();engineResult.queue[2]={spellID=102}
D:Refresh(true)
eq(D.productionReady,false,"unverified future queue rejected")
engineResult=ready();engineResult.source="other"
D:Refresh(true)
eq(D.productionReady,false,"wrong engine source rejected")
engineResult=ready()
D:Refresh(true)
eq(D.productionReady,true,"recovery restores icon")
eq(type(callbacks.bindings),"function","bindings subscribed")
eq(type(callbacks.cooldowns),"function","cooldown subscribed")
eq(type(callbacks.target),"function","target subscribed")
engineResult={status="UNKNOWN",source="RotationEngine",queue={}}
callbacks.bindings()
eq(D.productionReady,false,"binding invalidation clears stale icon")
eq(D.slots[1].data,nil,"binding invalidation clears slot")
engineResult=ready()
callbacks.cooldowns()
eq(D.productionReady,true,"cooldown refresh restores icon")
local onUpdate=D.visibilityFrame.scripts.OnUpdate
eq(type(onUpdate),"function","bounded polling installed")
active=false
onUpdate(D.visibilityFrame,0.41)
eq(D.productionReady,false,"disable clears icon through polling")
eq(D.frame.visible,false,"disable hides panel")
active=true
engineResult=ready()
D:Refresh(true)
registered=false
onUpdate(D.visibilityFrame,0.41)
eq(D.productionReady,false,"profile removal clears stale icon")
registered=true
D:Refresh(true)
opts.showPanel=false
onUpdate(D.visibilityFrame,0.41)
eq(D.productionReady,false,"hidden panel clears recommendation")
opts.showPanel=true
opts.testMode=true
D:Refresh(true)
eq(D.productionReady,false,"test mode is never production")
eq(D.frame.visible,true,"test mode remains independent")
print("PASS 2.8.5 display mock: "..n.." assertions")
