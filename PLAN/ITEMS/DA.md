# Карточки DA

Источник: REQUIREMENTS.md, blob 9efdec1900398c978ea121818fb5950cb1620337.

### DA-01 — Шина событий с ревизиями каналов, пакетная обработка

ID: [DA-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L7283). Приоритет: P0. Lua: упомянут (точный статус в источнике).

**Вердикт / статус**

**Вердикт**

**ОСНОВА РЕАЛИЗОВАНА, СКВОЗНАЯ КОРРЕКТНОСТЬ НЕ ДОКАЗАНА (P0):** есть каналы, немедленные ревизии, пакетная доставка, heartbeat, обработка ошибок и диагностика. Требуются проверка потребителей ревизий, инвалидации при вычислении, latency и расширения для nameplates.

**Архитектурные ссылки:** EN-A2, EN-A8, EN-A9, EN-A10, EN-01, EN-03, DA-01, EventBus, GameState, AbilityEligibility, RotationEngine. Обратные уточнения добавлены в EN-A2, EN-A8, EN-A10, EN-A9.

**Изменения Lua:** отсутствуют. Только аудит и документация.

**Ретроактивное уточнение DA-02:** DA-02 уточняет: long-lived cache проверяет revision-vector до чтения, не полагаясь только на отложенный Flush; revision change во время оценки требует отмены stale READY. Исторический аудит сохранён.

**Ретроактивное уточнение DA-03:** DA-03: провайдеры подключаются по разрешённым Needs и подписываются на соответствующие каналы ревизий, не создавая отдельную шину. Исторический аудит сохранён.

**Ретроактивное уточнение DA-04:** DA-04 отделяет частоту пакетной доставки EventBus (0,20 с) от CPU-времени одной оценки; диагностика превышения бюджета не должна запускать дорогой повторный расчёт. Исторический аудит сохранён.

**Ретроактивное уточнение DA-05:** DA-05 уточняет: EventBus Tick/heartbeat только объединяет уведомления и инвалидирует, не запускает безусловное сканирование GameAPI. Исторический аудит сохранён.

**Ретроактивное уточнение DA-06:** DA-06 уточняет семантику burst/coalescing: revision повышается на каждое принятое событие, Flush объединяет уведомления, не скрывая stale state; reentrant events остаются на следующий Flush. Исторический аудит сохранён.

**Ретроактивное уточнение DA-08:** DA-08: identity/talents/spellbook/actionbar/bindings должны менять revisions сразу; смена спека/уровня требует атомарного пересмотра профиля, рангов и рекомендаций. Исторический аудит сохранён.

**Выбранный путь Kord**

**Выбранный путь Kord**

**Сохранить `KordRotation/Core/EventBus.lua` единственным каноническим маршрутизатором и расширять его контракт, не создавать отдельный bus для DevTools или классов.** Ревизии увеличивать сразу при принятии события, объединять только доставку уведомлений. Потребители обязаны проверять revisions по своим `Needs` непосредственно перед использованием кэшированных фактов; dirty revision означает пересчёт или UNKNOWN, но никогда прежний READY. Для нескольких каналов предусмотреть согласованную snapshot revision-vector, повторную проверку перед выдачей результата и обработку изменения ревизий во время вычисления. Для UI допустим coalesced Flush, для критических рекомендаций требуется своевременная инвалидизация независимо от задержки уведомления. Сохранять общий snapshot main/defensive. Для nameplates расширять только после проверки безопасных событий и unit token. Подписки/отписки во время Flush должны иметь детерминированную семантику. Heartbeat — инвалидатор, не подставной источник игровых фактов.

**Требуемые изменения (полный текст)**

**Требуемые изменения**

1. Определить фиксированный реестр каналов, контракты MarkDirty/Subscribe/Flush и обработку неизвестных каналов; гарантировать монотонность revisions.
2. Ввести/проверить сквозное сопоставление revision-vector с `Needs` в GameState/наблюдениях/AbilityEligibility и UI; запрещать stale READY.
3. Проверить зависимость identity/talents/spellbook после LEVEL_UP, SPELLS_CHANGED, respec; target/auras/resources/cooldowns/cast после соответствующих событий.
4. Установить безопасную политику критических обновлений при окне 0,20 с; проверить worst-case latency и повторное изменение revision во время EvaluateBoth.
5. Проверить события/UNIT-фильтр для EN-A10 и будущих nameplates, без небезопасного GUID.
6. DevTools: channel, event, accepted/ignored, revision before/after, pending/coalesced count, subscriber errors, unavailable events, cache hit/miss/stale, snapshot revisions и latency без secret данных.
7. Тесты: burst из N событий одного канала→N ревизий и одно уведомление; разные каналы; unsubscribe/re-subscribe; подписка во время Flush; исключение подписчика; reentrant MarkDirty; неизвестный канал; недоступное событие; heartbeat; stale cache; event during evaluation; Lua 5.1 и in-game.

