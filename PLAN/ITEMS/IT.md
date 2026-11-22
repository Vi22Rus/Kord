# Карточки IT

Источник: REQUIREMENTS.md, blob 9efdec1900398c978ea121818fb5950cb1620337.

### IT-01 — Количество предмета в сумках по ID или по семейству (зелья, камни, бинты, еда)

ID: [IT-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4852). Приоритет: P0. Lua: упомянут (точный статус в источнике).

**Вердикт / статус**

**Вердикт**

**НЕ РЕАЛИЗОВАНО КАК УНИВЕРСАЛЬНАЯ ВОЗМОЖНОСТЬ — ДОРАБОТАТЬ (P0).** В Kord нет подтверждённого bag count API allowlist, inventory revisions, bags-only snapshot и семейного каталога. Внедрение IT-01 необходимо для достоверных рекомендаций расходников.

**Архитектурные ссылки:** SP-14, PE-04, PE-05, GR-05, SW-04. Обратные ссылки внесены в эти требования в том же коммите.

**Изменения Lua:** отсутствуют. Только документация.

**Выбранный путь Kord**

**Выбранный путь Kord**

**Один логический `InventoryObservation` в GameState/GameAPI с `InventoryItemObservation` и `InventoryFamilyObservation`, единым `ItemFamilyCatalog` и revision-based кэшем**, по архитектуре RotationMaster, с Forever каталогом JustAC и обновлением ForeverAuras. `InventoryReadAdapter` сперва пробует проверенный `C_Item.GetItemCount(itemID,false,false)`, а если semantics/secret/capability не позволяют доказать bags-only count, использует **один** bounded `C_Container` bag snapshot (только подтверждённые ID сумок) с полным coverage и обработкой secret. Не суммировать API count и bag scan как два независимых количества. Для `familyCount` строить множество уникальных ID из каталога (варианты рангов, healing potions, mana potions, healthstones, bandages, food/drink) и суммировать только полные известные результаты; при хотя бы одном неизвестном компоненте family count `UNKNOWN` с опциональной **нижней границей** `knownMinimum`, но не READY/полным count. Пересекающиеся семейства могут намеренно иметь один ID, но **внутри одного** семейства повторов нет. Семейство по `GetItemFamily` (тип сумки) не равно функциональной категории расходников — категории задаёт каталог, а не item bag family bitmask.

`BAG_UPDATE_DELAYED`, `BAG_UPDATE`, `BAG_CONTAINER_UPDATE` и подтверждённые inventory/healthstone refresh события меняют `bagRevision`; отдельная `catalogRevision` при обновлении семейства. При Soulwell refresh без `BAG_UPDATE_DELAYED` применять ограниченную **event-triggered recheck** при подтверждённом item/cooldown/interaction signal или по explicit UI/DevTools запросу, а не постоянный full scan. Lazy `Needs.items` разрешает чтение по запросу и per-evaluation memo; batched family query выполняет один snapshot/набор уникальных ID, без N×bag scanning. Различать item count и item cooldown/usability/effect/rank/level restrictions (следующие IT требования), а финальное `READY` — только в `AbilityEligibility` после item-specific gate. Read-only; никакого использования предметов/защищённых команд.

**Требуемые изменения (полный текст)**

**Требуемые изменения**

1. Ввести единый `InventoryObservation` (BAGS_ONLY), `InventoryItemObservation`, `InventoryFamilyObservation`, с status/source/reason/revision; не дублировать bag scanners.
2. Валидировать на Forever `C_Item.GetItemCount` параметры `includeBank/includeUses`, secret/nil и bags-only semantics; `GetItemCount` legacy только при подтверждённой совместимости.
3. Валидировать `C_Container.GetContainerNumSlots/GetContainerItemID/GetContainerItemInfo`, bag IDs, scope, неполные/secret слоты; не смешивать equipped/bank/reagent bank.
4. Реализовать версионированный `ItemFamilyCatalog` с Forever IDs и вариантами рангов, health/mana potions, healthstones, bandages, food/drink; дедупликация внутри семьи.
5. `familyCount` суммирует только подтверждённые counts, unknown component -> UNKNOWN с optional knownMinimum; отсутствие API никогда не становится count=0.
6. EventBus добавить `BAG_UPDATE`/`BAG_UPDATE_DELAYED`/`BAG_CONTAINER_UPDATE` после client probe, per-bag revisions, bounded event coalescing и refresh при soulwell edge case.
7. RotationConditions `items.count(itemID)`, `items.familyCount(familyID)`, `items.hasAny(familyID)`, `Needs.items` lazy memo и прозрачное UNKNOWN.
8. Подготовить отдельную item eligibility ветку в AbilityEligibility (count, usable, cooldown, combat/level/target), не считать item count готовностью и не использовать spellID как itemID.
9. DevTools-only диагностика: `item_count_unknown`, `item_count_secret`, `item_count_scope_unverified`, `item_bag_scan_incomplete`, `item_family_unknown`, `item_family_partial`, `item_family_duplicate_id`, `item_catalog_revision_changed`, `item_bag_revision_changed`, `item_soulwell_refresh_missing_event`, `item_count_zero_confirmed`.
10. Тесты: 0/1/multiple stacks, same item in multiple bags, partial bag secret, item count API vs scan, bank-only/equipped-only, includeBank false, family rank variants, duplicate IDs within family, overlapping families, potion/stone/bandage/food, custom Forever items, split/merge stacks, soulwell stone refresh without BAG_UPDATE_DELAYED, missing/out-of-order bag events, combat secret, item usability/cooldown separate, no heavy OnUpdate/protected item use.

**Тесты и диагностика**

в файле не указано

**Архитектурные и обратные ссылки:** CL-08, AC-02, IT-04, IT-14, IT-11, IT-10, IT-09, IT-08, IT-07, IT-06, IT-05, IT-03, IT-02, SP-14, PE-04, PE-05, GR-05, SW-04.

---

### IT-02 — Кулдаун предмета: активен, остаток, общий кулдаун зелий

ID: [IT-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4932). Приоритет: P0. Lua: упомянут (точный статус в источнике).

**Вердикт / статус**

**Вердикт**

**НЕ РЕАЛИЗОВАНО КАК УНИВЕРСАЛЬНАЯ ВОЗМОЖНОСТЬ — ДОРАБОТАТЬ (P0).** В Kord нет item cooldown API allowlist, item cooldown observation/revisions и достоверной модели общего cooldown зелий. Существующий spell cooldown не заменяет item cooldown.

**Архитектурные ссылки:** IT-01, SP-14, GR-05, PE-05, SW-04. Обратные ссылки внесены в эти требования в том же коммите.

**Изменения Lua:** отсутствуют. Только документация.

**Выбранный путь Kord**

**Выбранный путь Kord**

**Один логический `ItemCooldownObservation` + `SharedItemCooldownObservation` поверх IT-01 `InventoryObservation`/`ItemFamilyCatalog` и единого EventBus.** `ItemCooldownAdapter` — read-only `C_Item.GetItemCooldown`, fallback `C_Container.GetItemCooldown` и legacy **только** после Forever API probe; `C_Item.GetItemSpell` — дополнительная проверка item use-spell identity, не замена itemID. Нормализовать `enabled` (bool/0/1), проверять secret/finite/start/duration/clock. `active=true` при подтверждённом cooldown с положительным remaining; `active=false` только при валидированном нуле; иначе UNKNOWN. При `enabled=false` — отдельный `DISABLED/UNKNOWN`, не ready.

`SharedCooldownGroupCatalog` **переиспользует** IT-01 family itemIDs, но **не** приравнивает все функциональные семейства к общему cooldown: `healthPotion` и `manaPotion` могут разделять `POTION_SHARED`, тогда как healthstone, bandage, food, mana gem, trinket и GCD требуют отдельных подтверждённых связей. Группа получает `CONFIRMED_ACTIVE` только если (a) валидированные cooldown-состояния нескольких подходящих членов/категорий подтверждают общую блокировку, либо (b) подтверждённое применение itemID и проверенная на Forever duration/group rule дают явную **ESTIMATED_ACTIVE** с source/time horizon, не подменяя API-факт. `CONFIRMED_READY` — только если **все применимые** наблюдаемые члены и client shared lockout проверены, и нет известного combat-use restriction; иначе UNKNOWN. Если часть членов отсутствует в сумках, catalog-level group observation не должен делать ложный вывод об отсутствии общего cooldown; проверять доступные representative IDs и event evidence. Общее время до готовности может быть максимумом доказанных member cooldowns только при подтверждённой group semantics, но **не** произвольным max по всем расходникам. При missing/secret member cooldown `groupRemaining=UNKNOWN` с `knownLowerBound`, если допустимо. Separate item cooldown, GCD, shared potion cooldown и once-per-combat constraints.

`BAG_UPDATE_COOLDOWN`, `BAG_UPDATE_DELAYED`, `ACTIONBAR_UPDATE_COOLDOWN`, подтверждённые item use/cast/zone/combat signals — только revision/invalidation; событие без itemID не подтверждает, что именно зелье использовано. Item use-spell attribution требует уникального соответствия, иначе UNKNOWN. Кэш по `itemID`, `bagRevision`, `itemCooldownRevision`, `groupCatalogRevision`, monotonic now; bounded TTL для countdown и event coalescing. Lazy `Needs.items.cooldown`, один reader для всех профилей; `AbilityEligibility` остаётся единственным final READY для item candidates после IT-01 count, item cooldown, group cooldown, usability/target/combat gates. Никаких protected item uses.

**Требуемые изменения (полный текст)**

**Требуемые изменения**

