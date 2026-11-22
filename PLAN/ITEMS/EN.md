# Карточки EN

Источник: REQUIREMENTS.md, blob 9efdec1900398c978ea121818fb5950cb1620337.

### EN-01 — Число враждебных целей в радиусе N (nameplates или другие источники)

ID: [EN-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3153). Приоритет: P1.

**Вердикт**

**Вердикт**

**НЕ РЕАЛИЗОВАНО КАК ДОСТОВЕРНЫЙ ПОДСЧЁТ ВРАГОВ В РАДИУСЕ N — ДОРАБОТАТЬ (P1).** Есть API allowlist и имя условия, но нет доказанного полного count provider. Ссылки: TG-01, TG-09, TG-06, AU-06; обратные архитектурные сноски внесены.

**Изменения Lua:** отсутствуют. Только документация.


**Ретроактивное уточнение EN-A7:** EN-A7 задаёт потребление подтверждённого количества целей для auto; источник подсчёта остаётся общим EN-01, без второго сканера. Исторический аудит сохранён.

**Выбранный путь**

**Каноническая архитектура**

Один `EnemyProximityObservation(radius, origin="player")`, опирающийся на общий `UnitObservation(unitToken)`, `TargetRangeObservation` TG-09 и bounded GUID-index AU-06. Читает только подтверждённые на Forever `nameplateN`/другие наблюдаемые unit tokens; сохраняет `GUID`, `exists`, `alive`, `hostile`, `attackable`, `rangeBounds`, `source`, `observedAt`. Дедупликация по GUID обязательна; отсутствие nameplates **не** означает отсутствие врагов.

Результат: `confirmedWithinCount` (достоверно в радиусе), `possibleWithinCount` (не исключено, что в радиусе), `observedHostileCount`, `coverage=PARTIAL/VERIFIED`, `status/reason`, `radius`, `unit=yards`. Для интервала `[min,max]`: `max<=N` → confirmed within, `min>N` → confirmed outside, пересечение границы → unknown membership. `confirmedWithinCount` — **нижняя граница** количества, а не точное число всех врагов в мире. Точный `enemy.count=READY(n)` разрешён лишь при подтверждённой полноте источника и всех необходимых distance observations; иначе `UNKNOWN` с отдельными bounded estimates. Не использовать отсутствие nameplates для READY(0).

`AoEPolicyObservation` потребляет count и explicit profile thresholds, но не подменяет `AbilityEligibility` и не переключает скрытно ручной режим. Никаких защищённых действий, сканирования невидимых unit tokens или искусственной точности.

**Требуемые изменения (полный текст)**

**Требуемые изменения**

1. Проверить на Forever `C_NamePlate.GetNamePlates`, `nameplateN`, `NAME_PLATE_UNIT_ADDED/REMOVED`, их secret/visibility ограничения и доступность в бою.
2. Дедуплицировать по стабильному GUID; на target switch и recycled nameplate token не наследовать старые данные.
3. Проверять exists, alive, hostility и attackability отдельно; нейтральные и friendly nameplates не считать врагами.
4. Подключить TG-09 интервальные bounds для каждого unit; spell-specific range не считать точной дистанцией.
5. Для каждого N считать confirmed/possible и полноту наблюдений; при частичном обзоре `enemy.count` UNKNOWN, а не фиктивный ноль.
6. Не смешивать радиус **от игрока** и радиус AoE **вокруг цели**; `origin` обязателен и проверяем. Учитывать large hitboxes.
7. Ленивая активация только по `Needs.enemyCount`, bounded список/TTL, события nameplates и ревизии EventBus, ограниченный heartbeat.
8. Диагностика `nameplate_source_unavailable`, `nameplate_coverage_partial`, `enemy_guid_unknown`, `enemy_range_unknown`, `enemy_radius_boundary`, `enemy_count_unverified`; тесты 0/1/много nameplates, duplicates, friendly/neutral, secret, 5/8/30 boundary, missing plates, recycled tokens, moving targets, combat, AoE target-origin vs player-origin.

**Тесты и диагностика**

в файле не указано

**Архитектурные и обратные ссылки:** NO-05, EN-07, EN-08, EN-06, EN-05, EN-04, EN-03, EN-02, TG-09, AU-06, TG-01, TG-06.

---

