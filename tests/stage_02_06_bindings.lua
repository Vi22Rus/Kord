-- Kord Rotation 2.6: isolated Lua mock tests. Run from repository root:
-- texlua tests/stage_02_06_bindings.lua
local KR={}
local time=10
GetTime=function() return time end
issecretvalue=function(v) return v=="SECRET" end
issecrettable=function(v) return type(v)=="table" and v.secret==true end
canaccessvalue=function(v) return v~="INACCESSIBLE" end
local actions={
 [1]={"spell",101},[2]={"spell",102},[5]={"spell",105},
 [6]={"spell",106},[7]={"spell",107},[8]={"spell",108},
 [13]={"spell",103},[61]={"spell",102},[109]={"spell",104},
 [9]={"macro",900},[10]={"spell",110},
}
C_ActionBar={HasAction=function(s) return actions[s]~=nil end}
HasAction=function(s) return actions[s]~=nil end
GetActionInfo=function(s) local a=actions[s];if a then return a[1],a[2] end end
local keys={
 ACTIONBUTTON1={"SHIFT-1","CTRL-F"},
 MULTIACTIONBAR1BUTTON1={"2"},
 EUI_BAR9_BUTTON1={"F1"},
 EUI_BAR10_BUTTON1={"F2"},
 ["CLICK BT4Button1:LeftButton"]={"CTRL-G"},
 ["CLICK DominosActionButton1:LeftButton"]={"ALT-BUTTON4"},
 ["CLICK ElvUI_Bar1Button1:LeftButton"]={"3"},
 ["CLICK LABButton1:LeftButton"]={"PAD1"},
}
GetBindingKey=function(command)
 local k=keys[command]
 if k then return k[1],k[2] end
end
GetBindingAction=function(key)
 for cmd,pair in pairs(keys) do
  if pair[1]==key or pair[2]==key then return cmd end
 end
 return ""
end
local function button(name,slot,visible)
 local b={action=slot,shown=visible~=false,name=name}
 function b:IsVisible() return self.shown end
 function b:GetAttribute(key) if key=="action" then return self.action end end
 function b:GetName() return self.name end
 return b
end
ActionButton1=button("ActionButton1",1)
MultiBarBottomLeftButton1=button("MultiBarBottomLeftButton1",61)
BT4Button1=button("BT4Button1",5)
function BT4Button1:GetBindingAction() return "CLICK BT4Button1:LeftButton" end
DominosActionButton1=button("DominosActionButton1",6)
function DominosActionButton1:GetBindingAction() return "CLICK DominosActionButton1:LeftButton" end
ElvUI_Bar1Button1=button("ElvUI_Bar1Button1",7)
function ElvUI_Bar1Button1:GetBindingAction() return "CLICK ElvUI_Bar1Button1:LeftButton" end
EABButton13=button("EABButton13",13)
EABButton109=button("EABButton109",109)
local lab=button("LABButton1",8)
function lab:GetAction() return "action",8 end
function lab:GetBindingAction() return "CLICK LABButton1:LeftButton" end
LibStub=function(lib) if lib=="LibActionButton-1.0" then
 return {GetAllButtons=function() return {[lab]=true} end}
end end
CreateFrame=function() return {RegisterEvent=function() end,SetScript=function() end} end
local function load(path) assert(loadfile("KordRotation/"..path))("KordRotation",KR) end
load("Core/GameAPI.lua")
load("Core/EventBus.lua")
load("Core/ActionBarScanner.lua")
load("Core/BindingResolver.lua")
local count=0
local function eq(actual,want,label)
 count=count+1
 if actual~=want then error((label or "test")..": wanted "..tostring(want)..", got "..tostring(actual),2) end
end
eq(KR.EventBus:Initialize(),true,"bus")
eq(KR.ActionBarScanner:Initialize(),true,"scanner")
eq(KR.BindingResolver:Initialize(),true,"resolver")
local function resolve(id) return KR.BindingResolver:Resolve(id) end
local one=resolve(101)
eq(one.status,"READY","Blizzard")
eq(one.bindingLabel,"S+1","key formatting")
eq(one.keys[2].label,"C+F","secondary key")
eq(one.command,"ACTIONBUTTON1","Blizzard command")
eq(resolve(102).bindingLabel,"2","multi action bar")
eq(resolve(103).command,"EUI_BAR9_BUTTON1","EAB bar9")
eq(resolve(104).command,"EUI_BAR10_BUTTON1","EAB bar10")
eq(resolve(105).source,"Bartender4","BT4")
eq(resolve(106).bindingLabel,"A+M4","Dominos modifier")
eq(resolve(107).source,"ElvUI","ElvUI")
eq(resolve(108).bindingLabel,"PAD1","LAB gamepad")
eq(resolve(900).status,"UNKNOWN","macro not a spell")
eq(resolve(0).status,"UNKNOWN","bad ID")
-- A confirmed action slot with no assigned key stays UNBOUND.
keys["EUI_BAR9_BUTTON1"]=nil
KR.EventBus:HandleEvent("UPDATE_BINDINGS")
eq(resolve(103).status,"UNBOUND","no binding keys")
keys["EUI_BAR9_BUTTON1"]={"ALT-F3"}
KR.EventBus:HandleEvent("UPDATE_BINDINGS")
eq(resolve(103).bindingLabel,"A+F3","binding update")
-- Reverse lookup refuses mismatched commands.
local prior=GetBindingAction
GetBindingAction=function(k) if k=="ALT-F3" then return "ACTIONBUTTON9" end return prior(k) end
eq(resolve(103).status,"READY","binding cache before TTL")
time=time+1
eq(resolve(103).status,"UNKNOWN","reverse mismatch after TTL")
GetBindingAction=prior
-- Paging changes a visible EAB's action but a vanilla command is not
-- proof its click override is currently routed to the new slot.
EABButton13.action=10
EABButton13.GetAttribute=function(self,key)
 if key=="action" then return self.action end
 if key=="binding" then return "EUI_BAR9_BUTTON1" end
end
KR.EventBus:HandleEvent("ACTIONBAR_PAGE_CHANGED")
eq(resolve(110).status,"UNKNOWN","dynamic override cannot be assumed")
EABButton13.action=13
KR.EventBus:HandleEvent("ACTIONBAR_PAGE_CHANGED")
-- Hide a button without invalidation: scanner must revalidate.
BT4Button1.shown=false
eq(resolve(105).status,"UNKNOWN","hidden button")
BT4Button1.shown=true
KR.EventBus:HandleEvent("ADDON_LOADED")
eq(resolve(105).status,"READY","addon rediscovery")
-- Secret key fails closed.
keys["CLICK BT4Button1:LeftButton"]={"SECRET"}
KR.EventBus:HandleEvent("UPDATE_BINDINGS")
eq(resolve(105).status,"UNKNOWN","secret key")
-- Manual settings must not impersonate real key binding.
KR.RotationSettings={GetSpell=function() return {keyLabel="FAKE"} end}
keys["CLICK BT4Button1:LeftButton"]=nil
KR.EventBus:HandleEvent("UPDATE_BINDINGS")
eq(resolve(105).status,"UNBOUND","manual label ignored")
print("PASS 2.6 binding mock tests ("..count.." assertions)")
