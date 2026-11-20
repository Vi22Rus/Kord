-- Kord Rotation stage 2.5. Standalone client-free mocked action bar test.
-- Run from repo root: texlua tests/stage_02_05_actionbar.lua
local KR={}
local t=100
GetTime=function() return t end
issecretvalue=function(v) return v=="SECRET" end
issecrettable=function(v) return v and type(v)=="table" and v.secret==true end
canaccessvalue=function(v) return v~="INACCESSIBLE" end
local actions={
    [1]={"spell",101}, [2]={"spell",102}, [3]={"spell",103},
    [4]={"spell",104}, [5]={"spell",105}, [6]={"spell",106},
    [7]={"item",42}, [8]={"macro",9}, [9]={"spell",109},
    [10]={"spell",110}, [11]={"spell",211}, [12]={"spell",212},
    [13]={"macro",313}, [14]={"spell",214}, [15]={"spell",215},
}
C_ActionBar={HasAction=function(slot) return actions[slot]~=nil end}
HasAction=function(slot) return actions[slot]~=nil end
GetActionInfo=function(slot)
    local action=actions[slot]
    return action and action[1],action and action[2]
end
local function button(name,slot,shown)
    local b={action=slot,shown=shown~=false,name=name}
    function b:IsVisible() return self.shown end
    function b:GetAttribute(key) if key=="action" then return self.action end end
    function b:GetName() return self.name end
    return b
end
ActionButton1=button("ActionButton1",1)
BT4Button1=button("BT4Button1",2)
DominosActionButton1=button("DominosActionButton1",3)
ElvUI_Bar1Button1=button("ElvUI_Bar1Button1",4)
EABButton1=button("EABButton1",11)
EABButton2=button("EABButton2",12,false)
EABButton3=button("EABButton3",13)
EABButton4=button("EABButton4",14)
ActionButton2=button("ActionButton2",6,false)
ActionButton3=button("ActionButton3",7)
ActionButton4=button("ActionButton4",8)
BT4Button2=button("BT4Button2",nil)
BT4Button2.type="spell";BT4Button2.spell=777
local libraryButton=button("LibraryButton",5)
local labByGetter=button("LibGetter",nil)
function labByGetter:GetAction() return "action",10 end
local labDirect=button("LibDirect",nil)
function labDirect:GetAction() return "spell",111 end
local library={GetAllButtons=function()
    return {[libraryButton]=true,[labByGetter]=true,[labDirect]=true}
end}
LibStub=function(name)
    if name=="LibActionButton-1.0" then return library end
end
local events={}
CreateFrame=function()
    return {RegisterEvent=function(_,name)events[name]=true end,
        SetScript=function() end}
end
local function module(path)
    assert(loadfile("KordRotation/"..path))("KordRotation",KR)
end
module("Core/GameAPI.lua")
module("Core/EventBus.lua")
module("Core/ActionBarScanner.lua")
local function eq(a,b,description)
    if a~=b then error((description or "mismatch")..": expected "..tostring(b)..", got "..tostring(a),2) end
end
eq(KR.EventBus:Initialize(),true)
eq(KR.ActionBarScanner:Initialize(),true)
local s=KR.ActionBarScanner:GetSnapshot()
eq(s.status,"READY","known buttons")
eq(s.coverage,"CONFIRMED_BUTTONS_ONLY")
for id=101,105 do
    eq(KR.ActionBarScanner:FindSpell(id).status,"READY","discover ref "..id)
