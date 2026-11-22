# Карточки QA

Источник: REQUIREMENTS.md, blob 9efdec1900398c978ea121818fb5950cb1620337.

### QA-01 — DevTools: запись, трассировка, зонды API. Отдельный аддон, ядро побайтово то же, что у пользователя

ID: [QA-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L8357). Приоритет: P0. Lua: упомянут (точный статус в источнике).

**Вердикт / статус**

**Вердикт**

**SOURCE IMPLEMENTED / P0 / ПОЛНЫЙ QA НЕ ПОДТВЕРЖДЁН.** Отдельный DevTools, TOC-зависимость, собственные SavedVariables, трассировка, API-пробы, UI и сборщик побайтово идентичных общих файлов присутствуют в исходниках. Нельзя утверждать полную готовность до реального запуска сборки, всех тестов и WoW Forever. `CLIENT PASS=0/101` остаётся действующим нормативным значением.

**Архитектурные ссылки:** DA-03, DA-04, DA-05, UI-06, UI-07, AC-07, `docs/BUILD_VARIANTS_AND_DIAGNOSTICS.md`, `docs/rotation/Canonical_API_Matrix.md`, `KordRotationDevTools/*`, `scripts/build_variants.py`. **Обратные ссылки добавлены в DA-03, DA-04, DA-05, UI-06, UI-07, AC-07**; повторно создавать ранее предусмотренные инструменты запрещено.

**Изменения Lua:** отсутствуют. Только документация.

**Ретроактивное уточнение QA-02:** DevTools `Recorder` обязан сохранять **все проверенные внутренние machine reason codes** через безопасный общий `DiagnosticReasonEnvelope` QA-02, без ручного whitelist каждого кода и без `diagnostic_code_unmapped` для валидного доверенного reason. Подпричины, фактическая панель, evaluated stages и `NOT_EVALUATED` должны сохраняться структурно; untrusted строки по-прежнему отбрасываются. Независимый `Audit()` не должен повторно вычислять пропущенные ленивым движком правила и менять игровой результат.

**Ретроактивное уточнение QA-03:** DevTools QA-01 обязан иметь mock tests под настоящим Lua 5.1 для Start/Stop, reload, opt-in, secret, v14, recorder, byte-identical ZIP; единый CI/local test manifest QA-03, без пропуска devtools suites.

**Ретроактивное уточнение QA-04:** `ProbeAll` DevTools QA-01 даёт только `PRESENCE_ONLY`, не `CONFIRMED` клиентской совместимости. Для каждого matrixID требуется отдельный проверенный `ApiEvidenceRecord` QA-04 с client build, сценарием, безопасными результатами и явным вердиктом; `CLIENT PASS` увеличивается лишь по подтверждённым реальным игровым тестам.

**Ретроактивное уточнение QA-05:** при дифференциальной проверке QA-05 DevTools включён/выключен на одинаковом sanitized trace и точном SHA; он не должен менять production-решения. Диагностический `AuditFull` не выступает эталоном live-движка и выполняется только изолированно.

**Ретроактивное уточнение QA-06:** QA-06: DevTools не является способом обойти статический запрет игровых вызовов в профилях; результат линтера включается в offline QA report, а не в runtime user build.

**Выбранный путь Kord**

**Выбранный путь Kord**

**Оставить существующие `KordRotationDevTools/*`, `KordRotationCoreObservation`, `scripts/build_variants.py` и единственный `KordRotation/` каноническими.** Дорабатывать покрытие traces и QA **в этих модулях**, не создавать второй recorder, EventBus, engine, probe registry или дублирующее ядро. Все P0 требования диагностического наблюдения закрываются только доказанными source/mock/client результатами; `SOURCE IMPLEMENTED` не равен `QA COMPLETE`. Для ранее рекомендованных универсальных механизмов ссылки обязательны: DA-03 и UI-06 используют QA-01, DA-04/DA-05 используют opt-in замеры, AC-07 сохраняет причины STOP. Сохранить архитектуру двух физических аддонов из нормативного документа.

**Требуемые изменения (полный текст)**

**Требуемые изменения**

1. Утвердить формальную схему `DevToolsSession` и `ObservationRecord`: matrixID, module, status, machine reason, timestamp, revision, evaluationID/priority при наличии, bounded scalar context; запрещать raw/secret значения.
2. Проверить все входы `KordRotationCoreObservation` и `Trace.lua` на отсутствие повторной оценки движка, изменение профиля/Eligibility, секретные значения и несанкционированный protected API.
3. Проверить явный opt-in Start/Stop, состояние OFF после установки и /reload, отсутствие hidden production recording, отдельные `KordRotationDevToolsDB` и отсутствие dev кода в user ZIP.
4. Покрыть `EVENT/ENGINE/PROFILE/ELIGIBILITY/METHOD/API/ERROR/PERFORMANCE` без фиктивных событий и без потери первого UNKNOWN/STOP reason; недоступные поля помечать `UNAVAILABLE`.
5. Проверить `V14Registry` и `ProbeAll` по всем 101 строкам матрицы; presence-only не переводить в CLIENT PASS, сохранять ID и evidence для ручной игровой проверки.
6. Проверить кольцевой буфер, ограничения записей и SavedVariables, dedup/rate-limit, dropped counter, безопасный экспорт/очистку и корректный жизненный цикл после /reload.
7. Проверить нагрузку DevTools в OFF и RECORDING, throttled observations, EventBus storm, ограничение времени/памяти, отсутствие постоянного тяжёлого profiler и влияния на вывод Kord.
8. Запускать `scripts/build_variants.py` и `tests/test_build_variants.py` на текущем HEAD; сравнить списки общих файлов, SHA-256 и bytes, подтвердить отсутствие DevTools в user и корректную зависимость dev.
9. Прогнать `tests/devtools_*.lua`, регрессию ядра, locale/tooltip на шести языках, сценарии missing bridge, protected/secret, API exception, overflow, restart/reload, manual export, два одновременно загруженных аддона.
10. В реальном WoW Forever подтвердить загрузку двух аддонов, все UI-кнопки, Start/Stop, trace engine/eligibility/STOP, API probe на актуальном клиенте, performance, безопасный экспорт и паритет пользовательских рекомендаций; протоколировать по версии клиента, build/commit и строке v14. Без игры отмечать NOT RUN.

**Тесты и диагностика**

в файле не указано

