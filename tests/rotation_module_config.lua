-- Module-specific configuration is selected by class/spec/level and saved separately.
local KR={characterState={classToken="HUNTER",index=1,level=30},
 db={rotationProfiles={}}}
KR.RotationProfiles={Get=function(_,id,level)
 assert(id=="HUNTER_TREE_1")
 if level<=59 then
  return {id="HUNTER_BM_LEVELING_PVE",Config={
   {key="mana",type="enum",values={"fast","balanced","economy"},default="balanced"},
   {key="feign_hp",type="number",min=1,max=100,default=30},
   {key="aspect",type="bool",default=true}}}
 end
 return {id="HUNTER_BM_60_PVE",Config={
  {key="mana",type="enum",values={"fast","balanced","economy"},default="economy"}}}
end}
assert(loadfile("KordRotation/Core/RotationSettings.lua"))("KordRotation",KR)
local n=0
local function eq(a,b,label)
 n=n+1;assert(a==b,(label or "assert").." expected "..tostring(b)
  .." got "..tostring(a))
end
eq(KR.RotationSettings:GetActiveModule().id,"HUNTER_BM_LEVELING_PVE",
 "level30 module selected")
eq(KR.RotationSettings:GetModuleConfigValue("mana"),"balanced","leveling default")
eq(KR.RotationSettings:SetModuleConfigValue("mana","fast"),true,"save leveling config")
eq(KR.RotationSettings:SetModuleConfigValue("feign_hp",20),true,"save number config")
eq(KR.RotationSettings:SetModuleConfigValue("feign_hp",150),false,"reject bad numeric")
eq(KR.RotationSettings:SetModuleConfigValue("mana","invalid"),false,"reject bad enum")
eq(KR.RotationSettings:GetModuleConfigValue("mana"),"fast","leveling config persists")
eq(KR.RotationSettings:GetModuleConfigValue("feign_hp"),20,"numeric saved")
KR.characterState.level=60
eq(KR.RotationSettings:GetActiveModule().id,"HUNTER_BM_60_PVE","level60 module")
eq(KR.RotationSettings:GetModuleConfigValue("mana"),"economy","level60 independent")
eq(KR.RotationSettings:SetModuleConfigValue("mana","balanced"),true,"save level60")
KR.characterState.level=30
eq(KR.RotationSettings:GetModuleConfigValue("mana"),"fast","leveling preserved")
eq(KR.RotationSettings:GetModuleConfigValue("notDeclared"),nil,"undeclared rejected")
eq(type(KR.db.rotationProfiles.HUNTER_TREE_1.moduleConfigs),"table",
 "per-module config table stored")
print("PASS module-bound settings: "..n.." checks")
