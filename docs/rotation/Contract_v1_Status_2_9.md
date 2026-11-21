# Этап 2.9-C — контрольная точка минимального Profile Contract v1

**Дата:** 2026-11-21. **Статус:** SOURCE IMPLEMENTED / TARGETED STATIC CHECKS PASS / LUA 5.1 NOT RUN / CLIENT NOT RUN. **Пилот Hunter BM не подключён.**

## Единый канон и код

- [Profile_Contract.md](Profile_Contract.md) — точная исходная версия заказчика, Git blob `17415a2401f9b82bd2c580fa8d69d63483a38a65`. Оригинал **не редактировать** ради смены статуса реализации: это исходное проектное соглашение.
- `KordRotation/Core/RotationProfiles.lua` — новый `contractVersion=1`, Needs allowlist, Spells, Config, Rules, статусы draft/mock_tested/experimental/verified; неперекрывающиеся диапазоны уровней; запрет неразрешённого skip; защитная копия `Get()`, доверенный `ResolveForEngine()` без копирования всех Rules на каждом Evaluate.
- `KordRotation/Core/RotationConditions.lua` — один ограниченный контекст S на оценку, без прямого snapshot и глобального WoW API; ленивые all/any, трёхзначные is/isNot/eq/ge/le; кэш провайдеров и Eligibility на один вызов Evaluate; нет подмены UNKNOWN ложью.
- `KordRotation/Core/RotationEngine.lua` — один ленивый проход с `pcall` по приоритету, stop по умолчанию, контролируемый skip только для неопределённого условия, Eligibility UNKNOWN всегда stop; неподдерживаемая PET_COMMAND пропускается без иконки. Сохраняется единственный текущий результат, отсутствие автокаста и прежний формат display.
- `KordRotation/UI/RotationDisplay.lua` — отдельный gated показ experimental, если `allowUnverifiedProfiles=true`; при отсутствии разрешения такая иконка не отображается.
- `scripts/build_variants.py` продолжает собирать из **единого** `KordRotation/` две побайтово согласованные поставки; неподключённые Hunter не попадают ни в один ZIP.

## Проверяемые исправления, обнаруженные в ходе миграции

1. `S:any` — ошибка `unknown and nil or false` исправлена, `nil` остаётся `nil`.
2. Lua CFG bool и enum — `false` не заменяется дефолтом. Первопричина подтверждена локальной краткой Lua-репродукцией, это не полный тест движка.
3. Числовой CFG отвергает `NaN/+Infinity/-Infinity`, защищённый SpellID проверяется через GameAPI до сравнений.
4. Ошибочный тип результата дочернего `all/any` бросает exception; Engine преобразует его в `UNKNOWN/condition_error`, не в разрешённый skip.
5. Разграничены runtime ID ветки `HUNTER_TREE_1` и ID конкретного диапазона профиля `HUNTER_BM_LEVELING_PVE`.

## Ревизия тестов

**17 актуальных Lua mock suites**: 18 исторических минус два устаревших Engine 2.8 tests плюс новый `tests/profile_contract_v1.lua`. Локальный `scripts/run_local_lua_regression.sh` и ручной workflow имеют одинаковые 17 путей, каждый файл существует. Старые engine tests доступны в Git history, но отсутствуют в текущем checkout.

В новом v1 mock добавлены сценарии: валидатор и уровни профиля, UNKNOWN stop/skip, `pcall`, lazy all/any, per-evaluation Eligibility cache, запрет undeclared needs, экспериментальный explicit opt-in, обнуление иконки при отзыве допуска, `false` CFG, nonfinite CFG и protected SpellID. Исторические GameAPI/GameState/Eligibility/UI/DevTools тесты сохранены.

**Что действительно проверено на актуальных исходниках:**
- Пять изменённых Lua-файлов: статическая проверка баланса скобок/строк/комментариев — PASS. Это не Lua compiler и не runtime.
- TOC `RotationConditions.lua` и перечень файлов — PASS.
- 17/17 тестовых путей совпадают между локальным runner и manual-only GitHub workflow; пропущенных путей нет.
- Точный Git blob пользовательского контракта остался неизменным.
- Референсные архивы Sonah, MaxDps, JustAC, ForeverAuras, ForeverRotation и RotationGuide исследованы на уровне структуры и профильных модулей; без копирования кода.