**Архитектурные и обратные ссылки:** NO-06, NO-05, NO-04, SHA-256, UI-07, DA-03, UI-06, DA-04, DA-05, AC-07, QA-02, QA-03, QA-04, QA-05, QA-06.

---

### QA-02 — Журнал с полным списком причин, а не обрезанным белым списком; подпричины для панели и проверок

ID: [QA-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L8434). Приоритет: P0. Lua: упомянут (точный статус в источнике).

**Вердикт / статус**

**Вердикт**

**НЕ СООТВЕТСТВУЕТ ПОЛНОМУ ТРЕБОВАНИЮ / P0 / ПОДТВЕРЖДЁННАЯ ПОТЕРЯ REASON И SUBREASON.** В `Recorder.lua` ручной whitelist действительно заменяет новые внутренние причины на `diagnostic_code_unmapped`, а неизвестные детали на `diagnostic_detail_unmapped`. `Trace.lua` сохраняет часть причин, но структура BM-specific и не универсальна. Исправление должно сохранить безопасность и lazy semantics. **Lua, CI и игровой QA NOT RUN**; это документальный аудит, не реализация.

**Архитектурные ссылки:** QA-01, UI-06, UI-08, DA-03, EN-A2, EN-A3, AC-07, `RotationEngine`, `AbilityEligibility`, `ActionBarScanner`, `KordRotationCoreObservation`, `KordRotationDevTools/Recorder.lua`, `Trace.lua`. **Обратные ссылки внесены в QA-01, UI-06, DA-03, EN-A2, EN-A3, UI-08**; существующий DevTools должен быть исправлен, не заменён новым.
 
**Изменения Lua:** отсутствуют. Только документация.

**Ретроактивное уточнение QA-03:** полный reason/subreason envelope QA-02 проверять Lua 5.1 mock-тестами, включая новый trusted reason без whitelist, NOT_EVALUATED и отсутствие повторной оценки ленивого engine; `AuditFull` отдельно маркировать diagnostic-only, проверять non-interference и не объявлять live-equivalent.

**Ретроактивное уточнение QA-04:** полный журнал QA-02 связывает API reasons/subreasons с v14 `matrixID`, method, source, revision, client verdict и safe evidence. Отсутствие метода, secret result и несовпадение сигнатуры — разные причины; не превращать presence-only в подтверждение.

**Ретроактивное уточнение QA-05:** дифференциальный отчёт QA-05 сравнивает вычисленные trusted `reason/subreasons` и `NOT_EVALUATED` из единого QA-02 envelope; самостоятельный диагностический обход непрочитанных условий не признаётся эквивалентной трассой и не должен влиять на live evaluation.

**Выбранный путь Kord**

**Выбранный путь Kord**

**Единый `DiagnosticReasonEnvelope` и безопасный read-only observation bridge в уже существующем QA-01, с generic bounded machine reason validation и структурными subreasons.** Убрать **ручной словарь как обязательное условие сохранения доверенного reason**, но не убирать границу доверия/allowlist источников, secret guards, ограничения формата и размеров. Не создавать второй recorder, engine, API probe, второй журнал или BM-specific runtime evaluator. Отдельные адаптеры источников (DISPLAY/ENGINE/ELIGIBILITY/ACTIONBAR/API) только отображают **фактически вычисленные** проверки. В DevTools journal хранить reason chain и coverage flags, в user UI — краткое объяснение UI-06. Переходный compatibility decoder для старых сессий не должен выдумывать потерянные причины: помечать legacy `diagnostic_code_unmapped` как `UNRECOVERABLE_LEGACY_LOSS`.

**Требуемые изменения (полный текст)**

**Требуемые изменения**

1. Ввести versioned `DiagnosticReasonEnvelope` с primary reason, массивом `subreasons`, channel, source, priority, evaluationID, revision, observed/notEvaluated, complete/limited/dropped и лимитами глубины/длины.
2. Изменить `Recorder.sanitizeReason/safeDetail`: любой доверенный bounded internal reason сохранять дословно без ручного whitelist; недоверенные произвольные строки не принимать, даже при корректном regex. Добавить тест на новый ранее неизвестный код.
3. Передавать trusted source metadata через `KordRotationCoreObservation` и отдельные adapters, чтобы DevTools не принимал любой внешний addon string за внутреннюю причину. Secret safety выполнять до чтения/сравнения/сериализации.
4. В `RotationEngine` observation сохранять все **реально исполненные** `ruleChecks`, decisive priority, eligibility/barReason и `NOT_EVALUATED` для пропущенных; не выполнять `Audit()` повторно по всем правилам, если это изменяет lazy execution или нагрузку.
5. Убрать BM/Arcane-specific жёсткие списки `bm_rule_*`, `bm_stage_*`, `arcane_check_*` как единственный путь получения причин; заменить generic profile/rule/checkPath и metadata из зарегистрированных схем.
6. Для main/defensive панели записывать проверенные подпричины `panelEnabled/visibilityMode/combat/target/frameCreated/frameShown/engine/texture`, с отдельными каналами, используя UI-05/UI-06; не выдумывать «нет цели» при UNKNOWN.
7. Для eligibility, actionbar, binding/glow и API v14 записывать реальные подпричины по этапам с source/revision и `NOT_EVALUATED` для непрочитанных; не дублировать AbilityEligibility, ActionBarScanner, BindingResolver.
8. Сохранить кольцевой буфер, opt-in, dropped counters, dedup/rate-limit и SavedVariables; при частичной потере явно выводить `limited` и счётчик/диапазон потерянных записей, не маркировать неполный журнал COMPLETE.
9. Добавить в DevTools просмотр цепочки причин и безопасный ручной экспорт (machine code + локализованное UI-07 объяснение), без raw GUID/имён/ошибок/секретов; legacy-сессии с unmapped помечать невосстановимыми.
10. Тесты: новый код без whitelist, nested reasons, multiple subreasons, проверка панели при скрытии, main/defensive независимо, 40 приоритетов с ранним READY/UNKNOWN, short-circuit all/any, проверка реально непрочитанных стадий, protected/secret, untrusted malicious string, buffer overflow, /reload, throttling, cross-profile BM/non-BM, API v14, Lua 5.1, обе ZIP и реальный WoW Forever. Отдельно сравнить до/после рекомендации и число API calls.

**Тесты и диагностика**

в файле не указано