### EN-02 — Число врагов, находящихся в бою с группой

ID: [EN-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3226). Приоритет: P1.

**Вердикт**

**Вердикт**

**НЕ РЕАЛИЗОВАНО — ДОРАБОТАТЬ (P1).** В Kord есть combat/group/threat API-факты и allowlist nameplates, но нет доказательного подсчёта уникальных врагов, взаимодействующих с нашей группой.

**Архитектурные ссылки:** EN-01 — общий индекс врагов; TG-05 — threat/target-of-target; PL-07 — группа/рейд; TG-11 — generic unit tokens. Обратные ссылки добавлены в прежние задачи.

**Изменения Lua:** отсутствуют. Только документация.

**Выбранный путь**

**Каноническая архитектура**

**Расширить EN-01, а не создавать второй nameplate scanner.** Общий bounded `ObservedEnemyIndex` по GUID получает видимые unit tokens и событие lifecycle; `EnemyCombatObservation(enemyGUID)` хранит `inCombat`, `engagedWithGroup`, `engagementEvidence`, `matchedGroupMemberGUID`, `status/reason/observedAt`. Источники связи: достоверное `enemy target-of-target` в составе группы/питомцев, подтверждённые threat relations с каждым доступным членом группы и, если валидировано на Forever, боевые события с GUID обеих сторон. `UnitAffectingCombat(enemy)` **не** доказывает `engagedWithGroup`; отсутствие видимого target-of-target или угрозы **не** доказывает отсутствие взаимодействия. Сопоставление только по GUID, с учётом смены целей и питомцев; threat status не следует автоматически трактовать как фактического получателя атак.

Выход: `confirmedEngagedCount` (нижняя граница), `possibleEngagedCount` (верхняя граница **среди наблюдаемых**), `observedHostileCount`, `coverage`, `status/reason`; точное `enemy.engagedWithGroupCount=READY(n)` только при доказанной полноте источников и классификации. При неполном охвате `UNKNOWN`, не `READY(0)`. Отдельные запросы `engagedWithGroupCount` и `engagedWithGroupWithinRadius(N)` не смешивать; второй переиспользует TG-09 интервальную дальность EN-01. Все проверки ленивые по `Needs.enemyGroupCount`; нет защищённых действий.

**Требуемые изменения (полный текст)**

**Требуемые изменения**

1. Обобщить EN-01 `ObservedEnemyIndex` на GUID-indexed enemies, без второго nameplate loop; ограничить TTL и число записей.
2. Подключить PL-07 group/raid roster и питомцев с достоверной идентичностью; solo policy player+pet.
3. `UnitAffectingCombat` использовать как **факт боевого состояния**, а не доказательство боя с группой.
4. Добавить отдельные источники group-engagement evidence: enemy-target member, подтверждённая threat relation, валидированные combat log GUID relations. Непроверенные combat log events не считать источником.
5. Дедуплицировать GUID, проверять token recycling, death, target swap, pet/party roster changes и reset/evade.
6. Отдельно хранить `confirmed/possible` и coverage; не выводить точное число при скрытых nameplates или неизвестном engagement.
7. Добавить типизированное `enemy.engagedWithGroupCount` и `Needs.enemyGroupCount` в общий `RotationConditions`, при UNKNOWN применять PR-01/02.
8. Инвалидировать по nameplate add/remove, GROUP_ROSTER_UPDATE, UNIT_FLAGS, подтверждённым threat/target events, bounded heartbeat; диагностировать `enemy_engagement_unknown`, `group_roster_unknown`, `enemy_combat_secret`, `nameplate_coverage_partial`, `enemy_guid_recycled`.
9. Тесты: один враг на игроке, один на питомце, несколько на группе, посторонний бой, нейтральные, enemy in combat but not group, missing nameplates, unknown threat, token recycle, raid roster, solo, reset/evade, duplicates, secret flags, AoE radius filter.

**Тесты и диагностика**

в файле не указано

**Архитектурные и обратные ссылки:** NO-05, TH-01, EN-08, EN-06, EN-05, EN-03, EN-01, TG-09, PL-07, PR-01, TG-05, TG-11.

---

### EN-03 — Распознавание одной и той же цели в разных источниках (без двойного счёта)

ID: [EN-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3295). Приоритет: P1.

