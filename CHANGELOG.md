## 2026-11-22 — Correct Defensive ability recommendation routing

- Corrected the Advanced checkbox: `defensiveInCombatMain` now controls **defensive abilities** (category `defensive`), NOT buffs/auras.
- Checked: during confirmed combat, eligible Defensive spells appear in the **main recommendation frame**. Unchecked: they appear only in the separate **Defensive** frame. Outside combat: separate Defensive frame.
- Defensive ability routing has independent six-language text/tooltips and Lua regression tests. The old `buffsInCombatMain` option remains a distinct legacy aura preference and must not be confused with this checkbox.
- Separate window enable/disable only gates the separate Defensive view; it does not block an otherwise eligible defensive spell being routed to the main frame.
- Checked/unchecked routing validated with Lua mock CI; no claim of in-game verification.

## 2026-11-22 — Runtime API/eligibility integration driven by Rotation Master reference

- Reviewed reference runtime modules for auras, spell cooldowns, range applicability, secret-value gates, condition evaluation, revisions and plan lifetimes. Architecture mapping and remaining limitations: `docs/engine/RotationMaster_Runtime_Adoption.md`.
- `GameAPI` now supports the read-only `C_Spell.SpellHasRange`; `AbilityEligibility` checks range applicability before numeric in-range status. A verified no-range spell is eligible without a range probe; unavailable/secret facts remain UNKNOWN.
- Learned and usable spells no longer require an exact matching **visible action-bar button** to be recommended. The scanner remains responsible for keybind and rank mismatch diagnostics but cannot veto spell eligibility. No protected action execution added.
- `RotationEngine:EvaluateBoth` shares one snapshot **and one cached condition context** for the two recommendation lanes, with protected-value-safe preparation.
- `CoreObservation` and DevTools now report independent Defensive decisive conditions and confirmed boolean condition outcomes rather than only an ambiguous “READY = fact was readable.”
- The shared semantic router excludes non-spell commands even when their category is buffs.
- GitHub Actions Lua 5.1 regression workflow now automatically runs on relevant pushes; all checked-in Lua files are syntax checked and all existing v14 mock tests and ZIP packaging parity tests run. **Green run:** https://github.com/Vi22Rus/Kord/actions/runs/44996000545 (code commit `002e9166`). Live WoW Forever behavior still requires client verification.
- This adopts and extends Kord's runtime based on observed reference patterns; **not** a claim that all Rotation Master modules or all profile conditions have been transplanted.

## 2026-11-22 — Production routing by the rotation's recommended action type

- Removed all spell-name/ID-dependent routing from the **runtime engine**. A single `RotationProfiles:RecommendationKind(rule,effectiveCategory)` method classifies each actual profile rule's action generically as `buff`, `aura`, `aspect`, `stance`, `form`, `potion`, `consumable`, `debuff`, `utility`, or `spell`.
- Existing `buffs` category recommendations for non-enemy targets are automatically recognized as maintenance effects without individually annotating every rule; a rule's explicit semantic type can override this inference. Consumables, hostile debuffs and utility actions are not silently treated as aura upkeep.
- `RotationEngine` uses this shared classification and existing live recommendation eligibility to route any valid maintenance recommendation to Defensive outside combat, or according to the global toggle in combat. The active profile continues to choose what to recommend; the router never makes that choice based on a spell name.
- Corrected routing to use the **effective category after per-spell category preferences**, so classification and category enablement cannot disagree.
- Updated the existing regression mock to exercise the same production classifier rather than adding a separate fake rotation. **In-game outcome is still awaiting verification.**

## 2026-11-22 — Universal category-driven routing for recommended buffs/aspects/auras/stances

- Removed the explicit Hunter-name whitelist from the BM profile. **The display/engine never recognizes specific names or SpellIDs** as eligibility for the Defensive lane.
- Any valid profile rule in category `buffs` with a non-enemy target is now classified as a maintenance `buff` unless its rule explicitly supplies a different `recommendationType`.
- Supported semantic recommendations are `buff`, `aura`, `aspect`, and `stance`; each is routed **to Defensive outside combat**, to **main during confirmed combat** if the global `buffsInCombatMain` preference is enabled, and to **Defensive during combat** if disabled. The profile's normal `when` condition is still authoritative: active Cheetah outside combat must not trigger Hawk.
- Explicit `utility` and `debuff` roles prevent classification errors. For the current Hunter profile, Pet Mend/Call/Revive are utility and Hunter's Mark is an enemy debuff rather than a player maintenance buff.
- Existing per-profile role/category/priority and `AbilityEligibility` retain their responsibilities. Profiles must still define which abilities are appropriate; no generic Blizzard API safely proves that every arbitrary spell should be kept active.
- Added mock coverage using an otherwise unknown Paladin Retribution Aura spell name and ID, including all four semantic roles and both preference states. It is **not** a playable Paladin rotation.
- Tests and client behavior require separate execution/verification; GitHub file updates alone are not evidence of successful WoW gameplay.

## 2026-11-22 — Independent Defensive window and Hunter travel-aspect routing fix

- `RotationDisplay`: Defensive is now an independent `UIParent` sibling frame, anchored below the main panel but no longer hidden together with it. It ignores main-only `requireTarget`, `showInCombat`, `showOutOfCombat`, and `showPanel` visibility gates. Defensive own `defensiveEnabled` and `defensiveCombatOnly` settings control its visibility; normal death/mount preferences remain relevant.
- Hunter BM: Aspect of the Hawk is **not** recommended outside combat while Cheetah/Pack is confirmed active. On entering combat, if Hawk is missing or not directly readable and travel aspect is confirmed, it becomes a valid combat recommendation. The global `buffsInCombatMain` flag controls whether it appears in main (ON) or Defensive (OFF). An unverified travel-aspect state cannot cause a precombat Hawk recommendation.
- Main and Defensive continue to use `RotationEngine:EvaluateBoth()` with one game-state snapshot. Disabling the main panel clears its displayed recommendation without suppressing separately enabled Defensive.
- Added pull-only, spell-ID-free Defensive state to `CoreObservation:ReadDisplay()` and explicit v14 DevTools DISPLAY flags: `defensive_enabled`, `defensive_combat_only`, `aura_promotion`, `defensive_engine_status`, `defensive_recommendation`, `defensive_frame_created`, `defensive_frame_shown`, `defensive_visibility_allowed`.
- Extended Hunter Cheetah regression and UI mock to cover precombat suppression, combat Hawk, unknown travel state, absence of target, main hidden outside combat, and independent Defensive visibility.
- **Verification:** Changes are present in GitHub; manual Lua 5.1 / WoW game validation is still required. No external addon code was copied.

## 2026-11-22 — Fix Indicators tab crash on numeric controls

- Fixed malformed `UI:StepRow` arguments in `UI/Pages/IndicatorsProfiles.lua`, where the minimum was passed as the `formatter` and `maximum` remained nil. This triggered `Missing numeric bounds for IND_HIGHLIGHT_STRENGTH` on opening Indicators.
- Added exact min/max mapping for all seven Indicators sliders, matching `Core/IndicatorSettings.lua`, including `interruptSpellID` (0..9999999).
- Added `tests/indicator_slider_bounds.lua` and included in the manual Lua 5.1 CI regression list.
- WoW live and GitHub Actions execution are still pending. No changes to rotation/auras were needed.

## 2026-11-22 — Global combat aura routing and working Defensive aura lane

- Added a **single account-wide checkbox** under **Advanced → General preferences**: `buffsInCombatMain` (default ON, SavedVariables at `KordRotationDB.buffsInCombatMain`). Changing it immediately refreshes the main and Defensive recommendation windows without a reload.
- Extended the authored Kord Rotation profile contract with optional `recommendationType="aura"`. This is semantic metadata, not copied Rotation Master code and not a blanket redirect of the `buffs` category.
- Marked Hunter BM Aspect of the Hawk, Aspect of the Monkey and Trueshot Aura (BM60) as offensive aura maintenance. Other pet, cooldown and defensive abilities remain under their existing rules.
- Engine now independently evaluates two channels. **Out of combat** all designated auras go to Defensive; **in combat** they go to main if ON, otherwise Defensive. Non-aura damage rules remain eligible in main when OFF, no auratic double-display. Unsafe or unverified results remain UNKNOWN; all selection still goes through existing AbilityEligibility.
- Converted the first Defensive preview slot to a **real verified aura recommendation** (the other slots do not invent a future queue). The global indicator preference now defaults to enabled and `defensiveCombatOnly` defaults false so out-of-combat aura maintenance is visible on new installs; previously saved per-user choices are respected.
- Aspect maintenance no longer requires a hostile target before combat. Cheetah/Pack protection outside combat remains intact.
- Added translated labels/tooltips in all six languages and replaced obsolete placeholder claims for Defensive aura slots.
- Added `tests/combat_aura_routing.lua` and strengthened UI/aspect mocks; listed new regression in manual Lua 5.1 CI.
- **Limitations:** This activates only specifically tagged aura recommendations, not all defensive or interrupt skills. Paladin gains this routing via future Paladin profile metadata; no Paladin rotation is currently registered. Real WoW Forever UI and live aura behavior still require user testing. CI is manual-only and was not executed in this change.

## 2026-11-22 — Adapt Rotation Master aura presence in Kord without replacing engine

- Inspected Rotation Master `Platform/auras.lua`, `Core/aura_conditions.lua` and `Platform/cooldown_viewer.lua` (Preston A. Elder / PreZ). Source-derived strategy: targeted aura lookups first; Cooldown Manager tracked-item presence when raw aura details become secret; remember clean reads, never walk secret aura lists.
- Added read-only `Core/AuraCooldownViewer.lua` to Kord's canonical load order. Uses Blizzard `BuffIconCooldownViewer` / `BuffBarCooldownViewer`, confirms spell IDs via `C_CooldownViewer.GetCooldownViewerCooldownInfo`, extracts ONLY the secret/absent bit of `auraInstanceID`, hooks OnShow/OnHide, and invalidates/refreshes on relevant events outside lockdown.
- `GameState` uses confirmed viewer presence for `player.buff` / `target.debuff` before returning hidden-aura UNKNOWN. Remembers explicit out-of-combat absence and may reuse it when hidden. Unlike RM's heuristic of assuming initial no-history absence, Kord v14 keeps unobserved hidden auras UNKNOWN.
- Added two regression suites, updated manual Lua 5.1 workflow, six-language About attribution and copied upstream license with author credits to `THIRD_PARTY_NOTICES.md`.
- **Not yet Lua 5.1 tested or in-game verified.** Blizzard Cooldown Manager must actually track the aura; no information is invented for untracked items.

## 2026-11-22 — Fix in-game BM Hawk action-slot rank mismatch

- Latest user test after travel-aspect fix reaches BM rule #2 in combat, then fails `action_slot_unconfirmed` with `bm_bar_2 visible_spell_rank_mismatch` (t9912). Unlike prior `condition_unknown`, this is a precise rank/slot issue.
- Inspected Sonah `Core/Atoms/Spells.lua:41–66,137–159` (rank/name learned spell resolution), `Core/Atoms/ActionSlots.lua:15–33,62–75` (exact spell IDs from `GetActionInfo` / `FindSpellActionButtons`), and JustAC `ActionBarScanner.lua:431–486` (strict action IDs plus verified transformations). No localized-name-only acceptance.
- `BM_Leveling_Contract.resolveSpells` now prefers a **learned, exact-ID-confirmed visible button** for Aspect of the Hawk and Monkey when it differs from highest learned rank; otherwise keeps the existing learned selection. `BMLeveling:Register` subscribes to actionbar revision changes and re-resolves only when visible spell IDs change, avoiding repeated registration on state-only events.
- Added `tests/hunter_bm_aspect_bar_rank.lua` testing lower rank on bar, replacement with higher rank, restoration of lower rank, unknown bar ID fail-closed and stable repeats. Included in manual Lua 5.1 regression workflow.
- **Code committed; mock tests and client confirmation NOT RUN.** A READY recommendation still requires the actual registered spell ID, verified button/key, usability and remaining eligibility.

## 2026-11-22 — Correct Aspect of the Hawk condition using Sonah Hunter reference

- User's latest two-page test confirmed a readable `player.travelAspect` signal while BM rule #2 was `BLOCKED/condition_false`, then hidden aura reads left the rule UNKNOWN in combat. Existing `if travel==true then return false` was wrong for combat.
- Matched `Sonah/Classes/Hunter.lua:142–171`: out of combat preserve Cheetah/Pack; in combat recommend switching to Hawk while a travel aspect is still confirmed, including via previously observed and not-yet-consumed travel evidence. A confirmed already active Hawk still blocks redundant recommendation.
- `AuraEvidence` now recognizes higher-rank Hawk and other combat aspects as successful cast consumers, remembers **verified live positive** travel for up to 120s, never creates negative aura evidence and never refreshes its own stale live observation. Reset upon world entry/death.
- Added `tests/hunter_bm_aspect_switch.lua` (combat/offcombat/known active Hawk/unknown/disabled option) and extended GameState mock; added new test to manual Lua 5.1 workflow. **Tests not executed here; no live WoW client pass.**

## 2026-11-22 — Actual core aura provider improvements sourced from Sonah/ForeverAuras

- `GameState:ReadSignal` now tries ForeverAuras' targeted `C_UnitAuras.GetUnitAuraBySpellID(unit,spellID)` after a failed player-specialized lookup; exact ID and helpful flag must be readably verified. This adds a possible real successful data path when the specialized method returns nil.
- Added Sonah's bounded `GetAuraDataBySpellName(unit,localizedName,filter)` lookup; retrieves a localized name from `C_Spell.GetSpellInfo` or legacy `GetSpellInfo`, validates exact SpellID and aura kind. A nil by-name return proves absence only when `C_Secrets.ShouldAurasBeSecret` explicitly returns false. In secret mode a missing aura remains UNKNOWN.
- Added `KordRotation/Core/AuraEvidence.lua`, Sonah-derived own `UNIT_SPELLCAST_SUCCEEDED` tracker for four hunter aspects; a recent observed cast supplies bounded *positive* evidence while aura fields are hidden. Another aspect cast, world entering and death invalidate the record. **No gameplay cast/automation action is invoked**.
- TOC loads the new shared core file into both variants. Added standalone Lua mock scenarios for confirmed own casts, aspect switch/reset, generic ID fallback, by-name present/absent. **Lua mocks and Forever client not executed on this commit.**
- Limit: a previously unobserved aura in permanent secret mode remains UNKNOWN. Neither these reference implementations nor the live test demonstrate a reliable initial-negative lookup under that restriction. Never claim this is a guaranteed Aspect of the Hawk fix without the actual in-game recommendation test.

## 2026-11-22 — Reference-first implementation work begins (v14 101-row ledger)

- Added `docs/rotation/V14_Reference_Implementation_Audit.md`: 101 individual v14 rows, selected API chains, lookup pointers into the six uploaded reference addons, and **SOURCE_CANDIDATE vs SOURCE_REVIEWED** flags. Indexing all 101 rows is **not** the same as having verified every reference implementation; incomplete rows remain explicitly marked.
- Re-opened the uploaded source ZIPs. Confirmed Sonah `Core/Atoms/Secret.lua:235–260`, JustAC `BlizzardAPI/SecretValues.lua:239–286`, and ForeverAuras `BuffTrigger2.lua:290–323,2060–2090` agree: direct aura lookup nil may be hidden; indexed aura enumeration is denied under secret restrictions and must not be used to fabricate absence.
- Implemented in `GameState:ReadSignal`: read-only `C_Secrets.ShouldAurasBeSecret` gate after direct SpellID lookup; secret mode returns `UNKNOWN/aura_hidden_by_client` and skips both unavailable list fallbacks. When the dedicated predicate is absent/unreadable, follow Sonah restriction fallback: if in lockdown or lockdown cannot be verified, return `UNKNOWN/aura_secrecy_unverified` without enumeration. Both reasons preserved by DevTools recorder.
- Added regression cases for secret aura mode and absent secrecy predicate during combat; **tests have not been executed because a Lua 5.1 runtime is not available in this environment, and Forever client verification has not been run.** This deliberately removes illegal repeated API calls but does NOT prove the Aspect of the Hawk recommendation can be issued in secret aura mode.
- Reviewed Sonah `Units.lua` and JustAC `StateHelpers.lua` percent/curve threshold patterns. No arbitrary replacement of secret `UnitHealth/UnitPower` with imagined exact values has been made.

## KR-20261122 — DevTools full-journal multi-page export after 32 KiB truncation

- User's latest actual Forever trace has `truncated=1`, `dropped=0`, `evicted_parts=0`: the first 32 KiB text page ends amid method probes, so the combat/target-change portion cannot be analyzed from the submitted text. First observed actual GameAPI failures: `UnitHealth` and `UnitPower` `UNKNOWN/protected_value`. Profile has 35 BM rules, 29 confirmed visible spell buttons; scanner now gives distinct `button_action_not_spell`, `button_action_unconfirmed`, `button_spell_id_unconfirmed`, `button_not_visible` reasons.
- Replaced fixed first-32 KiB `Recorder:Export()` truncation with `Export(page)`, complete chronological records on bounded pages, `page=N/M` header/footer, no gap or duplicate within retained SavedVariables segments. Existing Export UI button cycles pages on successive clicks and wraps back to page 1. The `truncated=1` footer is retained for backward compatibility and now means **more than one page**, not that later pages are unavailable. `dropped` and `evicted_parts` continue to signal independent data loss.
- Added pagination regression in `tests/devtools_recorder.lua` (90 records, every sequence exactly once across multiple pages; bounded page size). **MOCK/CLIENT NOT RUN on latest commit.** This change affects only DevTools export, not game API semantics or BM eligibility.

## KR-20261122 — Runtime API trace static coverage reconciliation

- Static connector-backed cross-check of `V14Registry.lua` vs `GameAPI.lua`: **101 matrix rows**, **79 rows naming a direct method**, **29 distinct named methods**, **0 mapped methods absent from the GameAPI allowlist**. The remaining **22** are composite rows without a single safe method-probe. This validates source mapping only, not live execution in WoW Forever.
- Reviewed the 23 `KordRotation/Core/*.lua` source modules for direct use of core game API methods outside the adapter; none were detected by the targeted scan. Fixed the protected-field-key order in generic instrumentation (secrecy checked before string inspection).
- Runtime logger is **opt-in**, data-free apart from allowlisted API method/key metadata, status and bounded code/count. **LOCAL LUA NOT RUN, CI NOT RUN, FOREVER CLIENT NOT RETESTED** on this commit.

## KR-20261122 — Generic opt-in runtime GameAPI trace (v14, all real adapter calls)

- **SOURCE IMPLEMENTED; MOCK/LUA/FOREVER CLIENT NOT RUN on current commit.** Runtime opt-in tracing is now centralized in `KordRotation/Core/GameAPI.lua` for every actual `Read`, `ReadTuple`, `ReadValues`, `ReadField`, `Probe`, `ReadHealthPercent`, and `ReadPowerPercent` invocation. New adapter methods and refusal codes are captured by a generic bounded validated schema, not an updated per-spell or per-error logger. The scanner additionally emits fixed checkpoints for button inspection and `FindSpell` validation (including failed rank/slot checks). Presence-only probes use `GameAPI.Probe.<method>` and are never merged with successful API reads. Field reads use `GameAPI.ReadField.<safeKey>`, without returning field values.
- `CoreObservation` bridge exposes opt-in `BeginAPITrace`, `APITrace`, `EndAPITrace`, and immutable allowlisted method metadata. The production addon maintains **no persistent journal**; only the separate DevTools recorder activates and drains the in-memory scalar counters during a user-initiated session. No spell IDs, GUIDs, unit values, key bindings, names or protected returns are exported.
- `KordRotationDevTools/Trace.lua` records the first observed (method,status,reason) transition and one final aggregate count per tuple; duplicates are not written every 2 seconds. `Recorder.lua` safely retains `METHOD` method/count columns in both SavedVariables and text export, including automatically validated future lowercase internal API reasons without changing hard-coded reason lists. Missing capture, overflow, unknown codes, export truncation and same-session retention eviction are flagged explicitly.
- Existing 101-row v14 **presence-only** census still emits once per recording; dynamic `METHOD` records are separately tagged and do **not** claim 101 runtime scenario passes. Per-rule `RULE/SIGNAL/STAGE/BAR` BM audit, target, UI and events remain available. **This does not implement unknown TTD/aoe/hawk estimators or fix Hawk `action_slot_unconfirmed`.**
- Added or extended mock regression cases in `tests/stage_02_03_game_state.lua`, `tests/devtools_trace.lua`, `tests/devtools_recorder.lua`. **Local Lua test execution NOT RUN; GitHub Actions NOT RUN; latest game retest NOT RUN.**

## KR-20261122 — Diagnostic contract gap sentinels (no silent reason loss)

- `Recorder.lua` no longer collapses unknown fixed internal reason codes silently to `unknown`, or strips unknown detail codes to an empty eighth column. Invalid/untrusted reason → `diagnostic_code_invalid`; syntactically valid unregistered reason → `diagnostic_code_unmapped`; unknown/protected/invalid detail → `diagnostic_detail_unmapped`. Original rejected values are never exported.
- Updated `tests/devtools_recorder.lua` assertions for safe sentinels, retained scanner rank mismatch and aura diagnostics, and matrix row preservation. **MOCK/CLIENT NOT RUN** on newest commit.

## KR-20261122 — Exhaustive v14 presence census and lossless fixed-reason DevTools trace

- At explicit DevTools Start, `ProbeAll` now writes **101 separately indexed API journal records** (`kind=API`, `reason=matrix_probe`, `matrix=1..101`, detail `presence_only`/`api_missing`/`no_single_safe_probe` or fixed refusal). All rows are covered once per recording. This checks **API presence, not execution, capability support, secret usability, or 101 client passes**. Unmapped composite rows remain UNKNOWN; no speculative protected game calls.
- Fixed the established journal defect that discarded `spell_not_confirmed_on_visible_bar` and `visible_spell_rank_mismatch` from `bm_bar_N` details. Added new aura/travel refusal codes to bounded scalar allowlists. Recording persists numeric matrix row, status, and detail without target, name, GUID, keys, or spell ID.
- Added mock assertions to `tests/devtools_probe.lua` (all 101 rows, no false READY for composite row 23) and `tests/devtools_recorder.lua` (whitelisted scanner/aura reasons and matrix ID persistence). **SOURCE CHANGED; TESTS NOT RUN; CLIENT NOT RETESTED.**
- The current journal still cannot prove runtime behavior for all 101 composite matrix capabilities: it contains a 101-row source-level presence census plus event-driven engine/audit stage observations. Future dynamic per-method invocation coverage must preserve the read-only security boundary and must not be labeled implemented.

## KR-20261122 — WoW Forever BM live diagnostics, UI stabilization and aura reading (documentation reconciliation)

- **SOURCE CHANGED; LUA MOCK / WoW FOREVER RETEST NOT RUN on the latest SHA.** Startup event registration in `Init.lua` is protected with `pcall`; unsupported `LEARNED_SPELL_IN_TAB` no longer aborts UI bootstrap. Event availability depends on the client; this is not proof of all startup pathways.
- Fixed `PET_COMMAND` profile registration metadata (Lua `and nil or` defect), and level >=10 `aspect_monkey` UNKNOWN bug. User's DevTools trace shows `bm_profile_bm_leveling READY` (35 rules) after the former correction.
- `RotationDisplay` keeps configured frame/slot shells visible independently of READY. Preview question marks are not live recommendations. Engine still produces **one** verified current action only; future queue and independently populated defensive/interrupt slots are NOT IMPLEMENTED.
- `GameState` now populates target classification from `UnitClassification`, and derives `player.travelAspect` conservatively from confirmed Cheetah/Pack auras. A later user trace showed READY classification and travel-aspect reads with a target; target-dependent reads can remain UNKNOWN without a target.
- `ActionBarScanner` reports potential different-rank/localized-name mismatch without treating name equality as verified slot/SpellID. The user explicitly reports Aspect of the Hawk on a visible Ctrl+3 button, yet `bm_rule_2` still returns `action_slot_unconfirmed` in the latest trace; **NOT FIXED**, reason must be investigated.
- `GameAPI` allowlists read-only `C_UnitAuras.GetUnitAuras`; `GameState:ReadSignal` tries exact SpellID lookup, checked batch aura enumeration and bounded per-index fallback, rejecting protected/invalid/sparse arrays rather than converting UNKNOWN to false. The newest aura change has **NOT** been retested in-game. The client may provide incomplete observations even for structurally valid results; full negative-enumeration semantics remain CLIENT UNVERIFIED.
- Latest user trace: registered BM profile, visible frames and 29 scanned action buttons; no accepted live recommendation. Other blocking reads include `aura_scan_unverified`, `pet.health.percent`, and unsupported TTD/heuristic signals. Do not claim end-to-end BM readiness. GitHub Actions intentionally NOT RUN.

## KR-20261122 — Full Hunter BM rotation contract integration and per-module UI

- **SOURCE INTEGRATED, MOCK/CLIENT QA PENDING.** Портирована вся структура приоритетов из `KordRotation/Profiles/Hunter/Kord_Hunter_BM_Leveling_PVE.lua` v2.3 в новый исполняемый модуль `Profiles/Hunter/BM_Leveling_Contract.lua` (Contract v1): Feign Death, Monkey/Hawk, Call/Revive/Mend Pet, Hunter's Mark, PET_ATTACK, ближний бой/контроль, ranged Auto Shot, Concussive, кулдауны, AoE, Summon Hawk, Aimed, Arcane, Sting, филлеры. Все правила существуют сразу, но применимость проверяется строго через `RotationConditions` и `AbilityEligibility`; неизвестные факты не считаются доступностью.
- Автоматический выбор: Hunter BM TREE_1 + читаемый уровень 1–59 → `HUNTER_BM_LEVELING_PVE`, уровень 60 → отдельный `HUNTER_BM_60_PVE`; прежний Arcane-only pilot ограничен 61+. Повторная регистрация при входе, получении уровня и изменении книги заклинаний; максимальный известный Arcane rank выбирается по `SpellCatalogue`, не по одному уровню. BM60 имеет экспериментальный адаптер исходной стратегии v1.2 с особой маной/кулдаунами/ловушками/Trueshot/prepull; полную паритетность BM60 исходнику **не заявлять**.
- Вся конфигурация `BM.defaults` v2.3 (22 опции) переведена в `Profile.Config`. Вкладка «Ротация» сама создаёт bool/enum/numeric controls в соответствии с выбранным профилем, 26 у BM60, хранит настройки отдельно по `moduleConfigs[profile.id]`. Строки/подсказки переведены на шесть языков. Стандартные глобальные переключатели ротации не затронуты.
- Типизированные источники: `UnitClassification` для elite, `ReadAutoShot(75)` для activity (не swing), безопасный факт melee range через Raptor Strike, цель цели и агро, поиск отсутствующих AuraData через ограниченную и проверенную последовательность `GetAuraDataByIndex`. Отсутствующие/неподтверждённые WoW Forever сигналы (hawk_count, AoE safety, TTD, swing, profit heuristics, travel aspect, etc.) остаются `UNKNOWN`, а `PET_COMMAND` пока `unsupported_action`.
- **Полная диагностика одним запуском.** Новый `RotationEngine:AuditFull()` вызывается только при явной записи DevTools, независимо обходит весь выбранный профиль и сохраняет ограниченные сигнатуры: `RULE bm_rule_N` status/reason, `SIGNAL bm_signal_N_<field>` status/reason (в том числе ауры/питомец/target/TTD), `STAGE bm_stage_N_...` по 6 этапам Eligibility, `BAR bm_bar_N` revalidation reason. При этом обычный боевой движок остаётся ленивым, raw SpellID/GUID/имена/фреймы не записываются, события записываются в SavedVariables по сегментам. `UNKNOWN`/непроверенная способность не превращается в автоматический каст или рекомендацию.
- Дополнительный статический аудит: выбор рангов не привязан к английскому языку клиента — имена базовых заклинаний получаются через `GameAPI`; конфиг с выключенной способностью отсекает её до дорогостоящих фактов; полная диагностика содержит per-rule bar revalidation `bm_bar_N`. Старые поля `arcane_rank_4_rule/arcane_check_*` записываются только для прежнего пилота, не для нового профиля с другой нумерацией.
- Добавлены mock-тесты `tests/hunter_bm_leveling_contract.lua`, `tests/rotation_module_config.lua`, `tests/bm_full_audit.lua`; обновлены `tests/devtools_trace_signals.lua`, `tests/stage_02_03_game_state.lua`, `tests/hunter_bm_rank_selection.lua` и ручной Lua5.1 workflow. **Эти тесты ещё не запускались; WoW Forever с новым полным профилем не проверялся.**
- Сверены и актуализированы `README.md`, `docs/rotation/BM_Leveling_Integration_Status.md`. **`docs/rotation/Profile_Contract.md` намеренно не изменён**. Два физически отдельных аддона используют канонический `KordRotation` без ветвления боевых условий ради DevTools.

## KR-20261122 — SavedVariables journal and BM leveling v2.3 migration boundaries
- По запросу пользователя: не нужно копировать DevTools trace через Ctrl+C. `Recorder.lua` теперь автоматически сохраняет ограниченные сегменты журнала в `KordRotationDevToolsDB.sessions` при переполнении буфера и на Stop. `Core.lua` завершает активную запись на `PLAYER_LOGOUT`. WoW сохраняет SavedVariables в `WTF/Account/<ACCOUNT>/SavedVariables/KordRotationDevTools.lua` при нормальном выходе или `/reload`; прямой записи произвольного файла addon API не предоставляет.
- 512 строк на часть, до 12 последних частей; один лог может состоять из нескольких частей `sessionID/part/final` без потери строк на границе 256. Кнопка Export по-прежнему работает с текущей сессией через сохранённые части, но текст ограничен 32768 байт. При превышении лимита хранения старые части вытесняются, поэтому архив не бесконечен.
- Обновлены mock-тесты сохранения, ротации частей, экспорта после Stop, уникальных session ID и PLAYER_LOGOUT. **Запуск Lua и игровой клиент ещё не подтверждены**.
- Изучен исходный полноценный `Kord_Hunter_BM_Leveling_PVE.lua` v2.3. Он использует старый `BM.Next(s,cfg)` и многие отсутствующие в Contract v1 факты (TTD, hawk timers, enemy/AoE safety, swing, aura absence, pet command). Его нельзя просто добавить в TOC и считать полноценно работающим. Зафиксирована точная матрица переноса `docs/rotation/BM_Leveling_Integration_Status.md`. **Live-ротация пока остаётся на подтверждённом Hunter BM Arcane Shot пилоте**; полный порт v2.3 остаётся незавершённым и не заявляется готовым.

## KR-20261122 — WoW Forever GCD reference: 29515 вместо retail 61304
- **Основание — загруженные референсные архивы.** В `ForeverAuras/Prototypes.lua` Global Cooldown trigger читает `C_Spell.GetSpellCooldown(29515)` и `C_Spell.GetSpellCooldownDuration(29515)`; `ForeverAuras/GenericTrigger.lua` прямо указывает, что `61304` на Forever не ведёт полноценный GCD clock, тогда как `29515` запускает его. `JustAC/BlizzardAPI/SpellQuery.lua`, `Sonah/Core/Atoms/Spells.lua` и `MaxDps/Helper.lua` используют retail `61304`, `ForeverRotation/Engine.lua` оценивает доступность через API cooldown конкретной способности; это не прямое доказательство корректности `61304` именно в Forever.
- **Сравнение с KordRotation:** раньше `AbilityEligibility.gcd()` запрашивал modern `C_Spell.GetSpellCooldown(61304)` (isActive), а при отсутствии современной функции — legacy `GetSpellCooldown(61304)`. Это соответствует жалобе клиента: остальные пять check-этапов у Arcane Shot rank 4 READY, но GCD возвращает `UNKNOWN/gcd_unavailable`.
- **Адаптация:** единый канонический движок `KordRotation/Core/AbilityEligibility.lua` теперь использует Classic GCD reference **29515**; современный источник принимает только явно доступное обычное `isActive=true/false`, не анализирует потенциально секретные `startTime/duration` или `isOnGCD`. Если modern API отсутствует или вернул обычное недоступное значение, legacy `GetSpellCooldown(29515)` используется только с валидированными конечными `start/duration/enabled` и временем. При modern protected-value чтении и при неоднозначном ответе (только одна часть таймера) результат остаётся UNKNOWN. Состояние GCD по `61304` больше не считается достоверным. Никаких fail-open предположений по последнему касту.
- В `tests/stage_02_07_eligibility.lua` обновлён mock Forever 29515 и добавлены проверки active/idle, несовпадения dummy 61304, legacy fallback, аномальных и protected значений; исправлена изоляция собственного кулдауна способности при legacy GCD fixture.
- Контракт профилей и независимость `KordRotationDevTools` сохранены. **Mock-Lua тесты/игровая проверка не запускались**: контейнер не может разрешить github.com для скачивания актуальных файлов, игровой клиент недоступен. Вывод об источнике GCD основан на референсе, а не на выдуманном клиентском PASS.

## KR-20261122 — Stage-level diagnostics for Arcane Shot rank 4 (canonical core + DevTools)
- По ревью текущего исходного кода: фиксированный список причин `Recorder.lua` уже был расширен в предыдущей итерации; подтверждены ещё два дефекта. `ActionBarScanner:FindSpell` раньше инвалидировал весь кэш при одном устаревшем дубликате кнопки, даже если другой подтверждал способность. `AbilityEligibility` сохранял только первый UNKNOWN без подробной картины шести этапов.
- `ActionBarScanner.lua`: при отказе отдаёт фиксированный код этапа `button_not_visible`, `button_slot_unconfirmed`, `button_action_unconfirmed`, `button_action_info_unconfirmed`, `button_action_not_spell`, `button_spell_id_unconfirmed`, `button_mapping_changed` или `button_revalidation_unknown`. При хотя бы одной успешно перепроверенной кнопке не вызывает `Invalidate` из-за другого дубликата; при отсутствии подтверждённых кнопок сохраняет fail-closed UNKNOWN и инвалидацию.
- `AbilityEligibility.lua`: сохраняет core-only поле `barReason` вместе с совместимым `action_slot_unconfirmed`; для пройденных проверок собирает bounded `checks` по `cast/usability/charges/cooldown/gcd/range`. При достоверном BLOCKED по-прежнему останавливается сразу, не вызывая остальные проверки (каноническая ленивая оценка). Для UNKNOWN собираются все оставшиеся этапы, но первый UNKNOWN остаётся итоговой причиной и READY не синтезируется.
- `RotationConditions` и `RotationEngine` передают эти core-only диагностические записи в результат оценки. `CoreObservation.Diagnose` пропускает в отдельно установленный DevTools только проверенные имена этапов и статусы/причины пятого правила Hunter rank 4, без слотов, Spell ID, имён персонажей и фреймов.
- `Trace` и `Recorder` пишут `CHECK arcane_rank_4_bar_failure`, `CHECK arcane_check_cast`, `..._usability`, `..._charges`, `..._cooldown`, `..._gcd`, `..._range` в существующий export, только при изменении. Allowlist расширен исключительно фиксированными кодами; дополнительного текста в пользовательском UI нет.
- Подробный журнал отмечает этапы, не выполнявшиеся из-за раннего BLOCKED, как `UNAVAILABLE / not_evaluated`; это исключает путаницу со старым UNKNOWN от предыдущего снимка.
- Добавлены регрессионные сценарии для дублированных кнопок, нескольких UNKNOWN, ленивого BLOCKED, сканерных подпричин, sanitized bridge и журнала. `Profile_Contract.md` не изменялся. Проверено наличие исходников в GitHub; запуск Lua тестов из контейнера заблокирован невозможностью DNS-доступа к github.com, игровой клиент также недоступен. **Тесты не утверждаются как выполненные**.

## KR-20261122 — DevTools терял причины `UNKNOWN` для Arcane Shot rank 4
- Реальный trace после исправления downrank: на выбранной цели `engine_decisive_priority=5`, `ENGINE UNKNOWN/unknown`, `arcane_rank_4_rule UNKNOWN` с пустым detail; actionbar 29 кнопок, Arcane Shot rank 4 подтверждён, тестовый режим выключен, `dropped=0`.
- Причина потери детализации в DevTools, а не подтверждённая причина блокировки: `Recorder.lua` фильтровал причины, выданные собственным `AbilityEligibility` и `RotationEngine`. В allowlist отсутствовали `cast_unknown`, `usability_invalid`, `gcd_activity_unknown`, `range_unavailable`, `cooldown_active_unclassified`, `spell_known_unverified` и другие известные коды. `sanitizeReason` менял их на `unknown`, а `safeDetail` отбрасывал значение полностью.
- Исправлен **строгий статический allowlist** ровно известных кодов из двух модулей. Сырые значения, произвольные строки, пользовательские имена и SpellID по-прежнему не записываются. Добавлены тесты экспорта известных причин и отказа произвольным данным.
- Не меняли критерии `AbilityEligibility READY`, не обходили UNKNOWN/секретность и не выдавали иконку без подтверждения. Следующий лог должен показать точную причину отказа приоритета 5, после чего можно править непосредственно источник.
- Проверено наличие изменений в GitHub; **Lua/mock-тесты и WoW client не запускались**.

## KR-20261122 — Исправлен выбор ранга Arcane Shot Hunter BM
- По реальным журналам: Arcane Shot rank 4 подтверждён на панели (`FindSpell READY`), но после `BLOCKED` на правиле rank 4 движок продолжал к rank 3/2/1, мог получить `UNKNOWN action_slot_unconfirmed` для более низкого ранга, который игрок не размещал на панели. Это искажало причину отсутствия рекомендации.
- Экспериментальный профиль Hunter BM v0.1.2 теперь **не рассматривает низшие ранги**, когда изучен любой более высокий: кулдаун/каст/range у максимального изученного ранга приводит к нормальному `BLOCKED`, а не к попыткам downrank. Если факт изученности более высокого ранга неопределён, остаётся `UNKNOWN` (fail-closed); нет автоматических кастов.
- В DevTools `CoreObservation.Diagnose` добавлен только безопасный номер последнего проверенного приоритета и его причина. `Recorder` / `Trace` сохраняют `CHECK engine_decisive_priority` и `CHECK engine_decisive_reason` в автоматическом журнале, без разрастания интерфейса.
- Добавлены `tests/hunter_bm_rank_selection.lua` и дополнения к mock-тестам наблюдения/трассировки. **Lua и WoW-клиент не запускались**; код и тесты зафиксированы в репозитории. `docs/rotation/Profile_Contract.md` не менялся.