**Архитектурные и обратные ссылки:** NO-04, AC-07, QA-01, UI-06, UI-07, UI-05, UI-08, DA-03, QA-03, QA-04, QA-05.

---

### QA-03 — Mock-тесты движка и профилей, запуск на Lua 5.1

ID: [QA-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L8506). Приоритет: P0. Lua: упомянут (точный статус в источнике).

**Вердикт / статус**

**Вердикт**

**ЧАСТИЧНО РЕАЛИЗОВАНО / P0 / LUA 5.1 MOCK INFRASTRUCTURE EXISTS, COVERAGE AND PARITY NOT COMPLETE.** Реальные Lua 5.1 CI, mock suites и Python packaging tests существуют. Подтверждённое расхождение локального и CI списка тестов (17 против 27), отсутствует единый coverage gate и доказательство client QA. **Текущий запуск Lua/CI NOT RUN.**

**Архитектурные ссылки:** QA-01, QA-02, EN-A2, EN-A3, EN-A7, DA-08, `tests/`, `.github/workflows/lua-regression.yml`, `scripts/run_local_lua_regression.sh`, `scripts/build_variants.py`. **Обратные ссылки добавлены в QA-01, QA-02, EN-A2, EN-A3, EN-A7, DA-08.**

**Изменения Lua:** отсутствуют. Только документация.

**Ретроактивное уточнение QA-04:** mock-тесты Lua 5.1 QA-03 подтверждают только контракт адаптера и обработку `UNKNOWN/secret`, но не клиентский API verdict. Для каждой v14 строки отдельно требуются client evidence, build и сценарий QA-04; CI не вправе увеличивать CLIENT PASS.

**Ретроактивное уточнение QA-05:** единый Lua 5.1 manifest/harness QA-03 используется и для воспроизводимых QA-05 differential fixtures; сравниваются реальные version-pinned old/new Lua на одном safe deterministic input trace, а не два mock-алгоритма. Изменения классифицируются как MATCH/EXPECTED_DELTA/REGRESSION/INCONCLUSIVE с evidence, а не объявляются автоматическим FAIL при любом отличии.

**Ретроактивное уточнение QA-06:** QA-06: добавить обязательный offline static profile purity gate в единый Lua 5.1 test manifest QA-03; синтаксический `luac -p` и runtime mocks не заменяют AST/scope проверку, а проверка исходника не подтверждает клиентский PASS.

**Ретроактивное уточнение QA-07:** QA-07 задаёт единый обязательный `ScenarioCase`/`ScenarioResult` и матрицу `state → expected action` для каждого профиля; QA-03 запускает их через настоящий production engine на Lua 5.1, не заменяя семантические ожидания собственными mocks.

**Выбранный путь Kord**

**Выбранный путь Kord**

**Сохранить существующий `tests/`, GitHub Actions и `scripts/run_local_lua_regression.sh`, унифицировать список suites через один test manifest, добавить недостающие contract tests на Lua 5.1.** Не создавать второй test runner, engine, profile registry или диагностический evaluator. QA-03 — обязательный quality gate для каждого будущего P0/P1 изменения; QA-01/QA-02 тестируются теми же production Lua-модулями и строго изолированными mocks. `AuditFull` допустим только в отдельном offline/test/opt-in сценарии с подтверждённой safety, без изменения live engine decisions.

**Требуемые изменения (полный текст)**

**Требуемые изменения**

1. Создать один versioned `tests/manifest` и заставить CI и local runner использовать его, убрать дублирующиеся списки 27/17, проверять missing/duplicate suite и версию Lua 5.1.
2. Обеспечить `luac5.1 -p` для **всех** Lua в обоих аддонах и tests, fail-fast при ошибке синтаксиса и недоступном `lua5.1`.
3. Ввести общий deterministic mock harness с fake WoW API, EventBus, clock, spellbook, buttons, pet, item, secure/secret values; сбрасывать состояние между tests, не подменять production engine логикой test double.
4. Покрыть profile registry/contract/config и выбор class/tree/spec/level/talents, rank selection, приоритеты, `UNKNOWN` для отсутствующих профилей, непроверенные experimental profiles.
5. Проверить `EN-A2/EN-A3`: first-match-wins, all/any short-circuit, exact API call counts, `UNKNOWN→STOP`, skipped predicates, single snapshot per evaluation, READY only via AbilityEligibility.
6. Покрыть eligibility/provider states: target hostility/friendly, combat, range/LOS, movement/casting, cooldown/GCD/charges, mana/energy/rage, learned max rank, item/pet/stance, aura, AoE and UNKNOWN fail-closed; unsupported features явно `NOT_IMPLEMENTED/NOT_TESTED`.
7. Для QA-02 добавить regression тест сохранения любого trusted bounded reason и nested subreasons, `NOT_EVALUATED`, source/revision, dropped metadata; запрет на повторные live API reads в диагностике.
8. Проверить UI-05/06/08: main/defensive visibility, target/combat transitions, missing icon explanation, actionbar Hide/Show/paging/bindings/glow, secret frame; отсутствие зависимости собственных рекомендаций от видимости чужой панели.
9. Проверить DevTools opt-in/OFF after reload, API matrix 101 rows, trace/recorder safety, производительность и byte-identical user/dev ZIP из одного исходного каталога.
10. Сделать CI обязательным quality gate и выдавать машинно-читаемый отчёт `SHA/Lua version/suites executed/failed/skipped/P0 coverage`; запускать локально и в GitHub Actions на **одном** manifest. После mock PASS провести отдельный WoW Forever client QA, не смешивать статусы.

**Тесты и диагностика**

в файле не указано

**Архитектурные и обратные ссылки:** NO-06, NO-05, NO-04, QA-02, QA-01, UI-05, DA-08, QA-04, QA-05, QA-06, QA-07.

---

### QA-04 — Матрица API: каждый вызов с вердиктом подтверждён / не подтверждён / отличается в WoW Forever

ID: [QA-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L8580). Приоритет: P0. Lua: упомянут (точный статус в источнике).

**Вердикт / статус**

**Вердикт**

**ЧАСТИЧНО РЕАЛИЗОВАНО / P0 / SOURCE MATRIX COMPLETE, CLIENT VERDICTS NOT VERIFIED.** Утверждённая v14 уже содержит 101 выбранную возможность и источниковые verdict, DevTools имеет per-row presence probes. Нет доказанного клиентского `CONFIRMED/DIFFERENT` evidence, полного runtime callsite inventory и отдельной модели client verdict. **CLIENT PASS=0/101.** Игровой QA, Lua/CI NOT RUN в этом аудите.

