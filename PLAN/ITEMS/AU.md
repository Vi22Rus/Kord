# Карточки AU

Источник: REQUIREMENTS.md, blob 9efdec1900398c978ea121818fb5950cb1620337.

### AU-01 — Аура по spellID на игроке, цели, питомце, фокусе, члене группы: есть / нет

ID: [AU-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L2021). Приоритет: P0.

**Вердикт**

**Вердикт**

**ЧАСТИЧНО РЕАЛИЗОВАНО — ДОРАБОТАТЬ (P0).** Player helpful и target harmful по spellID уже есть, но нет полного набора юнитов/фильтров и достоверного отрицания для всех сочетаний.

**Выбранный путь**

в файле не указано

**Требуемые изменения (полный текст)**

**Требуемые изменения**

1. Расширить существующий `GameState`/aura provider до `ObserveAura(unitToken,spellID,filter,sourceFilter)` с строгим allowlist `player,target,pet,focus,party1..4,raid1..40` только где поддержано Forever. `focus` может отсутствовать в клиенте: проверять API и возвращать `UNKNOWN/unsupported`, не выдумывать unit.
2. Отдельно подтверждать `UnitExists` и `UnitGUID`; для меняющихся юнитов GUID до/после lookup; при смене/secret GUID — UNKNOWN. Кэш ключевать `unitGUID+spellID+filter+casterFilter` и инвалидировать по ревизиям.
3. Положительное `READY(true)` только при проверенном `aura.spellId==spellID`, корректном helpful/harmful и caster; для negative `READY(false)` требуется доказанное полное наблюдение и не-secret режим. Никаких nil→false в скрытом бою.
4. Сохранять source `C_UnitAuras.GetUnitAuraBySpellID`/`GetPlayerAuraBySpellID`/name lookup и `AuraCooldownViewer`/positive evidence; последним не разрешать подтверждать отсутствие без доказательной инвалидации.
5. `Needs.auras` расширить типизированными `unit/filter/caster` с lazy evaluation, без полного сканирования группы каждый тик; привязать к `RotationConditions` и `AbilityEligibility` как единственному READY арбитру.
6. Инвалидация `UNIT_AURA`, `PLAYER_TARGET_CHANGED`, `PLAYER_FOCUS_CHANGED`, `UNIT_PET`, `GROUP_ROSTER_UPDATE`, `PLAYER_ENTERING_WORLD` и соответствующих клиенту событий; не переиспользовать отрицательный кэш после смены unitGUID.
7. Тесты на player buff/debuff, target buff/debuff, pet, focus (если есть), party/raid, own-vs-any caster, разные ранги и spellID, пустой unit, unit сменился в середине чтения, secret-positive, secret-negative, no API, обновление/исчезновение ауры, повторные ID и производительность в рейде.

**Изменения кода:** не выполнялись; внесён аудит AU-01.


**Архитектурная актуализация AU-04:** **См. AU-04:** тип дебаффа/диспела и его снимаемость — дополнительные независимые факты того же общего `AuraPresenceObservation` из AU-01. Не создавать отдельный сканер аур для определения magic/poison/disease/curse/bleed; `canPlayerDispelNow` вычисляется отдельно из свойств способности, цели и eligibility.
**Архитектурная актуализация AU-02:** **См. AU-02:** длительность, expiration/remaining и число стаков — дополнительные независимые поля **того же** универсального `AuraPresenceObservation(unit,spellID,filter)`. Не создавать второй aura lookup/таймер/сканер для AU-02; использовать единый unitGUID, фильтры, secret-safe чтение, кэш и инвалидацию AU-01. Отсутствие подтверждённого времени или числа стаков не отменяет достоверного присутствия ауры.

**Тесты и диагностика**

в файле не указано

**Архитектурные и обратные ссылки:** NO-02, TG-11, TG-08, TG-07, AU-09, AU-08, AU-07, AU-06, AU-05, AU-02, PL-09, SP-14, AU-04.

---