## KR-20261121-223 — DevTools: диагностика переносится в журнал записи, а не разрастается в окне
- По запросу пользователя: ручной `/krdev why` уже стал слишком длинным, при каждом новом отказе нельзя требовать отдельные строки. Подробная диагностика при включённой вручную записи теперь сохраняется автоматически в обычном экспортируемом журнале.
- `Trace.lua`: при `Start`, на целевых событиях и ограниченно раз в 2 секунды опрашивает только безопасный `CoreObservation` bridge. Сохраняет изменение `Priority 1`, `Priority 5 / Arcane Shot rank 4`, статусов и причин `FindSpell`, общего сканирования панели, числа подтверждённых кнопок и ранга; live/cached target; агрегатов eligibility даже `0/0/0`; профиль UI; все конечные флаги `Display` (включена ли панель, testMode, принятие рекомендации, видимость, существование фрейма, last UI engine status/reason). При остановке — финальная ограниченная выборка.
- `Recorder.lua`: добавлены только-allowlist виды `CHECK/BAR/DISPLAY` и необязательный восьмой столбец `detail` (безопасная ограниченная причина/целое число). Scalar-only копирование в SavedVariables и экспорт. Только изменения значений, ограничение записей 256, экспорта 32768 байт и сессии 900 секунд; нет записи raw UI frames, GUID, имён или Spell ID. Защита от повторного Stop при лимите времени.
- Новый журнал не требует включать текстовую ручную диагностику `/krdev why`; в игровом DevTools остаются прежние кнопки Start / Stop / Export.
- Добавлены mock-тесты переноса всех категорий, дедупликации и sanitization. **Lua 5.1 / WoW client tests NOT RUN**; работа во время реального боя требует проверки в клиенте. Основной `KordRotation` в этой итерации не изменён.

## KR-20261121-210 — Hunter 30: диагностика реального rank-4 rule и UI режима
- Клиент сообщил: `Engine (manual evaluation): BLOCKED/no_eligible_rule`, `Priority 1: BLOCKED/condition_false`, `Engine (last UI evaluation): UNKNOWN/unknown`, `Target UnitExists: false` при визуально выбранной живой цели, `Action bar scan: READY`, `Profile manual READY`, сводка eligibility `0/0/0`.
- Исправлено misleading имя «Priority 1»: у профиля восемь правил от Arcane Shot rank 8 (уровень 60) к rank 1; для персонажа уровня 30 **ранг 4 — пятое правило**. `CoreObservation.Diagnose` теперь отдельными только-статус/причина значениями передаёт `arcaneR4Status/arcaneR4Reason` для пятого правила Hunter BM. Без Spell IDs и сырого списка.
- `CoreObservation.Display` добавляет два safe-only флага `panelEnabled/testMode`; `/krdev why` показывает состояние пользовательской панели, тестового режима и последнего engine результата раздельно. `RotationDisplay:Refresh` в тестовом режиме не вычисляет боевую рекомендацию; при `showPanel=false` пропускает engine — оба случая способны объяснить `UI UNKNOWN/unknown`.
- Никаких debug-сообщений или обхода Eligibility в пользовательском UI; только необязательный ручной DevTools. Mock-тесты расширены. **Lua 5.1/WoW Forever client NOT RUN**. Визуально выбранная цель и `UnitExists=false` пока расходятся — сохранять как незакрытый игровой факт, не делать вывод о причине без атомарной проверки.

## KR-20261121-205 — DevTools: end-to-end engine → display → frame
- Клиент подтвердил `Arcane Shot FindSpell: READY / confirmed`, но иконка на фрейме не появляется. Это подтверждает только проверку action-slot, **не** финальный `AbilityEligibility READY` и не приём рекомендации UI.
- Ревизия `CoreObservation.Display()` выдаёт только безопасные scalar-only результаты: существует ли фрейм, принял ли `RotationDisplay` рекомендацию (`productionReady`), разрешён ли `ShouldShow()`, реально ли `frame:IsShown()`, последний UI статус и причину движка. Не меняет UI и не вставляет тестовую иконку.
- `/krdev why` показывает эти данные отдельно от прямой оценки движка и `FindSpell`. Добавлены mock-тесты финального UI-пути, включая невидимый фрейм и отказ в приёме рекомендации.
- Поведение production-ротации не ослаблялось; пользовательский аддон не получает новых сообщений. **Lua 5.1/WoW runtime NOT RUN**.

## KR-20261121-199 — Hunter: snapshot-панель подтверждает Arcane Shot 4, но движок блокирует слот
- В реальном WoW Forever пользователь получил `Action bar scan: READY`, `Confirmed spell buttons: 29`, `Hunter Arcane Shot rank on bar: 4`, `Profile: READY`, одновременно с `ENGINE UNKNOWN action_slot_unconfirmed` при бое.
- Это исключает полное отсутствие распознавания панели, языковое несовпадение и отсутствие распознанного ID четвёртого ранга в момент ручного snapshot. **Не доказывает**, почему точная проверка `FindSpell` временно возвращает UNKNOWN.
- `CoreObservation.ActionBar()` теперь при явном запуске DevTools вызывает `ActionBarScanner:FindSpell` для подтверждённого ранга и отдаёт только безопасные `arcaneFindStatus/arcaneFindReason` без SpellID, slot, GUID или raw button.
- `/krdev why` дополнен `Arcane Shot FindSpell: ...`. Добавлены mock-тесты случая «snapshot содержит Arcane Shot rank 4, но повторная live revalidation возвращает UNKNOWN».
- **Lua 5.1 tests / WoW client NOT RUN**. Никаких новых сообщений в основном аддоне и никакого ослабления fail-closed validation.

## KR-20261121-194 — Hunter BM: scanner action-slot diagnosis from live DevTools trace
- Реальный лог: `PROFILE READY`, `TARGET READY target_present`, `ENGINE UNKNOWN action_slot_unconfirmed`, отдельные `BLOCKED condition_false` у рангов выше уровня, `dropped=0`. Поэтому исправление фокуса — распознавание кнопки на action bar, а не чтение цели/событий.
- `GameAPI:ReadField`: при отсутствии секретности допускает `userdata` UI-объекты наряду с Lua-таблицами; доступ к полю по-прежнему строго через `pcall` и `issecretvalue`/`issecrettable`/`canaccessvalue`. Это позволяет `ActionBarScanner` видеть методы WoW-кнопок, представленных `userdata`; защищённые кнопки по-прежнему блокируются.
- В DevTools-only `CoreObservation.ActionBar()` доступна **явная** проверка сканера и подтверждённых заклинаний: число проверенных кнопок, высший наблюдавшийся ранг Arcane Shot из профиля Hunter BM; **никаких сырьевых Spell IDs, slot, GUID, имен и ссылок на UI-объекты**.
- `/krdev why` показывает `Action bar scan`, `Confirmed spell buttons`, `Hunter Arcane Shot rank on bar`; разница между полностью пустым сканом и отсутствием нужного ранга теперь видна напрямую.
- Mock-тесты дополнены сценарием Lua 5.1 `newproxy` userdata UI-объекта, защищённого userdata, ручного scanner bridge и текстового отчёта. **Lua 5.1 runtime NOT RUN; WoW client result NOT CONFIRMED.** Причиной пользователя может быть и макрос/нестандартные кнопки: это ещё не доказано.
- Работающие ранее изменения в `RotationEngine` и двухаддонная архитектура сохранены; новые разработческие сообщения в основном аддоне не добавлены.

## KR-20261121-187 — полезный DevTools-лог при реальном бое
- По экспортированному игровому журналу Hunter: `TARGET BLOCKED target_absent → TARGET READY target_present`, подтверждены `player_target_changed`, успешные/неудачные собственные касты и cooldown events. `ENGINE UNKNOWN unknown` и `PROFILE UNKNOWN` не позволяли установить причину отсутствующей рекомендации; `dropped=20` означал реальные отброшенные записи, в том числе из-за общего 50-мс ограничения.
- `CoreObservation.Diagnose()` — **только через явное обращение DevTools**; реальный `RotationEngine:Evaluate()` и первая причина по приоритету возвращаются как ограниченные, безопасные статусы/коды без Spell IDs, GUID и сырых таблиц. Сам основной интерфейс и `/kr` не добавляют сообщений.
- Включённая вручную запись DevTools теперь получает прямой диагностический статус, код причины и первый отказ независимо от `lastEngineReason` пользовательского окна. `/krdev why` показывает отдельно прямую и UI-кэшированную оценки, а также статус профиля.
- `Recorder`: снят общий запрет на две записи в пределах 50 мс — он терял смены цели, касты и отказы. Схлопываются только повторные `spell_update_cooldown` в пределах 200 мс, без роста `dropped`; сохранены ограничения `maxRecords` и `maxDuration`.
- Добавлены mock-сценарии проверки прямой причины отказа, первого правила и нескольких важных записей в одно время. **Lua 5.1 / WoW Forever client QA not run**; фактическое исчезновение `ENGINE UNKNOWN unknown` требует игровой проверки.

## KR-20261121-174 — DevTools экспорт событий и причин теперь информативен
- По клиентскому отчёту: экспорт из сессии с выбором цели и боем показывал только `EVENT READY manual_sample`, `ENGINE UNKNOWN manual_sample`, `PROFILE UNKNOWN manual_sample`. Это недостаточная диагностика.
- `KordRotationDevTools/Trace.lua`: события записываются с точными **разрешёнными** именами причин (`player_target_changed`, `spell_update_cooldown`, `update_bindings`, `actionbar_slot_changed` и др.). Добавлены события начала, успешного и неудачного завершения **только собственных** кастов игрока; имена, GUID и ID заклинаний в лог не попадают.
- Переход `ENGINE` теперь включает `engineReason` от CoreObservation (например `action_slot_unconfirmed`), вместо неинформативного `manual_sample`. Изменение причины при том же статусе создаёт новую запись.
- Новый тип `TARGET` отражает `target_present`, `target_absent`, `target_unverified` по безопасному pull-only мосту `CoreObservation.Target`. Не сохраняются сырые игровые объекты.
- `Recorder.lua` расширен **строгими whitelist-значениями**; ограничения размера/времени и ручное включение сохранены. Добавлены mock-тесты. Основной `KordRotation` и его пользовательский интерфейс **не изменялись**.
- **LUA 5.1 / GAME CLIENT NOT RUN**; реальные события WoW Forever требуют проверки пользовательской установкой.

## KR-20261121-169 — Hunter BM: причина UNKNOWN/action_slot_unconfirmed
- По скриншоту реального клиента: `Target before evaluate: live=true`, `Target evaluated: exists=true`, `Rotation: UNKNOWN / action_slot_unconfirmed`. Чтение цели подтверждено; следующий отказ — на этапе проверки точного ID способности на видимой панели.
- Обнаружена ошибка в экспериментальном пилоте: `Spells.ArcaneShot=3044` означает только **ранг 1**, хотя у Arcane Shot на WoW Forever восемь разных Spell ID. Уровень 30 допускает ранг 4, ID **14283** (источник: 60.tools/spellbook/hunter, Forever build 1.60.1.70888).
- Пилот обновлён: восемь правил в порядке убывания ранга, сначала ограничение по уровню, затем `S:spellFact(id,"known")` (только факт реально изученного ранга), затем проверка цели. `false` допускает переход к следующему рангу, `nil/UNKNOWN` останавливает, не угадывая готовность. Финальный READY продолжает выдавать только AbilityEligibility.
- Добавлены mock-assertions уровня 30 и ранга 4. Никакой автокаст не добавлен, полная BM-ротация не подключалась.
- **Не подтверждено, что пользовательская кнопка распознана ActionBarScanner**: UI-аддон/макрос/неподтверждённый GetActionInfo также могут привести к `action_slot_unconfirmed`. Код ещё не проверен в клиенте; Lua 5.1 NOT RUN.

## KR-20261121-165 — диагностика перенесена в KordRotationDevTools
- Удалён `/kr why` и связанный многострочный вывод из пользовательского `KordRotation/Init.lua`. Основной аддон не должен писать разработческие сведения в чат.
- `/krdev why` в отдельно устанавливаемом `KordRotationDevTools` открывает ручной отчёт: последний статус/причина движка, живое `UnitExists("target")`, cached `target.exists` и агрегированные счётчики. Информация отображается в окне DevTools, не в основном аддоне.
- Добавлен read-only `KordRotationCoreObservation.Target()` с исключительно безопасными булевыми значениями; не раскрывает GUID, здоровье, имена или сырые таблицы, не вызывает полную оценку движка.
- Добавлены mock-проверки границы наблюдения и отчёта. **Lua 5.1 / WoW client NOT RUN**.
- Исправление свежего снимка в `GameState:GetSnapshot(true)` и `RotationEngine` оставлено: это функциональность движка, а не логирование.

## KR-20261121-158 — исправление считывания выбранной цели по реальному игровому сравнению
- По пользовательскому воспроизведению: `/kr why` сообщил `BLOCKED/no_eligible_rule`, `Priority 1: condition_false` при выбранной враждебной цели. Проверка пилота `S:is("target.exists")` читала `GameState` snapshot, в то время как отдельный работающий `KordRotationEngine` в `Core/State.lua` получает `safeCall(UnitExists,"target")==true` заново при каждом `BuildState()`.
- `GameState:GetSnapshot(force)`: при `force==true` явно делает `ReadNow()` и не использует краткосрочный кэш (обычные потребители сохраняют прежний кэш).
- `RotationEngine` теперь запрашивает `GetSnapshot(true)` для каждого живого вычисления; не опирается на пропущенный event `PLAYER_TARGET_CHANGED`. Само наличие цели по-прежнему подтверждается `GameAPI:Read("UnitExists","boolean","target")`, защищённое или nil остаётся UNKNOWN.
- `/kr why` отображает `Target before evaluate: live=..., cached=...` и `Target evaluated: exists=...`, чтобы выявить расхождение непосредственно в WoW Forever.
- `tests/stage_02_03_game_state.lua` дополнен mock-сценарием смены цели без события и без истечения TTL. Источники обновлены, **Lua 5.1 tests NOT RUN / CLIENT RECHECK PENDING**.
- Это устранение подтверждённого архитектурного различия, но не доказательство, что именно кэш вызвал пользовательский false. Если `Target evaluated` остаётся false при live true, продолжить диагностику адаптера.

## KR-20261121-151 — диагностика отсутствующей иконки Hunter BM
- По реальному игровому отчёту: Hunter BM 30, Arcane Shot изучен и находится на панели, настройки single/experimental включены, **рекомендация не появляется**. Пользовательский сценарий воспроизведён только по описанию, не в клиенте разработчика.
- Добавлена команда `/kr why`: по ручному запросу пересчитывает `RotationEngine:Evaluate()`, печатает в чат точный `status/reason` и причину первой приоритетной записи, а при `READY` дополнительно проверяет состояние отображения и `showPanel/testMode`. Проверки `GameAPI.IsSafeValue` не допускают вывод защищённых произвольных данных в чат.
- Возможный блокер — привязка экспериментального пилота к одному Spell ID 3044 при наличии другого изученного ранга на панели. **Не подтверждено**; не заменять нужный ранг догадкой до получения результата `/kr why`.
- **Локальная клиентская проверка не выполнена.** Lua 5.1, 17 suites и WoW Forever по-прежнему NOT RUN.

## KR-20261121-148 — hotfix: ошибка `Missing numeric bounds for LAYOUT_COUNT`
- Исправлены **все три** вызова `UI:StepRow` в `KordRotation/UI/MainWindow.lua`: добавлен пропущенный аргумент `formatter=nil`, чтобы границы `minimum` и `maximum` попадали в правильные позиции. Ошибка возникала при открытии страницы настроек отображения (`Components.lua:61`).
- Источник ошибки — несовпадение сигнатуры `StepRow(parent,labelKey,x,y,width,getter,setter,step,formatter,minimum,maximum)` с вызовами из `MainWindow.lua`. Проверка всех 3 вызовов выполнена по актуальному файлу в GitHub.
- **Исправление в исходниках; клиентский повторный запуск пока не проверен.** Не требует DevTools и не добавляет новых настроек.

## KR-20261121-146 — минимальный устанавливаемый экспериментальный Hunter BM пилот
- В `KordRotation.toc` подключён `BM_Pilot_Experimental.lua`: одно правило Arcane Shot (3044), Hunter BM tree 1, явно `experimental`, без прямых WoW API и без автоматического каста. Это **не полная ротация**.
- `RotationSettings`: `allowUnverifiedProfiles=false` по умолчанию; в UI добавлено отдельное ручное включение experimental. Подсказки и текст состояния актуализированы на enUS/ruRU/frFR/deDE/ptBR/esES.
- `README.md` — установка из GitHub ZIP и запуск минимального пилота; `tests/profile_contract_v1.lua` — фиксация статуса и состава пилота.
- Исходное общее ядро `KordRotation/` используется в двух вариантах сборки; `KordRotationDevTools/` остаётся отдельным аддоном.
- **NO LUA 5.1 PASS, NO CLIENT PASS, NO GITHUB ACTIONS.** Ранг заклинания и фактическая иконка в игровом клиенте не подтверждены.

## KR-20261121-136 — защита публичного выбора профиля от protected значений
- `RotationProfiles.lua`: `Get`/`Has` проверяют ключ и уровень через `GameAPI:IsSafeValue` под `pcall` до использования значения в индексах/сравнениях. Неизвестный или защищённый идентификатор не выбирает профиль.
- `tests/profile_contract_v1.lua`: четыре mock-проверки недоверенного ключа/уровня и отказа выбора.
- `docs/rotation/Contract_v1_Status_2_9.md` обновлён. **LUA 5.1 / 17 SUITES NOT RUN; CLIENT NOT RUN; CI NOT RUN.** Прямой checkout недоступен из-за DNS.
- Hunter BM и оригинальный `Profile_Contract.md` без изменений.

## KR-20261121-132 — исправлена Lua 5.1 проверка плотности массивов
- `RotationProfiles.lua`: проверка `dense` больше не использует `#t` для массива с пропущенными индексами; границы проверяются по ключам `pairs`, непрерывность — через `rawget`. Пустые массивы сохраняют допустимость там, где она была предусмотрена.
- `tests/profile_contract_v1.lua`: добавлено пять сценариев для дыр в `Needs.auras`, `Needs.ranges`, `Config`, `Rules`, а также индекса выше лимита.
- `docs/rotation/Contract_v1_Status_2_9.md` актуализирован. **Lua 5.1 17-suite NOT RUN, CI NOT RUN, WoW client NOT RUN**; изменения подтверждены в источниках, но не runtime.
- Hunter BM и канонический `Profile_Contract.md` не менялись.

## KR-20261121-128 — inRange факт привязан к GUID цели в снимке
- `AbilityEligibility:Fact(id,"inRange")`: чтение дальности теперь требует подтверждённую и неизменную идентичность цели (GUID снимка = UnitGUID перед и после чтения), иначе `UNKNOWN`; итоговое READY по-прежнему только у `Evaluate`.
- `tests/stage_02_07_eligibility.lua`: добавлены mock-кейсы отсутствующей цели, устаревшего снимка и смены GUID при вызове API.
- `docs/rotation/Contract_v1_Status_2_9.md`: записаны изменения и блокеры регрессии; локально не доступны Lua 5.1 и точный checkout из-за DNS.
- **SOURCE UPDATED, 17 Lua 5.1 suites NOT RUN, WoW CLIENT NOT RUN, Actions NOT RUN.** Hunter BM и канонический контракт v1 не менялись.

## KR-20261121-124 — согласование текущей контрольной точки 2.9 с реальным кодом
- `docs/rotation/Contract_v1_Status_2_9.md`: исправлены устаревшие утверждения об отсутствии `GameState.ReadSignal`, обновлён верхний статус на `SOURCE IMPLEMENTED (PARTIAL) / STATIC SOURCE AUDIT ONLY`, отдельно перечислены частичные провайдеры и неразрешённые факты.
- Ревизия исходников на GitHub не заменяет исполнение: полный checkout локально недоступен, Lua 5.1 отсутствует; `17 SUITES NOT RUN`, WoW Forever и GitHub Actions не запускались.
- Программный контракт v1 и реализация Hunter BM не изменены.

## KR-20261121-122 — chargesAtLeast fail-closed без неявного порога
- `RotationConditions.lua`: `S:spellFact(id,"chargesAtLeast")` всегда возвращает `nil` без вызова `AbilityEligibility.Fact`: в Profile Contract v1 нет явного аргумента минимального числа зарядов, и даже неверный `READY(true)` провайдера не должен разрешить условие.
- `tests/profile_contract_v1.lua`: сценарий с ошибочным `READY(true)` от mock-факта зарядов, проверка отсутствия вызова.
- `docs/rotation/Contract_v1_Status_2_9.md`: записано **неутверждённое** предложение `spellFact(id,"chargesAtLeast",minimum)` для будущей отдельной версии контракта, без изменения канонического `Profile_Contract.md`.
- В локальной среде отсутствуют Lua 5.1/LuaJIT и полный checkout (DNS недоступен). **17-suite LUA 5.1 NOT RUN; CLIENT NOT RUN; CI NOT RUN.** Hunter BM не затронут.

## KR-20261121-118 — факт known через единый spellKnown
- `AbilityEligibility.lua`: реализован `Fact(id,"known")` без второго алгоритма; повторно использует проверку `spellKnown`, различая `READY(true)`, строго подтверждённый `READY(false)` (SpellBook API `not_learned`) и `UNKNOWN` при недоступных/повреждённых данных. Защита `pcall` и `IsSafeValue` для каталога.
- `tests/stage_02_07_eligibility.lua`: добавлены mock-сценарии известного заклинания, подтверждённого отрицания, отсутствующей записи без API, сбоя и повреждённой структуры каталога.
- `chargesAtLeast` намеренно не реализован: для семантики «не меньше N» контракт `spellFact(id,kind)` не передаёт N. Высший изученный ранг v14 #20 не доказан.
- `docs/rotation/Contract_v1_Status_2_9.md` обновлён. **LUA 5.1/17 tests NOT RUN; WoW CLIENT NOT RUN; GitHub Actions NOT RUN**. Hunter BM не подключён, пользовательский `Profile_Contract.md` не менялся.

## KR-20261121-112 — fail-closed aura guard и расширение mock-фикстур
- `GameState.ReadSignal("player.buff")`: при наличии снимка проверяется `player.exists=READY(true)`; неизвестный/отсутствующий игрок не получает `READY(true)` по Aura lookup.
- `tests/stage_02_03_game_state.lua`: проверены сценарии секретной AuraData, исключения провайдера, защищённого GUID после чтения, а также противоречащих снимков игрока и отсутствие лишних запросов.
- `docs/rotation/Contract_v1_Status_2_9.md`: отрицательное подтверждение ауры не реализовано — `nil` остаётся `UNKNOWN`.
- **Только SOURCE / MOCKS ADDED: Lua 5.1 17-suite NOT RUN, WoW Forever NOT RUN, CI NOT RUN.** Hunter BM и контракт пользователя не изменялись.

## KR-20261121-107 — целостность target.debuff при смене цели
- `GameState.ReadSignal`: для целевых дебаффов требуется подтверждённый GUID цели из снимка; `UnitGUID("target")` проверяется до и после aura lookup через безопасный `GameAPI`. Несовпадение, отсутствие или секретное значение возвращает `UNKNOWN` без заявления об отсутствии ауры.
- `tests/stage_02_03_game_state.lua`: добавлены mock-сценарии отсутствующего/устаревшего/secret GUID и смены цели посреди чтения.
- `docs/rotation/Contract_v1_Status_2_9.md` фиксирует границы защиты. **Lua 5.1, 17 suites, WoW client и Actions NOT RUN**. Hunter BM не подключён.

## KR-20261121-103 — частичный GameState.ReadSignal для подтверждённого наличия аур
- `GameState.lua`: добавлен ленивый источник `player.buff`/`target.debuff` по v14 #12/#13 с защищённым чтением через `GameAPI`. `READY(true)` только для совпадающих Spell ID и типовой категории aura; отсутствие результата не считается `false`.
- `tests/stage_02_03_game_state.lua`: mock-проверки истинного наличия, nil/secret/wrong-ID/wrong-category и пропуска API при отсутствующей цели.
- `Contract_v1_Status_2_9.md`: ограничения, отсутствие доказанного `READY(false)`, неподключённые TTD/swing/enemyCount зафиксированы. `UNKNOWN` сохранён.
- **SOURCE IMPLEMENTED; Lua 5.1 mock regression NOT RUN, WoW client NOT RUN, GitHub Actions NOT RUN.** Hunter BM и оригинальный контракт не менялись.

## KR-20261121-099 — частичная реализация AbilityEligibility.Fact по v14
- `AbilityEligibility.lua`: введён узкий факт-провайдер `cooldownActive` через `C_Spell.GetSpellCooldown.isActive` и `inRange` через `C_Spell.IsSpellInRange` с legacy fallback 0/1. Результаты только `READY(boolean)` или `UNKNOWN`; это не рекомендация к касту.
- `known`, `chargesAtLeast` и GameState.ReadSignal остаются неподтверждёнными; `isOnGCD` не используется для подмены активности кулдауна.
- `tests/stage_02_07_eligibility.lua`: 12 новых mock-проверок для фактов, защит и неполных структур. `docs/rotation/Contract_v1_Status_2_9.md` синхронизирован.
- **Lua 5.1 / 17 suites NOT RUN, CI NOT RUN, CLIENT NOT RUN.** Hunter BM и канонический `Profile_Contract.md` не изменены.

## KR-20261121-095 — расширены тесты границы Needs и кэширования Fact
- В `tests/profile_contract_v1.lua` добавлен сценарий провайдера `inRange`, возвращающего `READY(false)`: запрет вне `Needs.ranges`, сохранение `false`, одно обращение в рамках оценки и новое обращение в следующем контексте.
- `docs/rotation/Contract_v1_Status_2_9.md`: зафиксировано, что в исходниках `GameState.ReadSignal` и `AbilityEligibility.Fact` отсутствуют; mock-провайдеры не означают реализации в WoW Forever.
- Контейнер по-прежнему не имеет Lua 5.1 и доступа к GitHub checkout по DNS. **Lua 5.1/17 suites NOT RUN, CI NOT RUN, client NOT RUN.** Оригинал `Profile_Contract.md` не менялся.

## KR-20261121-091 — локальная регрессия строго на Lua 5.1
- `scripts/run_local_lua_regression.sh`: удалён автоматический fallback на `texlua` (на доступном хосте это Lua 5.3), добавлены проверка наличия `lua5.1` и исполнение отдельного version-probe `_VERSION == "Lua 5.1"` до проверок исходников.
- Проверен фактический `texlua`: `Lua 5.3`; он не является доказательством совместимости Lua 5.1. Локальный checkout из контейнера недоступен из-за DNS, поэтому 17 тестов **не запускались** и статус этапа не повышен.
- Hunter BM, WoW клиент и GitHub Actions не затронуты.

## KR-20261121-087 — Needs.ranges применяется к spellFact(inRange)
- `RotationConditions.lua`: `S:spellFact(spellID, "inRange")` не вызывает `AbilityEligibility.Fact`, если spellID не указан в `Needs.ranges`; ответ `nil` (UNKNOWN). Другие виды фактов остаются доступными только для заклинаний из `Spells`.
- `tests/profile_contract_v1.lua`: добавлены проверки отказа без вызова провайдера и разрешённого запроса с объявленным range-ID.
- Lua 5.1 mock regression и WoW клиент НЕ ЗАПУСКАЛИСЬ; Hunter BM и GitHub Actions не затронуты.

## KR-20261121-085 — контрольная точка миграции Profile Contract v1
- Дата UTC: 2026-11-21. Вынесен `docs/rotation/Contract_v1_Status_2_9.md`: реальный список SOURCE IMPLEMENTED в Registry/Conditions/Engine/Display и 17 тестов, ошибки/фиксы (unknown nil, CFG false, nonfinite/secret) и проверяемые границы текущего статуса.
- `ROADMAP.md` и `docs/rotation/Test_Matrix.md` теперь ссылаются на контрольную точку. Полная Lua 5.1 регрессия, клиент, профиль Hunter и провайдеры v14 НЕ ГОТОВЫ. Только статические проверки и локальная репродукция Lua false выполнены; CI NOT RUN.
- Клиентская поставка по-прежнему без DevTools; оригинальный профильный контракт пользователя не изменялся. Дальше — завершить локальное исполнение 17 suites на точном checkout, затем провайдеры и BM.

## KR-20261121-084 — fail-closed реестр: защищённые SpellID и нечисловые границы CFG
- Дата: 2026-11-21 UTC. Валидация v1 не отвергала все бесконечные значения схемы Config и могла вызвать math.floor для секретного spellID без предварительного GameAPI guard.
- `RotationProfiles.lua`: finite-check default/min/max числовой CFG; spellID guard через IsSafeValue до сравнения/математики; валидация и копирование профиля под pcall, ошибка возвращает отказ регистрации без побочных эффектов. Has(key,level) использует внутренний селектор без глубокой копии.
- `tests/profile_contract_v1.lua`: новые сценарии нечислового CFG/Secret SpellID; все тесты пока SOURCE ONLY, Lua 5.1 / CI / клиент NOT RUN.
- Базовая регистрация профилей остаётся пустой; никакие неподключённые Hunter файлы не активированы. Чужой игровой API не обходится.

## KR-20261121-083 — тест false enum теперь проверяет изменение результата
- Дата: 2026-11-21 UTC. Исправлен недостаток теста KR-20261121-082: ветви cfg.alternate==false и true ранее возвращали одинаковое значение и не доказывали сохранение false. Теперь false отключает первый кандидат; ожидаемый результат — второй spellID=102. После проверки параметр восстанавливается.
- Изменён только tests/profile_contract_v1.lua; Lua 5.1 test NOT RUN, CI NOT RUN, клиент NOT RUN. Поведение исполняемого движка не менялось.

## KR-20261121-082 — исправлена потеря false в настройках профиля
- Дата UTC: 2026-11-21. Причина подтверждена короткой проверкой Lua в texlua: выражение `type(value)=="boolean" and value or default` возвращает `default`, когда `value=false`. Это могло молча включать отключённую настройку (например, useSting) при default=true. Аналогичная форма была в enum fallback.
- `RotationEngine.config` теперь использует явные if/else для bool и enum; пользовательское false сохраняется. `tests/profile_contract_v1.lua` дополнен сценарием выключения флага и enum false, без внешнего API.
- Локальный Lua воспроизводящий пример = PASS для подтверждения первопричины; **не** full repo test и **не** PASS новых скриптов. Полный Lua 5.1/CI/WoW client NOT RUN.

## KR-20261121-081 — актуальная матрица проверки контрактной миграции
- Дата: 2026-11-21 UTC. Profile Registry, cleanup audit и Test Matrix теперь различают SOURCE IMPLEMENTED v1, непроверенные Lua 5.1 сценарии и отсутствие WoW Forever API PASS. Активный набор: 17 Lua scripts.
- Зафиксированы PC-009…013: experimental opt-in в Engine/UI, отзыв разрешения, недекларированные ауры, трёхзначное S:any и отсутствие глубокого копирования при Evaluate.
- Незавершённые провайдеры GameState.ReadSignal / AbilityEligibility.Fact, AUTO-ST/AoE и генератор CFG UI не представлены как DONE. Оригинал Profile Contract v1 без изменений.
- Изменена только документация, local full/CI/client NOT RUN.

## KR-20261121-080 — согласование PROJECT_CONTEXT, BUILD_VARIANTS и Creation Guide
- Дата UTC 2026-11-21. Исправлены фактически устаревшие инструкции о «сначала полный Lua-прогон, потом писать контракт», «текущий Engine = 2.8» и «v1 SPEC ONLY» в PROJECT_CONTEXT, BUILD_VARIANTS, гайде ротаций и rotation README.
- Точная формулировка: v1 SOURCE IMPLEMENTED, актуально 17 Lua suites, ни один новый контракт не получил Lua 5.1 PASS и игровой PASS. Полный локальный прогон только после завершения миграции/ревизии тестов; GitHub Actions только вручную на общем QA.
- Разграничено: оригинальный Profile Contract v1 остаётся без изменений; старый Next и 7-bool requires не активны; Hunter и новые UI-переводы не внедрены. Провайдеры данных на основании непроверенной v14 не активированы.
- Проверки на этом SHA: source review; full Lua/CI/client NOT RUN. Следующий этап — законченность тестовой матрицы и локальная регрессия на exact checkout.

## KR-20261121-079 — целевые тесты нового контракта: experimental и недекларированные источники
- Дата: 2026-11-21 UTC. Добавлены сценарии source-only в `tests/profile_contract_v1.lua`: экспериментальный профиль допускается движком только с явным `allowUnverifiedProfiles`, возвращает отдельный source; недекларированная аура не вызывает провайдера, `S:any` корректно различает false/nil и отбрасывает неверный тип.
- `tests/stage_02_08_v14_display.lua` расширен: экспериментальная иконка без согласия не отображается, при явном согласии показывается, после сброса флага снова скрывается. Тесты UI/DevTools сохранены, старые engine suites не возвращаются.
- Запуск обновлённых тестов ещё не подтверждён на полном Lua 5.1 checkout; LOCAL NOT RUN, GitHub Actions manual-only/NOT RUN, WoW CLIENT NOT RUN. Не приписывать PASS исходникам без исполнения.

## KR-20261121-078 — синхронизация статуса контракта v1 и нового порядка тестов
- Дата: 2026-11-21 UTC. AGENTS/README/ROADMAP описывали v1 как NOT IMPLEMENTED и требовали полный прогон прежних 18 тестов до миграции.
- Обновлено: RotationProfiles/RotationConditions/RotationEngine = SOURCE IMPLEMENTED, Lua 5.1 / CLIENT NOT RUN. Две obsolete 2.8 suites удалены, одна v1 добавлена; активный набор = 17. Тесты выполняются после пересмотра новой архитектуры, а не перед её внедрением.
- Исходный загруженный Profile Contract v1 остаётся побайтово сохранён, второй движок не создан, Hunter не подключён. CI manual-only и NOT RUN. Следующий шаг — ревизия/локальный запуск; игровые провайдеры ещё не подтверждены.

## KR-20261121-077 — исключено глубокое копирование правил на каждой оценке
- Дата: 2026-11-21 UTC. В прежнем контракте `RotationProfiles:Get()` копировал все Rules на каждом `RotationEngine:Evaluate()`, что противоречит требованию минимальной нагрузки.
- Выделен внутренний селектор `ResolveForEngine(key,level)` с прямым чтением уже валидированной, скопированной при регистрации структуры. Единственный доверенный потребитель — `RotationEngine`; вызываемые профилем функции не получают ссылку на эту структуру, а получают только ограниченный контекст S и CFG. Обычный публичный `Get` всё ещё возвращает отдельную глубокую копию.
- В `tests/profile_contract_v1.lua` добавлены проверки, что Get не раскрывает внутренний объект и внутренний селектор не копирует Rules при каждом вызове.
- Изменения касаются только выбора профиля, не GameAPI, не WoW кадра; Lua 5.1 target-test / combined test пока NOT RUN, CI NOT RUN, CLIENT NOT RUN. Последующий статический аудит профилей остаётся обязательным.

## KR-20261121-076 — удалить две устаревшие контрактные фикстуры 2.8
- Дата: 2026-11-21 UTC. Согласованная миграция тестов после изменения RotationProfiles/RotationEngine; из текущего Git-дерева удаляются `tests/stage_02_08_rotation_engine.lua` и `tests/stage_02_08_v14_rotation_contract.lua`, проверявшие исключительно старый static requires/verified=true контракт.
- Заменены `tests/profile_contract_v1.lua`; оба runner-манифеста уже используют новый набор. Не удалены проверки GameState, GameAPI, AbilityEligibility, UI и DevTools.
- `docs/STAGE_02_08_ROTATION_ENGINE.md` явно отмечен историческим; `docs/rotation/Test_Matrix.md` разделяет старые прошлые PASS и новые v1 сценарии SOURCE IMPLEMENTED / LOCAL NOT RUN. Git сохраняет удалённые версии.
- CI manual-only без запуска; полный локальный 5.1, полный checkout и WoW Forever NOT RUN. Приложение не выполняет игровой каст.

## KR-20261121-075 — новый сценарный mock профиля v1 и тестовый манифест
- Дата: 2026-11-21 UTC. Реальный файл `tests/profile_contract_v1.lua` проверяет registry contractVersion/Needs/SkipExceptions/Spell IDs/диапазоны уровней, engine UNKNOWN/skip/pcall/PET_COMMAND/Eligibility, target mode, immutable Get, restricted S и ленивые all/any, per-evaluation cache, отсутствие необъявленного SpellID и непридуманных фактов кулдауна.
- `scripts/run_local_lua_regression.sh` и `.github/workflows/lua-regression.yml` теперь ссылаются на новый тест вместо двух устаревших наборов 2.8. Остальные GameAPI, GameState, AbilityEligibility, UI и DevTools mock сохранены; GitHub workflow остаётся ТОЛЬКО `workflow_dispatch`.
- Два старых теста 2.8 физически пока ещё существуют, их удаление будет отдельным проверяемым изменением после анализа ссылок; они не являются действующей регрессией контрактного движка. Это не доказательство прохождения new mock: LOCAL NOT RUN, CI NOT RUN, CLIENT NOT RUN на SHA.
- Цель: проверять новый контракт, а не пытаться восстановить старую статическую схему из семи requires. Следующий шаг — выполнить targeted Lua test на точном Git snapshot и довести тестовый набор.

## KR-20261121-074 — строгая трёхзначная проверка дочерних условий и secret аргументов
- Дата: 2026-11-21 UTC. По исходниковому аудиту обнаружена возможность неверного `skip`: `S.all/S.any` трактовали ошибочный строковый результат дочерней проверки как nil, позволяя пропустить недопустимое условие. Теперь значение вне true/false/nil бросает исключение; Engine превращает его в `condition_error` и останавливается.
- Порядок Secret API guards в `RotationConditions:Check` и `S:spellFact` исправлен: `IsSafeValue` вызывается перед сравнением потенциально защищённых полей. Без изменения actual WoW API.
- Результаты: защита UNKNOWN усилена, никаких новых опросов или сканирования. Targeted mock specs ещё разрабатываются; полный local CI/client NOT RUN.

