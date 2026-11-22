# Hunter BM — полный перенос стратегий в Contract v1

**Статус на 2026-11-22: SOURCE INTEGRATED; MOCK/CLIENT NOT VERIFIED для новой версии.**

## Модули и автоопределение

| Класс / специализация / уровень | Выбираемый модуль | Основа |
|---|---|---|
| HUNTER / BM (TREE_1) / 1–59 | `HUNTER_BM_LEVELING_PVE` | `Kord_Hunter_BM_Leveling_PVE.lua`, v2.3 |
| HUNTER / BM (TREE_1) / 60 | `HUNTER_BM_60_PVE` | экспериментальный адаптер приоритетов BM 60 v1.2, ещё не проверен на полной паритетности |
| HUNTER / BM (TREE_1) / 61–100 | `HUNTER_BM_PILOT_EXPERIMENTAL` | изолированный fallback Arcane Shot, вне диапазона WoW Forever 1–60 |

Оба рабочих профиля регистрируются через `Profiles/Hunter/BM_Leveling_Contract.lua` при PLAYER_LOGIN, PLAYER_LEVEL_UP, SPELLS_CHANGED, LEARNED_SPELL_IN_TAB. Стандартный движок `RotationEngine` выбирает профиль **строго по classToken, specIndex и читаемому уровню**. Неоднозначное дерево талантов или непрочитанный уровень не создаёт вымышленного профиля.

## Полный охват стратегии BM 1–59

Перенесены все ветки исходного `BM.Next(s,cfg)`, включая **Feign Death, Monkey/Hawk aspect, Call/Revive/Mend Pet, Hunter's Mark, Pet Attack, melee Disengage/Traps/Wing Clip/Mongoose/Raptor, ranged Auto Shot/Concussive, кулдауны Bestial Wrath/Rapid Fire/Intimidation, AoE Explosive/Volley/Multi-Shot, Summon Hawk, Aimed Shot, Arcane Shot, Serpent Sting и филлеры**. Порядок задан `Profile.Rules`; основной движок обрабатывает только разрешённые типы и `AbilityEligibility` решает конечный READY.

Исходные **22 конфигурации** `BM.defaults` перенесены без пропусков в `Profile.Config`. Раздел «Ротация» генерирует controls из схемы активного модуля, а `RotationSettings.moduleConfigs[profile.id]` хранит значения отдельно для каждого модуля. При смене уровня/специализации UI перестраивается. Дополнительные **4 настройки BM 60** делают его схему отдельной (26 элементов); этот 60-адаптер пока экспериментальный и не заявлен как точная паритетная копия стратегии 60.

ID заклинаний — стабильные базовые числовые ID и **наивысшие действительно известные ранги из `SpellCatalogue`**, если каталог подтверждён (включая Arcane Shot и собственные ID Summon Hawk из Forever). Если корректность ID не подтверждена, конечный `AbilityEligibility` должен вернуть UNKNOWN/BLOCKED, а не автоматически кастовать.

## Источники сигналов и границы достоверности

| Сигнал | Текущая реализация |
|---|---|
| Уровень, бой, здоровье/мана, target existence, pet existence/HP/attack target | типизированный `GameState` snapshot |
| Класс цели (normal/elite/rareelite/worldboss) | `UnitClassification` через `GameAPI` |
| Ближняя дистанция | отдельный безопасный `AbilityEligibility.Fact(2973,"inRange")`; неподтверждённое даёт UNKNOWN |
| Auto Shot active | `GameState.ReadAutoShot(75)`; **не приравнивать к swing timer** |
| Цель противника / атака игрока | `UnitExists("targettarget")` + `UnitIsUnit("targettarget","player")` |
| Player buffs / target debuffs | существующая проверка AuraData по spellID; при отсутствии — ограниченное 64-записями сканирование `GetAuraDataByIndex`; `false` только при проверенном завершении списка и стабильном target GUID |
| Hawk count / remaining | пока UNKNOWN: нет подтверждённого игрового источника |
| Enemy count, AoE safety, TTD, aimed/multi profitability, traps, travel aspect, sting remaining, movement needs | явные UNKNOWN до проверки соответствующих API |
| PET_ATTACK | сохранён в списке правил как `PET_COMMAND`, но контракт пока не умеет рекомендовать/исполнять этот тип: `unsupported_action` |
| Защищённые значения | UNKNOWN, никогда не интерпретируются как false/ready |

**Отдельная запись непроверенных сигналов** не означает, что весь набор способностей уже успешно отображается. Мы осознанно переключили экспериментальный режим на полный профиль ради одного комплексного игрового теста. По появлению очередных `UNKNOWN` будут дорабатываться провайдеры; защитные действия не могут обходить отсутствие подтверждения.

