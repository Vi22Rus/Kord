# KordRotationDevTools — обязательный контракт двух вариантов

Решение заказчика 2026-11-21: **диагностическая поставка — точная копия пользовательской KordRotation плюс отдельный диагностический аддон**. Это не вторая реализация движка.

## Одна кодовая база → два ZIP

- `KordRotation-user.zip`: только `KordRotation/`.
- `KordRotation-dev.zip`: **те же байты каждого файла** в `KordRotation/` плюс `KordRotationDevTools/`.
- Источник истинного пользовательского ядра/интерфейса/профилей — только `KordRotation/`. Запрещено создавать и редактировать его дублирующую копию отдельно.
- Любое изменение, не связанное с developer diagnostics, вносится в `KordRotation/` и поэтому попадает в обе поставки в одном сборочном действии.
- `KordRotationDevTools` — addon с `## Dependencies: KordRotation`; диагностический код, UI, логи и `KordRotationDevToolsDB` только там.
- Для сборки: `python3 scripts/build_variants.py --out dist`. Сборщик формирует JSON с SHA-256 **каждого общего файла**, а также сравнивает содержимое обоих ZIP побайтово. Если не совпадёт — сборка должна завершиться ошибкой. `dist/` не считать исходником.
- Нельзя включать DevTools Lua, developer toggles или диагностические SavedVariables в пользовательский ZIP. DevTools по умолчанию не записывает события.
- Совместимость: версии WoW Forever подтверждаются только игровым QA; LOCAL PASS и CI PASS — не клиентское доказательство.

## Неподвижные правила

Профили Hunter BM Leveling PvE 1–59 и общее ядро разрабатываются **один раз**. Две отдельные папки устанавливаются только при диагностической поставке. Настоящий DevTools не должен менять GameAPI, RotationEngine, AbilityEligibility, профили или счётчики ядра; только читать approved CoreObservation или отдельные guarded API при явном действии пользователя.

## DT-6: обязательная регрессия двух комплектов и параллельная разработка
Пользователь уточнил правило: диагностическая поставка содержит **точную копию всей текущей обычной сборки KordRotation плюс самостоятельный DevTools**. Следовательно, общие изменения всегда коммитятся в единственный `KordRotation/`, а не в две независимо редактируемые копии. Если меняется дизайн, UI, настройки или логика общего KordRotation — изменяется один исходник, а обе ZIP-сборки получают одни и те же байты. Developer-only изменения затрагивают исключительно `KordRotationDevTools/`.

Команда локальной сборки: `python3 scripts/build_variants.py --out dist`. Сборка проверяет TOC-ссылки, обязательную зависимость и SavedVariables DevTools, затем сравнивает весь базовый каталог в двух ZIP на уровне байтов и записывает SHA-256 всех общих файлов в `build-manifest.json`. Остановка при несовпадении обязательна.

Локальная проверка: `bash scripts/run_local_lua_regression.sh` (Lua 5.1 либо texlua, затем Python unittest). Расширенные тесты проверяют включение/остановку записи, Secret и overflow, API presence-only, события/перформанс, выключенное состояние после /reload и ключи шести локалей. Workflow GitHub Actions **только ручной**, не запускать перед каждым коммитом.

Приёмка реального клиента и FPS/RAM = NOT RUN до отдельной игровой проверки. Полный прогон в CI допускается лишь единожды перед общим QA по решению заказчика.

### Полная карта v14, без ложных клиентских PASS
`KordRotationDevTools/V14Registry.lua` содержит все 101 пронумерованных строки канонической матрицы v14. Для **79 строк** указан хотя бы один метод из существующего allowlist GameAPI только для проверки **наличия**. **22 строки** без безопасной одиночной проверки остаются `UNKNOWN/no_single_safe_probe`. Присутствие метода НЕ подтверждает функциональность составной возможности. Реестровый метод не выполняет боевых действий; `ProbeAll` запускается только вручную, клиентский PASS по матрице остаётся 0/101.

