# Test Matrix — от unit до WoW Forever

| Test ID | Scope | Scenario | Inputs / setup | Expected action + reason | Static | Unit | Integration | In-game | Evidence/log |
|---|---|---|---|---|---|---|---|---|---|
| CORE-001 | all profiles | state=nil | nil | safe nil / documented no recommendation, no crash | NOT RUN | NOT RUN | NOT RUN | NOT RUN | TODO |
| CORE-002 | all profiles | moving=nil | cast requiring stationary | no unsafe cast | NOT RUN | NOT RUN | NOT RUN | NOT RUN | TODO |
| CORE-003 | all profiles | unknown ready | ready[key]=nil | no unverified ability | NOT RUN | NOT RUN | NOT RUN | NOT RUN | TODO |
| CORE-004 | all profiles | invalid CFG | unexpected enum/number | validated fallback, no crash | NOT RUN | NOT RUN | NOT RUN | NOT RUN | TODO |
| CORE-005 | all profiles | missing binding | valid action, no bound button | safe UI status; no invented key | NOT RUN | NOT RUN | NOT RUN | NOT RUN | TODO |
| HUNTER-001 | BM/MM/SV | CC near AoE | breakableCCNearby=true | no unsafe AoE; safe ST if eligible | NOT RUN | NOT RUN | NOT RUN | NOT RUN | TODO |
| HUNTER-002 | BM/MM/SV | solo aggro + high HP | solo, aggro=true, HP high | no premature Feign Death per agreed policy | NOT RUN | NOT RUN | NOT RUN | NOT RUN | TODO |
| HUNTER-003 | BM/MM/SV | dungeon aggro | dungeon=true, aggro=true | evaluate Feign Death if known/eligible | NOT RUN | NOT RUN | NOT RUN | NOT RUN | TODO |
| HUNTER-004 | BM/MM/SV | pet absent | petExists=false | no pet-dependent attacks | NOT RUN | NOT RUN | NOT RUN | NOT RUN | TODO |
| PROFILE-001 | all | level boundary | level 59 then 60 | correct profile only | NOT RUN | NOT RUN | NOT RUN | NOT RUN | TODO |
| PROFILE-002 | all | invalid target | dead/friendly/no target | no harmful recommendation | NOT RUN | NOT RUN | NOT RUN | NOT RUN | TODO |
| INTEGRATION-001 | all | real TOC load | addon startup | common before dependent profiles | NOT RUN | NOT RUN | NOT RUN | NOT RUN | TODO |
| INTEGRATION-002 | all | recommendation chain | GameData→Next→Eligibility→BindingResolver→UI | consistent action/phase/reason | NOT RUN | NOT RUN | NOT RUN | NOT RUN | TODO |

## Обязательное покрытие
Для каждого профиля добавить отдельные проверки: уровень, talents/runes, ST/AoE, CC, TTD, движение, ресурс, range, proc, угрозу, питомца, пулл, смерть, бой, unknown, неверный CFG, отсутствующий bind. Для танков — mitigation/taunt, для хилов — friendly target/heal urgency, для DPS — damage priorities; только при появлении соответствующих классов.

**PASS** только с фактическим тестом и логом; **NOT RUN** — не проверено; **FAIL** — воспроизводимый сбой. Изменение общего контракта запускает регрессию всех зависимых профилей. Игровой тест выполняется на реальном клиенте и не выводится из Lua-моков.


## Hunter BM/MM/SV — исследование 2026-11-21

Подробный реестр по шести PVE-профилям Hunter, включая подтверждённые исходники, буквальные spellID, несовместимые поля, источники, открытые конфликты и тест-кейсы: [Hunter_Research_2026-11-21.md](Hunter_Research_2026-11-21.md). **SOURCE REVIEWED / WEB PARTIAL / IN-GAME NOT RUN**. Не переносить неизвестные свойства в рабочие таблицы как подтверждённые. Для полного заполнения этой таблицы требуются дополнительные проверки клиента и адаптера.

## Две сборки и диагностический пилот (решение 2026-11-21)

**Источник:** [BUILD_VARIANTS_AND_DIAGNOSTICS.md](../BUILD_VARIANTS_AND_DIAGNOSTICS.md). Статусы до фактических тестов — NOT RUN.

| Test ID | Сценарий | Критерий | Статус |
|---|---|---|---|
| BUILD-DEV-001 | Обычный ZIP без DevTools | Не содержит DevTools, developer-кнопки, recorder, отдельные debug SavedVariables | NOT RUN |
| BUILD-DEV-002 | Debug ZIP | Содержит два аддона, `KordRotationDevTools` зависит от `KordRotation` | NOT RUN |
| BUILD-DEV-003 | SHA ядра | Все файлы канонического ядра побайтно равны в двух пакетах | NOT RUN |
| DEV-001 | Ручной старт/стоп записи | Никаких данных до opt-in; stop прекращает запись | NOT RUN |
| DEV-002 | Secret API, nil, ERROR | Причины и номер v14 без попытки сериализовать защищённое значение | NOT RUN |
| DEV-003 | Большой лог | Ограниченный буфер, rate limit, dropped counter и измеренный overhead | NOT RUN |
| DEV-004 | /reload и экспорт | Диагностические SavedVariables сохраняются при reload/выходе; ручной экспорт работает | NOT RUN |
| DEV-005 | Сессия API v14 | Сценарные probe, 101 отдельных статусов; отсутствие client test не превращается в PASS | NOT RUN |
| BM-LEVEL-001 | Перенос BM 1–59 | ST/AoE/CFG/priority сохраняют решения старой ротации на одинаковых проверенных состояниях | NOT RUN |
| BM-LEVEL-002 | Игровой тест | Pet, Auto Shot, ammo, GCD, ресурсы, дальность, threat, solo/dungeon, смена level/target | NOT RUN |