**Тесты и диагностика**

в файле не указано

**Архитектурные и обратные ссылки:** NO-05, EN-01, EN-03, DA-02, DA-03, DA-04, DA-05, DA-06, DA-08.

---

### DA-02 — Кэш на одну оценку и долгий кэш только с инвалидацией по событиям

ID: [DA-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L7352). Приоритет: P0. Lua: упомянут (точный статус в источнике).

**Вердикт / статус**

**Вердикт**

**ЧАСТИЧНО РЕАЛИЗОВАНО (P0):** evaluation-scoped ленивые кэши и ревизионная проверка GameState есть; глобальная доказанная корректность всех long-lived caches и mid-evaluation revision validation отсутствует. Расширять существующие модули, не создавать классовые или параллельные кэши.

**Архитектурные ссылки:** DA-01, EN-A2, EN-A8, EN-A9, EN-A10, AbilityEligibility, RotationConditions, GameState, EventBus. Ретроактивные уточнения добавлены в DA-01, EN-A2, EN-A8, EN-A10, EN-A9.

**Изменения Lua:** отсутствуют. Только аудит и документация.

**Ретроактивное уточнение DA-03:** DA-03 определяет Needs как строгий allowlist доступа к провайдерам, а не команду предзагрузки; кэширование не может обходить отказ доступа. Исторический аудит сохранён.

**Ретроактивное уточнение DA-04:** DA-04 измеряет пользу ленивого evaluation cache и долгого revision-aware cache; оптимизация не разрешает stale READY. Исторический аудит сохранён.

**Ретроактивное уточнение DA-05:** DA-05: факты запрашиваются лениво с evaluation-scoped memoization; долгий кэш не оправдывает постоянное polling. Исторический аудит сохранён.

**Ретроактивное уточнение DA-06:** DA-06: burst-инвалидация long-lived caches происходит по немедленной revision, а не по позднему callback; повторные оценки используют только свежие факты. Исторический аудит сохранён.

**Ретроактивное уточнение DA-07:** DA-07: после изменения сохранённых настроек/миграции/сброса инвалидировать соответствующие кэши и revision-зависимые snapshots. Исторический аудит сохранён.

**Ретроактивное уточнение DA-08:** DA-08: кэши рангов, доступных заклинаний, action slots и bindings должны иметь полный revision-vector; старый READY/keybind недопустим. Исторический аудит сохранён.

**Ретроактивное уточнение UI-01:** UI-01: predicted next нельзя повторно использовать после изменения revision-vector; snapshot и cache для текущего READY и будущего PREDICTED имеют разную семантику. Исторический аудит сохранён.

**Ретроактивное уточнение UI-02:** UI-02: кеш button→spellID и binding labels должен учитывать actionbar/bindings/identity/talents revisions; защищённые или непроверенные кнопки не подсвечиваются. Исторический аудит сохранён.

**Выбранный путь Kord**

**Выбранный путь Kord**

**Сохранить `RotationConditions:Create` единственным evaluation-scoped cache context и `EventBus` каноническим источником ревизий.** Не создавать второй CacheManager без доказанной необходимости: долгоживущие кэши расширяются в существующих GameState/провайдерах, с декларацией `Needs/dependencyChannels`, сохранением revision-vector и сравнением с текущим EventBus перед каждым возвратом. Для одного прохода кэшировать также UNKNOWN и причину, но не переносить этот UNKNOWN в следующую оценку без новой проверки. Между main/defensive использовать один snapshot и согласованный контекст, сохраняя изоляцию channel-specific eligibility ключей. До выдачи READY сверять релевантные ревизии повторно; если состояние поменялось, результат не подтверждён. Для long-lived данных с внешними изменениями без подходящего события — не включать кэш, либо ввести доказанный канал инвалидации, но не полагаться на TTL. Не использовать stale value как fallback при UNKNOWN.

**Требуемые изменения (полный текст)**

**Требуемые изменения**

