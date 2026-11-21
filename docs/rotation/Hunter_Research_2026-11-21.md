# Hunter BM/MM/SV — исследование исходников и механик (2026-11-21)

**Область:** 6 PVE профилей (BM/MM/SV × Leveling 1–59/60), общий Hunter_Common и SV_Core. **Режим:** документация, Lua не менялся. **Статус:** SOURCE REVIEWED / WEB RESEARCH PARTIAL / CLIENT NOT RUN. Этот документ дополняет общие [реестры](README.md), а не создаёт альтернативный стандарт.

## 1. Фактически просмотренные исходники

Текущие файлы GitHub: `KordRotation/Profiles/Hunter/Kord_Hunter_Common.lua`, `Kord_Hunter_BM_Leveling_PVE.lua`, `Kord_Hunter_BM_60_PVE.lua`, `Kord_Hunter_MM_Leveling_PVE.lua`, `Kord_Hunter_MM_60_PVE.lua`, `Kord_Hunter_SV_Core.lua`, `Kord_Hunter_SV_Leveling_PVE.lua`, `Kord_Hunter_SV_60_PVE.lua`.

| Источник | Прочитанный файл | Что действительно установлено |
|---|---|---|
| Sonah.zip | Sonah/Classes/Hunter.lua | Чистые приоритеты и spell tables, отдельные Forever механики Hawk, Sniper, melee SV; ранги в списках |
| Sonah.zip | Sonah/Core/Atoms/Spells.lua | Разрешение изученных рангов, проверки cooldown/usable/range |
| MaxDps.zip | MaxDps_Hunter/Specialization/Forever/Beastmastery.lua | Короткий BM приоритет Sting, Mark, melee, Rapid, Aimed, Multi, Hawk |
| ForeverRotation.zip | ForeverRotation/Rotations/Hunter.lua | Три специализации, исходник сам помечает приоритеты как unconfirmed |
| RotationGuide.zip | RotationGuide/Data/Hunter.lua | Раздельные melee/ranged условия, упоминание общих cooldown Hawk/Arcane и Aimed/Multi |
| JustAC.zip | JustAC/DefensiveEngine.lua | Отдельная система защитных действий, не доказательство Hunter-таймингов |
| ForeverAuras.zip | Архив/структура | Hunter боевой профиль не установлен; полноценный аудит аур не завершён |

Референсный код не переносить дословно; свойства референса — не автоматически свойства клиента.

## 2. Внешние ресурсы и применимость

| Ресурс | Ссылка | Проверенное содержание / ограничение | Статус |
|---|---|---|---|
| ForeverDB | https://foreverdb.net/class/hunter | Forever Hunter BM/MM/SV, Aimed trainer 20, Hawk/Arcane, Aimed/Multi, Sniper, melee SV | RESEARCHED, not client |
| ForeverDB | https://foreverdb.net/article/wille-hunter-everything-you-need-to-know | Статья 2026-10-20 с проверкой по beta client 1.60.1.70450; Hawk, Lacerate, Sniper, traps | RESEARCHED, version caveat |
| ForeverDiff | https://foreverdiff.com/classes/hunter/ | Изменения относительно Classic, отдельные ранги и свойства | RESEARCHED, not client |
| Warcraft Tavern | https://www.warcrafttavern.com/wow-classic/guides/hunter-leveling-guide | Classic leveling, питомец/auto-shot/ресурс; не Forever | VERSION MISMATCH |
| Warcraft Tavern | https://www.warcrafttavern.com/wow-classic/guides/pve-beast-mastery-hunter-rotations-cooldowns/ | Classic BM, порядок зависит от эпохи | VERSION MISMATCH |
| Icy Veins | https://www.icy-veins.com/wow-classic/hunter-dps-pve-spec-builds-talents | Classic таланты, не Forever | VERSION MISMATCH |
| Wowhead | https://www.wowhead.com/classic/spell=19434/aimed-shot | Classic Aimed талант, ForeverDB Aimed baseline | VERSION MISMATCH |
| WoWSims | https://wowsims.github.io/ | Конкретная симуляция Forever Hunter не подтверждена | NOT VERIFIED |
| Warcraft Logs | https://www.warcraftlogs.com/ | Сопоставимые Forever логи не подтверждены | NOT VERIFIED |
| Официальные Forever патчноуты и игровой клиент | — | Не проверены непосредственно | NOT RUN |