## Canonical v14 — GameState прямые сигналы (2.8.2)

| ID | Метод/строка v14 | Сценарий | Ожидаемое | Статус |
|---|---|---|---|---|
| GAME-009 | IsPlayerMoving #9 | true / false / nil / secret / unsupported | отдельные READY(true/false) и UNKNOWN/UNAVAILABLE | NOT RUN |
| GAME-067 | UnitIsPlayer #38/#67 | игрок в цели / NPC / отсутствующая цель | не заменять UnitIsPlayer через UnitIsUnit | NOT RUN |
| GAME-092 | Threat #14/#78/#92 | целые 0..3 / дробное 1.5 / nil / secret | READY только для integer 0..3; иначе UNKNOWN | NOT RUN |
| GAME-099 | Pet #5/#77/#99 | живой, мёртвый, отсутствует, secret | pet.exists отдельно от pet.dead/health; отсутствие не равно UNKNOWN | NOT RUN |
| GAME-018 | Context #17/#18/#72/#73 | solo, world party, dungeon, raid, nil | не выводить инстанс/группу из одного флага; нет ложного boolean | NOT RUN |
| GAME-080 | Secret #3-6/#80 | secret health/power | никакая арифметика по секретному числу | NOT RUN |

## v14: наблюдение питомца и Auto Shot (2.8.2b)

| Test ID | Матрица | Сценарий | Ожидаемое | Game |
|---|---|---|---|---|
| PET-201 | #30 | pet/target отсутствуют | UNKNOWN, не false | NOT RUN |
| PET-202 | #30 | pet и target подтверждены | UnitIsUnit проверяется | NOT RUN |
| PET-203 | #77/#99 | UNIT_PET / UNIT_HEALTH(pet) | обновление канала pet/health | NOT RUN |
| CONTEXT-201 | #18/#90 | in instance, GetInstanceInfo nil | UNKNOWN | NOT RUN |
| AUTOSHOT-201 | #24 | valid/invalid ID, secret flag | раздельные статус active/current | NOT RUN |

## v14 GameAPI Curve-проценты (2.8.2c)

| Test ID | Matrix | Scenario | Expected | Lua | Game |
|---|---|---|---|---|---|
| GAME-CURVE-001 | #3/#4/#5/#41 | UnitHealthPercent returns ordinary 0, 40, 100 | READY and matching value | NOT RUN | NOT RUN |
| GAME-CURVE-002 | #3/#4/#5/#41 | missing curve, nil, secret result or failing API | UNKNOWN; no arithmetic, no invented threshold | NOT RUN | NOT RUN |
| GAME-CURVE-003 | #6/#49–51 | UnitPowerPercent with valid resource type | READY only for numeric 0..100 | NOT RUN | NOT RUN |
| GAME-CURVE-004 | #6/#49–51 | unexpected >100, NaN, negative, unknown resource type | UNKNOWN and reason | NOT RUN | NOT RUN |

## Исполняемая регрессия 2.8.2 (подэтап 2.8.2d)

- **Файл:** `tests/stage_02_08_v14_state.lua`; изолированные mock-значения здоровья/ресурса, API error, Secret API, pet/pettarget, instance status, Auto Shot, границы threat. **Синтаксис теста** проверен texluac; **исполнение на реальном исходном ядре** требуется при наличии всех файлов в локальном workspace — не выдавать syntax-only за PASS assertions.
- **Обязательные FAIL cases:** fractional threat; GetInstanceInfo second return nil при IsInInstance true; UnitPowerPercent secret; ошибочный UnitHealthPercent; отсутствующий Curve. **Игра:** NOT RUN.

## Исполняемая регрессия на точном GitHub-коммите

Добавлен workflow `.github/workflows/lua-regression.yml`: на push с Lua-изменениями и по ручному запуску устанавливает Lua 5.1, проверяет синтаксис Lua-модулей и запускает все семь существующих тестовых файлов, включая `tests/stage_02_08_v14_state.lua`. **Наличие workflow НЕ равно PASS:** результаты фиксировать только после завершённого GitHub Actions job с проверенным SHA; если GitHub Actions не запустится, отмечать NOT RUN. Это не тест в клиенте WoW Forever.

## 2.8.2e: защита входных аргументов до сравнения (v14 #24/#80)

| Test ID | Сценарий | Ожидаемое | Mock test | In-game |
|---|---|---|---|---|
| GAME-SECRET-ARG-001 | Secret unit/curve/powerType | UNKNOWN до числовой арифметики/сравнения, ноль вызовов WoW API | `tests/stage_02_08_v14_argument_guards.lua` — execution NOT RUN | NOT RUN |
| GAME-SECRET-ARG-002 | Secret Auto Shot SpellID | UNKNOWN без `math.floor` или обращения к WoW API | same — execution NOT RUN | NOT RUN |
| GAME-SECRET-ARG-003 | Валидные значения | обычные READY и всего 4 настоящих вызова | same — execution NOT RUN | NOT RUN |
