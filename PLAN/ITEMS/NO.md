# Карточки NO

Источник: REQUIREMENTS.md, blob 9efdec1900398c978ea121818fb5950cb1620337.

### NO-01 — Запрещено нажимать кнопки, выполнять макросы, менять цель и двигать персонажа

ID: [NO-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9941). Приоритет: P0. Lua: упомянут (точный статус в источнике).

**Вердикт / статус**

**Вердикт**

**ЧАСТИЧНО ПОДТВЕРЖДЕНО ПО ПРОСМОТРЕННЫМ ИСХОДНИКАМ / ПОЛНАЯ НЕГАТИВНАЯ ГАРАНТИЯ НЕ ПРОВЕРЕНА / P0.** Просмотренные `GameAPI`, `RotationEngine`, `BindingResolver`, `AbilityEligibility` ориентированы на read-only рекомендации; полный source audit всех Lua/XML/ZIP, запрет через динамические алиасы, mocks и WoW Forever не выполнены. **SOURCE/DOC AUDIT PASS; FULL STATIC SCAN NOT RUN; LUA 5.1 NOT RUN; CI NOT RUN; WOW FOREVER NOT RUN; CLIENT PASS 0/101.** Lua/TOC/ZIP не менялись.

**Ретроактивные ссылки:** AC-02, AC-03, AC-04, AC-05, EN-A1, QA-06, UI-01; они дополнены ссылкой на NO-01 в этом же коммите. Дополнительно связаны AC-07, CL-01–09, но классовые требования не переписываются: NO-01 действует глобально независимо от локальной ссылки.

**Выбранный путь Kord**

**Выбранный путь Kord**

**Один общий `RecommendationOnlyBoundary` / `NO_EXECUTION` invariant** на уровнях `GameAPI` allowlist, `Profile_Contract`, `RotationEngine`, `AbilityEligibility`, UI и DevTools. Это нормативный запрет, **не требование создавать новый runtime модуль**. В профилях — чистые `Needs`/`Rules`; в движке — данные `actionType`, `spellID`, `itemID`, `targetHint`, `keybind`, `reason`, `status`, `revision`; в UI — только показ и подсветка, без secure-action surface. `TARGET` из AC-04 означает совет о выборе цели, а не `TargetUnit`; `PET_COMMAND` из AC-03 — рекомендация команды, а не `PetAttack`; `STANCE_OR_FORM` из AC-05 — совет о смене облика, а не `CastShapeshiftForm`.

Не использовать `issecretvalue` или Blizzard protected restrictions как единственный механизм защиты: даже если действие технически доступно в конкретной версии/вне боя, NO-01 запрещает его **по продуктовой политике**. `UNKNOWN`/secret нельзя обходить выполнением действия «для проверки». Разрешённая диагностика — журналирование `would_recommend`, `would_block`, `reason`, а не `would_execute` с фактическим выполнением.

**Требуемые изменения (полный текст)**

**Требуемые изменения и приёмка**

1. Добавить QA-06 статический **denylist + semantic review** для всех `KordRotation/**/*.lua` и `KordRotationDevTools/**/*.lua`, включая вызовы через aliases, `_G`, `loadstring`, `RunScript`, `secure` templates, event callbacks, macro text, synthetic clicks, bindings и сторонние библиотеки; совпадение строки в комментарии/локализации не считать исполнением.
2. Проверить `GameAPI` allowlist, все API adapters, `RotationEngine`, `AbilityEligibility`, `BindingResolver`, UI callbacks, action highlights и DevTools: ни одна ветвь `READY` не должна иметь executable path.
3. Для всех типов AC-01–AC-07 закрепить typed output `recommendationOnly=true`; новый actionType отклонять без версионирования EN-A1 и доказанного read-only UI.
4. В Lua 5.1 mocks подменить каждый запрещённый API spy/stub, который при вызове немедленно проваливает тест; проверить `READY`, `BLOCKED`, `UNKNOWN`, target change, form/pet/item, combat/OOC, hardware-click UI callbacks, event storms.
5. Проверить отсутствие макросов/создаваемых macro buttons/secure action bindings в `.toc`, XML, Lua, packaged ZIP и зависимостях; сравнить user/dev каноническое ядро побайтово.
6. При клиентской приёмке на Forever отдельно подтвердить, что пользователь сам нажимает штатную кнопку, а Kord не меняет цель/позицию, не кастует, не исполняет макросы и не создаёт игровые bindings. **Не проводить запрещённые действия ради тестирования в реальном бою** — тестировать негативные гарантии безопасными mocks/инструментами.

**DevTools-only причины:** `no01_execution_api_denied`, `no01_macro_execution_denied`, `no01_target_mutation_denied`, `no01_movement_denied`, `no01_secure_click_denied`, `no01_binding_mutation_denied`, `no01_pet_execution_denied`, `no01_action_contract_invalid`, `no01_dynamic_dispatch_unverified`, `no01_ui_click_action_forbidden`.

**Тесты и диагностика**

**QA-07: сценарии «состояние → ожидаемое действие» (SPECIFIED / NOT RUN)**