1. Ввести `ItemCooldownObservation(itemID)` и `SharedItemCooldownObservation(groupID)` с active/remaining/enabled/status/source/revision.
2. Валидировать Forever `C_Item.GetItemCooldown`, `C_Container.GetItemCooldown`, legacy, типы enabled, secret/nil/finite, epoch и `GetTime`; добавить GameAPI read-only allowlist.
3. Реализовать cooldown adapter с `UNKNOWN` для missing/secret/disabled/invalid; не считать `duration<=1.5` универсальным доказательством отсутствия собственного CD.
4. Отделить item-specific cooldown от GCD, combat-use restriction, item count, charges и item usability.
5. Создать `SharedCooldownGroupCatalog` с верифицированной на Forever группой `POTION_SHARED` и исключениями; не смешивать healthstones/bandages/mana gems/trinkets без доказательства.
6. Реализовать group inference из проверенных cooldown states и observed item-use, с `CONFIRMED/ESTIMATED/UNKNOWN` и no false-ready при неполном наборе.
7. EventBus item cooldown revision по `BAG_UPDATE_COOLDOWN`, bag/actionbar/item-use/combat/zone events, coalescing и bounded refresh; не дублировать IT-01 bag scanner.
8. RotationConditions `items.cooldownActive(itemID)`, `items.cooldownRemaining(itemID)`, `items.sharedCooldownRemaining(groupID)` и lazy `Needs.items.cooldown`; AbilityEligibility единственный final READY.
9. DevTools-only диагностика: `item_cd_api_missing`, `item_cd_secret`, `item_cd_disabled`, `item_cd_invalid_tuple`, `item_cd_gcd_only`, `item_cd_remaining_unknown`, `item_cd_group_unknown`, `item_cd_group_partial`, `item_cd_group_estimated`, `item_cd_group_conflict`, `item_cd_use_attribution_unknown`, `item_cd_ready_confirmed`.
10. Тесты: cooldown zero/active/expired, enabled bool/0/1/false, nil/secret/invalid numbers, own CD vs GCD, health/mana potion shared cooldown, healthstone independence, bandage and food, multiple ranks, absent item but active group lockout, item moved/split, cooldown starts after use, use-spell collision, combat secret, estimated last-use timer, reload/zone/clock discontinuity, missed BAG_UPDATE_COOLDOWN, API fallback, no false ready/no protected uses.

**Тесты и диагностика**

в файле не указано

**Архитектурные и обратные ссылки:** AC-02, IT-01, IT-04, IT-10, IT-08, IT-07, IT-06, IT-05, IT-03, SP-14, GR-05, PE-05, SW-04.

---

### IT-03 — Предмет можно использовать: в бою, на цель, нужен уровень, нужна зона

ID: [IT-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5005). Приоритет: P0. Lua: упомянут (точный статус в источнике).

**Вердикт / статус**

**Вердикт**

**ЧАСТИЧНО РЕАЛИЗОВАНО НА УРОВНЕ ОБЩЕГО КОНТЕКСТА — ДОРАБОТАТЬ (P0).** Kord умеет читать player level/combat и часть target facts, но не имеет подтверждённой item usability, item range, zone restrictions, item required level и item-specific final eligibility.

**Архитектурные ссылки:** IT-01, IT-02, SP-14, GR-05, EN-04, PE-05. Обратные ссылки внесены в эти требования в том же коммите.

**Изменения Lua:** отсутствуют. Только документация.

**Выбранный путь Kord**

**Выбранный путь Kord**

**Один `ItemUseEligibilityObservation` поверх IT-01 `InventoryObservation`, IT-02 `ItemCooldownObservation`/`SharedItemCooldownObservation`, общего `Player/TargetObservation`, `WorldContextObservation` и `ItemRestrictionCatalog`; финальный READY исключительно в `AbilityEligibility`.** Логические adapters, не обязательные новые Lua-файлы. `ItemUsabilityAdapter` через `C_Item.IsUsableItem` (legacy только после probe), `ItemTargetAdapter` через `C_Item.IsItemInRange` с подтверждённым target kind/self/no-target и отдельно отношением friendly/enemy, life state, LOS/range unknown. `ItemMetadataAdapter` через `C_Item.GetItemInfo`/cached item data и `GetItemInfoInstant` (проверять позиции tuple на Forever; **item level ≠ required player level**), `WorldContextObservation` — `GetInstanceInfo`, `IsInInstance`, stable zone/map ID при подтверждённом API, не локализованное имя как единственный ключ. `ItemRestrictionCatalog` версионирует Forever-specific `combatAllowed`, `minLevel`, `allowedZoneIDs`, `instanceTypes`, `targetKind`, `requiresOutOfCombat`, `requiresSpecificArea` и источник подтверждения; **не изобретать ограничения**, если они неизвестны. `IsUsableItem` является итоговым наблюдаемым клиентским gate, но не предоставляет причины и может меняться с combat/target; явные catalog rules дополняют, а не отменяют клиентский false. `InCombatLockdown` не равен `UnitAffectingCombat` и не доказывает, что предмет запрещён в бою.

`requiredLevel` должен браться из подтверждённого item metadata/policy, а не из `effective item level`; при недоступных item data `UNKNOWN`, bounded refresh при `GET_ITEM_INFO_RECEIVED` или подтверждённом `ITEM_DATA_LOAD_RESULT`. Zone check только при валидированных IDs и соответствующем каталоге; instance type и zone/map — разные измерения. Если `itemID` имеет no-target policy, отсутствие target не блокирует; если нужен target, `nil/secret` range/target -> UNKNOWN. Нельзя автоматически применять enemy spell range к предмету. Combat restrictions различают `cannotUseInCombat`, `oncePerCombat`, `potionSharedCooldown` и GCD: последние принадлежат IT-02 или отдельной combat-use policy, не объявляются одинаковыми. `ItemUseEligibilityObservation` содержит независимые результаты `inventory/cooldown/sharedCooldown/usable/combat/target/level/zone` с `BLOCKED` при доказанном нарушении, `UNKNOWN` при существенной неопределённости и `READY` только при всех подтверждённых gates. Профили не могут обойти UNKNOWN через `ignoreReady`.

Lazy `Needs.items.usability`, `Needs.worldContext` и per-evaluation memo; EventBus revisions по `PLAYER_REGEN_*`, `PLAYER_TARGET_CHANGED`, `PLAYER_LEVEL_UP`, `ZONE_CHANGED`, `ZONE_CHANGED_NEW_AREA`, `PLAYER_ENTERING_WORLD`, `GET_ITEM_INFO_RECEIVED`, подтверждённым item data/bag/cooldown events; нет постоянного сканирования зоны или сумок. Никаких protected item-use calls.

**Требуемые изменения (полный текст)**

**Требуемые изменения**

1. Ввести `ItemUseEligibilityObservation` с независимыми combat/target/level/zone/usable gates, reason/source/revision и fail-closed UNKNOWN.
2. Валидировать на Forever `C_Item.IsUsableItem`/legacy, secret/nil/false и itemID vs item use-spell; добавить GameAPI read-only allowlist.
3. Реализовать item-specific target policy: SELF/FRIENDLY/ENEMY/NONE/AREA/UNKNOWN, range `C_Item.IsItemInRange`, relation, dead/LOS, missing target; не использовать spell range как item range.
4. Ввести `ItemMetadataAdapter` с item required level (не item level), pending cache и validated Forever tuple; unknown metadata не превращать в level=0.
5. Ввести общий `WorldContextObservation` (instance/zone/map stable IDs) с typed secret-safe probes; использовать один provider для других требований зоны.
6. Ввести версионированный `ItemRestrictionCatalog` Forever-specific с подтверждёнными combat/level/zone/instance/target правилами; отсутствие правила не считать разрешением.
7. Переиспользовать IT-01 bag count и IT-02 item/shared cooldown; различать in-combat, lockdown, once-per-combat, shared potion lockout, GCD и target usability.
8. EventBus revisions combat/target/level/zone/item metadata/bag/cooldown; RotationConditions lazy `items.usable(itemID,context)` и Needs; AbilityEligibility единственный final READY.
9. DevTools-only диагностика: `item_usable_api_missing`, `item_usable_secret`, `item_unusable_unspecified`, `item_combat_rule_unknown`, `item_combat_blocked`, `item_target_policy_unknown`, `item_target_range_unknown`, `item_level_metadata_pending`, `item_level_too_low`, `item_zone_unknown`, `item_zone_blocked`, `item_instance_rule_unknown`, `item_eligibility_blocked`, `item_eligibility_unknown`.
10. Тесты: usable true/false/secret, potion in/out combat, combat lockdown mismatch, bandage in combat, healthstone, food/drink out of combat, self/friendly/enemy/no target, dead/invalid/out-of-range target, unknown range, level below/equal/above requirement, item level vs required level, uncached item metadata, zone transitions/instance map ID, locale independent zone, zone-limited item, missing rule, item present but cooldown active, shared potion cooldown, count unknown, delayed events, no false READY/protected item use.

**Тесты и диагностика**

в файле не указано

**Архитектурные и обратные ссылки:** AC-02, IT-01, IT-04, IT-11, IT-10, IT-09, IT-08, IT-07, IT-06, IT-05, IT-02, SP-14, GR-05, EN-04, PE-05.

---

### IT-04 — Выбор лучшего предмета из семейства: зелье здоровья с максимальным уровнем, который игрок может применить

ID: [IT-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5080). Приоритет: P0. Lua: упомянут (точный статус в источнике).

**Вердикт / статус**

**Вердикт**

**НЕ РЕАЛИЗОВАНО КАК УНИВЕРСАЛЬНАЯ ВОЗМОЖНОСТЬ — ДОРАБОТАТЬ (P0).** В Kord нет подтверждённого item family selector, validated tier catalog, item count/cooldown/usable eligibility. Частичный player level snapshot не решает выбор максимального применимого зелья.

**Архитектурные ссылки:** IT-01, IT-02, IT-03, SP-14, GR-05. Обратные ссылки внесены в эти требования в том же коммите.

**Изменения Lua:** отсутствуют. Только документация.