**Вердикт**

**Вердикт**

**ЧАСТИЧНО РЕАЛИЗОВАНО — ДОРАБОТАТЬ (P1).** В Kord есть локальные GUID guards и `UnitIsUnit`, но нет единого cross-source identity/deduplication contract.

**Архитектурные ссылки:** EN-01, EN-02, TG-01, TG-11, AU-06. Обратные ссылки добавлены в каждую затронутую старую задачу.

**Изменения Lua:** отсутствуют. Только документация.


**Ретроактивное уточнение EN-A10:** EN-A10 использует каноническую дедупликацию целей EN-03; отдельный GUID-кэш мультидота не создавать. Исторический аудит сохранён.

**Выбранный путь**

в файле не указано

**Требуемые изменения (полный текст)**

**Требуемые изменения**

1. Создать/расширить один канонический GUID-based identity provider в существующем общем ядре, без отдельных индексов для каждой категории врагов.
2. Сохранять множественные alias tokens одного GUID и происхождение фактов; один GUID — один вклад в EN-01 и EN-02.
3. При secret/nil GUID возвращать UNKNOWN identity и не включать в подтверждённый count, даже если есть имя или token.
4. Проверять GUID до/после чтений, token recycling, target/focus/mouseover switch и nameplate lifecycle.
5. При исчезновении одного alias сохранять сущность, если другие alias всё ещё достоверны; устаревшие combat/range facts не сохранять как текущие.
6. Поддержать одинаковые имена разных GUID, один GUID с разными unit tokens, missing GUID, combat-log-only GUID, несколько sources с разными timestamp.
7. Развести identity и engagement/radius: один GUID может иметь несколько evidence sources, но один count contribution.
8. Добавить lazy Needs gating, bounded TTL/cache, event revisions, secret-safe diagnostics `identity_guid_unknown`, `identity_alias_conflict`, `identity_token_recycled`, `identity_stale`, `identity_deduplicated`.
9. Тесты: target=nameplate, focus=target, mouseover=nameplate, все 4 совпадают, одинаковое имя с разными GUID, stale alias, recycled nameplate, secret GUID, combat-log-only, multiple group-threat relations, rapid target switch, hidden nameplate.

**Тесты и диагностика**

в файле не указано

**Архитектурные и обратные ссылки:** NO-05, AC-04, PE-06, TH-03, TH-01, EN-07, EN-08, EN-06, EN-05, EN-04, EN-01, EN-02, AU-06, TG-01, TG-11.

---

### EN-04 — Есть ли рядом цели под ломаемым контролем (овца, ловушка), чтобы не задеть их AoE

ID: [EN-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3376). Приоритет: P1.

**Вердикт**

**Вердикт**

**НЕ РЕАЛИЗОВАНО — ДОРАБОТАТЬ (P1).** Есть название `aoe.safe` и чтение отдельного дебаффа, но нет достоверного AoE CC-preservation provider.

**Архитектурные ссылки:** TG-07, EN-01, EN-03, TG-09, AU-06, SP-14. Обратные ссылки добавлены в старые задачи.

**Изменения Lua:** отсутствуют. Только документация.


**Ретроактивное уточнение EN-A10:** EN-A10 обязан исключать цели под ломаемым контролем из кандидатов на DoT, когда факт подтверждён; при неизвестном safety-факте — STOP. Исторический аудит сохранён.

**Ретроактивное уточнение CL-07:** CL-07: Mage Polymorph, Frost Nova и Blizzard требуют общего EnemyCCSafetyProvider, чтобы не разбить breakable control AoE.

**Выбранный путь**

**Каноническая архитектура**

**Не создавать новый CC scanner, nameplate scanner, GUID index или отдельный AoE engine.** Использовать один `UnitIdentityIndex` EN-03, `ObservedEnemyIndex` EN-01/02, `TargetControlObservation(unitGUID)` TG-07, `AuraPresenceObservation` AU-01/06 и `TargetRangeObservation` TG-09. Добавить только логический производный `AoEControlSafetyObservation` в общий pipeline условий.

