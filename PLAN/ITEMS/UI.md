# Карточки UI

Источник: REQUIREMENTS.md, blob 9efdec1900398c978ea121818fb5950cb1620337.

### UI-01 — Иконка рекомендуемого действия и следующая в очереди

ID: [UI-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L7812). Приоритет: P0. Lua: упомянут (точный статус в источнике).

**Вердикт / статус**

**Вердикт**

**ЧАСТИЧНО РЕАЛИЗОВАНО (P0):** текущая иконка, очистка и defensive UI есть; `queue[2]` и его безопасное прогнозирование/отображение отсутствуют. Следующий шаг нельзя выдавать за текущий READY.

**Архитектурные ссылки:** EN-A9, EN-A2, DA-02, DA-08, RotationEngine, RotationDisplay, SpellIcon, AbilityEligibility. Ретроактивные уточнения добавлены в EN-A9, EN-A2, DA-02, DA-08.

**Изменения Lua:** отсутствуют. Только аудит и документация.

**Ретроактивное уточнение UI-02:** UI-02 использует только текущую подтверждённую queue[1] READY для подсветки реальной кнопки; queue[2] PREDICTED не может запускать glow как текущий action. Клавиша выводится из проверенного BindingResolver. Исторический аудит сохранён.

**Ретроактивное уточнение UI-03:** видимость/число иконок, keybind и предсказанный слот читают только effective validated UI/CFG settings общего resolver; настройки внешнего вида не создают следующий READY и не обходят Eligibility/UNKNOWN. См. UI-03.

**Ретроактивное уточнение UI-04:** смена пресета настроек должна инвалидировать presentation/recommendation revision UI-01 и очистить устаревшие иконки/клавиши до нового проверенного результата; не считать пресет источником READY.

**Ретроактивное уточнение UI-05:** видимость оболочки главной панели и подтверждённая рекомендация — разные состояния. Все три режима показа вычисляются единым `DisplayVisibilityPolicy` (UI-05); скрытие не создаёт READY/PREDICTED, не переносит defensive в main и не сохраняет устаревшие иконки/клавиши.

**Ретроактивное уточнение UI-06:** отсутствие текущей иконки и пустая/неподтверждённая PREDICTED очередь должны объясняться через единый `RecommendationAbsenceExplanation` (UI-06), не подменяя результат движка. Пустая оболочка не означает `no_eligible_rule` без подтверждённого engine reason.

**Ретроактивное уточнение UI-07:** подписи текущей/следующей рекомендации, пустого слота и прогнозного статуса UI-01 используют единый registry UI-07, не локализуют `SpellID`, source или машинные статусы `READY/PREDICTED/UNKNOWN`.

**Ретроактивное уточнение UI-08:** основная рекомендация и её texture не зависят от наличия видимой actionbar-кнопки; доступность подсветки и клавиши определяется общими read-only `ActionBarScanner`/`BindingResolver` и `ActionBarPresentationState` UI-08. Скрытие сторонней панели не означает, что spell стал недоступен.

**Ретроактивное уточнение QA-07:** QA-07 различает ожидаемое действие движка и ожидаемое отображение main/defensive/next; UI-01 не должен подменять engine decision фактом наличия иконки.

**Выбранный путь Kord**

**Выбранный путь Kord**

**Реализовать UI-01 на базе существующих `RotationEngine` и `RotationDisplay`, не создавать второго предсказывающего движка или отдельной очереди в UI.** Сохранить `queue[1]` как проверенный READY. Определить версионированный контракт `queue[2]` только для `PREDICTED` с `spellID/texture/name`, `predictionBasis`, `confidence/status` при реально доступных доказательствах; не придумывать confidence. Переиспользовать lazy priority traversal, но прогноз не должен выдавать READY без будущего состояния и не должен обходить UNKNOWN STOP или AbilityEligibility. Если безопасная модель будущего состояния на WoW Forever недоступна, `queue[2]` отсутствует и слот пуст. Валидатор UI проверяет каждый слот отдельно: не отклонять достоверный queue[1] из-за отсутствующего/некорректного queue[2]. Main/defensive остаются независимыми; текущий snapshot и revision проверяются до отображения. Иконка/клавиша очищается при устаревании. Не изменять другие классовые системы и не создавать speculative UI fallback.

**Требуемые изменения (полный текст)**

**Требуемые изменения**

1. Утвердить schema `queue[1]=READY`, `queue[2]=PREDICTED|nil`, разграничить status/reason/visuals, без недоказанного второго READY.
2. Расширить `RotationEngine` безопасным ограниченным next-step prediction поверх существующих условий/eligibility, только при доказанной модели будущего состояния; UNKNOWN STOP.
3. Переписать `RotationDisplay.verifiedRecommendation` на независимую валидацию слотов; отображать queue[2] только при валидном прогнозе, не сбрасывая queue[1].
4. Гарантировать очистку texture/keybind при смене профиля/состояния/revisions и невозможности прогнозирования; защитить secret values.
5. Разграничить defensive и next queue, проверить настройки количества слотов и preview/mock markers.
6. DevTools: current READY, next PREDICTED/UNKNOWN, prediction basis/reason, invalidation, accuracy (если доступны подтверждённые исходы), без secret.
7. Тесты: current-only, current+predicted, unknown next, invalid next, no current, stale revision, spec/level/actionbar/bindings, defensive, protected texture, false READY, profile with 40 priorities, Lua 5.1 и in-game.

**Тесты и диагностика**

в файле не указано

**Архитектурные и обратные ссылки:** NO-06, NO-04, NO-03, NO-02, NO-01, DA-02, DA-08, UI-02, UI-03, UI-04, UI-05, UI-06, UI-07, UI-08, QA-07.

---

### UI-02 — Подсветка кнопки на панели (если разрешено), показ клавиши привязки

ID: [UI-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L7889). Приоритет: P1. Lua: упомянут (точный статус в источнике).

**Вердикт / статус**

**Вердикт**

**ЧАСТИЧНО РЕАЛИЗОВАНО (P1):** отображение клавиши и verified actionbar/binding lookup существуют; `SpellIcon.highlightMain` подсвечивает только собственную иконку. Подсветка реальной кнопки, lifecycle и capability проверка отсутствуют в проверенных модулях; end-to-end in-game совместимость не подтверждена.

**Архитектурные ссылки:** UI-01, EN-A2, DA-02, DA-05, DA-07, DA-08, AC-02, ActionBarScanner, BindingResolver, RotationDisplay, SpellIcon. Обратные ссылки внесены в UI-01, DA-08, DA-05, DA-02, EN-A2.

**Изменения Lua:** отсутствуют. Только документация.

