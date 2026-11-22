-- Sonah/Classes/Hunter.lua travel-aspect combat switch regression.
-- Pure Lua mock; never calls protected gameplay actions.
local KR={}
KR.GameAPI={IsSafeValue=function() return true end}
KR.SpellCatalogue={Read=function()
 return {status="ready",entries={
  {id=13165,name="Aspect of the Hawk",known=true,rankNumber=1},
  {id=13163,name="Aspect of the Monkey",known=true,rankNumber=1}
 }}
end}
assert(loadfile("KordRotation/Core/RotationProfiles.lua"))("KordRotation",KR)
local loadHunter=assert(loadfile("KordRotation/Profiles/Hunter/BM_Leveling_Contract.lua"))
loadHunter("KordRotation",KR)
assert(KR.BMLeveling:Register())
local p=KR.RotationProfiles:Get("HUNTER_TREE_1",30)
local r=p.Rules[2]
assert(r.spell=="AspectHawk","second rule must remain combat Hawk")
local state={travel=true,combat=false,hawkMissing=nil,hasTarget=true}
local S={}
function S:spellFact() return true end
function S:ge() return true end
function S:is(field)
 if field=="target.exists" then return state.hasTarget end
 if field=="player.combat" then return state.combat end
 return nil
end
function S:observe(field)
 if field=="player.travelAspect" then return state.travel end
 return nil
end
function S:isNot(field)
 if field=="player.buff" then return state.hawkMissing end
 return nil
end
function S:any(a,b)
 local x=a()
 if x==true then return true end
 local y=b()
 if y==true then return true end
 if x==false and y==false then return false end
 return nil
end
local cfg={aspect=true}
local function eq(expected,description)
 local got=r.when(S,cfg)
 assert(got==expected,description.." expected "..tostring(expected)
    .." got "..tostring(got))
end
eq(false,"out-of-combat Cheetah should be kept")
state.combat=true
eq(true,"in-combat Cheetah should recommend Hawk even with hidden aura")
state.hawkMissing=false
eq(false,"verified existing Hawk must not be recommended")
state.hawkMissing=nil
state.travel=nil
eq(nil,"no confirmed travel and hidden Hawk must remain unknown")
state.travel=false
state.hawkMissing=true
eq(true,"clean missing Hawk should recommend casting")
cfg.aspect=false
eq(false,"user-disabled aspect never recommended")
cfg.aspect=true
state.combat=false
state.travel=false
state.hasTarget=false
state.hawkMissing=true
eq(true,"out of combat without target still recommends missing Hawk in Defensive")
state.travel=true
eq(false,"out of combat travel aspect is preserved without target")
state.combat=true
state.hawkMissing=true
eq(true,"entering combat with Cheetah recommends Hawk")
state.combat=false
state.travel=nil
eq(nil,"unknown travel aspect must not force Hawk out of combat")
state.travel=false
eq(true,"confirmed absence of travel aspect permits precombat Hawk")
print("PASS BM Sonah travel aspect combat switch")
