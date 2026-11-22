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