**Ретроактивное уточнение UI-03:** `glowEnabled`, стиль, интенсивность и `showKeybind` должны иметь однозначные ключи/владельцев CFG и показ источника значения. Различать `panel.highlightMain` (рамка иконки) и `indicators.actionHighlight` (намерение подсвечивать actionbar): два разных контракта, без автосинхронизации. См. UI-03.

**Ретроактивное уточнение UI-05:** подсветка текущей actionbar-кнопки и отображение клавиши должны учитывать итоговую видимость main по `DisplayVisibilityPolicy` (UI-05); скрытая main-панель не должна оставлять stale glow, но видимость не меняет eligibility и не разрешает protected операции.

**Ретроактивное уточнение UI-06:** отсутствие keybind/glow при существующей READY-иконке — отдельная причина `binding_unverified|button_not_visible|glow_blocked`, а не «нет рекомендации». UI-06 отображает explanation из существующего UI-02 observation, не дублирует поиск кнопок.

**Ретроактивное уточнение UI-08:** подсветка и keybind UI-02 обязаны пользоваться каноническим `ActionBarPresentationState` UI-08 поверх существующих `ActionBarScanner`/`BindingResolver`; при Hide/Show, paging, override, смене action/бинда сбрасывать stale glow/label, `UNKNOWN` не считать `UNBOUND` или `ABSENT`. Не создавать второй scanner или glow engine.

**Выбранный путь Kord**

**Выбранный путь Kord**

**Расширить существующие `ActionBarScanner`, `BindingResolver` и `RotationDisplay` единым лёгким UI glow-controller (логический контракт, не обязательный отдельный Lua-файл).** Единственный источник текущего действия — `RotationEngine.queue[1]` READY после AbilityEligibility; для кнопки повторно использовать `ActionBarScanner:GetVerifiedButtons(spellID)`, а для подписи — `BindingResolver:Resolve(spellID)`, без параллельного поиска кнопок/клавиш и без новых OnUpdate scans. Glow-controller хранит ссылку на **только ранее проверенную** кнопку и ID/ревизии; при изменении action/profile/revision/visibility останавливает прежний glow, затем (если разрешено) запускает новый. В качестве visual adapter использовать доступный и подтверждённый на WoW Forever `LibCustomGlow.ButtonGlow_Start/Stop` или эквивалентный read-only overlay, только после capability probe; не считать библиотеку обязательной и не модифицировать защищённые свойства кнопки. При combat/protected/secret неопределённости не запускать glow, диагностировать reason и оставить основную рекомендацию. Учитывать несколько кнопок с одним spellID: выбирать детерминированно одну verified visible, предпочтительно с доказанной binding, без подсветки скрытой/неактуальной страницы. Если предметы поддерживаются через AC-02 `actionType=ITEM`, проверять itemID отдельно и не подменять его use-spell ID; не объявлять item glow реализованным до item-aware scanner. Для defensive использовать независимую явную политику glow, по умолчанию не смешивать с main. Для `PREDICTED` glow запрещён. Параметры `glowEnabled`, style/color/intensity и `showKeybind` — типизированные настройки с безопасными defaults/миграцией DA-07; настройки рамки собственной иконки не являются glow игровой панели. Любая смена `actionbar/bindings/identity/talents/spellbook` и рекомендаций немедленно инвалидирует текущий glow; на следующем render — revalidate, без stale READY. Не выполнять protected click, `SetAttribute`, `SetBinding` или автоматическое использование способности.

**Требуемые изменения (полный текст)**

**Требуемые изменения**

1. Определить `ActionButtonPresentationObservation` и UI glow lifecycle (`activeButton`, `activeSpellID`, `revisions`, `reason`); не сохранять frame refs в SavedVariables.
2. Повторно использовать `ActionBarScanner:GetVerifiedButtons` и `BindingResolver:Resolve`, верифицировать видимость, action slot, spellID, ранг, macro/override/page и command; не создавать второй scanner.
3. Проверить capability `LibCustomGlow.ButtonGlow_Start/Stop`/read-only overlay на Forever в бою и вне боя; при неизвестном разрешении fail-closed для glow, не для READY.
4. Реализовать start/stop при смене текущего READY, страницы/спека/привязки/видимости/настроек, а также при UNKNOWN/BLOCKED; cleanup при disable/reload и отсутствии кнопки.
5. Сохранить и дополнить показ `keybindLabel` с `READY/UNBOUND/UNKNOWN`, поддержать несколько клавиш/модификаторы при подтверждённых данных; неизвестную клавишу скрывать, не подменять старой.
6. Подключить типизированные настройки `glowEnabled`, style/color/intensity и showKeybind к Settings/IndicatorSettings с DA-07 миграцией, без конфликта с `highlightMain`.
7. DevTools reason codes: `glow_disabled`, `glow_api_unavailable`, `glow_protected`, `glow_button_unverified`, `glow_button_not_visible`, `glow_stale_revision`, `glow_start_failed`, `glow_stop_failed`, `binding_unbound`, `binding_unknown`, `binding_reverse_mismatch`, `binding_override_unverified`; логировать transitions без secret/frame refs.
8. Тесты: verified spell+binding, no key, UNKNOWN key, duplicate buttons, different rank, macro, item action, paging/stance/vehicle/override, Bartender/Dominos/ElvUI/EllesmereUI/LAB, disabled glow, no glow API, combat lockdown, secret/protected, rapid spell changes, reentrant events, 1000 event storm, invalidation mid-evaluation, defensive vs main, predicted next, cleanup on hide/reload, Lua 5.1 и WoW Forever.

**Тесты и диагностика**

в файле не указано

**Архитектурные и обратные ссылки:** UI-01, AC-02, DA-07, DA-02, DA-05, DA-08, UI-03, UI-05, UI-06, UI-08.

---

### UI-03 — Окно настроек из схемы CFG: группы, подсказки, конфликты источников

ID: [UI-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L7947). Приоритет: P0. Lua: упомянут (точный статус в источнике).

**Вердикт / статус**

**Вердикт**

**ЧАСТИЧНО РЕАЛИЗОВАНО (P0):** девять вкладок, UI-компоненты, сохранение, числовые/булевы/enum-поля, часть CFG генерации и подсказок реализованы в исходниках. **Не реализован/не доказан единый end-to-end контракт CFG-групп, provenance и разрешения конфликтов источников**, нет полного schema-driven локализованного UI и внутриигровой приёмки. Не объявлять 100% coverage.

**Архитектурные ссылки:** EN-A5 (схема/валидатор CFG), EN-A7 (режимы/категории), DA-07 (миграции/default/reset), DA-08 (смена профиля/поля), DA-01/DA-02/DA-05/DA-06 (EventBus, revisions, demand-driven), EN-A4/AC-07 (UNKNOWN→STOP), UI-01/UI-02 (отображение/подсветка), `RotationProfiles`, `RotationSettings`, `RotationEngine`, `Settings`, `IndicatorSettings`, `AppearanceProfiles`, `UI/Pages/RotationAbilities`. **Ретроактивные уточнения UI-03 добавлены в EN-A5, EN-A7, DA-07, DA-08, UI-01 и UI-02 в том же коммите**; старый аудит не удалён.

