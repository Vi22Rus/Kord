# Canonical API Matrix — REFERENCE-FIRST research v2

**Status:** RESEARCHED / NOT IN-GAME VERIFIED. **Decision hierarchy:** source code of the six supplied Forever addon archives → independently justified method selection → actual Forever-client verification → only then redesign Kord. Existing Kord implementation is **not evidence** of correctness. Prior v1 choices based on existing Kord allowlist are **superseded**. This document is a comparative decision matrix, **not** an approved executable API implementation.

## Evidence discipline

The archives are code samples from addons intended for Forever, **not proof that every path works on the user's current Forever build**. Static inspection establishes which calls and safeguards they use, not in-game success. No Classic documentation is used. Prefer native Forever code paths when a reference distinguishes versions. Never copy third-party code; independently implement chosen principles.

## Selected architecture from references, not Kord

| Responsibility | Reference implementation inspected | Decision for future Kord redesign | Verification |
|---|---|---|---|
| Unit identity / combat | `Sonah/Core/Atoms/Units.lua:44–119,229–241` — centralized `Units`, memoized combat, `UnitAffectingCombat` and `InCombatLockdown` | **Sonah approach:** one unit-reader owner and event-scoped memoization. Keep combat and lockdown semantically distinct in our contract; Sonah's boolean OR is not proof of actual aggro | SOURCE REVIEWED; FOREVER CLIENT NOT RUN |
| Spell rank / learned abilities | `Sonah/Core/Atoms/Spells.lua:68–96,139–246` — rebuild/index/resolve by definitions and IDs; `RotationGuide/Core/State.lua:24–67` — highest-known-rank lookup | **Sonah primary + RotationGuide cross-check:** resolve canonical ability → learned spellID/rank centrally; no profile-local English names | SOURCE REVIEWED; CLIENT NOT RUN |
| Target/cast/auras | `MaxDps/Helper.lua:19–47,69–141` — `C_UnitAuras.GetAuraDataByIndex`, resource and cooldown helpers; `ForeverAuras/ClientAPI.lua:6–16` — client restriction detection | **MaxDps + ForeverAuras safeguards:** separate aura reader with explicit unknown/secret handling | SOURCE REVIEWED; CLIENT NOT RUN |
| Movement | `ForeverRotation/Engine.lua:134–138` — `IsPlayerMoving` guarded by `pcall`, but returns false when missing/failing | **Use candidate `IsPlayerMoving`**, but **reject its false-on-error fallback**; unknown must stay unknown. Requires build verification | CANDIDATE; CLIENT NOT RUN |
| Hostile target count | `JustAC/BlizzardAPI/StateHelpers.lua:82–108` — scans nameplate1..40, filters `UnitExists`, `UnitCanAttack`, `UnitThreatSituation`, caches 0.25s | **JustAC algorithm candidate**, but 0 when nameplates/API unavailable is not proof of zero enemies; preserve unknown and partial-observation distinction | CANDIDATE; CLIENT NOT RUN |
| Cooldown / usability / range | `RotationGuide/Core/State.lua:79–109,245–248`; `MaxDps/Helper.lua:36–47`; `ForeverRotation/Engine.lua:204–224` | **Multi-reference:** spellID-based cooldown, usability and range readers with typed return validation, secret checks and no invented readiness | SOURCE REVIEWED; CLIENT NOT RUN |
| Secret values / restrictions | `RotationGuide/Core/State.lua:14–21` (`Clean`), `ForeverAuras/ClientAPI.lua:6–16` (restriction detection), `MaxDps/Core.lua:86–87` | **RotationGuide + ForeverAuras:** never branch on secret, distinguish unknown from false, detect restrictions before data inspection | SOURCE REVIEWED; CLIENT NOT RUN |
| Forever-specific branch | `MaxDps/Core.lua:78–80` — `WOW_PROJECT_ID == WOW_PROJECT_CAMELOT` | **MaxDps candidate:** explicit Forever detection; verify identifier on client before using it as mandatory gate | SOURCE REVIEWED; CLIENT NOT RUN |
| General read orchestration | `JustAC/BlizzardAPI/SpellQuery.lua:69–93`, `StateHelpers.lua`; `Sonah/Core/Atoms/Units.lua` | **Sonah/JustAC:** single owner per state domain, caches with invalidation; no direct WoW API calls inside profile `Next` | DESIGN DECISION |
| Ability recommendation | `ForeverRotation/Engine.lua`; `RotationGuide/Core/API.lua:68–89` | Separate state, profile decision and UI recommendation; no automatic casts | DESIGN DECISION |

