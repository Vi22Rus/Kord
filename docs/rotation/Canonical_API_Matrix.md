# Canonical API & GameData Matrix — Kord Rotation

**Scope:** engine + all 9 classes / 27 specializations, Leveling/60 and future PVE/PVP. **Normative naming contract (v1, 2026-11-21).** This is a specification, not a claim that every signal is implemented or works in a specific WoW Forever build.

## Source review and choice

Reviewed actual archive code: `Sonah/Core/Atoms/Spells.lua` (spellbook/rank, secret-safe wrappers); `MaxDps_Hunter/Specialization/Forever/Beastmastery.lua` (simple named-spell priority, no universal state contract); `JustAC/BlizzardAPI/StateHelpers.lua` and `SpellQuery.lua` (centralized guarded state and spell queries); `ForeverAuras/API.lua` and `ClientAPI.lua` (aura-oriented wrapper, protected-value detection); `ForeverRotation/Engine.lua` (safe numbers, cooldown/range and conservative capability checks); `RotationGuide/Core/API.lua` and `State.lua` (separate API/state and spellbook access). Comparison reference: [API_REFERENCE_MATRIX.md](../../API_REFERENCE_MATRIX.md); existing target decisions: [KORD_API_DESIGN.md](../../KORD_API_DESIGN.md).

**Decision:** retain Kord's existing `GameAPI:Read/ReadTuple/ReadValues/ReadField/Probe` and `GameState`; borrow **principles** of centralized access, spellbook rank resolution and fail-closed checks, not reference source code. **No archive proves compatibility of all methods with the current Forever build.** Test on actual client; Classic guides are not evidence.

## Mandatory call chain

`WoW Forever read-only API → GameAPI allowlist/status → GameState and specialized readers → ONE normalization adapter → canonical state → ClassCommon/optional SpecCore/Profile.Next → AbilityEligibility → BindingResolver/UI`.

**Rule:** profiles and RotationEngine must not invent their own state aliases or directly call WoW globals. `state` uses lowerCamelCase only; API names preserve Blizzard spelling; ability keys use PascalCase, **not localized spell names**. One adapter maps legacy snake_case or English spell names during migration; never add aliases to individual profiles. No new signal without registering type, provenance, nil semantics, tests and consumers here.

## 1. Canonical signal dictionary

`UNKNOWN` means the underlying fact is not established. Do not coerce it to `false`, `true`, 0, 100 or a guessed distance. **Candidate / adapter TODO** means the canonical name is approved, not that a provider already exists.

| Canonical state key | Type | Provider / WoW read API (candidate where marked) | Unknown policy | Status |
|---|---|---|---|---|
| `playerLevel` | integer ≥1 | GameState identity ← `UnitLevel("player")` | profile selection unavailable | ADAPTER TODO |
| `playerClass` | uppercase class token | GameState identity ← `UnitClass("player")` | no class selection | ADAPTER TODO |
| `inCombat` | boolean | GameState combat ← `UnitAffectingCombat("player")` | not treated as out of combat | ADAPTER TODO |
| `hasTarget` | boolean | GameState target ← `UnitExists("target")` | no hostile recommendation | ADAPTER TODO |
| `targetDead` | boolean | GameState target ← `UnitIsDeadOrGhost("target")` | no hostile recommendation | ADAPTER TODO |
| `targetAttackable` | boolean | GameState target ← `UnitCanAttack("player","target")` | no hostile recommendation | ADAPTER TODO |
| `targetAssistable` | boolean | GameState target ← `UnitCanAssist("player","target")` | no friendly-target recommendation | ADAPTER TODO |
| `playerHealthPercent` | finite number 0–100 | GameState health ← `UnitHealth/UnitHealthMax` | no HP threshold decision | ADAPTER TODO |
| `manaPercent` | finite number 0–100 | GameState resources ← `UnitPower/UnitPowerMax`, confirmed mana power type | no mana threshold decision | ADAPTER TODO |
| `moving` | boolean | **provider not established** | block stationary-only recommendation when uncertain | UNVERIFIED |
| `targetDistance` | finite number ≥0 | **exact distance provider not established**; `IsSpellInRange` is not distance | no numeric range assumption | UNVERIFIED |
| `inDungeon` | boolean | **instance provider not yet on allowlist** | no solo assumption | UNVERIFIED |
| `inRaid` | boolean | **instance provider not yet on allowlist** | no solo assumption | UNVERIFIED |
| `hasAggro` | boolean | **threat provider not established** | do not trigger aggro-based action | UNVERIFIED |
| `enemyCount` | nonnegative integer | **AoE target counter not established** | no auto-AoE | UNVERIFIED |
| `aoeSafe` | boolean | **CC-aware provider not established** | no unsafe AoE | UNVERIFIED |
| `breakableCCNearby` | boolean | **CC scan not established** | no assumption CC absent | UNVERIFIED |
| `targetTTD` | finite number ≥0 | **estimator not established** | no duration-based action | UNVERIFIED |
| `petExists` | boolean | GameState extension ← `UnitExists("pet")` | no pet-dependent action | ADAPTER TODO |
| `petHealthPercent` | finite number 0–100 | GameState extension ← `UnitHealth/UnitHealthMax("pet")` | no pet HP threshold | ADAPTER TODO |
| `petAttackingTarget` | boolean | **pet target provider not established** | no assumption pet engaged | UNVERIFIED |
| `autoShotActive` | boolean | **autoshot provider not established** | no swing inference | UNVERIFIED |
| `known` | map[PascalCase ability key]→boolean/nil | SpellCatalogue, learned rank | nil ≠ learned | ADAPTER TODO |
| `ready` | map[PascalCase ability key]→boolean/nil | Eligibility-backed aggregate **semantics must be finalized** | nil ≠ ready | CONTRACT PENDING |
| `auras` | typed record / nil | AuraReader ← `UnitAura` or `C_UnitAuras.GetAuraDataByIndex` | unknown ≠ absent | CONTRACT PENDING |
| `casting` | typed record / nil | GameState cast ← `UnitCastingInfo/UnitChannelInfo` | unknown ≠ idle | CONTRACT PENDING |