## KR-20261121-073 — закрытие регрессии трёхзначной логики и допуск отображения
- Время: 2026-11-21 11:10 UTC. Проверка исходников после 2.9-C выявила баг: Lua выражение `unknown and nil or false` всегда возвращало false; `S:any` теперь возвращает именно nil при неопределённости без true. Это важно для fail-closed.
- `RotationProfiles:Has(key)` подтверждает наличие диапазонов без конкретного уровня; `Get(key,level)` выбирает правильный профиль. Проверяются `mode`, а `skip` запрещается для категорий defensive/cooldowns/interrupts.
- `RotationDisplay` допускает `experimental_profile` только при явном `settings.allowUnverifiedProfiles == true`, в обычной поставке такой флаг по умолчанию отсутствует. Строгий валидатор рекомендуемого spellID/texture остаётся прежним.
- Не тронуты Hunter TOC, пользовательские локали, автоматические действия; нового набора тестов ещё нет, поэтому full regression/CI/client NOT RUN. Следующий шаг: сценарные проверки нового контракта и ревизия старых 2.8 тестов.

## KR-20261121-072 — RotationEngine v1: ленивый обход, stop/skip и единый Eligibility
- Дата: 2026-11-21 11:00 UTC; этап 2.9-C IN PROGRESS, заменён ограниченный исполнитель семи `requires`.
- `RotationEngine.lua`: выбор профиля по классу, дереву и подтверждённому уровню; только `verified` или явно разрешённый `experimental`; режимы single/aoe, auto fail-closed; проверка одного правила за раз с pcall, UNKNOWN стоп, документированный condition_unknown skip, ошибок не пропускаем; `PET_COMMAND` unsupported_action без иконки; `AbilityEligibility` — единственная окончательная проверка; catalogue и binding читаются только после READY. UI использует прежний формат `queue` из 1 элемента.
- Не создан второй движок или runtime alias старых Hunter; GameState/provider без доказательств не вызывается eagerly. Ошибки и Secret значений превращаются в UNKNOWN. Настройки старого пользователя не активируют профиль автоматически.
- Неактивные Hunter исходники не подключены к TOC. Локальная новая регрессия ещё готовится; предыдущие 2.8 Engine-тесты устарели и будут заменены. GitHub Actions и WoW Forever не запускались.

## KR-20261121-071 — ограниченный ленивый контекст S (этап 2.9-C)
- Время: 2026-11-21 10:45 UTC. Изменены KordRotation/Core/RotationConditions.lua и KordRotation.toc (перед RotationEngine).
- Причина: будущий профиль должен получать только утверждённые методы чтения, а не сырые snapshot поля и не прямой WoW API. Глобальный S не создаётся; создаётся на каждый Evaluate и принимает ленивые замыкания.
- Добавлены S:is/isNot/eq/ge/le, all/any с short-circuit, S:spellAvailable, S:spellFact, ограничение Needs, кэш в рамках оценки, единый вызов AbilityEligibility; Fact без подтверждённого источника => nil, ReadSignal без провайдера => nil, прямой state не предоставляется. Метатаблица не даёт записывать новые поля. Никаких автоматических действий.
- Защита: pcall для внешних чтений, проверка Secret через GameAPI:IsSafeValue, объявленные SpellID; Eligibility UNKNOWN не превращается в READY. До реализации провайдеров данные remain UNKNOWN, никакой предварительной загрузки.
- Сравнены референсы Sonah/MaxDps/JustAC/ForeverRotation/RotationGuide; использована каноническая форма Kord, чужой код не копировался. Game client/CI/full regression NOT RUN; новые S tests — следующий шаг.

## KR-20261121-070 — Profile Contract v1: новый реестр (код 2.9-C, часть 1)
- Дата/время: 2026-11-21 10:30 UTC, этап 2.9-C IN PROGRESS; предыдущий HEAD 34cd937e803424799b1b5804576a203278190e1f.
- Проблема: старый 2.8 RotationProfiles принимал только verified=true и статичные single/aoe с семью boolean requires; не выражает Hunter BM и не различает уровень 1–59/60.
- Изменено: RotationProfiles.lua заменяет формат на contractVersion=1, id/status draft/mock_tested/experimental/verified, class/spec/level intervals, Spells, Needs allowlist, Config, Rules function when, explicit SkipExceptions. Регистрируются несколько неперекрывающихся диапазонов уровня, возвращаются независимые копии правил, не регистрируются старые Hunter автоматически.
- Безопасность: только явные Spell ID, запрещён skip без обоснования+testID, несовместимые старые правила отклоняются; выбор приоритета и клиентский допуск — следующий отдельный компонент.
- Исходники Sonah/MaxDps/JustAC/ForeverRotation/RotationGuide сравнены по организации классовых правил; ни один их модуль не копируется. Lua/CI/client на этом SHA NOT RUN; активных профилей ноль.
- Следующее: ограниченный контекст S, адаптация RotationEngine, целевые тесты нового формата, удаление устаревших тестовых ожиданий и ревизия регрессии.

## KR-20261121-069 — уточнения реализации Profile Contract без изменения оригинала
- Дата: 2026-11-21 UTC. Выявлено, что пример `when=S.all(...)` в оригинале v1 нельзя исполнять на загрузке модуля без `S` конкретной оценки. Добавлен отдельный поясняющий блок в `docs/rotation/Engine_Cleanup_Audit_2_9.md`: правило должно получать контекст `S` при выполнении.
- Уточнены границы целевых статусов профиля, cooldown/GCD фактов, `skip` и будущих измерений. **Оригинал Profile_Contract.md оставлен побайтово неизменным** (blob `17415a2401f9b82bd2c580fa8d69d63483a38a65`).
- Изменена только документация, никаких новой игровой логики, API или DevTools OnUpdate. Lua local suite, CI и клиент NOT RUN на SHA; последняя синтетическая сборочная проверка относится к точному `build_variants.py` blob.
- Следующий подэтап: полноценный локальный 18-suite прогон на точном Git checkout, а затем по отдельному утверждённому алгоритму контрактная миграция.

## KR-20261121-068 — сводная инвентаризация ядра, документов и тестовых статусов
- Дата UTC: 2026-11-21. Вынесен проверяемый перечень 122 исходных файлов (31/39 core Lua в TOC, остальные восемь — Hunter, 8/8 DevTools Lua в TOC), доказательства сохранения необходимых элементов и правила исключения неактивных файлов из ZIP.
- Новый `docs/rotation/Engine_Cleanup_Audit_2_9.md` различает: сохраняем активный код, сохраняем источники Hunter только в Git, архивируем исторический README, помечаем 16 STAGE отчётов и четыре root API research таблицы как исторические. Ни один пригодный исследовательский файл не удалён без проверки ссылок.
- В `docs/rotation/Test_Matrix.md` добавлены CLEAN-001…007: исправления mock-файлов, паритет упаковки, точный SHA контракта, локальные и игровые тесты со статусами. `docs/archive/README.md` ссылается на аудит.
- Подтверждено: source 11/11 нормативных файлов без сломанных относительных ссылок; локально синтетический упаковщик прошёл проверку на точном Git blob `98aa1bc4b7552d052d05b2f8f31b82dc319ef682`. **Полный** Lua/Python run, GitHub Actions CI, WoW Forever NOT RUN.
- Перед дальнейшей миграцией правило №1 требует исследование и явное согласование конкретных изменений. Аудит — документация, не реализованная ротация.

## KR-20261121-067 — байтовая точность загруженного Profile Contract v1
- Дата: 2026-11-21 UTC. При проверке исходного файла `Profile_Contract(1).md` выявлено отличие скопированного через text-index варианта от исходных байтов: отсутствовала единственная завершающая LF.
- Исправление: в `docs/rotation/Profile_Contract.md` восстановлен исходный trailing LF без изменения содержания. Ожидаемый Git blob SHA исходного загруженного файла: `17415a2401f9b82bd2c580fa8d69d63483a38a65` (12074 байта UTF-8). Этот SHA сравнивается с фактическим опубликованным blob SHA.
- Результат: сохранён **побайтово исходный** документ пользователя; остальные правила/движок/сборки не изменены. Lua/CI/client NOT RUN для этого документа.
- Уточнение к KR-20261121-062: текст тогда был полным, но без завершающего перевода строки; настоящая запись делает копию точной.

## KR-20261121-066 — установочные ZIP только из загружаемого кода
- Дата: 2026-11-21 UTC; согласованная очистка перед новым контрактом профилей.
- Причина: старый `build_variants.py` упаковывал все файлы `KordRotation/`, включая 8 неподключённых Hunter Lua-заготовок, хотя ни одна не была в TOC; это лишний размер пакета и возможная путаница.
- Изменено: `scripts/build_variants.py` включает Lua только из TOC, сам TOC и разрешённые игровые assets (.blp/.png/.tga/.ogg/.wav/.mp3); необъявленные Lua **сохраняются в репозитории**, но не в двух ZIP. `tests/test_build_variants.py` проверяет исключение Inactive.lua, отсутствие Hunter profiles в реальной поставке и сохранение Logo.blp. `docs/DEVTOOLS_ARCHITECTURE.md` уточняет правило.
- Гарантия: базовая папка `KordRotation/` внутри user/dev ZIP остаётся побайтово тождественной; DevTools-only Lua присутствует только во втором архиве; будущие профили подключать только явным TOC.
- Проверки: source inspection, тесты обновлены; локальный полный Python/Lua НЕ запускался на этом SHA, CI NOT RUN, игровой клиент NOT RUN. Не принимать source count за in-game PASS.

## KR-20261121-065 — исправление двух mock-фикстур по стороннему ревью
- Дата: 2026-11-21 UTC; исходник `test_fixtures_fix.patch` передан заказчиком и сопоставлен с реальным кодом.
- `tests/devtools_recorder.lua`: `issecretvalue(nil)` больше не считает `nil` секретным, когда тестовая переменная `saved` ещё не определена. Runtime-защита не меняется.
- `tests/stage_02_08_v14_display.lua`: mock-фрейм возвращает `nil` для отсутствующих data-атрибутов вместо заглушки функции; только mock, не игровой UI.
- Проверки: точные текстовые якоря патча подтверждены; полный Lua 5.1 прогон ещё NOT RUN на SHA, CI NOT RUN, WoW Forever CLIENT NOT RUN. Отдельный строгий mock методов — будущая задача.
- Сборочные ZIP и Hunter не менялись.

## KR-20261121-064 — синхронизация руководства и контрактных реестров
- Дата: 2026-11-21 UTC. Согласованная очистка перед этапом 2.9.
- Обновлены BUILD_VARIANTS_AND_DIAGNOSTICS, PROJECT_CONTEXT, Kord_Rotation_Creation_Guide и rotation README/GameData_Contract/Profile_Registry: в каждом указана единая нормативная `docs/rotation/Profile_Contract.md` (SPEC ONLY), порядок до Hunter, отсутствие runtime aliases и не подтверждённая клиентом v14.
- Уточнено, что устаревший `Next(state,options)` и `Hunter_Common` — исторические исходные интерфейсы, не второй нормативный контракт. Существующие фактические булевы условия 2.8 сохраняются до отдельного кодового этапа с тестами. Тестовый допуск не равен игровому verified.
- Исполняемый код, TOC, профили и игровой UI не изменялись; QA и CI NOT RUN на SHA. Все шесть локалей без изменений.
- Следующее: локальные фикстуры и проверяемые два ZIP; реальная миграция контракта будет отдельным этапом.

## KR-20261121-063 — чистка README, AGENTS и ROADMAP перед контрактом 2.9
- Дата: 2026-11-21 UTC. Задача: убрать исторические версии из действующей точки входа, устранить старую последовательность «DevTools → Hunter напрямую», не потеряв доказательства/историю.
- `README.md` переписан как короткий текущий индекс; его старое содержимое **сохранено дословно** в `docs/archive/README_HISTORY_2026-11-21.md`. Создан `docs/archive/README.md` с классификацией архивных материалов. AGENTS теперь прямо указывает этап 2.9 и контракт `docs/rotation/Profile_Contract.md` как SPEC ONLY; ROADMAP фиксирует новый 2.9-A…E, помечает старый пункт 2.9 историческим.
- Исходный код, профили Hunter, API matrices и игровые модули этим коммитом не меняются. Архивирование не равно удалению важных доказательств. Нет дублирования общего движка.
- Проверки: наличие документов, ссылок и Git commits; Lua LOCAL NOT RUN, GitHub Actions CI NOT RUN, Forever CLIENT NOT RUN.
- Выдача: документальный коммит; клиентская установка и тесты не требуются до единого QA.

## KR-20261121-062 — исходный Profile Contract v1 сохранён без изменений
- Дата: 2026-11-21 UTC; источник: загруженный заказчиком `Profile_Contract(1).md` (полные 141 строка, актуальная редакция от 2026-11-21).
- Задача: перед чисткой сохранить текст нового контрактного предложения в `docs/rotation/Profile_Contract.md`. **Важное:** документ является проектным ориентиром этапа 2.9; Lua implementation и игровой PASS ещё НЕ выполнены. Исторический предыдущий формат реестра остаётся кодом до отдельной проверенной миграции.
- Исходная версия скопирована без скрытого изменения правил. Известные уточнения (ленивость условий, исключения skip, тестовое/игровое подтверждение) будут отслеживаться отдельно в плане этапа и тестах.
- Проверки: полный исходный текст прочитан, git blob сохранён; runtime/CI/клиент NOT RUN; референсы Sonah/MaxDps/JustAC/ForeverAuras/ForeverRotation/RotationGuide проверены на организацию профилей, без копирования кода.
- Следующий шаг: инвентаризация ссылок и отдельных источников истины, архивирование только обоснованного; документация и сборщик синхронизируются без удаления исходников Hunter.

## KR-20261121-061 — актуальный проектный контекст и проверенные границы DT-1–DT-6
- Дата: 2026-11-21 UTC; коммит: см. git log --grep KR-20261121-061.
- Изменены PROJECT_CONTEXT.md и docs/rotation/Test_Matrix.md: текущий статус двух физически разных устанавливаемых вариантов с единственной исходной папкой KordRotation, список подтверждённых локальных точечных проверок с точными blob SHA, полный список NOT RUN.
- Фактические локальные результаты: синтетическая byte-parity сборка двух ZIP, Registry 101 строк, Probe 12 assertions, aggregate Trace 17 assertions. Сверка SHA подтверждает точные исходные скрипты. Данные нельзя экстраполировать на полный 18-suite PASS.
- GitHub Actions CI не запускался, клиент WoW Forever, FPS/RAM, полная реальная упаковка/чистая установка NOT RUN. Приоритеты Hunter и матрица v14 не менялись.
- Выдано: подтверждаемые ссылки и переносимый статус для будущих чатов, без требования промежуточной установки игроком.

## KR-20261121-060 — два точных пакета: обновление нормативной архитектуры
- Дата: 2026-11-21 UTC; коммит: см. git log --grep KR-20261121-060.
- Прямое решение заказчика: диагностическая сборка должна содержать точную копию всех файлов пользовательского KordRotation плюс дополнительный DevTools; общая разработка ведётся в одном исходном каталоге. Приведены в соответствие AGENTS.md, BUILD_VARIANTS_AND_DIAGNOSTICS.md, ROADMAP.md.
- Убрано устаревшее утверждение, будто папка DevTools ещё не создана. Статус: исходники есть, но полный сборочный артефакт, CI и игровой клиент НЕ проверены. Сценарии 18 Lua + Python накоплены. Частичные локальные тесты не превращены в общий PASS.
- Проверка: исходниковый анализ; GitHub Actions CI NOT RUN согласно решению заказчика; WoW Forever и FPS/RAM NOT RUN; Hunter BM 1–59 PvE не подключён.
- Выдано: точный SHA коммита и действующее правило параллельной разработки для всех следующих чатов.

## KR-20261121-059 — DT-4 тест агрегированных статусов и секретного счётчика
- Дата: 2026-11-21 UTC; см. git log --grep KR-20261121-059.
- Причина: Trace.lua не должен использовать tonumber на защищённом счётчике ошибок до проверки Safe; UI aggregate status требовал интеграционного mock.
- Изменено: Trace проверяет защищённость числа до арифметики, тесты проверяют PROFILE→ELIGIBILITY→ENGINE, UNKNOWN/ERROR/UNAVAILABLE, отсутствие повторов, остановленную запись, секретный counter. UI display mock проверяет агрегированные счётчики и неизменность production recommendation. Локальный runner и ручной workflow включают восемнадцатый Lua набор.
- Тесты: написаны; full local suites NOT RUN, GitHub Actions CI NOT RUN, клиент WoW Forever NOT RUN. Остаётся тест CPU/RAM в игре.
- Граница: агрегированные статусы не доказывают причины выбора каждой способности; профиль Hunter и приоритеты не менялись. Не выводить исходные Spell ID, GUID или необработанные значения.
- Выдано тестировщику: коммит с фикстурами для единого комплексного QA.

## KR-20261121-058 — DT-4: агрегированные ELIGIBILITY/PROFILE/ERROR сигналы без Spell ID
- Дата: 2026-11-21 UTC, см. git log --grep KR-20261121-058. Объём утверждённого DevTools.
- Проблема: ранее DevTools собирал EVENT и общий ENGINE, но не различал сводные изменения PROFILE/ELIGIBILITY и факт ошибок EventBus.
- Изменения: `RotationDisplay` после одного обычного Evaluate сохраняет только счётчики READY/BLOCKED/UNKNOWN и безопасный статус профиля, без Spell ID/GUID/имен/целей; `CoreObservation:Read()` отдаёт исключительно ограниченные скалярные значения; `DevTools/Trace.lua` записывает изменения PROFILE/ELIGIBILITY/ERROR только при Start и через bounded Recorder, максимум одну агрегированную запись за обновление с повтором при rate-limit. Без дополнительных GameAPI вызовов или нового боевого OnUpdate.
- Тесты: расширен observer mock, отдельный trace mock добавится в следующем коммите; пока LUA LOCAL NOT RUN, CI NOT RUN, Forever NOT RUN.
- Граница: это агрегированная диагностика, не per-rule spell trace; не представлять как точный журнал приоритетов. Общие модули KordRotation публикуются один раз для обеих поставок; DevTools-only Trace остаётся отдельно.
- Выдано тестировщику: точный коммит и новый сценарий для единого QA.

## KR-20261121-057 — DT-6 security regression: secret-safe CoreObservation probe
- Дата UTC: 2026-11-21. Коммит: см. git log --grep KR-20261121-057.
- Причина: read-only мост CoreObservation:Probe проверял длину имени перед вызовом GameAPI:IsSafeValue, что могло быть опасно для protected имени; DevTools:ProbeMethod читал status результата до проверки безопасности.
- Исправлено: CoreObservation проверяет безопасную доступность до сравнений, ProbeMethod обрабатывает статус внутри pcall после проверки Safe. На недоступном ответе UNKNOWN. Добавлены тесты protected API name, invalid name, presence-only и malicious secret status. Не добавлены игровые API или новые привилегии.
- Проверка: исходниковый статический анализ; новый Lua mock NOT RUN на этом SHA, CI NOT RUN (только ручной), WoW Forever NOT RUN. Это улучшение проверки секретов, но не доказательство клиента.
- Общий каталог CoreObservation остаётся единственным, автоматически идентичным в обеих ZIP, DevTools-only Probe присутствует только во второй. Следующий этап: синхронизация источников истины и QA-матрицы.

## KR-20261121-056 — подключение v14 Registry в загрузку и все шесть языков
- Дата: 2026-11-21 UTC; коммит: см. git log --grep KR-20261121-056.
- Изменения: TOC DevTools теперь загружает V14Registry.lua перед Probe.lua; переводы отчёта во всех шести языках уточняют, что 79/101 source-probe — только наличие связанного метода, не игровой PASS. Локальный runner и ручной workflow включают семнадцатый Lua mock; обновлена документация двух поставок.
- Причина: объединённый реестр 101 строк из KR-20261121-055 требует правильного порядка загрузки и ясного текста, чтобы не вводить пользователя в заблуждение.
- Проверки: текстовая проверка ТОC, 6 переводов и workflow_dispatch; Lua runtime NOT RUN, GitHub Actions CI NOT RUN, WoW Forever NOT RUN. Никакого автозапуска CI.
- Риски: метод может присутствовать, но возвращать Secret API или не работать для игрового сценария; игра ещё не проверена.
- Выдано тестировщику: коммит и программа общего QA, без промежуточного тестирования.

## KR-20261121-055 — v14 101-строчный реестр возможностей DevTools
- Дата: 2026-11-21 UTC; коммит: см. git log --grep KR-20261121-055; утверждённые DT-1–DT-6.
- Причина: старый Probe учитывал только 22 метода и не давал статуса всем 101 пунктам нормативной v14.
- Изменено: V14Registry.lua хранит номера 1–101; 79 строк имеют связанный метод из реального allowlist GameAPI исключительно для presence-probe, 22 без одиночного безопасного probe = UNKNOWN. ProbeAll собирает 101 строку, не приравнивая наличие API к доказанной игровой возможности; тесты обновлены и добавлен test registry.
- Проверка: исходниковый разбор 101 строки и 79/22, отсутствие новых API; Lua runtime NOT RUN, Actions CI NOT RUN, CLIENT PASS=0/101. Связанное подключение TOC и переводов — следующий отдельный коммит.
- Выдано тестировщику: коммит к будущему единому QA; временно Probe ожидает загрузку нового registry module.

## KR-20261121-054 — DT-6: проверяемый паритет упаковок и накопленная регрессия
- Дата: 2026-11-21 UTC; коммит: см. git log --grep KR-20261121-054; весь DT-1–DT-6 утверждён заказчиком.
- Проблема: упаковщик ранее не проверял наличие TOC-модулей и строгие метаданные второго аддона; новые mock-тесты не были включены в локальный и ручной CI сценарии.
- Изменения: build_variants.py сверяет все TOC пути и обязательные Dependencies/SavedVariables; test_build_variants.py проверяет реальный checkout, конфликтующие файлы и отсутствующие модули; добавлены devtools_boot.lua и devtools_ui_locale.lua; обновлены локальный bash runner и ручной workflow для 16 Lua наборов и Python unittest. README архитектуры и матрица QA синхронизированы.
- Проверки: тесты накоплены; общий локальный запуск NOT RUN на текущем SHA до проверки полного checkout; GitHub Actions CI NOT RUN — сохраняем минуты; Forever QA NOT RUN. В прошлой истории 11 suite не объявляются результатом текущего кода.
- Риски: UI требует клиента WoW для проверки FrameXML; только 22 присутствия методов допускаются в текущем Probe, не 101 функциональный PASS; профили Hunter не активированы.
- Выдано тестировщику: точный SHA по ссылке commit, сценарии будущего единого QA без промежуточной установки.

## KR-20261121-053 — DT-5b: вывод developer-функций из пользовательской диагностики
- Дата: 2026-11-21 UTC; коммит: см. git log --grep KR-20261121-053.
- Причина: девятая страница `Diagnostics` обычного аддона имела API-проверки, просмотр журнала, экспорт и developer-кнопки; это противоречит утверждённому разделению.
- Фактически изменены: `KordRotation/Core/Diagnostics.lua` — только безопасные базовые Snapshot/CompatibilityText, совместимые пустые методы Log/RecordCharacter без накопления сырых сообщений; `KordRotation/UI/Pages/AdvancedDiagnostics.lua` — страница девять сохранена, но без probe, export, rescan, clear, событий и записи; `KordRotation/Core/Locale.lua` — обновлены подсказки и добавлено пояснение на ruRU/enUS/frFR/deDE/ptBR/esES.
- Дополнительный UI расширенной диагностики теперь только в `KordRotationDevTools/UI.lua`. Это изменение базового каталога автоматически попадает в обе ZIP-поставки без копирования кода. Подход уменьшает запись данных и число UI-компонентов в обычном аддоне.
- Проверка: источниковое сопоставление и 6 словарей; полный Lua mock и игровой клиент НЕ ЗАПУСКАЛИСЬ, статусы LOCAL NOT RUN / CI NOT RUN / IN-GAME NOT RUN.
- Риски: старые вызовы Diagnostics:Log остаются совместимыми, но прежний технический отчёт намеренно не экспортируется из обычной сборки. Полный игровой тест страницы и формата локализаций перед выпуском обязателен.
- Выдано тестировщику: коммит и контракт для будущего единого QA; не просим устанавливать промежуточную версию.

## KR-20261121-052 — DT-5a: отдельный интерфейс и шесть локалей DevTools
- Дата: 2026-11-21 UTC; коммит: см. git log --grep KR-20261121-052; утверждённые DT-1–DT-6.
- Причина: диагностический TOC ссылался на отсутствующие Locale.lua и UI.lua — пакет был неполным.
- Изменены: KordRotationDevTools/Locale.lua и KordRotationDevTools/UI.lua. Добавлен самостоятельный UI с ручными Start/Stop, Probe, Measure, Export/Copy, Clear и Close, чётким статусом; все кнопки и подсказки локализованы на enUS/ruRU/frFR/deDE/ptBR/esES (алиасы enGB/esMX/ptPT). Копирование через выделение текста и Ctrl+C, без попыток записи на диск.
- Риски: FrameXML/видимость проверяются только в настоящем клиенте; использование BasicFrameTemplateWithInset требует client QA. В пользовательской сборке UI DevTools отсутствует. Не включён новый WoW API.
- Тесты: статическое сопоставление семи кнопок и ключей, locale coverage будет выполнен в DT-6. Lua runtime/игра NOT RUN; GitHub Actions CI NOT RUN по правилу экономии.
- Выдано тестировщику: коммит; отдельную установку пока не требуем. Следующий шаг: разделение пользовательской диагностики и DevTools.

## KR-20261121-051 — DT-4: opt-in EVENT/ENGINE trace и ограниченное профилирование
- **Дата UTC:** 2026-11-21. **Контракт:** TraceStart вызывается только после ручного Recorder:Start; TraceStop удаляет регистрации, callbacks, polling. События из whitelisted списка, без raw payload, target/GUID, spellId, chat или защищённых данных.
- **Изменено:** Trace.lua, Performance.lua, tests/devtools_trace.lua. EVENT записи содержат только разрешённую категорию и номер строки матрицы; ENGINE только изменение статуса готовой сводки, никакой автооценки AbilityEligibility. Интервал 0.75 сек только при активной ручной записи.
- **Измерение:** Measure() вручную измеряет только накладные расходы чтения CoreObservation через debugprofilestop, не объявляется всей CPU/FPS статистикой аддона. При отсутствии метода UNKNOWN/UNAVAILABLE; не выводить вымышленный 0ms.
- **Результаты:** мок тесты добавлены, локальный прогон NOT RUN; CI NOT RUN по утверждённой политике; WoW Forever NOT RUN. Per-rule ELIGIBILITY/PROFILE trace остаётся UNSUPPORTED до отдельного безопасного контракта и реального профиля.
- **Общие файлы KordRotation:** без изменений; диагностическая поставка по-прежнему получает точную копию общего исходника.

## KR-20261121-050 — DT-3: разовые верификационные API-пробы v14
- **Дата UTC:** 2026-11-21. **Доказательства:** source-baseline v14, номера 1,2,3,6,7,8,9,10,11,12,14,15,17,18,19,20,21,24,26,32,33.
- **Изменения:** DevTools-only Probe.lua, 22 пары известных методов и строк v14, однократный ProbeAll только по действию пользователя, запрет произвольного API name/action, ответ presence_only_not_client_pass. Через CoreObservation:Probe читает лишь уже утверждённую GameAPI:Probe; не вызывает никаких protected game actions и не выдаёт существование метода за его игровой PASS.
- **Тесты:** devtools_probe.lua написан; локальный прогон NOT RUN, CI NOT RUN, игровой Forever NOT RUN.
- **Граница:** никакой дополнительной зависимости от DevTools для пользовательского аддона; KordRotation входит в обе сборки в одинаковых байтах.

## KR-20261121-049 — DT-2: ручная запись и узкий мост CoreObservation
- **Дата UTC:** 2026-11-21. **Решение:** пользователь явно одобрил DT-1–DT-6 и побайтово одинаковую базу KordRotation в обеих сборках.
- **Причина:** DevTools имеет отдельный WoW namespace; прямого доступа к приватной KR таблице нет. Экспортировать всё ядро глобально нельзя.
- **Код:** в общем CoreObservation экспортирован строго read-only мост `KordRotationCoreObservation` с Read/Probe; он одинаков в обеих поставках. DevTools Core теперь читает только этот мост и проверки секрета клиента. Recorder: ручные Start/Stop, max 256 записей, max 3 остановленных сеанса в отдельных SavedVariables, 900-секундный лимит, дроп-счётчик, ограничение частоты и узкий whitelist полей. Никакого автозапуска после /reload; без чата, GUID, содержимого боевого журнала и raw Spell ID.
- **Тесты:** `tests/devtools_recorder.lua` добавлен, локальный Lua NOT RUN на этом SHA; Actions CI NOT RUN; игровой клиент NOT RUN. Новые методы должны проверяться перед QA.
- **Последствия:** общий файл CoreObservation меняется одновременно для обоих ZIP из одного источника. DevTools-only Recorder не входит в пользовательский архив.

## KR-20261121-048 — DT-1: два ZIP с побайтово общим KordRotation
- **Дата/часовой пояс:** 2026-11-21 UTC. **Решение:** заказчик утвердил DT-1–DT-6 и точную копию базового аддона в диагностической поставке.
- **Причина:** два независимых каталога исходников KordRotation в репозитории могли бы разойтись. Выбран единый кодовый каталог и детерминированная сборка двух физических пакетов.
- **Файлы:** KordRotationDevTools.toc, Core.lua (каркас, recording выключен), scripts/build_variants.py, tests/test_build_variants.py, docs/DEVTOOLS_ARCHITECTURE.md.
- **Контракт:** пользовательский ZIP содержит только KordRotation, диагностический — тот же KordRotation байт-в-байт плюс DevTools. Один исходник общего ядра для обоих, SHA-256 и ZIP-сравнение обязательны при сборке.
- **Референсы:** Sonah/MaxDps/JustAC/ForeverAuras/ForeverRotation/RotationGuide сравнены на уровне исходников; не копируются защищённые или лицензионные части.
- **Тесты:** тест упаковки написан; на SHA коммита LOCAL NOT RUN, CI NOT RUN, WoW Forever NOT RUN. Пустые пока DT-2–DT-5 не считать работающими.
- **Следующий шаг:** отдельные диагностические функции и тесты; общий CI только перед QA.

## KR-20261121-047 — убрать историческое противоречие в плане пилота и статусах CI
- **Дата/зона:** 2026-11-21 UTC. **Причина:** историческая фраза про первый профиль «Воин — Оружие» противоречила утверждённому Hunter BM 1–59 PvE и могла дезориентировать следующий чат.
- **Изменено:** `docs/STAGE_02_08_ROTATION_ENGINE.md` явно указывает пилот Hunter BM Leveling PvE после DevTools; `docs/ROADMAP.md` различает исходниковый IMPLEMENTED, частичный локальный PASS, общий CI NOT RUN и игровой QA NOT RUN. Остальные нормативы не менялись.
- **Проверки:** текстовый аудит, код Lua и тесты не изменены; Actions не запускались по решению заказчика. До общего QA необходимо проверить все 11 mock suites.

## KR-20261121-046 — 2.8.6e: локальный runner, проверка структуры и матрица QA
- **Дата/зона:** 2026-11-21 UTC. **Причина:** завершить 2.8.6 с воспроизводимыми локальными тестами, не расходуя GitHub Actions до общего QA.
- **Изменения:** локальный `scripts/run_local_lua_regression.sh` запускает синтаксис Lua всего KordRotation/tests и 11 mock-сценариев; поддерживает точечный запуск выбранных файлов. `scripts/check_lua_syntax.lua` компилирует без исполнения. Расширены `docs/rotation/Test_Matrix.md` и `docs/STAGE_02_08_ROTATION_ENGINE.md`.
- **Фактические проверки:** `texlua` локально: 20/20 observer assertions PASS. Локальные исходники observer и test хешированы через `git hash-object` и побайтно совпали с опубликованными GitHub blob SHA `c8ef6ac3` и `3e1fe9ff`. `bash -n` runner PASS, точечный runner observer PASS. Статическая проверка TOC порядка и 6 словарей присутствуют, ручной workflow содержит 11 suite, push trigger отсутствует. Полный 11-suite локально NOT RUN; GitHub Actions CI NOT RUN; WoW Forever NOT RUN.
- **Открыто:** полная интеграционная регрессия, API matrix #20, DevTools (ещё не создан), пилот BM Leveling PvE 1–59, WoW Forever QA. Не объявлять их DONE и не переносить старый PASS.
- **Сохранено:** 2 аддона/одно ядро, шесть UI локалей, Hunter приоритеты, Secret fail-closed, user-only UI без recorder.

## KR-20261121-045 — 2.8.6d: read-only CoreObservation contract для будущего DevTools
- **Дата/зона:** 2026-11-21 UTC. **Задача:** подготовить наблюдаемую границу ядра до создания отдельного KordRotationDevTools, не добавляя runtime logger, Recorder или SavedVariables в пользовательскую сборку.
- **Изменено:** новый `Core/CoreObservation.lua` (pull-only `Read()`, scalar-only version/status/engineReason/stateRevision/eventListenerErrors/bindingDirty). Источники — только уже имеющиеся значения памяти, без `Evaluate/GetSnapshot/WoW API`. Secret/неизвестные значения и не-allowlist причины не экспортируются. TOC подключает модуль после Engine; mock проверяет отсутствие Spell ID, целей, ключей, мутаций и побочных вызовов. GitHub workflow включает 11-й mock-тест и остаётся manual-only.
- **Проверка:** код написан, локальное выполнение будет проверено в 2.8.6e; GitHub Actions CI NOT RUN намеренно; Forever NOT RUN.
- **Граница:** настоящий DevTools — второй аддон следующего этапа, без копирования ядра; v14/Hunter priorities/ранги не менялись.

## KR-20261121-044 — 2.8.6c: guarded SpellCatalogue integration
- **Дата/зона:** 2026-11-21 UTC. **Симптом:** до 2.8.6c движок сравнивал импортированные Spell Catalogue ID/texture до проверки `GameAPI:IsSafeValue`; защищённые поля могли вызвать исключение или ложный вывод.
- **Изменения:** `RotationEngine` вводит внутренний защищённый `safeValue`, использует его до проверки numeric ID и asset, исключает неготовые записи каталога по ID/known/name/texture. При READY Eligibility и неподтверждённой визуализации остаётся UNKNOWN, очередь пустая, менее приоритетные правила не раскрываются. Добавлены mock-кейсы SECRET ID, texture и name.
- **Проверка:** статический аудит и новые утверждения; локальные Lua assertions пока NOT RUN (проверить со всем ядром); CI NOT RUN по ручному workflow; WoW Forever NOT RUN. Не менялись ранги, Hunter, API v14, классовые профили, два аддона.
- **Дальше:** 2.8.6d observation surface, 2.8.6e локальная проверка, единый CI перед QA.

## KR-20261121-043 — 2.8.6b: contract mock для переходов состояния и биндов
- **Дата/зона:** 2026-11-21 UTC. **Причина:** тест 2.8.4d до 2.8.5b не передавал `spellID` от mock BindingResolver (современный контракт требует exact identity), что могло вызвать ложный FAIL; тесту не хватало переходов идентичности и восстановления bind.
- **Изменения:** mock BindingResolver теперь возвращает проверяемый Spell ID; добавлены UNKNOWN binding, чужой Spell ID, восстановление клавиши, смена специализации и восстановление прежнего профиля, проверка отсутствия лишнего чтения GameState при неподключённой специализации. Это интеграционный тест реальных Engine/Profile/Eligibility модулей с mock API.
- **Проверка:** локальный Lua runtime TEST NOT RUN до переноса всех реальных исходников в workspace; исходники/ожидаемые причины сверены; GitHub Actions CI NOT RUN по ручному режиму; WoW Forever NOT RUN.
- **Не меняет:** production ротаций, приоритеты Hunter, API v14, два аддона. Открыто 2.8.6c–e и #20.

## KR-20261121-042 — 2.8.6a: аудит цепочки канонического ядра
- **Дата/зона:** 2026-11-21 UTC. **Симптом:** перед общей интеграцией отсутствовала единая текущая карта границ и доказательств 2.8.6.
- **Изменено:** добавлен `docs/rotation/Engine_Integration_Audit_2_8_6.md` с первоисточниками Sonah/MaxDps/JustAC/ForeverAuras/ForeverRotation/RotationGuide, контрактом API→UI, рисками, критериями и порядком тестов.
- **Проверка:** исходниковый аудит; Lua не менялся; локальный Lua тест NOT RUN, GitHub Actions CI NOT RUN (выполнить один раз перед общим QA), WoW Forever NOT RUN.
- **Открыто:** 2.8.6b–e, #20 highest rank, DevTools, клиентский тест, performance.

## KR-20261121-041 — 2.8.5 performance guard на EventBus refresh
- **Дата/зона:** 2026-11-21 UTC. **Причина:** подписки на 12 каналов могли вызывать Refresh в установке без зарегистрированных классовых профилей; это ненужная нагрузка.
- **Решение:** callback игнорирует тестовый режим и отсутствие игрового профиля, если нет ранее показанного production icon; при активном профиле и при необходимой очистке Refresh сохраняется. Не вводится новый OnUpdate, используются существующие каналы EventBus.
- **Статусы:** текстовая проверка контракта и Git HEAD; локальный Lua mock NOT RUN; GitHub Actions CI NOT RUN по решению заказчика; игровая нагрузка и QA NOT RUN. Прочие требования 2.8.5a–e сохраняются.