**Архитектурные ссылки:** QA-01, QA-02, QA-03, EN-A7, DA-03, AC-07, `docs/rotation/Canonical_API_Matrix.md`, `KordRotationDevTools/V14Registry.lua`, `Probe.lua`, `KordRotation/Core/GameAPI.lua`, `docs/BUILD_VARIANTS_AND_DIAGNOSTICS.md`. **Обратные ссылки внесены в QA-01, QA-02, QA-03, EN-A7, DA-03, AC-07**.

**Изменения Lua:** отсутствуют. Только документация.

**Ретроактивное уточнение QA-05:** QA-05 может сравнивать лишь source/mock поведение API adapters; дифференциальный PASS не повышает `CLIENT PASS` ни по одной из 101 строк v14. Неподтверждённые и различающиеся Forever API остаются отдельными `ApiEvidenceRecord` QA-04.

**Ретроактивное уточнение QA-07:** QA-07 помечает mock-сценарии с непроверенными WoW Forever API как MOCK ONLY/CLIENT UNVERIFIED; они не повышают `CLIENT PASS` v14.

**Ретроактивное уточнение CL-02:** CL-02: проверить в WoW Forever API aura ownership, dispelName, dead friendly targeting, resurrection combat restrictions, seal consumption, blessing group scope; непроверенные факты остаются UNKNOWN.

**Ретроактивное уточнение CL-03:** CL-03: обязательно подтвердить в WoW Forever trap shared cooldown, ranged swing timing, ammo/equipment, pet happiness, dead-zone range и Feign Death threat outcomes; неподтверждённые API не объявлять реализованными.

**Ретроактивное уточнение CL-04:** CL-04: подтвердить на WoW Forever combo power/target binding, energy tick timing, stealth detection, weapon enchant remaining/charges, interruptible casts и Gouge cast-break semantics.

**Ретроактивное уточнение CL-05:** CL-05: проверить WoW Forever Shadowform restrictions, shield/Weakened Soul, wand Shoot toggle, group unit tokens, dispel types, resurrection restrictions и group reagent rules.

**Ретроактивное уточнение CL-06:** CL-06: подтвердить WoW Forever totem slot/position/radius/expiry, shock shared cooldown, weapon enchant, dispel capabilities, Ancestral Spirit и Reincarnation mechanics; UNKNOWN при неподтверждённом API.

**Ретроактивное уточнение CL-07:** CL-07: проверить клиентские названия «превосходство», «зачарование», «подкрепление маны», а также polymorph break rules, freeze, mana gem and conjure spells; не выдумывать spellIDs.

**Выбранный путь Kord**

**Выбранный путь Kord**

**Расширять утверждённую `Canonical_API_Matrix.md` и существующий `KordRotationDevTools/V14Registry.lua` единым versioned `ApiEvidenceRecord`/callsite inventory, не создавать вторую матрицу или новый probe engine.** Сохранить 101 ID и все source verdict; отдельно накапливать подтверждённые client verdict, безопасно отображать в DevTools и связывать с QA-02 trace. `ProbeAll` остаётся presence-only; полноценный client verdict требует сценария, expected/observed behavior, client build и явной проверки. Новые неизвестные API не добавлять автоматически; выносить на утверждение обновления матрицы. Для критического неподтверждённого API сохранять UNKNOWN→STOP.

**Требуемые изменения (полный текст)**

**Требуемые изменения**

1. Ввести versioned `ApiEvidenceRecord` для каждого matrixID 1..101 с `sourceVerdict`, `presenceStatus`, `clientVerdict`, `reason`, build, commit, scenario, expected/observed safe behavior и evidence provenance.
2. Составить полный статический inventory всех runtime API callsites в `KordRotation/` и `KordRotationDevTools/`; сопоставить каждый вызов с v14 ID или `UNMAPPED_CALLSITE`. Запретить ложную классификацию косвенного API как уже проверенного.
3. Расширить `V14Registry` на multi-method chains и distinct row IDs; исправить `ProbeMethod` first-ID aliasing при одинаковом method, не ломая существующий presence-only режим.
4. Сохранить `ProbeAll` безопасным read-only, не вызывать произвольные функции и protected gameplay actions; отделить method presence от actual scenario execution.
5. Для каждой составной возможности фиксировать отдельно method presence, argument shape, return type/secret restrictions, context/target/movement/combat conditions и verdict всей chain.
6. Реализовать три client verdict и `NOT_RUN`, а также `STALE_REQUIRES_RETEST` после изменения клиента/метода; никогда не превращать отсутствие теста в отрицательный результат.
7. Добавить в QA-02 полный структурный trace API calls по matrixID с безопасными reason/subreason и ссылкой на evidence, без raw secret/tainted values.
8. Обеспечить per-row UI и экспорт DevTools, список всех 101 строк и агрегаты `CONFIRMED/UNCONFIRMED/DIFFERENT/NOT_RUN`; отчёт `CLIENT PASS` только по реальным игровым подтверждениям.
9. Тесты Lua 5.1: 101 уникальный ID, duplicates method→multiple IDs, nil method, missing bridge, secret/protected, method presence ≠ client PASS, DIFFERENT, stale build, evidence validation, unmapped callsites, version migration, безопасный экспорт, оба ZIP.
10. В реальном WoW Forever провести матрицу безопасных сценариев на фиксированном client build для 101 строк: target/player/pet, combat/out of combat, spellbook/level/rank, cooldown/charges/GCD, aura, power/HP, movement/cast, group/instance, actionbar/bindings, secret restrictions. Для непроверяемых сценариев оставить `NOT_RUN/UNCONFIRMED` с точной причиной; различия документировать и согласовывать изменения v14 до изменения production API.

**Тесты и диагностика**

в файле не указано

**Архитектурные и обратные ссылки:** NO-03, NO-02, CL-09, CL-08, QA-02, QA-01, QA-03, DA-03, AC-07, QA-05, QA-07, CL-02, CL-03, CL-04, CL-05, CL-06, CL-07.

---

### QA-05 — Дифференциальные тесты старой и новой логики

ID: [QA-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L8665). Приоритет: P1. Lua: упомянут (точный статус в источнике).

**Вердикт / статус**

**Вердикт**