## 3. Реестр конкретных утверждений

| ID | Механика | Что говорит источник | Статус | Как проверить |
|---|---|---|---|---|
| H-F01 | Aimed Shot | ForeverDB: базовая trainer-способность с 20, общий CD Multi-Shot | SECONDARY | книга, cooldown |
| H-F02 | Summon Hawk | ForeverDB: BM talent с 25, 18 сек, максимум 2, общий CD Arcane Shot | SECONDARY | книга, combat log, счетчик |
| H-F03 | Sniper Shot | ForeverDB: MM capstone с 40, 4 сек cast, 15 сек CD | SECONDARY | tooltip всех рангов |
| H-F04 | Strider Kick | ForeverDB: SV талант с 30; ForeverDiff описывает 8 сек CD | SECONDARY | книга, cooldown |
| H-F05 | Lacerate | ForeverDB: baseline с 30, bleed 21 сек | SECONDARY | книга, aura |
| H-F06 | Traps | ForeverDB статья: общий 30-секундный CD | SECONDARY | каст нескольких ловушек, таланты |
| H-F07 | Auto Shot | Sonah/RotationGuide и Classic гайды требуют учёта swing | REFERENCE ONLY | реальный combat log |
| H-F08 | Feign Death | Согласованная продуктовая политика: solo при агро и низком HP, dungeon/raid при опасном агро | PROJECT DECISION | сценарные тесты |

Не считать указанные уровни и тайминги окончательно доказанными для текущего билда. **Не переносить** параметры Classic WoW на Forever.

## 4. Инвентарь способностей из существующего кода

**BM Leveling и BM 60 (английские имена, без числовых ID в таблице):** Hunter's Mark; Serpent Sting; Arcane Shot; Summon Hawk; Auto Shot; Aimed Shot; Multi-Shot; Rapid Fire; Bestial Wrath; Intimidation; Concussive Shot; Raptor Strike; Mongoose Bite; Wing Clip; Disengage; Feign Death; Freezing Trap; Frost Trap; Explosive Trap; Immolation Trap; Volley; Mend Pet; Call Pet; Revive Pet; Pet Attack; Aspect of the Hawk; Aspect of the Monkey (Leveling); Trueshot Aura (60). Отсутствие в этом перечне не доказывает отсутствие в игре.

**MM Leveling / MM 60 (literal spellID из Lua):**
`AutoShot=75; RaptorStrike=2973; MongooseBite=1495; SerpentSting=1978; ArcaneShot=3044; ConcussiveShot=5116; WingClip=2974; AspectMonkey=13163; AspectHawk=13165; CallPet=883; RevivePet=982; MendPet=136; FeedPet=6991; MultiShot=2643; AimedShot=19434; HuntersMark=1130; RapidFire=3045; FeignDeath=5384; Disengage=781; FreezingTrap=1499; FrostTrap=13809; ExplosiveTrap=13813; ImmolationTrap=13795; Volley=1510; Deterrence=19263; ScatterShot=19503; TrueshotAura=1299346; SniperShot=1310687; SummonHawk=1293241; DismissPet=2641`. Некоторые ключи есть лишь в одном режиме.

**SV Leveling / SV 60 (literal spellID из Lua):**
`Attack=6603; AutoShot=75; RaptorStrike=2973; MongooseBite=1495; Counterattack=19306; StriderKick=1317257; Lacerate=24118; HuntersMark=1130; SerpentSting=1978; ArcaneShot=3044; AimedShot=19434; MultiShot=2643; Volley=1510; RapidFire=3045; ImmolationTrap=13795; ExplosiveTrap=13813; FreezingTrap=1499; FrostTrap=13809; WingClip=2974; Disengage=781; Deterrence=19263; FeignDeath=5384; AspectMonkey=13163; AspectBeast=13161; CallPet=883; RevivePet=982; MendPet=136; FeedPet=6991; DismissPet=2641`.