Каталог свойств способностей задаёт `effectGeometry` (self-centered, target-centered, ground-targeted, cone, chain, cleave, periodic/pet splash), `radius/angle` только при подтверждённых значениях, `damageBreakPotential`, `targetingMode`, `provenance`. Радиус от игрока нельзя выдавать за радиус вокруг текущей цели; расстояния игрок→A и игрок→B не определяют A→B. Без проверенной относительной геометрии и без полного охвата nameplates нельзя доказывать `SAFE`. Если confirmed breakable CC пересекается с проверенным AoE footprint — `UNSAFE`; если overlap возможен, но не подтверждён — `UNKNOWN`. При нескольких контролях учитывать конкретную механику каждого и возможность его разрушения прямым/периодическим/питомцем уроном.

Декларативное `aoe.safe` должно быть `READY(true)` только при доказанной безопасности, `READY(false)` при доказанном риске, `UNKNOWN` иначе. Ротация обязана различать «не рекомендовать AoE из-за политики сохранения CC» и «физически нельзя применить способность». Критические исключения должны быть явными в профиле, не скрытыми.

**Требуемые изменения (полный текст)**

**Требуемые изменения**

1. Согласовать общие каталоги CC/rank-family TG-07 и AoE spell footprints с проверенными Forever spell IDs, не копировать retail assumptions.
2. По EN-03 GUID объединять target/focus/mouseover/nameplate aliases и предотвращать двойной учёт контролируемого врага.
3. По AU-01/06 проверять breakable CC на каждом доступном враге; отсутствие видимой ауры при secret не доказывает отсутствия контроля.
4. Проверять источник/центр/радиус/форму AoE: self, target, ground, cone, chain, cleave, DoT, pet splash; UNKNOWN при неподтверждённой геометрии.
5. Разделять подтверждённое пересечение, возможное пересечение и подтверждённое отсутствие пересечения; радиусы до игрока не дают расстояния между врагами.
6. Учитывать неполное покрытие nameplates и потенциально скрытые цели; SAFE нельзя выводить из пустого видимого списка.
7. Ленивый `Needs.aoeSafety`, EventBus invalidation при aura/nameplate/target/unit movement, bounded cache по abilityID+targetGUID+revision.
8. Диагностика `aoe_cc_breakable_confirmed`, `aoe_geometry_unknown`, `aoe_overlap_unknown`, `aoe_cc_aura_secret`, `aoe_nameplate_coverage_partial`, `aoe_target_changed`.
9. Тесты: Polymorph/Freezing Trap рядом с AoE центром, Gouge/Blind, неразрушаемый stun, AoE от игрока/цели, cone/chain/ground, разные GUID alias, DoT, pet splash, hidden plate, secret aura, moving target, CC expires, spell footprint unknown.

**Тесты и диагностика**

в файле не указано

**Архитектурные и обратные ссылки:** CL-08, AC-04, IT-03, SW-04, SW-03, SW-01, EN-07, EN-08, EN-05, EN-01, TG-07, AU-06, TG-09, EN-03, AU-01, SP-14, CL-07.

---

### EN-05 — Минимальное число целей для включения AoE — настройка

ID: [EN-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3455). Приоритет: P1.

**Вердикт**

**Вердикт**

**ЧАСТИЧНО РЕАЛИЗОВАНО — ДОРАБОТАТЬ (P1).** Режимы `auto/single/aoe` и UI уже есть, но порог N и достоверный auto-switch отсутствуют.

**Архитектурные ссылки:** EN-01, EN-02, EN-03, EN-04, SP-14. Обратные ссылки внесены в старые задачи.

**Изменения Lua:** отсутствуют. Только документация.


**Ретроактивное уточнение EN-A7:** EN-A7 использует общий порог AoE из EN-05; ручной режим не отменяет safety-порог конкретного действия. Исторический аудит сохранён.

**Выбранный путь**

**Каноническая архитектура**

Добавить в общий `RotationSettings` параметр `aoeMinTargets` (целое число, диапазон и значение по умолчанию определяются контрактом UI/профиля; не выдавать произвольный default за существующий). `AoEPolicyObservation` читает `targetMode`, `aoeMinTargets`, подтверждённое `EnemyProximityObservation` EN-01, канонический GUID index EN-03 и `AoEControlSafetyObservation` EN-04. Для `auto`: `count >= N` и подтверждённая применимость → `AoE`; `count < N` только при достаточном coverage → `single`; при неполном покрытии/неизвестном числе → `UNKNOWN` или явно задокументированный консервативный fallback, который **не** выдаёт неизвестность за точный счётчик. Если confirmed lower bound уже >= N, порог математически подтверждён даже при неполном охвате; если lower bound < N, но possible upper bound >= N — UNKNOWN. При угрозе разрушить CC `UNSAFE` не разрешать AoE, независимо от N.