**НЕ РЕАЛИЗОВАНО КАК ЕДИНЫЙ ДИФФЕРЕНЦИАЛЬНЫЙ МЕХАНИЗМ / P1 / QA-03 MOCK FOUNDATION EXISTS.** Kord имеет production v1 engine и отдельные Lua 5.1 contract mocks, но version-pinned парный replay, доказанный legacy baseline, oracle с классификацией MATCH/EXPECTED_DELTA/REGRESSION/INCONCLUSIVE и машинный отчёт по всем обязательным сценариям не подтверждены. Источниковый аудит — PASS на перечисленных путях; полный повторный построчный аудит всех семи ZIP — **NOT RUN**; Lua 5.1/CI/WoW Forever в рамках QA-05 — **NOT RUN**. CLIENT PASS для v14 остаётся 0/101.

**Архитектурные ссылки:** QA-01, QA-02, QA-03, QA-04, EN-A2, EN-A3, AC-07, DA-08, EN-A1, EN-A7, UI-05, UI-06, UI-08, `docs/rotation/Profile_Contract.md`, `docs/rotation/Canonical_API_Matrix.md`, `docs/rotation/Test_Matrix.md`, `tests/profile_contract_v1.lua`. **Ретроактивные уточнения добавлены в QA-01, QA-02, QA-03, QA-04, EN-A2, EN-A3, AC-07, DA-08.** QA-05 обобщает только тестовую инфраструктуру QA-03; не заменяет production providers, движок или матрицу QA-04.

**Изменения Lua:** отсутствуют. Только документация.

**Ретроактивное уточнение QA-06:** QA-06: парный differential replay обязан сначала проверять candidate profile static purity; legacy violations записываются как известные отклонения, а не переносятся в новый runtime ради MATCH. Статическая проверка не исполняет профили.

**Ретроактивное уточнение QA-07:** QA-07 — канонический источник проверенных ожидаемых решений для candidate в дифференциальных тестах. Legacy output остаётся свидетельством, а не oracle; QA-05 привязывает каждое сравнение к `scenarioID` и approved expectation.

**Выбранный путь Kord**

**Выбранный путь Kord**

**Единый офлайн `DifferentialRegressionHarness` как надстройка к QA-03 Lua 5.1 mock harness и общему tests manifest, с парной загрузкой исторических production Lua в строго изолированные окружения.** Это **логический test-only контракт**, не обязательный новый runtime module и не второй игровой RotationEngine. Зафиксировать начальный legacy commit как immutable SHA и карту переносимых сценариев; воспроизводить один fixture в обеих версиях. Если исторический API/профиль несовместимы, применять только явный, версионированный **test-only input/output adapter**, сохраняющий различие unknown/false/secret и имеющий отдельные тесты; не добавлять runtime aliases в `KordRotation/`.

Каноническое решение по разнице принимает `DifferentialOracle` из утверждённого `Profile_Contract.md`, требований EN-A2/EN-A3, AC-07, `AbilityEligibility`, v14 и утверждённой матрицы приоритетов профиля. `legacyOutput` — evidence о прошлом поведении, **не** oracle безопасности. `MATCH` допустим только при выполнении новых инвариантов. `EXPECTED_DELTA` документируется по `approvedContractRef` и конкретному stage; любое новое ложное `READY`, пропущенный UNKNOWN или нарушение приоритетов даёт REGRESSION независимо от legacy. Недоступные/secret входы всегда fail-closed. Отдельные агрегаты для choice parity, safety parity, diagnostic parity, API read counts и UI channel parity; не сравнивать несущественные локализованные подписи, абсолютное время/адреса фреймов и порядок диагностических записей, не влияющий на семантику.

Взаимодействия: `EventBus` задаёт revisions и последовательности; `GameState`/`GameAPI` — единый safe input след; `RotationConditions` — lazy Needs; `AbilityEligibility` — единственный final READY; `RotationEngine` — результат текущего действия и routing; `CoreObservation`/`QA-02` — наблюдаемая трасса **без дополнительного повторного API чтения**; `QA-01` — opt-in независимость DevTools; `QA-04` — client evidence для неподтверждённых методов. Старый и новый engine запускаются отдельно в harness, никоим образом не одновременно в WoW.

**Требуемые изменения (полный текст)**

**Требуемые изменения**

1. Выбрать и записать **точный historical Kord legacy Git SHA** (предконтрактный engine) и актуальный candidate SHA; исключить плавающий `main` как baseline, сохранять source provenance, License и profile version.
2. Добавить QA-05 в единый tests manifest QA-03 и реализовать offline launcher Lua 5.1, запускающий pinned version-specific production modules в двух независимых окружениях с одинаковой последовательностью fixtures; не копировать алгоритмы в тестовые дублёры.
3. Ввести `DifferentialFixture` schema validator с безопасными typed observations, `UNKNOWN`, `nil`, ревизиями и bounds; запретить leaked GUIDs, player names, raw `secret`/protected и несогласованные timestamp.
4. Реализовать детерминированный replay fake clock и `EventBus`: `PLAYER_ENTERING_WORLD`, `PLAYER_TARGET_CHANGED`, `PLAYER_REGEN_DISABLED/ENABLED`, `SPELLS_CHANGED`, `SPELL_UPDATE_COOLDOWN`, `UPDATE_BINDINGS`, `ACTIONBAR_SLOT_CHANGED`, смены level/spec/talents и actionbar visibility. Проверять freshness snapshots и изменения revision.
5. Сравнивать `READY/BLOCKED/UNKNOWN`, `actionType`, реальный `spellID/itemID`, выбранный приоритет, rank, `reason/subreasons`, `channel`, `NOT_EVALUATED` и число обращений к API; отдельный expected-failure registry для устаревших unsafe решений.
6. Проверить `EN-A2/EN-A3`: first-match-wins, lazy `all/any`, short-circuit, одно чтение факта за оценку, отсутствие исполнения нижних правил после READY/UNKNOWN; отсутствие false-ready при скрытом `secret`.
7. Проверить `AC-07` и `AbilityEligibility`: legacy READY против нового UNKNOWN/STOP при неизвестном GCD/cooldown/range/target/charge/cast/resource, запрещённых `onUnknown="skip"`, отсутствии проверки максимального изученного ранга — только документированные `EXPECTED_DELTA`; неожиданное расширение READY — регрессия.
8. Провести paired scenarios: отсутствие/смена цели, friendly/enemy, дальняя/ближняя дистанция, dead target, buff/debuff present/absent/secret, incoming combat/out of combat, defensive/main routing, rank boundaries 1–59/60, pet exists/dead, items, AoE thresholds, burst/categories/config, actionbar paging/bindings/hidden-frame, профили verified/experimental/unregistered; неподдерживаемый action type отмечать `NOT_IMPLEMENTED`, не имитировать PASS.
9. Проверить независимость DevTools OFF/ON и QA-02 trace: включение записи не меняет `legacy/candidate` решение или API read counts; `AuditFull` — отдельный offline режим, а не эквивалент lazy runtime; полная запись `NOT_EVALUATED` без дополнительных чтений.
10. Формировать machine-readable differential report с SHA, version, runtime, fixture hashes, classification и `differencePaths`, агрегатами и ссылками на requirement/test IDs; gate `REGRESSION=0`, `unapproved EXPECTED_DELTA=0`, обязательные `INCONCLUSIVE=0`, явные `NOT_RUN`. Ручной GitHub Actions только перед совокупным QA по действующему правилу AGENTS, без auto-push; затем отдельное подтверждение в реальном WoW Forever на точном build, не считать mock PASS клиентским подтверждением.