**Важно:** это **значения, прописанные в исходниках**, не доказательство реального ID изученного ранга. Проверка rank resolution, цены, GCD, cast, range и shared cooldown остаётся открытой.

## 5. GameData — выявленные несовместимости

| Область | BM | Common/MM/SV | Требование |
|---|---|---|---|
| Ресурс | `mana_percent` | `manaPercent` | единый адаптер |
| Питомец | `has_pet`, `pet_health_percent` | `petExists`, `petHealthPercent` | единые типы и nil |
| Бой | `in_combat`, `in_dungeon`, `in_raid` | `inCombat`, `inDungeon`, `inRaid` | единый источник |
| Цель | `has_target`, `target_distance` | `targetValid`, `inMeleeRange`, `inRangedRange` | не угадывать дальность |
| AoE | `enemies` | `enemyCount`, `aoeSafe`, `breakableCCNearby` | safety fail-closed |
| Способность | `ready["Aimed Shot"]` | `ready.AimedShot` | один canonical key |
| Результат | строка | action table с phase/reason | согласовать с Engine |

Профили нельзя считать подключенными к текущему `RotationProfiles`, который ожидает static `single/aoe`. Никаких изменений Lua в этом исследовании.

## 6. Матрица профилей и отличий

| Профиль | Источник логики | Ключевые разделы | Проверка |
|---|---|---|---|
| BM Leveling | самостоятельный BM.Next | aspect/pet, mark/sting, Hawk/Arcane, Aimed/Multi, cooldown, AoE, melee/ranged | NOT RUN |
| BM 60 | самостоятельный BM.Next | maintenance, threat, pull cast, pet, Hawk/Arcane, cooldown, AoE | NOT RUN |
| MM Leveling | Common.NewProfile + MM.rotate | common safety/pet, aimed/sniper/multi, leveling CFG | NOT RUN |
| MM 60 | Common.NewProfile + MM.rotate | common safety/pet, aimed/sniper/multi, level-60 CFG | NOT RUN |
| SV Leveling | Common.NewProfile + SV_Core.SVRotate | style, melee/ranged, trap, mana, leveling defaults | NOT RUN |
| SV 60 | Common.NewProfile + SV_Core.SVRotate | style, melee/ranged, trap, mana, 60 defaults | NOT RUN |

Ни один порядок не признан оптимальным без симуляции/игрового теста. SpecCore **не обязателен**: BM_Core не создавать автоматически.

## 7. Конфликты и нерешённые вопросы

| ID | Конфликт | Решение до проверки |
|---|---|---|
| H-C01 | Classic Wowhead Aimed talent против ForeverDB Aimed trainer | приоритет Forever-specific; проверить клиент |
| H-C02 | Classic BM гайды расходятся по Sting/Multi и расходятся с ForeverRotation | сохранить разногласия, не выдавать один вариант за факт |
| H-C03 | Внешние страницы Sniper имеют различия рангов/дистанции | не фиксировать диапазон без tooltip |
| H-C04 | BM unknown mana `or 100` и unknown aura через `not` | тест fail-closed |
| H-C05 | Common `targetAttackable ~= false` / `trapSharedReady ~= false` | проверить политику nil |
| H-C06 | Питомец может получить команду до пулла | тест безопасности |
| H-C07 | Auto Shot clipping, серверный swing и ранги | client/combat log pending |

## 8. Тесты к добавлению в общий Test Matrix