**Изменения Lua:** отсутствуют. Только аудит/документация; Lua 5.1, GitHub Actions и WoW Forever не запускались. Итог GitHub — документальный commit, без CLAIM реализации.

**Ретроактивное уточнение UI-04:** именованные пресеты для спека/контента и импорт/экспорт должны использовать единый CFG resolver UI-03 и его provenance/conflict policy; UI-04 управляет только снимками валидированных пользовательских overrides, не создаёт второй schema-driven интерфейс и не обходит UNKNOWN при конфликте.

**Ретроактивное уточнение UI-05:** три пользовательских режима `COMBAT_ONLY|TARGET_ONLY|ALWAYS` отображаются в общем окне настроек через существующий Settings-владелец и единый CFG/UI контракт; legacy `showInCombat/showOutOfCombat/requireTarget` мигрируются с явной обработкой неоднозначностей. Не создавать вторую независимую панель настройки видимости.

**Ретроактивное уточнение UI-06:** поддержка объяснений «почему нет иконки» использует существующую локализацию/tooltip UI-03 и типизированный `reason` registry; diagnostic presentation не создаёт второй CFG editor и не меняет owner настроек.

**Ретроактивное уточнение UI-07:** все label/tooltip/group/error keys schema-driven CFG должны регистрироваться в едином каталоге `KordRotation/Core/Locale.lua` и проходить аудит ключей/шести языков UI-07. Нельзя создавать отдельный `BM_CFG_*` словарь с неподтверждёнными заглушками как обход общего контракта.

**Выбранный путь Kord**

**Выбранный путь Kord**

**Канонический вариант: расширить существующие `RotationProfiles.Config` (схема), `RotationSettings` (единый `ResolveConfigField/NormalizeConfig` и запись), `RotationEngine` (потребитель того же результата) и `UI/Pages/RotationAbilities` (presentation); сохранить `Settings/IndicatorSettings/AppearanceProfiles` владельцами своих namespaces. Новый `CFGManager`, параллельный settings engine или второй интерфейс не создавать.** Вся нормализация и конфликтная политика — один контракт, а не независимые проверки UI/engine. Возможная реализация логическими методами существующих файлов; не требовать нового Lua-файла без доказанной необходимости. Схема immutable registration snapshot; locale-таблицы только presentation. Профиль задаёт допустимые значения, игрок — explicit override; preset оформления никогда не изменяет `Config` активного боевого профиля. `RotationSettings:GetActiveModule` и `RotationProfiles:Get` выбирают namespace только по проверенным identity/spec/level, а `GetModuleConfigValue` возвращает для UI структурированный result с причиной/источником, не только bare value; существующий bare getter может быть совместимым фасадом, если неизменно читает тот же resolver.

**Разделить три независимые категории конфликтов:** (1) конфликт двух сохранённых значений одного `profileID/key` (canonical vs legacy) → UNKNOWN и read-only field до миграции; (2) конфликт области global/character/appearance → namespace mismatch с явной policy, без копирования; (3) UI-дубль одного семантического ключа в двух вкладках → один setter и synchronized refresh, **не** два значения. Общие параметры панели и показатели glow: `panel.highlightMain` — оформление собственной иконки, `indicators.actionHighlight` — намерение подсветки actionbar (UI-02); это не конфликт, а разные функции. `defensiveInCombatMain` в Advanced/Indicators — один настоящий ключ. Состояние разных профилей, level variants, PvE/PvP должно оставаться изолированным. Неподтверждённый `spellID`, itemID, auraID для UI-03 **не нужен**: CFG — типизированная форма, не доступность конкретной способности.

Генератор должен строить `group/order` только по валидированным schema metadata, выбирать безопасную общую группу/порядок при отсутствии метаданных, использовать существующие UI-компоненты и `KR:L`/шесть локалей, показывать при unresolved profile `UNKNOWN` без stale widget; display-only `NOT_APPLICABLE` не влияет на combat READY. `sourceScope` явно отражает, что `moduleConfigs` принадлежит сохранённому class/spec/profile, а значение предустановки не является профильной опцией. Следующие изменения — исключительно через общий setter с результатом `ok/reason/revision`; EventBus/DA-01, DA-02, DA-05, DA-06, DA-08 инвалидируют только необходимые представления, without UI polling. Секреты не читать из конфигурационных значений без проверки; protected WoW UI APIs не вызывать, spell-use и eligibility — только в своих существующих контрактах. Если существенный CFG конфликт влияет на Evaluation, `UNKNOWN→STOP` (AC-07/EN-A4); окно не имеет права заменять conflict runtime дефолтом «для удобства».

**Требуемые изменения (полный текст)**

**Требуемые изменения**