### AU-02 — Длительность, остаток времени, число стаков

ID: [AU-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L2102). Приоритет: P0.

**Вердикт**

**Вердикт**

**ЧАСТИЧНО РЕАЛИЗОВАНО — ДОРАБОТАТЬ (P0).** Presence и API-примитивы есть, но независимых достоверных duration/remaining/stacks в Kord нет.

**Выбранный путь**

в файле не указано

**Требуемые изменения (полный текст)**

**Требуемые изменения**

1. Расширить результат AU-01 полями `durationSeconds`, `expirationTime`, `remainingSeconds`, `stacks` с независимыми статусами; единый spellID match, caster filter, unitGUID guard и event revision.
2. Читать `duration`, `expirationTime`, `applications` из **того же подтверждённого AuraData** через `GameAPI.ReadField`; не повторять lookup и не сканировать ауры заново.
3. `remaining=max(0, expirationTime-GetTime())` только для подтверждённых конечных чисел и непостоянной ауры. Постоянную ауру обозначать `isPermanent=READY(true)`, `remaining` — не конечное число, без `math.huge`/99999 как фактического времени.
4. При отсутствии/секретности поля возвращать `UNKNOWN` именно для него. Установить правила нормализации `applications` (включая 0/1) по подтверждённому поведению Forever, не принудительно `max(1,stacks)` без основания.
5. Разделять `observedRemaining` и `estimatedRemaining` из combat log/профиля/истории; оценка не повышает статус до `READY`. Для `C_UnitAuras.GetAuraDuration` проверить формат и поддержку duration object на Forever.
6. Обновлять remaining по монотонному времени без повторного aura scan на каждый UI тик; сбрасывать при `UNIT_AURA`, смене GUID, caster, исчезновении ауры, переходе в secret mode.
7. Тесты: 1/2/5 стаков, отсутствие поля, duration=0 permanent, expiration=0, истечение и refresh, DoT/HoT на разных целях, pet/focus/party, чужой caster, rank/override, secret duration при видимом presence, задержка обновления, reload и invalid clock.

**Архитектурная ссылка:** **AU-01** — единственный общий aura provider. SP-12 (реактивные aura procs), SP-14 (требуемые/запрещённые ауры), PL-09 (классовые ауры) используют тот же источник; отдельные механизмы длительности для них не создавать.

**Изменения кода:** не выполнялись; внесён аудит AU-02 и актуализация AU-01.

**Тесты и диагностика**

в файле не указано

**Архитектурные и обратные ссылки:** AU-09, AU-07, AU-06, AU-01, AU-05, SP-12, SP-14, PL-09.

---

### AU-04 — Тип: магия, яд, болезнь, проклятие, кровотечение; можно ли снять

ID: [AU-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L2162). Приоритет: P1.

**Вердикт**

**Вердикт**

**ЧАСТИЧНО РЕАЛИЗОВАНО — ДОРАБОТАТЬ (P1).** Защищённое нахождение ауры есть, но тип и возможность снятия не определяются.

**Выбранный путь**

в файле не указано

**Требуемые изменения (полный текст)**

**Требуемые изменения**

