# 4. Зависимости контрактов

Граф: «контракт → зависит от». Простая обратная ссылка без слов зависимости не задаёт направление.

Контрактов 147, выведенных рёбер 42.

## ActionButtonPresentationObservation

зависимость в файле не указана.

## ActionLockObservation

зависимость в файле не указана.

## AmmoEquipmentProvider

зависимость в файле не указана.

## AoEControlSafetyObservation

зависимость в файле не указана.

## AoEHealGeometryPolicy

- **AoEHealGeometryPolicy → GroupRosterObservation**: из карточки [GR-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4196) (ссылка на [GR-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3888)): «1. Переиспользовать GR-01 roster/GUID/range, GR-02 health/life, GR-05 care candidates и SP-08/14 common spell eligibility; запретить отдельный AoE-heal roster scanner.»

## AoEPolicyObservation

- **AoEPolicyObservation → TargetRangeObservation**: из карточки [EN-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3455) (ссылка на [EN-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3153)): «3. Использовать один deduplicated GUID count EN-01/EN-03, не nameplate raw count.»

## AuraCancellationObservation

зависимость в файле не указана.

## AuraPresenceObservation

- **AuraPresenceObservation → GroupRosterObservation**: из карточки [GR-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4070) (ссылка на [GR-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3888)): «1. Переиспользовать GR-01 roster, GR-02 life/connectivity, GR-03 общий aura reader, SP-01/02 spell identity/ranks и SP-08/14 friendly eligibility; не создавать параллельный обход группы.»

## AutoAttackNeedPolicy

зависимость в файле не указана.

## AutoAttackStateProvider

зависимость в файле не указана.

## AutoShotClipWindowObservation

- **AutoShotClipWindowObservation → PlayerAutoAttackObservation**: из карточки [SW-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4735) (ссылка на [SW-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4623)): «2. Переиспользовать SW-01 Auto Shot active и SW-02 ranged remaining с подтверждённым phase confidence; неизвестный/устаревший timer — UNKNOWN.»

## BandageNeedAndSafetyObservation

- **BandageNeedAndSafetyObservation → ItemFamilySelectionObservation**: из карточки [IT-08](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5340) (ссылка на [IT-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5080)): «5. Реиспользовать health threshold/deficit с branchable semantics и IT-04 best usable tier, IT-01 count, IT-02 cooldown, IT-03 target/level/zone/combat.»
- **BandageNeedAndSafetyObservation → HealPriorityPolicy**: из карточки [IT-08](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5340) (ссылка на [GR-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4125)): «6. Реиспользовать GR-05 healing target и TH-01 incoming threat; recent damage только из validated GUID combat-log evidence, без гарантии будущего.»

## BandagePolicy

зависимость в файле не указана.

## BandageRiskObservation

зависимость в файле не указана.

## BuffDurationObservation

зависимость в файле не указана.

## CastDisruptionProvider

зависимость в файле не указана.

## CastObservation

- **CastObservation → PetObservation**: из карточки [PE-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4497) (ссылка на [PE-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4251)): «1. Переиспользовать PE-01 petGUID, PE-02 health, PE-04 spell/cooldown, общий cast/aura reader; **не создавать** отдельный pet scanner или cooldown provider.»

## CCBreakerCatalog

- **CCBreakerCatalog → PlayerControlObservation**: из карточки [CC-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5772) (ссылка на [CC-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5706)): «**Архитектурная актуализация CC-03:** для root/snare и решения об освобождении использовать общий `PlayerControlObservation` CC-01 и `ControlBreakSelection` CC-02; CC-03 добавляет отдельную политику необходимости снятия замедления/обездвиживания, а не второй LoC reader или breaker catalog (см. CC-03).»

## ComboPointStateProvider

- **ComboPointStateProvider → WeaponEnchantRefreshPolicy**: из карточки [CL-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9267) (ссылка на [IT-10](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5454)): «5. Подключить MH/OH poisons через общий WeaponEnchantProvider **IT-10**, включая remaining/charges/inventory.»