1. Зафиксировать в `Configuration_Registry.md` владельца/scope/consumer каждого существующего общего и профильного поля (включая `defensiveInCombatMain`, `panel.highlightMain`, `indicators.actionHighlight`), `Config` группы, tooltip keys, шесть локалей, migration policy; не объявлять TODO подтверждёнными ключами.
2. В `RotationProfiles` расширить валидацию **необязательных** `group/order/tooltip/visibleWhen/enabledWhen`, если они нужны; значения и ссылки должны быть data-only, без функций из SavedVariables. Уточнить `schemaRevision`/fingerprint и immutable registration snapshot; не менять контракт профиля без version bump.
3. В `RotationSettings` централизовать `ResolveConfigField` и `NormalizeConfig`: типизированные `READY/UNKNOWN/BLOCKED/NOT_APPLICABLE`, `effectiveValue/source/sourceScope/overrideState/reason/revisions`; сравнивать `saved.moduleConfigs[profile.id]` и исторический `saved.config` до миграции и не терять конфликтующее значение.
4. Согласовать `RotationEngine:config(profile,saved)` и `RotationSettings:GetModuleConfigValue` с единой функцией нормализации EN-A5; исключить расхождение runtime vs UI, особенно при legacy fallback, `false`, `0`, NaN/Infinity и смене версии. Факт `UNKNOWN` критичного CFG не подменять боевым READY.
5. Доработать `RotationAbilities:rebuildModule`: отдельная revision-aware проверка schema vs values, группировка по стабильным group/order, bool/number-slider+input/enum controls, disabled reason, source/default badges текстом, explicit reset одного поля; избегать удаления фокуса или записи после смены профиля. Скрытые/условные элементы показывать согласно подтверждённым dependencies, unknown dependency не превращать в false без обозначения причины.
6. Подключить `UI:ShowSettingTip` и новый schema-aware tooltip resolver: использовать реальные label/tooltip locale keys для всех классов/веток, не `BM_CFG_*` для любого profile; показать цель, диапазон/варианты, default, effective source, конфликт и причины disabled; динамические тексты экранировать и не логировать secret.
7. Привести UI-схемы `Settings`, `IndicatorSettings`, `AppearanceProfiles` к явному owner mapping без переноса данных; связать два представления `defensiveInCombatMain` с одним setter; не связывать ложным alias glow и highlightMain. Все reset/migration действия делегировать DA-07.
8. При `settingsRevision`, смене active profile/level/talents (DA-08), смене языка, reset и legacy migration сбросить неверные controls/state; использовать EventBus revision subscriptions/coalescing, без нового OnUpdate или сканирования всех Needs. Установить ограниченный refresh budget и проверить reentrancy.
9. DevTools-only: `cfg_schema_loaded`, `cfg_field_source`, `cfg_override_active`, `cfg_value_invalid_defaulted`, `cfg_source_conflict`, `cfg_scope_ambiguous`, `cfg_migration_pending`, `cfg_dependency_unknown`, `cfg_write_rejected`, `cfg_stale_revision`, `cfg_ui_translation_missing`, `cfg_ui_rebuild`, `cfg_ui_refresh`; логировать лишь ID/тип/status/reason/revision, не пользовательские значения и не frame refs.
10. Тесты: все `bool/number/enum` и границы, negative/NaN/Infinity/строка, `false/0`, empty override, equal-to-default explicit override, duplicate keys, invalid group/order, missing tooltip/locale, unknown enum, partially populated schemas, large schema до лимита 128, отсутствующий профиль, смена class/spec/level/profile version, reload/migration, legacy-only, canonical-only, equal canonical+legacy, **conflicting canonical+legacy**, раздельные account/char/appearance scopes, profile-specific PvE/PvP, two-tab same key, two names same meaning but different owner, reset single/rotation/all, invalid write rollback, language switch all six, tooltip and UI value-runtime cfg parity, hidden/disabled dependency, combat protected/secret, event storm 1000, invalidation mid-render, no periodic GameAPI scan, Lua 5.1 и WoW Forever in-game QA.

**Тесты и диагностика**

в файле не указано

**Архитектурные и обратные ссылки:** DA-01, DA-08, AC-07, UI-02, DA-02, DA-05, DA-06, DA-07, UI-01, UI-04, UI-05, UI-06, UI-07.

---

### UI-04 — Профили настроек для спека и контента, импорт, экспорт

ID: [UI-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L8023). Приоритет: P2. Lua: упомянут (точный статус в источнике).

**Вердикт / статус**

**Вердикт**

**ЧАСТИЧНО РЕАЛИЗОВАНО / P2 / НЕ ГОТОВО К ИМПОРТУ:** у Kord уже есть per-class/tree настройки ротации, отдельные именованные профили оформления и auto-spec оформление. **Нет доказанного полного named rotation settings preset + content binding + bounded data-only import/export + preview/atomic rollback.** Реализация требует отдельного согласования по правилам разработки Lua; данный аудит не меняет исполняемые файлы. Все игровые тесты NOT RUN.

**Архитектурные ссылки:** UI-03 (единый CFG UI resolver и source conflicts), EN-A5 (типизированная immutable schema), EN-A7 (режимы/категории), DA-07 (storage/migration/reset/transaction), DA-08 (spec/level switching), DA-01/DA-02/DA-05/DA-06 (revisions, invalidation, performance), UI-01/UI-02 (stale presentation), AC-07/EN-A4 (UNKNOWN→STOP), `RotationSettings`, `RotationProfiles`, `RotationEngine`, `AppearanceProfiles`, `Settings`, `Configuration_Registry.md`. **Обратные уточнения внесены в UI-03, EN-A5, DA-07, DA-08, EN-A7, UI-01 в том же коммите.** Не вводится новый универсальный механизм для UI-02 и независимых индикаторов, поэтому ложные обратные ссылки не добавляются.

**Изменения Lua:** отсутствуют. Только документация. Статический аудит ZIP/source выполнен; Lua 5.1/CI/WoW Forever не запускались.

**Ретроактивное уточнение UI-05:** `visibilityMode` — глобальная пользовательская UI-настройка, не поле исполняемого rotation Config. Пресеты UI-04 не переносят её неявно; если в будущем разрешён экспорт UI-настроек, требуется отдельный явный whitelist и scope. Единый resolver видимости остаётся в UI-05.

**Ретроактивное уточнение UI-07:** имена пользовательских пресетов остаются пользовательскими данными, а названия content types, действия import/export, конфликты и validation reasons UI-04 используют общий стабильный locale key registry UI-07; не сериализовать переведённый текст как идентификатор.

**Выбранный путь Kord**

**Выбранный путь Kord**

**Каноническое решение — расширить `RotationSettings` логическим менеджером `SettingsPreset`, использовать `RotationProfiles.Config` и общий UI-03 resolver для validation, `DA-07` для storage/migration/atomic commit, `DA-08` для spec binding, а `UI/Pages/IndicatorsProfiles.lua`/существующее окно для отдельной секции «Профили настроек».** Не создавать второй `RotationEngine`, универсальный импорт исполняемых rotation rules или дублирующий `Config` registry. `AppearanceProfiles` сохраняет собственные пресеты и auto-spec mapping: при необходимости объединять **только UI-навигацию**, а не payload и ключи. Один data-only transport codec должен быть переиспользуем для будущих безопасных пользовательских конфигураций, но не должен принимать Lua функции, protected refs или игровые snapshots. Сам факт сериализации не делает payload пригодным для runtime.

**Иерархия выбора:** verified class/spec → ручной contentKey → explicit assigned presetID → валидированный snapshot через UI-03 resolver → immutable defaults EN-A5. Применять только настройки, которые поддерживает текущий profileID/schemaVersion; при несовместимости выдавать `UNKNOWN`/preview, не записывать частично. Для `contentKey=general` разрешён документированный fallback, но не автоматический выбор `pvp` или `raid` по предположению. Назначения/выбор отдельно от данных пресета; замена пресета не изменяет правила/ранги/идентичность. EventBus revision + coalescing без polling; critical CFG conflict не подменять READY. `P2` означает отложенный функционал, **не** разрешение небезопасного импорта.

**Требуемые изменения (полный текст)**

**Требуемые изменения**