1. В AU-01/AU-02 provider после подтверждённого `spellId` читать `dispelName` (и `debuffType` только если подтверждено API клиента) из **того же AuraData** через `GameAPI.ReadField`. `nil`/secret → UNKNOWN; не выдумывать `none`.
2. Типы `Magic/Poison/Disease/Curse` нормализовать по проверенному Forever API, сохраняя raw значение и статус. `Bleed` — **не** пятый стандартный тип диспела: классифицировать только по подтверждённой механике/каталогу; неизвестная аура → `isBleed=UNKNOWN`.
3. Отделить `dispelType` от `dispelPossibleByMechanic` и `canPlayerDispelNow`. Даже подходящий тип не доказывает, что эффект можно снять конкретным spellID; immunities, target restrictions и protected значения → UNKNOWN/BLOCKED по доказательствам.
4. Различать friendly cleanse, hostile purge/steal, self-only dispel, pet dispel; способности, снимающие несколько типов, и таланты/руны/ранги/override описывать декларативными данными, общая eligibility — единственная точка READY.
5. Повторно использовать AU-01 `unitGUID+spellID+filter+caster`, AU-02 duration/stacks, SP-02 ranks, SP-11 overrides, SP-14 target/requirements; `Needs` ленивый, без массового скана группы каждый тик.
6. Инвалидация `UNIT_AURA`, смены GUID, изучения способности/талантов, cooldown/resources и изменения protected state; диагностика `aura_dispel_type_unknown`, `bleed_unverified`, `dispel_eligibility_unknown`.
7. Тесты: magic/poison/disease/curse, bleed, nil type, hostile purge vs friendly cleanse, self/pet/party/raid, неснимаемая magic-аура, несколько доступных dispel-способностей, отсутствие ресурсов/кулдаун, secret type, смена цели, rank/override, отсутствие разрешённого API.

**Архитектурная ссылка:** AU-01 — общий reader, AU-02 — его duration/stacks, AU-04 — его dispel/bleed свойства; SP-14 и AbilityEligibility — проверка применимости способности. Не создавать отдельные aura scanners.

**Изменения кода:** не выполнялись; внесён аудит AU-04 и сноска в AU-01.

**Тесты и диагностика**

в файле не указано

**Архитектурные и обратные ссылки:** TG-07, AU-08, AU-05, AU-01, AU-02, SP-02, SP-11, SP-14.

---

### AU-05 — Поиск ауры по имени и семейству рангов, а не только по одному ID

ID: [AU-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L2219). Приоритет: P1.

**Вердикт**

**Вердикт**

**ЧАСТИЧНО РЕАЛИЗОВАНО — ДОРАБОТАТЬ (P1).** Name fallback существует, но самостоятельного name query и verified family match нет.

**Выбранный путь**

в файле не указано

**Требуемые изменения (полный текст)**

**Требуемые изменения**

1. Расширить интерфейс AU-01 до типизированного `query` без ломания `ReadSignal(field,spellID)`; совместимость через адаптер `kind="spellID"`.
2. `localizedName`: использовать локаль клиента и точный фильтр/caster, подтверждать `spellId` возвращённой AuraData; при одинаковом имени нескольких эффектов не выдавать неподтверждённый точный ID.
3. `rankFamily`: формировать набор **aura spellID** из проверенного каталога/связей SP-02/ForeverAuras, дедуплицировать, не включать посторонние ID по совпадению имени. Если семейство неполное, положительный результат допустим для подтверждённого члена, но отрицание всего семейства — UNKNOWN.
4. Сохранять `matchedSpellID` и matched AuraData; AU-02 duration/stacks и AU-04 dispelType должны относиться к тому же экземпляру. Для нескольких одновременно активных рангов предусмотреть явную стратегию `allMatches`/ambiguity, не выбирать «максимальный» без правила.
5. Секретный name/ID/instance/список, ошибка enumeration, смена GUID → UNKNOWN; nil name lookup в secret combat не доказывает отсутствия. `READY(false)` для family только при полном достоверном отрицательном наблюдении всех подтверждённых членов и полноте семейства.
6. Lazy `Needs` и кэш `unitGUID+queryKind+normalizedQuery+filter+caster`, инвалидировать `UNIT_AURA`, изменение unitGUID, каталога рангов и локали; не сканировать все ауры группы каждый тик.
7. Тесты: разные ранги одного баффа, одинаковое имя у разных эффектов, разные локали, чужая/своя аура, castID≠auraID, отсутствующий член семейства, неполное семейство, несколько совпадений, secret и GUID switch, duration/stacks/dispel на matched instance.

**Архитектурные ссылки:** AU-01 — единый reader; AU-02 — поля matched aura; AU-04 — тип matched aura; SP-02 — проверенные rank families. Соответствующие старые требования обновлены сносками на AU-05.