### DT-4: ограниченная агрегированная наблюдаемость
`CoreObservation` только читает готовую сводку `RotationDisplay`: профиль READY/UNKNOWN/UNAVAILABLE/BLOCKED и количество кандидатов с READY/BLOCKED/UNKNOWN без идентификаторов. `Trace.lua` записывает их изменения как PROFILE и ELIGIBILITY, плюс изменения счётчика EventBus.listenerErrors как ERROR, только после ручного Start. Логи per-rule и собственные Spell ID этим **не реализованы**. Агрегат может быть пропущен при ограничении частоты; следующий опрос повторит незаписанный статус. Дополнительных вызовов GameAPI или RotationEngine нет.

## Этап 2.9-A: очистка установочных ZIP без потери исходников
Сборщик включает только Lua-файлы, явно перечисленные в соответствующем `.toc`, сами `.toc` и известные ресурсы `.blp/.png/.tga/.ogg/.wav/.mp3`. Неактивные `KordRotation/Profiles/Hunter/*.lua` остаются в Git и для дифференциальных mock-тестов, но не занимают место в установочной поставке до регистрации. В обоих ZIP содержимое всего **устанавливаемого** каталога `KordRotation/` совпадает побайтово; оригинальные исходники не дублируются. Добавление будущего активного профиля требует явного TOC и теста. Полный real checkout ZIP и WoW QA должны быть проверены отдельно.

## Opt-in runtime API call trace — 2026-11-22

**Источник истины:** `KordRotation/Core/GameAPI.lua` wraps its allowlisted read-only adapter calls. The only capture entry points are `KordRotationCoreObservation.BeginAPITrace/APITrace/EndAPITrace/APIMethodNames`, called by the independent `KordRotationDevTools` during manual recording. In normal user-addon mode this instrumentation is inactive. Neither protected raw data nor spell IDs, target names, GUIDs or keys cross the bridge.

**Two independent layers:** `API matrix_probe 1..101` covers the 101 canonical v14 *presence-only* source slots, including UNKNOWN composites. `METHOD method_call` and terminal `METHOD method_total` cover **actually observed** `GameAPI` read attempts: exported columns are `sequence kind status reason matrix elapsed time detail method count`. For actual calls, `detail` is a bounded safe internal failure code or `none`; `method` is an allowlisted API name, presence-only `GameAPI.Probe.<name>`, fixed action-scanner checkpoint, or bounded `GameAPI.ReadField.<fieldKey>`. Matrix column maps to the first registry row for a method; repeated uses of one method by other v14 scenarios are *not* individual runtime proofs. For those cases, see the separate row census and engine's rule/signal/stage evidence.

**No quiet truncation:** invalid method identities are collapsed to `GameAPI.unsupported`, invalid/previously unseen schema codes show `diagnostic_code_unmapped` / `diagnostic_detail_unmapped` in legacy records; generic METHOD internal reason tokens are validated by ASCII identifier grammar and do not require per-reason entries in Recorder. Capture failures show `method_trace_unavailable`, overflowing buffers `method_trace_overflow`. Export prints `truncated=1` when the UI text byte limit cuts off rows and `evicted_parts=N` when in-session SavedVariables segment retention loses older segments; `dropped=N` independently counts rejected record writes. Old export tools reading the initial eight TSV columns remain compatible; `method,count` are appended.

**Boundaries:** counters are grouped by method + status + reason; there is no raw argument/value recording or exact per-cast time sequence for every repeated invocation. One initial observation and final total are retained for each tuple. Client capability certainty still requires client tests, and unsupported composite v14 scenarios remain UNKNOWN. Debugging a result must distinguish `GameAPI.Probe.*` from actual method calls and consult `RULE/SIGNAL/STAGE/BAR` to identify conditional/eligibility semantics.

**QA:** source updated; `tests/stage_02_03_game_state.lua`, `tests/devtools_trace.lua`, and `tests/devtools_recorder.lua` extended. Latest Lua 5.1/Forever testing NOT RUN. GitHub Actions intentionally not invoked before shared QA.
