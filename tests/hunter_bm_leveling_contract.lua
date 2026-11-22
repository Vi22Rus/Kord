-- Full BM leveling profile registration and module selection, Lua 5.1.
local KR={}
KR.GameAPI={IsSafeValue=function(_,v)return true end}
KR.SpellCatalogue={Read=function()
 return {status="ready",entries={
  {id=3044,name="Arcane Shot",rankNumber=1,known=true},
  {id=14283,name="Arcane Shot",rankNumber=4,known=true},
  {id=1130,name="Hunter's Mark",rankNumber=1,known=true},
  {id=75,name="Auto Shot",rankNumber=1,known=true},
 }}
end}
assert(loadfile("KordRotation/Core/RotationProfiles.lua"))("KordRotation",KR)
assert(loadfile("KordRotation/Profiles/Hunter/BM_Pilot_Experimental.lua"))
 ("KordRotation",KR)
assert(loadfile("KordRotation/Profiles/Hunter/BM_Leveling_Contract.lua"))
 ("KordRotation",KR)
local n=0
local function eq(actual,expected,comment)
 n=n+1
 assert(actual==expected,(comment or "test")..
  " expected "..tostring(expected).." got "..tostring(actual))
end
local ok,id=KR.BMLeveling:Register()
eq(ok,true,"full profile validates")
eq(id,"HUNTER_BM_LEVELING_PVE","registered id")
local p=KR.RotationProfiles:Get("HUNTER_TREE_1",30)
eq(p.id,"HUNTER_BM_LEVELING_PVE","level30 selects full BM module")
eq(p.Spells.Arcane,14283,"actual highest learned rank4 preferred")
eq(p.levelMin,1,"start level1")
eq(p.levelMax,59,"end level59")
eq(#p.Config,22,"all original BM leveling settings preserved")
eq(#KR.RotationProfiles:Get("HUNTER_TREE_1",60).Config,26,"BM60 has separate 26-option schema")
eq(#p.Rules>25,true,"full strategic priority list present")
eq(p.Rules[1].spell,"Feign","defensive opener")
eq(p.Rules[2].spell,"AspectHawk","aspect next")
eq(p.Rules[3].spell,"AspectMonkey","early aspect fallback")
eq(p.Rules[2].category,"buffs","Hawk classified as maintenance buff")
eq(p.Rules[2].recommendationType,nil,
 "Hawk requires no name-specific routing annotation")
eq(p.Rules[3].recommendationType,nil,
 "Monkey requires no name-specific routing annotation")
eq(p.Rules[6].recommendationType,"utility",
 "Mend Pet explicitly excluded from maintenance channel")
eq(p.Rules[7].recommendationType,"debuff",
 "Hunter's Mark excluded from player buff routing")
eq(p.Rules[7].spell,"Mark","prepull mark")
local has={}
for _,rule in ipairs(p.Rules) do has[rule.spell or rule.action]=true end
for _,key in ipairs({"Feign","AspectHawk","AspectMonkey",
 "Revive","CallPet","Mend","Mark","PetAttack","Disengage",
 "Freezing","Frost","Wrath","Rapid","Intimidate","Immolation",
 "Wing","Mongoose","Raptor","Auto","Concussive","Explosive",
 "Volley","Multi","Hawk","Aimed","Arcane","Sting"}) do
 eq(has[key],true,"legacy action represented: "..key)
end
eq(KR.RotationProfiles:Get("HUNTER_TREE_1",59).id,
 "HUNTER_BM_LEVELING_PVE","level59 selects leveling")
eq(KR.RotationProfiles:Get("HUNTER_TREE_1",60).id,
 "HUNTER_BM_60_PVE","level60 selects separate BM 60 module")
local duplicates=0
local seen={}
for _,id in pairs(p.Spells) do
 if seen[id] then duplicates=duplicates+1 end
 seen[id]=true
end
eq(duplicates,0,"registered spell IDs are unique")
KR.SpellCatalogue.Read=function()
 return {status="ready",entries={{id=14284,name="Arcane Shot",
  rankNumber=5,known=true}}}
end
eq(KR.BMLeveling:Register(),true,"re-register after training")
p=KR.RotationProfiles:Get("HUNTER_TREE_1",36)
eq(p.Spells.Arcane,14284,"trained rank5 adopted")
print("PASS BM full leveling registration/selection: "..n.." checks")