| ID | Сценарий | Ожидаемый результат |
|---|---|---|
| `NO01-01` | Spell READY | recommendation emitted, cast spy calls 0 |
| `NO01-02` | Item READY | ITEM icon, item-use spy calls 0 |
| `NO01-03` | PET_COMMAND READY | advice only, pet command spy calls 0 |
| `NO01-04` | STANCE_OR_FORM READY | advice only, form/cancel spy calls 0 |
| `NO01-05` | TARGET suggestion | no target/focus/raid marker mutation |
| `NO01-06` | WAIT/STOP | no gameplay side effects |
| `NO01-07` | combat=false, spell usable | still no cast |
| `NO01-08` | click Kord UI recommendation | no secure gameplay action |
| `NO01-09` | event storm/OnUpdate | no action/macro/movement |
| `NO01-10` | alias `_G[name]` to prohibited API | static/dynamic test FAIL |
| `NO01-11` | RunMacroText or `/click` bridge | static/dynamic test FAIL |
| `NO01-12` | synthetic click / SetBindingClick | static/dynamic test FAIL |
| `NO01-13` | UI drag/scale Kord own frame | allowed, no player movement |
| `NO01-14` | DevTools probes | read-only, forbidden spy calls 0 |
| `NO01-15` | user/dev ZIP canonical files | byte-identical, no executor |
| `NO01-16` | secret/UNKNOWN gameplay state | STOP, never execute for discovery |

**QA статус:** сценарии документированы, **не запускались**. Статическая проверка отдельных файлов не заменяет полное сканирование двух пакетов, mocks и клиентскую приёмку.

**Архитектурные и обратные ссылки:** NO-04, NO-03, NO-02, AC-04, AC-02, AC-03, AC-05, QA-06, AC-01, AC-07, QA-07, UI-01, CL-01.

---

### NO-02 — Запрещено читать скрытые значения в бою и подставлять догадки вместо nil

ID: [NO-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L10035). Приоритет: P0. Lua: упомянут (точный статус в источнике).

**Вердикт / статус**

**Вердикт**

**ЧАСТИЧНО ПО ИСХОДНИКАМ / SECRET И NIL SAFETY НЕ ДОКАЗАНЫ ПОЛНОСТЬЮ / P0.** GameAPI имеет fail-closed read contract, но отсутствие probes и nested secret требуют проверки. **SOURCE/DOC AUDIT PASS; FULL STATIC SCAN NOT RUN; LUA 5.1 NOT RUN; CI NOT RUN; WOW FOREVER NOT RUN; CLIENT PASS 0/101.** Lua/TOC/ZIP не менялись.

**Ретроактивные ссылки:** NO-01, AC-07, QA-04, QA-06, DA-02, EN-A3, AU-01, PL-01, UI-01; обновлены в том же коммите.

**Выбранный путь Kord**

**Выбранный путь Kord**

**Один общий `SafeObservation` contract** поверх GameAPI/GameState/RotationConditions, не второй secret engine: `{status,value?,source,reason,observedAt?,revision?,capability?}`; value только при READY. `secret_detected`, `secret_probe_unavailable`, `api_no_value`, `api_call_failed`, `unexpected_type`, `stale_revision` различаются. `AbilityEligibility` — единственный финальный READY; `DA-02` не сохраняет stale READY; `EN-A3` lazy all/any не читает последующие данные после доказанного результата; `QA-04` проверяет конкретный Forever build. `nil` как подтверждённое отсутствие объекта допускается только при известной и доказанной API семантике.

**Требуемые изменения (полный текст)**

**Требуемые изменения**

1. Проверить отсутствие secret probes, вложенные таблицы, `ReadTuple`, `LuaCurveEvaluatedResult` и per-API capabilities в GameAPI; никакого `pcall` как обхода.
2. Статически проверять опасные `or 0`/`or false`/`not value`/`tostring(secret)`/`table[secret]` в gameplay paths, отделяя легальные UI defaults.
3. Провести UNKNOWN propagation через GameState → S → Engine → AbilityEligibility → UI/DevTools, без `READY`/false/0 по умолчанию.
4. Добавить Lua 5.1 negative mocks: отсутствующие probes, secret values/tables, inaccessible values, nil, errors, stale revisions, nested aura, curve, log payload.
5. Проверить v14 API secret flags и допустимые операции на WoW Forever; не объявлять Curve→numeric 5%-band без доказательства.
6. Логировать только `status/source/reason/revision/capability`, не secret payload; запретить его сохранение в SavedVariables.
7. Регрессия всех классов и AC-01–07: secret HP/resource/aura/range/TTD/target не дают READY; сохранить NO-01.

**DevTools-only причины:** `no02_secret_detected`, `no02_secret_table`, `no02_secret_probe_unavailable`, `no02_secret_access_denied`, `no02_api_no_value`, `no02_api_call_failed`, `no02_unexpected_type`, `no02_curve_not_numeric`, `no02_aura_field_restricted`, `no02_unknown_not_absent`, `no02_stale_revision`, `no02_fallback_guess_forbidden`, `no02_secret_log_denied`.

**Тесты и диагностика**

**QA-07: сценарии «состояние → ожидаемое действие» (SPECIFIED / NOT RUN)**