| ID | Сценарий | Ожидаемое безопасное поведение | Статус |
|---|---|---|---|
| H-010 | BM: nil state / ready | без краша | NOT RUN |
| H-011 | BM: неизвестная мана | не считать 100% | NOT RUN |
| H-012 | Hawk/Arcane общий CD | не рекомендовать невозможное | NOT RUN |
| H-013 | Aimed/Multi общий CD | не рекомендовать невозможное | NOT RUN |
| H-014 | неизвестная дальность / dead zone | не угадывать доступность | NOT RUN |
| H-015 | два ястреба и время жизни | проверять count/remaining | NOT RUN |
| H-016 | Sniper cast / движение | требовать подтверждённые условия | NOT RUN |
| H-017 | SV таланты и уровни | не советовать неизученное | NOT RUN |
| H-018 | solo агро, высокий/низкий HP | Feign только при согласованных условиях | NOT RUN |
| H-019 | dungeon/raid опасное агро | Feign если реально доступен | NOT RUN |
| H-020 | до пулла | нет непреднамеренного Pet Attack | NOT RUN |
| H-021 | CC рядом с AoE | не советовать опасное AoE | NOT RUN |
| H-022 | Auto Shot swing | не выдумывать таймер | NOT RUN |
| H-023 | GameData→Next→Eligibility→UI | единые имена и nil | NOT RUN |
| H-024 | 59→60, BM/MM/SV | правильный профиль | NOT RUN |

**Осталось:** полный аудит всех CFG ключей и шести переводов, проверка точных игровых рангов/таймингов и всех внешних источников, согласование GameData, затем интеграция и реальные тесты. Нельзя объявлять этот этап полностью игрово верифицированным.


## ИСПРАВЛЕНИЕ МЕТОДОЛОГИИ — 2026-11-21

**Строгое правило:** WoW Classic / Classic Era / Season of Discovery / Retail и WoW Forever — разные игровые версии. Wowhead Classic, Icy Veins Classic и Warcraft Tavern Classic **НЕ являются источниками подтверждения механик, приоритетов, уровней, рангов или таймингов Forever**. Их прежние упоминания в этом исследовании являются **отозванными сравнениями**, не доказательствами и не основанием для решений. Не использовать их для заполнения игровых полей. Если сайт не предоставляет явно проверяемые данные WoW Forever с указанием версии клиента, помечать NOT APPLICABLE.

**Forever-specific источники для дальнейшей проверки:**
- https://foreverdb.net/class/Hunter/abilities — способности Hunter Forever (извлечённые данные клиента, не игровой тест).
- https://foreverdb.net/class/Hunter — классовые изменения, специализации и приоритеты; отслеживать номер билда.
- https://foreverdiff.com/classes/hunter/ — изменения именно клиента Forever, с билдом и рангами.
- https://www.60.tools/spellbook/hunter — сравнение с отдельной колонкой Forever; использовать **только** Forever-значения.
- https://forever.rexas.tools/c/hunter — Forever snapshot 1.60.1.70755/70790; устаревание фиксировать.
- https://wowforever.wclbox.com/en — база Forever с указанным билдом 1.60.1.71037 на момент просмотра; перепроверить непосредственно перед реализацией.
- https://warcraftforever.games/classes/hunter — клиентский beta snapshot 1.60.1.70205, не актуальный игровой тест.

**Приоритет достоверности:** актуальный клиент Forever + подтверждённый combat log > официальные материалы Forever > актуальные клиентские дампы с build ID > Forever-specific референсы > неподтверждённые гипотезы. Даже совпадение двух сайтов не заменяет игровой проверки. Classic-данные не участвуют в этой иерархии.

**Новые наблюдения:** ForeverDB явно перечисляет Savage Rend, Swipe, Tendon Rip и Web как новые способности питомца Forever; текущие Hunter-профили не содержат подтверждённой логики этих pet abilities. Это **пробел исследования**, не доказательство, что Kord обязан автоматически их применять: сначала установить, управляются ли они питомцем, автоиспользованием и доступны ли через рекомендуемые действия. ForeverDB также указывает Aimed Shot как trainer ability уровня 20, общую перезарядку с Multi-Shot; это Forever-specific утверждение, **не сравнение с Classic**. Новые источники отражают разные билды (включая 1.60.1.71037); не смешивать числа без привязки к билду.
