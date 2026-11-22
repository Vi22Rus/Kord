-- IT-02/2.8: validate explicit cooldown Needs using real profile registry.
local KR={GameAPI={IsSafeValue=function(_,x) return x~="SECRET" end}}
assert(loadfile("KordRotation/Core/RotationProfiles.lua"))("KordRotation",KR)
local P=KR.RotationProfiles
local function make(items)
 return {
  contractVersion=1,id="TEST_CD_NEEDS",version="1",
  classToken="HUNTER",specIndex=1,status="draft",
  levelMin=1,levelMax=10,
  Spells={TEST=12345},
  Needs={items=items},
  Config={},
  Rules={{id="TEST",when=function() return true end,
     reason="test",category="cooldowns",target="none",cast="allow",
     chargesRequired=false,type="SPELL",spell="TEST"}}
 }
end
local function reject(items)
 local ok,reason=P:Register("HUNTER",1,make(items))
 assert(ok==false and reason=="invalid_needs",tostring(reason))
end
reject({ids={118},cooldown="true"})
reject({ids={118},cooldownGroups={"POTION_SHARED"}})
reject({ids={118},cooldown=true,cooldownGroups={"POTION_SHARED","POTION_SHARED"}})
reject({ids={118},cooldown=true,cooldownGroups={"bad group"}})
reject({ids={118},cooldown=true,cooldownGroups={"SECRET"}})
reject({ids={118},cooldown=true,cooldownGroups={"POTION_SHARED"},other=true})
local old=P:Register("HUNTER",1,make({ids={118},families={"HEALTH_POTION"}}))
assert(old==true)
-- Registry is isolated within this mock Lua VM; existing items-only
-- profiles remain valid, and guarded new declarations are opt-in.
print("item_cooldown_needs_contract_mock PASS")