**Ретроактивное уточнение CL-07:** CL-07: Conjure Food/Water и Mana Gem требуют общего ItemInventoryProvider с selection по rank/level/quantity, но не приравниваются к health potion family.

**Выбранный путь Kord**

**Выбранный путь Kord**

**Один `ItemFamilySelectionObservation` поверх IT-01 `ItemFamilyCatalog`/`InventoryObservation`, IT-02 `ItemCooldownObservation`/`SharedItemCooldownObservation` и IT-03 `ItemUseEligibilityObservation`.** Добавить в **тот же** `ItemFamilyCatalog` для каждого itemID `familyID`, `tierOrder`, `requiredPlayerLevel` (с source и проверкой client metadata), `clientEdition`, `variant`, `tieBreakGroup`, `classificationConfidence`. Нет нового универсального файла или второго каталога. `tierOrder` — проверенный rank/grade в семье, **не** числовой itemID, itemLevel или размер tooltip heal. Forever custom variants `241650,247242,247241,247240,247239,4596,282011,223913,223914,287977,288896,287967,287966,268881–268883` проверять отдельно по реальной семантике, требованиям уровня, эффектам и принадлежности к `HEALTH_POTION`; не переносить порядок из смешанного `RegisterHealingItems` JustAC как абсолютный. `ALL_HEALING_ITEMS` — отдельная семья/политика для heal amount, не заменяющая `HEALTH_POTION`.

Алгоритм: получить **один** revision-consistent bag snapshot IT-01; взять unique itemIDs `HEALTH_POTION` и отсортировать по подтверждённому `tierOrder` по убыванию; для каждого кандидата лениво проверить `count`, `requiredLevel`, `playerLevel`, `C_Item.IsUsableItem`, combat, zone, target, IT-02 individual/shared cooldown. `BLOCKED` исключить с reason; `READY` кандидаты рассматриваются, но **итоговый READY только AbilityEligibility**. Если `UNKNOWN` у любого потенциально **более высокого или равного по tier** кандидата, не утверждать оптимальность: `selectionStatus=UNKNOWN`, можно сохранить provisional lower-tier ID **только для диагностики**, не для final recommendation. При проверенном `BLOCKED` высоком tier разрешён lower-tier fallback. Если все известны и ни один не проходит — `NONE_AVAILABLE`; если неизвестен любой существенный компонент — UNKNOWN. Если cooldown общий и активен, все соответствующие potions blocked; не предлагать младшее зелье как обход. `tieBreakPolicy` стабильный и документированный, при одинаковом tier с неодинаковым эффектом возможна отдельная стратегия `MAX_EXPECTED_HEAL` **только** по явному запросу профиля.

Не делать full tooltip parsing на каждом evaluation; async item metadata загружать ограниченно вне combat, с `GET_ITEM_INFO_RECEIVED`/`ITEM_DATA_LOAD_RESULT` revision, с ограничением retries. `GetItemInfo` requiredLevel проверять по фактической позиции/типу на Forever; не трактовать missing metadata как level=0. Item selection memo key: `familyID+policy+playerLevel+bagRevision+itemCooldownRevision+sharedCooldownRevision+combatRevision+targetRevision+worldRevision+catalogRevision`; event-driven invalidation, lazy `Needs.items.selection`, no protected item use. Различать selector `selectedItemID` и финальную eligibility. DevTools отдельно пишет кандидатов и причины.

**Требуемые изменения (полный текст)**

**Требуемые изменения**

1. Ввести `ItemFamilySelectionObservation` и стратегию `HIGHEST_USABLE_TIER` с SELECTED/NONE_AVAILABLE/UNKNOWN, confidence/reason/revision.
2. Расширить **существующий IT-01** `ItemFamilyCatalog` validated tier/requiredLevel/Forever variant/classification; не создавать второй consumables catalog.
3. Проверить на Forever классические и кастомные health potions, отделить `HEALTH_POTION` от `ALL_HEALING_ITEMS`/healthstones/bandages.
4. Переиспользовать IT-01 bag count и UNKNOWN semantics, dedup itemIDs, один snapshot и bounded lazy candidate evaluation.
5. Переиспользовать IT-03 item required level, usability, combat, target, zone; high-tier blocked по уровню -> lower-tier fallback, high-tier unknown -> UNKNOWN.
6. Переиспользовать IT-02 per-item/shared potion cooldown; group lockout запрещает fallback на lower-tier potion.
7. Ввести явный `tieBreakPolicy` для равного tier; `MAX_EXPECTED_HEAL` не включать по умолчанию.
8. RotationConditions `items.bestUsable(familyID,policy)` и lazy `Needs.items.selection`, AbilityEligibility единственный final READY, EventBus revisions для level/bag/item data/cooldown/combat/target/zone.
9. DevTools-only диагностика: `item_select_family_unknown`, `item_select_tier_unknown`, `item_select_higher_candidate_unknown`, `item_select_level_blocked`, `item_select_cooldown_blocked`, `item_select_shared_cd_blocked`, `item_select_zone_blocked`, `item_select_metadata_pending`, `item_select_lower_tier_fallback`, `item_select_best_confirmed`, `item_select_none_confirmed`.
10. Тесты: one potion, multiple tiers, only high-level potion while underleveled, high-tier unusable -> lower fallback, high-tier unknown -> UNKNOWN, high-tier absent confirmed, equal tier variants, custom Forever IDs, overlapping healing families, healthstone exclusion, missing tooltip metadata, requiredLevel vs itemLevel, individual/shared potion cooldown, in/out combat, zone-limited variant, secret bag count, player level-up, bag mutation, async item info, deterministic ties, no false best/READY/protected item use.

**Тесты и диагностика**

в файле не указано

**Архитектурные и обратные ссылки:** AC-02, IT-01, IT-14, IT-10, IT-09, IT-08, IT-07, IT-06, IT-05, IT-03, IT-02, SP-14, GR-05, CL-07.

---

### IT-05 — Камни здоровья и камни души чернокнижника: наличие, кулдаун, необходимость создания

ID: [IT-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5155). Приоритет: P1. Lua: упомянут (точный статус в источнике).

**Вердикт / статус**

**Вердикт**

**ЧАСТИЧНО РЕАЛИЗОВАНО НА УРОВНЕ ОБЩИХ SPELL/CLASS API — ДОРАБОТАТЬ (P1).** В Kord есть class/spellbook/cast/cooldown primitives, но нет подтверждённого stone inventory/cooldown/creation lifecycle, reagent check и Soulstone applied-aura policy.

**Архитектурные ссылки:** IT-01, IT-02, IT-03, IT-04, SP-14, GR-05, PE-05. Обратные ссылки внесены в эти требования в том же коммите.

**Изменения Lua:** отсутствуют. Только документация.

**Выбранный путь Kord**

**Выбранный путь Kord**

**Один логический `WarlockStoneObservation` / `StoneLifecyclePolicy` поверх IT-01 `InventoryObservation`, IT-02 `ItemCooldownObservation`, IT-03 `ItemUseEligibilityObservation`, IT-04 `ItemFamilySelectionObservation`, общего spellbook/cast/aura/AbilityEligibility.** Не создавать второй item scanner, cooldown adapter, rank selector или независимый class engine. `StoneFamilyCatalog` — **расширение того же IT-01 ItemFamilyCatalog**: HEALTHSTONE (classic/improved), SOULSTONE item variants (validated on Forever), SOUL_SHARD reagent (6265, client-gated), create spell family и applied aura spell family (разные ID namespaces). Сначала class check: `WARLOCK` открывает CREATE, остальные классы могут USE уже имеющиеся healthstones; неизвестный class -> UNKNOWN, не CREATE. Выбирать highest learned create rank, но только если его item output соответствует подтверждённому tier; наличие младшего камня при доступном старшем регулируется явной `replaceLowerTier` настройкой, по умолчанию не тратить shard ради замены без доказанной пользы. Учитывать стоимость осколков и резерв на более приоритетные warlock действия; `GetSpellPowerCost` не является доказательством количества classic bag reagent. Soulstone create может иметь spell cooldown, отличающийся от item use cooldown; не объединять их. Проверять текущий cast, `UNIT_SPELLCAST_SUCCEEDED` и последующее изменение сумки; success cast без bag arrival ещё не доказывает наличие предмета, bounded grace не означает CREATED. При отмене/ошибке каста — повторная оценка; suppress duplicate pending. Для Soulstone применение на friendly target/себя и наличие resurrection effect проверять отдельно по aura target; target unknown не превращать в applied=false. Рекомендация использования Soulstone в бою/вне боя зависит от проверенной Forever policy, не от одного общего правила.

`StoneLifecyclePolicy` отдаёт `USE` при подтверждённом need и IT-03 eligibility, `CREATE` только при подтверждённом отсутствии нужного stone, class WARLOCK, изученном create spell, наличии reagent и итоговом AbilityEligibility READY, `APPLY` только для Soulstone при наличии item, valid friendly target и проверенном aura/usage policy, `WAIT` при подтверждённом in-progress creation, `NONE` при доказанной ненужности, иначе `UNKNOWN`. Приоритет между healthstone и soulstone, расход shard, out-of-combat preparation и запрет spam — декларативная class policy. Lazy `Needs.items.stones`, revisions bag/spellbook/cast/item cooldown/auras/target/combat/class, bounded reads и DevTools-only reasons; никаких protected item uses/casts.

**Требуемые изменения (полный текст)**

**Требуемые изменения**