## Полный журнал без Ctrl+C

DevTools теперь пишет `KordRotationDevToolsDB.sessions` в SavedVariables по сегментам до **512** строк, с сохранением **12** последних частей; на Stop и PLAYER_LOGOUT сохраняется финальный сегмент. После `/reload` или выхода WoW записывает файл `WTF/Account/<ACCOUNT>/SavedVariables/KordRotationDevTools.lua`. Нельзя писать произвольные файлы из WoW API.

В режиме ручной записи `CoreObservation.Audit()` запрашивает `RotationEngine:AuditFull()`. Это **диагностическая оценка всех правил независимо от обычной остановки на первом READY/UNKNOWN**. Она проверяет условия и Eligibility каждой применимой способности, не выдаёт рекомендаций и не выполняет кастов. В журнале:

- `PROFILE bm_profile_bm_leveling / bm_profile_bm_60` — выбранный модуль;
- `RULE bm_rule_N` — результат N-го приоритета, а в detail его причина;
- `SIGNAL bm_signal_N_<field>` — какая конкретно проверка бафа, дебафа, цели, питомца, ястреба или AoE дала READY/UNKNOWN и почему;
- `STAGE bm_stage_N_cast/usability/charges/cooldown/gcd/range` — все шесть этапов или `UNAVAILABLE/not_evaluated`;
- старые `ENGINE`, `TARGET`, `DISPLAY`, `CHECK` и `BAR` остаются.

Записываются **только изменения** безопасных статусных значений, чисел приоритетов и заранее разрешённых причин; ни один SpellID, GUID, имя игрока, имя цели или frame не экспортируется. Аудит активен только при записи DevTools, обычный движок остаётся ленивым. Старые сегменты вытесняются по лимиту.

## QA и дальнейшая работа

Добавлены Lua mock-тесты выбора 1–59/60, регресса на ранг Arcane, per-module Config и полного аудита, а также тесты лога и сохранения SavedVariables. **Не утверждать Lua/mock PASS и клиентский PASS до фактического запуска**. Не изменять без отдельного согласования `docs/rotation/Profile_Contract.md` (формальный документ контракта v1).

Исторические версии `Kord_Hunter_BM_Leveling_PVE.lua` и `Kord_Hunter_BM_60_PVE.lua` сохранены для сравнения при дальнейших уточнениях условий.

## 2026-11-22 — актуализация по игровым журналам и исходникам

**Проверено пользовательским DevTools в WoW Forever (частичная игровая проверка):** `bm_profile_bm_leveling=READY` и `ruleCount=35`; `frame_created=READY`, `frame_shown=READY`; обнаружены 29 подтверждённых кнопок и Arcane Shot rank 4. **Ни одной принятой реальной рекомендации пока не подтверждено**: `bm_rule_2=UNKNOWN/action_slot_unconfirmed`, несмотря на подтверждение пользователем, что Aspect of the Hawk находится на видимой панели и назначен на Ctrl+3. Это открытая проблема, а не доказательство отсутствия кнопки.

Изменённое поведение: `Init.lua` не регистрирует безусловно неподдерживаемый `LEARNED_SPELL_IN_TAB` (его не считать обязательным событием); `PET_COMMAND` metadata и условие низкоуровневого `aspect_monkey` исправлены; `target.classification` читается через `UnitClassification`; `player.travelAspect` вычисляется по подтверждённым Cheetah (5118) / Pack (13159). При отсутствии проверенной ауры — UNKNOWN. Сканер панели добавил диагностику возможного несовпадения ранга/SpellID на основе безопасного имени, но не изменил строгую проверку реальной кнопки.

**Ауры (новейшая реализация, ещё не прошла игровую проверку):** поиск по SpellID → попытка `C_UnitAuras.GetUnitAuras` с проверкой доступности полей и структуры массива → ограниченный `GetAuraDataByIndex` fallback. Неполное/защищённое значение не доказывает отсутствия бафа. Полнота отрицательных результатов клиента WoW Forever ещё не подтверждена.

**UI:** основная и дополнительные ячейки сохраняют позиции без READY; тестовые иконки не являются боевыми. Движок всё ещё возвращает максимум **одно** текущее действие. Очередь будущих способностей, реальные защитные/interrupt рекомендации и Pet Attack как боевое действие **не реализованы**. Защитные и interrupt рамки пока лишь фиксированные пустые области.

Открытые блокировки: `action_slot_unconfirmed` для Hawk, `aura_scan_unverified` в бою, `pet.health.percent=direct_field_unverified`, а также TTD и эвристические сигналы без провайдеров. Нельзя пропускать UNKNOWN Eligibility или считать видимый по словам пользователя action slot программно подтверждённым. Последние изменения исходников: **LUA MOCK NOT RUN, CI NOT RUN, LATEST IN-GAME RETEST NOT RUN**.