| ID | Состояние | Ожидаемый результат |
|---|---|---|
| `NO02-01` | issecretvalue=true | UNKNOWN, no formatting |
| `NO02-02` | issecrettable=true | UNKNOWN, no field access |
| `NO02-03` | canaccessvalue=false | UNKNOWN, no unwrap |
| `NO02-04` | probes missing, sensitive API | capability UNKNOWN |
| `NO02-05` | UnitHealth=nil | UNKNOWN, not HP=0 |
| `NO02-06` | UnitPower=nil | UNKNOWN, not resource=0 |
| `NO02-07` | percent Curve not numeric | UNKNOWN, no invented band |
| `NO02-08` | secret AuraData | UNKNOWN, not aura absent |
| `NO02-09` | secret auraInstanceID | no table key |
| `NO02-10` | secret expirationTime | UNKNOWN, no guessed refresh |
| `NO02-11` | ambiguous UnitCastingInfo nil | UNKNOWN, not idle |
| `NO02-12` | contract-proven nil=absent | explicit ABSENT allowed |
| `NO02-13` | API error in pcall | ERROR, not false |
| `NO02-14` | secret targetGUID | no stale owner inference |
| `NO02-15` | stale health cache | UNKNOWN, no old READY |
| `NO02-16` | S:all first false | skip second secret read |
| `NO02-17` | S:any first true | skip second secret read |
| `NO02-18` | required fact UNKNOWN | AC-07 STOP |
| `NO02-19` | secret range | no Eligibility READY |
| `NO02-20` | secret aura in DevTools | log reason, no payload |
| `NO02-21` | unknown next action | no fabricated UI icon |
| `NO02-22` | out of combat secret | UNKNOWN |
| `NO02-23` | combat readable value | typed READY only if verified |
| `NO02-24` | UI config nil | validated default allowed |
| `NO02-25` | unverified nil UnitExists | UNKNOWN, not absent |
| `NO02-26` | secretunwrap proposed | reject unsupported API |

**QA статус:** это спецификация, тесты не запускались; требуется Lua 5.1 mock и клиентский QA.

**Архитектурные и обратные ссылки:** NO-06, NO-05, NO-04, NO-03, NO-01, AC-07, DA-02, QA-04, AC-01, QA-07, QA-06, AU-01, PL-01, UI-01.

---

### NO-03 — Запрещено хранить в журнале произвольные данные игрока, цели и чат

ID: [NO-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L10139). Приоритет: P0. Lua: упомянут (точный статус в источнике).

**Вердикт / статус**

**Вердикт**

**ЧАСТИЧНО ПОДТВЕРЖДЕНО ПО ПРОСМОТРЕННЫМ ИСХОДНИКАМ / ПОЛНАЯ ГАРАНТИЯ ПРИВАТНОСТИ ЖУРНАЛА НЕ ДОКАЗАНА / P0.** Recorder уже использует ограниченные scalar поля, opt-in, фиксированные причины и сегменты; `METHOD.detail`, `ReadField`, legacy SavedVariables, общий byte budget и непрямые вызовы требуют отдельного тестирования. **SOURCE/DOC AUDIT PASS; FULL STATIC SCAN NOT RUN; LUA 5.1 NOT RUN; CI NOT RUN; WOW FOREVER NOT RUN; CLIENT PASS 0/101.** Lua/TOC/ZIP не менялись.

**Ретроактивные ссылки:** NO-01, NO-02, QA-04, QA-06, QA-07, DA-02, DA-08, UI-01 — дополнены ссылкой на NO-03 в том же коммите.

**Выбранный путь Kord**

**Выбранный путь Kord**

**Единый `DiagnosticRecordSchema` + `DiagnosticPrivacyBoundary` в существующем DevTools Recorder/GameAPI trace**, без второго logger. Проверять значения **до** сохранения, агрегирования, форматирования и экспорта; только immutable allowlist и ограниченные числа. Любой неизвестный метод/причина/деталь → `unmapped`, счётчик rejected/dropped; не удерживать исходное значение даже временно в таблице очереди. `method` привязан к известному GameAPI allowlist, `reason` к фиксированному словарю; `ReadField` — только подтверждённый внутренний field key registry. `sessionID` — локальный порядковый номер, не GUID. Экспорт только по ручному действию, без автоотправки; старые записи повторно санитизировать при чтении. Ограничивать размер по **записям и байтам**, общую ёмкость сегментов и срок хранения; при переполнении показывать dropped/evicted count, не наращивать без ограничения.

**Требуемые изменения (полный текст)**

**Требуемые изменения и приёмка**

1. Аудировать `GameAPI` trace, `Recorder`, `Trace`, `Probe`, `Performance`, `UI`, `Diagnostics`, все мосты/колбэки на raw payload, `CHAT_MSG_*`, `COMBAT_LOG_EVENT_UNFILTERED`, `UnitName`, `UnitGUID`, `debugstack`, `tostring(err)`, `SavedVariables` и `SendAddonMessage`; учитывать алиасы и непрямые вызовы.
2. Сделать closed vocabulary для `METHOD.detail` и `ReadField` names, без одной лишь regex-валидации; сохранить расширяемость через versioned внутренний registry.
3. Добавить единый schema validator на входе `Record`, перед `SaveJournalPart` и при `Export` для legacy/malformed SavedVariables; неизвестные поля и записи отбрасывать без печати.
4. Установить суммарный лимит байтов и частей на все `sessions` и retention policy, проверить segment rollover, eviction, overflow и large counters.
5. Убедиться, что user ZIP не содержит DevTools recorder/trace/diagnostic SavedVariables; dev ZIP сохраняет побайтовую идентичность `KordRotation/`.
6. Добавить Lua 5.1 negative mocks и privacy fixtures: names, GUIDs, whisper/chat, combat log payload, secret nested tables, error strings, fake method names, malicious SavedVariables, overlong UTF-8, unknown reasons, mixed target change.
7. В клиенте Forever подтвердить ручной Start/Stop/Clear/Export, отсутствие автоактивации, безопасный journal при combat/reload/logout и no chat capture. Ни одна QA проверка не должна логировать реальные личные данные ради теста.