**Изменения кода:** не выполнялись; внесён аудит AU-05 и актуализированы AU-01, AU-02, AU-04, SP-02.

**Тесты и диагностика**

в файле не указано

**Архитектурные и обратные ссылки:** TG-08, TG-07, AU-09, AU-08, AU-06, AU-01, AU-02, SP-02, AU-04.

---

### AU-06 — Подсчёт моих DoT и дебаффов на нескольких целях

ID: [AU-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L2282). Приоритет: P2.

**Вердикт**

**Вердикт**

**НЕ РЕАЛИЗОВАНО КАК МНОГОЦЕЛЕВОЙ КОНТРАКТ — ДОРАБОТАТЬ (P2).** Есть только чтение одного target debuff и частичные исходные примитивы.

**Выбранный путь**

в файле не указано

**Требуемые изменения (полный текст)**

**Требуемые изменения**

1. Сначала обеспечить AU-01 multi-unit `nameplateN` (если поддерживается клиентом), GUID guard и проверенный `sourceUnit/sourceGUID`; AU-05 family query и AU-02 duration/stacks повторно использовать, а не дублировать.
2. Вести ограниченный GUID-index наблюдаемых целей с отдельными состояниями `confirmedActive`, `confirmedRemoved`, `stale/unknown`; при исчезновении nameplate или потере target **не** приравнивать к снятию DoT и не считать прошлое наблюдение текущим фактом.
3. Исследовать доступность `COMBAT_LOG_EVENT_UNFILTERED` и полей `sourceGUID/destGUID/spellID` в WoW Forever и secret combat. Event evidence использовать лишь в пределах доказуемой семантики, с ограниченным TTL и подтверждением; не превращать event APPLIED в бесконечный активный дебафф.
4. Проверять caster ownership: player отдельно от pet/guardian; `isFromPlayerOrPlayerPet` не доказывает player-only. Для неподтверждённого источника — UNKNOWN, не засчитывать как «мой».
5. Поддерживать агрегаты `uniqueTargetsWithAura`, `uniqueTargetsWithAnyMyDebuff`, `confirmedDebuffInstances`, `unknownTargets`, `coverage`; не путать count of enemies с count of DoT.
6. Ленивая агрегация по необходимым query, bounded memory/CPU, инвалидация при UNIT_AURA/nameplate add/remove, смене target/GUID, подтверждённом снятии, смерти/деспавне, истечении времени и изменении доступности secret данных.
7. Тесты: 1/2/5 врагов, два DoT на одной цели, один DoT на двух, ранги семейства, чужой DoT того же ID, player vs pet, потеря nameplate, target swap, reapply/refresh/remove, смерть, secret aura, CLEU недоступен, GUID reuse/изменение, невалидное duration, отсутствующие наблюдаемые цели.

**Архитектурные ссылки:** AU-01 — единый reader; AU-02 — длительность и стаки; AU-05 — запрос по семейству; AU-06 — агрегатор GUID. В AU-01, AU-02 и AU-05 внесены обратные сноски.

**Изменения кода:** не выполнялись; внесён аудит AU-06 и актуализированы связанные требования.

**Тесты и диагностика**

в файле не указано

**Архитектурные и обратные ссылки:** EN-06, EN-04, EN-03, EN-01, TG-06, AU-09, AU-08, AU-05, AU-01, AU-02.

---

### AU-07 — Проки и временные бонусы (таланты, экипировка, руны)

ID: [AU-07](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L2351). Приоритет: P1.

**Вердикт**

**Вердикт**

**ЧАСТИЧНО РЕАЛИЗОВАНО — ДОРАБОТАТЬ (P1).** Базовые aura/usability примитивы есть, общего происхождения и активного proc-контракта нет.

**Выбранный путь**

в файле не указано

**Требуемые изменения (полный текст)**

**Требуемые изменения**

