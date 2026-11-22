-- Sonah ActionSlots / JustAC exact visible rank regression, Lua 5.1.
local KR={}
KR.GameAPI={IsSafeValue=function() return true end}
local shown=13165
KR.EventBus={callbacks={},Subscribe=function(self,ch,token,fn)
 self.callbacks[ch]=fn
 return true
end}
KR.ActionBarScanner={GetSnapshot=function()
 return {status="READY",entries={{spellID=shown,slot=23}}}
end}
KR.SpellCatalogue={Read=function()
 return {status="ready",entries={
  {id=13165,name="Aspect of the Hawk",rankNumber=1,known=true},
  {id=14318,name="Aspect of the Hawk",rankNumber=2,known=true},
  {id=13163,name="Aspect of the Monkey",rankNumber=1,known=true},
  {id=3044,name="Arcane Shot",rankNumber=1,known=true},
  {id=14283,name="Arcane Shot",rankNumber=4,known=true}
 }}
end}
assert(loadfile("KordRotation/Core/RotationProfiles.lua"))("KordRotation",KR)
assert(loadfile("KordRotation/Profiles/Hunter/BM_Leveling_Contract.lua"))
 ("KordRotation",KR)
local ok,reason=KR.BMLeveling:Register()
assert(ok,reason)
local function eq(expected,message)
 local p=KR.RotationProfiles:Get("HUNTER_TREE_1",30)
 assert(p.Spells.AspectHawk==expected,
  message.." expected "..expected.." got "..tostring(p.Spells.AspectHawk))
end
eq(13165,"use visible learned rank, not highest unbound")
assert(type(KR.EventBus.callbacks.actionbar)=="function")
shown=14318
KR.EventBus.callbacks.actionbar()
eq(14318,"bar change selects newly placed higher rank")
shown=13165
KR.EventBus.callbacks.actionbar()
eq(13165,"bar change back selects lower rank")
KR.EventBus.callbacks.actionbar()
eq(13165,"unchanged bar remains stable")
shown=999999
KR.EventBus.callbacks.actionbar()
eq(14318,"unrecognized bar action never trusted by name")
print("PASS aspect visible rank source matching")