**DevTools-only причины:** `no03_payload_rejected`, `no03_unknown_method`, `no03_unknown_reason`, `no03_unknown_detail`, `no03_chat_payload_denied`, `no03_unit_identifier_denied`, `no03_secret_payload_denied`, `no03_legacy_record_rejected`, `no03_storage_limit`, `no03_export_schema_invalid`, `no03_session_not_opted_in`.

**Тесты и диагностика**

**QA-07: сценарии «состояние → ожидаемое действие» (SPECIFIED / NOT RUN)**

| ID | Сценарий | Ожидаемый результат |
|---|---|---|
| `NO03-01` | Recorder не запущен | нет записей |
| `NO03-02` | Явный Start | только разрешённая схема |
| `NO03-03` | Player name | rejected, не сохранять |
| `NO03-04` | Target GUID | rejected, не сохранять |
| `NO03-05` | Party/pet name | rejected, не сохранять |
| `NO03-06` | CHAT_MSG_WHISPER payload | не подписываться/не сохранять |
| `NO03-07` | CHAT_MSG_GUILD payload | не сохранять |
| `NO03-08` | COMBAT_LOG raw args | не сохранять |
| `NO03-09` | Raw AuraData | не сохранять |
| `NO03-10` | Secret nested table | не индексировать/не сохранять |
| `NO03-11` | Raw pcall error string | только fixed reason |
| `NO03-12` | Unknown reason | unmapped, без оригинала |
| `NO03-13` | Regex-valid fake METHOD detail | rejected без allowlist |
| `NO03-14` | Regex-valid fake ReadField key | rejected без registry |
| `NO03-15` | Numeric overflow | reject/clamp по контракту |
| `NO03-16` | 512 записей | segment rollover, bounded |
| `NO03-17` | Превышение общего byte budget | eviction/dropped |
| `NO03-18` | SavedVariables с raw GUID legacy | reject при чтении/экспорте |
| `NO03-19` | Старый record с неизвестным полем | не экспортировать |
| `NO03-20` | Reload | запись не возобновляется |
| `NO03-21` | Logout активного сеанса | безопасное завершение |
| `NO03-22` | Clear | sessions удалены |
| `NO03-23` | Manual paginated export | только schema fields |
| `NO03-24` | Автоотправка по addon message | запрещена |
| `NO03-25` | User ZIP | без DevTools journal |
| `NO03-26` | Dev ZIP | каноническое ядро byte-identical |
| `NO03-27` | Diagnostic method trace | только allowed method/status/reason/count |
| `NO03-28` | UI support snapshot | не записывать в journal |
| `NO03-29` | Unknown spell/target data | не превращать в raw trace |
| `NO03-30` | Target change storm | bounded counters, no GUID |

**QA статус:** 30 сценариев специфицированы, не исполнялись.

**Архитектурные и обратные ссылки:** NO-05, NO-04, NO-02, UTF-8, QA-07, NO-01, QA-04, QA-06, DA-02, DA-08, UI-01.

---

### NO-04 — Запрещено включать в пользовательскую сборку другую логику, чем в диагностической

ID: [NO-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L10248). Приоритет: P0. Lua: упомянут (точный статус в источнике).

**Вердикт / статус**

**Вердикт**

**P0 / SPECIFIED, НЕ ПРОВЕРЕН В ПОЛНОМ ОБЪЁМЕ; ИМЕЕТСЯ ИСХОДНИКОВЫЙ РИСК ПОВТОРНОЙ LIVE-ОЦЕНКИ.** Утверждён один общий пакет `KordRotation/`, а build script его дублирует побайтово. Но `CoreObservation.ReadEngineDiagnostic` запускает `Evaluate/EvaluateBoth`, `Trace.ObserveTransition` вызывает Diagnose по событиям и таймеру. Это доказывает второй вычислительный путь во время записи, **но не доказывает фактического изменения пользовательской рекомендации**. Следовательно, до переработки/изолированного теста выпуск не может быть признан прошедшим NO-04. **SOURCE/DOC AUDIT PASS; ZIP BUILD NOT RUN; FULL STATIC SCAN NOT RUN; LUA 5.1 NOT RUN; CI NOT RUN; WOW FOREVER NOT RUN; CLIENT PASS 0/101.** Lua/TOC/ZIP не менялись.

**Ретроактивные связи:** QA-01, QA-02, QA-03, QA-05, QA-06, QA-07, DA-02, UI-01, NO-01, NO-02, NO-03. В указанные разделы добавлены обратные ограничения; не вводится новый engine, заменяющий уже существующие контракты.

**Выбранный путь Kord**

**Выбранный путь Kord**