Разделять пороги для общего nearby enemy count и, если профиль явно требует, для engaged-with-group EN-02; не подменять один другим. Единый профильный параметр по умолчанию не означает глобальную конфигурацию для всех классов; class-specific default — данные профиля. Не создавать отдельный классовый AoE switcher.

**Требуемые изменения (полный текст)**

**Требуемые изменения**

1. Добавить `aoeMinTargets` в схему/валидацию `RotationSettings`, миграцию старых настроек и UI с локализацией/подсказками на шести языках.
2. Сохранить `auto/single/aoe` как независимый ручной выбор; порог применяется только к auto.
3. Использовать один deduplicated GUID count EN-01/EN-03, не nameplate raw count.
4. Ввести `AoEPolicyObservation` с `READY(aoe/single)` либо `UNKNOWN(reason)`; не подменять неизвестный count нулём.
5. Поддержать доказательные нижнюю/верхнюю границы и частичный охват; подтверждённое `lowerBound>=N` достаточно для самого порога, но не для CC-safety.
6. Применять EN-04 `aoe.safe` отдельно от количества, затем окончательный `AbilityEligibility`.
7. Ленивые `Needs.enemyCount/aoeSafety`, ревизии EventBus и минимизация пересчётов.
8. Диагностика `aoe_threshold_invalid`, `aoe_count_unknown`, `aoe_threshold_met`, `aoe_threshold_not_met`, `aoe_cc_unsafe`, `aoe_mode_manual_override`.
9. Тесты N=1/2/3/много, N-1/N/N+1, duplicate GUID, partial coverage, lower/upper bound, UNKNOWN count, CC present/secret, manual single/aoe, profile switch, old settings migration, UI six-language tooltips.

**Тесты и диагностика**

в файле не указано

**Архитектурные и обратные ссылки:** SW-04, EN-08, EN-04, EN-01, EN-03, EN-02, SP-14.

---

### EN-06 — Здоровье и TTD по каждому врагу в списке (для выбора мультидота)

ID: [EN-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3516). Приоритет: P2.

**Вердикт**

**Вердикт**

**ЧАСТИЧНО РЕАЛИЗОВАНО — ДОРАБОТАТЬ (P2).** Kord умеет читать здоровье отдельных юнитов и имеет сигнальное имя TTD, но не ведёт достоверную per-GUID health/TTD history для всех врагов.

**Архитектурные ссылки:** EN-01, EN-02, EN-03, TG-02, PL-03, TG-06, AU-06. Обратные ссылки добавлены в предыдущие требования.

**Изменения Lua:** отсутствуют. Только документация.



**Ретроактивное уточнение EN-A10:** EN-A10 использует общий список здоровья/TTD EN-06, без второго TTD-движка. Исторический аудит сохранён.

**Выбранный путь**

**Каноническая архитектура**

**Один `UnitIdentityIndex` EN-03 + один `ObservedEnemyIndex` EN-01/02 + общие `UnitHealthObservation(unit)` TG-02/PL-03 и `TTDObservation(GUID)` TG-06.** `MultiDotCandidateObservation(enemyGUID, spellID)` — только производное решение, не новый scanner или estimator. На каждую подтверждённую GUID-сущность хранить ограниченную историю `{time, health evidence, max/percent precision, damage/heal evidence, confidence, provenance, revision}`. Alias nameplateN/target/focus/mouseover может меняться, но GUID history не смешивать; при recycled token, death, evade, heal reset, смене encounter, stale sample — инвалидировать/пересчитать. Число записей, период и TTL bounded; lazy `Needs.enemyHealth/Needs.enemyTTD`.

Оценка TTD допускается только по достаточному набору сопоставимых наблюдений и проверенному снижению здоровья; учитывать хил, шум, неполную видимость и диапазон ошибки. `TTD=UNKNOWN` при secret-only threshold, коротком окне, нестабильной скорости, невалидном максимуме или исчезнувшем GUID. Отдельные проценты и exact values не смешивать без доказанного преобразования.