1. Создать в `Configuration_Registry.md` точную таблицу разрешённых экспортируемых полей, владельцев `RotationSettings/Config`, scopes, spec/content bindings, default, migration и locale keys. Исключить appearance, DevTools, identity, raw GameState и секретные/персональные поля.
2. Определить версионированную data-only `SettingsPreset` и `KORDCFG1` envelope с фиксированным whitelist, каноническим порядком полей, лимитами depth/size/entry count/name и детерминированным checksum; проверить реализацию кодека на Lua 5.1. Ни `loadstring`, ни eval-подобного десериализатора.
3. Расширить `RotationSettings` методами `ListPresets/CreatePreset/CopyPreset/RenamePreset/DeletePreset/GetAssignedPreset/AssignPreset/ResolvePreset/PreviewImport/CommitImport/ExportPreset` как **логическими контрактами** в существующем модуле, без требования нового файла; нормализация CFG — только UI-03/EN-A5.
4. Разделить per-character и account presets и mappings; определить приоритеты, конфликты имён и IDs, delete активного/назначенного пресета, orphaned bindings, reset, migration и schema downgrade. Не допускать неявного смешения с `AppearanceProfiles`.
5. Построить в существующем UI список, spec/content выбор, создание/копирование/переименование/удаление, назначение и переключение, read-only preview изменений, export copy text и import paste text с явными кнопками `Create new/Replace/Cancel`. Никакого silent overwrite и скрытой автоматической активации после импорта.
6. Добавить двухфазный импорт: parse→validate→preview/diff→confirm→atomic apply/rollback. Отклонять неверный префикс, неизвестную версию, испорченный checksum, oversized payload, глубину, метатаблицы, неизвестные ключи, несовместимые class/spec/profileID, невалидные enum/number/bool, duplicate IDs и stale revision. Ошибка одного поля не должна оставлять половину применённых значений.
7. При смене спека/уровня/active profile (DA-08) инвалидировать устаревшее назначение, проверять applicability и optional auto-apply; при UNKNOWN — оставить данные без записи и уведомить пользователя. При смене contentKey требовать ручного выбора, пока не доказан game context provider; не переключать конфигурацию внутри боевой операции без проверенного safe path.
8. Интегрировать EventBus `settingsRevision` и coalescing DA-06: после применения обновлять UI-03, runtime cfg и UI-01/UI-02, очищать stale presentation. Не трогать actionbar bindings, spell eligibility, защищённые frames и DevTools-only state.
9. DevTools-only диагностика: `preset_created`, `preset_assigned`, `preset_applied`, `preset_spec_unknown`, `preset_content_manual_required`, `preset_import_format_invalid`, `preset_import_version_unsupported`, `preset_import_size_exceeded`, `preset_import_checksum_invalid`, `preset_import_unknown_key`, `preset_import_conflict`, `preset_import_rollback`, `preset_stale_revision`, `preset_export_success`; только ID, статус, reason, schema/revision и счётчики, без текста экспорта/значений/имён персонажей.
10. Тесты: создание/копия/rename/delete, одинаковые имена, пустое/слишком длинное/управляющие символы имя, account/char, два спека одного класса, два контента одного спека, разные классы, PvE/PvP, general fallback, unknown spec, content auto-detection UNKNOWN, несуществующий presetID, stale assignment, одинаковые и конфликтующие override, `false/0`, enum/number min/max/NaN/Infinity, 128 CFG keys, incompatible schema versions, legacy migrations, partial import rollback, malformed Base64, truncated/corrupted/oversized/deep/duplicate payload, checksum tamper, malicious Lua string, repeat import, replacement confirmation/cancel, combat restrictions, import/export roundtrip and deterministic export, 6 locales, reload, event storm, no polling, Lua 5.1, WoW Forever in-game and two build variants.

**Тесты и диагностика**

в файле не указано

**Архитектурные и обратные ссылки:** DA-07, UI-03, DA-08, DA-06, UI-01, UI-02, DA-01, DA-02, DA-05, AC-07, UI-05, UI-07.

---

### UI-05 — Режимы показа: только в бою, только с целью, всегда

ID: [UI-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L8091). Приоритет: P1. Lua: упомянут (точный статус в источнике).

**Вердикт / статус**

**Вердикт**

**ЧАСТИЧНО РЕАЛИЗОВАНО / P1 / ТРЕБУЕТ УНИФИКАЦИИ.** Kord уже умеет скрывать/показывать основную панель по combat/target через сочетание boolean-флагов, а defensive имеет отдельную политику. Но взаимоисключающий трёхрежимный контракт, migration конфликтов, корректное разделение combat/lockdown и end-to-end QA **не подтверждены**. Аудит документальный; Lua/CI/WoW Forever не запускались.

**Архитектурные ссылки:** UI-01, UI-02, UI-03, UI-04, DA-01/DA-02/DA-04/DA-05/DA-06/DA-07/DA-08, EN-A5, AC-07, `Settings`, `RotationDisplay`, `IndicatorSettings`. **Обратные уточнения внесены в UI-01, UI-02, UI-03, UI-04, DA-07, DA-08.** Не изменяется контракт `RotationEngine`/Eligibility и не создаётся второй движок.

**Изменения Lua:** отсутствуют. Только документация. Референсы проверены статически, runtime NOT RUN.

**Ретроактивное уточнение UI-06:** при скрытой main-панели первым объяснять проверенную причину `DisplayVisibilityPolicy` (UI-05), а не ошибочно сообщать «ротация не работает». `RecommendationAbsenceExplanation` UI-06 соединяет готовые статусы видимости, engine и presentation без повторного опроса API.

**Ретроактивное уточнение UI-07:** `COMBAT_ONLY|TARGET_ONLY|ALWAYS` — непереводимые внутренние enum, UI label/tooltip и legacy conflict explanations — единые ключи UI-07 на шести языках. Не сохранять текст текущего языка вместо enum.

**Ретроактивное уточнение UI-08:** `DisplayVisibilityPolicy` UI-05 управляет только собственной main-панелью Kord; скрытие Blizzard/Bartender/Dominos/ElvUI actionbar не скрывает main автоматически. UI-08 определяет независимую видимость и пригодность кнопок для keybind/glow.

**Выбранный путь Kord**

**Выбранный путь Kord**

**Единый `DisplayVisibilityPolicy` как чистый логический resolver внутри существующего `RotationDisplay` (либо общего UI policy, только если он реально переиспользуется) + один enum `Settings.panel.visibilityMode`.** Не создавать второй runtime state machine, EventBus, профильный CFG или отдельный combat provider. Использовать DA-01/DA-02 revision и event invalidation, UI-03 для контролов/подсказок, DA-07 для migration. `ShouldShow()` должен быть единственным consumer результата policy для main; defensive имеет отдельный consumer и не зависит от скрытия main. Изменение видимости не заменяет READY/STOP. Если одновременно присутствуют legacy и новое значение, после успешной миграции **новое** каноническое значение является единственным источником; конфликт до миграции — UNKNOWN, не silently override.