## Canonical consumer-facing names — selected independently of existing Kord

Names below are a **new proposed public contract** chosen for semantic clarity, not copied from Kord. They may happen to match old names; that is **not** an argument for keeping existing implementation.

| State signal | Canonical name | Best reference / underlying candidate | Status / caution |
|---|---|---|---|
| class / level | `playerClass` / `playerLevel` | Sonah Units.ClassToken / Units.Level | reference-backed; client untested |
| combat | `inCombat` | Sonah Units.InCombat | distinguish lockdown separately |
| target existence / hostility / death | `hasTarget`, `targetAttackable`, `targetDead` | Sonah Units.Exists / CanAttack / Dead | reference-backed; client untested |
| player health | `playerHealthPercent` | MaxDps Helper UnitHealth/UnitHealthMax | reference-backed; client untested |
| mana | `manaPercent` | ForeverRotation Engine manaPct | ensure actual mana power type |
| movement | `moving` | ForeverRotation IsPlayerMoving | reject false on missing API |
| pet existence / HP | `petExists`, `petHealthPercent` | Sonah Units + MaxDps health methods, applied to pet token | composition candidate; not demonstrated |
| target range | `inMeleeRange`, `inRangedRange` | RotationGuide State.InMelee / spell-specific range checks | **do not infer exact `targetDistance`** |
| enemy count | `enemyCount` | JustAC GetEngagedEnemyCount | observable engaged nameplates only; unknown if incomplete |
| learned / usable / ready | `known`, `usable`, `ready` keyed by canonical ability ID | Sonah Spells + RotationGuide State.Ready | readiness aggregation still to define |
| buffs / debuffs | `playerBuffs`, `targetDebuffs` | MaxDps aura scan / ForeverAuras restrictions | unknown ≠ aura absent |
| threat | `hasAggro` | JustAC UnitThreatSituation nameplate algorithm **not equivalent to player aggro** | UNRESOLVED |
| instance context | `inDungeon`, `inRaid` | no verified implementation selected from inspected examples | UNRESOLVED |
| time-to-die | `targetTTD` | no reliable source chosen | UNRESOLVED |
| CC-safe AoE | `aoeSafe`, `breakableCCNearby` | no reliable source chosen | UNRESOLVED |
| auto shot | `autoShotActive` | no reliable source chosen | UNRESOLVED |

**Do not publish a numeric `targetDistance`** without a verified distance API. Ranged/melee boolean probes are separate signals. Do not pretend `enemyCount` is a complete census of enemies.

## Excluded / deferred decisions

- **Reject** using the current Kord `GameAPI.lua` allowlist as the starting source of method selection. It is a migration target to audit and possibly replace.
- **Reject** treating any reference's `nil → false` or `nil → 0` as verified game state. Example: ForeverRotation moving() false fallback; JustAC engaged count 0 when unavailable.
- **Reject** raw English spell names and snake_case aliases in individual profiles.
- **Defer** unverified threat, instance context, TTD, CC-safe AoE and exact numeric distance.
- **Do not implement** new Lua engine code as part of this documentation review. First approve an explicit redesign plan based on this matrix.

## Required follow-up audit before implementation

1. Expand each selected method to exact call signature, return fields, secret behavior, source line, client build, update frequency and negative tests.
2. Inspect alternate implementations in all six archives for each high-impact signal; mark absent examples explicitly rather than assuming.
3. Run client tests on the current WoW Forever build for every selected method and record PASS/FAIL/NOT RUN.
4. Only then propose deleting/replacing Kord modules, with a compatibility and rollback plan.

## Superseded v1

The previous v1 document was biased toward the existing Kord allowlist. That selection rationale is withdrawn. See Git history for the previous version; do not use it as implementation authority.
