# Research Evidence — источники, факты и расхождения

## Обязательная карта источников для каждого профиля
| Profile ID | Source | URL/path | Checked at | Game/client version | Relevant? | Finding | Confidence | In-game verified? |
|---|---|---|---|---|---|---|---|---|
| HUNTER/BM/Leveling/PVE | Sonah.zip | project attachment | TODO | TODO | TODO | TODO | unknown | NO |
| HUNTER/BM/Leveling/PVE | MaxDps.zip | project attachment | TODO | TODO | TODO | TODO | unknown | NO |

**Для каждого профиля проверить и отметить:** WoW Forever client, official patch notes, ForeverDB, WoWSims, Warcraft Tavern, Icy Veins, Wowhead, Warcraft Logs, community/Discord, Sonah, MaxDps, ForeverRotation, ForeverAuras, JustAC, RotationGuide, provided profile archives and current Kord code. Для отсутствующих или нерелевантных ресурсов писать `UNAVAILABLE` / `NOT RELEVANT` и причину. Наличие имени в этом документе **не означает**, что ресурс уже проверен.

## Реестр игровых фактов
| Fact ID | Class/spec | Mechanic | Exact claim | Source/URL/file+line | Version/date | Confidence | Verified in client | Decision | Affected profiles |
|---|---|---|---|---|---|---|---|---|---|
| TEMPLATE-001 | HUNTER/BM | shared cooldown | TODO: проверить взаимодействие Summon Hawk / Arcane Shot | TODO | TODO | unknown | NO | не считать доказанным | BM Leveling, BM 60 |

## Реестр конфликтов
| Conflict ID | Mechanic | Source A | Source B | Version/context difference | Experiment to resolve | Resolution | Status |
|---|---|---|---|---|---|---|---|
| TEMPLATE-C01 | TODO | TODO | TODO | TODO | TODO | unresolved | OPEN |

## Методика
Сначала первичные данные Forever и клиент, затем внешние гайды и референсы. У каждого факта фиксировать источник, применимость, уверенность и решение. Не превращать конфликтующие данные в пользовательский переключатель. Новые классы используют эти же таблицы с фильтром Class/spec.


## Hunter BM/MM/SV — исследование 2026-11-21

Подробный реестр по шести PVE-профилям Hunter, включая подтверждённые исходники, буквальные spellID, несовместимые поля, источники, открытые конфликты и тест-кейсы: [Hunter_Research_2026-11-21.md](Hunter_Research_2026-11-21.md). **SOURCE REVIEWED / WEB PARTIAL / IN-GAME NOT RUN**. Не переносить неизвестные свойства в рабочие таблицы как подтверждённые. Для полного заполнения этой таблицы требуются дополнительные проверки клиента и адаптера.


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