**Требуемые изменения (полный текст)**

**Требуемые изменения**

1. В `Settings.lua` добавить типизированный `visibilityMode` с валидацией и единым getter/setter; исключить прямую конкурентную запись legacy-флагов после миграции.
2. Реализовать DA-07 migration table для всех восьми сочетаний трёх legacy boolean; явно конфликтные комбинации не переводить автоматически с потерей смысла, хранить исходные значения до выбора пользователем.
3. В `RotationDisplay.lua` централизовать `DisplayVisibilityPolicy`, разделить `playerCombat` и `InCombatLockdown`, fail-closed при UNKNOWN обязательных фактов и сохранять независимые master/dead/mounted/test gates.
4. Согласовать событийные invalidations combat/target/death/mount с EventBus, без второго poller; исключить stale видимость после `PLAYER_TARGET_CHANGED`, `PLAYER_REGEN_*`, `UNIT_FLAGS`, смены настроек.
5. В существующем окне настроек создать один enum selector с тремя вариантами, подсказками, статусом migration/conflict и переводами на шесть языков; не дублировать ручные boolean controls.
6. Сохранить независимость `ShouldShowDefensive`, маршрутизации defensive, interrupt/resource/test UI и UI-01 прогнозов; при скрытии main не переносить defensive в основной frame.
7. При смене видимости очистить старый glow и недостоверные keybinds (UI-02), не делать actionbar protected writes и не выдавать пустые placeholder за READY.
8. Добавить DevTools-only `visibility_mode_changed`, `visibility_combat_unknown`, `visibility_target_unknown`, `visibility_legacy_conflict`, `visibility_stale_revision`, `visibility_main_hidden` с mode/reason/revision без персональных данных и без production recorder.
9. Тесты: три режима × combat true/false/UNKNOWN × target true/false/UNKNOWN; target дружественная/враждебная/мертвая/потерянная; начало боя без цели; цель вне боя; `ALWAYS` до первого target и после потери target; mount/death/test/master flags; defensive независимо от main; hidden main без переноса иконок; READY/PREDICTED/UNKNOWN, stale glow; legacy все 8 комбинаций, conflict/rollback, reload; смена спека и UI-04 presets; coalescing/event storm; six locales; Lua 5.1 и WoW Forever in-game.
10. Зафиксировать политику затрат: скрытая main не вызывает дополнительную полную оценку движка только ради оболочки; defensive и другие действительно активные потребители могут запрашивать независимую оценку через общий engine без дублирования. Измерить DA-04 и DA-05, проверить обе сборки.

**Тесты и диагностика**

в файле не указано

**Архитектурные и обратные ссылки:** UI-01, DA-07, DA-04, DA-05, DA-01, DA-02, UI-03, UI-02, UI-04, DA-06, DA-08, AC-07, UI-06, UI-07, UI-08.

---

### UI-06 — Индикация причины: почему нет иконки (для отладки и поддержки)

ID: [UI-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L8159). Приоритет: P1. Lua: упомянут (точный статус в источнике).

**Вердикт / статус**

**Вердикт**

**ЧАСТИЧНО РЕАЛИЗОВАНО / P1 / НЕТ ПОЛНОГО USER-FACING EXPLANATION.** Engine уже выдаёт reason/status, RotationDisplay хранит последнюю причину и агрегаты, DevTools умеет opt-in trace. Не доказаны единая приоритетная причина отсутствия иконки, шесть локалей для reason registry, поддержка скрытой панели и защита от stale explanation. Документация аудита завершена; Lua/CI/WoW Forever NOT RUN.

**Архитектурные ссылки:** UI-01 (пустая иконка/очередь), UI-02 (keybind/glow), UI-03 (локализация/UI), UI-05 (видимость), DA-01/DA-02/DA-03/DA-04/DA-05/DA-06/DA-08, AC-07 (STOP), EN-A2/EN-A3/EN-A4, `RotationEngine`, `RotationDisplay`, `AbilityEligibility`, `Diagnostics`, `KordRotationDevTools/Trace.lua`. **Обратные ссылки добавлены в UI-01, UI-02, UI-03, UI-05, DA-03, AC-07** там, где старые механизмы должны переиспользовать новый presentation adapter; нет замены Eligibility или engine.

**Изменения Lua:** отсутствуют. Только документация.

**Ретроактивное уточнение UI-07:** все `RecommendationAbsenceExplanation.reason` UI-06 отображаются через единый reason→locale key registry UI-07; технические коды остаются стабильными непереводимыми значениями, при отсутствии перевода используется проверенный fallback без ложного объяснения.

**Ретроактивное уточнение UI-08:** объяснение UI-06 различает отсутствие рекомендации и недоступность отображения keybind/glow из-за скрытой/неподтверждённой actionbar-кнопки; коды `button_not_visible|no_confirmed_visible_button|button_slot_unconfirmed|dynamic_routing_unverified` берутся из существующих providers UI-08, без нового API-опроса ради tooltip.

**Ретроактивное уточнение QA-01:** пользовательское «почему нет иконки» остаётся компактным read-only explanation, а подробная трасса по evaluationID/reason/priority — в отдельном DevTools QA-01, через безопасный observation bridge. Никакой зависимости пользовательской сборки от DevTools.

**Ретроактивное уточнение QA-02:** `RecommendationAbsenceExplanation` UI-06 берёт полный verified primary/subreason chain из безопасного `DiagnosticReasonEnvelope` QA-02, а не из усечённого списка `Recorder.lua`. Пользовательский summary остаётся коротким, полный список доступен только в opt-in DevTools.

**Выбранный путь Kord**

**Выбранный путь Kord**

**Канонический путь — единый read-only `RecommendationAbsenceExplanation` как presentation adapter существующих `RotationDisplay.lastEngineStatus/Reason`, `RotationEngine.diagnostics`, `DisplayVisibilityPolicy` UI-05 и `AbilityEligibility`/UI-02, с разделением user support summary и DevTools trace.** Не создавать второй evaluator, Eligibility, EventBus, combat/target provider, собственный журнал в пользовательской сборке или новую причину без подтверждённого источника. Данные потреблять из **одного актуального результата оценки**, не вызывать движок заново для tooltip. Критический UNKNOWN должен оставаться UNKNOWN. Объяснение при скрытой панели берётся из UI-05; при engine READY и отсутствии texture — presentation failure; при disabled profile — profile reason. Один registry reason→locale keys, source/revision; unknown code отображать как безопасное «Причина пока не определена» плюс буквальный ограниченный technical code.

**Требуемые изменения (полный текст)**

**Требуемые изменения**