## KR-20261121-040 — 2.8.5 defensive follow-up: guarded UI/binding reads
- **Дата/зона:** 2026-11-21 UTC. **Причина:** дополнительные пограничные проверки 2.8.5 выявили, что доступ к полям потенциально защищённой структуры после успешного Resolve/Engine Evaluate оставался вне pcall.
- **Изменено:** `RotationDisplay` защищает получение метаданных и валидацию queue через pcall; `RotationEngine` защищает проверку статуса/ID/label результата BindingResolver. При исключении метаданные UNKNOWN и клавиша не отображается; остальные уже подтверждённые рекомендации не теряются. Нет новых API или обхода Secret.
- **Проверка:** статическая инспекция; локальное выполнение тестов NOT RUN, GitHub Actions CI NOT RUN (ручной режим), игровой QA NOT RUN. Все mock проверки запускаются совместно перед QA.
- **Сохранены:** v14, Hunter priorities, два аддона, прежний UI/тексты на шести языках и запрет автокаста.

## KR-20261121-039 — fix: корректный mock отключённого профиля
- **Дата/зона:** 2026-11-21 UTC. **Причина:** первичная фикстура теста UI возвращала READY из заглушки движка даже при `active=false` или `registered=false`, что не соответствует настоящему RotationEngine и давало бы ложный FAIL.
- **Изменения:** mock Evaluate возвращает UNKNOWN/пустую очередь при выключенном, отсутствующем или невыбранном профиле; тесты проверяют именно очистку `RotationDisplay`, а не противоречивую фикстуру. Production Lua не изменён.
- **Проверки:** статическая инспекция фикстуры; LOCAL RUN NOT RUN, CI NOT RUN согласно решению заказчика, игровой QA NOT RUN. Test Matrix без ложного PASS.
- **Сохранено:** ручной workflow_dispatch, v14, два аддона, ранги, Hunter priorities.

## KR-20261121-038 — 2.8.5e: UI mock регрессия и план QA
- **Дата/зона:** 2026-11-21 UTC. **Причина:** укреплённый UI/Binding/EventBus требует воспроизводимой проверки без расходования GitHub Actions на каждый коммит.
- **Изменения:** самостоятельный mock `stage_02_08_v14_display.lua` проверяет реальные методы RotationDisplay на подставных UI кадрах, bad payload, пустую очередь, refresh bindings/cooldowns, отключение/удаление профиля, скрытие панели и TEST-режим. Десятый набор включён в `lua-regression.yml` с сохранённым `workflow_dispatch`. Добавлены сценарии Test_Matrix и техдокументация 2.8.
- **Результаты:** исходники записаны, локальное исполнение NOT RUN, GitHub Actions специально NOT RUN, клиент/CPU/FPS NOT RUN. Старые PASS 2.8.4 не переносятся на этот SHA.
- **Без изменений:** ранги, приоритеты Hunter, GameData v14, два аддона, локализованные тексты, TOC, автокаст.

## KR-20261121-037 — 2.8.5d: очистка stale-индикатора при отключении профиля
- **Дата/зона:** 2026-11-21 UTC. **Симптом:** старый OnUpdate прекращал опрос, если профиль отключался или пропадал, но не гарантировал очищение уже показанной рекомендации.
- **Ожидаемое и изменение:** активные профили остаются на ограниченном опросе 0,4 с, а при отсутствии/отключении зарегистрированного профиля или скрытой панели запускается единственная очистка только если `productionReady` ранее был true. Изолированный testMode не затрагивается. При UNKNOWN/BLOCKED действующий Refresh сбрасывает основной и 2–5 слоты, скрывает панель.
- **Проверки:** источник изучен, сценарий будет охвачен интеграционным UI mock. LOCAL NOT RUN, CI NOT RUN, WoW Forever NOT RUN. Без новых API, шести UI-текстов, изменений приоритетов или рангов.

## KR-20261121-036 — 2.8.5c: EventBus invalidation to RotationDisplay
- **Дата/зона:** 2026-11-21 UTC. **Решение:** согласованный 2.8.5a–e. **Проблема:** релевантные события обновляли внутренние версии модулей, но UI мог ждать периодического опроса.
- **Изменение:** подписки RotationDisplay на уже существующие объединённые каналы EventBus: bindings, actionbar, spellbook, identity, talents, target, cooldowns, resources, cast, combat, pet, auras. Через EventBus:Flush происходит один ограниченный callback на канал; сохраняется 0,4-секундный fallback и отсутствие фонового оценивания без профиля. Состав API не расширялся.
- **Проверки:** source review; интеграционные тесты готовятся в 2.8.5e. LOCAL RUN NOT RUN; CI NOT RUN по утверждённой экономии Actions; game QA NOT RUN.
- **Риски:** количество Refresh при событийном потоке ограничено коалесцированием EventBus, точная нагрузка на игровом клиенте НЕ ИЗМЕРЕНА.

## KR-20261121-035 — fix: verify binding identity and label (2.8.5b)
- **Дата/зона:** 2026-11-21 UTC. **Подэтап:** утверждённый 2.8.5. **Исходная проблема:** раньше любой READY bindingLabel принимался даже при несовпадающем Spell ID или пустой строке; теперь подпись отображается только при подтверждённом соответствии.
- **Изменения:** KordRotation/Core/RotationEngine.lua, tests/stage_02_08_rotation_engine.lua. Защищённые данные не декодируются, лишних зависимостей нет. Приоритеты Hunter, ранги, 2 аддона не изменены.
- **Проверка:** код и новые сценарии внесены; локальный тест при невозможности исполнения LOCAL NOT RUN; GitHub Actions намеренно CI NOT RUN; игра NOT RUN. Итоговый CI — единовременно перед общим QA.

## KR-20261121-034 — feat: validate production recommendation payload (2.8.5a)
- **Дата и зона:** 2026-11-21 UTC. **Утверждение:** 2.8.5a–e одобрены заказчиком.
- **Причина/ожидаемое:** непроверенные или повреждённые engine queue/Spell ID/texture/name раньше могли пройти слабую проверку рабочего UI; теперь они дают пустую рекомендацию.
- **Фактические изменения:** KordRotation/UI/RotationDisplay.lua. Без новых API, без изменения Hunter, без автокаста и без модификации двухаддонной архитектуры.
- **Проверки:** исходники и контракты просмотрены; тестовый код накапливается. LOCAL RUN NOT RUN для этого коммита; GitHub Actions намеренно CI NOT RUN (ручной режим до общего QA); WoW Forever NOT RUN.
- **Открыто:** оставшиеся подпункты 2.8.5, 2.8.6, v14 #20, игровой QA и производительность.

## KR-20261121-033 — ручной CI по решению заказчика
- **Дата/зона:** 2026-11-21 UTC. **Причина:** автоматические прогоны после каждого Lua-коммита расходуют лимит GitHub Actions; заказчик потребовал накопить тесты и запустить их один раз перед общим QA.
- **Изменено:** `.github/workflows/lua-regression.yml` переведён только на `workflow_dispatch`; удалён `push` trigger. В `AGENTS.md` закреплены отдельные статусы локальных проверок и CI и запрет запускать CI до итогового QA без отдельного согласования.
- **Проверка:** сверка конфигурации по тексту; GitHub Actions намеренно **NOT RUN** для этой записи. Изменений Lua/TOC/UI/ротаций нет. Ранее зафиксированные CI PASS относятся только к прежним SHA.
- **Следующий шаг:** накапливать тесты для 2.8.5 и 2.8.6 без автоматического CI.