Для мультидота кандидат должен иметь достоверный recipient/binding (TG-11), проверенную дальность (TG-09), ауру и остаток (AU-06/AU-09), пригодность способности (SP-14) и достаточную ожидаемую продолжительность жизни; unknown TTD не трактовать как бесконечное время. Политика выбора при UNKNOWN должна быть явной, консервативной и не нарушать PR-01/02.

**Требуемые изменения (полный текст)**

**Требуемые изменения**

1. Использовать единый GUID-index EN-03 и общий EN-01/02 registry; запретить отдельный nameplate scan для multi-dot.
2. Расширить `UnitHealthObservation` на доступные enemy unit tokens с проверкой GUID до/после каждого snapshot и secret-safe semantics.
3. Расширить общий TG-06 `TTDObservation` до bounded GUID-keyed history для нескольких врагов; никакого отдельного `MultiDotTTD`.
4. Разделять exact health, процент и threshold curve; неизвестные exact значения не вычислять из кривой.
5. История должна учитывать heal/damage, reset, death, evade, recycled nameplates, исчезновение алиаса, неполный combat log.
6. Дать `MultiDotCandidateObservation` только подтверждённые/оценочные факты с provenance/confidence и причины UNKNOWN.
7. Не рекомендовать мультидот на неадресуемую цель; не выполнять защищённые target switch/cast действия.
8. Инвалидировать по `UNIT_HEALTH`, `UNIT_MAXHEALTH`, nameplate lifecycle, GUID changes, aura revisions, bounded heartbeat.
9. Диагностика `enemy_health_secret`, `enemy_health_unknown`, `enemy_ttd_insufficient_history`, `enemy_ttd_unstable_rate`, `enemy_ttd_stale`, `enemy_guid_recycled`, `multidot_recipient_unknown`.
10. Тесты: две одинаковые NPC names с разными GUID, один GUID в нескольких tokens, 0/1/many enemies, stable/unstable damage, heal, immune, reset, dead, new pull, threshold-only secret, disappearing nameplate, aura refresh, unaddressable unit, low TTD vs DoT duration.

**Тесты и диагностика**

в файле не указано

**Архитектурные и обратные ссылки:** CL-08, EN-08, EN-03, EN-01, TG-02, PL-03, TG-06, TG-11, TG-09, AU-06, AU-09, SP-14, PR-01, EN-02.

---

### EN-07 — Ближайшая цель для смены, цель с прерываемым кастом

ID: [EN-07](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3579). Приоритет: P2.

**Вердикт**

**Вердикт**

**ЧАСТИЧНО РЕАЛИЗОВАНО — ДОРАБОТАТЬ (P2).** Kord имеет базовые read-only cast/range API, target GUID guards и event invalidation, но не имеет подтверждённого общего выбора ближайшей переключаемой цели и per-enemy interruptible cast observation с корректной адресуемостью.

**Архитектурные ссылки:** EN-01, EN-03, EN-04, EN-08, TG-09, TG-11, SP-14. Обратные архитектурные ссылки добавлены в перечисленные ранее требования в том же коммите.

**Изменения Lua:** отсутствуют. Только документация.

**Выбранный путь**

**Выбранный путь Kord (решение по результатам сравнения)**

**Выбрать модель RotationMaster для универсального `EnemyCastObservation(unitGUID,alias)` с per-evaluation memo и `UNKNOWN(reason)`, событийную lifecycle/serial-инвалидацию JustAC, общий GUID-index EN-03 и event-maintained observed registry MaxDps/EN-08.** Принцип `true/false/nil` ForeverRotation сохранить, но исключить его fail-open при рекомендации прерывания. Для nearest selection использовать только подтверждённый частичный порядок диапазонов/достижимости: при равных/неразличимых диапазонах вернуть `UNKNOWN(nearest_unresolved)` либо упорядоченный список кандидатов **без утверждения «самая близкая»**. Не пытаться вычислять метры из имени, порядка nameplates, screen position или секретных значений. Если подтверждён каст другой цели, выдавать отдельно «цель для ручного переключения»; готовую кнопку прерывания текущей цели рекомендовать только после GUID-safe `AbilityEligibility`. Это сохраняет единое общеклассовое ядро и не дублирует EN-01/03/08, TG-09, TG-11 и SP-14.