## ConsumableBuffMaintenanceObservation

- **ConsumableBuffMaintenanceObservation → ItemFamilySelectionObservation**: из карточки [IT-07](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5276) (ссылка на [IT-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5080)): «6. Реиспользовать IT-04 best usable tier, IT-01 count, IT-02 item cooldown, IT-03 combat/level/zone/target; не считать REFRESH итоговым READY.»

## ConsumableBuffPolicy

зависимость в файле не указана.

## ControlBreakRiskObservation

- **ControlBreakRiskObservation → AuraPresenceObservation**: из карточки [TG-07](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L2869) (ссылка на [AU-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L2021)): «1. Повторно использовать AU-01/AU-05 aura reader, AU-02 duration и targetGUID TG-01; не создавать второй scanner.»

## CooldownGroupProvider

зависимость в файле не указана.

## CooldownObservation

зависимость в файле не указана.

## CrowdControlStateProvider

зависимость в файле не указана.

## CurseFamilyProvider

зависимость в файле не указана.

## DemonPetObservation

зависимость в файле не указана.

## DispelStateProvider

зависимость в файле не указана.

## DisplayVisibilityPolicy

зависимость в файле не указана.

## DotCoverageObservation

зависимость в файле не указана.

## DruidFormPolicy

зависимость в файле не указана.

## EnemyCastObservation

зависимость в файле не указана.

## EnemyProximityObservation

зависимость в файле не указана.

## EnemySchoolLockoutObservation

- **EnemySchoolLockoutObservation → InterruptOpportunityObservation**: из карточки [CC-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5949) (ссылка на [CC-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5889)): «6. Добавить `RotationConditions` `target.schoolLocked(schoolMask)`, `target.schoolLockoutRemaining`, `Needs.enemySchoolLockout`; использовать для контекста CC-04, не подменять `target.castInterruptible`.»

## EquipmentObservation

зависимость в файле не указана.

## ExclusiveAuraModeProvider

зависимость в файле не указана.

## FearControlObservation

зависимость в файле не указана.

## FormStanceObservation

зависимость в файле не указана.

## FormStateProvider

- **FormStateProvider → SpellFamilyCatalog**: из карточки [CL-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9376) (ссылка на [CL-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9039)): «8. Использовать общий `friendly_dead` из CL-02 для Resurrection, не менять live-friendly healing gate.»

## FriendlyUnitSelectionProvider

зависимость в файле не указана.

## GCDObservation

зависимость в файле не указана.

## GetAuraDataByIndex

зависимость в файле не указана.

## GroupAoEHealCoverageObservation

зависимость в файле не указана.

## GroupCareCandidateObservation

зависимость в файле не указана.

## GroupMemberRoleObservation

зависимость в файле не указана.

## GroupMemberVitalsObservation

зависимость в файле не указана.

## GroupRosterObservation

зависимость в файле не указана.

## HealEligibilityProvider

зависимость в файле не указана.

## HealPriorityPolicy

- **HealPriorityPolicy → GroupRosterObservation**: из карточки [GR-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4125) (ссылка на [GR-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3888)): «1. Переиспользовать GR-01 GUID-keyed roster и GR-02 health/life/role; один общий candidate index для heal/res, без дополнительного полного сканера группы.»

## HoTCoverageObservation

зависимость в файле не указана.

## HunterRangeObservation

зависимость в файле не указана.

## InterruptAbilityCatalog

зависимость в файле не указана.

## InterruptCandidateObservation

зависимость в файле не указана.

## InterruptOpportunityObservation

зависимость в файле не указана.

## InterruptStateProvider

зависимость в файле не указана.

## InventoryObservation

зависимость в файле не указана.

## InventoryReadAdapter

зависимость в файле не указана.