**Сохранить единственные действующие `KordRotation/` + `KordRotationDevTools/`, сборщик и существующий read-only `CoreObservation`; усилить его до пассивного захвата реальных результатов.** После завершения обычной live evaluation строить ограниченный immutable `DecisionObservationEnvelope(schemaVersion,evaluationID,channel,profileCode,revision,status,reason,priority,candidateCode,eligibility,checks,notEvaluated)`, используя только *уже рассчитанные* и проверенные данные, без нового World API read или engine Evaluate. Поля/коды должны согласовываться с QA-02, NO-03 (allowlist, no raw GUID/имён/чата/secret, bounded safe numbers). Простое чтение `CoreObservation:Read()` не должно обновлять GameState или lazy conditions. Если готового безопасного результата нет — `UNAVAILABLE/UNKNOWN`, но не искусственная «полная» оценка.

`Trace` читает envelope, не повторяет `RotationEngine:EvaluateBoth` ради reason. `AuditFull` допускается лишь в **явно изолированном offline/mock harness на frozen fixture**, не в live UI/onUpdate/event recording. `GameAPI` wrappers должны сохранять все return values, error semantics, UNKNOWN и event/cache invariants даже при переполнении/ошибке диагностической записи. DevTools работает только с ограниченным безопасным snapshot, не мутирует настройки, profile registry, queue, GameState или поведение UI; probes по явному действию маркируются отдельной экспериментальной выборкой без присвоения production verdict. Пределы CPU/memory измеряют отдельно от семантических полей и фиксируют до приёмки.

Это **новая ось differential**: user-vs-dev modes при фиксированном SHA и input; QA-05 уже сравнивает legacy-vs-candidate commit и здесь переиспользуется его deterministic harness, но никогда не вводится второй runtime engine.

**Требуемые изменения (полный текст)**

**Требуемые изменения**

1. На точном коммите запустить `scripts/build_variants.py` и перечислить ZIP entries: имена, byte length, SHA-256, полные bytes всех `KordRotation/`, отсутствие DevTools в user и посторонних core-дубликатов в dev. Сохранить manifest и SHA.
2. Проверить оба TOC, реально загружаемые Lua/XML, developer dependencies, overrides/monkey patching, conditional `_G` dispatch, debug-specific profiles, `KordRotationDB` writes в DevTools, hooks/callbacks и возможность переключения engine. Блокировать выпуск при доказанном runtime divergence.
3. Заменить live вызовы engine `CoreObservation.ReadEngineDiagnostic`/Trace `ObserveTransition` на чтение **уже рассчитанного** production envelope. Убрать реальный `AuditFull` из live paths; не нарушать lazy `Needs`.
4. Уточнить schema `DecisionObservationEnvelope` совместно с QA-02/NO-03, зафиксировать `NOT_EVALUATED` для непрочитанных условий; отсутствие данных — `UNKNOWN`, не дополнительная проверка.
5. Изолировать logging wrapper: любое исключение `Recorder`, overflow/Stop/Export, missing bridge не меняет return/error contract оригинального GameAPI вызова и не ломает engine/UI.
6. Lua 5.1 mode-differential fixtures: сравнивать одну и ту же последовательность событий, профиль, конфигурацию, snapshots в режимах user / dev OFF / dev RECORDING / dev STOP / export. Отдельно проверить main/defensive и `READY/BLOCKED/UNKNOWN`.
7. Сравнить кроме decision fields источники/ревизии, lazy rule order, cache invalidation, число canonical API reads; **manual probes исключить из парного теста**, диагностические counters не приравнивать к gameplay changes.
8. Проверить fail-isolation при secret/nil, malformed envelope, recorder overflow, exception, /reload, ошибочном stop, отсутствующей зависимости; NO-02 fail-closed, NO-03 privacy в обоих режимах.
9. Дополнить QA-03/QA-07/QA-05 и локальные scripts для release gate, сохранить результаты/fixture hashes/build SHA; performance сравнить с заранее установленными tolerances. CI запускать только вручную перед общим QA, согласно AGENTS.md.
10. Release gate: при хотя бы одном различии общего ZIP, recommendation/priority/reason, или повторном `Evaluate`/`AuditFull` из live DevTools **блокировать пользовательскую поставку**. Не объявлять PASS при незапущенных тестах.

**DevTools-only коды причин (спецификация, не реализованный список):** `no04_core_hash_mismatch`, `no04_shared_entry_missing`, `no04_devtools_in_user_zip`, `no04_runtime_override_detected`, `no04_live_diagnostic_reevaluation`, `no04_decision_mismatch`, `no04_reason_mismatch`, `no04_revision_mutated`, `no04_cache_pollution`, `no04_probe_interference`, `no04_trace_exception`, `no04_trace_overflow`, `no04_missing_bridge`, `no04_untrusted_envelope`, `no04_perf_budget_exceeded`.

**Тесты и диагностика**

**QA-07: сценарии «состояние → ожидаемое действие» (SPECIFIED / NOT RUN)**