1. Ввести типизированный `RecommendationAbsenceExplanation` и единую таблицу приоритета причин `visibility→not_evaluated→profile→engine→eligibility→presentation` с явным `channel` и bounded secondary reasons. Не изменять структуру/порядок вычисления правил движка.
2. Использовать уже имеющиеся `RotationEngine.status/reason/diagnostics` и `RotationDisplay.lastEngineStatus/lastEngineReason/lastSummary`; дополнить только недостающий bounded snapshot, не хранить сырые GameState/secret/protected values.
3. Подключить UI-05 `DisplayVisibilityPolicy` как единственный источник причин скрытия main; независимый defensive channel и его `lastDefensiveReason` не переносить в main.
4. В user UI добавить доступное при скрытой панели «Почему нет иконки?», короткую причину и копируемый технический код; при видимой пустой панели разрешить tooltip без навязчивого overlay. Различать `HIDDEN`, `NOT_EVALUATED`, `UNKNOWN`, `BLOCKED`, `READY_NOT_VISIBLE`.
5. Создать versioned reason registry и `label/tooltip` на шести языках `ruRU/enUS/frFR/deDE/ptBR/esES`, fallback на безопасный общий текст и технический код, без фиктивных переводов. Причины GCD, ресурса, дистанции, cooldown, LOS и цели показывать только при реально подтверждённом eligibility reason.
6. Привязать snapshot к `settings/identity/target/combat/actionbar/bindings` revisions (DA-01/DA-02/DA-08), сбрасывать stale reason на смене профиля/спека/цели/режима и при `UNKNOWN` не оставлять старое «нет маны».
7. Для UI-01 и UI-02 различать «нет main recommendation» и «READY есть, но не удалось показать texture/keybind/glow»; не объявлять отсутствие keybind причиной отсутствия spell icon.
8. В DevTools добавить opt-in trace корреляции `evaluationID/revision/channel/priority/status/reason/source`, ограниченный размер/частоту и экспорт без персональных данных; пользовательская сборка содержит только последний безопасный summary, без Start/Stop и скрытого recorder.
9. Тесты: нет профиля, выключена ротация, неизвестный spec/level, auto AoE UNKNOWN, приоритетное condition UNKNOWN→STOP, condition_false, no_eligible_rule, категория disabled, недостаток ресурса подтверждённый/неподтверждённый, spell_visual_data_unverified, engine_exception, defensive независимо, 3 режима UI-05, target loss, смена спека, stale snapshot, READY без texture, glow/keybind missing, event storm, no repeated evaluation on tooltip, 6 locales, safe copy code, отсутствие секретных значений.
10. Проверить производительность DA-04/DA-05, отсутствие повторных API-read и двойных логгеров, совместимость Lua 5.1/WoW Forever, обе ZIP-сборки с побайтово общим `KordRotation/`, и то, что user addon не получает DevTools-only export/recording.

**Тесты и диагностика**

в файле не указано

**Архитектурные и обратные ссылки:** UI-05, UI-02, AC-07, DA-01, DA-02, DA-08, UI-01, DA-04, DA-05, UI-03, DA-03, DA-06, UI-07, UI-08, QA-01, QA-02.

---

### UI-07 — Локализация (ru, en), единые ключи

ID: [UI-07](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L8229). Приоритет: P1. Lua: упомянут (точный статус в источнике).

**Вердикт / статус**

**Вердикт**

**ЧАСТИЧНО РЕАЛИЗОВАНО / P1 / ШЕСТИЯЗЫЧНЫЙ КАТАЛОГ ЕСТЬ, ПОЛНОЕ ПОКРЫТИЕ НЕ ДОКАЗАНО.** У Kord уже есть `KR:L/KR:Format`, шесть языков и отдельный DevTools locale. Обнаружены generic placeholder-подсказки и динамические ключи, для которых не подтверждён полный coverage/semantic review. Статический аудит выполнен; исчерпывающий поэлементный игровой QA и точные проценты покрытия **не выполнены**.

**Архитектурные ссылки:** UI-01/UI-03/UI-04/UI-05/UI-06, DA-07, EN-A5, `KordRotation/Core/Locale.lua`, `KordRotationDevTools/Locale.lua`, `AdvancedDiagnostics.lua`, `RotationAbilities.lua`, `AGENTS.md`. **Обратные уточнения внесены в UI-01, UI-03, UI-04, UI-05, UI-06, DA-07**: существующие интерфейсы и будущие механизмы должны пользоваться единым ключевым каталогом, без второго runtime resolver.

**Изменения Lua:** отсутствуют. Только документация.

**Ретроактивное уточнение UI-08:** пользовательские сообщения о скрытой панели, неподтверждённой кнопке и неподтверждённой привязке используют единые `REASON_*`/`TIP_*` ключи UI-07 на шести языках; имена Bartender/Dominos/ElvUI и технические коды не локализуются.

**Ретроактивное уточнение QA-01:** `KordRotationDevTools/Locale.lua` физически отдельный от пользовательского `Locale.lua`; оба проходят шестиъязычную валидацию UI-07, но DevTools-only тексты не попадают в user ZIP (QA-01).

**Выбранный путь Kord**

**Выбранный путь Kord**

**Канонический механизм — сохранить `KordRotation/Core/Locale.lua` + `KR:L/KR:Format` как единственный пользовательский runtime resolver, добавить проверяемый каталог ключей/статусов и статический валидатор; DevTools сохраняет отдельный словарь, но использует те же критерии валидации.** Не создавать второй localization provider, не внедрять AceLocale, не сохранять переведённые значения вместо enum/reason. Схемы UI-03, пресеты UI-04, режимы UI-05 и причины UI-06 **обязаны переиспользовать** этот registry. При появлении новых общих UI-параметров регистрировать ключи/подсказки в том же каталоге до объявления функционала завершённым. Проверка должна охватывать оба варианта сборки и исключать developer-only тексты из user addon.

**Требуемые изменения (полный текст)**

**Требуемые изменения**