1. Ввести общую типизированную декларативную таблицу `procDefinition`: `effectID`, `auraSpellIDs`, `triggerSource=talent/item/rune/other/unknown`, `sourceID`, `affectedSpellIDs`, `triggerEvidence`, `effectModifiers` — только проверенные Forever-данные; отсутствие записи не означает отсутствие прока.
2. `procActive` для aura-backed эффектов читать из AU-01/AU-05, `remaining/stacks` — из AU-02; не повторять aura lookup. Для event-only/glow-only эффектов отдельный статус, не подменять aura active.
3. Объединить с SP-12: `reactiveWindowActive`, `buttonGlowActive`, `procActive` и `usable` независимы. Проверить на Forever overlay API и события; при недоступности `UNKNOWN`.
4. Использовать PL-12/PL-13 для доказательного происхождения item/talent и проверенный источник rune; связь source→effect не выводить из одного факта экипировки/изучения таланта.
5. SP-07/09 используют только подтверждённые `effectModifiers` (скидка ресурса, мгновенный каст, возможность двигаться), а не угадывают по названию прока. Финальный READY — только `AbilityEligibility`.
6. Кэш/инвалидация по `UNIT_AURA`, overlay glow show/hide, экипировке, талантам, рунам, смене формы, cast outcome и ревизиям; таймеры только при проверенном expiration, без выдуманного duration.
7. Диагностика: `proc_source_unverified`, `proc_aura_unknown`, `proc_glow_unknown`, `proc_effect_unverified`; тесты talent/item/rune proc, одновременно несколько, aura vs glow, мгновенный каст, cost discount, stacks, expired/refresh, secret, смена предмета/таланта/руны, недоступный API.

**Архитектурные ссылки:** AU-01/02/05 — aura facts; SP-12 — реактивное окно и glow; PL-12/13 — предметы/таланты; SP-07/09 — последствия эффекта. В связанных старых требованиях добавлены обратные сноски на AU-07.

**Изменения кода:** не выполнялись; внесён аудит AU-07 и актуализированы связанные требования.

**Тесты и диагностика**

в файле не указано

**Архитектурные и обратные ссылки:** SP-12, AU-01, AU-02, AU-05, PL-12, PL-13, SP-07, SP-09.

---

### AU-08 — Защитные ауры цели (иммунитет, щит, отражение): не бить впустую

ID: [AU-08](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L2401). Приоритет: P1.

**Вердикт**

**Вердикт**

**ЧАСТИЧНО РЕАЛИЗОВАНО НА УРОВНЕ АУР — НЕТ МЕХАНИЗМА ПРОВЕРКИ ЗАЩИТЫ ЦЕЛИ (P1).**

**Выбранный путь**

в файле не указано

**Требуемые изменения (полный текст)**

**Требуемые изменения**

1. Завершить AU-01 `target/HELPFUL` и AU-05 family query. По подтверждённым spellID распознавать иммунитеты, щиты и отражения через общие данные, не угадывать по имени/иконке.
2. Для каждой атакующей способности проверенно определять schoolMask, physical/magical, mechanic/bleed и применимость отражения; отсутствие данных → UNKNOWN, не «универсально отражается».
3. Разделить полную неуязвимость, school/mechanic immunity, absorb, reflect и damage reduction. Поглощение и reduction **не** равны нулевой пользе от атаки.
4. Использовать проверенные события `UNIT_COMBAT`/CLEU, если Forever реально предоставляет source/target/spell/school; помечать `IMMUNE`, `REFLECT`, `ABSORB` как разные результаты. Историческое `IMMUNE` для одного spellID не доказывает иммунитет ко всем способностям/навсегда.
5. Classic NPC seed и learned evidence ForeverRotation хранить как предположение/ограниченное наблюдение с TTL и возможностью опровержения попаданием; при скрытом NPC ID — GUID-scoped transient state, не переносить на другого моба.
6. Общий GUID-index AU-06 использовать для нескольких целей; invalidation при UNIT_AURA, GUID switch, смерти, исчезновении nameplate, изменении защиты, завершении боя, secret transition.
7. Декларативные исключения (атакующий spellID, school, отражаемость, bypass, специфический иммунитет) в общих данных; без отдельных `MageImmunityReader`, `WarriorShieldReader` и подобных.
8. Диагностика `target_defense_unknown`, `school_unverified`, `immunity_event_unattributed`, `reflect_applicability_unknown`, `absorb_not_immunity`; тесты полный иммунитет, частичный иммунитет, разные школы, bleed, absorb, reflect, дружественная/враждебная цель, разные GUID, исчезновение ауры, stale event, secret combat, смена цели, исключения.