## Диагностика DevTools: 101 строк v14 (после последнего журнала)

При явном начале записи DevTools сохраняет `API ... matrix_probe` **для каждой из 101 строк** `Canonical_API_Matrix.md`. `matrix` — номер строки; detail содержит результат безопасной проверки **наличия** метода, не игровой результат выполнения. Для составных возможностей, у которых нет отдельного безопасного probe, сохраняется `UNKNOWN/no_single_safe_probe`. Это не 101 динамический тест и не 101 CLIENT PASS.

В per-rule журнале `bm_bar_2` больше не должен терять фиксированные детали `spell_not_confirmed_on_visible_bar` или `visible_spell_rank_mismatch`. Связь аудита остаётся `RULE → BAR → SIGNAL → STAGE` с номером приоритета и ограниченными кодами. Реальная причина отсутствия Hawk на UI пока **не доказана**; нужен новый клиентский тест новой версии.

**Проверки новой версии:** `tests/devtools_probe.lua`, `tests/devtools_recorder.lua` обновлены, но **локально не выполнялись**. CLIENT NOT RUN для актуального SHA. 

### Защита журнала от молчаливой потери причин

Регистратор теперь оставляет безопасные маркеры `diagnostic_code_unmapped`, `diagnostic_code_invalid`, `diagnostic_detail_unmapped`, если исходный код не внесён в фиксированный словарь или передан небезопасный detail. Это не раскрывает исходное содержимое, но показывает разрыв диагностического контракта, вместо пустого поля. Ранее пустой `bm_bar_2` мог быть результатом такого фильтра. Все изменения требуют клиентской проверки после установки и локального запуска Lua mock; пока **NOT RUN**.

## Runtime API trace: после пересмотра диагностики 2026-11-22

По прямому требованию заказчика запись DevTools теперь **не ограничивается отдельным методом Hawk**. При включённом Recorder все вызовы через `GameAPI:Read/ReadTuple/ReadValues/ReadField/Probe/ReadHealthPercent/ReadPowerPercent` автоматически дают агрегированные записи `METHOD`: имя операции (для полей — безопасный ключ), статус, внутренняя причина отказа и число вызовов. Проверки панели `ActionBarScanner.inspect/findspell` добавлены как отдельные фиксированные этапы. Специальная `GameAPI.Probe.<API>` не смешивается с фактически выполненным игровым вызовом. Первый результат и финальная сумма на Stop отражают частоту без дублирования тысяч событий. Исходные аргументы, SpellID, GUID и результат API не сохраняются.

101 строка `Canonical_API_Matrix.md` продолжает логироваться независимо как **presence-only**. У одного API может быть несколько сценариев в матрице; их нельзя считать успешно исполненными по одному счётчику метода. Полная ротация по-прежнему оценивается через `RULE/SIGNAL/STAGE/BAR`, поэтому статусы 35 правил видны в той же записи.

**Новые тестовые проверки добавлены, но не запускались**; последний пользовательский trace до этой версии по-прежнему демонстрировал `bm_rule_2=UNKNOWN/action_slot_unconfirmed`. Новая система помогает выявить причину, но **не утверждает, что сама исправила распознавание Hawk**. Код последних изменений SOURCE IMPLEMENTED, LOCAL LUA NOT RUN, CLIENT NOT RETESTED.

## Reference-first fix: secret aura scans (2026-11-22)

**Evidence from actual game recording:** `C_UnitAuras.GetUnitAuras` and `GetAuraDataByIndex` each failed with `api_call_failed` 903 times, `GetPlayerAuraBySpellID` returned `no_value` 903 times; aspect rule #2 became `condition_unknown` after `player.buff` was `aura_scan_unverified`.

**Reference-backed implementation (not client-tested):** Sonah/JustAC/ForeverAuras confirm that these list APIs can be blocked while auras are secret. `GameState:ReadSignal` now tests `C_Secrets.ShouldAurasBeSecret` before forbidden enumeration fallback after an unsuccessful direct SpellID lookup. Secret mode returns `aura_hidden_by_client`; missing secrecy predicate while locked down returns `aura_secrecy_unverified`. Neither condition can prove a missing buff; the engine still fails closed. The intended effect is to stop thousands of denied calls, **not** to pretend Aspect of the Hawk is visible/absent. New Lua mock scenarios added, NOT RUN in this environment; CLIENT NOT RETESTED.