**Причины диагностики QA-05:** `diff_baseline_missing`, `diff_fixture_invalid`, `diff_input_mismatch`, `diff_profile_incompatible`, `diff_unknown_preserved`, `diff_decision_changed`, `diff_priority_changed`, `diff_reason_changed`, `diff_channel_changed`, `diff_api_read_count_changed`, `diff_approved_expected_delta`, `diff_unapproved_delta`, `diff_safety_regression`, `diff_evidence_incomplete`, `diff_client_unverified`, `diff_runner_not_executed`. Это внутренние статические коды; raw protected values в reason и subreason запрещены.

**Тесты и диагностика**

в файле не указано

**Архитектурные и обратные ссылки:** NO-04, AC-07, QA-04, QA-03, QA-02, QA-01, DA-08, UI-05, UI-06, UI-08, QA-06, QA-07.

---

### QA-06 — Статическая проверка: профиль не обращается к игровым функциям

ID: [QA-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L8742). Приоритет: P1. Lua: упомянут (точный статус в источнике).

**Вердикт / статус**

**Вердикт**

**НЕ РЕАЛИЗОВАНО КАК ОБЯЗАТЕЛЬНЫЙ STATIC PURITY GATE / P1.** Контракт отсутствия прямого WoW API в профиле уже утверждён; runtime registry проверяет структуру, engine вызывает `when` под `pcall`, а Lua 5.1 runner проверяет синтаксис. Однако обязательный AST/scope/call-graph анализ всех подключённых production профилей и отрицательные обходные тесты в проверенных путях **не подтверждены**. Текущий исторический BM-файл нельзя считать мигрированным v1. **SOURCE AUDIT PASS; QA-06 CHECKER NOT IMPLEMENTED; LUA/CI/WOW FOREVER NOT RUN; CLIENT PASS=0/101.**

**Архитектурные ссылки:** EN-A1, EN-A2, EN-A3, EN-A7, AC-07, QA-01, QA-03, QA-04, QA-05, `docs/rotation/Profile_Contract.md`, `KordRotation/Core/RotationProfiles.lua`, `RotationConditions.lua`, `RotationEngine.lua`, `scripts/run_local_lua_regression.sh`. **Обратные ссылки внесены в EN-A1, EN-A2, EN-A3, EN-A7, AC-07, QA-01, QA-03, QA-05.** QA-06 использует общую тестовую инфраструктуру QA-03, но не заменяет runtime реестр, QA-04 или differential oracle QA-05.

**Изменения Lua:** отсутствуют. Только документация.

**Ретроактивное уточнение QA-07:** QA-07 сценарные fixtures проходят QA-06 purity gate для реальных profile source; отсутствие прямого API не доказывает правильности выбранного действия, поэтому QA-07 остаётся отдельным обязательным поведенческим gate.

**Выбранный путь Kord**

**Выбранный путь Kord**

**Один `ProfilePurityStaticChecker` — offline test-only gate поверх QA-03, до допуска любых production профилей, с Lua 5.1 AST + scope/call-graph analysis.** Это логический модуль в `scripts/`/`tests/`, **не** новый игровой provider и **не** второй engine. Проверка применяется ко всем реально подключённым `.toc` профилям, всем файлам `KordRotation/Profiles/**` и локальным helpers/closure dependencies; unreferenced/legacy файлы учитываются отдельно, чтобы их нельзя было случайно подключить без проверки. Положительный список разрешает pure Lua 5.1 и документированные `S` methods; любые игровые источники разрешены только в ядре, где проходят QA-04 v14.

Рекомендуемая архитектура: `ProfileSourceDiscovery` (полный manifest по `.toc` и профилям) → `Lua51Parser` (синтаксис, scope, symbols, alias resolution) → `ProfilePurityAnalyzer` (call graph, callbacks, global accesses, escapes) → `ProfileStaticAuditRecord` (path:line:column, evidence, deterministic status) → QA-03 common manifest и QA-05 preflight. Parser должен быть version-pinned; если внешняя библиотека отсутствует или не распознала синтаксис, **fail closed**, а не «сканирование прошло». Lua 5.1 runtime test с подменой опасных глобалов — дополнительный отрицательный тест, не замена AST.

Важное уточнение: `S:spellAvailable`/`S:spellFact` и `S:observe` разрешены лишь по контракту и declared `Needs`; доступ к `KR.GameAPI` или `KR.GameState` запрещён даже если такой код не вызывает прямой `Unit*`. Допустимость `S["method"]` зависит от статически проверенного literal method и контекста; вычисляемый ключ/alias с неизвестным происхождением — FAIL. Проверять транзитивные вызовы и upvalues. Статический анализ не должен выполнять код профиля или изменять его приоритеты.

**Требуемые изменения (полный текст)**

**Требуемые изменения**