| ID | Сценарий | Ожидаемый результат |
|---|---|---|
| `NO04-01` | user vs dev ZIP common entries | байты, имена, размеры, SHA равны |
| `NO04-02` | user ZIP | нет `KordRotationDevTools/` |
| `NO04-03` | dev TOC | отдельная зависимость от KordRotation |
| `NO04-04` | common TOC/profiles | один набор loaded rules |
| `NO04-05` | DevTools не установлен | исходная рекомендация |
| `NO04-06` | DevTools установлен, OFF | та же рекомендация |
| `NO04-07` | DevTools RECORDING | те же status/priority/reason |
| `NO04-08` | DevTools STOP/EXPORTED | то же решение |
| `NO04-09` | main READY | тот же candidate |
| `NO04-10` | defensive READY | тот же defensive candidate |
| `NO04-11` | condition UNKNOWN | одинаковый STOP |
| `NO04-12` | Eligibility UNKNOWN | READY не возникает |
| `NO04-13` | secret/protected input | UNKNOWN, не unwrap |
| `NO04-14` | nil/UNAVAILABLE API | одинаковый fail-closed |
| `NO04-15` | смена профиля/конфига | один resolve |
| `NO04-16` | binding/actionbar change | одинаковая подсветка/keybind |
| `NO04-17` | target/event storm | ревизии и выбор не расходятся |
| `NO04-18` | START/STOP trace wrapper | неизменные return/error |
| `NO04-19` | recorder overflow | не меняет engine |
| `NO04-20` | recorder throws | engine/UI устойчивы |
| `NO04-21` | missing bridge | user решение сохраняется |
| `NO04-22` | reload без opt-in | запись OFF, решение прежнее |
| `NO04-23` | получение decision envelope | не вызывает Evaluate повторно |
| `NO04-24` | diagnostic event/OnUpdate | нет дополнительных Evaluate |
| `NO04-25` | AuditFull в live callback | static/dynamic gate FAIL |
| `NO04-26` | manual presence ProbeAll | client verdict не изменён |
| `NO04-27` | record без raw GUID/name/chat | NO-03 pass |
| `NO04-28` | DevTools UI vs profile setting | production settings неизменны |
| `NO04-29` | overhead | в утверждённом CPU/memory budget |
| `NO04-30` | новый actionType | одинаковое отклонение/UNKNOWN |
| `NO04-31` | второй core/debug branch | static gate FAIL |
| `NO04-32` | exact-SHA full scenario replay | decision fields MATCH |
| `NO04-33` | запись выключена | нет retained raw data |
| `NO04-34` | повтор fixture | детерминированный MATCH |

**QA статус:** 34 сценария заданы, Lua 5.1/ZIP/game run в этом аудите NOT RUN.

**Архитектурные и обратные ссылки:** NO-06, NO-05, NO-02, SHA-256, QA-02, NO-03, QA-05, QA-03, QA-07, QA-01, QA-06, DA-02, UI-01, NO-01.

---

### NO-05 — Запрещено постоянно сканировать ауры и врагов без запроса профиля

ID: [NO-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L10367). Приоритет: P0. Lua: упомянут (точный статус в источнике).

**Вердикт / статус**

**Вердикт**

**P0 / ДОКУМЕНТИРОВАНО; РЕАЛИЗАЦИЯ ЧАСТИЧНА; END-TO-END НЕ ПОДТВЕРЖДЁН.** `Needs` allowlist, ленивое кэширование и event invalidation видны в исходниках. Условный bounded aura fallback реализован, но нет доказательства лимита суммарной стоимости на оценку, а `enemy.count` пока не реализован. Повторная live диагностика из NO-04 может добавлять demand-reads. **SOURCE/DOC AUDIT PASS; FULL STATIC SCAN NOT RUN; LUA 5.1 NOT RUN; CI NOT RUN; ZIP BUILD NOT RUN; WOW FOREVER NOT RUN; CLIENT PASS 0/101.** Это изменение только документации, не runtime.

**Ретроактивные связи:** DA-01/02/03, EN-01/02/03, QA-01/03/07, NO-02/03/04. В них добавлены обратные ограничения, не удалены прежние контракты.

**Выбранный путь Kord**

в файле не указано

**Требуемые изменения (полный текст)**

**План изменений / критерии приёмки**

1. Протрассировать все runtime вызовы `ReadSignal(player.buff,target.debuff,enemy.count)`, `GetUnitAuras`, `GetAuraDataByIndex`, `GetNamePlates` и подписчиков `EventBus`; построить call graph от UI, engine, DevTools, events и timers. Отличать address lookup от enumeration.
2. Статический gate: запрет перечисления аур/врагов из `OnUpdate`, heartbeat, event handlers, init/registration, DevTools без достигнутого условия. Разрешён только bounded, documented fallback для конкретного fact.
3. Проверить `Needs` как allowlist; отсутствие нужного `spellID` или `enemyCount` означает ноль соответствующих expensive API calls. Даже объявленный `Needs` при short-circuit означает ноль вызовов.
4. В одной evaluation кэшировать факт и UNKNOWN по `field+spellID+unit/target identity`; повтор не вызывает provider. При новой evaluation, target change, UNIT_AURA, spec/profile/config changes инвалидация по каналам; не смешивать разные GUID.
5. В aura provider: ID-first, затем safe name/viewer/evidence и только при подтверждённой доступности bounded batch/index; документировать максимумы **256/64** и контролировать совокупную стоимость для множества spellIDs. Если стоимость превышает бюджет — `UNKNOWN/budget_exceeded`, не false.
6. Для enemyCount до реализации EN-01/02/03 оставлять `UNKNOWN/signal_provider_unimplemented`. Будущий provider должен принимать требуемую семантику radius/engagement/dedup и запускаться лишь при реально достигнутом `enemy.count`; no guess=0.
7. Проверить main/defensive: общая уже подтверждённая информация может переиспользоваться, но независимость lane и отсутствие запросов для неисполненной ветки обязательны.
8. DevTools: устранить повторный live `Evaluate` (NO-04); trace наблюдает уже сформированный bounded result, не делает самостоятельные aura/enemy reads.
9. Добавить Lua 5.1 mock counters, negative tests и performance budget (max scans/indices/API calls на одну оценку и на единицу времени) до acceptance; тестировать burst `UNIT_AURA`, смену цели, secret, missing APIs, off-combat, профиль без `Needs`.
10. Release gate: любой scan без demand, недоказанный `READY(false)` или `enemy.count=0`, переполнение bounded budget, повторное live DevTools evaluation — FAIL. При незапущенных тестах — NOT RUN, не PROD PASS.