1. Составить исчерпывающий inventory всех кэшей Kord: владелец, ключ, lifespan, Needs, event channels, invalidation, UNKNOWN handling.
2. Утвердить единый revision-vector contract для long-lived caches, с проверкой **перед чтением** и после оценки; не зависеть от задержки Flush.
3. Проверить правильность ключей `readCache/factCache/eligibilityCache` (spellID, target policy, cast, charges, scope, snapshot identity) и отсутствие cross-channel contamination.
4. Проверить, что повторное UNKNOWN в одной оценке не вызывает второе GameAPI чтение, а новая оценка не наследует устаревший UNKNOWN.
5. Обеспечить инвалидацию при target/auras/health/resources/cooldowns/cast/identity/spellbook/talents/equipment и других реально необходимых событиях.
6. DevTools: cache owner, key-class, lifespan, dependency channels, revisions at read/current, hit/miss/stale/invalidated, reason без secret payload.
7. Тесты: repeated fact one read, repeated UNKNOWN one read, next evaluation new read, multiple main/defensive, target switch, spellbook update, cooldown event before Flush, revision changes mid-evaluation, missing event, unknown dependencies, secret value, performance benchmark и in-game Lua 5.1.

**Тесты и диагностика**

в файле не указано

**Архитектурные и обратные ссылки:** NO-05, NO-04, NO-03, NO-02, DA-01, DA-03, DA-04, DA-05, DA-06, DA-07, DA-08, UI-01, UI-02.

---

### DA-03 — Провайдеры данных подключаются через список Needs; без разрешения профиль данные не получит

ID: [DA-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L7428). Приоритет: P0. Lua: упомянут (точный статус в источнике).

**Вердикт / статус**

**Вердикт**

**ЧАСТИЧНО РЕАЛИЗОВАНО (P0):** базовая схема Needs и ограниченный фасад с ленивым чтением существуют. Полный gate всех методов, неизменность деклараций, проверка непрямых обходов и граница доверия исполняемого Lua не доказаны. Не обещать абсолютную изоляцию произвольного Lua без технических мер.

**Архитектурные ссылки:** DA-01, DA-02, EN-A2, EN-A4, EN-A10, RotationProfiles, RotationConditions, GameState, AbilityEligibility, EventBus. Ретроактивные уточнения добавлены в DA-02, DA-01, EN-A2, EN-A10.

**Изменения Lua:** отсутствуют. Только аудит и документация.

**Ретроактивное уточнение DA-04:** DA-04 измеряет затраты разрешённых Needs-провайдеров по запросу; нельзя обходить Needs ради экономии времени. Исторический аудит сохранён.

**Ретроактивное уточнение DA-05:** DA-05: провайдеры вызываются исключительно при фактическом разрешённом Needs-запросе; декларация Needs не запускает preload. Исторический аудит сохранён.

**Ретроактивное уточнение DA-07:** DA-07: сохранённые Needs после миграции проходят строгую allowlist-валидацию, нельзя автоматически выдавать новые полномочия. Исторический аудит сохранён.

**Ретроактивное уточнение DA-08:** DA-08: после смены спека/талантов/уровня разрешения Needs и профиль переопределяются без доступа к старому контексту. Исторический аудит сохранён.

**Ретроактивное уточнение UI-06:** пользовательское краткое объяснение отсутствия иконки строится из того же snapshot/status/reason, что DevTools диагностика DA-03; подробные traces, запись и экспорт остаются исключительно в DevTools, без второго логгера в пользовательской сборке.

**Ретроактивное уточнение QA-01:** все подробные event/engine/eligibility/API traces, opt-in recorder, performance samples и экспорт должны жить исключительно в отдельном `KordRotationDevTools` согласно QA-01; `KordRotation/Core/Diagnostics.lua` оставляет только bounded read-only support snapshot. Не создавать второй production recorder.

**Ретроактивное уточнение QA-02:** диагностический журнал DA-03 обязан сохранять валидные новые reason/subreason из trusted core bridge без ручного whitelist кодов; не подменять их `diagnostic_code_unmapped`/`diagnostic_detail_unmapped`. Проверки, которые движок не исполнял, маркировать `NOT_EVALUATED`, а не пересчитывать.

**Ретроактивное уточнение QA-04:** диагностический API trace использует канонические `matrixID` v14 и разделяет source-confirmed, presence-only и actual client-confirmed; экспорт не должен приписывать проверку игры исходниковому анализу.

**Выбранный путь Kord**

**Выбранный путь Kord**

**Сохранить `RotationProfiles.Needs` как единственную схему полномочий и `RotationConditions` как единый профильный фасад, расширяя существующие провайдеры, без отдельного ProviderManager или классовых фасадов.** Для каждого доступного метода/факта определить явное соответствие `fact kind + spellID/target scope → Needs entry → canonical provider → EventBus dependency channels`. Отсутствие разрешения — отказ до чтения, без побочных эффектов, без раскрытия значения, без косвенного fallback через другой метод. Запросы валидировать на типы, безопасные значения, target identity, known spellID и разрешённую семантику. Различать `needs_not_declared`, `provider_unavailable`, `fact_unknown`, `secret_value`; все неавторизованные или неизвестные обязательные условия приводят к UNKNOWN→STOP (EN-A4). Факты читать лениво, memoize включая UNKNOWN, инвалидировать long-lived данные по DA-01/DA-02. Учитывать, что исполняемые профили Lua нельзя объявлять полностью изолированными без отдельной границы доверия.