1. Составить исчерпывающий `ProfileSourceManifest` из `KordRotation/Profiles/**`, `.toc` references и profile registration, с `ACTIVE_V1|LEGACY|UNREFERENCED|TEST_FIXTURE`; исключить скрытые/случайно подключённые файлы из PASS.
2. Реализовать offline Lua 5.1 lexer/parser AST с source positions и lexical scope; syntax error, parser missing и unsupported grammar дают FAIL/INCONCLUSIVE, а не silent skip.
3. Ввести allowlist pure Lua 5.1 и методов `S`; deny direct WoW globals, `C_*`, `_G`, `KR.GameAPI`, `GameState`, protected calls, динамическую загрузку и глобальные записи, включая обращения в table initializers и вложенных closures.
4. Реализовать transitive alias/upvalue/call-graph analysis для `local f=UnitHealth`, `local t=_G`, `KR["GameAPI"]`, computed keys, higher-order callbacks, local helpers и metatable-based escape; непроверяемые пути fail closed.
5. Проверить `when(S,cfg)` и весь граф достижимых helpers: нет доступа к raw snapshot/недекларированным `Needs`, `S` остаётся method-only, условия возвращают `true/false/nil` без side effects; финальный READY по-прежнему только `AbilityEligibility`.
6. Отделить historical `BM.Next(s,cfg)` и legacy profiles от активного v1: нельзя объявлять legacy PASS как v1 purity; случайное подключение legacy к runtime — FAIL.
7. Добавить детерминированные negative fixtures: direct `UnitHealth`, `C_Spell.IsSpellUsable`, `GetTime`, `_G["UnitAura"]`, alias, concatenated key, nested closure, local helper, callback escape, `loadstring`, `setfenv`, global assignment, `KR.GameAPI:Read`, `S` dynamic method, undeclared `Needs`.
8. Добавить positive fixtures: чистая локальная функция, shadowed local `UnitHealth`, pure `math.min`, `string`/table operations, комментарии и строки с API names, разрешённые `S:is`/`S:all`/`S:spellFact` с lazy closures; исключить false positives.
9. Интегрировать QA-06 в единый QA-03 Lua 5.1 manifest и QA-05 preflight; проверять все production профили при локальной сборке и ручном совокупном CI. При FAIL блокировать release/verified status; не менять игровые runtime модули или user ZIP ради проверки.
10. Формировать `ProfileStaticAuditRecord` с source SHA, profile/closure coverage, location, ruleID, callChain, severity и fail-closed status; добавить DevTools-only агрегат по запросу, не исполняющий анализ в бою. Принятие: 100% production source coverage, 0 forbidden paths, 0 unexplained INCONCLUSIVE, positive/negative fixture PASS, Lua 5.1 syntax PASS; отдельный WoW Forever QA и v14 CLIENT PASS не подменять.

**Причины диагностики QA-06:** `profile_static_parser_missing`, `profile_static_parse_error`, `profile_static_source_untracked`, `profile_static_legacy_active`, `profile_static_wow_global`, `profile_static_gameapi_bypass`, `profile_static_dynamic_global`, `profile_static_dynamic_load`, `profile_static_global_write`, `profile_static_alias_escape`, `profile_static_callback_escape`, `profile_static_undeclared_need`, `profile_static_raw_snapshot`, `profile_static_unresolved_call`, `profile_static_inconclusive`. Причины — статические machine-readable codes без пользовательских или protected значений.

**Тесты и диагностика**

в файле не указано

**Архитектурные и обратные ссылки:** NO-04, NO-03, NO-02, NO-01, QA-03, QA-04, QA-05, AC-07, QA-01, QA-07.

---

### QA-07 — Сценарные таблицы «состояние → ожидаемое действие» для каждого профиля

ID: [QA-07](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L8820). Приоритет: P0. Lua: упомянут (точный статус в источнике).

**Вердикт / статус**

**Вердикт**

**ЧАСТИЧНО НА УРОВНЕ РЕЕСТРОВ / ОБЯЗАТЕЛЬНЫЕ СЦЕНАРНЫЕ ТАБЛИЦЫ ДЛЯ КАЖДОГО ПРОФИЛЯ НЕ РЕАЛИЗОВАНЫ / P0.** Существуют `Test_Matrix.md`, `Profile_Registry.md`, `Priority_Matrix.md` и core mock-тесты, но нет доказанного полного исполняемого `ScenarioCase` набора на **каждый** профиль, покрытия всех его правил и утверждённых точных ожиданий. Шесть Hunter PvE файлов — исторические, не зарегистрированы в TOC, игровая проверка отсутствует. В текущем проходе **SOURCE/DOC AUDIT PASS**, **SCENARIO RUNNER NOT IMPLEMENTED**, **LUA 5.1 NOT RUN**, **CI NOT RUN**, **WOW FOREVER NOT RUN**, **CLIENT PASS 0/101**.

**Архитектурные ссылки:** QA-03, QA-04, QA-05, QA-06, EN-A1, EN-A2, EN-A3, AC-07, DA-08, UI-01, `docs/rotation/Test_Matrix.md`, `Profile_Registry.md`, `Priority_Matrix.md`, `Profile_Contract.md`, `Ability_Catalogue.md`, `GameData_Contract.md`. **Ретроактивные уточнения добавлены в QA-03, QA-04, QA-05, QA-06, EN-A1, EN-A2, EN-A3, AC-07, DA-08, UI-01.**

**Изменения Lua:** отсутствуют. Только документация.

**Ретроактивное уточнение CL-01:** CL-01: обязательный Warrior-specific scenario manifest для стоек, rage, queued-next-swing, shout, execute threshold, Charge/Intercept и interrupt, с точными expected actions только после утверждения данных.

**Ретроактивное уточнение CL-02:** CL-02: отдельный Paladin scenario manifest обязателен для seal→Judgement→reseal, aura switch, blessing target, Hand conflicts, Divine Shield, Consecration mana reserve, dead-friendly resurrection, poison/disease dispel.

**Ретроактивное уточнение CL-03:** CL-03: отдельные сценарии Hunter для аспектов, trap shared CD, pet state/commands/heal/revive/happiness, ammo, ranged swing/clipping, dead zone, Hunter's Mark, Feign Death и main/defensive routing.

**Ретроактивное уточнение CL-04:** CL-04: каждый Rogue профиль обязан иметь scenarios combo points target binding, finisher, stealth, poison MH/OH, energy ticks, Kick/Gouge, Vanish/Evasion/Feint и cast disruption.

**Ретроактивное уточнение CL-05:** CL-05: сценарии Priest Shadowform, Power Word: Shield/Weakened Soul, DoT/mana, wand Shoot, party heal, friendly/hostile dispel, Resurrection и group buffs обязательны для каждого реального профиля.