**Что НЕ выполнялось:** полный `lua5.1/luac5.1` на актуальном Git checkout (в доступной локальной среде нет полного checkout и бинарника Lua 5.1), новый `profile_contract_v1.lua` в полном runtime, GitHub Actions (запрещено запускать до общего QA), клиент WoW Forever. **Не писать 17/17 PASS.**

## Дополнительная правка после контрольной точки (KR-20261121-086…088)

- `RotationConditions.lua`: `spellFact(id, "inRange")` теперь отказывает (`nil`) для ID вне `Needs.ranges` **до обращения к провайдеру**. Наличие ID в `Spells` само по себе недостаточно для запроса дальности.
- `tests/profile_contract_v1.lua`: проверяется отсутствие вызова `Fact` для недекларированного range-ID и наличие вызова для разрешённого ID.
- **Проверка исполнения:** тесты обновлены, но новый Lua 5.1 mock-прогон не выполнен. 17-suite/клиент/CI по-прежнему NOT RUN; изоляция `UNKNOWN` от `READY` сохраняется.

## Уточнение локальной проверки (KR-20261121-090…091)
- Локальный runner теперь требует настоящий `lua5.1` и подтверждает `_VERSION == "Lua 5.1"`; `texlua` не подменяет приёмку (в текущей среде он сообщает `Lua 5.3`).
- Прямая загрузка полного Git checkout из текущего контейнера заблокирована DNS; GitHub доступен через подключение. **Ни один из 17 Lua mock suites пока не имеет подтверждённого runtime PASS.**
- После получения checkout с Lua 5.1 запустить `bash scripts/run_local_lua_regression.sh`, затем зафиксировать результаты пофайлово. До этого статус SOURCE IMPLEMENTED / LUA 5.1 NOT RUN.

## Проверка границы фактов и провайдеров (KR-20261121-094)

- До KR-20261121-097 методы `GameState.ReadSignal` и `AbilityEligibility.Fact` отсутствовали. Теперь `AbilityEligibility.Fact` частично реализован (см. ниже), а `GameState.ReadSignal` реализован частично для положительного доказательства аур (подробности ниже). Вызовы условий через `S` остаются `UNKNOWN`/`nil` до реализации подтверждённых источников; наличие mock-заглушек в тесте не доказывает работоспособность WoW API.
- Добавлен mock-контроль: `Needs.ranges` запрещает вызов даже при включённом провайдере; подтверждённое `READY(false)` сохраняется как `false`, повторное чтение внутри контекста не происходит, а новый контекст читает заново.
- Проверки сохранены как исходный код; **Lua 5.1 runtime NOT RUN**. Они не повышают статус `experimental`/`verified` и не разрешают подключение Hunter BM.

## Частичный фактический провайдер v14 (KR-20261121-097…098)

- `AbilityEligibility:Fact(id, kind, options)` добавлен только для `cooldownActive` (читаемое `C_Spell.GetSpellCooldown(...).isActive`) и `inRange` (проверка текущей цели через `C_Spell.IsSpellInRange`, либо валидный legacy 0/1). Возвращает `{status="READY",value=<boolean>}` только при доступном обычном boolean; ошибка, nil, secret и неподдерживаемый источник = `UNKNOWN`.
- `isOnGCD` не используется для вывода активности кулдауна. Положительная дальность / отрицательный факт кулдауна не означают итоговую пригодность способности: `Evaluate` остаётся единственным источником финального допуска.
- `known` и `chargesAtLeast` пока отвечают `UNKNOWN`: требуется отдельная доказательная проверка spellbook, а у `chargesAtLeast` нет порога в текущем интерфейсе `spellFact(id,kind)`.
- В `tests/stage_02_07_eligibility.lua` добавлены сценарии true/false/UNKNOWN, secret Spell ID, защищённого поля cooldown и запрета угадывать `isActive` по `isOnGCD`. `GameState.ReadSignal` остаётся отсутствующим.
- **Статус:** SOURCE IMPLEMENTED (partial), MOCKS UPDATED, LUA 5.1 NOT RUN, CLIENT NOT RUN. Никакие API не объявлены подтверждёнными в реальном WoW клиенте.

## Первый этап GameState.ReadSignal (KR-20261121-101…102)

