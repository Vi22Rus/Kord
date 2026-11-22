# Kord runtime adoption from Rotation Master references

Last updated: 2026-11-22. Scope: runtime engine and Blizzard API interaction only. Built-in profiles remain Kord-owned; no Rotation Master UI, import/export, profile parser, editor or action execution is installed.

## Source review

Reference archive: project-supplied `RotationMaster.zip`. The following source modules were examined directly:

- `Platform/auras.lua`: independent validation of each native aura field; nil/hidden read is **not** proof of an absent aura.
- `Platform/cooldown_viewer.lua`: presence evidence from Blizzard's own viewer when aura payloads are restricted.
- `Platform/spells.lua`: cooldown never-secret flags separately from restricted timer fields, known/rank and spell data.
- `Platform/actions.lua`: no-range applicability before distance test; range reader with one fact per spell/unit per poll; spell policy independent of action button mapping.
- `Platform/gates.lua`: secret health/power is usable as UI passthrough only, **not** a Lua decision.
- `Core/condition_runtime.lua`: lazy conditions and per-provider certificates; UNKNOWN cannot be synthesized into true.
- `Core/dependency_revisions.lua`, `Core/active_runtime_plan.lua`: snapshot/revision validity and plan lifetime.
- `Platform/swing_timer.lua`: event-based measured **melee** timing; not equivalent to guessing ranged swing times.

These patterns are architectural reference behavior, not a wholesale copy of Rotation Master source.

## Production module mapping

| Responsibility | Kord implementation |
| --- | --- |
| Safe Blizzard reads | `KordRotation/Core/GameAPI.lua` |
| Player/target/pet snapshot and aura fact evidence | `Core/GameState.lua`, `Core/AuraEvidence.lua`, `Core/AuraCooldownViewer.lua` |
| Spellbook and rank | `Core/SpellCatalogue.lua` |
| Spell eligibility, cast/GCD, range and cooldown | `Core/AbilityEligibility.lua` |
| Per-evaluation fact cache and checked conditions | `Core/RotationConditions.lua` |
| Built-in profile contracts and semantic action routing | `Core/RotationProfiles.lua` |
| Two recommendation channels sharing one snapshot and condition context | `Core/RotationEngine.lua` |
| Invalidations | `Core/EventBus.lua`, `Core/GameState.lua` |
| Independent Defensive and main UI | `UI/RotationDisplay.lua` |
| Safe read-only, source-specific traces | `Core/CoreObservation.lua`, `KordRotationDevTools/Trace.lua`, `Recorder.lua` |

## Corrections implemented during this integration pass

1. Added allowed read-only `C_Spell.SpellHasRange`. Eligibility checks range applicability first. Confirmed no-range abilities are not rejected for lacking an in-range result. A protected/unknown applicability signal remains UNKNOWN.
2. Removed the hard **action-bar-presence** veto from eligibility. The rotation selects a **known and usable** action independently of a button, and the scanner only diagnoses button/keybind state; it does not determine Blizzard spell readiness.
3. `EvaluateBoth` obtains one authoritative GameState snapshot, prepares one lazy fact cache across both recommendation channels and guards this preparation with a protected-value-safe `pcall`.
4. Each recommended ability is routed by **semantic type/category** rather than a whitelist of names or SpellIDs. Buff/aura/aspect/stance/form maintenance goes to Defensive outside combat or according to the combat toggle. Enemy debuffs, utility commands and consumables are not automatically treated as maintenance.
5. DevTools exposes confirmed condition booleans as sanitized 1/0 status evidence, not just “read successful”; unknown and secret values stay UNKNOWN. Both recommendation lanes have separate final statuses and decisive refusal information. No raw spell/target/player identity is exported.
6. Lua 5.1 syntax and regression workflow now runs on push to main; mock tests and packaging checks are executed by CI. This is not an in-client validation.

## Honesty boundary

This is an integrated **Kord-native** runtime adoption of verified reference principles; it is **not** the entire original Rotation Master engine transplanted byte-for-byte, nor should it claim feature parity with its editor/condition repertoire. Forever restrictions can make player/pet health %, exact TTD, certain aura absences and resource facts unknowable in ordinary Lua. Those cannot be used to silently select or advance combat recommendations. Full compatibility requires client-side runs with the user's actual combat data and log outcomes.

All action execution remains read-only: the engine recommends; it never casts or presses a button.