**Требуемые изменения (полный текст)**

**Требуемые изменения**

1. Расширить общий `ObservedEnemyIndex` (EN-01/02/03/08) адресуемыми aliases и статусами доступности, не добавлять новый nameplate scanner.
2. Реализовать общеклассовый `EnemyCastObservation` для cast и channel: active, spellID/name если plain, start/end если доступны, interruptible tri-state, GUID, cast serial, observedAt, provenance, reason. Проверять версию клиента/индексы API по v14.
3. Учитывать `UNIT_SPELLCAST_START/STOP/FAILED/INTERRUPTED/CHANNEL_*`, `UNIT_SPELLCAST_INTERRUPTIBLE/NOT_INTERRUPTIBLE` только при подтверждённой доступности в клиенте; nameplate add/remove, target switch и GUID changes инвалидируют соответствующий cast, не соседние GUID.
4. Реализовать `TargetSwitchCandidateObservation` с фильтрами alive/hostile/CC/visible/addressable и проверяемой оценкой range; nearest только при доказуемом сравнении, иначе UNKNOWN или честно немаркированный набор.
5. Реализовать `InterruptCandidateObservation` для активного interruptible cast, оставшегося времени (только при доступных plain данных), способности/дальности и целевого GUID; чужой GUID не объявлять текущей целью.
6. Передать рекомендацию прерывания текущей цели в общую `AbilityEligibility` (единственный final READY); пользовательское переключение показывать как отдельную информационную подсказку, не как автоматическое действие.
7. Сохранить lazy `Needs`, EN-08 rate limit, bounded cast TTL и GUID-keyed cache; не опрашивать все nameplates каждый frame.
8. DevTools-only диагностика: `enemy_cast_active`, `enemy_cast_secret`, `enemy_interruptible_unknown`, `enemy_cast_guid_changed`, `enemy_cast_stale`, `nearest_unresolved`, `switch_requires_manual_target`, `interrupt_range_unknown`, `interrupt_candidate_ready`.
9. Тесты: 0/1/many enemies, два одинаковых имени/разные GUID, один GUID/несколько aliases, recycled nameplate, cast vs channel, cast stop/interrupt, mid-cast interruptibility change, secret flag, no cast, disappearing plate, current vs off-target, range unknown, CC protected, equal range bands, cooldown, stale snapshot, event burst, no protected action.

**Тесты и диагностика**

в файле не указано

**Архитектурные и обратные ссылки:** SW-03, SW-02, SW-01, EN-08, EN-03, EN-01, TG-09, TG-11, SP-14, EN-04.

---

### EN-08 — Бюджет: чтение nameplates не чаще заданного интервала, без постоянного сканирования

ID: [EN-08](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3636). Приоритет: P1.

**Вердикт**

**Вердикт**

**ЧАСТИЧНО РЕАЛИЗОВАНО — ДОРАБОТАТЬ (P1).** EventBus уже ограничивает частоту инвалидаций, но канонический бюджетированный nameplate scanner/registry с общей кэшированной выборкой, лимитом частоты и измеряемыми затратами не подтверждён. Отсутствие реализации EN-01/EN-03 не позволяет объявить EN-08 выполненным.

**Архитектурные ссылки:** EN-01, EN-02, EN-03, EN-04, EN-05, EN-06, TG-01, TG-09, TG-06, AU-06. Обратные ссылки внесены в EN-01…EN-06; они уточняют прежние рекомендации о чтении nameplates без удаления исторического аудита. EN-07 пока отсутствует в REQUIREMENTS.md и потому обратная ссылка в него не добавлялась.

**Изменения Lua:** отсутствуют. Только документация.

**Выбранный путь**

**Выбранный путь Kord (решение по результатам сравнения)**