## ItemCooldownAdapter

зависимость в файле не указана.

## ItemCooldownObservation

- **ItemCooldownObservation → InventoryObservation**: из карточки [IT-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4932) (ссылка на [IT-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4852)): «**Один логический `ItemCooldownObservation` + `SharedItemCooldownObservation` поверх IT-01 `InventoryObservation`/`ItemFamilyCatalog` и единого EventBus.** `ItemCooldownAdapter` — read-only `C_Item.GetItemCooldown`, fallback `C_Container.GetItemCooldown` и legacy **только** после Forever API probe; `C_Item.GetItemSpell` — дополнительная проверка item use-spell identity, не замена itemID. Нормализовать `enabled` (bool/0/1), проверять secret/finite/start/duration/clock. `active=true` при подтверждённом cooldown с положительным remaining; `active=false` только при валидированном нуле; и»

## ItemFamilyCatalog

зависимость в файле не указана.

## ItemFamilySelectionObservation

- **ItemFamilySelectionObservation → InventoryObservation**: из карточки [IT-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5080) (ссылка на [IT-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4852)): «4. Переиспользовать IT-01 bag count и UNKNOWN semantics, dedup itemIDs, один snapshot и bounded lazy candidate evaluation.»
- **ItemFamilySelectionObservation → ItemUseEligibilityObservation**: из карточки [IT-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5080) (ссылка на [IT-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5005)): «5. Переиспользовать IT-03 item required level, usability, combat, target, zone; high-tier blocked по уровню -> lower-tier fallback, high-tier unknown -> UNKNOWN.»
- **ItemFamilySelectionObservation → ItemCooldownObservation**: из карточки [IT-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5080) (ссылка на [IT-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4932)): «6. Переиспользовать IT-02 per-item/shared potion cooldown; group lockout запрещает fallback на lower-tier potion.»

## ItemMetadataAdapter

зависимость в файле не указана.

## ItemRestrictionCatalog

зависимость в файле не указана.

## ItemTargetAdapter

зависимость в файле не указана.

## ItemUsabilityAdapter

зависимость в файле не указана.

## ItemUseEligibilityObservation

- **ItemUseEligibilityObservation → InventoryObservation**: из карточки [IT-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5005) (ссылка на [IT-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4852)): «7. Переиспользовать IT-01 bag count и IT-02 item/shared cooldown; различать in-combat, lockdown, once-per-combat, shared potion lockout, GCD и target usability.»

## LifeTapSafetyPolicy

зависимость в файле не указана.

## MeleeSwingQueueProvider

зависимость в файле не указана.

## MovementImpairmentRemovalPolicy

- **MovementImpairmentRemovalPolicy → PlayerControlObservation**: из карточки [CC-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5834) (ссылка на [CC-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5706)): «Ввести **`MovementImpairmentRemovalPolicy`** поверх **единого** `PlayerControlObservation` (CC-01) и `ControlBreakSelection` (CC-02). Сначала установить, что именно действует: `ROOT`, `SNARE` или оба; при отсутствии достоверного LoC API и неизвестной aura mapping не утверждать `FALSE`. Отдельно определить `movementNeeded` по уже имеющимся проверенным сигналам движка (расстояние до цели/нужна позиция, маршрут отступления, опасная зона только при наличии достоверного источника, ручной приоритет PvP). **Не выдумывать универсальный детектор опасной зоны или направление движения**, если с»

## MovementObservation

зависимость в файле не указана.

## MultiDotCandidateObservation

зависимость в файле не указана.

## NextSwingEmpowerObservation

зависимость в файле не указана.

## NextSwingNeedPolicy

зависимость в файле не указана.

## NextSwingSpellCatalog

зависимость в файле не указана.

## ObservedEnemyIndex