1. Ввести `WarlockStoneObservation` и `StoneLifecyclePolicy` с USE/CREATE/APPLY/WAIT/NONE/UNKNOWN и provenance.
2. Расширить IT-01 `ItemFamilyCatalog` healthstone/soulstone/improved/Forever variants и Soul Shard reagent, без второго каталога или bag scan.
3. Проверить Forever highest learned `Create Healthstone`/`Create Soulstone` ranks, created item outputs и applied Soulstone effect IDs; не смешивать spellID, itemID и auraID.
4. Реиспользовать IT-01 bag count и IT-04 best owned tier; неизвестное наличие -> UNKNOWN, не CREATE.
5. Реиспользовать IT-02 item/shared cooldown и **отдельный** spell cooldown создания; не принимать фиксированный 120s как универсальный факт.
6. Реиспользовать IT-03 item use combat/target/zone/level; отдельно Soulstone friendly-target and applied-aura observation.
7. Class gate WARLOCK только для CREATE; прочие классы могут использовать имеющийся Healthstone, class unknown fail-closed.
8. Реагент 6265 или подтверждённый Forever-specific resource, shard reserve, anti-duplicate cast/pending bag arrival, EventBus revisions, lazy Needs и финальный AbilityEligibility READY.
9. DevTools-only диагностика: `stone_class_unknown`, `stone_create_not_warlock`, `stone_family_count_unknown`, `stone_create_rank_unknown`, `stone_output_mapping_unknown`, `stone_reagent_unknown`, `stone_reagent_insufficient`, `stone_create_in_progress`, `stone_create_success_item_unconfirmed`, `stone_item_cd_unknown`, `stone_shared_cd_unknown`, `stone_soulstone_target_unknown`, `stone_soulstone_aura_unknown`, `stone_create_suppressed_owned`.
10. Тесты: warlock/non-warlock/unknown class, healthstone 0/1/multiple/improved ranks, soulstone 0/1, shard 0/1/secret, reagent reserve, highest learned rank, wrong spell output mapping, spell cooldown vs item cooldown, soulwell bag event missing, creation in progress/succeeded but bag not arrived/failed, low-tier owned high-tier known, no repeated create, Soulstone target friendly/dead/unknown, applied aura present/absent/secret, item use in/out combat, no false CREATE/READY or protected actions.

**Тесты и диагностика**

в файле не указано

**Архитектурные и обратные ссылки:** CL-08, IT-06, IT-01, IT-04, IT-02, IT-03, SP-14, GR-05, PE-05.

---

### IT-06 — Зелья маны и ресурса: порог процента, отличие боя и вне боя

ID: [IT-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5212). Приоритет: P1. Lua: упомянут (точный статус в источнике).

**Вердикт / статус**

**Вердикт**

**ЧАСТИЧНО РЕАЛИЗОВАНО НА УРОВНЕ RESOURCE/COMBAT API — ДОРАБОТАТЬ (P1).** Kord имеет typed player power, combat snapshot и `ReadPowerPercent`, но не имеет подтверждённого универсального mana/resource potion threshold policy, combat/ooc split, OOM fallback и item eligibility integration. Secret UI alpha **не** является доказательством branchable percent.

**Архитектурные ссылки:** IT-01, IT-02, IT-03, IT-04, IT-05, SP-14, SW-04. Обратные ссылки внесены в эти требования в том же коммите.

**Изменения Lua:** отсутствуют. Только документация.

**Ретроактивное уточнение CL-07:** CL-07: Mana Gem, Evocation и mana consumables используют общий ResourceStateProvider и item eligibility; conjured gem и spell не одно действие.

**Выбранный путь Kord**

**Выбранный путь Kord**

**Один логический `ResourceConsumableNeedObservation` и `ResourceConsumablePolicy` поверх общего typed `PlayerResourceObservation` из GameState, IT-01 `ItemFamilyCatalog`/`InventoryObservation`, IT-02 `ItemCooldownObservation`, IT-03 `ItemUseEligibilityObservation`, IT-04 `ItemFamilySelectionObservation`.** Никакого второго resource scanner, item scanner, ranked selector или отдельного cooldown engine. `ResourceThresholdObservation(powerType,thresholdPct)` предоставляет **два явно разных режима**: (A) `BRANCHABLE` — подтверждённый обычный процент или **клиентом доказанно branchable** boolean threshold; (B) `DISPLAY_ONLY` — secret curve/alpha, который разрешено передавать только в безопасный UI setter, **не сравнивать, не приводить к bool, не использовать для принятия решения в Lua**. Для `DISPLAY_ONLY` `thresholdBelow=UNKNOWN` в logic и отдельный `displayGate` для UI, если разрешён client API. При невозможности доказать boolean gate на Forever — не обещать пороговую рекомендацию в combat. Не переносить unsafe workaround, не превращать secret в readable через UI.

`ResourceConsumablePolicy` хранит `combatThresholdPct`, `oocThresholdPct`, `enabledInCombat`, `enabledOutOfCombat`, `powerType`, `minimumMissingResource` (только при readable numbers), `preferOOCDrink`, `potionConservation`, `oomFallbackEnabled` (явная настройка), `combatUrgency` и `recoveryPriority`. Для mana potion требуется **именно mana** или подтверждённый relevant typed mana pool; low rage/energy не является доказательством, что mana potion восстановит этот ресурс. `OOMObservation` на основе проверенного `noPower` при **изученном и релевантном** spellID может быть отдельным boolean signal для `OOM_FALLBACK`, но **не** эквивалентом `mana < X%`; при неизвестном noPower — UNKNOWN. Учитывать power type switch, player level, item effect/rank and cooldown; отсутствие предмета, shared potion lockout и forbidden combat use блокируют независимо от threshold. Вне боя low mana → преимущественно drink/food/class regeneration, если доступно и разрешено, potion only if explicit policy; не выдумывать наличие питья или его эффект без IT-01/03 и aura/cast observation.

`decision=RECOMMEND` только при доказанном `need` (`BRANCHABLE` threshold либо отдельно включённый подтверждённый OOM fallback), допустимом combat/ooc mode, IT-04 выбранном предмете, IT-01 count, IT-02 item+shared cooldown, IT-03 usability/level/zone/target, и итоговом `AbilityEligibility READY`. При secret/display-only и без OOM evidence → UNKNOWN; если UI-only подсказка возможна, её статус `DISPLAY_ONLY` и она **не** подменяет READY или основную ротацию. Lazy `Needs.items.resourceConsumable`, memo `powerType+threshold+mode+resourceRevision+combatRevision+bagRevision+itemCooldownRevision+worldRevision+catalogRevision`, bounded refresh. Конфликт OOM vs threshold, thresholds 0/100, power max=0, raw/curve scale 0..1 vs 0..100, stale observations и client secrets диагностируются, не интерпретируются оптимистично.

**Требуемые изменения (полный текст)**

**Требуемые изменения**

1. Ввести `ResourceConsumableNeedObservation` и `ResourceConsumablePolicy` с разными combat/ooc thresholds, mode, powerType и typed statuses.
2. Реиспользовать общий GameState typed player resource; валидировать на Forever числовой percent и branchable boolean threshold отдельно от UI-only secret alpha.
3. Если доступен только `DISPLAY_ONLY` secret curve, хранить logic UNKNOWN и визуальный gate отдельно; не использовать UI alpha для обхода secret restrictions.
4. Ввести опциональный `OOMObservation` по изученному релевантному spell noPower, с отдельным OOM_FALLBACK policy; не считать OOM точным процентом.
5. Реиспользовать IT-01 `MANA_POTION` и другие **проверенные** resource item families, без Retail-only IDs и дублирования каталога.
6. Реиспользовать IT-04 highest usable tier, IT-02 item/shared potion cooldown и IT-03 combat/level/zone/target eligibility; не предлагать другую potion при shared lockout.
7. Реализовать явную out-of-combat policy: drink/food/class recovery vs potion conservation, без выдуманного drink availability и без автокаста.
8. EventBus и lazy RotationConditions `resource.belowThreshold(powerType,mode)`, `items.resourcePotionNeed(family)`, per-evaluation memo, invalidate power/combat/bag/itemCD/zone/level.
9. DevTools-only диагностика: `resource_potion_power_type_mismatch`, `resource_potion_threshold_unknown`, `resource_potion_curve_display_only`, `resource_potion_oom_fallback`, `resource_potion_oom_unknown`, `resource_potion_mode_unknown`, `resource_potion_ooc_conserve`, `resource_potion_no_eligible_item`, `resource_potion_shared_cd_blocked`, `resource_potion_resource_max_invalid`, `resource_potion_percent_scale_unknown`, `resource_potion_ready_confirmed`.
10. Тесты: mana 0/19/20/21/100%, separate combat/ooc thresholds, threshold boundaries, 0/100 config, resource secret, display-only curve vs branchable boolean, powerType mana/rage/energy, druid form switch, warlock Life Tap, OOM noPower true/false/unknown, spell unlearned, out-of-combat drink available/unavailable, combat potion allowed/blocked, no item, multiple potion tiers, shared potion CD with health potion, zone/level restriction, raw max=0, scale 0..1 vs 0..100, stale power after combat switch, no false READY/protected item use.

**Тесты и диагностика**

в файле не указано

**Архитектурные и обратные ссылки:** IT-14, IT-09, IT-07, IT-02, IT-03, IT-01, IT-04, IT-05, SP-14, SW-04, CL-07.

---

### IT-07 — Зелья усиления и эликсиры: нужно ли обновить, остаток действия

ID: [IT-07](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5276). Приоритет: P1. Lua: упомянут (точный статус в источнике).

**Вердикт / статус**

**Вердикт**

**ЧАСТИЧНО РЕАЛИЗОВАНО НА УРОВНЕ ОБЩЕГО AURA API — ДОРАБОТАТЬ (P1).** Kord имеет aura presence и event invalidation, но не имеет подтверждённого универсального consumable buff catalog/remaining reader/refresh policy и compatibility checks.

**Архитектурные ссылки:** IT-01, IT-02, IT-03, IT-04, IT-06, SP-01, SP-14, GR-04. Обратные ссылки внесены в эти требования в том же коммите.

**Изменения Lua:** отсутствуют. Только документация.

**Выбранный путь Kord**

**Выбранный путь Kord**

