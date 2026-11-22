-- Standalone Lua 5.1 mock: one global toggle, two independent recommendation windows.
-- No WoW client, protected action or third-party source code.
local KR={
 characterState={classToken="HUNTER",index=1,level=30},
 db={rotationProfiles={}},
}
KR.GameAPI={IsSafeValue=function(_,v) return v~="SECRET" end}
KR.SpellCatalogue={Read=function()
 return {status="ready",entries={
  {id=13165,known=true,name="Aspect of the Hawk",texture=13165},
  {id=3044,known=true,name="Arcane Shot",texture=3044},
 }}
end}
KR.BindingResolver={Resolve=function(_,id)
 return {status="READY",spellID=id,bindingLabel="1",bindingSource="test"}
end}
local combat=false
local auraKnown=false
KR.GameState={GetSnapshot=function()
 return {player={level={status="READY",value=30},
   combat={status="READY",value=combat}},
   target={}}
end}
local profile={
 id="TEST_HUNTER_BM",status="verified",Spells={Hawk=13165,Arcane=3044},
 Config={},
 Rules={
  {id="hawk",type="SPELL",spell="Hawk",category="buffs",
   recommendationType="aura",target="none",cast="idle",
   chargesRequired=false,when=function()return not auraKnown end},
  {id="arcane",type="SPELL",spell="Arcane",category="damage",
   target="enemy",cast="idle",chargesRequired=false,
   when=function()return true end}
 }
}
KR.RotationProfiles={
 Has=function()return true end,
 ResolveForEngine=function()return profile end,
}
KR.RotationConditions={
 Create=function()return {} end,
 Check=function()return {status="READY",reason="none",checks={}} end,
}
KR.db.rotationProfiles.HUNTER_TREE_1={
 enabled=true,targetMode="single",allowUnverifiedProfiles=false,
 categories={buffs=true,damage=true},spells={}
}
assert(loadfile("KordRotation/Core/RotationSettings.lua"))("KordRotation",KR)
assert(loadfile("KordRotation/Core/RotationEngine.lua"))("KordRotation",KR)
local S,E=KR.RotationSettings,KR.RotationEngine
local function spell(result)
 assert(result.status=="READY",result.reason or "not ready")
 assert(#result.queue==1,"exactly one current recommendation")
 return result.queue[1].spellID
end
local function eq(a,b,label)
 assert(a==b,(label or "check").." expected "..tostring(b)
  .." got "..tostring(a))
end
eq(S:GetFlag("buffsInCombatMain"),true,"global default on")
eq(spell(E:Evaluate()),3044,"out of combat main skips aura")
eq(spell(E:EvaluateDefensive()),13165,"out of combat defensive offers aura")
combat=true
eq(spell(E:Evaluate()),13165,"in combat default prioritizes offensive aura")
eq(E:EvaluateDefensive().status,"BLOCKED","same aura never duplicated")
eq(S:SetFlag("buffsInCombatMain",false),true,"disable global promotion")
eq(spell(E:Evaluate()),3044,"in combat disabled does not block DPS")
eq(spell(E:EvaluateDefensive()),13165,"in combat disabled stays defensive")
auraKnown=true
eq(spell(E:Evaluate()),3044,"active aura does not replace DPS")
eq(E:EvaluateDefensive().status,"BLOCKED","active aura absent from defensive")
auraKnown=false
combat=false
eq(spell(E:Evaluate()),3044,"off remains unaffected outside combat")
eq(spell(E:EvaluateDefensive()),13165,"off retains defensive outside combat")
KR.characterState={classToken="PALADIN",index=2,level=30}
eq(S:GetFlag("buffsInCombatMain"),false,"one toggle across specs/classes")
eq(S:SetFlag("buffsInCombatMain",true),true,"enable global promotion")
eq(S:GetFlag("buffsInCombatMain"),true,"global save persists")
eq(KR.db.buffsInCombatMain,true,"saved to root account db")
print("PASS global combat aura routing and dual engine channels")