- **ObservedEnemyIndex → TargetRangeObservation**: из карточки [EN-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3226) (ссылка на [TG-09](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L2981)): «Выход: `confirmedEngagedCount` (нижняя граница), `possibleEngagedCount` (верхняя граница **среди наблюдаемых**), `observedHostileCount`, `coverage`, `status/reason`; точное `enemy.engagedWithGroupCount=READY(n)` только при доказанной полноте источников и классификации. При неполном охвате `UNKNOWN`, не `READY(0)`. Отдельные запросы `engagedWithGroupCount` и `engagedWithGroupWithinRadius(N)` не смешивать; второй переиспользует TG-09 интервальную дальность EN-01. Все проверки ленивые по `Needs.enemyGroupCount`; нет защищённых действий.»

## OOMObservation

зависимость в файле не указана.

## OutOfCombatRecoveryObservation

- **OutOfCombatRecoveryObservation → ResourceConsumableNeedObservation**: из карточки [IT-09](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5397) (ссылка на [IT-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5212)): «3. Реиспользовать IT-06 health/mana branchable thresholds и OOC mode; не принимать secret percent или UI-only curve за условие Lua.»
- **OutOfCombatRecoveryObservation → ItemFamilySelectionObservation**: из карточки [IT-09](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5397) (ссылка на [IT-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5080)): «5. Реиспользовать IT-04 ranked item selection и IT-03 item usability, учитывая дефицит ресурсов, restore amount, class/powerType, level и conserve policy.»
- **OutOfCombatRecoveryObservation → PetObservation**: из карточки [IT-09](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5397) (ссылка на [PE-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4313)): «6. Реиспользовать PE-02 pet happiness и PE-01 pet identity, проверить на Forever `GetPetFoodTypes`/pet diet/food compatibility/level; без второго pet reader.»

## PetActionCooldownObservation

зависимость в файле не указана.

## PetActionUsabilityObservation

- **PetActionUsabilityObservation → PetObservation**: из карточки [PE-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4431) (ссылка на [PE-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4251)): «1. Переиспользовать **один** pet actionbar adapter PE-01/PE-03, расширить slot record PE-04 полями cooldown, usable, autocastAllowed/enabled, command token, status/reason; не дублировать сканирование.»

## PetAttackActivityObservation

зависимость в файле не указана.

## PetAutocastObservation

зависимость в файле не указана.

## PetCareNeedPolicy

зависимость в файле не указана.

## PetCareTimingObservation

зависимость в файле не указана.

## PetCommandProvider

зависимость в файле не указана.

## PetFeedingNeedObservation

зависимость в файле не указана.

## PetFeedingPolicy

зависимость в файле не указана.

## PetHappinessObservation

зависимость в файле не указана.

## PetObservation

зависимость в файле не указана.

## PetStanceObservation

зависимость в файле не указана.

## PetStateProvider

зависимость в файле не указана.

## PetTargetObservation

зависимость в файле не указана.

## PetVitalsObservation

зависимость в файле не указана.

## PlayerAutoAttackObservation

зависимость в файле не указана.

## PlayerCastObservation

зависимость в файле не указана.

## PlayerControlObservation

зависимость в файле не указана.

## PlayerResourceObservation

зависимость в файле не указана.

## PlayerSwingObservation

зависимость в файле не указана.

## RangeObservation

зависимость в файле не указана.

## RecentlyBandagedAuraCatalog

зависимость в файле не указана.

## RecoveryConsumablePolicy

зависимость в файле не указана.

## RequiredMaterialsObservation

- **RequiredMaterialsObservation → InventoryObservation**: из карточки [IT-11](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5509) (ссылка на [IT-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4852)): «**Реагенты:** отдельно стоимость предмета, число единиц, специальные class resources и charges; наличие компонента в сумках проверять через **IT-01**, не собственным сканером. **Боеприпасы:** проверить необходимость для конкретной атаки, тип дальнобойного оружия, допустимый тип/слот, фактическую доступность и требуемое количество; при версии клиента без ammo mechanic вернуть NOT_REQUIRED лишь после достоверного определения capability. **Символы:** отличать установленные пассивные модификаторы от действительно обязательных для способности условий; не считать glyph самостоятельным расх»