end
eq(KR.ActionBarScanner:FindSpell(106).status,"UNKNOWN","hidden button")
eq(KR.ActionBarScanner:FindSpell(42).status,"UNKNOWN","item not spell")
eq(KR.ActionBarScanner:FindSpell(777).status,"UNKNOWN","direct spell not action slot")
eq(KR.ActionBarScanner:FindSpell(9).status,"UNKNOWN","macro not spell")
eq(KR.ActionBarScanner:FindSpell(103).source,"Dominos","source assigned")
eq(KR.ActionBarScanner:FindSpell(110).status,"READY","LAB GetAction action slot")
eq(KR.ActionBarScanner:FindSpell(111).status,"UNKNOWN","LAB direct spell excluded")
-- EllesmereUI native EABButton: only a visible, verified Blizzard action slot.
eq(KR.ActionBarScanner:FindSpell(211).status,"READY","Ellesmere EABButton accepted")
eq(KR.ActionBarScanner:FindSpell(211).source,"EllesmereUI","Ellesmere source preserved")
eq(KR.ActionBarScanner:FindSpell(212).status,"UNKNOWN","hidden EAB button")
eq(KR.ActionBarScanner:FindSpell(313).status,"UNKNOWN","EAB macro excluded")
eq(KR.ActionBarScanner:FindSpell(214).slot,14,"EAB slot verified")
-- EAB updates the secure action attribute on page/form changes.
EABButton4.action=15
eq(KR.ActionBarScanner:FindSpell(214).status,"UNKNOWN","EAB stale mapping rejected")
KR.EventBus:HandleEvent("ACTIONBAR_PAGE_CHANGED")
eq(KR.ActionBarScanner:FindSpell(215).status,"READY","EAB paging maps new slot")
EABButton4.action="SECRET"
KR.ActionBarScanner:Invalidate("eab_secret")
eq(KR.ActionBarScanner:FindSpell(215).status,"UNKNOWN","protected EAB attribute")
EABButton4.action=15
EABButton4.shown=false
KR.ActionBarScanner:Invalidate("eab_hidden")
eq(KR.ActionBarScanner:FindSpell(215).status,"UNKNOWN","EAB hidden after rescan")
EABButton4.shown=true
KR.EventBus:HandleEvent("ADDON_LOADED","EllesmereUIActionBars")
eq(KR.ActionBarScanner:FindSpell(215).status,"READY","EAB post-load refresh")
s.entries[1].spellID=9999
eq(KR.ActionBarScanner:FindSpell(101).status,"READY","cache isolated")
-- Modifier paging rewrites action attribute without an event. Reject stale record.
DominosActionButton1.action=9
eq(KR.ActionBarScanner:FindSpell(103).status,"UNKNOWN","stale paging rejected")
KR.EventBus:HandleEvent("ACTIONBAR_PAGE_CHANGED")
eq(KR.ActionBarScanner:FindSpell(109).status,"READY","new page mapping")
-- Disappearing custom button invalidates its previously observed slot.
BT4Button1.shown=false
eq(KR.ActionBarScanner:FindSpell(102).status,"UNKNOWN","hidden after cache")
-- Secret/inaccessible attributes cannot produce a confirmed mapping.
BT4Button1.shown=true; BT4Button1.action="SECRET"
KR.ActionBarScanner:Invalidate("secret")
eq(KR.ActionBarScanner:FindSpell(102).status,"UNKNOWN","secret attribute")
BT4Button1.action=2
BT4Button1.GetAttribute=function() return "SECRET" end
KR.ActionBarScanner:Invalidate("protected_attribute")
eq(KR.ActionBarScanner:FindSpell(102).status,"UNKNOWN","protected attribute never falls back to raw action")
BT4Button1.GetAttribute=function(self,key)
    if key=="action" then return self.action end
end
C_ActionBar.HasAction=nil
KR.ActionBarScanner:Invalidate("legacy")
eq(KR.ActionBarScanner:FindSpell(102).status,"READY","legacy HasAction fallback")
GetActionInfo=function(slot)
    if slot==2 then return "SECRET",102 end
    local action=actions[slot]
    return action and action[1],action and action[2]
end
KR.ActionBarScanner:Invalidate("protected")
eq(KR.ActionBarScanner:FindSpell(102).status,"UNKNOWN","secret GetActionInfo")
print("PASS stage 2.5 mocked action bar scenarios")