**Ретроактивное уточнение CL-06:** CL-06: Shaman scenario manifest обязателен для totem slots/expiry/range, shock shared CD, weapon imbue MH/OH, poison/disease dispel, Ancestral Spirit и Reincarnation.

**Ретроактивное уточнение CL-07:** CL-07: добавить Mage scenarios mana reserve, armor/intellect coverage, Polymorph protection, freeze/root, conjure food/water, Mana Gem, Evocation и unresolved spell aliases.

**Выбранный путь Kord**

**Выбранный путь Kord**

**Единый `ProfileScenarioMatrix` (данные/контракт) и `ScenarioRunner` поверх общего QA-03 Lua 5.1 harness**; `Test_Matrix.md` остаётся человекочитаемым реестром, а machine-readable fixtures являются **единственным исполняемым источником** конкретных expected outcomes. Между реестром и fixtures — обязательная двусторонняя проверка ID/версии/expected/reason, запрещающая расхождение документов. Никакого второго игрового engine, отдельной логики выбора действий или копии profile rules в тестовом runner. Runner вызывает настоящие `RotationProfiles/RotationEngine/RotationConditions/AbilityEligibility` с контролируемыми safe provider mocks и fake clock; профили должны быть реальными version-pinned production Lua. `ProfileSourceManifest` QA-06 обеспечивает точный инвентарь и purity gate; QA-05 использует QA-07 как oracle, но не наоборот.

Для каждого профиля формировать собственный coverage manifest с обязательными измерениями: каждое правило/ветка и skip/UNKNOWN, каждая категория действия и режим, 1/59/60 границы, solo/dungeon/raid, pull/combat/OOC, enemy/friendly/dead/no target, range/melee/dead-zone, ресурс/GCD/cooldown/charges/rank, ауры/дебафы present/absent/expiring/UNKNOWN, pet/no pet/dead/low HP, AoE count 0/1/N/threshold/CC, defensive/main routing, buffs/consumables, config flags и конфликтующие настройки, talent/spec/binding/actionbar changes, spell not learned, secret/invalid observations, lazy read counts, stale revision. **Применимость определяется реальными Needs/Rules профиля**, а неприменимые измерения помечаются `N/A` с доказанной причиной, не «пропускаются». Для несуществующего/неподключённого профиля — `NOT_IMPLEMENTED/NOT_RUN`, а не фиктивная пустая матрица.

**Требуемые изменения (полный текст)**

**Требуемые изменения**

1. Создать `ProfileScenarioMatrix`/schema `ScenarioCase` и реестр `scenarioID` с профилем, версией, source SHA, evidence, приоритетом, входами, ожидаемым действием, reason/channel, test status; запретить дубли ID и неопределённые expected.
2. Связать каждую строку `docs/rotation/Priority_Matrix.md` с хотя бы одним `scenarioID` для true/false/UNKNOWN, boundary и следующего приоритета; нерешённые `TODO` — `SPEC_GAP` и блокируют готовность профиля.
3. Инвентаризировать `Profile_Registry.md` и `KordRotation/Profiles/**`: для шести Hunter PvE — отдельные coverage manifests, legacy status и конкретные gaps; другие классы/спеки не объявлять существующими. PvP — только отдельные ID после реального создания.
4. Разработать deterministic fixtures с typed observations, fake clock, events/revisions, config, target/pet/aura/resource/range, подтверждёнными spellID/ranks, с `nil/UNKNOWN` и fail-closed secret. Синтетические spellID допускаются только для контрактных core-тестов и явно помечаются.
5. Реализовать `ScenarioRunner` как QA-03 suite, исполняющий **настоящие** production modules/profile callbacks и сравнивающий `status/actionType/spellID/rank/priority/channel/reason/NOT_EVALUATED/readCounts` без повторной реализации ротации.
6. Добавить scenario coverage checker: 100% зарегистрированных/активных профилей и 100% их правил/достижимых ветвей; каждый обязательный контекст покрыт или доказательно `N/A`; отдельно `SPEC_GAP`, `NOT_RUN`, `BLOCKED_BY_CAPABILITY`, `FAIL`.
7. Обязательные negative/boundary suites: `UNKNOWN→STOP`, Eligibility UNKNOWN, first-match-wins, lazy all/any, no target/dead/friendly, неверный ранг, неполный ресурс, невалидный CFG, скрытая панель, смена level/spec/target, пет, AoE и ломаемый контроль, buffs и защитные действия.
8. Добавить двухканальные scenarios для `EvaluateBoth`: main и defensive с одним snapshot, отсутствие ложного переноса ауры в main, настройка `defensiveInCombatMain`, independent UNKNOWN и отсутствие повторных API reads; UI outcome отдельно от engine recommendation.
9. Встроить QA-06 static purity preflight и QA-05 differential replay: candidate expected action берётся из утверждённого QA-07 oracle; старое unsafe решение отмечается `EXPECTED_DELTA`, но не заменяет expected. Все несовпадения трассируются по `scenarioID`.
10. Реализовать machine-readable report и документальный sync `Test_Matrix.md`/fixtures; gate профиля: `FAIL=0`, `SPEC_GAP=0` для обязательных сценариев, `NOT_RUN=0`, `BLOCKED_BY_CAPABILITY=0` для заявленных возможностей, полное покрытие; `MOCK PASS` отдельно от `WoW Forever CLIENT PASS`. GitHub Actions — только ручной совокупный запуск согласно AGENTS.

**Причины диагностики QA-07:** `scenario_profile_missing`, `scenario_profile_version_mismatch`, `scenario_source_hash_mismatch`, `scenario_fixture_invalid`, `scenario_expected_missing`, `scenario_oracle_unapproved`, `scenario_spec_gap`, `scenario_action_mismatch`, `scenario_priority_mismatch`, `scenario_reason_mismatch`, `scenario_channel_mismatch`, `scenario_lazy_violation`, `scenario_unknown_unsafe_ready`, `scenario_api_read_mismatch`, `scenario_revision_stale`, `scenario_coverage_missing`, `scenario_not_run`, `scenario_client_unverified`. Статические reason codes без protected payload.

**Тесты и диагностика**

в файле не указано

**Архитектурные и обратные ссылки:** NO-06, NO-05, NO-04, NO-03, CL-09, CL-08, AC-06, CORE-LAZY-004, CORE-001, QA-03, QA-05, QA-06, QA-04, AC-07, DA-08, UI-01, CL-01, CL-02, CL-03, CL-04, CL-05, CL-06, CL-07.

---