**Один логический `ConsumableBuffMaintenanceObservation` + `ConsumableBuffPolicy` поверх существующего общего `PlayerAuraObservation` (SP-01), IT-01 `ItemFamilyCatalog`/`InventoryObservation`, IT-02 `ItemCooldownObservation`, IT-03 `ItemUseEligibilityObservation` и IT-04 `ItemFamilySelectionObservation`.** Не создавать отдельный buff scanner, bag scanner, item cooldown reader, tier selector или отдельный READY gate. В **тот же** `ItemFamilyCatalog` добавить `itemID`, `auraSpellIDs`, `category=FLASK/ELIXIR/...`, `effectStat`, `tierOrder`, `compatibilityGroup`, `overwritesGroups`, `clientEdition`, `source/verificationStatus`; использовать Forever-specific mappings JustAC, валидировать реальные игровые ограничения, не предполагать автоматически Retail-era battle/guardian flask slots. Разные itemIDs могут давать один auraID; разные ранги могут иметь отдельные auraIDs; dedup по effect family с provenance. Если идентификатор эффекта неизвестен, не объявлять отсутствие бафа.

`BuffDurationObservation` — **расширение того же общего aura provider SP-01**, с `PRESENT/ABSENT/UNKNOWN`, `remaining=FINITE/PERMANENT/UNKNOWN`, `expirationTime`, `durationSource`, `auraRevision`. Для подтверждённой aura `expirationTime` вычислять только из валидированных конечных readable данных и общего `GetTime`; отсутствие expiry может означать permanent **только если это подтверждено**. При secret duration `logicRemaining=UNKNOWN`, `displayRemaining` допускается через native DurationObject/UI binding, **но UI-only countdown нельзя использовать в Lua для REFRESH/READY**. Время обновления порога должно быть сравнимым в Lua или подтверждённым client-safe branchable boolean; иначе UNKNOWN, а не «скоро закончится».

`ConsumableBuffPolicy` сначала определяет желаемые stat/effect family по классу/спеку/контексту и пользовательской настройке (не объявлять любой доступный elixir нужным), затем проверяет текущие подтверждённые эффекты и совместимость: `KEEP` если действующий эффект того же или лучшего tier с remaining выше порога; `REFRESH` при доказанном отсутствии/истечении/низком remaining и отсутствии нежелательной замены; `WAIT` при подтверждённой боевой/политической блокировке или сохранении расходника; `UNKNOWN` при secret/missing duration, неясной совместимости, неполном catalog/ауре. При действующем более сильном бафе нельзя предлагать слабый, даже если он единственный в сумках. При одинаковом эффекте от разных источников не делать ложного вывода о расходнике по имени бафа. Для подтверждённо несовместимых elixirs/flasks не рекомендовать конфликтующий эффект без явного `allowOverwriteStronger` и проверки последствий. В бою/OOC, level, zone, item cooldown, bag count и item usability проверять через IT-01–03; лучший tier — IT-04. `REFRESH` есть **policy need**, а не final READY: только AbilityEligibility выдаёт READY после всех gates.

Lazy `Needs.items.buffMaintenance` с per-evaluation memo; invalidation по `UNIT_AURA`, bag/item cooldown, player identity/spec, combat/zone, item metadata и catalog revision. Не использовать бесконечный OnUpdate scan, secret comparisons, protected item use. DevTools фиксирует факты/причины, не сериализует secret.

**Требуемые изменения (полный текст)**

**Требуемые изменения**

1. Ввести `ConsumableBuffMaintenanceObservation` и настраиваемую `ConsumableBuffPolicy` с KEEP/REFRESH/WAIT/UNKNOWN.
2. Расширить общий aura provider SP-01 до duration/expiration с typed PRESENT/ABSENT/UNKNOWN и FINITE/PERMANENT/UNKNOWN; не создавать новый scanner.
3. Валидировать на Forever `C_UnitAuras.GetAuraDuration`, duration object/expiration и secret-safe branchability; UI-only countdown отдельно от Lua refresh decision.
4. Расширить **тот же IT-01** `ItemFamilyCatalog` itemID→buffSpellID, tier/stat/compatibility/edition, используя Forever catalog JustAC; не смешивать Retail IDs.
5. Проверить реальную совместимость flask/elixir, overwrite, stacking и rank/effect identity на Forever; не переносить неподтверждённые Retail правила.
6. Реиспользовать IT-04 best usable tier, IT-01 count, IT-02 item cooldown, IT-03 combat/level/zone/target; не считать REFRESH итоговым READY.
7. Реализовать threshold seconds, pre-pull/OOC policy, in-combat refresh switch, stat preference и защиту от замены сильного бафа слабым.
8. EventBus aura/item/bag/combat/zone revisions, lazy `Needs.items.buffMaintenance`, per-evaluation memo, no duplicate scan.
9. DevTools-only диагностика: `consumable_buff_aura_unknown`, `consumable_buff_duration_secret`, `consumable_buff_duration_display_only`, `consumable_buff_mapping_unknown`, `consumable_buff_compatibility_unknown`, `consumable_buff_stronger_active`, `consumable_buff_refresh_due`, `consumable_buff_refresh_suppressed`, `consumable_buff_item_unavailable`, `consumable_buff_item_cd_blocked`, `consumable_buff_final_eligibility_unknown`.
10. Тесты: aura absent/present, finite remaining 0/below/equal/above threshold, permanent, secret duration, display-only countdown, same aura from multiple items, different rank auraIDs, custom Forever elixir/flask, weaker vs stronger, incompatible groups, compatibility unknown, class/spec preferred stats, item absent/secret count, cooldown active, combat/OOC, zone/level restrictions, aura refresh event and expiration race, player relog, no false REFRESH/READY/protected item use.

**Тесты и диагностика**

в файле не указано

**Архитектурные и обратные ссылки:** IT-10, IT-09, IT-08, IT-01, IT-04, SP-01, IT-02, IT-03, IT-06, SP-14, GR-04.

---

### IT-08 — Бинты: необходимость и вероятность успешного применения («Недавно перевязан», DoT, яд)

ID: [IT-08](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5340). Приоритет: P2. Lua: упомянут (точный статус в источнике).

**Вердикт / статус**

**Вердикт**

**ЧАСТИЧНО РЕАЛИЗОВАНО НА УРОВНЕ ОБЩИХ HEALTH/AURA/CAST API — ДОРАБОТАТЬ (P2).** Kord имеет health, aura и cast primitives, но нет подтверждённой bandage family eligibility, Recently Bandaged target debuff, periodic-damage risk и safe-channel policy.

**Архитектурные ссылки:** IT-01, IT-02, IT-03, IT-04, IT-07, SP-01, SP-14, GR-05, TH-01. Обратные ссылки внесены в эти требования в том же коммите.

**Изменения Lua:** отсутствуют. Только документация.

**Выбранный путь Kord**

**Выбранный путь Kord**

**Один `BandageNeedAndSafetyObservation` + `BandagePolicy` поверх IT-01 inventory/catalog, IT-02 item cooldown, IT-03 item eligibility, IT-04 family selector, общего health snapshot, SP-01 aura provider, GR-05 target selection и TH-01 threat.** Не создавать отдельный scanner бинтов, дебафов, DoT или здоровья. Расширить **тот же IT-01 ItemFamilyCatalog**: `BANDAGE` itemIDs, `tierOrder`, `requiredPlayerLevel`, `healingAmount`, `channelDuration`, `clientEdition`, `source/verificationStatus`; классические/Forever варианты и spell effects проверять на клиенте, не выводить эффект по itemID. `RecentlyBandagedAuraCatalog` — логическая категория в **общем aura spell catalog SP-01**, с проверенными ID и вариантами Forever; не искать только по локализованной строке «Недавно перевязан». Проверять `recentlyBandaged` именно на **предполагаемой цели лечения**, не только на player; для self/player target использовать canonical GUID dedup. `UnitAura` positive/negative classification и `C_UnitAuras` secret-safe, nil не считать отсутствием без доказанной полноты чтения. Отдельно проверять `periodicDamageAuraObservation`: debuff school/type, periodic damage behavior, poison/bleed/magic и source только из подтверждённого catalog или combat-log evidence; **не каждый яд наносит периодический урон** и не каждый harmful aura прерывает bandage. Если DoT active и `avoidAnyPeriodicDamage`, SUPPRESS; если нет подтверждённого DoT, но данные неполные — UNKNOWN, не SAFE.

`BandageRiskObservation` агрегирует `periodicDamageRisk`, `incomingDamageRisk`, `targetHasAggro`, `recentDamageObserved`, `channelInProgress`, `combatState`, `riskWindowSeconds`. Угроза/агро — косвенный сигнал, не предсказание гарантированного попадания; recent damage от `COMBAT_LOG_EVENT_UNFILTERED` — только если разрешён, читаем и корректно сопоставлен по GUID, иначе UNKNOWN. Не использовать secret combat-log payload для Lua сравнения. `safeToBandage=CONFIRMED_SAFE` возможно лишь при достаточной полноте **наблюдаемых** фактов (нет блокирующего дебафа, нет подтверждённого DoT/текущего урона, нет явной угрозы прерывания), и даже это **не гарантия будущего**. `riskUnknown` по умолчанию подавляет рискованную рекомендацию, `allowRiskyBandage` — явный пользовательский override **только risk policy**, не обход hard restriction/AbilityEligibility.

Порог здоровья `healthThresholdPct` и `minMissingHealth` требуют branchable typed health; secret percent UI-only не использовать для Lua-ветвления (см. IT-06). `needBandage` только при подтверждённой нужде и доступном целевом юните, IT-04 выбирает лучший подтверждённо применимый бинт, IT-02/03 подтверждают item readiness, `recentlyBandaged=false` и risk policy допускает канал; финальный READY выдаёт только AbilityEligibility. Низкое здоровье при UNKNOWN aura не разрешает бинт. В бою и вне боя отдельные политики: OOC может быть предпочтительнее food/heal, in combat допускается только при явной настройке и подтверждённой пригодности. Не начинать новый bandage при уже активном channel/cast; отслеживать событие прерывания/успеха для диагностики, не создавать таймеров без evidence. Lazy `Needs.items.bandageSafety`, memo по targetGUID/health/aura/item/bag/combat/target/threat revisions; event-driven bounded updates.

