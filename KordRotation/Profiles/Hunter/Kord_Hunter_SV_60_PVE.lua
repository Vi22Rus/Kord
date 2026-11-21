-- Kord Rotation | Hunter Survival | Level 60 | PVE | WoW Forever
-- Load order: Kord_Hunter_Common.lua, Kord_Hunter_SV_Core.lua, then this file.
-- Interface: SV.Next(state, options) -> {spellID, spell, phase, reason} | {action="PET_ATTACK",...} | nil
-- SV.Config is the CFG schema for the addon UI.
local C = KordHunterCommon
local Spells = {
  Attack=6603, AutoShot=75, RaptorStrike=2973, MongooseBite=1495, Counterattack=19306,
  StriderKick=1317257, Lacerate=24118, HuntersMark=1130, SerpentSting=1978, ArcaneShot=3044,
  AimedShot=19434, MultiShot=2643, Volley=1510, RapidFire=3045, ImmolationTrap=13795,
  ExplosiveTrap=13813, FreezingTrap=1499, FrostTrap=13809, WingClip=2974, Disengage=781,
  Deterrence=19263, FeignDeath=5384, AspectMonkey=13163, AspectBeast=13161, CallPet=883,
  RevivePet=982, MendPet=136, FeedPet=6991, DismissPet=2641,
}
local SV = { id = "HUNTER_SV_60_PVE", version = "2.0.0-design", minLevel = 60, maxLevel = 60,
  Spells = Spells, aspect = "AspectBeast", aspectFallback = "AspectMonkey", leveling = false,
  Metadata = { class = "HUNTER", spec = "SV", mode = "60", content = "PVE", standalone = false,
    engineRegistered = false, gameplayVerified = false } }
SV.ExtraConfig = C.SVConfig
C.NewProfile(SV)
for _, e in ipairs(SV.Config) do if e.key == "petMendAt" then e.default = 50 end end
SV.Defaults = C.Defaults(SV.Config)
function SV.rotate(x) return C.SVRotate(x) end
return SV