## KR-20261121-032 — подтверждение итогового CI этапа 2.8.4a–d
- **Дата/зона:** 2026-11-21 UTC. **Тип:** documentation evidence, Lua/TOC/UI не изменяются.
- **Проверенный источник:** [GitHub Actions run 44888049693](https://github.com/Vi22Rus/Kord/actions/runs/44888049693), SHA `28104bbb9920fdba46170426e8c6eb621a243b17`, job `136797558374`, completed/success. Проверка синтаксиса всех Lua через luac5.1 PASS. **Девять из девяти mock suites PASS**: Stage 2.3 GameState, 2.4 SpellCatalogue, 2.5 ActionBar, 2.6 Bindings (25), Eligibility (57), RotationEngine (38), v14 GameState (31), v14 argument guards (26), v14 real-module integration (28). Лог получен непосредственно из job.
- **Документы:** зафиксированы действующий 2.8.4 контракт, перечень разрешённых boolean GameData requirements, критерии UNKNOWN/BLOCKED, новый integration test и точные результаты в Test Matrix и Stage 2.8.
- **Не выполнено:** клиентский тест WoW Forever, проверка максимального изученного ранга v14 #20, FPS/RAM, все будущие игровые профили; не считать mock PASS игровым PASS.

## KR-20261121-031 — 2.8.4d: интеграционная Lua mock-регрессия
- **Дата/зона:** 2026-11-21 UTC. **Статус:** CI pending; WoW Forever NOT RUN.
- **Проблема:** только изолированные тесты контрактов не подтверждали цепочку настоящих RotationProfiles→RotationEngine→AbilityEligibility.
- **Изменения:** новый тест `tests/stage_02_08_v14_rotation_contract.lua` загружает все три реальные Lua-модуля с mock GameAPI/GameState; проверяет readiness, fallback при BLOCKED, остановку при UNKNOWN, GCD, отсутствие цели, недоступность способности, контекст и исключение GetSnapshot. Workflow выполняет девять Lua mock-наборов. Матрица тестов дополнена явными PENDING/NOT RUN.
- **Референсы и контракт:** Sonah/MaxDps/JustAC/ForeverRotation/ForeverAuras/RotationGuide, v14; не меняет Hunter priorities, ранги, API, архитектуру двух пакетов или production-профили. Игровой тест и #20 НЕ выполнены.
- **Проверка:** требуются завершённый CI SHA и лог; PASS здесь заранее не заявлен.

## KR-20261121-030 — 2.8.4c: fail-closed результат Eligibility
- **Дата/зона:** 2026-11-21 UTC. **Статус:** IMPLEMENTED / CI pending / WoW Forever NOT RUN.
- **Проблема:** нераспознанный статус Eligibility мог быть пропущен подобно BLOCKED; ответ с чужим spellID мог сформировать рекомендацию для неправильной способности.
- **Решение:** допускаются только READY/BLOCKED/UNKNOWN, у каждого ответа spellID должен точно совпадать с проверяемым правилом; любые прочие ответы становятся UNKNOWN и блокируют переход к менее приоритетным. Порядок правил, ST/AoE, ранги, Hunter priorities, два пакета не изменены.
- **Тест:** stage_02_08_rotation_engine.lua: неожиданный status и несовпадающий spellID; остальные регрессии без изменения. GitHub Actions требуется подтвердить; in-game NOT RUN.
- **Открыто:** 2.8.4d, максимальный изученный ранг #20, игра, FPS/RAM.

## KR-20261121-029 — 2.8.4b: проверяемые GameData requirements
- **Дата/зона:** 2026-11-21 UTC. **Статус:** IMPLEMENTED / CI pending / game NOT RUN. 2.8.4a PASS: [run 44887845208](https://github.com/Vi22Rus/Kord/actions/runs/44887845208), SHA 98e76571.
- **Проблема:** без декларативного контракта будущие профили могли бы вызывать произвольные ключи GameData или превращать неизвестное состояние в false.
- **Решение:** необязательный список до 8 проверяемых boolean-требований на правило, строго из уже реализованных player.moving, target.isPlayer, pet.exists, pet.dead, context.inGroup/inRaid/inInstance. Отсутствие/Secret/не-boolean/status не READY = UNKNOWN; явное несовпадение = BLOCKED. Профиль копирует вложенные требования; неизвестные имена/дубли отвергаются.
- **Файлы:** RotationProfiles.lua, RotationEngine.lua, stage_02_08_rotation_engine.lua; новые зависимости отсутствуют, действующие правила без requires неизменны; игровые профили по-прежнему не зарегистрированы. Ранг #20 и Hunter priorities не менялись.
- **Тест:** mock на неверное поле, UNKNOWN и несовпадение; CI пока NOT RUN, игра NOT RUN. Дальше 2.8.4c–d.

## KR-20261121-028 — 2.8.4a: единый снимок GameState
- **Дата/зона:** 2026-11-21 UTC. **Статус:** IMPLEMENTED / CI pending / game NOT RUN. Решение: заказчик утвердил 2.8.4a–d.
- **Симптом и причина:** движок не закреплял один снимок и Eligibility перечитывал GameState для каждого кандидата. Ожидаем единое согласованное состояние на проход.
- **Изменения:** защищённый единичный GetSnapshot после выбора правил, UNKNOWN при отсутствии/повреждении, передача snapshot в Eligibility, прямой вызов Eligibility сохраняет старый путь. Не требуется глобальный status READY, не добавлены WoW API, профили, ранги, приоритеты и зависимости.
- **Сверка:** Sonah/Core/Organisms/Engine.lua BuildContext/Secret.BeginEpoch; MaxDps/Core.lua; JustAC/RotationImport.lua; ForeverRotation/Engine.lua; RotationGuide/Core/State.lua; ForeverAuras/SpellCooldown.lua.
- **Проверки:** stage_02_08_rotation_engine.lua дополнен проверками общего snapshot/одного чтения/отсутствия; GitHub Actions pending; игровой тест NOT RUN. **Открыто:** 2.8.4b–d, highest rank #20, WoW Forever, FPS/RAM.

## KR-20261121-027 — доказанный CI PASS 2.8.3e: GCD и заряды
- **Дата UTC:** 2026-11-21T08:58:19.274Z. **Тип:** docs/test evidence, без изменения Lua, TOC и ротаций.
- **FAIL evidence:** GitHub Actions [run 44887103080](https://github.com/Vi22Rus/Kord/actions/runs/44887103080), SHA `05ffac3283332fae3474065be91cc509b1aa7b88`, FAILURE из-за неверного тестового выражения Lua 5.1 `condition and nil or value` (mock не моделировал отсутствие поля).
- **PASS evidence:** GitHub Actions [run 44887247067](https://github.com/Vi22Rus/Kord/actions/runs/44887247067), SHA `aff9473fafadb3039a6bc229ec1cb66e55c8d951`, job `136795100392`, completed/success. По фактическому логу: luac5.1 -p PASS; все 8 Lua mock suites PASS; Eligibility **57 checks**, GameState v14 31 assertions, protected args 26, RotationEngine 29.
- **Контракт:** 4 кейса ELIG-CHARGE-002..004 и ELIG-GCD-004 помечены с конкретным PASS CI SHA; rank #20 и все тесты игрового клиента остаются NOT RUN. Ни один CI PASS не является CLIENT PASS.
- **Далее:** остальные вопросы 2.8.3 и переход к 2.8.4 RotationEngine по согласованному отдельному проектированию; DevTools и BM Hunter 1–59 ещё впереди.

## KR-20261121-026 — исправлен тестовый mock для отсутствующих полей зарядов
- **Дата UTC:** 2026-11-21T08:56:53.887Z. **FAIL evidence:** [GitHub Actions run 44887103080](https://github.com/Vi22Rus/Kord/actions/runs/44887103080), SHA `05ffac3283332fae3474065be91cc509b1aa7b88`: syntax PASS, mock suite остановился на `tests/stage_02_07_eligibility.lua:120`, `missing currentCharges got READY expected UNKNOWN`. Не игнорировать этот FAILED run.
- **Причина:** тестовая формула `missingChargeCount and nil or chargeCount` в Lua 5.1 не умеет создавать условное nil: выражение возвращает резервный chargeCount. Аналогичная ошибка была для maxCharges. **Это тестовая фикстура**, а не доказательство ошибки `AbilityEligibility`.
- **Изменения:** в `tests/stage_02_07_eligibility.lua` mock `C_Spell.GetSpellCharges` теперь строит структуру с явными присваиваниями только известных полей. Источники ядра, приоритеты Hunter, TOC, UI и каноническая матрица v14 не меняются.
- **Проверки:** требуется следующий confirmed CI PASS; игровой WoW Forever NOT RUN. Остальные новые кейсы уже включены в Test_Matrix, статусы PENDING до нового прогона.

## KR-20261121-025 — 2.8.3e: строгие заряды и GCD, пограничная регрессия
- **Дата UTC:** 2026-11-21T08:54:49.504Z. **Решение:** согласованный продолжением вариант 2.8.3e; референсы `Sonah/Core/Atoms/Spells.lua` (GetSpellCharges и GCD), `JustAC/BlizzardAPI/CooldownTracking.lua`, MaxDps (Cooldowns.lua, SpellData.lua). Канон — матрица v14 #25/#26/#80/#83.
- **Дефект/риск:** логическая путаница `isActive` у зарядов (recharge ≠ count), а также неявное принятие неполных ответов GCD как подтверждённой готовности. Рефакторинг сохраняет fail-closed и делает семантику явной.
- **Изменено:** `AbilityEligibility` раздельно требует доступные finite integer current/max, не выводит count из recharge.isActive; GCD принимает только доступный boolean isActive, не выводит его из `isOnGCD`/secret timing. В `tests/stage_02_07_eligibility.lua` добавлены кейсы recharge при 0/1, отсутствующие поля, дроби, превышения max, отсутствие GCD isActive. Обновлены GameData_Contract и Test_Matrix; состав API и Hunter профили не менялись.
- **Проверки:** CI Lua 5.1 на точном SHA после коммита; **игра WoW Forever NOT RUN**; алгоритм highest known rank #20 остаётся открытым, CLIENT PASS 0/101.

## KR-20261121-024 — подтверждена регрессия уровня 2.8.3d
- **Дата UTC:** 2026-11-21T08:48:33.763Z. **Тип:** docs/test evidence, без изменения Lua, профилей или .toc.
- **Проверенный результат:** [GitHub Actions run 44886522419](https://github.com/Vi22Rus/Kord/actions/runs/44886522419), SHA `5ac5d0fee8805d0b6f0054cbb28e9dbdc1341ac8`, completed/success, job 136792876252. Проверены job logs: `luac5.1 -p` PASS по Lua; **8/8** mock suites PASS; `AbilityEligibility` **47 checks**, `GameState v14` 31, secret input guards 26, `RotationEngine` 29. Новые minLevel 4 сценария помечены PASSED CI в Test_Matrix.
- **Не подтверждено:** клиент WoW Forever; правильность выбора highest learned rank v14 #20; корректность v14 всех 101 API capabilities в игре. CLIENT PASS=0/101, соответствующие строки NOT RUN.
- **Далее:** продолжить проверку v14 GCD/charges и явно открытых rank-проверок; затем согласованный переход к ядру Engine 2.8.4, DevTools и Hunter BM 1–59 без изменения приоритетов.

## KR-20261121-023 — 2.8.3d: строгая минимальная граница уровня в Eligibility
- **Дата UTC:** 2026-11-21T08:47:16.138Z. **Источник:** Canonical API Matrix v14 #20/#80/#82, Sonah/Core/Atoms/Spells.lua:68–94,171–189 и MaxDps/SpellData.lua (сверка источников). **Согласование:** утверждённый пользовательский план переработки ядра v14.
- **Проблема:** известность заклинания не доказывает подходящий уровень персонажа или выбранный ранг. Прежний Eligibility не имел явного контракта минимального уровня, а открытый вопрос рангов нельзя скрыть под `known=true`.
- **Исправление:** в `AbilityEligibility:Evaluate(id,options)` добавлена только **опциональная** `minLevel` — обычное целое 1–100; Secret policy проверяется до сравнений; подтверждённый уровень ниже порога блокируется; неизвестный уровень даёт UNKNOWN. Без `minLevel` старые правила сохраняют прежнюю проверку. Изменены `tests/stage_02_07_eligibility.lua`, GameData_Contract и Test_Matrix.
- **Открытый вопрос:** высший ранг и spell variants v14 #20 НЕ реализованы, нельзя выводить rank по имени или наличию ID; тесты в клиенте WoW Forever NOT RUN. Приоритеты Hunter, UI, TOC не менялись.
- **Проверка:** новый код должен быть испытан в GitHub Actions на exact SHA; до подтверждения CI mock-прогоны имеют PENDING, game CLIENT PASS по-прежнему 0/101.

## KR-20261121-022 — подтверждённый CI PASS 2.8.3c (protected policy, secret/nil)
- **Дата UTC:** 2026-11-21T08:44:31.052Z. **Тип:** docs/test evidence; игровые модули и .toc не менялись.
- **Фактический тест:** GitHub Actions [run 44886222396](https://github.com/Vi22Rus/Kord/actions/runs/44886222396), исходный commit `120c8040b139c81831a792d423fc0c8bdf16024f`, job `136791978814`, completed SUCCESS. Проверены logs, не только workflow-config: Lua 5.1 syntax PASS, 8/8 Lua mock suites PASS; Eligibility 38 checks, GameState v14 31, protected args 26, RotationEngine 29.
- **Исправление документации:** Test_Matrix фиксирует PASS для пяти новых ELIG-SEC/CHARGE/USABLE/RANGE сценариев и точный SHA. **In-game NOT RUN:** реальный клиент WoW Forever, 101 API матрицы не объявлены клиентски проверенными.
- **Следующая работа:** 2.8.3d remaining rank/level policy and cooldown/charges context; далее 2.8.4 RotationEngine; пользовательский и диагностический аддоны остаются отдельными поставками с единым ядром.

## KR-20261121-021 — 2.8.3c: protected policy/ID output and nil/secret eligibility regression
- **Дата UTC:** 2026-11-21T08:43:30.557Z; **подэтап:** 2.8.3c Canonical API Matrix v14 #10,#21,#26,#52,#80. Одобрение: каноническое ядро без runtime-адаптеров старых ротаций.
- **Проблема:** при invalid/Secret ID Evaluate мог возвращать исходный защищённый id в result.spellID; developer-трассировка могла попытаться сериализовать его. Policy table и поля опций сравнивались без секретной защиты. Не хватало исполняемых сценариев protected currentCharges, nil/secret usability, nil range.
- **Изменения:** выход candidate всегда содержит только проверенный finite positive SpellID либо nil; Evaluate проверяет безопасность policy table/fields до индексирования/сравнения и отклоняет unknown. Расширено `tests/stage_02_07_eligibility.lua` сценариями secret-ID/secret-options, защищённых зарядов и unavailable usability/range. Обновлены Test_Matrix/GameData_Contract.
- **Ограничение:** GameAPI, Hunter-приоритеты, .toc, старые классовые профили не изменены. 101 game CLIENT PASS по-прежнему 0; Lua CI требует выполнения на SHA нового коммита. До реальной CI проверки не ставить PASS.
- **Следующее:** проверить GitHub Actions, зафиксировать evidence; затем продолжить Eligibility v14 #20/#26 и перейти к Engine 2.8.4 после подтверждения контрактов.

## KR-20261121-020 — зафиксирован CI PASS 2.8.3b (SpellKnown и secret ID)
- **Дата UTC:** 2026-11-21T08:40:55.294Z. **Тип:** docs/test-evidence, код и .toc не менялись.
- **Проверенный SHA:** `ebcaa131367d80a827619e909228e7b7bf8a7d68`. GitHub Actions [run 44885927707](https://github.com/Vi22Rus/Kord/actions/runs/44885927707) — completed SUCCESS. Считан job log: luac5.1 -p PASS; все 8 Lua mock suites PASS; Eligibility = 29 checks (включая known fallback, negative, API absent и protected ID), GameState v14 =31, secret input=26, Engine=29.
- **Исправлено:** Test_Matrix ранее имела PENDING run; теперь статусы пяти новых сценариев привязаны к конкретному подтверждённому SHA. Список ограничений: игровые тесты, ранги/варианты spell, полная v14 интеграция и другие 101 capabilities НЕ закрыты.
- **Дальше:** 2.8.3c остальные eligibility ветки и далее 2.8.4; сохранять неизменными приоритеты Hunter и разделение двух аддонов.

## KR-20261121-019 — 2.8.3b: known spell без ложного отрицания; secret Spell ID
- **Дата UTC:** 2026-11-21T08:39:33.703Z. **Этап:** Canonical API Matrix v14 #19/#80/#81, AbilityEligibility, без изменения .toc.
- **Источники:** Sonah/Core/Atoms/Spells.lua известность пассивных/талантовых заклинаний через C_SpellBook.IsSpellKnown (Player bank); сверено с MaxDps/SpellData.lua и v14. Матрица остаётся единственным authority по выбранному API; client test NOT RUN.
- **Дефект:** при отсутствии в локальных entries любой ID считался not_learned, хотя это не доказывает неизвестность способности. Кроме того validID делал math.floor/comparison до проверки секретности ID.
- **Исправление:** добавлена прямая spellKnown-проверка в Eligibility: запись known=true принимается; иначе C_SpellBook.IsSpellKnown(ID, Enum.SpellBookSpellBank.Player), явное false=BLOCKED, невозможность проверить=UNKNOWN. validID защищает ID через GameAPI:IsSafeValue до арифметики. Никаких alias-адаптеров классовых ротаций. Тест 2.7 расширен проверками known positive/negative/absent и protected ID; матрица тестов и GameData Contract актуализированы.
- **Проверка:** обязательный GitHub Actions mock после публикации, отчёт отдельно; игровой Forever NOT RUN. **Ограничение:** поведение высших рангов, spell variants и talent-правил проверяется отдельно; ложного CLIENT PASS нет.

## KR-20261121-018 — зафиксирован подтверждённый CI PASS этапа 2.8.3a
- **Дата UTC:** 2026-11-21T08:35:26.552Z. **Тип:** docs/test evidence, без изменения кода/TOC/профилей/сборки.
- **Доказательство:** GitHub Actions [run 44885528119](https://github.com/Vi22Rus/Kord/actions/runs/44885528119), head SHA `0eec94612ad106cb3ba7eb57f758180adc33eccb`, completed/success; syntax Lua 5.1 PASS; все 8 mock suites PASS. Eligibility 25 checks (включая 2 новых по isOnGCD), GameState v14 31 assertions, secret inputs 26 assertions, RotationEngine 29 assertions. Записано из фактического job log.
- **Причина:** после завершения CI новые кейсы ELIG-083 в Test Matrix ещё имели статус ожидания, что противоречило уже полученным доказательствам. **Исправление:** `docs/rotation/Test_Matrix.md` ссылается на проверенный запуск и SHA; **In-game NOT RUN**, 101 Client PASS не присваиваются.
- **Следующий подэтап:** 2.8.3 — дальнейшая проверка eligibility по v14 (spellbook, ранги, заряды, ресурсы, range/cast), затем 2.8.4 engine. Боевая логика Hunter не изменена.

## KR-20261121-017 — 2.8.3a: запрет неавторизованного isOnGCD в Eligibility + подтверждение CI
- **Дата UTC:** 2026-11-21T08:34:22.591Z. **Исходный SHA:** e6a7de617126e0e02a1282d36c173c731507ee02. **Область:** AbilityEligibility и регрессия; **версия .toc:** не менялась, стадия 2.8.3a.
- **Результат проверки предыдущего коммита:** GitHub Actions run 44885160182, commit e6a7de617126e0e02a1282d36c173c731507ee02, завершился SUCCESS 2026-11-21 08:30 UTC, все 8 mock suites и luac5.1 syntax PASS; Games CLIENT PASS=0, NOT RUN. Получен полный job log, а не предположение по наличию workflow.
- **Первопричина:** исходный cooldown() в AbilityEligibility мог вернуть READY при isActive=true и isOnGCD=true в обычном snapshot-poll, хотя утверждённая матрица v14 #83 позволяет доверять isOnGCD только во время SPELL_UPDATE_COOLDOWN. Это противоречило канонической семантике и было риском ложного READY.
- **Исправление:** активный cooldown не классифицировать по isOnGCD вне события: возвращать BLOCKED/cooldown_active_unclassified, никогда READY по этому признаку; inactive остаётся READY; secret/unknown не конвертировать. Обновлён тест stage_02_07_eligibility.lua (проверка active+isOnGCD=true) и Test_Matrix/GameData_Contract. Hunter-профили, ST/AoE, GCD-отдельный метод и привязки клавиш не менялись.
- **Проверка новой ревизии:** в следующем CI зафиксировать результат после публикации; статическая сверка source+tests; WoW Forever NOT RUN. **Открытый вопрос:** точная классификация shared vs GCD только с доказанным event-scoped наблюдением и игровым тестом; остальные v14 методы и полный новый Engine не объявлять завершёнными.

## KR-20261121-016 — 2.8.2e: обработка secret-аргументов до сравнений
- **Дата UTC:** 2026-11-21T08:29:48.587Z. **Основание:** Canonical API Matrix v14 #24/#80, решение о чистом ядре и отдельном DevTools.
- **Выявленный дефект:** guard в ReadPowerPercent/ReadHealthPercent/ReadAutoShot выполнял сравнения/математику над потенциально secret аргументами до проверки `GameAPI:IsSafeValue`. Это могло дать Lua error вместо консервативного UNKNOWN.
- **Изменение:** в GameAPI ReadHealthPercent/ReadPowerPercent входные unit/curve/powerType проверяются через IsSafeValue первыми; GameState ReadAutoShot проверяет spellID до math.floor/comparison; результат и сигнатуры старых методов не меняются. Добавлен `tests/stage_02_08_v14_argument_guards.lua`, CI workflow запускает 8 test suite на каждом изменении Lua. Hunter и UI не меняются.
- **Проверки:** текстовые проверки опубликованного GitHub, проверка структуры YAML и статусов; **Lua-тесты NOT RUN без подтверждённого CI**, клиентский QA NOT RUN. Не считать mock-изображения Secret полноценным тестом реального WoW.
- **Следующий шаг:** дождаться подтверждённого CI/разобрать провалы, закончить 2.8.2, затем перейти к AbilityEligibility 2.8.3.

## KR-20261121-015 — исправление синтаксического шага CI
- **Дата UTC:** 2026-11-21T08:25:57.399Z. **Проблема:** первоначальная команда `lua -e ... file` могла выполнить файл, а не только проверить синтаксис. **Исправление:** `luac5.1 -p "$f"` для syntax-only; исполняемые тесты остаются отдельно под явным шагом run.
- **Проверка:** опубликованный YAML и фактический job статус проверяются отдельно; клиентский тест NOT RUN. Изменены только CI YAML и CHANGELOG, профиль Hunter не тронут.

## KR-20261121-014 — воспроизводимые Lua-тесты опубликованного ядра v14
- **Дата UTC:** 2026-11-21T08:25:23.503Z. **Основание:** утверждённая разработка ядра по v14 и требование реальной регрессии.
- **Проблема:** предыдущие проверки GameState/v14 были только статическими, локальная среда не может скачать точный GitHub snapshot; заявлять 31/31 PASS без исполнения недопустимо.
- **Решение:** добавить GitHub Actions workflow с read-only checkout точного push SHA, установкой Lua 5.1, синтаксическим прогоном модулей и исполнением 7 существующих Lua mock suite. Ключевой v14 suite: `tests/stage_02_08_v14_state.lua`. Он не делает игровых действий, не меняет классовые профили и не создаёт адаптеров.
- **Изменения:** `.github/workflows/lua-regression.yml`, `docs/rotation/Test_Matrix.md`; только CI и docs, без правок Lua/TOC/версии.
- **Проверка:** GitHub workflow/correct trigger/status после публикации; **NOT RUN**, пока job не исполнен. **WoW Forever client QA = NOT RUN**. Если runner/permission недоступны, зафиксировать блокер вместо ложного PASS.
- **Дальше:** закрыть обнаруженные тестами дефекты 2.8.2, затем AbilityEligibility v14.

## KR-20261121-013 — 2.8.2d: исправление достоверности context/threat и Lua-регрессия
- **Дата UTC:** 2026-11-21T08:09:01.721Z. **Область:** каноническое ядро v14, GameState; **статус:** исходники, клиент NOT RUN.
- **Причины:** (1) context.status мог оказаться READY при unknown instanceType; (2) threat считывался как finite число 0..3 без проверки целочисленности, хотя UnitThreatSituation имеет дискретный контракт уровней 0–3.
- **Исправления:** context.status включает instanceType; target.threat требует integer 0..3, иначе UNKNOWN c reason=threat_level_invalid. Добавлен `tests/stage_02_08_v14_state.lua`: сценарии nil, secret, missing Curve, API ERROR, pet state, Auto Shot, context, threat; обновлены GameData_Contract и Test_Matrix.
- **Проверено:** синтаксис теста локально через `texluac -p`; опубликованный Git HEAD/изменения проверяются отдельно. **NOT RUN:** полное исполнение теста с реальными GameAPI/GameState/EventBus из коммита, игровой WoW Forever. Отсутствие ошибок синтаксиса не равно успешной интеграции. Никаких изменений приоритетов Hunter и временных адаптеров нет.
- **Следующий шаг:** запустить полный Lua suite на точном snapshot GitHub, закрыть оставшиеся изъяны 2.8.2, затем 2.8.3 AbilityEligibility.

## KR-20261121-012 — v14 2.8.2c: строгое чтение процентов здоровья и ресурса
- **Дата UTC:** 2026-11-21T08:06:01.625Z. **Тип:** feature/docs; подэтап 2.8.2c, версия .toc не изменена. **Согласование:** пользователь одобрил переработку всего ядра по v14.
- **Симптом:** в GameState процент здоровья/ресурса может быть неизвестен, когда UnitHealth/UnitPower дают защищённые значения. Нельзя компенсировать это несуществующей гарантией числовой Curve.
- **Изменения:** GameAPI read-only allowlist расширен UnitHealthPercent и UnitPowerPercent по v14 #3–6/#41/#49–51, но добавлены только явные методы ReadHealthPercent/ReadPowerPercent с обязательным безопасным Curve, unit/power validation, валидностью plain numeric 0..100. GameState делегирует эти прямые контракты без адаптеров старых профилей. Обновлены GameData_Contract и Test_Matrix.
- **Ограничения:** ни Curve-object provider, ни дискретные 5%-интервалы не объявлены готовыми; вызывающий должен передать реально допустимый Curve. Secret/nil/error не является 0/100. Нельзя использовать функции для обхода защищённых условий.
- **Проверки:** статическая сверка источников и published tree проводится отдельно; Lua runtime/тест в WoW Forever в этом коммите **NOT RUN**. Варианты сценариев добавлены в Test Matrix для последующего исполняемого теста. Следующее — общий исполняемый тест 2.8.2 и расширение GameData.

## KR-20261121-011 — 2.8.2b: прямые pet/instance/Auto Shot контракты v14
- **Дата UTC:** 2026-11-21T08:03:36.258Z. **Согласование:** пользователь одобрил полную переработку v14, отдельный DevTools, отсутствие runtime-адаптеров. **Тип:** feature/docs, без изменения версии и Hunter-профилей.
- **Проблема:** GameState pet не имел отношения pettarget→target; EventBus исключал pet unit-события; IsInInstance не различает тип инстанса; для Auto Shot не было отдельного read-only сигнала.
- **Изменения:** GameState добавляет pet.targetExists, pet.attackingTarget по v14 #30 с fail-closed, context.instanceType из второго ответа GetInstanceInfo по #18/#90/#91, ReadAutoShot(spellID) отдельно для #24 без предположений swing/queued; EventBus добавляет pet domain/UNIT_PET/PET_BAR_UPDATE и принимает pet/pettarget unit events. Обновлены GameData_Contract и Test_Matrix.
- **Проверки:** контроль синтаксиса Lua, опубликованного Git HEAD и структуры кода проводится отдельно. **NOT RUN:** WoW Forever, полный mock реальных зависимостей, измерения производительности. Наличие API ≠ CLIENT PASS.
- **Следующий шаг:** расширить типизированное безопасное чтение GameData, протестировать все новые случаи, затем продолжить Eligibility/Engine.

## KR-20261121-010 — 2.8.2a: прямые сигналы GameState и selected API v14
- **Дата (UTC):** 2026-11-21T08:00:31.642Z. **Статус:** исходниковая реализация; CLIENT QA NOT RUN. **Версия:** 0.1.8.3-rc9 (без смены релизного номера, подэтап незавершён).
- **Задача:** начать переписывание ядра под матрицу v14 без runtime-адаптеров старых профилей. Основание: одобрение пользователя, [Engine_v14_Audit.md](docs/rotation/Engine_v14_Audit.md).
- **До:** `GameState` не хранил pet/context/movement/threat; `target.isPlayer` ошибочно вызывал `UnitIsUnit("player","target")`, что не классифицирует player-target. `GameData_Contract.md` противоречиво утверждал, что API-матрица задаёт имена state keys, и упоминал v2/адаптер.
- **Сделано:** `GameAPI` разрешает выбранные read-only методы v14 для движения, контекста, угрозы, UnitIsPlayer, а также будущих spellbook/aura/auto shot данных. `GameState`: безопасные `player.moving`, `target.isPlayer`, `target.threat`, `pet.exists/dead/health`, `context.inGroup/inRaid/inInstance`, матричные статусы и уже существующие события инвалидации. Никаких игровых действий/автоматизации. Исправлены конфликты нормативного `GameData_Contract.md`; добавлены GAME-тест-кейсы в `Test_Matrix.md`.
- **Доказательства и проверки:** статически сверить allowlist, реализацию с матрицей #5,#9,#14,#17,#18,#38,#67,#72,#77,#92,#99 и сохранение старого снимка; runtime mock и игровой тест документировать отдельно. Наличие API в whitelist **не означает**, что клиент возвращает доступный результат.
- **Не выполнено:** игра WoW Forever, работа с pet в реальном бою, полные 101 способности, полная интеграция профилей. Следующее: расширить GameData и провести unit/integration/secret тесты; затем Eligibility и Engine.

## KR-20261121-009 — 2.8.1: полный inventory 101 строк v14 против ядра
- **Дата UTC:** 2026-11-21T07:59:13.695Z. **Тип:** docs/audit; **версия:** игровую сборку не меняли; **основание:** утверждение заказчика полной переработки 2.8.1–2.8.6 и двух отдельных аддонов.
- **Проблема:** старое ядро создано до v14, существует разрыв между низкоуровневым API, условиями профилей Hunter и чистым движком.
- **Исполнено:** документ `docs/rotation/Engine_v14_Audit.md` содержит **101/101 строк** с точной выбранной API-цепочкой и предварительным поиском имён по 10 кодовым модулям. Выявлены 8 приоритетных групп расхождений, следующий порядок исправления и источники Sonah/MaxDps/JustAC. **Методика:** это source-name inventory, не functional validation и не 101 успешно реализованный метод.
- **Проверки:** входная матрица прочитана из текущего GitHub, количество и уникальность всех 101 номеров проверены программно; ветка main проверяется перед коммитом. Не менялись Lua, .toc, модули Hunter и пользовательский UI. **NOT RUN:** игровой клиент, unit/integration test нового кода (код не изменён).
- **Следующий шаг:** 2.8.2, каноническая GameAPI/GameData; отдельный коммит с CHANGELOG, затем 2.8.3–2.8.6. Два аддона и DevTools остаются запланированными, а не реализованными.

## KR-20261121-008 — утверждены два физических аддона, общий канонический движок и BM 1–59 QA
- **Дата/время:** 2026-11-21T07:56:41.486Z (UTC). **Этап:** перестройка последовательности ядро/инструментарий/пилот; **тип:** docs, без изменения Lua, TOC или версии; **статус:** нормативный план, реализации NOT RUN.
- **Решение пользователя:** одно ядро на Canonical API Matrix v14 для двух физических аддонов: `KordRotation` (пользовательский) и `KordRotationDevTools` (отдельная зависимая установка). DevTools включает opt-in запись API/rotation/events/errors/performance, ограниченный журнал и ручной экспорт, пользовательская сборка без developer-инструментов. **Пилот:** Hunter BM Leveling PvE 1–59 после разработки ядра и DevTools. Профиль переносится на контракт нового ядра без runtime-адаптеров и без намеренного изменения приоритетов.
- **Проблема:** текущие документы по-разному описывали один устанавливаемый аддон и встроенную диагностику, порядок диагностики и пилота; ROADMAP содержал прежнее предложение «Воин — Оружие»; старые README/PROJECT_CONTEXT называли фундамент неготовым как текущий статус. Это путало новые чаты.
- **Причина:** ранее задокументированные решения разных этапов и исторические релиз-кандидаты остались рядом с новым согласованным планом без явного приоритета.
- **Исправление:** создан `docs/BUILD_VARIANTS_AND_DIAGNOSTICS.md` — единый контракт архитектуры, API-доказательств, порядка работ, границ журналирования, двух сборок и тестов. Приведены в соответствие `AGENTS.md`, `README.md`, `docs/PROJECT_CONTEXT.md`, `docs/ROADMAP.md`, `docs/Kord_Rotation_Creation_Guide.md`, `docs/rotation/README.md`, `Profile_Registry.md`, `Test_Matrix.md`. Исторические исходники и результаты тестов не переписывались; устаревшие исторические разделы помечены как ненормативные.
- **Проверки:** сверено текущее дерево `main` (87279b354e8668de5263e85d8e162bed825030e5), прочитаны целевые проектные документы и обнаружены конфликты в пилоте/распределении диагностической функциональности/сборке; после публикации отдельно проверяется текущий HEAD, ссылки, противоречия, уникальность нормативного файла. **NOT RUN:** в WoW, обе ZIP-сборки, Lua tests (код не менялся), новый DevTools и BM игровой пилот.
- **Выдача:** документированное решение, ссылки из главных точек входа и регрессионные сценарии BUILD-DEV/DEV/BM-LEVEL. Следующий шаг: реализация канонического ядра v14, затем DevTools; отдельный коммит для каждого согласованного подэтапа и CHANGELOG.

## KR-20261121-043 — утверждение v14 канонической матрицы и обязательное подключение нового чата

- Дата: 2026-11-21 (час не фиксировался). Согласование: пользователь прямо утвердил v14 исследовательской матрицы и потребовал обязательные указания для нового чата в AGENTS.md. Тип: docs/governance.
- Причина: новый чат разработки движка рисковал не прочитать 101-строчную матрицу или ошибочно считать методы прошедшими игровой тест.
- Ожидалось: утвердить source-baseline, обеспечить приоритет полного документа при разработке RotationEngine, сохранить Secret API/unknown ограничения и предварительное согласование изменений.
- Фактически: Canonical_API_Matrix.md v14 утверждена как SOURCE-BASELINE (KR-20261121-041, d315b9e22a3ceed5e578214b66b4e1859a771905); AGENTS.md дополнен обязательным чтением полного актуального файла и правилами применения (KR-20261121-042, 989f11fc4ab689dd886289503ffe6e32abc1eae3). Настоящая запись фиксирует связанные последовательные документационные изменения.
- Охват: 101 выбранный метод; по исходникам Blizzard Forever 58 подтверждённых методов, 20 частичных, 23 открытых; CLIENT PASS 0/101 и NOT RUN 101/101. Утверждение исследовательского базиса не равно утверждению исполнения в игровом клиенте.
- Проверки: PASS — оба целевых документа перечитаны из GitHub перед правкой и обновлены по их SHA; NOT RUN — WoW Forever client, Lua unit/integration (код Lua не менялся). Открытые вопросы: 43 строки и ограничения Secret API по реестру.
- Следующий шаг: новый чат обязан прочитать AGENTS.md, Kord Rotation Creation Guide и Canonical_API_Matrix.md полностью, сопоставить требования с шести референсами и получить конкретное согласование перед реализацией движка.
- SHA этой записи: git log --grep KR-20261121-043.
## KR-20261121-012 — reference-first переоценка матрицы API

- По требованию пользователя отменён выбор методов на основании существующего Kord; сравнение выполнено по реальным исходникам шести архивов: Sonah, MaxDps, JustAC, ForeverAuras, ForeverRotation, RotationGuide.
- Переписана Canonical_API_Matrix.md: конкретные файлы/строки, выбранные подходы, причины, выявленные ошибочные fallback, неустановленные сигналы, ограничения статического анализа.
- PASS: документальный пересмотр. NOT RUN: WoW Forever client, Lua tests, движок и ротации не менялись.

## KR-20261121-011 — единая каноническая матрица API и GameData

- **Дата:** 2026-11-21. **Согласование:** пользователь явно одобрил создание единой матрицы после проверки референсных аддонов. **Тип:** docs/architecture.
- **Референсы:** Sonah (Atoms/Spells), MaxDps Forever BM, JustAC (StateHelpers/SpellQuery), ForeverAuras (API/ClientAPI), ForeverRotation (Engine), RotationGuide (Core/API, Core/State); сравнение с существующими API_REFERENCE_MATRIX и KORD_API_DESIGN. Не копировался чужой код.
- **Решение:** нормативный `docs/rotation/Canonical_API_Matrix.md` с каноническими именами сигналов, владельцами, WoW read API, unknown policy, состояниями реализации и таблицей миграции Hunter BM. Ссылки добавлены в AGENTS, гайд, GameData Contract, индекс.
- **PASS:** документальный аудит референсов и сопоставление с текущим GameAPI allowlist. **NOT RUN:** реализация нормализатора, Lua unit/integration, игровой клиент и проверка API на текущем Forever build.
- **Риски:** наличие имени API в allowlist не гарантирует доступность/возврат значений; часть сигналов пока не имеет провайдера. **SHA:** `git log --grep KR-20261121-011`.

## KR-20261121-010 — исправление источников: Forever ≠ Classic

- **Дата:** 2026-11-21. **Согласование:** пользователь прямо потребовал исключить Classic и продолжить исследование. **Тип:** docs/research correction.
- **Причина:** предыдущий Hunter Research ошибочно использовал Classic Wowhead/Tavern/Icy Veins для сравнения с Forever; сравнение не доказывает игровые свойства Forever.
- **Решение:** методология и AGENTS запрещают использовать Classic как источник игровых свойств Forever; прежние сравнения отозваны. Добавлены ForeverDB abilities, ForeverDiff, 60.tools (только Forever), Rexas Forever, WCLBox Forever, WarcraftForever.games с учётом разных билдов. Выделен пробел pet abilities Savage Rend/Swipe/Tendon Rip/Web.
- **PASS:** документационное исправление и источники с явной Forever-применимостью. **NOT RUN:** игровой клиент, игровые ранги и Lua-тесты. **SHA:** git log --grep KR-20261121-010.

## KR-20261121-009 — Hunter BM/MM/SV: источники, способности, сигналы и тесты

- **Дата:** 2026-11-21, точное время по Git. **Тип:** docs/research. **Согласование:** пользователь одобрил исследование и заполнение реестров без изменения Lua.
- **Проблема:** существующие реестры содержали шаблоны, без подробной доказательной карты Hunter.
- **Изменения:** создан `docs/rotation/Hunter_Research_2026-11-21.md` с источниками, инвентарём BM/MM/SV, GameData-расхождениями, конфликтами и 15 тестовыми сценариями; добавлена ссылка в общий индекс. Общие таблицы остаются нормативными и будут дополнены после подтверждения фактов.
- **Исследовано:** 8 актуальных Hunter-файлов GitHub; локальные Sonah, MaxDps, ForeverRotation, RotationGuide, JustAC, ForeverAuras (последние два ограниченно); ForeverDB, ForeverDiff, Warcraft Tavern, Icy Veins, Wowhead. WoWSims и Warcraft Logs без подтверждённого Forever Hunter результата.
- **PASS:** наличие источников и фиксация буквальных ID/контрактов; **NOT RUN:** клиент, Lua unit/integration, реальные тайминги/ранги, полнота внешних данных.
- **Статус:** SOURCE REVIEWED / PARTIAL RESEARCH; не игровой DONE. **SHA:** `git log --grep KR-20261121-009`.

## KR-20261121-008 — единые исследовательские и технические реестры ротаций

- **Дата:** 2026-11-21; время по Git. **Тип:** docs. **Согласование:** заказчик прямо запросил создать необходимые документы для всех будущих классов и закрепить их в AGENTS и гайде.
- **Проблема:** отсутствие централизованных таблиц GameData, способностей, источников, приоритетов, CFG, тестов и статусов; риск дублирования на будущих восьми классах.
- **Решение:** создано семь общих реестров и README в docs/rotation; AGENTS.md закрепляет назначение; гайд v2.0 содержит ссылки на документы по шагам 1–13. Новые профили/спековые Core и Lua не создавались.
- **Основание:** Sonah и MaxDps содержат различные подходы к классовым данным/приоритетам; Kord сохраняет собственный документируемый контракт без копирования их реализации. Фактические игровые механики не подтверждались.
- **Проверки:** PASS — подготовлены согласованные Markdown-ссылки и схемы; NOT RUN — игровой клиент, Lua-тесты (код не менялся), независимая верификация всех механик, полное заполнение таблиц. TODO и UNVERIFIED не означают готовность.
- **Результат:** общая документационная основа для 9 классов. Следующий шаг — исследование и заполнение подтверждённых записей, согласование GameData перед изменением Lua. **Git SHA:** определяется через `git log --grep KR-20261121-008`.

## KR-20261121-007 — 2.8: универсальный движок и интеграция панели

- **Дата:** 2026-11-21; точное UTC-время — в Git commit. **Версия:** 0.1.8.3-rc9; **тип:** feature/test/docs. **Согласование:** заказчик одобрил универсальные RotationEngine/RotationProfiles и UI без выдуманных профилей.
### Исходная проблема
- `AbilityEligibility` проверял индивидуальный Spell ID, но отсутствовали реестр приоритетных правил и единый выбор текущей рекомендации. `RotationDisplay` показывал только testMode.
- Причина — незавершённый этап 2.8; попытка выводить любые изученные заклинания без классового профиля была бы ложной «ротацией».
### Анализ
- Сравнены локальные Sonah, MaxDps, JustAC, ForeverRotation, RotationGuide, ForeverAuras, выбран независимый реестр правил с fail-closed оценкой в порядке приоритета, без копирования стороннего исходного кода.
### Изменения
- `Core/RotationProfiles.lua`: строгая валидация специализации, категорий, target/cast/charges, максимум 64 правила в режиме, неизменяемость внутренних записей через копирование, **нулевой набор боевых профилей по умолчанию**.
- `Core/RotationEngine.lua`: явный opt-in, ST/AoE без ложного auto, последовательный `AbilityEligibility`, незамедлительная остановка на более приоритетном UNKNOWN, выбор одного текущего READY, реальные name/texture из каталога, клавиша только через BindingResolver.
- `UI/RotationDisplay.lua`: безопасный производственный путь для одной рекомендации, сохранение testMode, очистка пустых слотов, периодическое обновление только при зарегистрированном и разрешённом профиле. Нет ложных placeholder-рекомендаций.
- `KordRotation.toc`, `Init.lua`: версия 0.1.8.3-rc9 и загрузка модулей; `tests/stage_02_08_rotation_engine.lua`: автономный тест; `docs/STAGE_02_08_ROTATION_ENGINE.md`, `ROADMAP.md`, `KORD_API_DESIGN.md`: контракты.
### Проверки и честные ограничения
- **PASS:** `texlua tests/stage_02_08_rotation_engine.lua` — **29/29 Lua mock assertions**, `texluac -p` трёх новых Lua файлов. Точные Git blob SHA сканируются и сверяются после публикации.
- **NOT RUN:** игровой клиент WoW Forever, Lua UI-моки для `RotationDisplay`, полный код связки из настоящих Core зависимостей, все 27 реальных профилей, FPS/RAM. Статические проверки по Git tree отдельно.
- Результат — движок + UI-граница без классовых ротаций; панель в обычном режиме остаётся скрытой, пока первый профиль не добавлен и включён. Версия готова для этапа 3, но **не является проверенным в игре боевым аддоном**.
- **Связь:** предыдущий 2.7 `c02de02e2a225e0df52e7e67a7726ad88716eab0`.

## KR-20261121-006 — этап 2.7: AbilityEligibility и fail-closed проверка способностей
- **Дата:** 2026-11-21; SHA коммита через `git log --grep KR-20261121-006`; версия `0.1.8.3-rc8`; тип feature/test/docs.
- **Задача:** после прямого одобрения реализовать подтверждённую применимость изученной способности со слотом, кулдаунами, GCD, зарядами, ресурсами, целью, дальностью и кастом; не включать автоматический каст/приоритеты.
- **До:** существовали SpellCatalogue, GameState, ActionBarScanner и BindingResolver, но общего проверяющего слоя не было; отдельные API чтения зарядов/usable/range отсутствовали в whitelist. Причина — незавершённый этап 2.7.
- **Исследование:** перед реализацией просмотрены `Sonah/Core/Atoms/Spells.lua`, `JustAC/BlizzardAPI/SpellQuery.lua`, `JustAC/BlizzardAPI/CooldownTracking.lua`, `MaxDps/Cooldowns.lua` и остальные ZIP проекта. Использованы идеи, без копирования стороннего кода.
- **Изменения:** `Core/AbilityEligibility.lua`: новая проверка `Evaluate(spellID,options)` со строгими READY/BLOCKED/UNKNOWN, обязательной политикой цели, каста и зарядов, отказом от секретных cooldown timing; `Core/GameAPI.lua`: read-only whitelist; `Core/EventBus.lua`: каналы cooldown/charges/usability и cast events; `Init.lua`, `.toc`: версия rc8/инициализация; `tests/stage_02_07_eligibility.lua`: mock-проверки; `docs/STAGE_02_07_ELIGIBILITY.md`, `docs/ROADMAP.md`, `CHANGELOG.md`: документация.
- **Ранее обнаруженная ошибка:** локальный Lua-тест выявил, что выражение `status=="READY" and value or nil` теряет достоверное булево `false`; заменено на явный `if`. Также запрещены неявные политики charges и неопределённое состояние игрока/цели.
- **PASS:** `texlua tests/stage_02_07_eligibility.lua`: **23 mock-утверждения**, включая modern и legacy; исходные байты двух новых Lua-файлов сверены с Git blob SHA. Статическую проверку Git HEAD выполняем отдельно после публикации.
- **NOT RUN:** реальная WoW Forever игра, полный совместный запуск с реальными GameAPI/GameState/SpellCatalogue/ActionBarScanner, FPS/RAM, 27 профилей. Это не следует трактовать как 100% боевую совместимость.
- **Риски:** в отсутствие читаемых полей modern cooldown, доказанной политики цели/зарядов, применимости к цели, определённой дальности возвращается UNKNOWN; GCD dummy 61304 зависит от клиента. Выбран приоритет безопасности над ложным READY.
- **Результат/выдача:** коммит `main`, ZIP по SHA и `docs/STAGE_02_07_ELIGIBILITY.md`. Следующая задача требует согласования по правилу №1.

## KR-20261121-005 — Stage 2.6: выполнены автономные Lua-тесты, исправлен TTL-сценарий
- **Дата:** 2026-11-21; точный timestamp SHA см. в Git; **ID:** `git log --grep KR-20261121-005`.
- **Тип / версия:** test/docs, `0.1.8.3-rc7` без изменения игрового кода; связь: `720629cad367a0e9721e326e8ca6817606daad32`.
### Контекст и причина
- После KR-20261121-004 автономный тест был добавлен, но его запуск не подтверждался. Необходимо действительно проверить условия, а не выдавать статическое наличие файла за PASS.
- Первичный запуск обнаружил ошибку **тестового ожидания**: после подмены ответа `GetBindingAction` без события `UPDATE_BINDINGS` и без истечения TTL кэш обязан возвращать предыдущий проверенный результат. Это не доказательство дефекта игрового модуля.
### Изменения
- `tests/stage_02_06_bindings.lua`: явная проверка `READY` до истечения TTL и `UNKNOWN` после `time=time+1` и несовпадения обратной команды. Восстановлены остальные сценарии.
- `docs/STAGE_02_06_BINDINGS.md`: внесены результаты запуска, SHA проверенных файлов, границы тестирования.
- `CHANGELOG.md`: документирован исходный FAIL тестового сценария, исправление теста, PASS и ограничения. `BindingResolver.lua`, `ActionBarScanner.lua`, TOC и версия не менялись.
### Доступные проверки
- **PASS:** `texlua tests/stage_02_06_bindings.lua`, **25 assertions**, локальный каталог `/mnt/data/kord25`, точные Git blob SHA `05ae933518e9417456946b32a31c3e6f0bc7e646`, `d3d8f6c8f0dd6b28078480b3f2943555e12cfa2c`, `689f4aca23929ba4cd0a9e80ee34b9ae0cbeaba6`; имитации GameAPI/EventBus вместо реальных.
- **PASS:** `texlua tests/stage_02_05_actionbar.lua` с локальными mock, регрессионный прогон сканера.
- **PASS:** `texluac -p` для трёх упомянутых Lua-файлов.
- **NOT RUN:** единый mock-тест с реальными GameAPI/EventBus, игровой клиент Forever, UI-аддоны в игре и производительность.
### Выдача и итог
- Публикация отдельного test/docs коммита; файлы и исходный релиз 2.6 остаются в git; без дополнительного игрового тестирования между подэтапами.
- **Статус:** 2.6 IMPLEMENTED / AWAITING IN-GAME QA, следующий 2.7 требует нового анализа референсов и одобрения по правилу № 1.

## KR-20261121-004 — Stage 2.6: BindingResolver и реальные сочетания клавиш
- **Дата:** 2026-11-21, точное время фиксирует Git commit; SHA находится через `git log --grep KR-20261121-004`. **Тип:** feature/test/docs. **Версия:** `0.1.8.3-rc7`.
- **Задача:** заказчик одобрил сравнение Sonah, JustAC, MaxDps и поддержку Blizzard, Bartender4, Dominos, ElvUI, EllesmereUI, LibActionButton. OPie остаётся вне рамок. Исходники прочитаны перед написанием кода по правилу № 1.
### Контекст, ожидаемое, причина
- Ранее `ActionBarScanner` подтверждал action-slot, но не реальную binding-command/клавиши. `RotationSettings.keyLabel` — вручную сохранённая подпись, не реальное назначение.
- Требуется показывать реальную привязку только при достоверном сопоставлении; главная опасность — неверная клавиша на custom-paged панели из-за слепого преобразования номера слота.
### Изменения и обоснование
- `Core/BindingResolver.lua`: отдельный read-only модуль без дополнительных библиотек, извлекает binding-command из метода или атрибута кнопки, иначе использует строгую карту штатных кнопок Blizzard/EAB; проверяет до двух `GetBindingKey` и reverse `GetBindingAction` (если присутствует). Кэш 0,5с с инвалидированием по событиям; новый fallback UNKNOWN при неподтверждённых override routes.
- `Core/ActionBarScanner.lua`: `GetVerifiedButtons` для доказательно существующих видимых кнопок с повторной проверкой slot/spellID; не выдаёт кнопки в пользовательские SavedVariables.
- `Init.lua`, `KordRotation.toc`: загрузка и версия rc7. `tests/stage_02_06_bindings.lua`, `docs/STAGE_02_06_BINDINGS.md`, `docs/ROADMAP.md`, `KORD_API_DESIGN.md`.
- **Не менялись:** интерфейсные строки/шесть языков, ручной `keyLabel`, спелл-ротации, OPie и сторонние обязательные библиотеки.
### Проверки
- После публикации проверяются файлы в Git HEAD, TOC порядок, реальные контракты, отсутствие protected actions, тестовые случаи, размер.
- **NOT RUN до подтверждения запуска:** автономный Lua-тест с настоящими модулями, QA WoW Forever, API/UI совместимость и профилирование. Наличие тестов не считается PASS.
### Выдано / статус
- Самостоятельный коммит, архив SHA, документация и сценарии будущего игрового теста. Статус **IMPLEMENTED / GAME QA NOT RUN**, а не DONE.
- Следующий шаг: 2.7 только после изучения Sonah и MaxDps и отдельного одобрения; связь: `ae8845a2a021b51db79016c1a96ad5afce0a65ae`.

## KR-20261121-003 — этап 2.5a: поддержка EllesmereUI EABButton
- **Дата/время:** 2026-11-21 (точный UTC timestamp — в GitHub commit); идентификатор SHA: `git log --grep KR-20261121-003`.
- **Этап / версия / тип:** 2.5a / 0.1.8.3-rc6 / feature + test + docs.
- **Задача:** по прямому одобрению заказчика добавить EllesmereUI через реальные игровые action-слоты, **без OPie**.
### Контекст, ожидание и причина
- Ожидалось: способность на видимой кнопке EllesmereUI допускается к будущему этапу Eligibility лишь при наличии настоящего подтверждённого игрового slot и spellID. Устаревшее/скрытое/защищённое действие не подтверждается.
- Фактически до исправления: ActionBarScanner обнаруживал Blizzard, BT4, Dominos, ElvUI и LAB, но не `EABButton`.
- Первопричина: отсутствовал префикс кнопок EllesmereUI, несмотря на уже существующий общий механизм проверки action-атрибута.
### Сверка референсов и изменённый код
- Sonah, MaxDps и JustAC использованы как архитектурные ориентиры read-only подтверждения слота. Первичный код EllesmereUI `EUI_ActionBars_Secure.lua`, `Bars.lua`, `Paging.lua` подтвердил `EABButton1..180` и динамический `action`.
- `KordRotation/Core/ActionBarScanner.lua`: добавлено обнаружение `EABButton` в ограниченном цикле; иной алгоритм не менялся. OPie не интегрирован, внешние зависимости не добавлены.
- `tests/stage_02_05_actionbar.lua`: добавлены реальные mock-проверки EAB, макроса, скрытой кнопки, смены action, protected значения и события ADDON_LOADED.
- `Init.lua`, `KordRotation.toc`: версия 0.1.8.3-rc6. `docs/STAGE_02_05_ACTIONBAR.md`, `docs/STAGE_02_05A_ELLESMERE.md`, `docs/ROADMAP.md`, `KORD_API_DESIGN.md`: обновлены границы решения.
### Проверки
- **PASS:** `texlua tests/stage_02_05_actionbar.lua` с точными версиями файлов `ActionBarScanner.lua` (blob `9c89217e10ca402562f694516bc9e3266b4ca619`) и теста (blob `ff42482161a0b7d7a094e305ea14784c483c8d7d`), но **с mock GameAPI/EventBus**. Результат: `PASS stage 2.5 mocked action bar scenarios`.
- **NOT RUN:** полный сценарий с фактическим GameAPI/EventBus, игровой WoW Forever, реальная совместимость установленных EllesmereUI/OPie, CPU/FPS.
- Перед публикацией/после — статические проверки TOC, версий, ссылок и содержимого нового коммита; итог указать в ответе.
### Выдано / статус / связи
- Коммит в `main`, ссылка и ZIP по неизменяемому SHA, полный QA-кейс добавлен в документ; промежуточный игровой тест не требуется.
- **Результат:** реализовано в коде, но `IMPLEMENTED / GAME QA NOT RUN`. Следующий пункт: предварительное исследование референсов для 2.6 и согласование по правилу №1.
- **Связь:** предыдущий релиз 2.5 `508aee89555998f49c650bc2111d8bf8835d9f62`, записи KR-20261121-001 и KR-20261121-002.

## KR-20261121-002 — 2.5: исправление защищённого paging и LibActionButton; исполняемый mock-тест
- **Дата:** 2026-11-21, точное время/UTC по Git commit; **SHA:** `git log --grep KR-20261121-002`.
- **Версия/этап/тип:** 0.1.8.3-rc5 / 2.5 / fix + test + docs. Связь: `4f010d4efd8e9503f515679f053ce5f35e7ab9be` (первоначальная реализация).
### Контекст, ожидаемое, фактическое
- При анализе исходников Sonah, MaxDps и JustAC выявлено: некоторые LibActionButton выдают `("action",slot)` через `GetAction()`; предыдущее решение без этой ветки пропускало их.
- Проблема fail-closed: ошибка/secret `GetAttribute("action")` могла привести к fallback на другое, возможно устаревшее поле `button.action`. Ожидалось — `UNKNOWN`, не подтверждение неверной способности.
### Причина и изменения
- Причина — смешение недоступного API и допустимого `nil` в прежнем `actionSlot`.
- `Core/ActionBarScanner.lua`: прекращение сканирования при защищённом/ошибочном результате реально имеющегося GetAttribute/GetPagedID; поддержка `GetAction()` только для `"action"` со строго подтверждённым игровым слотом.
- `tests/stage_02_05_actionbar.lua`: новые mock-сценарии LAB GetAction, non-slot LAB spell, secret attr при числовом raw action. Версия/TOC/UI/зависимости не менялись.
- `docs/STAGE_02_05_ACTIONBAR.md`: алгоритм и проверенный объём тестирования.
### Проверки
- **PASS:** `texlua tests/stage_02_05_actionbar.lua` в локальном тестовом каталоге, использованы байт-в-байт исходники scanner/test (их Git blob SHA совпал с опубликованными `3c495008db0c20f3df3e99204cbd98f0b8b6b1d9` и `19ee4aa3ee0a90e628e9c341540b0f5038334d42`). Зависимости GameAPI/EventBus были **упрощёнными mock-адаптерами**, а не живыми исходниками.
- **NOT RUN:** Lua-тест с настоящим GameAPI и EventBus проекта; Lua-синтаксис всего аддона; реальный клиент WoW Forever, полная функциональная совместимость Bartender4/Dominos/ElvUI; FPS/RAM.
- **План:** в итоговом QA обязательно повторить те же сценарии на клиенте.
### Выдача и результат
- Отдельный коммит коррекции, обе версии файлов и документация. Следующий этап — только после предварительного анализа референсов и одобрения по правилу № 1.

## KR-20261121-001 — этап 2.5: сканер игровых action-слотов сторонних панелей
- **Дата:** 2026-11-21 (точное время в Git commit). ID/SHA: `git log --grep KR-20261121-001`.
- **Этап/версия/тип:** 2.5 / `0.1.8.3-rc5` / feature, test, docs.
- **Задача:** по явному одобрению заказчика добавить безопасное обнаружение Blizzard, Bartender4, Dominos, ElvUI и уже загруженных LibActionButton. Прежде рассмотрены Sonah, MaxDps, JustAC, ForeverRotation; критерии одобрены.
### Контекст и причина
- Ранее был SpellCatalogue, но не было доказуемой связи изученного spell ID с видимым игровым action-слотом. Предполагалось использовать только Blizzard-кнопки, однако пользователь расширил разрешённый объём.
- Причина: не существовал `ActionBarScanner`; копирование MaxDps целиком добавило бы ненужные зависимости и подсветки.
### Изменения и почему
- `Core/ActionBarScanner.lua`: только читающий сканер и многоканальный кэш; безопасное извлечение action-слота, проверка видимости, типа и ID через whitelist GameAPI. Переобход при изменениях, перед FindSpell повторная проверка источника; прямые безслотовые действия исключены.
- `Core/GameAPI.lua`: `IsSafeValue` для результатов методов и frame references; использует существующий secret-guard.
- `Core/EventBus.lua`: входящие события actionbar, modifier, stealth, vehicle, override, загрузка UI.
- `Init.lua`/`.toc`: порядок загрузки и инициализация нового сканера, новая версия.
- `KORD_API_DESIGN.md`, `docs/ROADMAP.md`, `docs/PROJECT_CONTEXT.md`, `docs/STAGE_02_05_ACTIONBAR.md`: отражено одобренное расширение, ограничения и ссылки на референсы.
- `tests/stage_02_05_actionbar.lua`: имитация Blizzard/BT4/Dominos/ElvUI/LAB, смены paging, макросов, предметов и protected API.
### Проверки
- Проверки файлов, версии, статусов/контрактов и Git HEAD проводятся после коммита; их результат отражён в финальном отчёте.
- Lua mock и WoW Forever: результаты должны указываться фактически, без предположений об успешности.
### Выдано
- GitHub SHA и ZIP конкретной версии. Промежуточный игровой тест не требуется по протоколу этапа.
### Статус и остаточные риски
- Сканер не гарантирует полноты всех версий сторонних панелей; missing/secret API → UNKNOWN, не READY. Скорость и реальная совместимость ожидают игрового QA.
- Следующий шаг 2.6: сравнение референсов и отдельное согласование с заказчиком по правилу № 1.
- Связь: `cb70986ff1afc6176d4958543bca4ab34ba83776` (этап 2.4a).

## KR-20261120-011 — исправление 2.4a: secret tables, spellbook и события
- **Дата:** 2026-11-20, время UTC определяется по Git commit; ID коммита через `git log --grep KR-20261120-011`.
- **Версия/этап:** 0.1.8.3-rc4 / 2.4a; **тип:** fix/test/docs; прямое одобрение заказчиком варианта из сравнения Sonah и MaxDps.
### Контекст
- **Ожидалось:** защищённые таблицы не читаются; неизвестные itemType и пустая неинициализированная книга не выглядят успешной загрузкой; неподдерживаемые события не регистрируются.
- **Фактически до:** GameAPI не проверял secret tables, modern spellbook молча пропускал неизвестный ненулевой тип, нулевые вкладки давали ready, EventBus не использовал IsEventValid.
- **Первопричина:** неполный защитный контракт адаптера и слишком оптимистичные ветви обхода книги. Подтверждено статически в коде предыдущей версии; поведение на реальном клиенте ещё не проверялось.
### Изменения
- `Core/GameAPI.lua`: усиленные проверки secret-table/value и `ReadField` с fail-closed.
- `Core/SpellCatalogue.lua`: безопасное чтение таблиц, строгая обработка modern itemType, отрицание неподтверждённой пустой книги и fallback.
- `Core/EventBus.lua`: проверка валидности событий, три точечных новых события обучения/специализации.
- `tests/stage_02_04_spell_catalogue.lua`: дополнительные сценарии; `KordRotation.toc`, `Init.lua`: версия 0.1.8.3-rc4; документы `docs/STAGE_02_04A_FIXES.md`, `docs/ROADMAP.md`.
### Проверки
- **PASS:** 8 узконаправленных Lua-утверждений с `texlua` в локальном mock-сценарии, основанном на внедрённых защитных условиях (не полные исходники аддона).
- **NOT RUN:** полный тестовый файл из GitHub, игровое тестирование WoW Forever, реальный профайлинг и совместимость secret API клиента.
- **Результат:** исправления опубликованы в исходниках; правдоподобность подтверждена статикой, функциональная приёмка остаётся открытой.
### Выдано и следующий шаг
- GitHub commit SHA и неизменяемый ZIP по SHA; промежуточную игровую установку не требовать. Следующее: предложить 2.5 по правилу № 1 и получить одобрение перед кодом.
- **Связь:** `85cf15c3372a0b6466128e0f52690f75ffcdecdd` (KR-20261120-010), `c90bea2bebf6f1c55153491440d8524aaa941b6b` (аудит).

## KR-20261120-010 — правило № 1: предварительная сверка референсов и согласование решения
- **Дата:** 2026-11-20; точное время и SHA см. в Git-истории по `git log --grep KR-20261120-010`.
- **Этап / версия:** процесс разработки, документация; версия Lua-аддона `0.1.8.3-rc3` не меняется.
- **Тип / запрос:** docs; прямое решение заказчика присвоить высший приоритет предварительному изучению референсов и обязательному согласованию выбранного подхода.
### Контекст и причина
- **Ожидалось:** до любой реализации изучаются минимум Sonah и MaxDps, желательно все шесть референсов; сравниваются способы и аргументируется лучший, а пользователь решает — делать ли.
- **Было:** в `AGENTS.md` имелось правило немедленно кодировать очередной шаг по команде «Продолжай», не требовавшее сравнительного предложения и отдельного согласования.
- **Причина:** прежний рабочий цикл не учитывал обязательную фазу выбора архитектуры и одобрения заказчиком.
### Изменения
- `AGENTS.md`: в начале закреплено приоритетное ПРАВИЛО № 1, шаги сравнения/предложения/ожидания одобрения, поведение при недоступности ZIP, отношения с ROADMAP и CHANGELOG.
- `README.md`: заметное изложение правила у заголовка, ссылка на полный текст.
- `docs/PROJECT_CONTEXT.md`: краткий высокоприоритетный протокол для новых чатов.
- `CHANGELOG.md`: настоящая запись по стандарту проекта.
- **Без изменений:** Lua, UI, профильные настройки, кодовая версия, пользовательский интерфейс; это только процессное изменение.
### Проверки
- PASS — статическое сравнение прежних `AGENTS.md`/README/PROJECT_CONTEXT; проверка, что новое правило стоит выше прочих требований и противоречащие пункты «Продолжай» явно подчинены ему.
- NOT RUN — Lua/runtime/игровой QA (нет изменений игрового кода).
### Выдано и результат
- Заказчик получает коммит, ссылку на актуальные инструкции и их содержание; **следующая техническая задача не начинается без согласования решения по правилу № 1**.
- Связь: предыдущий аудит `c90bea2bebf6f1c55153491440d8524aaa941b6b` (KR-20261120-009).

## KR-20261120-009 — аудит 2.1–2.4 против Sonah/MaxDps
- **Дата:** 2026-11-20; точное время — Git commit; **SHA:** через `git log --grep KR-20261120-009`.
- **Тип:** audit/docs, версия Lua-аддона `0.1.8.3-rc3` без изменений.
- **Задача:** сверить CHANGELOG и актуальные исходники с Sonah.zip и MaxDps.zip; оценить корректность, пропуски, архитектуру и вес.
- **Контекст:** отсутствие запусков Lua и Forever QA не позволяет считать предыдущие статические PASS игровыми PASS; появились основания для отдельного обзора перед 2.5.
- **Выявлено:** P1 secret-table guard и молчаливый пропуск неизвестного modern spellbook itemType; P2 known-spell вне книги, события, неоднозначность пустой legacy книги; P3 возможное чрезмерное чтение при частых dirty events и лишние копирования.
- **Размер:** папка аддона выросла с 404480 до 434358 байт (+29878 / +7.39%) относительно коммита `139f2fcda6fd6625cc80fa4ac48fadd3685b22c5`. Корневая документация в это число не включена.
- **Файлы:** `docs/STAGE_02_04_SELF_AUDIT.md`, `CHANGELOG.md`. Lua/TOC/версия не менялись.
- **Проверка:** PASS — статическое чтение исходников текущей ветки, Sonah и MaxDps, Git tree размеров и предыдущих записей CHANGELOG. NOT RUN — Lua runtime / тестирование в WoW Forever / профилирование FPS и RAM.
- **Выдача:** ссылку на audit и коммит, новая игровая сборка не требуется.
- **Результат:** направление подтверждено условно, но рекомендован отдельный исправляющий коммит до 2.5. Не выдавать аудит за выполненную регрессию игрового клиента.

## KR-20261120-008 — исправление порядка загрузки и версии 2.4
- **Дата:** 2026-11-20, точное время — Git; SHA определяется по `git log --grep KR-20261120-008`.
- **Тип:** fix; версия `0.1.8.3-rc3`; связь: коммит `97afaf40b983a5e67978ee8cb11a119b635edf2a` (KR-20261120-007).
- **Обнаружение:** статическая проверка предыдущего коммита 2.4 дала FAIL (2 из 17): `.toc` содержит старое `## Version: 0.1.8.3-rc2` и располагает SpellCatalogue до GameAPI/EventBus.
- **Первопричина:** предыдущая замена версии затронула Notes, но не строку Version; старое положение SpellCatalogue в списке модулей не было перенесено после новых зависимостей.
- **Исправление:** `KordRotation/KordRotation.toc`: точная версия 0.1.8.3-rc3, порядок `GameAPI → EventBus → SpellCatalogue`. Остальные файлы Lua и интерфейс не менялись.
- **Ожидаемое:** при инициализации каталога обе зависимости уже существуют; метаданные совпадают с `Init.lua`.
- **Проверки:** запланирована повторная статическая проверка опубликованного дерева; Lua runtime и WoW Forever — NOT RUN.
- **Выдано:** коммит с корректирующим изменением, без промежуточной игровой установки.
- **Статус:** требует подтверждения в клиенте только после всего этапа 2; следующий шаг 2.5.

## KR-20261120-007 — Stage 2.4: SpellCatalogue legacy/modern, ранги и обновление
- **Дата:** 2026-11-20 (точное время — в GitHub); **коммит:** `git log --grep KR-20261120-007`.
- **Этап / версия:** 2.4, `0.1.8.3-rc3`; тип feature/test/docs. Запрос пользователя — реализовать 2.4 по `KORD_API_DESIGN.md`.
### Контекст и причина
- Ранее был только legacy-скан книги без рангов и событийной инвалидации. Отсутствие функции выдавало unavailable, частично прочитанные результаты могли выглядеть успешными.
- Причина — неполный адаптер данных этапа 1; совместимость конкретного клиента неизвестна.
### Изменения
- `Core/SpellCatalogue.lua`: два проверяемых способа получения фактически изученных spell ID, отображение рангов, дедупликация ID, аккуратная сортировка/поиск, fail-closed при частичном чтении, 2-секундный кэш, отдельная ревизия и инвалидация по EventBus.
- `Core/GameAPI.lua`: разрешённые spellbook-методы и `ReadValues` для многорезультатных API с `pcall` и secret-guard.
- `Core/EventBus.lua`: LEARNED_SPELL_IN_TAB и SKILL_LINES_CHANGED; сохранены прежние события и подписки.
- `UI/Pages/RotationAbilities.lua`: если API предоставил ранг, редактор показывает его рядом с названием без новых непереведённых интерфейсных текстов.
- `Init.lua`, `KordRotation.toc`: инициализация каталога после EventBus, версия синхронизирована.
- `tests/stage_02_04_spell_catalogue.lua`, `docs/STAGE_02_04_SPELL_CATALOGUE.md`, `docs/ROADMAP.md`, CHANGELOG: автономные сценарии, документ и статус.
### Проверки
- PASS/FAIL/NOT RUN — подробные результаты сообщить после проверки опубликованного дерева; пока создание Lua тестов не равнозначно исполнению тестов.
- **NOT RUN:** реальный клиент Forever, различные классы/ранги, событие изменения талантов в бою, protected/secret в игре.
### Выдано
- Коммит `KR-20261120-007` и ZIP по конкретному SHA; промежуточный игровой тест не требуется по согласованному протоколу.
### Итог
- Программная часть 2.4 реализована, **игровой QA ожидается**. Двигаться к 2.5 — action slots Blizzard. Связь: `e5415abdc33fb9671570330f180e0a1b01f7d78c`.

## KR-20261120-006 — Stage 2.3: GameState для игрока, цели и боя
- **Дата:** 2026-11-20 (время Git коммита — см. историю); **коммит:** `git log --grep KR-20261120-006`.
- **Этап / версия:** 2.3 / 0.1.8.3-rc2. **Тип:** feature/test/docs.
- **Задача:** создать событийно обновляемый снимок player/target/combat, здоровья и ресурсов с явным UNKNOWN, не начиная боевую ротацию. Пользовательских баг-отчётов для этого шага нет.
### Контекст и причина
- Ранее GameAPI имел ограниченный whitelist, EventBus не отслеживал изменение здоровья и максимального ресурса; потребителям недоставало единого нормализованного снимка.
- Причина — отсутствие GameState; варианты API клиента в игре не проверены.
### Изменения
- `Core/GameState.lua`: read-only snapshot, статусы каждого поля, целевой GUID, здоровье/проценты, типизированные ресурсы, бой, каст/канал, копия кэша и 0.5с TTL, инвалидация по EventBus.
- `Core/GameAPI.lua`: разрешённые read-only UnitGUID/UnitHealth/UnitHealthMax/UnitPowerType/UnitCanAssist/UnitIsUnit/GetTime.
- `Core/EventBus.lua`: дополнены события здоровья/ресурса/флагов и входа в мир, фильтр player/target.
- `Init.lua`, `.toc`: порядок загрузки и включение GameState, запуск после PLAYER_LOGIN, синхронизация 0.1.8.3-rc2.
- `tests/stage_02_03_game_state.lua`: воспроизводимые автономные сценарии с mock API.
- `docs/STAGE_02_03_GAME_STATE.md`, `docs/ROADMAP.md`: контракт, ограничения и статус.
### Проверки
- Статическая проверка таблицы API, порядка TOC, согласованности версий, контрактов статусов и подписок — запланирована перед публикацией.
- Автономный Lua-тест: точный результат фиксируется в сообщении о коммите; отсутствие запуска не считать PASS.
- **NOT RUN:** проверка API в игровом клиенте Forever, манекен/бой и интеграция боевой ротации.
### Выдано
- Отдельный коммит с документацией и ZIP конкретного SHA. Промежуточный игровой тест не требуется, накопленные сценарии вошли в документ шага 2.3.
### Результат
- Исходники шага 2.3 написаны; игровой статус **AWAITING IN-GAME QA**. Следующий шаг — 2.4 SpellCatalogue. Связь: `55d3bb8bd77853138a2cd7e8a71cdba1ba9eae15`.

## KR-20261120-005 — утверждаемая целевая матрица API Kord Rotation
- **Дата:** 2026-11-20; точное время UTC см. в GitHub commit.
- **Коммит:** `git log --grep KR-20261120-005`.
- **Этап/версия:** подготовительное архитектурное действие перед 2.3; Lua-версия `0.1.8.3-rc1` без изменений. Тип: docs/research.
- **Запрос пользователя:** на основе шести референсов выбрать API именно для Kord, записать предпочтительные методы, альтернативы и способ реализации в отдельной таблице корня репозитория.
### Контекст и причина
- До: `API_REFERENCE_MATRIX.md` сравнивал встречающиеся вызовы, но не фиксировал целевые решения Kord. Игровые API не подтверждены в клиенте Forever.
- Причина: требовалось формально разделить выбранные методы, методы для особых профилей и ненужные/небезопасные вызовы.
### Изменения
- `KORD_API_DESIGN.md`: обзор выбранных паттернов и 159 строк с решениями, предпочитаемым референсом, конкретной реализацией/проверками, целевым модулем, этапом и указателями исходников.
- `KORD_API_DESIGN.csv`: фильтруемая версия той же целевой матрицы.
- `CHANGELOG.md`: настоящая запись. Lua/TOC/настройки/UI и версии не изменялись.
- Классификация: 54 CORE, 82 CONDITIONAL, 11 DEFER, 12 EXCLUDE. Приоритет определяется потребностями Kord и предполагаемой совместимостью, не частотой использования.
### Проверки
- **PASS:** перенесены все 159 строк из сравнительного справочника, 9 тематических разделов, 6 референсов учтены при выборе основ, для каждой строки есть решение/модуль/этап и текст способа реализации, созданы два GitHub blob.
- **NOT RUN:** клиент WoW Forever, выполнение Lua, ручная полная проверка каждого контекста источника; статус методов может корректироваться после реальной проверки API. Никакие способности не кастовались.
### Выдано тестировщику
- Файлы в корне `main`, ссылка на SHA коммита и архив для просмотра; промежуточный игровой QA не требуется.
### Результат
- Отдельный целевой справочник опубликован, исходный сравнительный справочник не изменён.
- Следующий шаг: использовать целевые решения при реализации 2.3 и следующих подпунктов, не выдавая запланированные методы за уже работающие.
- Связь: `3a0d38ebd3b1f44d21f85230c2a2f419486a57b7` (KR-20261120-004).

## KR-20261120-004 — сравнительная матрица API всех шести референсов

- **Дата:** 2026-11-20 (точное время UTC — в GitHub commit).
- **Коммит:** определяется через `git log --grep KR-20261120-004`.
- **Этап:** подготовка к 2.3; тип: docs/research; версия Lua-аддона не изменялась.
- **Запрос:** собрать в корне репозитория таблицу API-методов с шестью столбцами референсов, чтобы сравнивать использование и не пересматривать все ZIP при каждом новом шаге.
- **Ожидалось:** у каждой строки название API, функция, статус для Kord; по каждому референсу — назначение, характер использования и адрес исходника.
- **До:** была матрица кандидатов в `docs/STAGE_02_01_API_RESEARCH.md`, но отсутствовала полноценная перекрёстная таблица по каждому референсу.
- **Причина:** материалы исследования были распределены по ZIP и описаниям; это усложняло обоснованный выбор адаптеров.
- **Изменения:** `API_REFERENCE_MATRIX.md` — 159 методов, тематические разделы, 6 столбцов Sonah/JustAC/MaxDps/ForeverAuras/ForeverRotation/RotationGuide, конкретные пути и строки; `API_REFERENCE_MATRIX.csv` — фильтруемая табличная версия тех же строк. Указаны границы статического поиска, отсутствие доказательства совместимости с клиентом и запрет на копирование чужого кода без проверки лицензии.
- **Проверено (PASS):** распакованы шесть предоставленных ZIP; просмотрены .lua-файлы каждого архива; собраны 159 уникальных строк; совпадение имен и количества полей в таблице; файлы созданных blob-объектов GitHub. Позиции вызовов найдены статически, не проверены интерпретатором.
- **Не проверено (NOT RUN):** работа любого API в клиенте WoW Forever, интерпретация каждого встретившегося контекста вручную, тестирование Lua аддона, внешний функциональный тест. Ячейки с ссылкой/упоминанием не равны доказательству прямого вызова.
- **Выдано:** отдельные справочники в корне `main`; новый игровой ZIP не требуется, но доступен архив коммита. Внутриаддонных изменений нет.
- **Результат и следующий шаг:** справочная матрица готова к сравнительной архитектурной оценке; отдельную целевую таблицу Kord с выбором лучших вариантов составлять на следующем согласованном шаге. Исходная версия Kord остаётся `0.1.8.3-rc1`.

## KR-20261120-003 — Этап 2.2: безопасный GameAPI, шина событий и восстановление загрузки
- **Дата:** 2026-11-20 (точное время — Git commit); **коммит:** `git log --grep KR-20261120-003`.
- **Этап / версия:** 2.2, `0.1.8.3-rc1`; тип: feature/fix. Запрос пользователя: реализовать шаг 2.2.
### Контекст
- До: отсутствовал единый read-only API/диспетчер событий; `.toc` не загружал `SafeActions` и `MinimapButton`, версия `.toc` отличалась от `Init.lua`.
- После: раздельные `Core/GameAPI.lua` и `Core/EventBus.lua`, корректная загрузка модулей, инициализация при PLAYER_LOGIN.
- Проверено статически по исходникам коммита предыдущего шага; реальный клиент Forever, персонаж, специализация и версия сборки не предоставлены.
### Анализ причины
- Статически подтверждено несоответствие перечня .toc существующим модулям и метаданных версий; игровой эффект — гипотеза до QA.
- Безопасный API ещё не был реализован, поэтому нет ни боевого state-provider, ни реальных рекомендаций.
### Что изменено
- `Core/GameAPI.lua`: ограниченный allowlist только read-only функций, `pcall`, валидация типа/чисел/secret, статусы READY/UNKNOWN/UNAVAILABLE/ERROR, отсутствие подмены неизвестного на false.
- `Core/EventBus.lua`: безопасная регистрация игровых событий, фильтр player/target, инвалидация каналов, coalescing 0.20 c, fallback heartbeat 2 c только подписчикам, защищённые callback, ограниченные сообщения ошибок.
- `KordRotation/KordRotation.toc`: порядок загрузки новых модулей и отсутствовавших SafeActions/MinimapButton, версия.
- `Init.lua`: запуск `SafeActions` и `EventBus` после входа, синхронизация версии.
- `docs/ROADMAP.md`, `docs/STAGE_02_02_IMPLEMENTATION.md`: статус и тестовые контракты; ни панель, ни локали не менялись (нового UI нет).
### Проверки
- PASS: проверка API-перечня на read-only, строгого контракта статусов, независимости callback, TOC-упорядочения и совпадения двух версий по исходникам.
- NOT RUN: Lua interpreter (в среде отсутствует), клиент WoW Forever, события/привязки/секретные поля во время боя.
- Остаточные риски: реальная регистрация определённых событий и API зависит от билда клиента; heartbeat не подтверждает истинное игровое состояние. Движок рекомендаций ещё не существует.
### Выдано тестировщику
- Git-коммит и ZIP по SHA после публикации; промежуточный игровой тест не требуется.
- В накопленный финальный QA: вход в игру, миникарта, сброс после выхода из боя, отсутствие API/типа, смены цели/талантов/биндов, проверка таймингов и доступности событий.
### Результат
- Реализован программный фундамент 2.2; **игровое подтверждение НЕ проведено**, поэтому статус IMPLEMENTED / AWAITING IN-GAME QA, не DONE. Следующий шаг 2.3 (снимок состояния), исправления только по подтверждённым кейсам.

## KR-20261120-002 — Stage 2.1: инвентаризация API и архитектурных контрактов
- **Дата:** 2026-11-20 (точное время коммита см. GitHub).
- **Коммит:** определяется через `git log --grep KR-20261120-002`.
- **Этап / версия:** 2.1 / Lua-версия не изменялась; тип: docs / research.
- **Задача:** исследовать код Kord и шесть архивов-референсов, выбрать API-границы для движка. Отчёт пользователя об ошибке отсутствует.
### Контекст и воспроизведение
- Ожидалось: конкретные API, события, статусы неизвестных данных и интерфейсы модулей.
- Фактически: ROADMAP содержал только задачи, без результата исследования.
- Проверено чтением `Init.lua`, `KordRotation.toc`, `Core/*`, `UI/SpellIcon.lua`, `UI/RotationDisplay.lua` и файлов референсов; версия клиента и персонаж неизвестны.
### Анализ причины
- Статически установлены расхождение версии `.toc`/`Init.lua` и отсутствие `Core/SafeActions.lua` и `UI/MinimapButton.lua` в загрузочном перечне .toc. Их фактическое влияние в игре не подтверждено.
- Пробел API-контрактов — закономерное состояние до реализации движка, не зарегистрированный пользовательский BUG.
### Что изменено и почему
- `docs/STAGE_02_01_API_RESEARCH.md`: матрица способностей, action slots, биндов, цели, боя, ресурсов, cooldown/auras; исследование референсов и лицензий; типы ApiRead/GameSnapshot/ActionSlot/Recommendation; fail-closed правила.
- `docs/ROADMAP.md`: шаг 2.1 отмечен как исследованный, этап 2 — IN PROGRESS; шаг 2.2 остаётся впереди.
- `CHANGELOG.md`: настоящая запись. Исходники Lua, настройки и версия не изменялись.
### Проверки
- **PASS:** статическая проверка перечисленных файлов репозитория и ZIP; наличие документов и ключевых контрактов.
- **NOT RUN:** Lua execution/синтаксический тест новой логики (нового Lua-кода нет), WoW Forever API, проверка биндов и ротации в игре.
### Выдано тестировщику
- Коммит и ZIP по `git log --grep KR-20261120-002` / `/archive/<SHA>.zip` после публикации; промежуточный игровой тест не требуется.
- Для единого QA этапа накоплены проверки версии клиента, API вне/в бою, панели, смены биндов, форм, макросов, рангов.
### Фактический результат и следующие действия
- Статус: **2.1 research completed / in-game QA NOT RUN**. Движок ещё не реализован.
- Следующий шаг: 2.2 безопасный адаптер API и модель событий; устранение найденных несоответствий .toc.
- Связи: предыдущий документирующий коммит `521473edccd8a431f91381b60828278be9e596cc` (KR-20261120-001).

# CHANGELOG — Kord Rotation

## 2026-11-20 — KR-20261120-001 — детализация этапа 2 (только документация)
- **Задача:** разбить этап «Ядро игровых данных» на исполнимые блоки и зафиксировать три требования: препятствия для RGB-автоматизации, реальные бинды, допуск способностей только с панелей Blizzard.
- **До:** в ROADMAP четыре общих пункта этапа 2; ограничения и критерии фильтра панели не определены.
- **После:** 12 подэтапов с зависимостями, критериями готовности, строгой обработкой UNKNOWN, архитектурой слотов/биндов, аудитом каналов автоматизации и единым игровым QA.
- **Причина:** без явного разделения адаптеров API, слотов и рекомендаций легко принять тестовые иконки/ручные keyLabel за работающий движок.
- **Файлы:** docs/ROADMAP.md и CHANGELOG.md; Lua-код, версия аддона и поведение не менялись.
- **Проверка:** логическая и структурная проверка плана по текущим исходникам; статические/игровые тесты аддона **NOT RUN** (изменений Lua нет). Поддержка конкретных API Forever **NOT VERIFIED IN GAME**.
- **Выдача:** коммит документации в main; нет новой игровой сборки и нет запроса промежуточного игрового теста.
- **Итог:** план зафиксирован; все 12 блоков остаются PLANNED.


Политика: **каждый коммит фиксируется подробно** по [docs/CHANGELOG_RULES.md](docs/CHANGELOG_RULES.md), включая причины, реальные проверки и выдачу пользователю. Новые записи — сверху. Отдельно фиксируются пользовательские баг-репорты и повторные проверки. Коммиты идентифицируются постоянным KR-ID из сообщения коммита и по Git SHA из истории.

## KR-20261120-023 — 0.1.7.9-rc2: исправления по первому игровому тесту
- Источник: первые замечания пользователя по 0.1.7.8-rc1 (значок миникарты не виден, непрозрачность требует ползунка и ввода, однотипные тултипы непонятны).
- Minimap: showMinimap по умолчанию true для новых установок, кнопка вынесена за край миникарты, поднята над её слоем; существующие сохранённые настройки showMinimap=false остаются уважаемыми.
- Display: непрозрачность фона иконки 0–100 теперь меняется ползунком и полем ручного ввода; значения проходят через существующий валидатор.
- Components/Locale: индивидуальные подробные русские и английские пояснения для ресурсоэкономии, action-bar glow, рамки/свечения, защит, прерываний, аудио, миникарты и прозрачности; для остальных ключей сохранён fallback до дальнейшего уточнения.
- Тесты: код изменён и сохранён в Git; фактическая повторная проверка в WoW Forever НЕ проводилась.
- Важно: на ранее настроенном клиенте сохранённый showMinimap=false требует включения переключателя «Дополнительно → Показывать кнопку миникарты».
- Логотип Logo.blp не менялся.

## KR-20261120-022 — 0.1.7.8-rc1: полноценный интерфейсный релиз-кандидат для первого QA
- Дата/время: 2026-11-20T14:18:56.382Z (UTC), точное Git-время в метаданных коммита.
- ID коммита: `git log --grep KR-20261120-022` (SHA собственного коммита не может быть вписан в его дерево).
- Этап: 1, **IMPLEMENTED / AWAITING IN-GAME QA**, не DONE. Тип: функциональное завершение интерфейсного этапа, кандидат к приёмке.
- Запрос: «Давай, прямо сейчас с одним заходом доделай оставшиеся функции интерфейса и выпусти сборку для первого полноценного теста».
- Родитель: `e5b8ec5753b51303eaa7af7aaf000a8c1dd40e58` (0.1.7.7).
- Файлы: новые `Core/SafeActions.lua`, `UI/MinimapButton.lua`; изменения `Core/Advanced.lua`, `Core/Locale.lua`, `Core/Diagnostics.lua`, `Core/Settings.lua`, `Core/AppearanceProfiles.lua`, `Core/RotationSettings.lua`, `Core/IndicatorSettings.lua`, `UI/Components.lua`, `UI/MainWindow.lua`, `UI/SpellIcon.lua`, `UI/RotationDisplay.lua`, `UI/Pages/AdvancedDiagnostics.lua`, `UI/Pages/IndicatorsProfiles.lua`, `Init.lua`, `KordRotation.toc`, README, ROADMAP, PROJECT_CONTEXT, STAGE_01_COMPLETION_AUDIT, STAGE_01_INTERFACE, STAGE_01_QA_PLAN, STAGE_01_RELEASE_CANDIDATE, CHANGELOG.

### Основание, ожидаемое/фактическое
Ранее 0.1.7.7 прошёл только статическую регрессию; UI имел подготовительные (неработающие) showMinimap/showTooltips, выбор языка строго по GetLocale, без отображения совместимости/отложенных действий, без дополнительного визуального оформления и явных кнопок перемещения на Главной. Во вкладке «Индикаторы» не было реального действия «тест звука»; опциональные области защит/interrupt/resource были лишь настройками. При этом боевого движка ещё нет и в рамках первого этапа он не должен выдумываться.
Ожидаемое после изменения: все опции интерфейса имеют реальные UI-действия либо явно объявлены контрактами будущего движка; пользователь получает один воспроизводимый кандидат и 44 теста. Фактические игровые результаты пока неизвестны.

### Изменения и причины
1. `MinimapButton.lua`: создаёт обычную кнопку возле миникарты, показом управляет showMinimap; ЛКМ окно, ПКМ вкладка Advanced, GameTooltip под контролем showTooltips. Использует неизменённый существующий `Media/Logo.blp`, не изобретает новый логотип.
2. `Advanced.lua`: язык auto/ru/en, 6 настраиваемых значений частот разных будущих подсистем (не работающий engine scheduler); showMinimap переключает кнопку немедленно, выбранный язык применяется на /reload; все три сброса теперь требуют подтверждения.
3. `SafeActions.lua`: очередь однократно подтверждённого ResetAll при InCombatLockdown до PLAYER_REGEN_ENABLED. Если состояние боя не доступно, сброс **отклоняется**, не удаляя сохранения; в бою лишь откладывается, а не исполняется. В очереди **нет** автонажатий способностей или защищённых боевых действий.
4. `Locale.lua`: locale override после InitializeSettings и обновление всех шести словарей новыми UI-ключами; удалён старый дубликат STATUS_waiting в ruRU. Модульная загрузка TOC поддерживает новый порядок.
5. `Diagnostics.lua`: GetBuildInfo/Interface, combat/protected state, очередь отложенных действий, профиль/уровень/метод/ветка/уверенность, безопасный read-only probe API с pcall, локализованные статусы. Нет доступа к недокументированным секретным данным.
6. `MainWindow.lua`: на Главной статус Auto/ST/AoE и категории protection/interrupt как сохранённые предпочтения; рабочие кнопки «Переместить тестовую панель» и «Проверить UI»; на «Отображение» фон/alpha, толщина рамки, интенсивность, цвет подсветки, цвет/тень/выравнивание текста.
7. `SpellIcon.lua` и `Settings.lua`: эти свойства нормализованы/сохраняются и действительно применяются к иконке (только оформление); `AppearanceProfiles.lua` включает их в Classic/Minimal/Compact и custom snapshot.
8. `RotationDisplay.lua` и `IndicatorSettings.lua`: подготовлены отдельные демо-слоты защиты (1–3), interrupt и пустая полоса ресурсов, выключены по умолчанию. В режиме «ТЕСТ» показывают исключительно вопросительные иконки/подпись без реальных боевых значений.
9. `IndicatorsProfiles.lua`: ручная кнопка звукового теста с pcall(PlaySound) и диагностическим сообщением. **Не** включаются звуковые оповещения из будущей боевой ротации.
10. `Init.lua` + TOC: 0.1.7.8-rc1, подключены SafeActions и MinimapButton. README, ТЗ, Roadmap, QA план и этот changelog обновлены одновременно.

### Проверки и ограничения
- [PASS] Статическая проверка 22 Lua-путей TOC (все существуют, без лишних), порядок Core/UI/Init и все девять page builders.
- [PASS] Сверка одинаковых ключей шести словарей, отсутствие дублей после исправления ruRU, локализация всех новых статических UI-строк.
- [PASS] Точное совпадение версии TOC/Init, предотвращение полного сброса с неизвестным InCombatLockdown или отсутствующим ReloadUI.
- [PASS] Отсутствие новой подсистемы автоматического cast/боевых таймеров, звуки только по ручной кнопке.
- [NOT RUN] Lua-парсер и полное выполнение; нет запуска исходников на настоящей Lua среде аддона в GitHub connector.
- [NOT RUN] WoW Forever: интерфейс, сворачивание, UI scale, Minimap/GameTooltip/PlaySound/GetBuildInfo API, сохранения /reload, все девять вкладок, 44 теста.
- [NOT RUN] Согласованность качества текущего BLP с окончательно утверждённым референсом (файл не менялся).

### Выдача тестировщику и итог
- Release candidate публикуется единым коммитом и архивом GitHub по его точному SHA, установка описана в `docs/STAGE_01_RELEASE_CANDIDATE.md`, 44 кейса — `docs/STAGE_01_QA_PLAN.md`.
- Пользователь теперь может провести **один** полный тест (включить Lua errors, пройти все 9 вкладок, сохранить таблицу PASS/FAIL/NOT RUN и stacktrace). Не требовать теста каждой последующей микроверсии.
- Этап 1: IMPLEMENTED / AWAITING IN-GAME QA, не DONE. Если обнаружатся ошибки, фиксировать их вместе с SHA и проводить общую регрессию. Этап 2 не запускать до результата пользователя.

## KR-20261120-021 — 0.1.7.7: ЕДИНАЯ статическая регрессия всех девяти вкладок

- Дата: 2026-11-20 UTC (точное время Git-коммита смотреть в git log, не подменять датой записи).
- Коммит: `git log --grep KR-20261120-021`; полный SHA опубликован отдельно после push.
- Этап/версия: этап 1 / 0.1.7.7. Статус **IN PROGRESS, NOT IN-GAME QA**.
- Тип: комплексная регрессия / bugfix / docs.
- Запрос: пользователь потребовал **одну общую проверку**, а не множество однотипных микрокоммитов.
- Файлы: `UI/MainWindow.lua`, `UI/Pages/AdvancedDiagnostics.lua`, `UI/Pages/IndicatorsProfiles.lua`, `UI/Components.lua`, `Core/AppearanceProfiles.lua`, `UI/RotationDisplay.lua`, `Core/RotationSettings.lua`, `Init.lua`, `KordRotation.toc`, `docs/STAGE_01_STATIC_REGRESSION.md`, README, ROADMAP, PROJECT_CONTEXT, STAGE_01_COMPLETION_AUDIT, STAGE_01_QA_PLAN, CHANGELOG.

### Контекст / воспроизведение
Ожидаемо: все девять страниц функционально связаны, настройки не вызывают Lua-ошибок на неготовом профиле, пользовательские пресеты синхронны, диагностика актуальна при повторном открытии. До исправления код содержал несколько подтверждённых статическим чтением дефектов: диагностическое обновление выполнялось лишь при видимости страницы; страница могла быть помечена initialized до завершения builder; StepRow делал арифметику с неподтверждённым getter; `SetSlotData(1.5,...)` мог обращаться к несуществующему слоту; Spell ID не имел верхнего предела; Profile UI не подтягивал активный пресет после внешних изменений. Эти сценарии **выведены из исходников, а не подтверждены отчётом игрового тестера**.

### Анализ причины
Общие UI компоненты добавлялись в несколько этапов, а их связность не была проверена в одном проходе. Ошибки наблюдаются на границах между страницами, состояниями и контрактами nil/number. Настоящая совместимость WoW Forever остаётся неизвестной, а не объявлена подтверждённой.

### Исправления в одном коммите
- `MainWindow:SelectPage`: отметка initialized теперь после builder, refresh callback вызывается на каждом открытии вкладки, сохраняя ленивую модель.
- `Pages:Diagnostics`: refresh callback выставлен на контейнер, поэтому после обновления журнала в скрытом состоянии повторное открытие перерисовывает отчёт.
- `AppearanceProfiles:Apply/SetAutoSpec` и `Pages:Profiles`: актуализация списка, выбор текущего профиля, применение per-spec привязки при включении.
- `UI:StepRow`: отсутствие числа/NaN/Infinity не приводит к сложению; данные не меняются.
- `RotationDisplay:SetSlotData`: только целые номера 1–5.
- `RotationSettings:GetSpell/SetSpell/ResetSpell/normalize`: положительный целый Spell ID до 99999999, с отбрасыванием невалидных SavedVariables ключей.
- Init/TOC 0.1.7.7, docs и CHANGELOG в том же коммите. Логотип не менялся.

### Проверки
- [PASS] Статическая проверка nine-page routing и builders; зарегистрированы Home/Display/Rotation/Abilities/Indicators/Profiles/Advanced/Diagnostics/About.
- [PASS] TOC включает 20 Lua модулей с Core → UI → Pages → Init; изменения не меняют load order.
- [PASS] Шесть словарей имеют одинаковые 273 ключа, нет дубликатов, все статические KR:L/KR:Format ключи найденных страниц имеют перевод.
- [PASS] Сверены ограничения Settings, IndicatorSettings и RotationSettings; проверены переходы false/nil, восстановление профиля, сбросы, UI buttons и callback.
- [PASS] Версия TOC=Init=0.1.7.7, оригинальная текстура не изменена.
- [NOT RUN] Lua parser и настоящее исполнение, mock tests / WoW Forever client, все внутриигровые скрины/положение/рендер/сохранения.
- [NOT RUN] Оригинальный BLP не перевыпускался; соответствие согласованному референсу остаётся отдельным решением.

### Выдача / тесты / результат
Вся матрица PASS/NOT RUN, конкретные дефекты и открытые ограничения записаны в `docs/STAGE_01_STATIC_REGRESSION.md`. Единый игровой тест содержится в `docs/STAGE_01_QA_PLAN.md`; **устанавливать эту промежуточную версию не требуется**. Не начинать ещё один цикл общей проверки интерфейса микрокоммитами: следующий шаг должен быть конкретно устранением оставшихся функциональных требований или выдачей окончательного кандидата. До фактического QA статус IN PROGRESS.
Родительский коммит: `b26b76facc94acecf5d644d136ebed8fa99bf25a`.

## KR-20261120-020 — 0.1.7.6: проверка SavedVariables перед созданием UI и защита полного сброса
- Дата/время: 2026-11-20T13:38:00Z (UTC, приблизительная запись в ходе текущей сессии; точное Git-время смотреть в коммите).
- Идентификатор: `git log --grep KR-20261120-020`, SHA самого коммита нельзя разместить в его содержимом.
- Этап / версия: этап 1, 0.1.7.6, IN PROGRESS, пользовательский этапный QA не проводился.
- Тип: bugfix / data validation.
- Основание: продолжение технической регрессии 0.1.7.5, аудит надёжности SavedVariables.

### Контекст и воспроизведение
- Ожидалось: при повреждении отдельного поля старого SavedVariables аддон должен восстановить только некорректное значение, а не передать строку или бесконечность в WoW `Frame:SetPoint`/`SetSize`.
- Фактически до исправления: `InitializeSettings` делал `copyMissing` (только отсутствующие поля), но не проверял `window.point/x/y/width/height` и `panel.x/y`. В `CreateMainWindow` эти значения передавались непосредственно в Frame API. Частичное повреждение сохранений могло ломать открытие окна; это вывод по коду, а не отчёт игрового тестера.
- Отдельно: в `Advanced:ResetAll` глобальные SavedVariables обнулялись до проверки наличия функции `ReloadUI`; при отсутствии API уже созданные UI-компоненты сохраняли ссылки на прежние таблицы.
- Воспроизведение по исходникам: в тестовой копии `KordRotationDB.window.x="bad"`, `point="UNSUPPORTED"`, `width="broken"`, `panel.y="invalid"`; загрузить UI и открыть окно. В реальном Forever НЕ ПРОВЕРЕНО; это сценарий для итогового общего QA.

### Причина
Отсутствовала нормализация сохранённых оконных координат и размеров, в отличие от нормализации более новых полей `panel`. Full Reset считал `ReloadUI` необязательным, хотя состояние UI и баз данных уже связано ссылками.

### Изменения
- `KordRotation/Core/Settings.lua`: `finiteOffset()` отвергает нечисловые, NaN/Infinity, ограничивает координаты ±10000; `normalizeWindow()` задаёт поддерживаемый центр и стандартные фиксированные размеры 880×570; `InitializeSettings()` валидирует `window`, `panel.x/y` и `showAtLogin`, не перезаписывая остальные пользовательские ключи.
- `KordRotation/Core/Advanced.lua`: `ResetAll()` перед очищением SavedVariables проверяет `ReloadUI`; при отсутствии функции сразу возвращает false, не производя частичного сброса. При наличии ReloadUI путь подтверждённого сброса остался прежним.
- `Init.lua` и TOC: версия 0.1.7.6, без изменения порядка загрузки модулей.
- README, PROJECT_CONTEXT, ROADMAP, STAGE_01_COMPLETION_AUDIT, STAGE_01_QA_PLAN и CHANGELOG согласованы в одном коммите.

### Проверки
- [PASS] Статический анализ: оба вида оконных offsets и panel offsets проходят `finiteOffset`; независимые повреждения `window` обрабатываются и при неправильном типе таблицы, и при неправильном типе отдельного поля.
- [PASS] Сохранённые размеры соответствуют нынешней нересайзовой вёрстке; неизвестные поля SavedVariables не удаляются; сброс блокируется при отсутствии ReloadUI.
- [PASS] Версии Init/TOC соответствуют 0.1.7.6; код логотипа и ротаций не менялся.
- [NOT RUN] Компилятор/интерпретатор Lua, тесты на самом WoW Forever, регрессия сохранённых профилей и /reload.
- [NOT RUN] Фактическое игровое поведение при отсутствии ReloadUI и повреждённом SavedVariables.

### Выдано тестировщику
Коммит доступен по ID в GitHub. Немедленная установка не требуется. Общий тест-план дополнен проверкой нормализации через резервную копию SavedVariables; реальные результаты записывать PASS/FAIL/NOT RUN после единого этапного QA.

### Результат, остаток и связь
Дефект по чтению повреждённых SavedVariables устранён в исходниках; совместимость на клиенте неизвестна. Дальше проверить оставшиеся компоненты, границы/переключатели, целостность TOC, приоритеты, затем подготовить один кандидат на пользовательское тестирование. Этап 1 остаётся IN PROGRESS.
Родительский коммит: `2e493bd94240070750774f8c2e8ecd2e7ebc0a16`.

## KR-20261120-019 — 0.1.7.5: исправлена заглушка «Дополнительно» и некорректная трактовка неопределённых API
- Дата: 2026-11-20 (UTC; Git metadata задают точный timestamp).
- Версия: 0.1.7.5; этап 1 IN PROGRESS, единый WoW Forever QA не запускался.
- Коммит: `git log --grep KR-20261120-019`. SHA собственного коммита нельзя включить в его же дерево.
- Источник: команда пользователя «Продолжай», техническая регрессия всех девяти вкладок и условий тестовой панели.
- **Симптом до исправления:** пункт меню `advanced` на 0.1.7.4 в `MainWindow.lua` отсутствовал среди ветвей `page.build` и попадал в fallback `makePlanned`; переход в «Дополнительно» не показывал ранее созданную страницу AdvancedDiagnostics. Второй дефект: формула `isPanelFlag and GetPanelFlag(key) or GetPanelLayout(key)` для ложного значения подставляла второй результат и маскировала явное `false`. Третий: `requireTarget` скрывал панель только при явном `false`; отсутствие API трактовалось как разрешение отображения.
- **Причина:** неполная регистрация маршрута при реализации 0.1.7; типичная ошибка Lua `and/or` при логическом false; недостаточно консервативный fallback API для явных ограничений.
- **Ожидаемое:** вкладка показывает настоящие дополнительные настройки; UI ToggleRow получает сохранённое `false`; условия видимости панели не нарушают строгие правила при неизвестных API.
- **Исправление:** `UI/MainWindow.lua` — добавлен маршрут `advanced -> KR.Pages:Advanced`, Getter boolean переписан в явное условие; `UI/RotationDisplay.lua` — требует `UnitExists(...) == true` для режима requireTarget и предотвращает обход ограниченных режимов при неизвестном combat state; `Init.lua`, `KordRotation.toc` — версия 0.1.7.5. Документы README, PROJECT_CONTEXT, ROADMAP, STAGE_01_COMPLETION_AUDIT, STAGE_01_QA_PLAN и этот CHANGELOG обновлены вместе с кодом.
- **Статическая проверка PASS:** 9 меню/маршрутов связаны с настоящими builders; нет прежнего `and/or` getter; 2 условия fail-closed присутствуют; версия Init/TOC совпадает; реализация logo/rotation untouched.
- **NOT RUN:** Lua parser/runtime и внутриигровые API Forever, полноценная отрисовка страниц и SavedVariables после /reload. Эти тесты нельзя засчитывать как PASS.
- **Накопленный единый QA:** перейти на «Дополнительно» и проверить настройки/сброс, отдельно false-параметры панели и состояние no-target/combat. Прочие 44 сценария остаются в `docs/STAGE_01_QA_PLAN.md`.
- **Результат:** конкретный сценарий недоступной страницы устранён в коде; этап 1 по-прежнему требует оставшихся UI-фиксов, статической проверки и одного общего теста. Следующий шаг: перепроверка целостности SavedVariables/компонентов и подготовка кандидата после устранения открытых пунктов.
- Предшествующий commit: `2607e45ce160033c701df538e105e07276a364ec`.

## KR-20261120-018 — 0.1.7.4: фирменный логотип в игровом формате BLP2
- Дата: 2026-11-20 UTC (фактическая дата/время коммита по Git).
- Коммит: `git log --grep=KR-20261120-018` (его SHA нельзя включить в собственное дерево).
- Этап: 1, устранение замечания по оформлению; версия 0.1.7.4; этап остаётся IN PROGRESS, без внутриигровой приёмки.
- Основание: неоднократно отложенный пункт аудита №1, исходный согласованный бренд KR/Kord Rotation и просьба пользователя завершать реальные задачи.
- Ожидалось/факт до изменения: на «Главной» был текстовый псевдологотип KR с Unicode-стрелками и надписью об ожидающем конвертации логотипе, несмотря на наличие подготовленных BLP-файлов вне репозитория. Это давало неподдерживаемые глифы и не выполняло брендовый пункт.
- Причина: бинарная BLP-текстура не была добавлена в дерево Git; предыдущие попытки повторно передать длинный файл прерывались.
- Исправление: использован ранее созданный и сверенный с локальным файлом Git blob `4913319b4a32531b388be1f7482ad0cef4104011`, включённый в дерево как `KordRotation/Media/Logo.blp`. `UI/MainWindow.lua` изменён на прямую загрузку текстуры BLP2, удалены KR/Unicode имитация и устаревшая подпись об ожидании. `Init.lua`, `KordRotation.toc`, README, ROADMAP, PROJECT_CONTEXT, STAGE_01_INTERFACE, QA_PLAN, AUDIT, CHANGELOG обновлены.
- Проверки: [PASS] локальный файл `logo-64.blp` BLP2, Pillow смог открыть как RGB 64×64; `git hash-object` файла совпадает с подготовленным Git blob SHA. [PASS] текстура из отдельного binary Git blob, не подменена буквальным base64 в Lua; корректный путь SetTexture. [PASS] обе строки версии согласованы — 0.1.7.4. [NOT RUN] отображение BLP именно на клиенте WoW Forever, разные масштабирования, читаемость.
- Тестирование: промежуточное не требуется. Включить в единый QA проверку Главной после чистой установки, /reload, визуальную правильность логотипа при разных UI scale и отсутствие квадратных символов.
- Риски и продолжение: отдельный значок миникарты и полная регрессия UI ещё открыты; фактическая загрузка BLP в Forever только после испытания. Следующие изменения в отдельном коммите с подробным CHANGELOG.
- Предыдущий коммит: `83fb7210179285bf563664fca290c517ec97c691`.

## KR-20261120-017 — 0.1.7.3: восстановление слоёв в профилях оформления и очистка удалённых привязок
- Дата: 2026-11-20 UTC (точное время Git-коммита в метаданных).
- Коммит: `git log --grep=KR-20261120-017` (самоссылка SHA внутри коммита невозможна).
- Этап: 1, исправление аудита; версия 0.1.7.3. Игровой QA не выполнялся.
- Тип: bugfix / regression / docs.
- Причина: в 0.1.7.2 добавили семь настроек слоёв и textSize, но прежний список `panelKeys` профилей оформления их не сохранял; удаление активного custom-пресета меняло только значение `activeAppearance`, а связи `appearanceBindings` оставались.
- Воспроизведение прежней ошибки: сохранить пресет со скрытой подписью клавиши, переключиться на иной и вернуть сохранённый — старые настройки слоёв не восстанавливаются. Связать пользовательский пресет с веткой и удалить — привязка указывает на несуществующий id; при удалении активного пользовательского пресета панель фактически не переходила в Classic.
- Изменения: `Core/AppearanceProfiles.lua` расширен до всех параметров оформления; Classic, Minimal, Compact получили явные значения слоёв/шрифта; удаление активного вызывает применение Classic и очищает связанные записи CharDB; OnCharacterRefresh обрабатывает устаревший профиль безопасно. `UI/Pages/IndicatorsProfiles.lua` показывает видимое имя активного custom-пресета и результат удаления; синхронизированы версия в Init/TOC, README, аудит, PROJECT_CONTEXT, QA_PLAN.
- Проверки: [PASS] статическая сверка полноты panelKeys с Settings; [PASS] отсутствие присваивания rotationProfiles и spells в профилях оформления; [PASS] обновлены операции удаления и автообновления; [PASS] версия Init/TOC 0.1.7.3. [NOT RUN] WoW Forever, SavedVariables /reload, Lua-парсер и события смены ветки.
- Результат: известный пробел совместимости сохранений и удаления профилей исправлен в исходниках. Полный этап 1 остаётся IN PROGRESS; оригинальная игровая текстура и другие пункты аудита остаются открытыми.
- Родительский коммит: `9fdcae92738989db504f3989988e098ae6675108`.

## KR-20261120-016 — 0.1.7.2: независимые слои боевой иконки, настройки и контракт данных
- Дата/время: 2026-11-20T12:47:23.624Z UTC (Git фиксирует точное время коммита).
- Коммит: `git log --grep=KR-20261120-016`; SHA собственного коммита не может находиться в его дереве.
- Этап/версия: исправление пунктов аудита этапа 1, 0.1.7.2; статус IN PROGRESS, без игрового QA.
- Тип: feature / audit remediation / docs.
- Причина: `docs/STAGE_01_INTERFACE.md` §§1.2, 1.5.4 требует отдельных слоёв иконок и настроек, до этого существовали только текстура, рамка и номер слота.
- Файлы: `KordRotation/UI/SpellIcon.lua`, `KordRotation/UI/RotationDisplay.lua`, `KordRotation/UI/MainWindow.lua`, `KordRotation/Core/Settings.lua`, `KordRotation/Core/Locale.lua`, `KordRotation/KordRotation.toc`, `KordRotation/Init.lua`, README, ROADMAP, PROJECT_CONTEXT, STAGE_01_INTERFACE, STAGE_01_QA_PLAN, STAGE_01_COMPLETION_AUDIT, CHANGELOG.

### Контекст / воспроизведение
Ранее иконка показывала вопросительный знак, порядковый номер и рамку. Нельзя было отдельно включить keybind/название/cooldown/charges/dimming/GCD, хотя ТЗ требует настройки слоёв. Воспроизведение по исходникам 0.1.7.1: `SpellIcon:Create` не содержал соответствующих текстовых регионов. В игровом клиенте текущая версия ещё не запускалась.

### Анализ причины
Недостающие слои были сознательно отложены на полный UI-аудит, тогда как боевой движок не существует. Любой статический cooldown/charges/Spell ID в тестовом режиме был бы недостоверным. Поэтому добавляется лишь контракт получения явного `data` от будущего достоверного движка и отдельная отрисовка, без придумывания значений. Защищённый WoW API чтения реальных заклинаний не вызывается.

### Что изменилось
- `SpellIcon.lua`: к имеющимся texture/border/index добавлены fontstring keybind/name/cooldownText/chargesText, overlay unavailableShade/gcdShade, контролируемый фон. `SetDisplayData(data)` принимает только переданные поля, `ClearDisplayData()` обнуляет; nil-данные скрывают слой. Фрейм один, не пересоздаётся от смены Spell ID. При получении data.texture меняется только текстура.
- `RotationDisplay.lua`: `SetSlotData(index,data)` для будущего провайдера, без автоматического чтения боевых данных. В `RefreshLayout` передаются настройки слоёв; при тестировании используется пустой data.
- `Settings.lua`: 7 булевых переключателей `showKeybind/showSpellName/showCooldown/showCharges/showUnavailable/showGCD/showIconBackground` и `textSize` 8–20 px; валидация и defaults для старых SavedVariables.
- `MainWindow.lua`: новый прокручиваемый блок с семью переключателями и размером текста; корректировка высоты ScrollFrame.
- `Locale.lua`: 10 новых ключей в `enUS/ruRU/frFR/deDE/ptBR/esES`, региональные алиасы без изменения.
- TOC и Init синхронизированы с 0.1.7.2, документы и итоговый тест-план дополнены.

### Проверки
- [PASS] Статическое чтение кода: нет циклического пересоздания Frame в `SetDisplayData`; 5 игровых иконок остаются заранее созданными.
- [PASS] Поля при отсутствии данных скрыты, тестовая текстура question mark остаётся; вызовы Spell ID/cooldown/bindings не добавлены.
- [PASS] Все новые настройки присутствуют в defaults/normalize/GetPanelLayout/SetPanelLayout; 10 новых ключей во всех шести языках, версии Init/TOC совпадают.
- [NOT RUN] Реальный WoW Forever: API CreateTexture/FontString, порядок OVERLAY и фон, размеры текстов, сохранение после reload.
- [NOT RUN] Lua parser/runtime и тесты передачи настоящих боевых значений от движка — последнего пока нет.

### Накопленный единый QA
Пока не устанавливать промежуточную сборку. После выпуска кандидата проверить на «Отображение» 7 toggles + size 8/20, сохранение после /reload, отсутствие фиктивных cooldown/keybind/charges в тестовом режиме, отсутствие Lua ошибок при смене количества/масштаба иконок.

### Результат и далее
Пункт слоёв частично закрыт **в исходниках**; остаются фирменный логотип, более подробные настройки текста/подсветки, начальная миникарта, закладки/надёжность и все проверки клиента. Статус этапа 1 IN PROGRESS, не DONE. Следующий подшаг — оригинальная игровая текстура/оставшиеся замечания аудита; затем финальная статическая проверка и общий QA этапа.
Связи: KR-20261120-015, SHA `ec3c9d2fa90341a861aeaff0d26c99d9ce53e130`.

## KR-20261120-015 — 0.1.7.1: быстрые настройки Главной и контролируемая видимость панели
- Дата/время: 2026-11-20T12:40:31.165Z (UTC; точное Git-время в метаданных коммита).
- Коммит: `git log --grep=KR-20261120-015`; собственный SHA нельзя разместить в этом же коммите.
- Этап/версия: дополнительное исправление аудита этапа 1 / исходники 0.1.7.1, IN PROGRESS; игровой QA не проводился.
- Тип: feature / audit remediation / docs.
- Основание: запрос «Продолжай», `docs/STAGE_01_INTERFACE.md` §§1.2, 1.4, 1.5 и `docs/STAGE_01_COMPLETION_AUDIT.md` пп. 2–3.
- Изменённые файлы: `KordRotation/Core/Settings.lua`, `KordRotation/UI/RotationDisplay.lua`, `KordRotation/UI/MainWindow.lua`, `KordRotation/Core/Locale.lua`, `KordRotation/Init.lua`, `KordRotation/KordRotation.toc`, README, ROADMAP, PROJECT_CONTEXT, STAGE_01_INTERFACE, STAGE_01_COMPLETION_AUDIT, STAGE_01_QA_PLAN, CHANGELOG.

### Контекст и воспроизведение
В 0.1.7 страница «Главная» имела только три кнопки теста/блокировки/сброса, а боевая панель проверяла лишь два булевых свойства showPanel/testMode без условий боя/цели/смерти/маунта. Ожидаемое: быстрые настройки в основном окне и сохраняемые условия видимости, согласованные с разделом «Отображение». Эти функции реализуются **для тестовой панели**, а не для фактического движка.
Шаги статического воспроизведения старого ограничения: просмотреть makeHome в `UI/MainWindow.lua` и Refresh в `UI/RotationDisplay.lua` версии 0.1.7. Среда: GitHub-исходники, клиент WoW Forever для текущего коммита недоступен.

### Анализ причины
Подтверждённая причина: часть §1.2 и §1.4 исходного ТЗ оставалась вне предыдущих подшагов; настройки не существовали в schema и не проверялись при Refresh. Риск: отдельные WoW API на Forever могут отсутствовать или вести себя иначе — `pcall` и unknown-data fallback предотвращают выдуманное состояние; неизвестный сигнал не приравнивается к ложному бойцовскому факту.

### Изменения и обоснование
- `Core/Settings.lua`: добавлены defaults и нормализация showInCombat/showOutOfCombat/requireTarget/hideWhenDead/hideMounted, API SetPanelFlag/GetPanelFlag принимает эти boolean поля; старые SavedVariables получают безопасные defaults.
- `UI/RotationDisplay.lua`: ShouldShow() рассматривает режим теста, бой, наличие цели, смерть и маунт. Доступность функций проверяется защищённым pcall; событие-driven refresh на PLAYER_REGEN, PLAYER_TARGET_CHANGED, PLAYER_DEAD/ALIVE/UNGHOST, UNIT_FLAGS и PLAYER_MOUNT_DISPLAY_CHANGED. Нет OnUpdate-поллинга и нет каких-либо cast/protected action.
- `UI/MainWindow.lua`: «Главная» стала прокручиваемой, введены четыре быстрых тумблера (будущие рекомендации текущей ветки, showPanel, testMode, locked) и кнопка перехода в «Отображение»; значения синхронизированы через общие Settings API. В «Отображение» новая группа пяти опций видимости, не дублирующая хранилище.
- `Core/Locale.lua`: 10 новых ключей во всех 6 словарях; Init/TOC версия 0.1.7.1; профиль класса и Spell ID остаются без перевода.
- README/ROADMAP/PROJECT_CONTEXT/STAGE_01/QA_PLAN/AUDIT/CHANGELOG обновлены в том же коммите.

### Проверки
- [PASS] Статическая сверка всех 5 ключей в defaults/нормализации/SetPanelFlag и в конфигурационном UI.
- [PASS] Логика ShouldShow() не показывает реальную ротацию без testMode; не вызывает незащищённых API при отсутствии функции.
- [PASS] Существующая система размеров 1–5 и три самостоятельные команды не заменялись.
- [PASS] 10 новых ключей на каждый из 6 языков; версия TOC/Init согласована.
- [NOT RUN] Lua parser/runtime и игровой клиент WoW Forever, события, видимость в бою/при смерти/на маунте, сохранение после reload.
- [NOT RUN] Фирменный TGA/BLP логотип. Оригинальный скриншот пользователя найден среди материалов, но опубликованного корректного бинарного ассета в репозитории нет.

### Накопленный тестовый план
Немедленных действий от пользователя нет. В общий QA добавить быстрые настройки Главной, переход к вкладке Отображение, проверку флагов showPanel/testMode/combat/target/death/mounted, события и сохранение. Не считать статус PASS до фактического отчёта тестера.

### Результат и остаток
Устранены два частичных замечания audit пп. 2–3 в исходниках. **Этап 1 ещё не завершён:** не все слои и подробные статусы, оригинальный логотип TGA/BLP, совместимость API и regressions. Следующим шагом продолжить устранение открытых audit пунктов, после полной статической проверки — единый игровой QA. Не переходить к этапу 2.
Связь: KR-20261120-014, SHA `afc623c5b88980463504a0772c3dcb5c5c4951be`.

## KR-20261120-014 — 0.1.7: Дополнительно/Диагностика/О проекте и честный аудит завершённости этапа 1
- Дата/время: 2026-11-20T12:26:58.700Z (UTC; фактическое Git-время — в коммите).
- Коммит: `git log --grep=KR-20261120-014` (SHA нельзя включить в собственное содержимое).
- Этап/версия: этап 1 / исходники 0.1.7. **Нумерованный подшаг реализован; полный этап ещё НЕ завершён и НЕ проверен.**
- Тип: feature / QA planning / docs.
- Задача: пользователь «Продолжай. Продолжай.», `docs/STAGE_01_INTERFACE.md` §§1.10–1.12, 1.16–1.18, `AGENTS.md`.
- Файлы: `Core/Diagnostics.lua`, `Core/Advanced.lua`, `UI/Pages/AdvancedDiagnostics.lua`, `Core/SpecDetector.lua`, `UI/MainWindow.lua`, `Init.lua`, `KordRotation.toc`, `Core/Locale.lua`, `docs/STAGE_01_QA_PLAN.md`, `docs/STAGE_01_COMPLETION_AUDIT.md`, README, ROADMAP, PROJECT_CONTEXT, STAGE_01_INTERFACE, CHANGELOG.

### Контекст и воспроизведение
Ожидалось: вкладки «Дополнительно», «Диагностика», «О проекте» завершат серию интерфейсных подшагов, а тестировщик получит один комплексный тест только после выполнения исходного полного ТЗ. Фактически до 0.1.7 раздел «Дополнительно» был заглушкой, диагностика давала только восемь полей талантов, «О проекте» не раскрывала реальное число 0/27 работающих ротаций. Предыдущие 0.1.2–0.1.6 не проходили пользовательскую регрессию.
Воспроизведение: открыть эти разделы на 0.1.6, сравнить с §§1.10–1.12 полного ТЗ. Среда изменений: GitHub исходники без клиента WoW Forever, частичные старые подтверждения тестирования относятся только к 0.1.0, охотнику в 0.1.1 и ruRU 0.1.1.1.

### Анализ причины
Причина отсутствия функций: последовательная реализация проекта, 0.1.7 оставлен для трёх последних страниц. Полный интерфейсный этап нельзя считать DONE только по версии номера: аудит §1.0–1.18 выявил оставшиеся обязательные слои, фирменную игровую текстуру, настройки видимости и недостаточную регрессию. Отсутствие реальных боевых API и engine — запланированная граница этапа, но существующие контролы обязаны честно сообщать о неактивных функциях.

### Что изменено и почему
- `Core/Advanced.lua`: типизированные и нормализованные параметры, автооткрытие (старое положение `showAtLogin`), контроль сообщения загрузки, подготовительные flags подсказок/миникарты/частот, разделённые операции reset appearance/current tree/all. Полный reset инициируется только из отдельного диалога подтверждения.
- `Core/Diagnostics.lua`: bounded кольцевой журнал не более 80 записей, не внешнее хранилище; уровень, модуль, время, ограничение текста; самообследование наличия нескольких публичных API без вызовов защищённого боя; Report с информацией о персонаже/профиле/очках/панели, последней ошибке, списком возможностей; отчёт можно выделить вручную.
- `Core/SpecDetector.lua`: записи обновления класса/ветки в ограниченную диагностику.
- `UI/Pages/AdvancedDiagnostics.lua`: отдельные три страницы с прокруткой, переключателями и stepper, подтверждение общего сброса, отчёт EditBox для ручного Ctrl+C, кнопки обновления/очистки и честная страница о проекте.
- `UI/MainWindow.lua`: старые локальные варианты «Диагностика» и «О проекте» заменены новыми модулями, «Дополнительно» перестало быть заглушкой; dev paths зарегистрированы при первом открытии.
- `Core/Locale.lua`: 32 новых ключа во всех шести языках, `Init.lua`/TOC версии 0.1.7 с правильной последовательностью Core/UI.
- `docs/STAGE_01_QA_PLAN.md`: 44 подробных кейса, объединяющих все вкладки и SavedVariables; **пока это тест-план, а не выполненные результаты**.
- `docs/STAGE_01_COMPLETION_AUDIT.md`: перечислены открытые пункты полного ТЗ (оригинальный логотип/TGA, дополнительные слои и условия видимости, часть Главной, неактивный minimap и др.) — запрещено объявлять этап DONE, пока не закрыты или явно согласованно ограничены.

### Проверки
- [PASS] Источник ТЗ §1.0–1.18 перечитан; зафиксирована разница между нумерацией версий и полным объёмом этапа.
- [PASS] Статическое сравнение TOC/Init версии 0.1.7 и зависимостей, ссылка на все девять страниц, шесть словарей для новых ключей.
- [PASS] Журнал ограничен 80 записями; общая очистка требует отдельного пользовательского подтверждения; отчёт не вызывает clipboard API; 0/27 фактически реализованных ротаций явно указаны.
- [NOT RUN] Исполнение Lua parser/runtime и тесты боевого UI; отсутствует клиент и прогоны симулятора в этом окружении.
- [NOT RUN] Подтверждение layout, взаимодействий, text wrapping, кнопок и сохранения на WoW Forever.
- [NOT RUN] Итоговые 44 тест-кейса: тест-план создан, тесты ещё не запускались.

### Выдано тестировщику / единый QA
План тестирования записан в `docs/STAGE_01_QA_PLAN.md`, но **выполнить его сейчас НЕ требуется**. После закрытия выявленного аудита и выпуска release candidate разработчик предоставит точный SHA и один чек-лист. Пользователь не должен устанавливать каждую промежуточную сборку. Исключение: настоящий API-блокер, который нельзя обойти статической проверкой.

### Результат и дальнейшие действия
Исходники 0.1.7 подготовлены. **Статус этапа 1: IN PROGRESS (open acceptance gaps), не IMPLEMENTED/DONE; пользователю не объявлялся завершённый этап.** Следующий подшаг — закрытие пунктов аудита интерфейса и статическая проверка, затем общий игровой тест и исправления. Только после приёмки переходить к этапу 2.
Связи: KR-20261120-013, SHA `eab525a15a3c028f923a30007529cde75c928f2d`.

## KR-20261120-013 — 0.1.6: вкладки Индикаторы и Профили оформления
- Дата/время: 2026-11-20T12:14:06.322Z UTC (точное время коммита определяет Git).
- Коммит: `git log --grep=KR-20261120-013` (SHA невозможно включить в тот же Git-коммит).
- Этап/версия: этап 1 / 0.1.6; код подготовлен, этапный игровой QA ожидается после 0.1.7.
- Тип: feature / docs.
- Задача: пользователь «Продолжай», `docs/STAGE_01_INTERFACE.md` §§1.8–1.9. Не смешивать профили ротаций и оформления.
- Изменены: `KordRotation/Core/IndicatorSettings.lua`, `KordRotation/Core/AppearanceProfiles.lua`, `KordRotation/UI/Pages/IndicatorsProfiles.lua`, `KordRotation/UI/MainWindow.lua`, `KordRotation/Core/Locale.lua`, `KordRotation/Init.lua`, `KordRotation/KordRotation.toc`, `README.md`, `docs/PROJECT_CONTEXT.md`, `docs/ROADMAP.md`, `docs/STAGE_01_INTERFACE.md`, `CHANGELOG.md`.

### Контекст и воспроизведение
Ожидалось: вкладки должны предлагать настройки будущих боевых индикаторов и самостоятельные пресеты оформления. Ранее в 0.1.5 они показывали только заглушки «запланировано». Среда: GitHub исходный Lua-код; реальный клиент Forever не запускался. Воспроизведение исходного состояния: открыть вкладки «Индикаторы» и «Профили» в коде 0.1.5, увидеть текстовые заглушки.

### Анализ причины
Причина: это не регрессия, а следующая нереализованная часть интерфейсного этапа. Для подсветки и прерываний отсутствует проверенный по клиенту combat/actionbar API, поэтому добавление ложных игровых эффектов нарушило бы принцип достоверности. Для оформления требовался независимый от `rotationProfiles` механизм сохранения. Разделили модели на `indicators` и `appearanceProfiles`; привязка к специализации хранится отдельно в CharDB.

### Что изменено и почему
- `Core/IndicatorSettings.lua`: дефолты и валидация boolean/enum/числовых диапазонов actionHighlight, highlightStyle/Strength/Count, defensiveEnabled/Slots/Size/Alpha/CombatOnly, interruptEnabled/SpellID/Size/Text/Sound, audioEnabled/Important/Defensive/Interrupt/Cooldown и флагов запланированных виджетов. Чтение/запись UI через одно API, без доступа к защищённым combat API.
- `Core/AppearanceProfiles.lua`: встроенные Classic/Minimal/Compact, пользовательский снимок только параметров `panel`, независимые операции Create/Duplicate/Rename/Delete/Apply, запрет удаления встроенных, ResetAppearance, optional bindings через `KordRotationCharDB.appearanceBindings`. При неопределённой ветке AssignCurrent отклоняется. Никогда не затрагивает `rotationProfiles` или настройки отдельных заклинаний.
- `UI/Pages/IndicatorsProfiles.lua`: прокручиваемые страницы с локализованными ToggleRow, ChoiceRow, StepRow, список пресетов с пагинацией, текстовое поле имени, действия, отдельный диалог подтверждения удаления. Текущие значения и предупреждения об ещё не реализованном боевом поведении.
- `UI/MainWindow.lua`: подключение вкладок и обновление оформления при смене автоматически определённой специализации.
- `Core/Locale.lua`: 57 ключей добавлены во все шесть словарей; версия Init и TOC 0.1.6; соответствующий порядок загрузки.
- README, PROJECT_CONTEXT, ROADMAP, STAGE_01, CHANGELOG: актуализированы статусы и сценарии общего тестирования.

### Проверки
- [PASS] Статическая сверка кода: отдельные таблицы хранилища UI и ротаций, три предустановки и защита удаления встроенных, проверка имён/чисел/boolean/enum.
- [PASS] TOC содержит оба Core-модуля перед MainWindow/Pages, Init после модулей; версия 0.1.6.
- [PASS] 57 новых локализационных ключей для каждого языка enUS/ruRU/frFR/deDE/ptBR/esES.
- [PASS] Нет попыток выдать неподтверждённое чтение боевых данных или звуки за работающие функции.
- [NOT RUN] Lua runtime/парсер, игровой API WoW Forever, реальная отрисовка прокрутки/диалога, изменяемые настройки и SavedVariables после reload.
- [PENDING] Обобщённый пользовательский тест после всей реализации этапа 1.

### Выдано тестировщику — накопленный QA
Текущую версию устанавливать не нужно. После 0.1.7 проверить: корректность отображения страниц, чисел и локализаций; переключатели и сохранение индикаторов; отсутствие ложных боевых рекомендаций; создание, дублирование, переименование, применение и удаление оформления только с подтверждением, невозможность удалить встроенные пресеты; независимость от ротационных профилей; привязку к текущей ветке и сохранение после reload. Все обнаруженные ошибки регистрировать отдельно в CHANGELOG с этапной регрессией.

### Фактический результат и дальнейшие действия
Система настроек индикаторов и оформления реализована в коде, но не проверена в WoW Forever; часть функций намеренно остаётся конфигурационными заготовками, поскольку движок и боевые API ещё не подключены. Следующий подшаг 0.1.7 — «Дополнительно», расширенная «Диагностика», «О проекте», завершающая самопроверка и единый чек-лист игрового тестирования. Статус этапа IN PROGRESS.
Связи: KR-20261120-012, коммит `b77c7ea9c6c877b806c3cc910565331fec1caacb`.

## KR-20261120-012 — 0.1.5: Ротация/Способности, настройки профиля и безопасный читатель книги заклинаний
- Дата/время: 2026-11-20T12:03:00.814Z UTC (фактические Git-метаданные после коммита).
- Коммит: `git log --grep=KR-20261120-012` (встроенная самоссылка SHA невозможна).
- Этап/версия: этап 1 / 0.1.5; исходники подготовлены, игровой QA отложен до конца этапа 1.
- Тип: feature / docs.
- Задача/источник: «Продолжай», `docs/STAGE_01_INTERFACE.md` 1.6–1.7, 1.13–1.15; разделение UI от ещё не существующего движка.
- Изменённые файлы: `Core/RotationSettings.lua`, `Core/SpellCatalogue.lua`, `UI/Pages/RotationAbilities.lua`, `UI/MainWindow.lua`, `Core/Locale.lua`, `Init.lua`, `KordRotation.toc`, README, PROJECT_CONTEXT, ROADMAP, STAGE_01_INTERFACE, CHANGELOG.

### Контекст и воспроизведение
Ожидалось: вкладки «Ротация» и «Способности» способны показывать профиль реально определённого персонажа и готовить настройки на будущий движок, не выдавая непроверенные приоритеты. До 0.1.5 это были только сообщения «планируется». В предыдущих сборках автодетектор уже возвращал `HUNTER_TREE_1` для подтверждённого пользователем охотника 30 уровня; никаких настоящих правил ротаций ещё не существует. Среда: исходники GitHub, WoW Forever не запускался.
Воспроизведение старого состояния: открыть 0.1.4, вкладки «Ротация»/«Способности» содержат только заглушки.

### Анализ причины
Причина отсутствия страниц: запланированные подшаги 0.1.0–0.1.4 не включали их реализацию. Нельзя выбирать класс вручную, хранить профили по переведённым именам, выдумывать ID заклинаний или считать интерфейс работающим движком. Выбраны стабильные `CLASS_TREE_N`/числовые `Spell ID` и только feature-detected API чтения книги заклинаний.
Риск совместимости: Classic spellbook API `GetNumSpellTabs/GetSpellTabInfo/GetSpellBookItemInfo` может отсутствовать на клиенте Forever; в этом случае статус `unavailable`, без утверждения, что список заклинаний полон. Чтение книги/названий ограничено защитными вызовами `pcall` и ограничителями циклов.
Ограничение модели: категории и правила — сохранённые предпочтения, но боевой движок не читает их.

### Что изменено и почему
- `Core/RotationSettings.lua`: `GetProfileID/GetProfile` с безопасной обработкой отсутствующей ветки, defaults и миграцией типизированных настроек, Auto/ST/AoE, девять категорий, флаги условий, per-Spell ID override (enabled, separate, category, keyLabel до 32 байт), ResetSpell. Отдельные профили хранятся в `KordRotationDB.rotationProfiles`, а не по локализованному тексту.
- `Core/SpellCatalogue.lua`: адаптер чтения известной книги заклинаний игрока, безопасные `pcall`, дедупликация по Spell ID, алфавитная сортировка, фильтры поиска по названию/ID и категории, явный статус недоступности.
- `UI/Pages/RotationAbilities.lua`: scrollable страницы, переключатель будущих рекомендаций с предупреждением, ручной режим Auto/ST/AoE, категории и условия; поиск и фильтр книги, 7 строк на страницу, кнопки пагинации/обновления, выбор и настройка конкретного заклинания, локализованные подписи.
- `UI/MainWindow.lua`: подключение двух ленивых страниц и обновление после событий изменения талантов; при отсутствии API список не выдумывается.
- `Core/Locale.lua`: 50 новых ключей на шести языках. Технические ID остаются неизменными.
- `Init.lua` и TOC: версия 0.1.5, правильный порядок загрузки Core до Pages.
- README, PROJECT_CONTEXT, ROADMAP, STAGE_01_INTERFACE, CHANGELOG: актуальный прогресс и накопленные случаи для комплексного теста.

### Проверки
- [PASS] Статическая проверка регистрации 9 страниц, порядка загрузки двух модулей Core и Pages из .toc.
- [PASS] Сохранение данных по неизменяемому `CLASS_TREE_N`, ключи Spell ID числовые; строгие boolean/enum и обработка неопределённой ветки.
- [PASS] SpellCatalogue не содержит статических/выдуманных Spell ID; пользователь видит только то, что удалось прочитать из SpellBook.
- [PASS] UI-строки и названия категорий берутся из 6 словарей; 50 ключей записаны для каждого языка.
- [NOT RUN] Реальное исполнение Lua на Forever, полнота/совместимость SpellBook API, результат spell name/icon, текстовые метки и перенос длинных строк.
- [NOT RUN] Проверка SavedVariables после /reload; изменение талантов/класса; защищённый бой.
- [PENDING] Итоговая игровая проверка после завершения 0.1.7.

### Выдано тестировщику — накопленный QA
Промежуточную 0.1.5 не устанавливать. В итоговом тесте этапа 1: сопоставить профиль/очки с Диагностикой; переключать Auto/ST/AoE и категории; проверить сохранение по веткам; проверить читатель SpellBook, корректность имен/ID/иконок, строк поиска, фильтров, страницы списка и карточку выбранной способности; настройки enable/separate/category/keyLabel, сброс, /reload; убедиться в отсутствии настоящей ротации и автокаста.

### Фактический результат и следующие действия
Вкладки реализованы в исходниках, ротационный движок не создан и тест в игре отложен согласно заказчику. Следующий подшаг 0.1.6 — «Индикаторы» и «Профили» с безопасной моделью сохранения. Статус этапа 1 IN PROGRESS.
Связи: KR-20261120-011, SHA `dcab161b6eefd15174fb1912779ccf0764bde1e6`.

## KR-20261120-011 — 0.1.4: параметры размеров, раскладки, прозрачности и рамок боевой панели
- Дата/время: 2026-11-20T11:52:48.517Z (UTC; фактическое время Git-коммита в Git).
- Коммит: `git log --grep=KR-20261120-011` (самоссылку SHA в этот файл нельзя вставить).
- Этап/версия: этап 1 / 0.1.4; реализация подшага завершена, игровой тест отложен до общей приёмки этапа 1.
- Тип: feature / docs.
- Задача/источник: пользователь «Продолжай», план `docs/STAGE_01_INTERFACE.md` разделы 1.2 и 1.5.2–1.5.3, после 0.1.3.
- Файлы: `KordRotation/Core/Settings.lua`, `KordRotation/UI/Components.lua`, `KordRotation/UI/SpellIcon.lua`, `KordRotation/UI/RotationDisplay.lua`, `KordRotation/UI/MainWindow.lua`, `KordRotation/Core/Locale.lua`, `KordRotation/Init.lua`, `KordRotation/KordRotation.toc`, `README.md`, `docs/PROJECT_CONTEXT.md`, `docs/ROADMAP.md`, `docs/STAGE_01_INTERFACE.md`, `CHANGELOG.md`.

### Контекст и воспроизведение
Ожидалось: пользователь может независимо менять количество тестовых слотов 1–5, размеры, направление, расстояние, масштаб и прозрачность, с сохранением в SavedVariables. Фактически до 0.1.4 существовали только три фиксированных слота 72/52/52 и отсутствие работающих layout-контролов. Старое поведение: `/kr test` показывал жёстко зафиксированные 3 иконки; новые размеры или количество установить было невозможно. Среда: GitHub/Lua-код; игру не запускали.

### Анализ причины
Фиксированные значения и создание ровно трёх слотов были сознательными ограничениями первого прототипа 0.1.2. Настройки отображения из подробного ТЗ 1.5 ещё не были подключены. Это не найденный игровой баг. Риск: WoW Forever API рендера ScrollFrame, SetScale/SetAlpha и поведение при экстремальных размерах требуют единой будущей приёмки на клиенте.

### Что изменено и почему
- `Core/Settings.lua`: единый `SetPanelLayout/GetPanelLayout`, сервер SavedVariables, строгая проверка разрешённых типов, числовых диапазонов и перечислений, нормализация старых значений при загрузке. Значения defaults: 3 слота, 72/52, gap 6, scale 100, alpha 100, vertical OFF, primaryAtEnd OFF, border standard, showNumbers ON.
- `UI/Components.lua`: многоразовые StepRow (+/-) и ChoiceRow с локализованными подписями; никакого ручного дублирования логики сохранения.
- `UI/SpellIcon.lua`: применение видимости индекса, alpha дополнительных иконок, стандартной/минимальной/отсутствующей рамки без пересоздания.
- `UI/RotationDisplay.lua`: создаёт 5 тестовых слотов один раз; `RefreshLayout` рассчитывает размеры и расположение по настройкам, допускает вертикальный ряд и положение главной иконки в конце, ставит SetScale/SetAlpha. Реальная ротационная очередь не реализуется и тестовые текстуры явно помечены.
- `UI/MainWindow.lua`: ScrollFrame страницы «Отображение» с группами флагов, чисел, вариантов и кнопкой восстановления позиции.
- `Core/Locale.lua`: 20 новых переводных ключей для каждого из шести языков. `Init.lua` и TOC: синхронизирована версия 0.1.4.
- README, PROJECT_CONTEXT, ROADMAP, STAGE_01_INTERFACE, CHANGELOG: добавлен прогресс и сценарии для **общего** теста этапа.

### Проверки
- [PASS] Статическая проверка диапазонов числовых параметров и единых setters/getters; старые данные с неверным типом нормализуются.
- [PASS] Математика размеров: горизонтальный extent = main + other*(count-1) + gap*(count-1); вертикальная высота аналогична, ширина берётся как max(main, other).
- [PASS] Five-slot reuse: `Create` создаёт пять фреймов один раз; RefreshLayout изменяет точки и размеры без создания новых.
- [PASS] Новые ключи имеют значения во всех шести словарях; TOC и версия исходников 0.1.4 синхронизированы.
- [NOT RUN] Рендеринг/прокрутка и реальная интерактивность на WoW Forever (пользовательский этапный тест отложен).
- [NOT RUN] Профессиональный инструмент Lua parser / game runtime пока не запускался; исходники проверены чтением.
- [PENDING] Сохранение после reload, 0% alpha, граничные размеры и UI scale проверить на финальном этапе.

### Выдано тестировщику — накопленный QA
Промежуточную сборку устанавливать не нужно. В будущий единый чек-лист после 0.1.7 входят: 1–5 слотов, 32–128 и 24–96 px, gap 0–30, scale 50–200%, alpha 0/100, рамки, ориентация, главная иконка в конце, сохранение settings/position, переключение с Главной и через команды. Отсутствие ротационного движка должно честно отображаться.

### Фактический результат и следующие действия
0.1.4 реализован в исходниках GitHub, но не объявляется протестированным в WoW. Следующий подшаг: 0.1.5 — страницы «Ротация» и «Способности», контракты настроек и безопасная подготовка UI к будущему движку. Финальный тест интерфейса по завершении 0.1.7.
Связи: KR-20261120-010; commit `1782cb3bf3c204b1e585aa5b27f6d590024242bf`.

## KR-20261120-010 — 0.1.3: полноценная навигация и страницы Главная / Отображение

- Дата/время: 2026-11-20T11:46:24.040Z (UTC; фактическое время коммита см. Git).
- Коммит: `git log --grep=KR-20261120-010` (SHA собственного коммита не может находиться внутри него).
- Этап/версия: этап 1, версия исходников 0.1.3; подшаг реализован, пользовательский QA отложен до 0.1.7.
- Тип: feature / docs.
- Задача: согласно `docs/STAGE_01_INTERFACE.md`, пункт 0.1.3, наполнить «Главная» и «Отображение», зарегистрировать 9 лениво создаваемых страниц, добавить единые элементы управления и сохранение.
- Изменённые файлы: `KordRotation/Core/Settings.lua`, `KordRotation/UI/Components.lua`, `KordRotation/UI/MainWindow.lua`, `KordRotation/UI/RotationDisplay.lua`, `KordRotation/Core/Locale.lua`, `KordRotation/Init.lua`, `KordRotation/KordRotation.toc`, `README.md`, `docs/PROJECT_CONTEXT.md`, `docs/ROADMAP.md`, `docs/STAGE_01_INTERFACE.md`, `CHANGELOG.md`.

### Контекст и воспроизведение
Ожидалось: два содержательных раздела с общими работающими настройками и созданием неиспользуемых страниц только по запросу. До изменения «Отображение» было простой заглушкой, «Главная» показывала только имя класса/ветку и три команды теста, а все страницы создавались сразу при загрузке окна. Среда: код GitHub, тестовый Forever клиент отсутствует.
Воспроизведение старого состояния: открыть раздел «Отображение» версии 0.1.2 — текст «запланировано» без реальных элементов.

### Анализ причины
Причина — раздел запланирован на 0.1.3, а предыдущая итерация 0.1.2 обеспечила лишь тестовую панель и первые кнопки. Независимые прямые изменения `db.panel` в разных местах могли привести к рассинхронизации интерфейса после появления отдельной страницы. Для предотвращения создан один API настроек и обновления.
Риски: игровой API создания шаблонных кнопок и позиционирования на Forever пока не проверен; изменение ленивой инициализации нужно проверить при первом и повторном открытии страниц.

### Что изменено и почему
- `Core/Settings.lua`: добавлены defaults панели, `GetPanelFlag/SetPanelFlag`, проверка ключей и boolean, одно сохранённое состояние для команды, главной и страницы отображения.
- `UI/Components.lua`: переиспользуемый `ToggleRow` (локализованная надпись + состояние, клик, hover).
- `UI/MainWindow.lua`: 9 страниц регистрируются сразу и строятся один раз при первом выборе; активная «Отображение» содержит три независимых переключателя, координаты и reset; «Главная» дополнилась очками талантов, методом группировки и ID профиля с явной пометкой отсутствующего движка.
- `UI/RotationDisplay.lua`: команды тест/lock читают и изменяют общие panel flags; сброс обновляет оба UI.
- `Core/Locale.lua`: 14 локализованных ключей для всех 6 языков (ruRU, enUS, frFR, deDE, ptBR, esES); внутренние API и profile ID не переводятся.
- `Init.lua` и `KordRotation.toc`: версия 0.1.3, `UI/Components.lua` загружается до MainWindow.
- README, Roadmap, Stage01 и PROJECT_CONTEXT: обновлён фактический прогресс и долг финальных тестов.
- Три лицензионных notice в новом Lua файле; root LICENSE не изменена.

### Проверки
- [PASS] Git дерево содержит новый Components и согласованный TOC-порядок; 9 ключей страниц неизменны.
- [PASS] Статически проверен единый API для `showPanel`, `testMode`, `locked`; reset использует данные SavedVariables, обновление видимых состояний привязано к setter.
- [PASS] 14 новых строк присутствуют в шести словарях; оригинальные внутренние идентификаторы не переведены.
- [PASS] По исходнику не добавлен ротационный движок, Spell ID или фиктивное автоматическое выполнение способностей.
- [NOT RUN] Lua parser/runtime: доступного клиента WoW или исполнения Lua в этом интеграционном окружении нет.
- [NOT RUN] Внутриигровые события мыши, сохранение позиции, визуальные наложения/перенос строк.
- [PENDING] Единый пользовательский тест после реализации 0.1.7.

### Выдано тестировщику / накопленный QA этапа
Немедленная установка **не нужна**. После 0.1.7 включить в комплексный список:
1. Первое и повторное открытие всех 9 страниц, отсутствие дублированных контролов/обработчиков.
2. «Главная»: верные класс, специализация, очки и метод, ID профиля и честная пометка «не реализован».
3. «Отображение»: показать/спрятать тест, блокировать/разблокировать, запретить отображение (даже если тест включён), снова разрешить.
4. Согласованность двух страниц и `/kr test`, `/kr lock`, `/kr resetposition`; положение после `/reload`.
5. Русские подписи и английский fallback, проверка шести языков при наличии клиентов.
В качестве базы для теста использовать итоговый SHA всего этапа 1, а не промежуточную 0.1.3.

### Результат и дальнейшие действия
Подшаг 0.1.3 реализован в исходниках. На реальном клиенте проверка ещё не проводилась; статус этапа 1 IN PROGRESS. Следующий подшаг 0.1.4: размеры 1–5 слотов, направления/раскладка, прозрачность, рамки и сохранение. Никаких промежуточных пользовательских /reload не требуется.
Связи: KR-20261120-009, коммит `91ae1062fd44cd02baf18db2aa9386f94d1ae7a3`.

## KR-20261120-009 — новый рабочий протокол: полный этап, затем один комплексный QA

- Дата/время: 2026-11-20T11:40:49.074Z (UTC; фактическое время коммита см. Git).
- Коммит: `git log --grep=KR-20261120-009` (SHA невозможно вписать в собственный коммит).
- Этап/версия: процесс разработки этапов 1–7; текущий код 0.1.2 не изменяется.
- Тип: docs / workflow.
- Задача: заказчик не желает повторно скачивать и перезагружать аддон ради каждого небольшого подшага. Разработать все шаги одного пункта Roadmap, документируя каждый, затем выдать один большой тест.
- Файлы: `AGENTS.md`, `docs/PROJECT_CONTEXT.md`, `docs/ROADMAP.md`, `docs/CHANGELOG_RULES.md`, `CHANGELOG.md`.

### Контекст и воспроизведение
Ожидалось: пункт Roadmap разбивается на содержательные шаги, после каждого фиксируется реальный код и CHANGELOG, но игрок тестирует **целый завершённый этап**, например весь интерфейс после 0.1.7. Фактически раньше после каждого 0.1.0–0.1.2 пользователь получал отдельную просьбу скачать сборку, сделать /reload и проверить отдельные элементы.
Среда: процесс разработки и GitHub; игровая среда не использовалась. Шаги для наблюдения прежней проблемы: посмотреть несколько последних ответов с инструкциями установки после каждого маленького релиза.

### Анализ причины
Подтверждённая причина неудобства: прежний рабочий цикл ошибочно отождествлял внутренний кодовый подшаг с внешней приёмкой игрока. Это не дефект API или Lua. Исправление — разделить **частые коммиты и автоматические/статические проверки** от **редкого большого пользовательского QA**.

### Что изменено и почему
- `AGENTS.md`: зафиксирован обязательный для любого нового чата режим «подшаг -> код -> подробный коммит и CHANGELOG -> ответ о следующем шаге». Без немедленного требования запуска игры.
- `docs/PROJECT_CONTEXT.md`: постоянное решение заказчика, ближайшая последовательность 0.1.3–0.1.7, сохранение уже проведённых проверок 0.1.0/0.1.1/0.1.1.1.
- `docs/ROADMAP.md`: этап 1 остаётся IN PROGRESS, 0.1.2 входит в накопленный итоговый тест; критерий DONE — после общего QA.
- `docs/CHANGELOG_RULES.md`: каждый подшаг по-прежнему подробно документируется, но «выдано тестировщику» означает описание будущего этапного сценария и ссылку на коммит, не обязательную промежуточную установку.
- `CHANGELOG.md`: подробная запись о смене процесса без переопределения фактов старых коммитов.

### Проверки
- [PASS] Проверена согласованность нового правила с прежним требованием CHANGELOG в **каждом** коммите.
- [PASS] Проверена последовательность полного этапа интерфейса 0.1.0–0.1.7; цель и наполнение девяти вкладок не сокращены.
- [NOT RUN / NOT APPLICABLE] Внутриигровое тестирование, так как меняются только документы.
- [PASS] Существующие подтверждённые тесты 0.1.0, HUNTER 0.1.1 и русской локали 0.1.1.1 не переписаны и не объявлены повторно пройденными.

### Выдано тестировщику
Ссылка на рабочий коммит и новый регламент. **Немедленных действий в игре не требуется.** Следующее действие разработчика: подшаг 0.1.3 (навигация/реализация страниц «Главная» и «Отображение»). Накопить тест-кейсы в ТЗ этапа и выдать один подробный сценарий после завершения 0.1.7.

### Фактический результат и следующие действия
Правила процесса изменены; игровой код остаётся 0.1.2 и пока не был проверен в игре. Следовать Roadmap последовательно: 0.1.3 -> 0.1.4 -> 0.1.5 -> 0.1.6 -> 0.1.7 -> общий тест всего интерфейса. Только после исправления обнаруженных на общем QA проблем двигаться к этапу 2. Статус: workflow введён, продолжение кода ещё впереди.
Связи: KR-20261120-008, коммит `c2360dd9d890f25356e6d4351946e8bb4274a7de`.

## KR-20261120-008 — 0.1.2: тестовая боевая панель (3 иконки), управление, сохранение

- Дата/время: 2026-11-20T11:34:05.081Z (UTC; точное время Git-коммита — в истории).
- Коммит: `git log --grep=KR-20261120-008` (SHA нельзя встроить в собственный коммит).
- Этап/версия: этап 1, 0.1.2; статус **ожидает пользовательского теста**.
- Тип: feature / docs / test record.
- Задача: после подтверждения пользователем 0.1.1.1 продолжить Roadmap, шаг 0.1.2; не подменять отсутствие ротаций фиктивными способностями.
- Файлы: `KordRotation/UI/SpellIcon.lua`, `KordRotation/UI/RotationDisplay.lua`, `KordRotation/UI/MainWindow.lua`, `KordRotation/Core/Locale.lua`, `KordRotation/Init.lua`, `KordRotation/KordRotation.toc`, `README.md`, `docs/PROJECT_CONTEXT.md`, `docs/ROADMAP.md`, `docs/STAGE_01_INTERFACE.md`, `CHANGELOG.md`.

### Пользовательский тест предыдущей сборки 0.1.1.1
- Дата сообщения: 2026-11-20 (точные часы не предоставлены).
- Тестировщик: пользователь, русский клиент WoW Forever; точный build не указан.
- Проверенный SHA: `ec60f4ddff7c87d1971583940a22ca09f6e0ef06`.
- Действия: пользователь проверил русские подписи и ранее проблемный разделитель имени персонажа/ветки.
- Ожидалось: русский интерфейс, ASCII-дефис вместо непечатаемого глифа.
- Фактически: «всё на русском», прямоугольник исчез, появилась линия; пользователь сообщил, что всё хорошо.
- [USER PASS] Русская локализация 0.1.1.1; устранение прямоугольника из `BUG-20261120-002`.
- [NOT TESTED] enUS/frFR/deDE/ptBR/esES и региональные алиасы, длинные тексты, другие билды клиента.
- Итог: `BUG-20261120-002` закрыт по подтверждению пользователя для ruRU и этого клиента.

### Контекст и воспроизведение новой задачи
До 0.1.2 была только панель настроек, отдельного отображения рекомендации на экране не существовало. Ожидалось 3 тестовых слота с главной иконкой 72 пикселя, двумя по 52, промежутком 6, возможностью переместить, заблокировать и включить тест без ротационного движка.
Среда разработки: GitHub исходники, без запуска Forever. Шаги после установки: `/reload`, `/kr test`, `/kr lock`, перетаскивание, `/kr resetposition`.

### Анализ причины и риски
Отсутствие панели обусловлено стадией работ, не багом предыдущей сборки. Реальная очередь ещё не вычисляется, поэтому отображение якобы боевых способностей создало бы ложные рекомендации. Реализованы очевидные тестовые вопросительные текстуры и явная маркировка; производственный режим без ротационного профиля **скрывает панель**. Адаптер Spell ID и умная видимость — дальнейшие этапы.
Отдельный риск: API и перетаскивание/слои текста требуют подтверждения на реальном WoW Forever.

### Что изменено и почему
- `UI/SpellIcon.lua`: переиспользуемый слот с безопасной системной текстурой вопросительного знака, числовой позицией, рамкой и cyan-выделением главной иконки; без выдуманных Spell ID.
- `UI/RotationDisplay.lua`: отдельная игровая панель 188x78 для 72/52/52, gap 6, метка TEST, показ только при активном тестовом режиме и showPanel, drag только после разблокировки, сохранение координат, сброс (0,-120).
- `UI/MainWindow.lua`: на «Главная» 3 кнопки (тест, lock, reset), которые используют то же API, что и команды.
- `Init.lua`: /kr test, /kr lock, /kr resetposition; создание панели при входе; версия 0.1.2.
- `Core/Locale.lua`: 13 новых/обновлённых строк в каждом из шести словарей, английский fallback по предыдущему правилу.
- TOC, проектные документы, Roadmap, README, CHANGELOG обновлены синхронно.
- В двух новых Lua-файлах три уведомления об авторском праве; корневая LICENSE остаётся действующей.

### Проверки
- [PASS] Статическая сверка размеров: 72 + 6 + 52 + 6 + 52 = 188, неравные размеры не пересекаются; панель из трёх слотов.
- [PASS] Исходный код не вызывает Spell ID, не имитирует вычисление ротации и скрывает тестовые значки по умолчанию.
- [PASS] TOC содержит новые модули до MainWindow и Init; сохранены 9 страниц, 6 языков.
- [NOT RUN] Интеграционное тестирование на WoW Forever: окна, слои, перетаскивание, реальное сохранение после /reload.
- [NOT RUN] Остальные клиенты и языки; другие режимы видимости, пользовательские размеры 1–5: план 0.1.4.
- [PENDING] Повторная пользовательская проверка 0.1.2.

### Выдано тестировщику
Скачать main, заменить `Interface/AddOns/KordRotation`, выполнить `/reload`. Команда `/kr test` включает/выключает 3 вопросительных слота; /kr lock снимает блокировку, мышью можно переместить; /kr resetposition возвращает положение, /reload должен сохранять положение и тестовый режим. Те же операции доступны с «Главная». Проверить без ошибок Lua, первая иконка должна быть крупнее, метка теста должна быть видна. Если ошибка — полный Lua trace и скриншот.

### Фактический результат и следующие действия
Код 0.1.2 подготовлен, опубликовывается для пользовательской проверки; тест на реальном клиенте ещё не проводился. После подтверждения перейти к 0.1.3 (страница «Отображение» и полноценные элементы настроек). Связи: KR-20261120-007, BUG-20261120-002, SHA `ec60f4ddff7c87d1971583940a22ca09f6e0ef06`.

## KR-20261120-007 — пользовательский тест 0.1.1 и мультиязычный интерфейс 0.1.1.1
- Дата/время: 2026-11-20T11:25:43.714Z UTC; точный timestamp коммита устанавливается по Git.
- Коммит: `git log --grep=KR-20261120-007` (SHA самого коммита в его содержимое встроить невозможно).
- Этап/версия: этап 1, 0.1.1.1; ждём пользовательского теста новой сборки.
- Тип: feature / fix / test record / docs.
- Задача: запрос пользователя на автоматический выбор языка игрового клиента. Связанный отчёт: `BUG-20261120-002` — прямоугольник вместо разделителя класса и специализации.
- Файлы: `KordRotation/Core/Locale.lua` (новый), `KordRotation/UI/MainWindow.lua`, `KordRotation/Init.lua`, `KordRotation/KordRotation.toc`, `README.md`, `AGENTS.md`, `docs/PROJECT_CONTEXT.md`, `docs/STAGE_01_INTERFACE.md`, `docs/ROADMAP.md`, `CHANGELOG.md`.

### Подтверждённый пользовательский тест 0.1.1
- Кто: пользователь проекта; отчёт поступил 2026-11-20 (точное время не предоставлено).
- Тестируемый SHA: `c3c991bb5eb90297fafab339933de0830f0cb86f`.
- Среда: клиент пользователя WoW Forever, охотник уровня 30; точная версия клиента не сообщена.
- Шаги: открыть `/kr`, затем `/kr debug`, прочитать распознанный класс, ветку, очки, метод и статус.
- Ожидалось: HUNTER, Beast Mastery, 21/0/0, `header_groups`, статус `confirmed`.
- Получено от пользователя: класс Охотник [HUNTER], уровень 30, конфигурация 695-83-31 (возможен формат интерфейса/визуального чтения, не заявлять числом), очки `21 / 0 / 0`, метод `header_groups`, ветка «Повелитель зверей», статус `confirmed`.
- [USER PASS] Выбор класса, уровня, ведущей ветки охотника на этом персонаже.
- [NOT TESTED] Все прочие классы, другие распределения талантов, равенство очков, смена ветки.
- Наблюдение BUG-20261120-002: квадрат вместо типографского разделителя `·` в строке персонажа на русской локали. Гипотеза: используемый игровой шрифт не содержит нужный глиф (не подтверждена тестом шрифта). Исправление: заменить на `-` и вынести строку в таблицу локализации.

### Контекст и анализ причины
Ожидание: интерфейс на языке клиента в русском, английском, французском, немецком, португальском и испанском. Фактически прежний интерфейс содержал литералы на русском независимо от `GetLocale()`, а технические статусы и диагностические ключи на английском. Это не проблема алгоритма определения специализации, а отсутствие модуля локализации. Необходимость региональных вариантов: `esES/esMX`, `ptBR/ptPT`.
Причина квадрата в строке персонажа до запуска новой версии не подтверждена, но использование необязательного Unicode глифа не нужно для интерфейса.

### Что изменено и почему
- Новый `Core/Locale.lua`: 6 словарей, функции `KR:L`, `KR:Format`, `KR:GetLocalizedTree`; `GetLocale()` с алиасами `enGB`, `esMX`, `ptPT`; английский fallback для неподдерживаемых языков/ключей.
- `UI/MainWindow.lua`: все девять заголовков меню, основной экран, About, диагностические подписи, статусы и названия веток из словаря, разделитель ASCII дефис. Никакого дополнительного выбора класса или языка не требуется.
- `Init.lua`: сообщения `/kr help`, `/kr refresh`, предупреждения и сообщение запуска переведены, версия 0.1.1.1.
- TOC загружает локаль **до** построения интерфейса, версия 0.1.1.1, сохраняя 0.1.2 для планируемой боевой панели.
- README/PROJECT_CONTEXT/STAGE_01/ROADMAP/AGENTS: новое обязательное правило централизованных переводов на всех следующих этапах.
- Внутренние profile ID, class token, технические коды остаются стабильными; изменяется только подпись.
- Корейский/китайский/итальянский переводы ещё не добавлены: для этих клиентов пока безопасный английский fallback, без заявлений о готовой локализации.

### Проверки
- [PASS] Статическая сверка структуры словарей, ключей и региональных алиасов.
- [PASS] Вырезана прямая конкатенация `class..' · '..spec`; все пользовательские строки UI из словаря.
- [NOT RUN] Lua runtime и загрузка 0.1.1.1 в WoW Forever; среда пользователя не подключена.
- [NOT RUN] Клиенты frFR, deDE, ptBR, ptPT, esES, esMX, enUS, enGB.
- [PENDING] Проверка шрифтов, переносов текста, длинных названий вкладок, переведённой диагностики и повторного устранения квадратов.

### Выдано тестировщику
Загрузить ветку main, заменить папку AddOns/KordRotation, выполнить `/reload`. Открыть `/kr` и `/kr debug`. На русском клиенте проверить корректность подписей, отсутствие квадрата между «Охотник» и «Повелитель зверей» и русские статусы. Другие языки проверять на реальных настройках локали клиента; не подменять `GetLocale()`. При любой проблеме передать locale, билд, скриншот и точный текст ошибки.

### Результат и следующие действия
Публикуется централизованная основа локализации; первая игровая проверка ожидается. После подтверждения продолжить 0.1.2: боевая панель из трёх тестовых иконок. Статус BUG-20261120-002: кодовая правка подготовлена, **не подтверждена пользователем**.
Связи: KR-20261120-006, `c3c991bb5eb90297fafab339933de0830f0cb86f`.

## KR-20261120-006 — подтверждение 0.1.0 и детектор класса/талантов 0.1.1
- Дата/время: 2026-11-20T11:02:38.118Z UTC (фактический Git time определяется по коммиту).
- Коммит: `git log --grep=KR-20261120-006` (самоссылка на SHA невозможна).
- Этап/версия: этап 1, 0.1.1, ожидает пользовательской проверки.
- Тип: feature / test record / docs.
- Задача/источник: продолжение Roadmap после подтверждения пользователем успешного 0.1.0; референс `Sonah.zip`, `Core/Atoms/Talents.lua`; код Sonah не копировался.
- Файлы: `KordRotation/Core/Character.lua`, `Core/Talents.lua`, `Core/SpecDetector.lua`, `UI/MainWindow.lua`, `Init.lua`, `KordRotation.toc`, README, PROJECT_CONTEXT, ROADMAP, CHANGELOG.

### Пользовательское тестирование предыдущей сборки
- Тестировщик: пользователь проекта, сообщение 2026-11-20 (точное время в сообщении не указано).
- Проверенный коммит: `9e56e3e218e2930d1124490b9c137f0dbf71f971` (0.1.0).
- Среда: клиент пользователя WoW Forever, билд не предоставлен.
- Действия: открыл окно, переключил все вкладки.
- Ожидаемо: окно открывается; навигация работает без Lua-ошибок.
- Фактически: пользователь подтвердил, что всё открывается, вкладки переключаются, ошибок нет.
- [USER PASS] Открытие главного окна и переключение страниц.
- [NOT RUN / NOT REPORTED] Перемещение/сохранение координат, поведение после reload, экстремальные разрешения, совместимость с другими аддонами.
- Решение: продолжить по плану; неизвестные тесты не считать пройденными.

### Контекст и воспроизведение
До 0.1.1 интерфейс не получал класс и очки талантов, а вкладка «Диагностика» была заглушкой. Ожидалось автоматическое определение класса и ведущей ветки 3 деревьев с безопасным состоянием при отсутствии данных. Среда нового кода: GitHub исходники, тест на клиенте ещё не проводился.

### Анализ причины и выбор решения
Недостающая возможность — ранее этот этап не был реализован, не регрессия. Анализ Sonah показывает, что Forever хранит три классических ветки как секции единой конфигурации `C_Traits`; поэтому нельзя считать три `treeID` тремя классическими ветками. Реализован отдельный адаптер с `GetActiveConfigID/GetConfigInfo/GetTreeNodes/GetNodeInfo`, группировкой `groupIDs` по заголовкам и **предварительным** fallback по самым широким промежуткам X. Резервный способ может ошибиться, он помечен provisional. Ограниченные/secret данные не преобразуются в вымышленные числа.

### Что изменено и почему
- `Character.lua`: защищённый `pcall` запрос `UnitClass/UnitLevel`; автоматический класс.
- `Talents.lua`: чтение ID активной конфигурации, узлов и фактических рангов; суммирование по трём секциям; явные причины unavailable; метод группировки.
- `SpecDetector.lua`: 9 классов и названия веток, выбор уникального максимума, сохранение предыдущей подтверждённой ветки при ничьей; 0/0/0 и непрояснённые ничьи = undetermined.
- `MainWindow.lua`: поле персонажа на «Главная» и новая диагностическая страница с классом, конфигурацией, счётом, методом, статусом, кнопкой обновления.
- `Init.lua`: slash `/kr debug`, `/kr refresh`; обработка событий изменения талантов/уровня; версия 0.1.1.
- `.toc`: порядок загрузки модулей и версия.
- Документация обновлена с результатом пользователя 0.1.0 и текущим статусом 0.1.1.
- Все добавленные Lua-файлы содержат три лицензионных уведомления.

### Проверки
- [PASS] Изучен непосредственный ZIP-референс `Sonah/Core/Atoms/Talents.lua` и схема группировки C_Traits.
- [PASS] Статическая сверка .toc, модулей, связей и текстов отладочного UI.
- [NOT RUN] Реальные значения C_Traits/группировка на живом персонаже, game API, Lua runtime.
- [NOT RUN] Воин/маг/другие классы; сброс талантов, ничья, переключение наборов.
- [PENDING] Пользовательская проверка 0.1.1.

### Выдано тестировщику
Установить обновлённую папку `KordRotation` в AddOns, выполнить `/reload`, затем `/kr debug`. Проверить правильность класса, уровня, **трёх сумм очков** в порядке деревьев и выбранной специализации. Прислать скрин диагностической вкладки и класс/суммы реального персонажа. `/kr refresh` — краткая строка в чате. При ошибке прислать полный Lua error, версию клиента, повторяемость, состояние talents.

### Результат и следующий шаг
0.1.0: первая базовая проверка пользователем подтверждена. 0.1.1: исходники предоставлены к тестированию; точность группировки **не доказана** на клиенте. Следующий шаг: исправить обнаруженные несоответствия API или перейти к 0.1.2 после подтверждения.
Связи: KR-20261120-005, коммит `9e56e3e218e2930d1124490b9c137f0dbf71f971`.

## KR-20261120-005 — начало этапа 1, UI 0.1.0 и проприетарная лицензия

- Дата/время: 2026-11-20T10:41:02.783Z (UTC; Git commit time берётся из метаданных после публикации)
- Коммит: `git log --grep=KR-20261120-005` (самоссылка SHA в файле невозможна)
- Этап/версия: 1 / прототип 0.1.0 — **IN PROGRESS**, запуск на Forever не подтверждён
- Тип: feature / docs / legal
- Задача: запрос пользователя начать MainFrame по плану, разместить бренд, создать лицензию и повторяющиеся авторские уведомления
- Изменённые файлы: `KordRotation/KordRotation.toc`, `KordRotation/Core/Settings.lua`, `KordRotation/UI/Theme.lua`, `KordRotation/UI/MainWindow.lua`, `KordRotation/Init.lua`, `LICENSE`, `docs/LEGAL_AND_AI.md`, `README.md`, `docs/PROJECT_CONTEXT.md`, `docs/ROADMAP.md`, `docs/STAGE_01_INTERFACE.md`, `CHANGELOG.md`

### Контекст и воспроизведение
Ожидалось: первый устанавливаемый каркас интерфейса с Modern Dark окном, навигацией, информацией о проекте, slash-командами, SavedVariables; права использования и обязательные notice в исходниках. Фактически: до изменений репозиторий содержал документацию и бренд-референсы, но не Lua/TOC и не LICENSE.
Воспроизведение исходного состояния: открыть main на `89a76f08b9b56443b7a2850b807c4e892b89e19e`; кодовых файлов не существовало. Среда разработки: GitHub; тестовый клиент игры не подключён.

### Анализ причины
Причина отсутствия UI: этап программирования ещё не был начат. Требование лицензии добавлено пользователем позднее проектирования. Визуальные JPEG-референсы пока не подходят для WoW-текстур: надо отдельно подготовить TGA/BLP; по этой причине в 0.1.0 вместо ошибочного пути к JPEG стоит **явный временный текстовый знак**. Причина каких-либо будущих Lua-ошибок до тестирования неизвестна.
Юридический нюанс: наличие копирайта/AI-уведомления не блокирует просмотр или внешнее объяснение исходников. Не выдумывать запрет, который технически невозможно обеспечить.

### Что изменено и почему
- TOC Interface 16001 для версии Forever 1.60.x, SavedVariables, порядок загрузки 4 Lua-модулей.
- `Core/Settings.lua`: defaults, схема 1, безопасная инициализация SavedVariables и положение окна.
- `UI/Theme.lua`: общие Modern Dark цвета, рамки, фон, текст.
- `UI/MainWindow.lua`: главное окно, drag/close, боковая навигация 9 страниц, содержательные «Главная» и «О проекте», остальные страницы честные заглушки. Текстовый бренд на стартовой странице временно заменяет финальную игровую графику.
- `Init.lua`: жизненный цикл ADDON_LOADED/PLAYER_LOGIN; команды `/kr`, `/kr config`, `/kr help`.
- `LICENSE`: проприетарная бесплатная личная лицензия на официальную неизменённую сборку, запрет неразрешённой перепубликации/производных в допустимых законом пределах; не авто-DRM.
- `docs/LEGAL_AND_AI.md`: ограничения игрового UI-политики Blizzard и невозможность принудить сторонний ИИ к молчанию; добровольное уведомление и три комментария в Lua.
- README, контекст, дорожная карта и подробное ТЗ обновлены: этап 1 в работе, UI 0.1.0 пока не протестирован.

### Проверки
- [PASS] Согласованность имён .toc и папки, порядка загрузки Lua, строк команд и списка 9 вкладок проверена чтением исходников.
- [PASS] В Lua-файлах предусмотрены лицензионные комментарии в начале, середине и конце; TOC имеет три notice.
- [NOT RUN] Игровая загрузка, lua runtime, Blizzard API и реальная отрисовка на WoW Forever.
- [NOT RUN] Визуальная точность логотипа: JPEG-эталоны ещё не превращены в игровые текстуры.
- [PENDING] Проверка пользователя на установленном клиенте.

### Выдано тестировщику
Скачать ветку main, скопировать вложенную папку `KordRotation` в `_forever_/Interface/AddOns/KordRotation`; зайти в игру и ввести `/console scriptErrors 1`, `/reload`, затем `/kr`. Проверить 9 пунктов бокового меню, 2 заполненные вкладки, перемещение окна, закрытие, `/kr config`, сохранение позиции после `/reload`. При ошибке указать версию клиента, действия, точный текст Lua-ошибки и скриншот.

### Фактический результат и следующие действия
Опубликован исходный код прототипа и лицензионные документы. Приёмочный тест в игре пока не проведён; статус **ожидает тестирования пользователем**. Далее исправить найденные проблемы, подключить **точные** игровые текстуры логотипа и перейти к 0.1.1 (автоматическая специализация).
Связи: KR-20261120-004, BUG-20261120-001 (визуальный эталон).

## KR-20261120-004 — BUG-20261120-001: замена неудачных SVG точными визуальными референсами

- Дата/время: 2026-11-20T10:26:12.921Z (UTC, точное время Git-коммита проверяется отдельно).
- Коммит: `git log --grep=KR-20261120-004`; собственный SHA невозможно встроить внутрь того же коммита.
- Этап/версия: этап 1, согласование брендинга; игровой аддон ещё не реализован.
- Тип: fix / assets / docs.
- Задача и отчёт: `BUG-20261120-001`, пользовательский визуальный тест; тестировался коммит `78191aa7c8369d812436f41401a33ae576ca8f30`.
- Файлы: удалены `assets/branding/logo.svg`, `assets/branding/icon-kr.svg`; добавлены `assets/branding/logo-reference.jpg`, `assets/branding/minimap-reference.jpg`; обновлены `assets/branding/README.md` и `CHANGELOG.md`.

### Контекст и воспроизведение
Ожидалось: логотип полностью соответствует первому утверждённому изображению (характерная металлическая монограмма KR, форма верхней/нижней стрелок, курсивный KORD и разреженный ROTATION) и круглая иконка миникарты из второго изображения.
Фактически: предыдущие `logo.svg` и `icon-kr.svg` заметно отличались от утверждённого эскиза; пользователь отверг их и приложил два изображения для визуального сравнения. Воспроизведение: открыть файлы коммита `78191aa7...` и сравнить с предоставленными `Screenshot_11.jpg` и `Screenshot_12.jpg`. Среда: GitHub/визуальное сравнение, не WoW Forever.

### Анализ причины
Подтверждённая причина: предыдущие SVG были нарисованы заново упрощёнными геометрическими фигурами без трассировки/точного использования утверждённого исходника. Изменились форма букв, композиция, градиенты и стрелки; художественная интерпретация была ошибочно выдана за согласованный логотип.
Гипотеза/ограничение: изготовление высококачественных прозрачных игровых текстур потребует отдельной подготовки альфа-канала и тестов.

### Что изменено и почему
- Удалены два неудачных SVG из текущей ветки, чтобы не использовать их в дальнейшей разработке.
- Вместо вольного рисунка помещены **обрезанные изображения именно из скриншотов пользователя**: `logo-reference.jpg` и `minimap-reference.jpg`. Убраны подписи, уменьшено разрешение для компактного просмотра в репозитории. Эти JPEG — **визуальные эталоны**, не окончательные assets WoW.
- README теперь прямо запрещает использовать старые SVG и описывает следующий шаг: подготовить PNG/TGA/BLP с прозрачностью из утверждённой композиции после согласования.

### Проверки
- [PASS] Оба Git blob созданы из изображений пользователя: `f3d727ba3cd6c1b749dcdf9f6dabb8720c58833e` и `4ee363ab881241bd83a7fbd6af10bc9a46a75f57`.
- [PASS] Старые SVG исключены из дерева новой ревизии; проверка состояния Git после коммита.
- [NOT RUN] Тест в WoW Forever: ещё нет игровых текстур/интерфейса.
- [NOT RUN] Проверка прозрачности и высококачественного экспорта: это JPEG с тёмным фоном и уменьшенным разрешением.
- [PENDING] Повторная визуальная проверка пользователем.

### Выдано тестировщику
Ссылки GitHub: `assets/branding/logo-reference.jpg` и `assets/branding/minimap-reference.jpg`. Сравнить форму KR и стрелок с приложенными скриншотами и подтвердить, что это верный референс.
Отдельно предоставлены локальные более крупные обрезанные версии. Их нельзя считать напрямую готовыми текстурами WoW.

### Фактический результат и следующие действия
Исходные визуальные эталоны проекта заменены на пользовательские; неправильные SVG удалены из `main`, но сохраняются в историческом коммите (стандартная история Git).
Дальше: создать качественные прозрачные изображения и игровые текстуры с сохранением точного рисунка; отдельно протестировать в WoW Forever.
Статус BUG-20261120-001: исправлен источник референса, ожидается подтверждение визуального соответствия и завершение подготовки ассетов.
Связи: `KR-20261120-003`; коммит `78191aa7c8369d812436f41401a33ae576ca8f30`.

## KR-20261120-003 — официальный логотип Modern Dark
- Дата/время: 2026-11-20T10:16:20.876Z (UTC; точное время коммита по Git)
- Коммит: `git log --grep=KR-20261120-003` (SHA собственного коммита не может находиться внутри него)
- Этап/версия: 1, бренд-ассеты перед реализацией UI; версия приложения не меняется
- Тип: asset / docs
- Задача: пользователь утвердил первый концепт (металлические KR, голубые стрелки, KORD ROTATION) и запросил создать и поместить логотип на GitHub
- Изменённые файлы: `assets/branding/logo.svg`, `assets/branding/icon-kr.svg`, `assets/branding/README.md`, `CHANGELOG.md`

### Контекст и воспроизведение
Ожидалось: отдельный файл официального логотипа в репозитории, пригодный для дальнейшего оформления UI. Фактически до изменения существовали только визуальные изображения концепта в переписке; бренд-ассетов в репозитории не было. Среда: GitHub; WoW Forever не запускался.

### Анализ причины
Причина отсутствия файлов: концепт был согласован на изображении, но не переведён в отдельные исходные ассеты. Это не ошибка игрового клиента. Ограничение: SVG — исходник для оформления и экспорта, не подтверждённый формат текстур WoW.

### Что изменено и почему
- `logo.svg`: создан самостоятельный векторный логотип со знаком KR, двумя циклическими стрелками и надписью KORD ROTATION на прозрачном фоне. Нужен для шапки настроек, документации и сборки текстур.
- `icon-kr.svg`: версия без надписи для маленьких размеров, миникарты и кнопок.
- `assets/branding/README.md`: принципы брендинга, цветовая палитра и статус игрового экспорта.
- `CHANGELOG.md`: зафиксирована причина, набор файлов, проверки и выдача.
Дизайн является собственной SVG-перерисовкой по первому согласованному концепту; точная пиксельная идентичность изображению-концепту не заявляется.

### Проверки
- [PASS] Созданы валидные XML/SVG текстовые исходники с прозрачным фоном и именами KORD ROTATION/KR.
- [NOT RUN] Визуальная проверка отрисовки GitHub и WoW Forever в реальном клиенте.
- [NOT RUN] PNG/TGA/BLP экспорт и проверка миникарты в игре.
- [PENDING] Пользовательское подтверждение соответствия первому концепту.

### Выдано тестировщику
GitHub: `assets/branding/logo.svg` и `assets/branding/icon-kr.svg`.
Проверить в браузере GitHub отображение эмблемы, круговых стрелок и надписи; подтвердить сходство с утверждённым первым концептом. Для игры перед подключением экспорта потребуется отдельный тест формата.

### Фактический результат и следующие действия
Исходные файлы логотипа включены в репозиторий; работа игрового UI не заявляется. Статус: ожидает визуального согласования, затем экспорт игровых текстур и встраивание в окно настроек.
Связи: KR-20261120-002.

## KR-20261120-002 — проектная документация и обязательный журнал
- Дата/время: 2026-11-20T09:49:33.238Z (UTC; точная дата Git проверяется по метаданным коммита)
- Коммит: найти по `git log --grep=KR-20261120-002` (SHA собственного коммита не может присутствовать в его файлах)
- Этап/версия: подготовка; этап 1 PLANNED; кода игрового аддона нет
- Тип: docs
- Задача: запрос пользователя о непрерывности контекста между чатами и обязательном подробном CHANGELOG
- Файлы: `AGENTS.md`, `docs/PROJECT_CONTEXT.md`, `docs/ROADMAP.md`, `docs/STAGE_01_INTERFACE.md`, `docs/CHANGELOG_RULES.md`, `CHANGELOG.md`

### Контекст и воспроизведение
Ожидалось: новый чат открывает репозиторий и понимает цель, архитектуру, подробный этап 1 и точное правило ведения истории. Фактически: репозиторий имел только стартовый README; техническое задание существовало в переписке, где теряется при смене контекста.
Шаги: открыть исходно пустой репозиторий; перейти к новой беседе без прочтения старого чата.
Среда: документация GitHub, игровая среда не запускалась.

### Анализ причины
Подтверждённая причина отсутствия истории: новый GitHub-репозиторий не имел документации и протокола работы. Риск потери контекста связан с тем, что требования были описаны только в сообщениях чата. Это не баг игрового клиента.

### Что изменено и почему
- `AGENTS.md`: порядок чтения документов в новом чате и строгий pre-commit протокол.
- `docs/PROJECT_CONTEXT.md`: что, зачем и как делаем; фиксированные решения и риски API.
- `docs/ROADMAP.md`: 7 этапов со статусами и результатами.
- `docs/STAGE_01_INTERFACE.md`: подробные спецификации 9 вкладок, панели, автоматического распознавания талантов, настройки и тест-кейсы.
- `docs/CHANGELOG_RULES.md`: обязательные поля, ведение BUG-отчётов, правила коммитов и физическая невозможность SHA-самоссылки.
- `CHANGELOG.md`: начальные записи, привязка истории к Git.
Риски: это план, не подтверждение доступности API и не готовый UI.

### Проверки
- [PASS] У репозитория есть стартовый README и исходный коммит `74be1ecc80ee43f93f7195ac78f9d1a51020526c`.
- [NOT RUN] Lua syntax / загрузка в WoW Forever: кода аддона ещё нет.
- [NOT RUN] Пользовательское тестирование: материалы ещё не получены тестировщиком.
- [PENDING] Проверка наличия всех документов в GitHub после публикации этого коммита.

### Выдано тестировщику
GitHub: https://github.com/Vi22Rus/Kord ; открыть `AGENTS.md`, `docs/STAGE_01_INTERFACE.md`, `CHANGELOG.md`. Проверить, что вкладки, автодетектор класса/талантов и правила журнала соответствуют утверждённому плану. Архива WoW-аддона пока нет.

### Фактический результат и следующие действия
Результат: документальная база для продолжения разработки между чатами. Реализация UI: не начата. Статус: требует просмотра пользователем; далее сборка `0.1.0`.
Связи: стартовый коммит `74be1ecc80ee43f93f7195ac78f9d1a51020526c`.

## KR-20261120-001 — первый коммит пустого репозитория
- Дата/время: 2026-11-20T09:44:20Z (UTC; по Git)
- Коммит: `74be1ecc80ee43f93f7195ac78f9d1a51020526c`
- Этап/версия: подготовка; документация
- Тип: docs
- Задача: инициализировать пустой `Vi22Rus/Kord`
- Файлы: `README.md`

### Контекст и воспроизведение
Ожидалось: центральная точка входа в новый репозиторий. Фактически: GitHub отвечал «This repository is empty», веток не было. 
Среда: GitHub, новый публичный репозиторий.

### Анализ причины
Причина: репозиторий создан без начального коммита и файлов; отсутствовала точка входа. Подтверждено просмотром API GitHub.

### Что изменено и почему
Создан `README.md` с названием Kord Rotation, целью 9×3 профиля, автоматическим определением класса/ветки, ссылками на планируемые документы и инструкцией нового чата. Инициализация нужна, чтобы появилась ветка `main` и можно было фиксировать документацию атомарным последующим коммитом.

### Проверки
- [PASS] GitHub вернул SHA создания файла `README.md`.
- [NOT RUN] WoW Forever/Lua: код ещё не написан.
- [NOT RUN] Пользовательский тест: файл справочный.

### Выдано тестировщику
Ссылка: https://github.com/Vi22Rus/Kord/commit/74be1ecc80ee43f93f7195ac78f9d1a51020526c . Проверка: открыть README, убедиться в правильном имени проекта и назначении.

### Результат и следующие действия
Создана первая точка входа. Полные файлы планирования и обязательные правила добавляются следующим коммитом. **Исключение bootstrap:** первый коммит пустого репозитория не мог содержать отдельный CHANGELOG при однопоточном создании файла; задокументирован этой записью при следующем коммите.