**Naming reservation:** `isPlayer`, `isMove`, `move`, `in_combat`, `mana_percent`, `has_pet`, `enemies` are **not** canonical signal keys. `player` is a WoW unit token, not a boolean state field. Do not confuse `moving` with a movement command.

## 2. GameAPI method registry (implemented allowlist, not proven client support)

**Existing Kord read-only methods:** `GameAPI:Read` (single typed value), `ReadTuple` (2–4 typed values), `ReadValues` (up to 6 raw values validated by consumer), `ReadField` (guarded structured field), `Probe` (method availability). Each read produces `status/source/reason/observedAt/value`; only `READY` permits using `value`.

| Domain | WoW API methods already allowlisted in GameAPI.lua | Intended owner | Client status |
|---|---|---|---|
| identity | `GetBuildInfo, UnitClass, UnitLevel, UnitGUID, UnitIsUnit` | GameState | NOT IN-GAME VERIFIED |
| target/combat | `UnitExists, UnitIsDeadOrGhost, UnitCanAttack, UnitCanAssist, UnitAffectingCombat, InCombatLockdown` | GameState | NOT IN-GAME VERIFIED |
| health/resource | `UnitHealth, UnitHealthMax, UnitPowerType, UnitPower, UnitPowerMax` | GameState | NOT IN-GAME VERIFIED |
| casts/auras | `UnitCastingInfo, UnitChannelInfo, UnitAura, C_UnitAuras.GetAuraDataByIndex` | GameState/AuraReader | NOT IN-GAME VERIFIED |
| spellbook/identity | `GetNumSpellTabs, GetSpellTabInfo, GetSpellBookItemInfo, GetSpellBookItemName, GetSpellBookItemTexture, GetSpellInfo, GetSpellTexture, C_SpellBook.GetSpellBookItemInfo, C_SpellBook.GetNumSpellBookSkillLines, C_SpellBook.GetSpellBookSkillLineInfo, C_SpellBook.GetSpellBookItemName, C_SpellBook.GetSpellBookItemTexture, C_Spell.GetSpellInfo` | SpellCatalogue | NOT IN-GAME VERIFIED |
| eligibility | `GetSpellCooldown, GetSpellCharges, IsUsableSpell, IsSpellInRange, C_Spell.GetSpellCooldown, C_Spell.GetSpellCharges, C_Spell.IsSpellUsable, C_Spell.IsSpellInRange` | AbilityEligibility | NOT IN-GAME VERIFIED |
| actionbar/binding | `HasAction, GetActionInfo, GetActionCooldown, GetActionBarPage, GetBonusBarOffset, GetBindingKey, GetBindingAction, GetMacroInfo, C_ActionBar.HasAction, C_ActionBar.FindSpellActionButtons` | ActionBarScanner/BindingResolver | NOT IN-GAME VERIFIED |
| environment | `GetTime, IsMounted` | shared read adapter | NOT IN-GAME VERIFIED |

**Not on current allowlist:** direct numeric distance, movement state, threat, reliable AoE count, dungeon/raid context, TTD, pet-target relation. These are **gaps**, not callable APIs. New methods require reference comparison, Forever-client verification, explicit proposal/approval, then allowlist and contract update. Protected actions/casts are excluded.

## 3. Legacy mapping (one adapter only)

| Legacy use | Canonical | Migration |
|---|---|---|
| `s.in_combat` | `state.inCombat` | ADAPTER TODO |
| `s.mana_percent` | `state.manaPercent` | ADAPTER TODO |
| `s.has_pet` | `state.petExists` | ADAPTER TODO |
| `s.pet_health_percent` | `state.petHealthPercent` | ADAPTER TODO |
| `s.in_dungeon` | `state.inDungeon` | ADAPTER TODO |
| `s.in_raid` | `state.inRaid` | ADAPTER TODO |
| `s.has_target` | `state.hasTarget` | ADAPTER TODO |
| `s.target_distance` | `state.targetDistance` | ADAPTER TODO |
| `s.enemies` | `state.enemyCount` | ADAPTER TODO |
| `s.ready["Aimed Shot"]` | `state.ready.AimedShot` | ADAPTER TODO; rank resolver required |
| `s.ready["Summon Hawk"]` | `state.ready.SummonHawk` | ADAPTER TODO; rank resolver required |

**Do not claim the adapter exists.** Do not let profiles implement these conversions. Existing Hunter Lua files are intentionally untouched.

## 4. Validation and change control

For every new/changed signal: record key, precise semantics, type/range, underlying API, source build, refresh event/TTL, consumer, nil/UNKNOWN behavior, test ID, implementation status. If no verified provider exists, reserve key but do not return invented data. For every method: record exact signature and return shape for the **current Forever client**, legacy vs `C_*` fallback, secret/protected rules, and whether `ReadTuple` can represent optional nil outputs.

**Gate before profile integration:** automated lint for undeclared state keys and direct WoW API calls in profiles; adapter unit tests; GameState→Next→Eligibility→BindingResolver integration tests; client QA separately. No game tests have been performed here.