## ResourceConsumableNeedObservation

- **ResourceConsumableNeedObservation → InventoryObservation**: из карточки [IT-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5212) (ссылка на [IT-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4852)): «5. Реиспользовать IT-01 `MANA_POTION` и другие **проверенные** resource item families, без Retail-only IDs и дублирования каталога.»
- **ResourceConsumableNeedObservation → ItemFamilySelectionObservation**: из карточки [IT-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5212) (ссылка на [IT-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5080)): «6. Реиспользовать IT-04 highest usable tier, IT-02 item/shared potion cooldown и IT-03 combat/level/zone/target eligibility; не предлагать другую potion при shared lockout.»

## ResourceConsumablePolicy

зависимость в файле не указана.

## ResourceReservePolicy

зависимость в файле не указана.

## ResourceTickProvider

зависимость в файле не указана.

## ResurrectionCandidatePolicy

зависимость в файле не указана.

## ResurrectionStateProvider

зависимость в файле не указана.

## SealJudgementStateProvider

зависимость в файле не указана.

## SelfResurrectionStateProvider

зависимость в файле не указана.

## SharedCooldownGroupCatalog

зависимость в файле не указана.

## SharedItemCooldownObservation

зависимость в файле не указана.

## ShotInteractionPolicy

зависимость в файле не указана.

## SoulShardObservation

- **SoulShardObservation → InventoryObservation**: из карточки [CL-08](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9713) (ссылка на [IT-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4852)): «2. Реализовать `SoulShardObservation` поверх IT-01/IT-05: validated `C_Item.GetItemCount`/legacy, bag revisions, reserved/current/available, pending creation arrival; не использовать `or 0` при secret и не считать каст фактом получения shard.»

## SpatialObservation

зависимость в файле не указана.

## SpellFamilyCatalog

зависимость в файле не указана.

## SpellKnowledgeObservation

зависимость в файле не указана.

## SpellRangeProvider

зависимость в файле не указана.

## SpellRequirementsObservation

зависимость в файле не указана.

## StanceStateProvider

- **StanceStateProvider → FormStanceObservation**: из карточки [CL-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L8925) (ссылка на [AC-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L6305)): «| Стойки | Battle Stance, Defensive Stance, Berserker Stance; Stance Mastery (если применимо к клиенту) | current stance index/token, learned/available, change permitted, combat, retained rage, GCD/cooldown, form events | `STANCE_OR_FORM` через AC-05; после смены повторная оценка, без предположения мгновенной готовности |»

## StatObservation

зависимость в файле не указана.

## StealthStateProvider

зависимость в файле не указана.

## StoneFamilyCatalog

зависимость в файле не указана.

## StoneLifecyclePolicy

зависимость в файле не указана.

## SummonedEntityObservation

- **SummonedEntityObservation → AoEHealGeometryPolicy**: из карточки [PE-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4568) (ссылка на [GR-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4196)): «6. Переиспользовать GR-06 spatial coverage contract для spell-specific summon-to-target effect radius, отдельно от cast range/guardian attack reach; без координат/ауры — UNKNOWN.»

## SummoningRitualObservation

зависимость в файле не указана.

## SwingEventAdapter

зависимость в файле не указана.

## SwingSpeedAdapter

зависимость в файле не указана.

## TalentObservation

зависимость в файле не указана.

## TargetHealthProvider

зависимость в файле не указана.

## TargetRangeObservation

зависимость в файле не указана.

## TargetSuggestionPolicy

- **TargetSuggestionPolicy → TargetRangeObservation**: из карточки [AC-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L6235) (ссылка на [EN-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3153)): «2. Реализовать `TargetSuggestionPolicy/Eligibility` поверх EN-01–EN-06, без отдельного сканирования nameplates/GUID и без автоматической смены цели.»