**Требуемые изменения (полный текст)**

**Требуемые изменения**

1. Провести inventory всех методов `RotationConditions`, `ReadSignal`, `spellFact`, `AbilityEligibility` и их источников; составить матрицу fact→Needs→provider→revisions.
2. Закрыть возможные обходы Needs через `spellFact` и другие методы; разрешение проверять **до** обращения к провайдеру.
3. Утвердить строгую версионированную схему Needs (списки spellID, bool/enum, scope), отвергать неизвестные/лишние ключи и изменённые после регистрации декларации.
4. Для новых enemy/TTD/auras/range/swing фактов проверять доступность и secret безопасность API; не создавать mock READY.
5. Обеспечить независимость main/defensive при общем evaluation context и запрет кросс-профильного чтения.
6. DevTools: profileID, requested fact, Needs decision allow/deny, provider, revision, cache hit/miss, UNKNOWN reason, без значения secret.
7. Тесты: разрешённый факт, недекларированный факт без вызова провайдера, неверный spellID, изменённые Needs, неизвестный provider, secret, два профиля, общий main/defensive, запрет косвенного обхода через eligibility/spellFact, Lua 5.1 и in-game; отдельно тест границы доверия для исполняемого Lua.

**Тесты и диагностика**

в файле не указано

**Архитектурные и обратные ссылки:** NO-06, NO-05, DA-02, DA-01, DA-04, DA-05, DA-07, DA-08, UI-06, QA-01, QA-02, QA-04.

---

### DA-04 — Бюджет времени на оценку, замер, предупреждение при превышении

ID: [DA-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L7502). Приоритет: P1. Lua: упомянут (точный статус в источнике).

**Вердикт / статус**

**Вердикт**

**НЕ РЕАЛИЗОВАНО (P1):** ленивый обход и общая оценка есть, но CPU-бюджет, полный замер и предупреждения о превышении не подтверждены. Нужен измерительный слой существующего движка и Diagnostics.

**Архитектурные ссылки:** DA-01, DA-02, DA-03, EN-A2, EN-A4, RotationEngine, Diagnostics, EventBus. Ретроактивные уточнения добавлены в DA-01, DA-02, DA-03, EN-A2.

**Изменения Lua:** отсутствуют. Только аудит и документация.

**Ретроактивное уточнение DA-05:** DA-05: в бюджет оценки входят затраты GetSnapshot(force), lazy ReadSignal и bounded aura scans; отсутствие OnUpdate в Engine не доказывает отсутствие дорогостоящего polling в UI. Исторический аудит сохранён.

**Ретроактивное уточнение DA-06:** DA-06: замерять events/sec, coalescing ratio, callback duration и latency, но rate-limit WARN без изменения safety. Исторический аудит сохранён.

**Ретроактивное уточнение DA-07:** DA-07: настройки бюджета времени валидируются при загрузке/миграции, неподтверждённые числовые дефолты не вводятся. Исторический аудит сохранён.

**Ретроактивное уточнение QA-01:** performance probes и измерение накладных расходов из DA-04 выполняются только в opt-in DevTools QA-01; нельзя включать тяжёлый постоянный profiler в пользовательский аддон.

**Выбранный путь Kord**

**Выбранный путь Kord**

**Встроить тонкий измерительный слой в существующий `RotationEngine` и агрегирование в `Diagnostics`, без отдельного PerformanceEngine и без per-rule таймеров в production по умолчанию.** Измерять полный цикл единым monotonic clock, предпочтительно `debugprofilestop()` при безопасной доступности на Forever; fallback на доступный monotonic timer с явной маркировкой типа часов и точности, не выдавая wall-time за CPU-time. Замер start/stop даже при ошибке `pcall`, отдельная метрика для main/defensive/both и shared portion. Дефолтный budgetMs утвердить только после baseline на целевых устройствах; настройки ограничить диапазоном, диагностировать exceed и накопительные count/max/rolling average/p95 в bounded buffer. Предупреждения rate-limit и агрегировать. При превышении — фиксировать, оптимизировать Needs/caches/сканы; не прерывать Lua произвольно, не выдавать устаревший READY и не нарушать EN-A4. Измерения без секретных значений и дорогостоящих трассировок в обычном режиме.

**Требуемые изменения (полный текст)**

**Требуемые изменения**