1. Составить исчерпывающий registry всех пользовательских ключей и динамических фабрик из Lua/UI/CFG/reason enums, с owner, source file, параметрами format и статусом `TRANSLATED|PLACEHOLDER|MISSING|INVALID|UNUSED` по шести языкам.
2. Автоматизировать извлечение `KR:L/KR:Format/UI:ShowSettingTip` и enumerate динамические `BM_CFG_*`, `TIP_BM_CFG_*`, `ROT_CAT_*`, `BM_CHOICE_*`, `REASON_*` по зарегистрированным значениям. Ложный PASS по одним строковым литералам запрещён.
3. Сохранить `enUS` fallback и `ruRU` обязательную базу; обеспечить полный перевод `frFR/deDE/ptBR/esES` согласно AGENTS. Обоснованно документировать locale aliases и отсутствие поддержки неизвестных локалей.
4. Устранить шаблонные, неточные, устаревшие подсказки, особенно `TIP_*` с generic filler и ложными утверждениями «engine not active», когда код уже реализован частично; каждый tooltip должен описывать **фактическую** функцию, ограничения и статус.
5. Проверять сигнатуры `string.format` для каждого ключа и языка (`%s/%d/%%`, positional formats, количество и типы аргументов), отсутствие некорректного UTF-8, неэкранированного markup, пустых/дублирующихся ключей.
6. Добавить `REASON_*` для UI-06, `VISIBILITY_*` для UI-05, `PRESET_*` для UI-04, schema-driven label/tooltip UI-03, без дублирования уже существующих смысловых ключей.
7. Определить инвалидацию/refresh созданных виджетов при смене `Advanced.language`, включая tooltip, dynamic CFG rows, вкладки, окна подтверждения и пользовательскую диагностику; никакой смены сохранённых машинных значений.
8. В DevTools валидировать отдельный `D:L/D:Format` каталог тем же CI-контрактом, но без общего runtime зависимости; user ZIP не должен содержать developer-only команды/тексты/recorders.
9. Создать отчёт покрытия по каждой локали с количествами `total/translated/placeholder/missing/invalid`, списком конкретных source locations и fail CI на missing/invalid; не объявлять «100%», пока не проведён ручной semantic review.
10. Тесты: все 6 локалей и alias, неизвестная локаль, missing base key, format mismatch, duplicate key, long strings/line wrap, Cyrillic/UTF-8, dynamic enum/reason keys, переключение языка при открытом UI, tooltip каждого элемента, окно импорта/сброса, main/defensive/diagnostics, обе ZIP, Lua 5.1, WoW Forever. Отдельный PASS по source inventory и NOT RUN по клиенту до реального QA.

**Тесты и диагностика**

в файле не указано

**Архитектурные и обратные ссылки:** UI-03, UI-04, UI-05, UI-06, UTF-8, UI-01, DA-07, UI-08, QA-01.

---

### UI-08 — Реакция на скрытие панелей и аддоны панелей (Bartender, Dominos, ElvUI и др.)

ID: [UI-08](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L8293). Приоритет: P1. Lua: упомянут (точный статус в источнике).

**Вердикт / статус**

**Вердикт**

**ЧАСТИЧНО РЕАЛИЗОВАНО / P1 / ИМЕЕТСЯ READ-ONLY ОСНОВА, НЕТ ПОДТВЕРЖДЁННОГО END-TO-END QA.** Scanner и binding resolver уже знают основные сторонние панели и безопасно проверяют видимые кнопки; остаются presentation lifecycle, все сценарии Hide/Show/paging и игровой QA. Не заявлять полную поддержку без тестов на WoW Forever.

**Архитектурные ссылки:** UI-01, UI-02, UI-05, UI-06, UI-07, DA-08, `ActionBarScanner`, `BindingResolver`, `RotationDisplay`, `docs/STAGE_02_05_ACTIONBAR.md`, `docs/STAGE_02_06_BINDINGS.md`. **Обратные уточнения внесены в UI-01, UI-02, UI-05, UI-06, UI-07, DA-08.** Никакого нового engine, Eligibility или второго scanner.

**Изменения Lua:** отсутствуют. Только документация.

**Ретроактивное уточнение QA-02:** для скрытых actionbar кнопок и сторонних панелей UI-08 записывать полный структурный chain `visibility→button→slot→binding→glow` только по реально наблюдённым фактам, с source/revision, без второго scanner и без raw frame refs.

**Выбранный путь Kord**

**Выбранный путь Kord**

**Единый `ActionBarPresentationState` как тонкий read-only адаптер поверх уже существующих `ActionBarScanner` и `BindingResolver`; повторное использование EventBus revisions/TTL.** UI-02 получает из него допустимость keybind/glow, UI-06 — объяснение, UI-05 остаётся независимой политикой видимости собственной панели. Не создавать второй scanner/провайдер, не подключать Ace/LibActionButton принудительно, не hook protected foreign UI. При доказанном скрытии кнопки убрать подсветку и устаревшую подпись; при неизвестном состоянии — UNKNOWN, не выдумывать бинды/слоты.

**Требуемые изменения (полный текст)**

**Требуемые изменения**

1. Реализовать `ActionBarPresentationState` с `READY|UNBOUND|UNKNOWN|HIDDEN`, причиной, источником, spellID, slot, bindingLabel, glowEligible, revision/observedAt; не дублировать scanner.
2. Разделить видимость собственной панели Kord (UI-05) и чужих actionbar кнопок: скрытая чужая панель не скрывает main/defensive и не блокирует рекомендации.
3. Повторно проверять `IsVisible` и активный слот/SpellID перед отображением keybind/glow; учитывать parent Hide/Show и dynamic paging, fail-closed при protected/secret.
4. Подключить EventBus `actionbar/bindings/identity/talents`, доступные события смены страниц/форм/override и bounded TTL; не создавать второй частый polling loop.
5. Поддерживать обнаруженные семейства Blizzard, Bartender4, Dominos, ElvUI, EllesmereUI, LAB только через проверенные read-only API; при неизвестном custom UI возвращать UNKNOWN, не объявлять поддержку «всех аддонов».
6. При изменении видимости/slot/binding снимать старый glow и label, не оставлять stale overlay на скрытой/переиспользованной кнопке, не выполнять protected writes.
7. Для нескольких видимых кнопок одного SpellID использовать детерминированный приоритет подтверждённого binding route и актуального слота; не выбирать скрытую только потому, что она имеет меньший индекс.
8. В UI-06 объяснять отдельно `button_not_visible`, `no_confirmed_visible_button`, `button_slot_unconfirmed`, `dynamic_routing_unverified`, `binding_reverse_mismatch` без вывода «spell unavailable»; UI-07 шесть локалей.
9. DevTools opt-in trace: `actionbar_visibility_changed`, `actionbar_slot_changed`, `actionbar_binding_changed`, `actionbar_route_unknown`, `actionbar_glow_cleared`, source/revision без сырых frame refs, названий персонажей или protected данных. Production не пишет developer history.
10. Тесты: Blizzard/BT4/Dominos/ElvUI/EAB/LAB; Hide/Show child и parent; spell на двух кнопках, одна скрыта; paging/stealth/stance/override; addon load, отсутствие события и TTL; изменение клавиши и reverse mismatch; защищённый GetAttribute, secret IsVisible, отсутствующая библиотека; READY icon при скрытой actionbar; main/defensive независимо; stale glow/keybind cleanup; coalescing/event storm; Lua 5.1, обе ZIP, реальный WoW Forever с конкретными версиями аддонов.

**Тесты и диагностика**

в файле не указано

**Архитектурные и обратные ссылки:** UI-05, UI-02, UI-06, UI-07, UI-01, DA-08, QA-02.

---