**Комбинированный канонический подход: event-maintained GUID registry (MaxDps/RotationMaster/JustAC) + один time-gated snapshot refresh (сильная сторона ForeverRotation, без его независимых обходов) + lazy needs/early exit (ForeverAuras) + fail-closed staleness.** Реализовать через существующие `EventBus` и общие EN-01/EN-03 индексы, без нового классового движка и без отдельного nameplate scanner для каждого условия. Nameplate ADD/REMOVE обновляют известные tokens и dirty revision; полное перечисление допускается только общим `EnemyRefreshBudget` не чаще валидированного интервала. Все потребители получают один snapshot и причину UNKNOWN при stale/partial coverage. Это предпочтительнее краткоживущего per-condition кэша ForeverRotation, timestamp-only кэша RotationGuide и необусловленного запроса API Sonah: обеспечивает глобальный лимит затрат и исключает дублирование между AoE, CC, TTD и target selection. Числовой default интервала установить после измерений в клиенте Forever, не выдумывать его сейчас.

**Каноническая архитектура**

Расширить общий механизм наблюдений/индекс врагов, **не создавать второй scanner**. `EnemyRefreshBudget` — логический контракт scheduler внутри общего observation/index слоя, не обязательный отдельный Lua-файл. Состояние: `lastFullScanAt`, `nextEligibleAt`, `dirtyReasons`, `snapshotRevision`, `observedAt`, `coverage`, `scanCount`, `scanDuration`, `deferredCount`, `status/reason`. Все EN-01…EN-07 и TG/AU/TTD потребители читают общий snapshot лениво по `Needs` и не вызывают `GetNamePlates` напрямую. События `NAME_PLATE_UNIT_ADDED/REMOVED` могут точечно обновлять/инвалидировать alias с проверкой GUID и не должны провоцировать полный обход на каждое событие; debounce/coalescing и minimum full-scan interval обязательны. Heartbeat — bounded fallback для refresh eligibility, не повод безусловно сканировать при каждом тике.

Минимальный интервал конфигурируем, валидируется и ограничивается безопасными min/max; нулевой или отрицательный интервал запрещён. При нагрузке/пакетных событиях сохранять hard rate limit, bounded per-refresh work и TTL; запрос в cooldown возвращает прежний snapshot с age/staleness или `UNKNOWN` по контракту, но не запускает обход. Отдельно учитывать API-secret, unavailable, partial coverage, nameplate recycled, disappearance и возможность неполной видимости. `AbilityEligibility` остаётся единственным источником финального READY; budget никогда не создаёт искусственно подтверждённый count.

**Требуемые изменения (полный текст)**

**Требуемые изменения**

1. Ввести единый `EnemyRefreshBudget` поверх EN-01/EN-03 индексов, используя EventBus invalidation/coalescing; не плодить class-specific scanner.
2. Установить один gate для полного перечисления nameplates с `nameplateScanMinIntervalMs`, monotonic timestamp, hard rate limit и bounded work; не вызывать из `OnUpdate` напрямую.
3. Подписать nameplate lifecycle и GUID changes на инвалидацию/точечные обновления; объединять bursts и корректно сбрасывать recycled alias.
4. Возвращать единый versioned snapshot с `observedAt/age/coverage/status/reason`; при устаревании или неизвестной полноте не утверждать точный count и безопасность AoE.
5. Запретить повторный обход по каждому `enemy.count`, EN-02 combat, EN-04 CC, EN-05 threshold, EN-06 TTD и EN-07 interrupt/target consumer.
6. Вынести бюджетную настройку в общие настройки с валидацией, сохранением, миграцией и шестиязычными подсказками, если настройка доступна пользователю; безопасное значение по умолчанию определить после клиентских замеров, не выдавать предположение за измеренный норматив.
7. DevTools-only метрики: `nameplate_scan_count`, `nameplate_scan_interval_actual`, `nameplate_scan_duration`, `nameplate_scan_deferred`, `nameplate_snapshot_age`, `nameplate_coverage_unknown`, `nameplate_budget_exceeded`; пользовательский аддон не должен хранить developer-only recorder.
8. Тесты: no plates, burst add/remove, 1/много plates, запросы нескольких потребителей в один тик, repeated condition evaluation, scan cooldown, interval boundary, delayed refresh, combat target switch, recycled GUID, stale snapshot, secret/unavailable API, heartbeat без dirty listeners, high event rate; доказать отсутствие полного сканирования чаще бюджета.

**Тесты и диагностика**

в файле не указано

**Архитектурные и обратные ссылки:** TH-03, TH-02, TH-01, EN-07, EN-01, EN-03, EN-02, EN-04, EN-05, EN-06, TG-01, TG-09, TG-06, AU-06.

---