**DevTools-only коды причин (предложение, не существующая реализация):** `no05_scan_without_demand`, `no05_undeclared_aura`, `no05_undeclared_enemy_count`, `no05_eager_needs_preload`, `no05_short_circuit_violation`, `no05_duplicate_provider_read`, `no05_scan_budget_exceeded`, `no05_secret_enumeration_attempt`, `no05_stale_target_cache`, `no05_event_triggered_scan`, `no05_devtools_extra_scan`, `no05_enemy_count_unimplemented`, `no05_negative_aura_unverified`.

**Тесты и диагностика**

**QA-07: сценарии «состояние → ожидаемое действие» (SPECIFIED / NOT RUN)**

| ID | Вход / триггер | Ожидаемое действие |
|---|---|---|
| `NO05-01` | профиль без `Needs.auras` | ноль aura enumeration |
| `NO05-02` | профиль без `Needs.enemyCount` | ноль enemy scans |
| `NO05-03` | `Needs.auras` объявлен, правило не достигнуто | ноль aura reads |
| `NO05-04` | `Needs.enemyCount=true`, ветка не достигнута | ноль enemy reads |
| `NO05-05` | `all` short-circuit до aura | ноль aura reads |
| `NO05-06` | `any` short-circuit до enemy | ноль enemy reads |
| `NO05-07` | разрешён конкретный `spellID` | только нужный fact, ID-first |
| `NO05-08` | неразрешённый `spellID` | UNKNOWN без aura API |
| `NO05-09` | повтор одного aura fact в оценке | provider вызван один раз |
| `NO05-10` | повтор UNKNOWN fact | provider не вызывается второй раз |
| `NO05-11` | новая evaluation | безопасная новая проверка, без stale |
| `NO05-12` | `UNIT_AURA` | invalidate, без немедленного scan |
| `NO05-13` | burst 100 `UNIT_AURA` | bounded flush, без 100 scans |
| `NO05-14` | `PLAYER_TARGET_CHANGED` | invalidate target facts, без скана всех |
| `NO05-15` | target GUID меняется в ходе lookup | UNKNOWN, нет reuse |
| `NO05-16` | target GUID неизменен | корректный адресный lookup |
| `NO05-17` | direct ID hit | batch/index не вызываются |
| `NO05-18` | direct ID miss, secrecy true | UNKNOWN, нет enumeration |
| `NO05-19` | secrecy unknown + lockdown | UNKNOWN, нет enumeration |
| `NO05-20` | secrecy false, bounded batch | до 256, только по demand |
| `NO05-21` | batch sparse/protected | UNKNOWN, не false |
| `NO05-22` | index fallback | до 64, bounded UNKNOWN при лимите |
| `NO05-23` | множество `Needs.auras` | общий budget, нет бесконтрольного N×256 |
| `NO05-24` | enemy.count достигнут, provider отсутствует | UNKNOWN/unimplemented, не 0 |
| `NO05-25` | enemyCount не объявлен | никакого GetNamePlates |
| `NO05-26` | enemyCount будущий provider | проверены radius/engagement/GUID dedup |
| `NO05-27` | enemy source secret | UNKNOWN, не 0 |
| `NO05-28` | два источника одной цели | один подсчитанный GUID |
| `NO05-29` | main/defensive оба нуждаются в ауре | общий корректный факт без лишнего read |
| `NO05-30` | defensive не исполняется | нет его aura scans |
| `NO05-31` | no target / out-of-combat | нет скана врагов по умолчанию |
| `NO05-32` | `OnUpdate`/heartbeat без нужного правила | ноль aura/enemy enumeration |
| `NO05-33` | DevTools OFF/ON/RECORDING | нет дополнительных scans/evaluations |
| `NO05-34` | `AuditFull` из live diagnostic | запрещён NO-04 |
| `NO05-35` | profile/spec/config changed | корректная инвалидация разрешений |
| `NO05-36` | provider exception | UNKNOWN, нет runaway loop |
| `NO05-37` | per-evaluation scan budget exhausted | UNKNOWN, не READY(false) |
| `NO05-38` | user vs dev identical fixture | равные decisions и bounded read counts |
| `NO05-39` | API unsupported/nil | UNKNOWN, не false/0 |
| `NO05-40` | повтор deterministic fixture | тот же trace/count/status |

**QA статус:** 40 сценариев SPECIFIED; Lua 5.1, полный static scan, CI, сборка ZIP и WoW Forever **NOT RUN** в документальном проходе.