**Source decision ledger:** `docs/rotation/V14_Reference_Implementation_Audit.md` tracks **all 101** v14 items individually, the indexed reference pointers and research status. This ledger is not yet a completed 101-method implementation audit; review states make the gap explicit.

## 2026-11-22 — Fix gameplay aura signal using reference mechanisms (source only)

**Implemented, not just logged:**
1. `GameState:ReadSignal` now uses Sonah `Core/Atoms/Auras.lua:216–259` address-based localized `C_UnitAuras.GetAuraDataBySpellName` after a direct-ID miss. An exact verified `spellId` + `isHelpful`/ `isHarmful` can confirm positive presence. A `nil` can prove absent **only if** `C_Secrets.ShouldAurasBeSecret()==false`. Failed/secret calls remain UNKNOWN; explicit rank/name collisions never count as verified presence.
2. `Core/AuraEvidence.lua` implements Sonah `Core/Atoms/Auras.lua` positive own-cast tracking pattern (`UNIT_SPELLCAST_SUCCEEDED`) for the four Hunter aspect IDs 13165, 13163, 5118, 13159. After own successful cast, a bounded 3600-second positive evidence window may maintain the aspect through hidden-aura mode. Observed aspect switch invalidates the prior entry, as do world entry and death. It does **not** infer an unseen buff is absent, and it does not auto-cast. It is an evidence projection, not an assertion of client-confirmed continuous aura uptime; removed aura during the window is not yet reflected unless another aspect is cast or resets happen.
3. TOC loads the tracker before GameState; regression scenarios for positive evidence, aspect switching, reset, clean by-name positive and negative added to `tests/stage_02_03_game_state.lua`.

**Remaining blocker:** on the supplied 2026-11-22 game recording `C_Secrets.ShouldAurasBeSecret` was true and all direct known-ID lookups were nil. No reference establishes a trustworthy **initial negative** in that state, so a previously unobserved Aspect of the Hawk still correctly remains UNKNOWN rather than spuriously re-cast. This patch provides real operational pathways for nonsecret aura checks and observed self-casts, but has NOT been tested in the Forever client and does not warrant a claim that Aspect of the Hawk now appears under every state.

**Validation:** source reviewed against Sonah/ForeverAuras/JustAC, Lua mock added but not run, no Forever client test. 

## 2026-11-22 — Reference-driven Hawk aspect switching after user battle log (8797–8821)

**Live evidence:** newest two-page test starts with `C_UnitAuras.GetPlayerAuraBySpellID READY` and `bm_signal_2_player_travelaspect READY` at t8797, while rule #2 `condition_false`. After combat begins, the direct player-aura, generic by-ID and by-name paths return `no_value` 1062 times, `C_Secrets.ShouldAurasBeSecret` is readable and hidden-mode returns `player.buff UNKNOWN/aura_hidden_by_client`. Rule #2 transitions to UNKNOWN. This proves a false rule decision was possible in the presence of a *confirmed positive travel aspect*; previous code always did `if travel==true then return false`, unlike Sonah.

**Source:** `Sonah/Classes/Hunter.lua:142–171` specifically separates an out-of-combat reminder (wait while Cheetah or Pack active) from an in-combat emergency combat-aspect switch. `travelOn(def)` checks `C.buff(def)` and that its evidence is not consumed by a later cast of a combat aspect.

**Implemented in the canonical core:**
- `BM_Leveling_Contract.lua` rule #2 returns TRUE to recommend Hawk in combat if a confirmed travel aspect is active, even if the current Hawk aura lookup is hidden/UNKNOWN. A verified already-active Hawk still blocks duplicate recommendation. Out of combat, it leaves Cheetah/Pack active.
- `AuraEvidence.lua` tracks 5118/13159 by *verified positive direct observation* for at most 120 seconds through secret-combat transitions, and consumes it when a player `UNIT_SPELLCAST_SUCCEEDED` event confirms a combat aspect. Covers known Hawk ranks 13165/14318–14322/25296, Beast, Monkey, Wild. Self-cast positive records remain bounded. A historical positive record is not refreshed from itself; `PLAYER_ENTERING_WORLD` and death reset all records.
- `GameState:ReadSignal("player.travelAspect")` records a verified Cheetah/Pack presence and can reuse unconsumed *positive* travel evidence while live APIs are hidden. This is deliberately NOT a generic fabricated absence or an unconditionally optimistic cast.
- New mock `tests/hunter_bm_aspect_switch.lua` and stage state evidence checks; new mock is included in manual Lua 5.1 CI workflow.

**State:** SOURCE IMPLEMENTED / MOCK NOT RUN / FOREVER CLIENT NOT RETESTED. No claim of confirmed in-game rendering; client-side eligibility still requires a verified actionbar spell/rank, usability, cooldown, etc.