**Требуемые изменения (полный текст)**

**Требуемые изменения**

1. Ввести `BandageNeedAndSafetyObservation`/`BandagePolicy` с need, hard-block, periodic risk, channel risk и tri-state.
2. Расширить IT-01 `ItemFamilyCatalog` verified BANDAGE tiers/level/healing/channel/Forever IDs; не создавать новый scanner.
3. Расширить SP-01 общий aura provider для `player/friendly harmful auras`, Recently Bandaged IDs и secret-safe remaining; не дублировать ауры.
4. Разделить `RecentlyBandaged` hard block и DoT/poison/bleed **risk**, подтверждать тип периодического урона, не считать любой яд DoT.
5. Реиспользовать health threshold/deficit с branchable semantics и IT-04 best usable tier, IT-01 count, IT-02 cooldown, IT-03 target/level/zone/combat.
6. Реиспользовать GR-05 healing target и TH-01 incoming threat; recent damage только из validated GUID combat-log evidence, без гарантии будущего.
7. Ввести отдельные in-combat/OOC policies, `avoidAnyPeriodicDamage`, `allowRiskyBandage`, `minMissingHealth`, `healthThresholdPct`, suppress already channeling.
8. EventBus UNIT_AURA/health/combat/item/bag/target/threat/channel revisions, lazy `Needs.items.bandageSafety`, per-evaluation memo.
9. DevTools-only диагностика: `bandage_recently_bandaged`, `bandage_recently_bandaged_unknown`, `bandage_dot_confirmed`, `bandage_dot_classification_unknown`, `bandage_poison_non_dot`, `bandage_incoming_damage_risk`, `bandage_risk_unknown`, `bandage_health_threshold_unknown`, `bandage_channel_active`, `bandage_target_unknown`, `bandage_item_unavailable`, `bandage_ready_confirmed`.
10. Тесты: self/friendly targets, Recently Bandaged present/absent/secret, remaining duration, DoT/bleed/poison with and without periodic damage, multiple debuffs, incomplete aura scan, target under attack/no aggro/recent damage/unknown threat, player combat/OOC, health 0/threshold±1/100 and secret, max heal vs missing HP, item absent/secret, tier fallback, item cooldown, channel active/interrupted/completed, target dead/out-of-range, no false SAFE/READY/protected item use.

**Тесты и диагностика**

в файле не указано

**Архитектурные и обратные ссылки:** IT-09, IT-01, IT-04, SP-01, GR-05, TH-01, IT-02, IT-03, IT-06, IT-07, SP-14.

---

### IT-09 — Еда и питьё вне боя, пища питомца

ID: [IT-09](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5397). Приоритет: P1. Lua: упомянут (точный статус в источнике).

**Вердикт / статус**

**Вердикт**

**ЧАСТИЧНО РЕАЛИЗОВАНО НА УРОВНЕ ОБЩИХ PLAYER/PET/RESOURCE/AURA API — ДОРАБОТАТЬ (P1).** В Kord есть player health/mana/combat, pet snapshot и aura primitives, но нет подтверждённого OOC food/drink selector, active eating suppression, pet diet/food compatibility и Feed Pet lifecycle policy.

**Архитектурные ссылки:** IT-01, IT-03, IT-04, IT-06, IT-07, IT-08, PE-02, PE-05, SP-14. Обратные ссылки внесены в эти требования в том же коммите.

**Изменения Lua:** отсутствуют. Только документация.

**Выбранный путь Kord**

**Выбранный путь Kord**

**Один `OutOfCombatRecoveryObservation`/`RecoveryConsumablePolicy` и `PetFeedingNeedObservation`/`PetFeedingPolicy` поверх IT-01 `InventoryObservation`/`ItemFamilyCatalog`, IT-03 `ItemUseEligibilityObservation`, IT-04 `ItemFamilySelectionObservation`, SP-01 общего aura reader, GameState player health/mana/combat и PE-02 `PetHappinessObservation`.** Это два логических policy consumers **одних универсальных источников**, а не два новых inventory/aura/pet engines. В том же `ItemFamilyCatalog` расширить `FOOD`, `DRINK`, `FOOD_AND_DRINK`, `PET_FOOD` с verified `itemID`, `requiredLevel`, `healthRestore`, `manaRestore`, `duration`, `dietType`, `petLevelCompatibility`, `auraSpellIDs`, `clientEdition`, `source`. Не выводить pet diet из human food family; `PET_FOOD` — подтверждённая совместимость вида еды с diet текущего pet, а не просто любой мясной предмет. Учитывать уровень/тип питомца и изменения Forever, не предполагать что pet can eat everything.

**Player recovery:** OOC должен быть подтверждён `UnitAffectingCombat`, `InCombatLockdown` использовать только по его собственной семантике; `COMBAT`/UNKNOWN suppress OOC recovery. Проверять alive, not mounted/moving, no active cast/channel, не предлагать повторно при `EATING`/`DRINKING`/`COMBINED` auras; если aura secret/partial — UNKNOWN, не считать absent. Оценивать health/mana пороги **только branchable** (см. IT-06); raw/secret UI alpha не использовать в Lua. Учитывать combined item при обоих дефицитах, separate item при одном, rank/restore amount/minimum missing resources и conserve policy. `Well Fed` stat buff — отдельная IT-07 maintenance policy, не смешивать с фактом текущего eating; наличие Well Fed не доказывает, что player всё ещё ест. Включить recovery items в **внебоевую** рекомендацию, не выдавать их как боевую ability, не рекомендовать новую еду во время действующего восстановления.

**Pet feeding:** только `UnitClass=HUNTER`, pet exists/alive/confirmed own hunter pet, `GetPetHappiness`/validated `C_PetInfo.GetPetHappiness` на Forever с tri-state, и изученный `Feed Pet` spellID 6991. Если happiness < threshold (по умолчанию цель HAPPY, но не выдумывать клиентский numeric scale) и pet diet/level compatibility подтверждены, выбрать подходящую `PET_FOOD` из **того же** bag snapshot; если pet dead/missing/unknown mood/diet/food data — не рекомендовать FEED. Проверить `GetPetFoodTypes`/pet family diet или клиентский эквивалент и item subtype/tooltip только после capability probe; отсутствующий API не означает, что любая еда подходит. Feed Pet может требовать последующего выбора предмета/cursor action: **аддон не должен пытаться программно использовать protected spell/item или симулировать клики**, а должен показывать допустимую подсказку, при необходимости отдельно spell и compatible item, с UI контрактом `requiresManualFoodSelection`. После подтверждённого spellcast/aura/mood change suppress повторную рекомендацию на bounded grace, но не считать кормление успешным без evidence. Вне боя, pet care PE-05 и другие более приоритетные pet actions координировать через общий priority policy; голод питомца не равен низкому pet HP.

**Инвалидация:** EventBus player health/power/combat, `UNIT_AURA`, `UNIT_PET`, `PET_BAR_UPDATE`, pet happiness/diet events если подтверждены, bag/metadata/spellbook/level revisions, cast/move/mount transitions; bounded refresh и lazy `Needs.items.recovery`/`Needs.pet.feeding`. Item selection и eligibility — IT-01–04, final READY только AbilityEligibility. DevTools не сериализует secret.

**Требуемые изменения (полный текст)**

**Требуемые изменения**

1. Ввести `OutOfCombatRecoveryObservation`/`RecoveryConsumablePolicy` и `PetFeedingNeedObservation`/`PetFeedingPolicy`, без нового item scanner.
2. Расширить **тот же IT-01 ItemFamilyCatalog** Forever food/drink/combined/pet food, recovery amount, level/diet/aura metadata, edition and provenance.
3. Реиспользовать IT-06 health/mana branchable thresholds и OOC mode; не принимать secret percent или UI-only curve за условие Lua.
4. Расширить SP-01 общий aura reader для eating/drinking/combined и Well Fed (IT-07 отдельно), UNKNOWN при неполной/secret ауре.
5. Реиспользовать IT-04 ranked item selection и IT-03 item usability, учитывая дефицит ресурсов, restore amount, class/powerType, level и conserve policy.
6. Реиспользовать PE-02 pet happiness и PE-01 pet identity, проверить на Forever `GetPetFoodTypes`/pet diet/food compatibility/level; без второго pet reader.
7. Проверить learned `Feed Pet` 6991, class HUNTER, alive pet, OOC, manual cursor food-selection contract и anti-repeat после подтверждённого результата.
8. EventBus bag/health/power/aura/combat/pet/diet/spellbook/cast revisions; lazy Needs, per-evaluation memo и bounded refresh, no protected actions.
9. DevTools-only диагностика: `recovery_combat_blocked`, `recovery_percent_unknown`, `recovery_active_eating`, `recovery_aura_unknown`, `recovery_food_unavailable`, `recovery_drink_unavailable`, `recovery_combined_selected`, `recovery_mount_moving_blocked`, `pet_feed_not_hunter`, `pet_feed_pet_missing`, `pet_feed_mood_unknown`, `pet_feed_diet_unknown`, `pet_feed_food_incompatible`, `pet_feed_food_missing`, `pet_feed_spell_unknown`, `pet_feed_manual_item_required`, `pet_feed_pending_result`.
10. Тесты: OOC/combat/unknown, health-only/mana-only/both, mana vs rage/energy, low/high thresholds and secret percent, food/drink/combined item choices, already eating/drinking/Well Fed, interrupted meal, moving/mounted/dead/casting, bag count unknown/zero, wrong item level, conjured/custom Forever items, hunter/non-hunter, pet missing/dead/low mood/happy/unknown mood, diet compatible/incompatible/unknown, food level requirement, Feed Pet learned/unlearned, pending cursor selection, pet mood change and bag arrival, no duplicate recommendations/no false READY/protected actions.