- `GameState:ReadSignal` реализован только для `player.buff` и `target.debuff`, согласно v14 #12/#13. Использует `GameAPI.Read` и `GameAPI.ReadField`, не обращается к WoW API напрямую.
- Истинное наличие возвращается как `READY(true)` лишь после проверки точного `spellId` и правильного флага `isHelpful`/`isHarmful`. `nil`, тайный/недоступный AuraData, несовпадающий ID, недоказанная категория и неизвестная цель дают `UNKNOWN`.
- Отсутствие ауры **не** объявляется `READY(false)` из одиночного nil lookup: результат может быть скрыт или недоступен. Поэтому условия `S:isNot(...)` не будут ошибочно разрешать отсутствие DoT/баффа.
- `tests/stage_02_03_game_state.lua` расширен mock-проверками положительного наличия, nil, protected values, несоответствия типа и отказа чтения при отсутствующей цели.
- `enemy.count`, `target.ttd`, `autoShot.swing` и `spell.range` через GameState остаются без источников и возвращают `UNKNOWN`. Реальные игровые API не подтверждены клиентским тестированием.
- **SOURCE IMPLEMENTED (partial); Lua 5.1 TESTS NOT RUN; WoW CLIENT NOT RUN; Actions NOT RUN.**

## Защита аур при смене цели (KR-20261121-105…106)

- `GameState.ReadSignal("target.debuff", ...)` теперь требует `READY` GUID из снимка оценки, проверяет его через `GameAPI.Read("UnitGUID", "string", "target")` **до и после** чтения ауры. Отсутствующий/secret GUID, несовпадение с текущей целью или смена цели во время запроса дают `UNKNOWN`.
- Проверки идут через `GameAPI.ReadField` и `GameAPI.Read`, не используют защищённые значения в ключах и не меняют политику `nil` — отсутствие ауры не доказано.
- В `tests/stage_02_03_game_state.lua` добавлены mock-сценарии устаревшего GUID, смены цели между чтениями, отсутствующего/защищённого GUID.
- Гарантия ограничена двумя последовательными проверками GUID внутри синхронного чтения; подлинность AuraData, поведение игры и атомарность API по-прежнему требуют клиентского подтверждения.
- **Lua 5.1 / 17 suites NOT RUN; клиент NOT RUN; GitHub Actions NOT RUN.**

## Расширенная защитная проверка аур (KR-20261121-109…111)

- `player.buff` с переданным снимком требует подтверждённое `player.exists=READY(true)`. Снимок с отсутствующим, секретным или неизвестным игроком прекращает запрос до Aura API и возвращает `UNKNOWN`. Прежний прямой вызов без снимка пока сохраняется для совместимости; полноценная фиксация личности игрока не заявлена.
- В mock-тест `stage_02_03_game_state.lua` добавлены проверки защищённой AuraData-таблицы, исключения в lookup, защищённого GUID после успешного чтения, а также присутствующего/отсутствующего/неизвестного игрока и отсутствия лишних API-вызовов.
- Вывод по v14 #12/#13 прежний: `nil` от прямого поиска ауры не доказывает её отсутствия. `READY(false)` **не реализован**, `UNKNOWN` сохраняется.
- Граница приёмки: изменения проверены по исходникам в GitHub; **17 Lua mock suites NOT RUN / Lua 5.1 NOT RUN / CLIENT NOT RUN / CI NOT RUN**.

## Блокирующие оставшиеся задачи ДО Hunter BM

1. Выполнить целевой контрактный mock на точном checkout в Lua 5.1, затем все 17 пересмотренных Lua tests, синтаксис и Python ZIP parity. Ошибки исправить до итогового общего QA.
2. Доработать и подтвердить по API v14 необходимые `GameState.ReadSignal` (auras по SpellID, range, enemyCount, TTD, swing) и `AbilityEligibility.Fact`. До этого будущие проверки должны возвращать UNKNOWN.
3. Выбор `targetMode=auto` сейчас сознательно возвращает `auto_target_count_unverified`; не включать автоподбор ST/AoE без достоверного счётчика.
4. CFG UI из схемы v1, хранение пользовательских конфигураций и локализация всех новых controls на 6 языков ещё не готовы; не выдавать наличие `Config` у профиля за готовую UI-генерацию.
5. Перед подключением Hunter выполнить статическую проверку запрета прямых WoW API в профиле и дифференциальные тесты против сохранённых исходников BM. Старые Hunter Lua сейчас не в TOC.

## Правила сохранности

История CHANGELOG и старые исследования не удаляются; они помечены историческими. Два ZIP содержат одно общее ядро, DevTools отдельный. `UNKNOWN` не превращается в `READY` ради удобства, игровые данные не выдумываются, автокаст не реализуется.