1. Определить единый timing contract: `durationMs`, `clockKind`, `budgetMs`, `overBudget`, `channel`, `profileID`, `evaluationID`, статус, причину ошибки; fail-safe при недоступном таймере.
2. Добавить start/stop в `Evaluate`, `EvaluateDefensive`, `EvaluateBoth` с корректным учётом общего snapshot/context и ошибок.
3. Собрать baseline и выбрать подтверждённый дефолт бюджета на WoW Forever; ограничить диапазон пользовательской настройки.
4. Добавить bounded статистику (count/avg/max/p95), throttled WARN и диагностику без secret data.
5. Проверить, что измерение не добавляет сканы и не создаёт дополнительный OnUpdate; влияние профилировщика измерять отдельно.
6. Тесты: обычный проход, превышение, ошибка, недоступный timer, двойной канал, nested evaluation, частые превышения, rate limit, неизменность UNKNOWN→STOP, Lua 5.1 и in-game benchmark.

**Тесты и диагностика**

в файле не указано

**Архитектурные и обратные ссылки:** DA-01, DA-02, DA-03, DA-05, DA-06, DA-07, QA-01.

---

### DA-05 — Нет постоянного сканирования: данные читаются по запросу

ID: [DA-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L7562). Приоритет: P0. Lua: упомянут (точный статус в источнике).

**Вердикт / статус**

**Вердикт**

**АРХИТЕКТУРНАЯ ОСНОВА РЕАЛИЗОВАНА, ПОЛНОЕ ПОКРЫТИЕ НЕ ДОКАЗАНО (P0):** EventBus не сканирует из OnUpdate, Conditions читают по запросу, Engine не создаёт polling loop. Но другие UI/модули, принудительный snapshot и частота Evaluate не прошли исчерпывающий аудит. Требуется доказательство отсутствия непрерывных тяжёлых сканирований во всём аддоне.

**Архитектурные ссылки:** DA-01, DA-02, DA-03, DA-04, EN-A10, EventBus, RotationConditions, GameState, RotationEngine. Ретроактивные уточнения добавлены в DA-01, DA-02, DA-03, DA-04, EN-A10.

**Изменения Lua:** отсутствуют. Только аудит и документация.

**Ретроактивное уточнение DA-06:** DA-06: шторм событий не должен запускать непрерывные полные сканы аур/cooldowns; только demand-driven bounded reads. Исторический аудит сохранён.

**Ретроактивное уточнение UI-02:** UI-02: glow обновляется по изменению подтверждённой рекомендации и revision, без непрерывного полного сканирования кнопок. Исторический аудит сохранён.

**Ретроактивное уточнение QA-01:** event storm, coalescing, dropped count и лимиты трассировки проверяются в отдельном DevTools QA-01; наблюдатель не должен сам создавать неконтролируемый OnUpdate/второй EventBus.

**Выбранный путь Kord**

**Выбранный путь Kord**

**Оставить EventBus единственным механизмом событийной инвалидации, RotationConditions — единственным Needs-gated lazy fact facade, GameState — источником snapshot/ReadSignal; не создавать ScanManager или отдельные class-specific polling loops.** На событии только `MarkDirty`/инвалидация; на оценке только запрошенные факты. `GetSnapshot(force)` оптимизировать по реальной потребности и измерениям DA-04, не нарушая согласованность и запрет stale READY. Для дорогих сканов определить максимальное число API вызовов и условие полного/неполного результата. Для UI обновлять отображение по изменению данных, а не бесконечно перечитывать все источники. Для будущего EN-A10 использовать событийно поддерживаемый список кандидатов с ленивыми per-target запросами, без полного nameplate обхода на каждом кадре. Любое резервное периодическое обновление должно быть обосновано конкретной недоступностью событий, иметь лимит и явно документироваться как исключение, не как основной механизм.

**Требуемые изменения (полный текст)**

**Требуемые изменения**

1. Инвентаризировать все `OnUpdate`, `C_Timer`, `GetSnapshot(force)`, `Evaluate`, сканеры аур/предметов/nameplates/actionbars и частоту их вызовов; классифицировать event-only, demand-driven, polling.
2. Проверить отсутствие GameAPI сканов в `EventBus:Tick` и других безусловных периодических callback; зафиксировать тестом.
3. Измерить затраты snapshot и каждого дорогостоящего `ReadSignal` по DA-04, определить bounded scan budgets.
4. Проверить, что неразрешённый Needs-запрос не вызывает провайдер, а повторный факт в одной оценке не повторяет API вызов.
5. Для неполного сканирования возвращать UNKNOWN, не false/absence; контролировать secret/protected и смену target revision.
6. DevTools: source of trigger, requested fact, API-call count, scan bound/completion, cache hit/miss, elapsed, skipped due to no demand; без secret payload.
7. Тесты: idle 60 с без demand→нет тяжёлых сканов; burst событий без Evaluate→только invalidation; 40 правил с ранним READY→поздние Needs не читаются; aura scan limit→UNKNOWN; два канала с общим snapshot; target/nameplate change; Lua 5.1 и in-game performance.