## TargetSwitchCandidateObservation

зависимость в файле не указана.

## TauntNeedObservation

зависимость в файле не указана.

## ThreatObservation

- **ThreatObservation → TargetRangeObservation**: из карточки [TH-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3701) (ссылка на [EN-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3153)): «5. Переиспользовать EN-01/02/03/08 индекс врагов и bounded refresh; отдельное чтение threat по `Needs` с per-pass memo, без полного nameplate scan при каждом запросе.»

## ThreatRiskObservation

зависимость в файле не указана.

## ThreatRiskPolicy

- **ThreatRiskPolicy → ThreatObservation**: из карточки [TH-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3770) (ссылка на [TH-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3701)): «1. Использовать единый TH-01 per-GUID/per-actor `ThreatObservation` и EN-03 identity, без дополнительного threat reader и nameplate scanner.»

## TotemStateProvider

- **TotemStateProvider → ExclusiveAuraModeProvider**: из карточки [CL-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9492) (ссылка на [CL-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9152)): «4. Подключить shock shared CD через **существующую запланированную общую задачу CL-03 CooldownGroupProvider**; никакого отдельного shaman cooldown таймера.»
- **TotemStateProvider → WeaponEnchantRefreshPolicy**: из карточки [CL-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9492) (ссылка на [IT-10](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5454)): «5. Подключить imbues через **IT-10 WeaponEnchantProvider** и per-hand equipment eligibility.»
- **TotemStateProvider → SpellFamilyCatalog**: из карточки [CL-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9492) (ссылка на [CL-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9039)): «7. Подключить Ancestral Spirit через **CL-02/CL-05 friendly_dead**, не изменять live-only healing gate.»

## TTDObservation

зависимость в файле не указана.

## UnitHealthObservation

зависимость в файле не указана.

## UnitIdentityIndex

зависимость в файле не указана.

## V14Registry

зависимость в файле не указана.

## WaitDecisionPolicy

зависимость в файле не указана.

## WarlockStoneObservation

- **WarlockStoneObservation → InventoryObservation**: из карточки [IT-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5155) (ссылка на [IT-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4852)): «4. Реиспользовать IT-01 bag count и IT-04 best owned tier; неизвестное наличие -> UNKNOWN, не CREATE.»
- **WarlockStoneObservation → ItemCooldownObservation**: из карточки [IT-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5155) (ссылка на [IT-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4932)): «5. Реиспользовать IT-02 item/shared cooldown и **отдельный** spell cooldown создания; не принимать фиксированный 120s как универсальный факт.»
- **WarlockStoneObservation → ItemUseEligibilityObservation**: из карточки [IT-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5155) (ссылка на [IT-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5005)): «6. Реиспользовать IT-03 item use combat/target/zone/level; отдельно Soulstone friendly-target and applied-aura observation.»

## WeaponEnchantProvider

зависимость в файле не указана.

## WeaponEnchantRefreshPolicy

- **WeaponEnchantRefreshPolicy → InventoryObservation**: из карточки [IT-10](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5454) (ссылка на [IT-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4852)): «5. Реиспользовать IT-01 count, IT-02 cooldown, IT-03 usability/level/combat/weapon compatibility, IT-04 best tier; spell class imbue проверять через spellbook, не требовать item.»
- **WeaponEnchantRefreshPolicy → ItemUseEligibilityObservation**: из карточки [IT-10](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5454) (ссылка на [IT-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5005)): «- `KordRotation/Core/AbilityEligibility.lua`: spell-centric final gate, нет отдельной item/weapon compatibility eligibility; использовать общую итоговую READY архитектуру IT-03/SP-14.»

## WeaponEquipmentObservation

зависимость в файле не указана.

## WorldContextObservation

зависимость в файле не указана.

## Циклы

не обнаружены