**Тесты и диагностика**

в файле не указано

**Архитектурные и обратные ссылки:** IT-01, IT-04, IT-06, IT-08, PE-02, PE-05, SP-14, IT-03, SP-01, IT-07, PE-01.

---

### IT-10 — Яды, смазки, пропитки оружия: оставшееся время, нужно ли обновить

ID: [IT-10](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5454). Приоритет: P1. Lua: упомянут (точный статус в источнике).

**Вердикт / статус**

**Вердикт**

**НЕ РЕАЛИЗОВАНО КАК УНИВЕРСАЛЬНАЯ ВОЗМОЖНОСТЬ — ДОРАБОТАТЬ (P1).** Kord имеет общий aura reader, но не имеет подтверждённого temporary weapon enchant API/slot observation, timer/charges, item-to-enchant catalog и refresh policy.

**Архитектурные ссылки:** IT-01, IT-02, IT-03, IT-04, IT-07, SP-01, SP-14, PE-04. Обратные ссылки внесены в эти требования в том же коммите.

**Изменения Lua:** отсутствуют. Только документация.

**Выбранный путь Kord**

**Выбранный путь Kord**

**Один `WeaponTemporaryEnchantObservation` с `WeaponEnchantRefreshPolicy`** поверх `GameAPI` read-only adapter, общего `ItemFamilyCatalog` IT-01, IT-02 item cooldown, IT-03 eligibility, IT-04 family selection и единого `AbilityEligibility`. Не создавать по сканеру для rogue/shaman/warlock, не создавать отдельный consumable catalog, не использовать SP-01 player aura как доказательство отсутствия покрытия. В `GameAPI` добавить capability-probed `C_Item.GetWeaponEnchantInfo` для Forever, `C_PaperDollInfo.GetTemporaryEnchantmentInfo`/legacy только после проверки формата; нормализовать slot `MAIN_HAND/OFF_HAND`, hasEnchant, enchantID/type, remaining и charges с `READY/UNKNOWN`, не интерпретировать secret/nil/unsupported enum как false. Для `C_Item.GetWeaponEnchantInfo` проверять формат list/enum/remaining unit непосредственно на клиенте; legacy `GetWeaponEnchantInfo` возвращает другой tuple, и смешение ms/sec опасно. Для временного покрытия с известным `remaining=0` и `hasEnchant=true` перепроверить событие/момент, не заявлять ложное отсутствие. Оружие и тип слота получать из read-only `GetInventoryItemLink('player',16/17)`/verified slot metadata; unknown equipment → UNKNOWN.

В **том же** IT-01 `ItemFamilyCatalog` описать `WEAPON_POISON`, `WEAPON_OIL`, `SHARPENING_STONE`, `WEIGHTSTONE`, `CLASS_IMBUE`, `enchantID`, `itemID/spellID`, `compatibleWeaponTypes`, `handRestrictions`, `tierOrder`, `overwritesGroups`, `class/spec`, `edition`, `source/verified`. `CLASS_IMBUE` может быть заклинанием, поэтому не требовать item count; яды rogue и oils/stones используют item inventory, если Forever edition это подтверждает. Отдельно различать **слои временных enchant categories**, если клиент допускает совместное наложение (например, Sonah описывает coexistence); нельзя считать любой найденный temporary enchant доказательством наличия именно желаемой категории. При отсутствии category-specific API и возможных нескольких покрытиях → UNKNOWN, не REFRESH. Конфликтующее покрытие, stronger existing tier, incompatible weapon или неизвестное overwrite rule подавляют замену; пользовательская `allowOverwrite` не отменяет item eligibility.

`WeaponEnchantRefreshPolicy` хранит `enabled`, `refreshThresholdSeconds`, `prePullOnly`, `allowInCombat`, `mainHandPreference`, `offHandPreference`, `allowOverwriteWeaker`, `allowOverwriteStronger=false`, `conserveConsumables`. `KEEP` если желаемый confirmed enchant active и remaining > threshold, `REFRESH` при confirmed near expiry, `APPLY` при confirmed missing desired category, `SUPPRESS` при incompatible/stronger/disabled/no weapon, `UNKNOWN` при secret duration, category ambiguity, unsupported API, missing catalog. Переключение оружия/dual wield/смена экипировки инвалидирует slot observation и повторно проверяет тип/наличие, не переносит старый timer на новое оружие. Сравнение `remaining <= threshold` допустимо только для **branchable** числа/boolean, display-only curve — отдельно и не влияет на READY. Для class imbue использовать spellbook/ability eligibility, для item coating IT-01–04; итоговый READY только `AbilityEligibility`. EventBus `UNIT_INVENTORY_CHANGED`/`PLAYER_EQUIPMENT_CHANGED` (после проверки Forever), bag/item cooldown, spellcast/aura/class/spec/zone revisions и bounded heartbeat для приближения expiry; lazy `Needs.weaponEnchants`, per-evaluation memo, no protected actions.

**Требуемые изменения (полный текст)**

**Требуемые изменения**

1. Ввести `WeaponTemporaryEnchantObservation` с per-slot/per-category typed remaining/charges и `WeaponEnchantRefreshPolicy`.
2. Добавить capability-probed read-only `C_Item.GetWeaponEnchantInfo`, `C_PaperDollInfo.GetTemporaryEnchantmentInfo`/legacy adapter и проверить Forever tuple, enum, ms/sec, secret semantics.
3. Ввести общий `WeaponEquipmentObservation` main/off weapon presence/type/identity и equip revision, без второго scanner.
4. Расширить **IT-01 ItemFamilyCatalog** Forever poisons/oils/stones/class imbues, tier, enchantID, weapon masks, coexistence and overwrite rules.
5. Реиспользовать IT-01 count, IT-02 cooldown, IT-03 usability/level/combat/weapon compatibility, IT-04 best tier; spell class imbue проверять через spellbook, не требовать item.
6. Реализовать независимые main/off refresh thresholds и policies, pre-pull, in-combat, conservation, stronger protection, category-specific presence.
7. Разделить itemID/spellID/enchantID, permanent enchant/player aura/temporary enchant, branchable timer vs display-only secret.
8. EventBus equipment/bag/itemCD/spellcast/zone/class revisions + bounded expiry heartbeat; lazy Needs и per-evaluation memo.
9. DevTools-only диагностика: `weapon_enchant_api_missing`, `weapon_enchant_secret`, `weapon_enchant_slot_unknown`, `weapon_enchant_no_weapon`, `weapon_enchant_type_unknown`, `weapon_enchant_duration_unit_unknown`, `weapon_enchant_category_ambiguous`, `weapon_enchant_compatibility_unknown`, `weapon_enchant_stronger_active`, `weapon_enchant_refresh_due`, `weapon_enchant_keep`, `weapon_enchant_item_unavailable`, `weapon_enchant_spell_unlearned`, `weapon_enchant_equipment_changed`.
10. Тесты: main/off, one/two weapons, dual wield, missing weapon, swapped weapon, enchant absent/present, 0/threshold±1/long duration, milliseconds vs seconds, nil/secret time, category poison/oil/stone/class imbue, coexistence vs overwrite, stronger/weaker, rogue learned poison and items, shaman imbue spell, warlock Firestone/Spellstone, custom Forever oil IDs and weapon masks, item count/cooldown, class/spec changes, combat/OOC, event missed with bounded refresh, no false APPLY/REFRESH/READY/protected use.

**Тесты и диагностика**

в файле не указано

**Архитектурные и обратные ссылки:** IT-03, SP-14, IT-01, IT-02, IT-04, SP-01, IT-07, PE-04.

---

### IT-11 — Реагенты, боеприпасы, символы: хватает ли — P1

ID: [IT-11](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5509). Приоритет: P1. Lua: упомянут (точный статус в источнике).

**Вердикт / статус**

в файле не указано

**Выбранный путь Kord**

**Каноническая архитектура**

Ввести один `RequiredMaterialsObservation` (провайдер, не второй eligibility engine), вызываемый лениво через `Needs.materials`. Вход: `actionKind`, `spellID/itemID`, `rank`, `weaponSlot`, контекст клиента; выход: `requirementKind`, `itemID`, `requiredCount`, `availableCount`, `compatible`, `status`, `reason`, `source`, `revision`. Список требований — из проверяемого каталога/достоверного API; неизвестное требование не трактовать как отсутствие требований. Несколько материалов: все обязательные должны быть подтверждены; один достоверно отсутствующий → BLOCKED; хотя бы один неизвестный без другого BLOCKED → UNKNOWN.

**Реагенты:** отдельно стоимость предмета, число единиц, специальные class resources и charges; наличие компонента в сумках проверять через **IT-01**, не собственным сканером. **Боеприпасы:** проверить необходимость для конкретной атаки, тип дальнобойного оружия, допустимый тип/слот, фактическую доступность и требуемое количество; при версии клиента без ammo mechanic вернуть NOT_REQUIRED лишь после достоверного определения capability. **Символы:** отличать установленные пассивные модификаторы от действительно обязательных для способности условий; не считать glyph самостоятельным расходником. Не путать glyph, rune, talent и reagent.

Интеграция: `IT-01` единый inventory count/catalog; `IT-03` item usability; `IT-12` on-use предметы с расходом материала; spellbook/known/rank и equip observation для заклинаний/боеприпасов; окончательный `READY` выдаёт только `AbilityEligibility`. Для `IT-02` cooldown не дублировать. EventBus ревизии сумок, экипировки, класса/талантов/символов/заклинаний, смены зоны; per-evaluation memo, ленивые проверки, не полное сканирование каждый тик. Никаких protected actions.

**Требуемые изменения (полный текст)**

в файле не указано

**Тесты и диагностика**

**Диагностика и тесты**