**Тесты и диагностика**

в файле не указано

**Архитектурные и обратные ссылки:** DA-03, DA-02, DA-01, DA-04, DA-06, UI-02, QA-01.

---

### DA-06 — Защита от «шторма» событий (кулдаун, ауры)

ID: [DA-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L7620). Приоритет: P1. Lua: упомянут (точный статус в источнике).

**Вердикт / статус**

**Вердикт**

**ЧАСТИЧНО РЕАЛИЗОВАНО (P1):** базовая защита от storm через coalesced Flush и немедленные revisions есть. Метрики, bounded callbacks, критическая latency/priority политика и stress tests не подтверждены.

**Архитектурные ссылки:** DA-01, DA-02, DA-04, DA-05, EN-A10, EventBus, GameState, RotationEngine. Ретроактивные уточнения добавлены в DA-01, DA-02, DA-04, DA-05, EN-A10.

**Изменения Lua:** отсутствуют. Только аудит и документация.

**Ретроактивное уточнение DA-08:** DA-08: шторм SPELLS_CHANGED/талантов/панелей coalesce, но немедленно инвалидирует прежний профиль и keybind; critical revision не теряется. Исторический аудит сохранён.

**Выбранный путь Kord**

**Выбранный путь Kord**

**Усилить существующий `EventBus`, не создавать StormManager или вторую шину.** Сохранять немедленный `MarkDirty` и coalesced `Flush`, добавить bounded per-channel burst counters и метрики задержки. Для критических каналов гарантировать немедленную видимость revision потребителям; latency уведомления отдельно измерять и при необходимости корректировать scheduler, не добавляя прямые дорогостоящие сканы в OnEvent. Потребитель с pending revision не может вернуть старый READY (DA-02). Определить явную политику per-channel criticality, приоритеты не должны создавать starvation. `Flush` snapshot-подписчиков или детерминированная семантика изменения подписок; reentrant MarkDirty остаётся pending. Для UI/звуков rate-limit без подавления фактов. Диагностику ограничивать и агрегировать. Если шторм продолжается бесконечно, выполнять bounded work и fail-closed при недостоверном состоянии.

**Требуемые изменения (полный текст)**

**Требуемые изменения**

1. Добавить per-channel `acceptedCount`, `coalescedCount`, `flushCount`, `first/last event time`, `max pending age`, `callback cost` в bounded диагностике.
2. Определить priority/latency contract для target/cast/interrupt-sensitive обновлений против aura/cooldown storms; без неподтверждённых числовых SLA до бенчмарка.
3. Гарантировать revision-based invalidation до Flush и отсутствие stale READY в GameState/провайдерах/Engine.
4. Установить bounded work подписчиков и правила reentrancy/subscribe/unsubscribe во время Flush; предотвращать starvation.
5. Не запускать полный aura/cooldown scan на каждый event; читать факты по разрешённым Needs и DA-05.
6. DevTools: burst size, channel, accepted/coalesced/delivered, oldest pending age, callback duration, WARN count, без secret payload.
7. Тесты: 100/1000 UNIT_AURA в окне → 100/1000 revisions, одно уведомление; смешанный cooldown/aura burst; reentrant MarkDirty; error subscriber; slow subscriber; смена цели во время storm; бесконечный burst; latency/CPU на Forever, Lua 5.1; UNKNOWN→STOP и no stale READY.

**Тесты и диагностика**

в файле не указано

**Архитектурные и обратные ссылки:** DA-02, DA-05, DA-01, DA-04, DA-08.

---

### DA-07 — Сохранение настроек, миграция схемы, сброс на дефолты

ID: [DA-07](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L7674). Приоритет: P1. Lua: упомянут (точный статус в источнике).

**Вердикт / статус**

**Вердикт**

**ЧАСТИЧНО РЕАЛИЗОВАНО (P1):** SavedVariables, defaults, нормализация и per-spell reset существуют; полноценная версионированная миграция, общий scoped reset и доказанные round-trip тесты отсутствуют.

**Архитектурные ссылки:** EN-A5, EN-A6, EN-A8, DA-02, DA-03, DA-04, Settings, RotationSettings, RotationProfiles. Ретроактивные уточнения добавлены в EN-A5, EN-A6, EN-A8, DA-02, DA-03, DA-04.

**Изменения Lua:** отсутствуют. Только аудит и документация.

**Ретроактивное уточнение DA-08:** DA-08: смена спека не должна перезаписывать настройки предыдущего class/spec профиля; требуется корректная привязка SavedVariables. Исторический аудит сохранён.

