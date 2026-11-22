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