DevTools reason codes: `materials_missing`, `materials_unknown`, `materials_not_required`, `ammo_missing`, `ammo_incompatible`, `ammo_requirement_unknown`, `glyph_modifier_not_required`, `materials_api_unavailable`; согласовать с реестром кодов перед реализацией. Сценарии: 0/1/N реагентов, несколько реагентов, secret/nil, смена сумок, отсутствие/смена ranged weapon, совместимые/несовместимые патроны, клиент без ammo mechanic, glyph модифицирует эффект без обязательности, glyph действительно обязателен по каталогу, item on-use с reagent, ранги и кэш, один материал BLOCKED + другой UNKNOWN, без ложного READY и без автоприменения. **LOCAL/CI/CLIENT NOT RUN.**

**Архитектурные и обратные ссылки:** CL-04, CL-06, IT-10, IT-01, IT-03, IT-12, IT-02, IT-04, IT-05, IT-06, IT-07, IT-08, IT-09.

---

### IT-12 — Активируемые предметы (аксессуары, инженерные устройства): кулдаун, пригодность — P1

ID: [IT-12](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5554). Приоритет: P1. Lua: упомянут (точный статус в источнике).

**Вердикт / статус**

в файле не указано

**Выбранный путь Kord**

**Решение для Kord**

**Один общий путь предметной пригодности** (предметный провайдер GameState → `AbilityEligibility`), а не отдельный движок аксессуаров или инженерных устройств. Использовать общий контракт кулдаунов IT-02, ограничений использования IT-03 и необходимых материалов IT-11; IT-12 добавляет обнаружение on-use эффекта, экипированного слота (включая 13/14), контекстную классификацию (offensive/defensive/utility/PvP-breaker/engineering/unknown) и политику рекомендации. Не объявлять незнакомый предмет наступательным только потому, что у него есть use-spell.

Проверки: (1) itemID/слот и актуальность экипировки/инвентаря; (2) существование подтверждённого активируемого эффекта; (3) читаемый cooldown, `enabled`, общий/shared cooldown и отсутствие ложной готовности от GCD; (4) `IsUsableItem` и отдельные требования уровня, профессии, зоны, боя и цели, когда подтверждены; (5) материалы IT-11, если требуются; (6) профильная уместность и синхронизация с burst/defensive окном. Не смешивать **техническую доступность** и **стратегическую целесообразность**. Не рекомендовать автоматическое использование и не выполнять каст.

**Результат:** `READY` / `BLOCKED` / `UNKNOWN` / `NOT_APPLICABLE` с кодом причины и источником. `READY` от провайдера означает лишь подтверждённость его части условий; финальный `READY` выдаёт только `AbilityEligibility`. `nil`, secret, неподтверждённая категория, нечитабельный cooldown → `UNKNOWN`, если от значения зависит решение. Наблюдаемое использование и сохранённая длительность могут быть диагностикой/подсказкой, но не доказательством текущей готовности. Кэш только в рамках согласованного snapshot/ревизий EventBus; инвалидировать при смене экипировки, сумок, предметном cooldown, входе/выходе из боя, смене зоны и других релевантных событиях. Дорогие запросы — лениво, только для кандидатов.

**API-кандидаты для проверки на точном Forever:** `GetInventoryItemID`, `GetInventoryItemCooldown`, `C_Item.GetItemSpell`, `C_Item.GetItemCooldown`, `C_Item.IsUsableItem`. Проверить signature, secret-поведение, профессии/инженерные ограничения и shared cooldown в актуальной матрице; не заявлять CLIENT PASS.

**Минимальные изменения при будущей реализации:** расширить существующий предметный GameState/Eligibility контракт и DevTools reason codes, добавить тестовые фикстуры; не создавать отдельный `TrinketEngine`. Новые UI-переключатели — только при необходимости и с 6 локалями. Ожидаемая стоимость — небольшой провайдер/правила, без крупных библиотек; фактические размер и производительность не измерены. Лицензионный подход: заимствовать принципы, не копировать код референсов.

**Тесты:** пустые слоты 13/14; пассивный аксессуар; on-use аксессуар READY; активный cooldown; GCD при свободном item cooldown; shared cooldown двух предметов; предмет непригоден по уровню/профессии/зоне/цели/бою; инженерный предмет; PvP-breaker не классифицируется как damage; secret/nil cooldown → UNKNOWN; смена экипировки и инвалидация кэша; стратегически неуместный, но технически доступный предмет не рекомендуется; отсутствие повторного сканирования за оценку. Статусы тестов: **LOCAL NOT RUN; CLIENT NOT RUN; CI NOT RUN**.

**Требуемые изменения (полный текст)**

в файле не указано

**Тесты и диагностика**

в файле не указано

**Архитектурные и обратные ссылки:** IT-14, IT-02, IT-03, IT-11, IT-13, IT-10, IT-01.

---

### IT-13 — Экстренное спасение: камень, зелье, щит; порог HP, смерть цели рядом — P1

ID: [IT-13](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5597). Приоритет: P1. Lua: упомянут (точный статус в источнике).

**Вердикт / статус**

в файле не указано

**Выбранный путь Kord**

в файле не указано

**Требуемые изменения (полный текст)**

в файле не указано

**Тесты и диагностика**

в файле не указано

**Архитектурные и обратные ссылки:** IT-14, IT-04, IT-05, IT-12, IT-02, IT-03, IT-06, IT-07, IT-08, IT-09, IT-10, IT-11, IT-01.

---

### IT-14 — Настройка: выбранные игроком предметы, пороги, автоподбор

ID: [IT-14](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5650). Приоритет: P0. Lua: упомянут (точный статус в источнике).

**Вердикт / статус**

**Вердикт**

**ТРЕБУЕТ ПРОВЕРКИ И ДОРАБОТКИ (P0).** Требования к выбору, порогам и автоподбору сформулированы; степень реализации в Lua и совместимость конкретных API не подтверждены.

**Архитектурные ссылки:** IT-01–IT-13. Обратные ссылки на IT-14 уже внесены в IT-01, IT-04, IT-06, IT-12 и IT-13; остальные должны быть добавлены при проверке соответствующих записей.

**Изменения Lua:** отсутствуют. Только документация.

**Выбранный путь Kord**

**Выбранный путь Kord**

Расширить существующую конфигурацию Kord общей **политикой выбора предмета**, а не отдельным движком ротации. Для каждого семейства хранить `enabled`, `selectionMode=AUTO/MANUAL`, `manualItemID`, `allowList/denyList`, `priority`, `conserveRare`, `combatPolicy`, категорийные `thresholds` и `refreshThresholdSeconds`. Для отключённой категории не показывать рекомендацию. Настройки должны иметь безопасные значения по умолчанию, валидацию диапазонов и миграцию SavedVariables.

В режиме `MANUAL` искать только выбранный предмет/разрешённый пользователем эквивалент; отсутствие, неподходящий уровень, cooldown, недостаток компонентов или UNKNOWN отображать как причину отказа. В режиме `AUTO` получать кандидатов через **IT-01**, ранжировать через **IT-04** и фильтровать через **IT-02/IT-03/IT-11**; предпочтения игрока применяются до окончательного выбора, но не отменяют ограничения клиента. При конфликте нескольких категорий использовать общий приоритет ротации. Для экстренного применения использовать IT-13, для on-use — IT-12; не создавать второй emergency/item engine.

Разделять HP%, mana/resource%, время оставшегося эффекта (секунды), пороги для питомца, боевые условия и индивидуальные настройки категорий. Не использовать `nil`/secret как нулевое значение и не считать display-only данные разрешением на ветвление. Смена предметов в сумках, экипировки, уровня, специализации и настроек должна инвалидировать релевантный кэш; чтение ленивое и с memo в рамках оценки. Интерфейс обязан показывать AUTO/MANUAL, выбранный item, пороги и причины недоступности, с подсказками на существующих шести языках.

**Требуемые изменения (полный текст)**

**Требуемые изменения**

1. Провести построчный аудит существующих UI, SavedVariables, профилей, GameState, ItemFamilyCatalog, AbilityEligibility и референсных ZIP; зафиксировать реальные API/строки и отсутствие или наличие уже готовых настроек.
2. Добавить в существующие настройки категории расходников режимы `AUTO/MANUAL/OFF`, выбранный itemID, приоритеты, запреты и политику экономии редких предметов.
3. Реализовать раздельные пороги HP, маны/ресурса, бафов/пропиток, боя/вне боя, питомца и экстренного использования с явными единицами и границами сравнения.
4. В AUTO использовать IT-01/IT-04 для каталога и ранжирования; IT-02/IT-03/IT-11 для проверок. В MANUAL не выполнять незаметную замену выбранного предмета.
5. Связать настройки с IT-05–IT-13 без второго scanner, eligibility engine и без protected actions; итоговый READY только через общий `AbilityEligibility`.
6. Добавить в UI отображение выбора, причины блокировки, сброс параметров, подсказки и переводы на шесть языков.
7. Обеспечить сохранение по персонажу/специализации, безопасную миграцию SavedVariables, корректное поведение после смены спека и обновления каталога.
8. Добавить EventBus config/bag/equipment/cooldown/level/spec revisions, lazy needs, memo и диагностику DevTools: режим, itemID, порог, фактическое значение (если разрешено), причина отбора/отказа, ревизия.
9. Тесты: AUTO/MANUAL/OFF, предмет отсутствует/недоступен, два уровня зелий, запрет и экономия редкого, cooldown/shared cooldown, nil/secret, HP/resource threshold ±1, бой/OOC, pet, weapon coating, смена сумок/экипировки/спека, сохранение/миграция, шесть локализаций, отсутствие ложного READY и автоприменения.

**Тесты и диагностика**

в файле не указано

**Архитектурные и обратные ссылки:** IT-01, IT-02, IT-03, IT-04, IT-06, IT-07, IT-08, IT-09, IT-10, IT-13, IT-11, IT-12, IT-05.

---