**Ретроактивное уточнение UI-03:** миграция SavedVariables обязана сохранять provenance/namespace CFG, отличать explicit override от inherited default, разрешать legacy `saved.config` только по доказанной однозначной миграции и выводить конфликт через UI-03, без молчаливого затирания пользовательского значения. После reset UI перечитывает effective settings через один resolver. См. UI-03.

**Ретроактивное уточнение UI-04:** сохранение/миграция/сброс именованных пресетов, версии export envelope и атомарное применение импорта относятся к общему механизму DA-07; UI-04 добавляет безопасный transport и content/spec binding без отдельной миграционной системы.

**Ретроактивное уточнение UI-05:** миграция legacy-флагов `showInCombat/showOutOfCombat/requireTarget` в канонический `visibilityMode` и откат при конфликте — часть общего версионированного механизма DA-07; не затирать несовместимые сочетания молча. См. UI-05.

**Ретроактивное уточнение UI-07:** смена языка не изменяет сериализованные enum/CFG/импортированные пресеты и не требует миграции gameplay state; язык хранится как валидированный locale code, UI обновляется через общий registry UI-07.

**Выбранный путь Kord**

**Выбранный путь Kord**

**Сохранить `Settings.lua` владельцем общей схемы и `RotationSettings.lua` владельцем нормализации/сброса ротационных настроек; не создавать отдельный SettingsManager.** В `Settings:InitializeSettings` внедрить последовательный registry `migrations[fromVersion]` с проверкой входной версии, преобразованием копии данных, проверкой результата и commit только после успешного преобразования. Для будущей версии — не перезаписывать неизвестную структуру дефолтами; отказ от использования неподтверждённых полей, предупреждение и безопасный read-only/fallback режим. После миграции — глубокая нормализация типизированных полей и допустимых диапазонов, независимые defaults для каждого профиля/персонажа, неизменяемые зарегистрированные метаданные профиля. Определить scopes reset: `ui`, `rotation`, `spell`, `all` с явным подтверждением разрушительного all; reset сбрасывает только соответствующие пользовательские значения и инвалидирует зависимые snapshots/cache, оповещает UI. Не выполнять reset при ошибке миграции. При обновлении контракта профиля не повышать автоматически `verified`.

**Требуемые изменения (полный текст)**

**Требуемые изменения**

1. Инвентаризировать все SavedVariables и их области аккаунт/персонаж; закрепить schemaVersion и порядок инициализации.
2. Реализовать последовательные миграции `vN→vN+1`, validate-before-commit, идемпотентность, запрет downgrade future schema.
3. Расширить нормализацию nested settings, moduleConfigs, targetMode, spell overrides, неизвестных/опасных полей; сохранять совместимые пользовательские значения.
4. Реализовать единый reset contract по scope, с deep copy defaults и безопасным подтверждением полного сброса.
5. После миграции/reset публиковать изменение настроек, инвалидировать релевантные кэши и обновлять UI; не запускать полный игровой скан.
6. DevTools: old/new schema, migration step/result, invalid fields count, reset scope, warnings; не логировать секреты и содержимое пользовательских настроек.
7. Тесты: fresh install, legacy version, multi-step, repeated initialization, malformed/nil/NaN, future version, failed migration rollback, character isolation, nested defaults, profile status/Needs, per-spell reset, full reset confirmation, round-trip after /reload, Lua 5.1/in-game.

**Тесты и диагностика**

в файле не указано

**Архитектурные и обратные ссылки:** DA-02, DA-03, DA-04, DA-08, UI-03, UI-04, UI-05, UI-07.

---

### DA-08 — Реакция на смену спека, талантов, уровня, панели, привязок

ID: [DA-08](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L7736). Приоритет: P0. Lua: упомянут (точный статус в источнике).

**Вердикт / статус**

**Вердикт**

**ЧАСТИЧНО РЕАЛИЗОВАНО (P0):** маршрутизация событий, ревизии, выбор профиля по уровню и инвалидация BindingResolver есть. Полный end-to-end пересмотр рангов, профиля, слотов, UI и отсутствие stale READY при всех переходах не доказаны.

**Архитектурные ссылки:** DA-01, DA-02, DA-03, DA-05, DA-06, DA-07, EN-A8, RotationProfiles, RotationEngine, BindingResolver, ActionBarScanner, EventBus. Ретроактивные уточнения добавлены в DA-01, DA-02, DA-03, EN-A8, DA-07, DA-06.

**Изменения Lua:** отсутствуют. Только аудит и документация.

**Ретроактивное уточнение UI-01:** UI-01: смена спека/уровня/actionbar/bindings немедленно очищает устаревшие иконки и клавиши; defensive не является next slot. Исторический аудит сохранён.