**Архитектурные ссылки:** AU-01/04/05/06, SP-14, AbilityEligibility. В старых требованиях добавлены обратные сноски на AU-08.

**Изменения кода:** не выполнялись; внесён аудит AU-08.

**Тесты и диагностика**

в файле не указано

**Архитектурные и обратные ссылки:** TG-07, TG-01, AU-01, AU-06, AU-04, AU-05, SP-14.

---

### AU-09 — Обновление ауры: «осталось меньше N секунд» без неоправданных мерцаний

ID: [AU-09](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L2456). Приоритет: P1.

**Вердикт**

**Вердикт**

**ЧАСТИЧНО РЕАЛИЗОВАНЫ БАЗОВЫЕ МЕХАНИЗМЫ — ДОРАБОТАТЬ (P1).**

**Выбранный путь**

в файле не указано

**Требуемые изменения (полный текст)**

**Требуемые изменения**

1. AU-02 даёт `remainingSeconds` и `isPermanent` с отдельными статусами; AU-09 вычисляет `remaining < N` строго, `remaining <= N` только для отдельного явно выбранного оператора. `N` — валидное неотрицательное конечное число; при `N=0` строгий предикат никогда не true.
2. Для отсутствующей ауры отдельный `needsApplication`; для permanent `refreshByTime=READY(false)` только при подтверждённой постоянности; для UNKNOWN remaining → UNKNOWN, не false/true.
3. При подтверждённом `expirationTime` пересчитывать remaining от общего монотонного clock и планировать **один** пересчёт на пересечение порога, если доступен надёжный механизм; `UNIT_AURA` и смена GUID немедленно инвалидируют. Heartbeat 2s использовать только как fallback, не заявлять точность лучше реальной.
4. Для повторного применения/refresh немедленно обновлять matched aura identity и expiration; старый срок не сохранять после смены цели/ранга/caster.
5. Для anti-flicker: короткий UI hold только для повторного отображения прежней рекомендации при кратковременном UNKNOWN; TTL и revision bound; при достоверном исчезновении ауры/смене GUID/смене eligibility/приоритета hold сбрасывать немедленно. Никаких скрытых действий.
6. Hysteresis/debounce отдельно для визуального переключения и только там, где не скрывает важную готовую способность; не сдвигать доказательный порог `remaining < N` и не повышать UNKNOWN до READY.
7. Multi-target: отдельный GUID+matched aura key из AU-06, чтобы переход между целями не переносил состояние предыдущей; AU-05 rank family не смешивает время разных экземпляров.
8. Диагностика `refresh_remaining_unknown`, `refresh_threshold_crossed`, `refresh_ui_held`, `refresh_identity_changed`, `refresh_permanent`; тесты N=0, N=1, N=5, exact N, переприменение, истечение, permanent, missing, secret, rank family, две цели, target swap, UI blink, срочный приоритет, изменившаяся eligibility.

**Архитектурные ссылки:** AU-01 — reader, AU-02 — время, AU-05 — match, AU-06 — GUID-index, SP-12 — отдельные reactive windows. Обратные сноски добавлены в связанные требования.

**Изменения кода:** не выполнялись; внесён аудит AU-09 и обратные архитектурные ссылки.

**Тесты и диагностика**

в файле не указано

**Архитектурные и обратные ссылки:** AU-02, AU-05, AU-06, AU-01, SP-12.

---

