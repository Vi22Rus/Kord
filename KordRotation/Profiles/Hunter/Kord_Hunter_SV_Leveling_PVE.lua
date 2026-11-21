-- Kord Rotation | Hunter Survival | Leveling 1-59 | PVE | WoW Forever
-- Load order: Kord_Hunter_Common.lua, Kord_Hunter_SV_Core.lua, then this file.
-- Interface: SV.Next(state, options) -> {spellID, spell, phase, reason} | {action="PET_ATTACK",...} | nil
local C = KordHunterCommon
local Spells = {
  Attack=6603, AutoShot=75, RaptorStrike=2973, MongooseBite=1495, Counterattack=19306,
  StriderKick=1317257, Lacerate=24118, HuntersMark=1130, SerpentSting=1978, ArcaneShot=3044,
  AimedShot=19434, MultiShot=2643, Volley=1510, RapidFire=3045, ImmolationTrap=13795,
  ExplosiveTrap=13813, FreezingTrap=1499, FrostTrap=13809, WingClip=2974, Disengage=781,
  Deterrence=19263, FeignDeath=5384, AspectMonkey=13163, AspectBeast=13161, CallPet=883,
  RevivePet=982, MendPet=136, FeedPet=6991, DismissPet=2641,
}
local SV = { id = "HUNTER_SV_LEVELING_PVE", version = "2.0.0-design", minLevel = 1, maxLevel = 59,
  Spells = Spells, aspect = "AspectBeast", aspectFallback = "AspectMonkey", leveling = true }
SV.ExtraConfig = C.SVConfig
C.NewProfile(SV)
-- Leveling defaults differ from level 60: balanced mana style, slightly higher mend threshold.
for _, e in ipairs(SV.Config) do
  if e.key == "manaStyle" then e.default = "balanced" end
  if e.key == "petMendAt" then e.default = 55 end
end
SV.Defaults = C.Defaults(SV.Config)
function SV.rotate(x) return C.SVRotate(x) end
return SV