**Ретроактивное уточнение UI-02:** UI-02: смена actionbar page/slot/override/bindings/спека немедленно инвалидирует кнопку подсветки и keybind; нельзя сохранять glow на прежней кнопке. Исторический аудит сохранён.

**Ретроактивное уточнение UI-03:** при смене class/spec/level/активного модуля окно динамических CFG-контролов должно переустановить привязку к новой схеме и namespace, перечитать значения, сбросить focus/stale widgets и показать UNKNOWN при неопределённом профиле. Изменение bindings/actionbar не меняет CFG, но обновляет зависимые UI-сведения. См. UI-03.

**Ретроактивное уточнение UI-04:** при изменении спека/уровня пересчитывать привязку именованного пресета UI-04 после подтверждения identity и схемы; при неопределённости не переключать профиль и не переносить overrides между class/spec. Не менять профиль при обновлении actionbar/bindings.

**Ретроактивное уточнение UI-05:** combat/target visibility инвалидируется по EventBus (UI-05), независимо от пересмотра spec/level и actionbar/bindings; смена спека не должна менять общий режим показа без явного применения пресета настроек.

**Ретроактивное уточнение UI-08:** общий механизм инвалидации DA-08 обязан учитывать actionbar Hide/Show, paging, addon load/unload where observable, bindings, form/stance/override и live revalidation из UI-08. Не предполагать, что все сторонние аддоны посылают Blizzard event; TTL fallback остаётся ограниченным.

**Ретроактивное уточнение QA-03:** инвалидации DA-08 проверяются детерминированным mock event harness Lua 5.1 с счётчиками API reads, revision, cache, target/spec/talents/bindings/actionbar; без in-game PASS.

**Ретроактивное уточнение QA-05:** сравнение переходов после `PLAYER_TARGET_CHANGED`, смены спека/уровня/талантов/привязок/actionbar и EventBus revision должно охватывать одинаковый event trace и отсутствие stale snapshot; несовпадение на непроверенном API маркировать INCONCLUSIVE.

**Ретроактивное уточнение QA-07:** QA-07 использует event/revision последовательности в сценариях смены цели, спека, уровня, талантов и панели; состояние после события должно проверяться отдельным ожидаемым результатом, без stale snapshot.

**Выбранный путь Kord**

**Выбранный путь Kord**

**Оставить EventBus каноническим источником ревизий, а существующие RotationProfiles/RotationEngine/BindingResolver/ActionBarScanner/GameState потребителями; новый SpecChangeManager не создавать.** Разделить цепочки invalidation: `identity/talents/spellbook` → перечитать class/spec/level и изученные ранги, заново выбрать профиль и перепроверить Eligibility; `actionbar` → перепроверить реальные слоты и доступность кнопок; `bindings` → обновить только доказанную привязку. Все цепочки должны инвалидировать отображаемую старую рекомендацию/клавишу до завершения пересчёта; если свежая проверка невозможна, UNKNOWN. Не смешивать профили и SavedVariables разных class/spec. Поддержать reorder событий и revision change во время EvaluateBoth без stale READY; no full polling.

**Требуемые изменения (полный текст)**

**Требуемые изменения**

1. Создать полную матрицу event→revision→affected cache→profile/rank/slot/binding/UI и проверить подписчиков всех модулей.
2. Проверить реальное обновление learned-rank resolver и вызов `RotationProfiles:Replace` после SPELLS_CHANGED/PLAYER_LEVEL_UP/смены талантов; исправить отсутствующие пути.
3. Инвалидировать старый READY и keybind при смене identity/spec/level, slot/page/override/bindings до подтверждения нового.
4. Разделить независимые изменения binding-only и actionbar-only, не запускать полный профильный пересчёт без необходимости.
5. Обеспечить корректную область SavedVariables для class/spec и level ranges, защиту от межпрофильной записи.
6. DevTools: event/channel, old/new profile ID (только безопасные данные), level boundary, revision, rank status, slot/binding invalidation, recompute result, UNKNOWN reason; без secret.
7. Тесты: смена спека и талантов, уровень на границе, rank upgrade, перемещение кнопки, смена страницы/stance/vehicle/override, UPDATE_BINDINGS, macro update, события в разном порядке, storm, mid-evaluation, reload, in-combat secret, Lua 5.1/in-game.

**Тесты и диагностика**

в файле не указано

**Архитектурные и обратные ссылки:** NO-03, CL-09, DA-01, DA-06, DA-05, DA-02, DA-03, DA-07, UI-01, UI-02, UI-03, UI-04, UI-05, UI-08, QA-03, QA-05, QA-07.

---

