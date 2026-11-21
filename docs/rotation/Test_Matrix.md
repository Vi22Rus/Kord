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

## Подтверждённый GitHub Actions PASS на каноническом 2.8.2

- **Фактический run:** [44885160182](https://github.com/Vi22Rus/Kord/actions/runs/44885160182), Git SHA `e6a7de617126e0e02a1282d36c173c731507ee02`, 2026-11-21 08:30 UTC, **completed/success**.
- `luac5.1 -p` по Lua-файлам KordRotation и tests: **PASS** в журнале CI.
- Все **8 из 8** Lua mock suites завершились PASS. В том числе v14 GameState **31 assertion**, v14 Secret argument guards **26 assertions**, предыдущий Eligibility **23 checks**, RotationEngine **29 assertions**. Эти результаты принадлежат указанному SHA, а не автоматически будущим коммитам.
- **Во всех строках "In-game": NOT RUN.** Нет CLIENT PASS из CI. Отдельные матричные возможности v14, не охваченные тестами, остаются в прежнем статусе.

## 2.8.3a — v14 #11/#25/#83, активный cooldown

| ID | Сценарий | Критерий | Lua | Game |
|---|---|---|---|---|
| ELIG-083-001 | `isActive=true,isOnGCD=true` при обычном `Evaluate()` | BLOCKED с `cooldown_active_unclassified`, не ложный READY | PASS run 44885528119 / 0eec9461 | NOT RUN |
| ELIG-083-002 | `isActive=true,isOnGCD=false` | BLOCKED; причина не утверждает индивидуальную или GCD категорию | PASS run 44885528119 / 0eec9461 | NOT RUN |
| ELIG-083-003 | `isActive=false` | Отдельный cooldown READY, независимо от неприменимого `isOnGCD` | PASS run 44885528119 / 0eec9461 | NOT RUN |

## Canonical v14 Eligibility #19/#80/#81 — прямое подтверждение known (2.8.3b)

| ID | Сценарий | Ожидаемое | Lua CI | WoW Forever |
|---|---|---|---|---|
| ELIG-KNOWN-001 | Запись каталога known=true | READY по известности; продолжить другие проверки | PASS run 44885927707 (ebcaa131) | NOT RUN |
| ELIG-KNOWN-002 | Нет записи в каталоге, C_SpellBook.IsSpellKnown=true | Известность READY (включая пассивные/талантовые ID), без ложного BLOCKED | PASS run 44885927707 (ebcaa131) | NOT RUN |
| ELIG-KNOWN-003 | Нет записи в каталоге, IsSpellKnown=false | BLOCKED/not_learned | PASS run 44885927707 (ebcaa131) | NOT RUN |
| ELIG-KNOWN-004 | Нет записи в каталоге, API/enum bank отсутствует или nil | UNKNOWN/spell_known_unverified, не false | PASS run 44885927707 (ebcaa131) | NOT RUN |
| ELIG-ID-005 | Secret Spell ID при Evaluate | UNKNOWN/invalid_spell_id до math.floor | PASS run 44885927707 (ebcaa131) | NOT RUN |

## 2.8.3c — безопасные Eligibility policy/ID и nil/Secret сигналы

| Test ID | Matrix v14 | Ожидаемый результат | Автотест | Клиент |
|---|---|---|---|---|
| ELIG-SEC-001 | #80 | Secret SpellID не копируется в результат Evaluate, UNKNOWN/invalid_spell_id | stage_02_07_eligibility.lua; PASS run 44886222396 (120c8040) | NOT RUN |
| ELIG-SEC-002 | #80 | Защищённая policy-таблица или поле отклоняется до сравнения | stage_02_07_eligibility.lua; PASS run 44886222396 (120c8040) | NOT RUN |
| ELIG-CHARGE-001 | #26/#80 | Защищённый currentCharges → UNKNOWN, не no_charges или READY | stage_02_07_eligibility.lua; PASS run 44886222396 (120c8040) | NOT RUN |
| ELIG-USABLE-001 | #21/#52 | nil/secret IsSpellUsable → UNKNOWN, не READY/BLOCKED | stage_02_07_eligibility.lua; PASS run 44886222396 (120c8040) | NOT RUN |
| ELIG-RANGE-001 | #10 | nil IsSpellInRange → UNKNOWN, не в дальности | stage_02_07_eligibility.lua; PASS run 44886222396 (120c8040) | NOT RUN |

## 2.8.3d — минимальный уровень; ранг остаётся отдельным доказательством

| ID | v14 | Сценарий | Ожидаемое | Mock | Клиент |
|---|---|---|---|---|---|
| ELIG-LEVEL-001 | #82 | minLevel=40 и player.level=40 | READY по уровню, остальная Eligibility не пропущена | PASS run 44886522419 / 5ac5d0fe | NOT RUN |
| ELIG-LEVEL-002 | #82 | minLevel=41 и player.level=40 | BLOCKED/player_level_too_low | PASS run 44886522419 / 5ac5d0fe | NOT RUN |
| ELIG-LEVEL-003 | #80/#82 | level UNKNOWN / нецелое / secret | UNKNOWN, без угадывания уровня | PASS run 44886522419 / 5ac5d0fe | NOT RUN |
| ELIG-LEVEL-004 | #82 | minLevel нецелое/0/>100/Secret | UNKNOWN/level_policy_invalid или policy_protected | PASS run 44886522419 / 5ac5d0fe | NOT RUN |
| ELIG-RANK-001 | #20/#82 | highest learned rank и допустимый Spell ID | НЕ РЕАЛИЗОВАНО: точный алгоритм требует доказательства; не считать наличие ID проверкой ранга | NOT RUN | NOT RUN |

## Eligibility v14 2.8.3e — заряды и GCD

| ID | Матрица | Проверка | CI | Игра |
|---|---|---|---|---|
| ELIG-CHARGE-002 | #26/#80 | Ноль зарядов при `isActive=true` = BLOCKED; при одном заряде и активном восстановлении допускается READY только по собственному count | PASS run 44887247067 / aff9473f | NOT RUN |
| ELIG-CHARGE-003 | #26/#80 | Отсутствует `currentCharges` или `maxCharges` → UNKNOWN, не синтезировать count по isActive | PASS run 44887247067 / aff9473f | NOT RUN |
| ELIG-CHARGE-004 | #26 | Дробное, отрицательное, больше max, max=0 → UNKNOWN/charges_invalid | PASS run 44887247067 / aff9473f | NOT RUN |
| ELIG-GCD-004 | #25/#80 | `GetSpellCooldown(61304)` без подтверждённого `isActive` → UNKNOWN/gcd_activity_unknown даже с `isOnGCD=true` | PASS run 44887247067 / aff9473f | NOT RUN |
| ELIG-RANK-002 | #20 | Проверка highest learned rank на актуальном клиенте остаётся открыта; никакого нового rank inference | NOT RUN | NOT RUN |

## 2.8.4a–d — канонический RotationEngine и GameData
| ID | Сценарий | Ожидаемое | Mock CI | WoW Forever |
|---|---|---|---|---|
| ENG-284A-001 | Один GameState снимок на проход, общий для Eligibility | Одна оценка состояния, без отдельного снимка на кандидата | PASS run 44888049693 / 28104bbb | NOT RUN |
| ENG-284A-002 | GameState недоступен или падает | UNKNOWN и пустая очередь | PASS run 44888049693 / 28104bbb | NOT RUN |
| ENG-284B-001 | Условия только из утверждённых boolean полей | Недопустимое поле отвергнуто при регистрации | PASS run 44888049693 / 28104bbb | NOT RUN |
| ENG-284B-002 | required GameData UNKNOWN / mismatch | UNKNOWN / BLOCKED соответственно | PASS run 44888049693 / 28104bbb | NOT RUN |
| ENG-284C-001 | Неверный status или чужой spellID | UNKNOWN без перехода к младшему правилу | PASS run 44888049693 / 28104bbb | NOT RUN |
| ENG-284D-001 | Настоящие Profiles+Engine+Eligibility, mock API | Порядок, cooldown, GCD, target, context, snapshot failure | PASS run 44888049693 / 28104bbb | NOT RUN |

CI: `tests/stage_02_08_rotation_engine.lua` и `tests/stage_02_08_v14_rotation_contract.lua`; подтверждено логу Actions: 9/9 Lua mock suites PASS, including integration 28 assertions. Игровые тесты, диагностика CPU/RAM и v14 #20 highest learned rank остаются NOT RUN.

## 2.8.5a–e — интеграция Engine, BindingResolver, EventBus, UI
| ID | Проверка | Ожидаемое | Локально | GitHub CI | WoW Forever |
|---|---|---|---|---|---|
| UI-285A-001 | Неверный Spell ID, texture, имя, источник или лишняя queue | Пустая рекомендация, скрытая production-панель | NOT RUN | NOT RUN | NOT RUN |
| UI-285B-001 | Чужой BindingResolver Spell ID, пустая клавиша, UNKNOWN | keybind=nil, без ложного отображения | NOT RUN | NOT RUN | NOT RUN |
| UI-285C-001 | EventBus bindings/target/cooldowns | Обновление без старой иконки | NOT RUN | NOT RUN | NOT RUN |
| UI-285D-001 | Нет профиля, профиль выключен, showPanel=false | Рабочая иконка очищается | NOT RUN | NOT RUN | NOT RUN |
| UI-285E-001 | Тестовый режим и 5 слотов | TEST отдельно, только одна production рекомендация | NOT RUN | NOT RUN | NOT RUN |

Сценарии: `tests/stage_02_08_v14_display.lua`, обновлён `tests/stage_02_08_rotation_engine.lua`. Workflow добавляет десятый набор, но запускается **только вручную** один раз перед общим QA. Новых UI-строк нет; словари 6 языков не меняются. Изолированная реальная игровая FrameXML/Secret проверка и FPS/RAM — NOT RUN.

## 2.8.6a–e — итоговая интеграция ядра (без CI до общего QA)
| ID | Сценарий | Факт | Локально | GitHub CI | Игра |
|---|---|---|---|---|---|
| CORE-286A-001 | Аудит v14 API→UI и шести референсов | Карта зависимостей и рисков, SOURCE REVIEWED | SOURCE REVIEWED | NOT RUN | NOT RUN |
| CORE-286B-001 | GameState/target/group/GCD/identity/bind переходы | Дополнены реальные Engine+Eligibility mock-сценарии | NOT RUN | NOT RUN | NOT RUN |
| CORE-286C-001 | Secret ID/name/texture из SpellCatalogue | Новые mock-кейсы, guarded lookup | NOT RUN | NOT RUN | NOT RUN |
| CORE-286D-001 | Read-only CoreObservation, secret/missing/untrusted | 20 Lua assertions, точные SHA исходников совпадают | **LOCAL PASS 20** (texlua; SHA verified) | NOT RUN | NOT RUN |
| CORE-286E-001 | TOC порядок, наличие шести локалей, manual CI | Static source verification: 6 locales present, 11 mock suites listed, manual-only workflow, TOC order | **STATIC PASS** | NOT RUN | NOT RUN |
| CORE-286E-002 | Все 11 Lua suites на полном рабочем дереве | Локальный запускатель добавлен; общий прогон доступен после получения всех файлов в workspace | NOT RUN | NOT RUN | NOT RUN |

**Принцип доказательств:** `LOCAL PASS` относится только к прямому запуску `tests/stage_02_08_v14_observation.lua` с файлом `CoreObservation.lua`, чьи Git blob SHA подтверждены соответственно `3e1fe9ffcbddbf37d9c72eec5bebf6626a9ae9db` и `c8ef6ac3d3abbd3d716557c3fe4d957acd059c8b`. Сценарии других модулей на этом SHA не исполнялись локально. Не переносить прежний CI PASS 2.8.4 на текущий коммит. GitHub Actions запускать один раз перед общим игровым QA, по согласованию заказчика.

## DevTools DT-1–DT-6 — регрессия и статус доказательств
| ID | Область | Требование | Локально | CI | WoW Forever |
|---|---|---|---|---|---|
| DT-001 | Две поставки | Все файлы KordRotation идентичны в обоих ZIP, DevTools только во втором | NOT RUN | NOT RUN | NOT RUN |
| DT-002 | Загрузка | Два TOC, dependencies, отдельные SavedVariables, все модули существуют | NOT RUN | NOT RUN | NOT RUN |
| DT-003 | Запись | Только ручной Start/Stop, после /reload выключена, ограничены буфер и история | NOT RUN | NOT RUN | NOT RUN |
| DT-004 | Secret | Защищённые значения/имена/GUID не экспортируются | NOT RUN | NOT RUN | NOT RUN |
| DT-005 | API v14 | Allowlist, presence-only не считается CLIENT PASS | NOT RUN | NOT RUN | NOT RUN |
| DT-006 | Трассировка | EVENT/ENGINE лишь при записи, Stop отключает callbacks | NOT RUN | NOT RUN | NOT RUN |
| DT-007 | UI | Семь рабочих кнопок, ручной текстовый экспорт, отсутствие DevTools UI в user ZIP | NOT RUN | NOT RUN | NOT RUN |
| DT-008 | 6 локалей | Полные labels/tooltips для enUS/ruRU/frFR/deDE/ptBR/esES | NOT RUN | NOT RUN | NOT RUN |
| DT-009 | Производительность | Время чтения observer; не выдавать за CPU всего аддона | NOT RUN | NOT RUN | NOT RUN |

Полный мок-набор не является игровым доказательством; API матрица v14 CLIENT PASS по-прежнему 0/101. История предыдущих mock PASS к текущему SHA не переносится.

### DT-1–DT-6: фактические локальные доказательства (не общий CI)
| Проверка | Фактический результат | Граница доказательства |
|---|---|---|
| `scripts/build_variants.py` (Git blob `9ed24b775964ca3ff078577d0da3ac5e430ac779`) | **LOCAL PASS**: синтетические пользовательский/диагностический ZIP; общий файл совпадает, DevTools только во втором; отсутствующий TOC-модуль вызывает ошибку | Полная упаковка реального checkout NOT RUN |
| Registry `ff4f3caa0e1d9e02051cedf921726595fed6c3f3`; тест `a2aef8763daba5cdd2ab3c688318af349da00170` | **LOCAL PASS:** 101 строка, 79 presence-only, 22 UNKNOWN | Не запуск игрового API |
| Probe `e174c645cdead6547b9e0cb9a1d7ffa410cebb70`; тест `7c870986150daab4de717b60d61ffccbbbb2353c` | **LOCAL PASS 12 assertions** | Только mock bridge, не игровой PASS |
| Aggregate Trace `bc06d83fafb6339a50882acd1c80572886c7c179`; тест `bdba8661768111a6db1a002dff02e4b61eb38e4f` | **LOCAL PASS 17 assertions** | Только агрегированные события mock, не per-spell trace |

**Полная локальная регрессия (18 Lua suites), GitHub Actions и внутриигровой WoW Forever QA — NOT RUN.** В текущем dev-репозитории документация описывает исходники двух устанавливаемых аддонов, а не доказанную установленную сборку. CLIENT PASS API v14 остаётся 0/101.

## Очистка перед Profile Contract v1 (2.9-A)
| ID | Проверка | Статус | Доказательство |
|---|---|---|---|
| CLEAN-001 | Profile Contract сохранён дословно, включая завершающую LF | SOURCE PASS | Git blob `17415a2401f9b82bd2c580fa8d69d63483a38a65` |
| CLEAN-002 | Старый README сохранён как архив, действующий README не содержит старых статусов | SOURCE PASS | `docs/archive/README_HISTORY_2026-11-21.md` |
| CLEAN-003 | AGENTS/ROADMAP/Creation Guide/rotation indexes используют 2.9 и Contract v1 как SPEC ONLY | SOURCE PASS | KR-20261121-063/064 |
| CLEAN-004 | В обоих тестовых ZIP исключены неподключённые Lua, сохранён Logo.blp и полная идентичность общего каталога | LOCAL PASS (synthetic) | `scripts/build_variants.py` blob `98aa1bc4b7552d052d05b2f8f31b82dc319ef682` |
| CLEAN-005 | Две mock-фикстуры исправлены | SOURCE PASS / FULL LOCAL NOT RUN | KR-20261121-065 |
| CLEAN-006 | Полный Lua 5.1 и Python прогон по реальному checkout | NOT RUN | Не переносить PASS с прошлого SHA |
| CLEAN-007 | CI manual-only, игровая проверка | NOT RUN | Перед общим QA |


## Контракт v1 — замена устаревших тестов этапа 2.8 (KR-20261121-076)
| ID | Предмет | Новый актуальный файл | Статус |
|---|---|---|---|
| PC-001 | Схема v1: Spells, Needs, Config, Rules, version, status, диапазоны уровней | `tests/profile_contract_v1.lua` | SOURCE IMPLEMENTED / LOCAL NOT RUN |
| PC-002 | UNKNOWN выше READY и разрешённый необязательный skip | `tests/profile_contract_v1.lua` | SOURCE IMPLEMENTED / LOCAL NOT RUN |
| PC-003 | Ошибка условия при skip всегда останавливает выбор | `tests/profile_contract_v1.lua` | SOURCE IMPLEMENTED / LOCAL NOT RUN |
| PC-004 | Ленивые all/any и правила, raw snapshot недоступен | `tests/profile_contract_v1.lua` | SOURCE IMPLEMENTED / LOCAL NOT RUN |
| PC-005 | Eligibility BLOCKED → следующий, UNKNOWN → стоп и кэш за оценку | `tests/profile_contract_v1.lua` | SOURCE IMPLEMENTED / LOCAL NOT RUN |
| PC-006 | Неподдерживаемый PET_COMMAND пропускается без иконки | `tests/profile_contract_v1.lua` | SOURCE IMPLEMENTED / LOCAL NOT RUN |
| PC-007 | Разные уровни профилей и draft/mock_tested недопуск в бой | `tests/profile_contract_v1.lua` | SOURCE IMPLEMENTED / LOCAL NOT RUN |
| PC-008 | Реальные GameData providers, 5.1, Secret & client | будущий stage 2.9-D / WoW Forever | NOT RUN |

`tests/stage_02_08_rotation_engine.lua` и `tests/stage_02_08_v14_rotation_contract.lua` — **удалены из текущего дерева** как тесты прежнего архитектурного формата; их прежние результаты и исходники остаются в Git history. Другие GameAPI/GameState/Eligibility/UI/DevTools тесты сохранены. Никакого выполнения GitHub Actions на этом SHA не было.

### Новые проверки перед финальной локальной регрессией (2.9-C)
| ID | Сценарий | Статус |
|---|---|---|
| PC-009 | Экспериментальный профиль только с явным allowUnverifiedProfiles | SOURCE TEST ADDED / NOT RUN |
| PC-010 | RotationDisplay скрывает experimental без разрешения и после его отзыва | SOURCE TEST ADDED / NOT RUN |
| PC-011 | S:any различает false/nil, некорректный тип не приводит к skip | SOURCE TEST ADDED / NOT RUN |
| PC-012 | Needs не вызывает провайдер для необъявленного Spell ID | SOURCE TEST ADDED / NOT RUN |
| PC-013 | ResolveForEngine не копирует профиль; Get возвращает отдельную копию | SOURCE TEST ADDED / NOT RUN |

Активный набор — **17** Lua suites; полный локальный Lua 5.1 / CI / WoW Forever NOT RUN.

### Контрольная точка 2.9-C (KR-20261121-085)
[Contract_v1_Status_2_9.md](Contract_v1_Status_2_9.md): единый фактический список внедрённого кода, проверенных статических инвариантов и блокирующих результатов Lua/игры. В исходниках добавлены сценарии false CFG, finite CFG, protected SpellID; их выполнение по точному SHA НЕ подтверждено. Оригинальный документ контракта v1 остался побайтово неизменным.