**Архитектурные и обратные ссылки:** NO-06, EN-01, NO-02, NO-04, QA-07, DA-01, QA-01.

---

### NO-06 — Запрещено считать расхождение источников ошибкой, если оно становится настройкой CFG

ID: [NO-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L10486). Приоритет: в файле не указано. Lua: упомянут (точный статус в источнике).

**Вердикт / статус**

в файле не указано

**Выбранный путь Kord**

в файле не указано

**Требуемые изменения (полный текст)**

в файле не указано

**Тесты и диагностика**

**QA-07: сценарии (SPECIFIED, NOT RUN)**

| ID | Вход | Ожидаемый результат |
|---|---|---|
| `NO06-01` | два безопасных приоритета заклинаний | классификация STRATEGY, CFG-кандидат |
| `NO06-02` | разные пороги обновления DoT | `number` с валидным min/max/default |
| `NO06-03` | три допустимых режима AoE | `enum` с именованными вариантами |
| `NO06-04` | необязательный self buff | `bool` только если не дублирует существующий |
| `NO06-05` | разница retail/Forever API | capability gate, не CFG |
| `NO06-06` | aura true против protected nil | UNKNOWN, не CFG |
| `NO06-07` | разные target GUID | UNKNOWN/invalid snapshot, не CFG |
| `NO06-08` | ошибка range | исправление, не CFG |
| `NO06-09` | ref делает protected cast | NO-01 FAIL, CFG запрещён |
| `NO06-10` | альтернативы эквивалентны | один адаптер, без лишнего CFG |
| `NO06-11` | стратегия не подтверждена Forever | OPEN/NOT VERIFIED |
| `NO06-12` | два профиля с одинаковым key | значения изолированы по profile.id |
| `NO06-13` | CFG default | идентичен UI и engine |
| `NO06-14` | сохранённый bool корректен | применён без изменения |
| `NO06-15` | сохранённый enum вне списка | default и диагностическая причина |
| `NO06-16` | сохранённый number ниже min | default |
| `NO06-17` | сохранённый number выше max | default |
| `NO06-18` | NaN/secret/nil config | default без чтения protected значения |
| `NO06-19` | профиль сменён | CFG нового профиля, без cross-profile leak |
| `NO06-20` | spec/level сменились | пересчёт schema и валидная миграция |
| `NO06-21` | переключение bool | изменяется только заявленная стратегия |
| `NO06-22` | переключение enum | каждый вариант имеет отдельный ожидаемый decision |
| `NO06-23` | числовой порог на границе | детерминированный branch |
| `NO06-24` | CFG изменён в бою | только разрешённая смена рекомендации, без автоматического действия |
| `NO06-25` | cfg с UNKNOWN game fact | UNKNOWN→STOP, не forced READY |
| `NO06-26` | cfg меняет eligibility | обязательная eligibility не обходится |
| `NO06-27` | main/defensive | одна нормализованная cfg |
| `NO06-28` | user/dev same fixture | равные cfg/decisions |
| `NO06-29` | DevTools ON/OFF | cfg и decision не меняются |
| `NO06-30` | новый CFG без ruRU | localization FAIL |
| `NO06-31` | новый CFG без любого из 6 языков | localization FAIL |
| `NO06-32` | enum option без tooltip | coverage FAIL |
| `NO06-33` | новая настройка без правила-потребителя | unreachable CFG FAIL |
| `NO06-34` | дублирование существующего CFG | reject duplicate |
| `NO06-35` | 129-й Config item | schema validation FAIL |
| `NO06-36` | enum более 32 значений | schema validation FAIL |
| `NO06-37` | новый CFG запускает scan без Needs | NO-05 FAIL |
| `NO06-38` | две стратегии и ни одна не подтверждена | OPEN, не фиктивный PASS |
| `NO06-39` | runtime variant без согласования | AGENTS rule #1 FAIL |
| `NO06-40` | решение ref divergence записано в журнал | только фиксированные коды, без player/chat data |
| `NO06-41` | переустановка/перезагрузка UI | сохранённое валидное значение не теряется |
| `NO06-42` | migration старого enum | корректный default и сохранение иных ключей |
| `NO06-43` | выключенный профиль | CFG не инициирует фоновые aura/enemy scans |
| `NO06-44` | одинаковый fixture, повторный запуск | стабильный decision/default |
| `NO06-45` | выбранный режим не поддерживается текущим level | fail-closed, не auto-skip |
| `NO06-46` | разная UI/engine normalization | NO-06 FAIL до исправления |
| `NO06-47` | один ref без стратегии, другой с ней | отсутствие аналога не равно ошибке |
| `NO06-48` | unknown capability | UNKNOWN, а не CFG «force supported» |

**Release gate:** до acceptance обязательны покрытие реальных конфликтов матрицей классификации, одинаковые UI/engine default и типы, отсутствие override safety, шесть переводов и tooltips, 48 Lua 5.1 mock/QA-07 сценариев, parity NO-04 и проверка WoW Forever. Любое недоказанное утверждение о предпочтительной стратегии помечается NOT VERIFIED. Стратегический выбор не является «исправлением бага» без свидетельства бага.

**Архитектурные и обратные ссылки:** NO-01, NO-05, NO-04, QA-07, DA-03, QA-01, UI-01, NO-02.

---

