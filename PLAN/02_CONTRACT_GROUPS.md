# 2. Группы по общим контрактам

Источник: PLAN/ITEMS/*.md, PLAN/01_INVENTORY.md, PLAN/03_MODULE_CHANGES.md и REQUIREMENTS.md.

- Контрактных имён до объединения: **160** (из них в прежнем 02 без модулей: 122).
- Контрактов после подтверждённых объединений: **147**.
- ID без общего контракта: **77**.

## ActionButtonPresentationObservation

- Имя первичного определения: `ActionButtonPresentationObservation` ([UI-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L7889)).
- Число ID: **1**.
- ID и приоритеты: [UI-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L7889) — P1.
- Затрагиваемые модули (03): DevTools, UI, BindingResolver; [UI-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L7889).

- `ActionButtonPresentationObservation`: [UI-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L7889). Цитата из [UI-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L7889): «1. Определить `ActionButtonPresentationObservation` и UI glow lifecycle (`activeButton`, `activeSpellID`, `revisions`, `reason`); не сохранять frame refs в SavedVariables.»

## ActionLockObservation

- Имя первичного определения: `ActionLockObservation` ([SW-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4735)).
- Число ID: **1**.
- ID и приоритеты: [SW-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4735) — P1.
- Затрагиваемые модули (03): EventBus, AbilityEligibility, RotationConditions, DevTools; [SW-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4735).

- `ActionLockObservation`: [SW-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4735). Цитата из [SW-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4735): «**Один `AutoShotClipWindowObservation` поверх SW-01 `PlayerAutoAttackObservation`, SW-02 `PlayerSwingObservation.ranged`, общего `CastTimingObservation` и spell metadata/policy.** Никакого второго swing scanner и отдельного hunter event loop. `ShotInteractionPolicy(spellFamily,clientBuild)` — проверенный Forever-каталог `PRESERVES/RESETS/PAUSES/UNKNOWN` (на базе ForeverAuras, но с валидацией конкретного билда); `ActionLockObservation` — реальный cast/channel duration + проверенные GCD/animation/shot locks»

## AmmoEquipmentProvider

- Имя первичного определения: `AmmoEquipmentProvider` ([CL-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9152)).
- Число ID: **1**.
- ID и приоритеты: [CL-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9152) — P0.
- Затрагиваемые модули (03): в файле не указано; [CL-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9152).

- `AmmoEquipmentProvider`: [CL-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9152). Цитата из [CL-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9152): «4. `AmmoEquipmentProvider`: ammo count/type, weapon compatibility, equip/availability; общий equipment gate `AbilityEligibility`.»

## AoEControlSafetyObservation

- Имя первичного определения: `AoEControlSafetyObservation` ([EN-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3376)).
- Число ID: **2**.
- ID и приоритеты: [EN-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3376) — P1; [EN-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3455) — P1.
- Затрагиваемые модули (03): EventBus, AbilityEligibility, UI; [EN-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3376), [EN-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3455).

- `AoEControlSafetyObservation`: [EN-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3376), [EN-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3455). Цитата из [EN-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3376): «**Не создавать новый CC scanner, nameplate scanner, GUID index или отдельный AoE engine.** Использовать один `UnitIdentityIndex` EN-03, `ObservedEnemyIndex` EN-01/02, `TargetControlObservation(unitGUID)` TG-07, `AuraPresenceObservation` AU-01/06 и `TargetRangeObservation` TG-09. Добавить только логический производный `AoEControlSafetyObservation` в общий pipeline условий.»

## AoEHealGeometryPolicy

- Имя первичного определения: `AoEHealGeometryPolicy` ([GR-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4196)).
- Число ID: **1**.
- ID и приоритеты: [GR-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4196) — P2.
- Затрагиваемые модули (03): EventBus, DevTools, UI; [GR-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4196).

- `AoEHealGeometryPolicy`: [GR-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4196). Цитата из [GR-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4196): «3. Ввести spell-specific `AoEHealGeometryPolicy` и `GroupAoEHealCoverageObservation` с раздельными count injured vs count eligible vs count geometrically confirmed, coverage/UNKNOWN.»

## AoEPolicyObservation

- Имя первичного определения: `AoEPolicyObservation` ([EN-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3153)).
- Число ID: **2**.
- ID и приоритеты: [EN-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3153) — P1; [EN-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3455) — P1.
- Затрагиваемые модули (03): EventBus, AbilityEligibility, UI; [EN-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3153), [EN-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3455).

- `AoEPolicyObservation`: [EN-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3153), [EN-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3455). Цитата из [EN-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3153): «`AoEPolicyObservation` потребляет count и explicit profile thresholds, но не подменяет `AbilityEligibility` и не переключает скрытно ручной режим. Никаких защищённых действий, сканирования невидимых unit tokens или искусственной точности.»

## AuraCancellationObservation

- Имя первичного определения: `AuraCancellationObservation` ([CL-09](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9827)).
- Число ID: **1**.
- ID и приоритеты: [CL-09](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9827) — P0.
- Затрагиваемые модули (03): EventBus, AbilityEligibility, DevTools; [CL-09](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9827).

- `AuraCancellationObservation`: [CL-09](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9827). Цитата из [CL-09](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9827): «7. **`AuraCancellationObservation`** — общий read-only контракт отменяемой self aura и выхода из формы, расширяющий PL-09/AC-05, **не** механизм автоматического `CancelAura`. Неразрешённый «срыв ауры» → `catalog_alias_unresolved`, STOP зависимого правила; пользовательская подсказка только при доказанном безопасном действии.»

## AuraPresenceObservation

- Имя первичного определения: `AuraPresenceObservation` ([EN-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3376)).
- Число ID: **11**.
- ID и приоритеты: [AU-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L2021) — P0; [CL-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L8925) — P0; [CL-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9039) — P0; [CL-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9152) — P0; [CL-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9376) — P0; [CL-08](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9713) — P0; [CL-09](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9827) — P0; [EN-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3376) — P1; [GR-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4070) — P2; [IT-07](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5276) — P1; [PE-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4497) — P2.
- Затрагиваемые модули (03): GameState, AbilityEligibility, RotationConditions, UI, GameAPI, EventBus, DevTools; [AU-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L2021), [CL-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L8925), [CL-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9039), [CL-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9152), [CL-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9376), [CL-08](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9713), [CL-09](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9827), [EN-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3376), [GR-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4070), [IT-07](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5276), [PE-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4497).

- `AuraObservation`: [GR-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4070), [PE-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4497). Цитата из [GR-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4070): «**Выбрать GR-01 GUID-keyed roster + общий per-member `AuraObservation` GR-03/RotationMaster + проверку `HELPFUL` семейств и post-cast suppression JustAC + классовые декларации семейств Sonah + event/secret boundary ForeverAuras.** Один логический `GroupBuffCoverageObservation(memberGUID,buffFamilyID)` возвращает подтверждённые `PRESENT/MISSING_CONFIRMED/REFRESH_DUE/NOT_APPLICABLE/UNKNOWN`, matching auraID/rank, source, observedAt, completeness. Отдельный `GroupBuffRecommendation(buffFamilyID,castSpellID)`»
- `AuraPresenceObservation`: [EN-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3376), [AU-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L2021). Цитата из [EN-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3376): «**Не создавать новый CC scanner, nameplate scanner, GUID index или отдельный AoE engine.** Использовать один `UnitIdentityIndex` EN-03, `ObservedEnemyIndex` EN-01/02, `TargetControlObservation(unitGUID)` TG-07, `AuraPresenceObservation` AU-01/06 и `TargetRangeObservation` TG-09. Добавить только логический производный `AoEControlSafetyObservation` в общий pipeline условий.»
- `AuraStateProvider`: [CL-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L8925), [CL-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9039), [CL-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9152), [CL-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9376), [CL-08](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9713), [CL-09](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9827). Цитата из [CL-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L8925): «4. `AuraStateProvider` — player buffs, target debuffs, remaining, ownership и UNKNOWN, общий механизм для криков.»
- `PlayerAuraObservation`: [IT-07](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5276). Цитата из [IT-07](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5276): «**Один логический `ConsumableBuffMaintenanceObservation` + `ConsumableBuffPolicy` поверх существующего общего `PlayerAuraObservation` (SP-01), IT-01 `ItemFamilyCatalog`/`InventoryObservation`, IT-02 `ItemCooldownObservation`, IT-03 `ItemUseEligibilityObservation` и IT-04 `ItemFamilySelectionObservation`.** Не создавать отдельный buff scanner, bag scanner, item cooldown reader, tier selector или отдельный READY gate. В **тот же** `ItemFamilyCatalog` добавить `itemID`, `auraSpellIDs`, `category=FLASK/ELIXIR»

## AutoAttackNeedPolicy

- Имя первичного определения: `AutoAttackNeedPolicy` ([SW-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4623)).
- Число ID: **1**.
- ID и приоритеты: [SW-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4623) — P0.
- Затрагиваемые модули (03): GameState, EventBus, AbilityEligibility, RotationConditions, DevTools; [SW-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4623).

- `AutoAttackNeedPolicy`: [SW-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4623). Цитата из [SW-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4623): «7. Отдельная `AutoAttackNeedPolicy`: alive attackable target, EN-04 breakable CC, proven melee/ranged range, weapon/ammo/standing/cast, no harmful toggles; fail-closed unknown.»

## AutoAttackStateProvider

- Имя первичного определения: `AutoAttackStateProvider` ([CL-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9376)).
- Число ID: **1**.
- ID и приоритеты: [CL-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9376) — P0.
- Затрагиваемые модули (03): AbilityEligibility; [CL-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9376).

- `AutoAttackStateProvider`: [CL-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9376). Цитата из [CL-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9376): «7. **`AutoAttackStateProvider`** — typed wand Shoot auto-repeat, toggle on/off, equipped wand, range, channel/cast interactions; общий с Hunter CL-03, но `wand` не равно `Auto Shot`.»

## AutoShotClipWindowObservation

- Имя первичного определения: `AutoShotClipWindowObservation` ([SW-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4735)).
- Число ID: **1**.
- ID и приоритеты: [SW-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4735) — P1.
- Затрагиваемые модули (03): EventBus, AbilityEligibility, RotationConditions, DevTools; [SW-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4735).

- `AutoShotClipWindowObservation`: [SW-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4735). Цитата из [SW-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4735): «**Один `AutoShotClipWindowObservation` поверх SW-01 `PlayerAutoAttackObservation`, SW-02 `PlayerSwingObservation.ranged`, общего `CastTimingObservation` и spell metadata/policy.** Никакого второго swing scanner и отдельного hunter event loop. `ShotInteractionPolicy(spellFamily,clientBuild)` — проверенный Forever-каталог `PRESERVES/RESETS/PAUSES/UNKNOWN` (на базе ForeverAuras, но с валидацией конкретного билда); `ActionLockObservation` — реальный cast/channel duration + проверенные GCD/animation/shot locks»

## BandageNeedAndSafetyObservation

- Имя первичного определения: `BandageNeedAndSafetyObservation` ([IT-08](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5340)).
- Число ID: **1**.
- ID и приоритеты: [IT-08](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5340) — P2.
- Затрагиваемые модули (03): EventBus, DevTools; [IT-08](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5340).

- `BandageNeedAndSafetyObservation`: [IT-08](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5340). Цитата из [IT-08](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5340): «**Один `BandageNeedAndSafetyObservation` + `BandagePolicy` поверх IT-01 inventory/catalog, IT-02 item cooldown, IT-03 item eligibility, IT-04 family selector, общего health snapshot, SP-01 aura provider, GR-05 target selection и TH-01 threat.** Не создавать отдельный scanner бинтов, дебафов, DoT или здоровья. Расширить **тот же IT-01 ItemFamilyCatalog**: `BANDAGE` itemIDs, `tierOrder`, `requiredPlayerLevel`, `healingAmount`, `channelDuration`, `clientEdition`, `source/verificationStatus`; классические/For»

## BandagePolicy

- Имя первичного определения: `BandagePolicy` ([IT-08](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5340)).
- Число ID: **1**.
- ID и приоритеты: [IT-08](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5340) — P2.
- Затрагиваемые модули (03): EventBus, DevTools; [IT-08](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5340).

- `BandagePolicy`: [IT-08](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5340). Цитата из [IT-08](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5340): «**Один `BandageNeedAndSafetyObservation` + `BandagePolicy` поверх IT-01 inventory/catalog, IT-02 item cooldown, IT-03 item eligibility, IT-04 family selector, общего health snapshot, SP-01 aura provider, GR-05 target selection и TH-01 threat.** Не создавать отдельный scanner бинтов, дебафов, DoT или здоровья. Расширить **тот же IT-01 ItemFamilyCatalog**: `BANDAGE` itemIDs, `tierOrder`, `requiredPlayerLevel`, `healingAmount`, `channelDuration`, `clientEdition`, `source/verificationStatus`; классические/For»

## BandageRiskObservation

- Имя первичного определения: `BandageRiskObservation` ([IT-08](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5340)).
- Число ID: **1**.
- ID и приоритеты: [IT-08](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5340) — P2.
- Затрагиваемые модули (03): EventBus, DevTools; [IT-08](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5340).

- `BandageRiskObservation`: [IT-08](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5340). Цитата из [IT-08](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5340): «`BandageRiskObservation` агрегирует `periodicDamageRisk`, `incomingDamageRisk`, `targetHasAggro`, `recentDamageObserved`, `channelInProgress`, `combatState`, `riskWindowSeconds`. Угроза/агро — косвенный сигнал, не предсказание гарантированного попадания; recent damage от `COMBAT_LOG_EVENT_UNFILTERED` — только если разрешён, читаем и корректно сопоставлен по GUID, иначе UNKNOWN. Не использовать secret combat-log payload для Lua сравнения. `safeToBandage=CONFIRMED_SAFE` возможно лишь при достаточной полноте»

## BuffDurationObservation

- Имя первичного определения: `BuffDurationObservation` ([IT-07](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5276)).
- Число ID: **1**.
- ID и приоритеты: [IT-07](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5276) — P1.
- Затрагиваемые модули (03): EventBus, DevTools, UI; [IT-07](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5276).

- `BuffDurationObservation`: [IT-07](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5276). Цитата из [IT-07](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5276): «`BuffDurationObservation` — **расширение того же общего aura provider SP-01**, с `PRESENT/ABSENT/UNKNOWN`, `remaining=FINITE/PERMANENT/UNKNOWN`, `expirationTime`, `durationSource`, `auraRevision`. Для подтверждённой aura `expirationTime` вычислять только из валидированных конечных readable данных и общего `GetTime`; отсутствие expiry может означать permanent **только если это подтверждено**. При secret duration `logicRemaining=UNKNOWN`, `displayRemaining` допускается через native DurationObject/UI binding»

## CastDisruptionProvider

- Имя первичного определения: `CastDisruptionProvider` ([CL-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9267)).
- Число ID: **1**.
- ID и приоритеты: [CL-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9267) — P0.
- Затрагиваемые модули (03): AbilityEligibility, WeaponEnchantProvider; [CL-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9267).

- `CastDisruptionProvider`: [CL-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9267). Цитата из [CL-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9267): «5. **`InterruptStateProvider`**: cast/channel/interruptible, cast remaining and Kick eligibility; **`CastDisruptionProvider`** отдельно оценивает CC break, DR/immunity, target validity; не маркировать Gouge гарантированным interrupt.»

## CastObservation

- Имя первичного определения: `CastObservation` ([PE-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4497)).
- Число ID: **2**.
- ID и приоритеты: [PE-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4497) — P2; [SW-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4735) — P1.
- Затрагиваемые модули (03): EventBus, AbilityEligibility, DevTools, RotationConditions; [PE-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4497), [SW-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4735).

- `CastObservation`: [PE-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4497). Цитата из [PE-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4497): «**Один логический `PetCareTimingObservation(petGUID,careActionFamily)` поверх PE-01/02/04, общего `CastObservation` GameState, `AuraObservation` GR-03/GR-04 и единого cooldown provider AbilityEligibility.** Отдельные поля `castDuration/remaining`, `lastStartedAt`, `lastSucceededAt`, `auraDuration/remaining`, `cooldownRemaining`, `petIdentityTransitionAt`, каждый со `status/source/reason/revision`; все времена в секундах после подтверждённого преобразования из клиентских миллисекунд, часы — единый валидиро»
- `CastTimingObservation`: [SW-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4735). Цитата из [SW-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4735): «**Один `AutoShotClipWindowObservation` поверх SW-01 `PlayerAutoAttackObservation`, SW-02 `PlayerSwingObservation.ranged`, общего `CastTimingObservation` и spell metadata/policy.** Никакого второго swing scanner и отдельного hunter event loop. `ShotInteractionPolicy(spellFamily,clientBuild)` — проверенный Forever-каталог `PRESERVES/RESETS/PAUSES/UNKNOWN` (на базе ForeverAuras, но с валидацией конкретного билда); `ActionLockObservation` — реальный cast/channel duration + проверенные GCD/animation/shot locks»

## CCBreakerCatalog

- Имя первичного определения: `CCBreakerCatalog` ([CC-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5772)).
- Число ID: **1**.
- ID и приоритеты: [CC-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5772) — P1.
- Затрагиваемые модули (03): EventBus, AbilityEligibility, RotationConditions, DevTools; [CC-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5772).

- `CCBreakerCatalog`: [CC-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5772). Цитата из [CC-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5772): «- `KordRotation/Core/GameAPI.lua:26,35`: есть read-only `IsUsableSpell`/`C_Spell.IsSpellUsable`, но не подтверждён отдельный источник `CCBreakerCatalog` и capability для точного сопоставления LoC mechanics с эффектами снятия.»

## ComboPointStateProvider

- Имя первичного определения: `ComboPointStateProvider` ([CL-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9267)).
- Число ID: **2**.
- ID и приоритеты: [CL-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9267) — P0; [CL-09](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9827) — P0.
- Затрагиваемые модули (03): AbilityEligibility, WeaponEnchantProvider, EventBus, DevTools; [CL-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9267), [CL-09](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9827).

- `ComboPointObservation`: [CL-09](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9827). Цитата из [CL-09](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9827): «3. **`ComboPointObservation` (CL-04)** — target GUID, current/cap, finisher requirements, loss/transfer on target change, form-specific gates; общая инфраструктура, отдельная Feral policy.»
- `ComboPointStateProvider`: [CL-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9267). Цитата из [CL-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9267): «1. **`ComboPointStateProvider`**: typed current/max, `targetIdentity`/revision, reset/move semantics только после проверки клиента, fail-closed при смене цели; переиспользуется другими классами, если combo resource применим.»

## ConsumableBuffMaintenanceObservation

- Имя первичного определения: `ConsumableBuffMaintenanceObservation` ([IT-07](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5276)).
- Число ID: **1**.
- ID и приоритеты: [IT-07](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5276) — P1.
- Затрагиваемые модули (03): EventBus, DevTools, UI; [IT-07](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5276).

- `ConsumableBuffMaintenanceObservation`: [IT-07](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5276). Цитата из [IT-07](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5276): «**Один логический `ConsumableBuffMaintenanceObservation` + `ConsumableBuffPolicy` поверх существующего общего `PlayerAuraObservation` (SP-01), IT-01 `ItemFamilyCatalog`/`InventoryObservation`, IT-02 `ItemCooldownObservation`, IT-03 `ItemUseEligibilityObservation` и IT-04 `ItemFamilySelectionObservation`.** Не создавать отдельный buff scanner, bag scanner, item cooldown reader, tier selector или отдельный READY gate. В **тот же** `ItemFamilyCatalog` добавить `itemID`, `auraSpellIDs`, `category=FLASK/ELIXIR»

## ConsumableBuffPolicy

- Имя первичного определения: `ConsumableBuffPolicy` ([IT-07](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5276)).
- Число ID: **1**.
- ID и приоритеты: [IT-07](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5276) — P1.
- Затрагиваемые модули (03): EventBus, DevTools, UI; [IT-07](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5276).

- `ConsumableBuffPolicy`: [IT-07](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5276). Цитата из [IT-07](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5276): «**Один логический `ConsumableBuffMaintenanceObservation` + `ConsumableBuffPolicy` поверх существующего общего `PlayerAuraObservation` (SP-01), IT-01 `ItemFamilyCatalog`/`InventoryObservation`, IT-02 `ItemCooldownObservation`, IT-03 `ItemUseEligibilityObservation` и IT-04 `ItemFamilySelectionObservation`.** Не создавать отдельный buff scanner, bag scanner, item cooldown reader, tier selector или отдельный READY gate. В **тот же** `ItemFamilyCatalog` добавить `itemID`, `auraSpellIDs`, `category=FLASK/ELIXIR»

## ControlBreakRiskObservation

- Имя первичного определения: `ControlBreakRiskObservation` ([TG-07](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L2869)).
- Число ID: **1**.
- ID и приоритеты: [TG-07](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L2869) — P1.
- Затрагиваемые модули (03): AbilityEligibility, RotationConditions; [TG-07](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L2869).

- `ControlBreakRiskObservation`: [TG-07](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L2869). Цитата из [TG-07](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L2869): «6. `ControlBreakRiskObservation` оценивает способность (single-target, AoE, cleave, DoT, pet) и текущие подтверждённые эффекты; наличие уже активного DoT и будущие тики учитывать отдельно от немедленного удара.»

## CooldownGroupProvider

- Имя первичного определения: `CooldownGroupProvider` ([CL-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9152)).
- Число ID: **2**.
- ID и приоритеты: [CL-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9152) — P0; [CL-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9492) — P0.
- Затрагиваемые модули (03): WeaponEnchantProvider; [CL-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9152), [CL-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9492).

- `CooldownGroupProvider`: [CL-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9152), [CL-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9492). Цитата из [CL-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9152): «2. `CooldownGroupProvider`: per-spell и shared cooldown groups для trap family; общий для других классов/предметов, без отдельных таймеров в профиле.»

## CooldownObservation

- Имя первичного определения: `CooldownObservation` ([SP-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L1106)).
- Число ID: **1**.
- ID и приоритеты: [SP-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L1106) — P0.
- Затрагиваемые модули (03): AbilityEligibility, UI; [SP-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L1106).

- `CooldownObservation`: [SP-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L1106). Цитата из [SP-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L1106): «2. Объединить факты с `CooldownObservation` из SP-03 без слияния их достоверности: `gcdOnly` подтверждать только когда индивидуальный cooldown достоверно неактивен, а GCD активен; `individual` — когда собственный cooldown подтверждён. При shared cooldown без достоверной классификации оставлять `unknown`.»

## CrowdControlStateProvider

- Имя первичного определения: `CrowdControlStateProvider` ([CL-08](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9713)).
- Число ID: **1**.
- ID и приоритеты: [CL-08](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9713) — P0.
- Затрагиваемые модули (03): GameAPI, EventBus, AbilityEligibility, DevTools; [CL-08](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9713).

- `CrowdControlStateProvider`: [CL-08](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9713). Цитата из [CL-08](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9713): «**Один Warlock policy layer на общей инфраструктуре, а не самостоятельный модуль-ротационный движок.** Для shards использовать IT-01 inventory/item family и IT-05 reagent budget; логический `SoulShardObservation` не создает второй bag scanner. `DemonPetObservation` расширяет PE-01–PE-05 единого `PetObservation` по owner/pet GUID, идентичность демона и pet spell availability; pet actions только AC-03, guardians и ритуал PE-06. `CurseFamilyProvider` — **конфигурация общего `AuraStateProvider`**: на пару (`t»

## CurseFamilyProvider

- Имя первичного определения: `CurseFamilyProvider` ([CL-08](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9713)).
- Число ID: **1**.
- ID и приоритеты: [CL-08](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9713) — P0.
- Затрагиваемые модули (03): GameAPI, EventBus, AbilityEligibility, DevTools; [CL-08](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9713).

- `CurseFamilyProvider`: [CL-08](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9713). Цитата из [CL-08](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9713): «**Один Warlock policy layer на общей инфраструктуре, а не самостоятельный модуль-ротационный движок.** Для shards использовать IT-01 inventory/item family и IT-05 reagent budget; логический `SoulShardObservation` не создает второй bag scanner. `DemonPetObservation` расширяет PE-01–PE-05 единого `PetObservation` по owner/pet GUID, идентичность демона и pet spell availability; pet actions только AC-03, guardians и ритуал PE-06. `CurseFamilyProvider` — **конфигурация общего `AuraStateProvider`**: на пару (`t»

## DemonPetObservation

- Имя первичного определения: `DemonPetObservation` ([CL-08](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9713)).
- Число ID: **1**.
- ID и приоритеты: [CL-08](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9713) — P0.
- Затрагиваемые модули (03): GameAPI, EventBus, AbilityEligibility, DevTools; [CL-08](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9713).

- `DemonPetObservation`: [CL-08](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9713). Цитата из [CL-08](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9713): «**Один Warlock policy layer на общей инфраструктуре, а не самостоятельный модуль-ротационный движок.** Для shards использовать IT-01 inventory/item family и IT-05 reagent budget; логический `SoulShardObservation` не создает второй bag scanner. `DemonPetObservation` расширяет PE-01–PE-05 единого `PetObservation` по owner/pet GUID, идентичность демона и pet spell availability; pet actions только AC-03, guardians и ритуал PE-06. `CurseFamilyProvider` — **конфигурация общего `AuraStateProvider`**: на пару (`t»

## DispelStateProvider

- Имя первичного определения: `DispelStateProvider` ([CL-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9039)).
- Число ID: **4**.
- ID и приоритеты: [CL-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9039) — P0; [CL-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9376) — P0; [CL-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9492) — P0; [CL-09](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9827) — P0.
- Затрагиваемые модули (03): UI, AbilityEligibility, WeaponEnchantProvider, EventBus, DevTools; [CL-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9039), [CL-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9376), [CL-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9492), [CL-09](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9827).

- `DispelStateProvider`: [CL-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9039), [CL-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9376), [CL-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9492), [CL-09](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9827). Цитата из [CL-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9039): «5. **`DispelStateProvider`** — общий по классам provider типов `Poison/Disease/Magic/Curse` с per-spell allowed dispel types; паладинские Purify/Cleanse получают только подтверждённые возможности. Aura `UNKNOWN` не равна dispellable.»

## DisplayVisibilityPolicy

- Имя первичного определения: `DisplayVisibilityPolicy` ([UI-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L8091)).
- Число ID: **2**.
- ID и приоритеты: [UI-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L8091) — P1; [UI-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L8159) — P1.
- Затрагиваемые модули (03): EventBus, DevTools, UI, GameState, RotationEngine; [UI-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L8091), [UI-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L8159).

- `DisplayVisibilityPolicy`: [UI-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L8091), [UI-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L8159). Цитата из [UI-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L8091): «**Единый `DisplayVisibilityPolicy` как чистый логический resolver внутри существующего `RotationDisplay` (либо общего UI policy, только если он реально переиспользуется) + один enum `Settings.panel.visibilityMode`.** Не создавать второй runtime state machine, EventBus, профильный CFG или отдельный combat provider. Использовать DA-01/DA-02 revision и event invalidation, UI-03 для контролов/подсказок, DA-07 для migration. `ShouldShow()` должен быть единственным consumer результата policy для main; defensive»

## DotCoverageObservation

- Имя первичного определения: `DotCoverageObservation` ([CL-08](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9713)).
- Число ID: **1**.
- ID и приоритеты: [CL-08](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9713) — P0.
- Затрагиваемые модули (03): GameAPI, EventBus, AbilityEligibility, DevTools; [CL-08](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9713).

- `DotCoverageObservation`: [CL-08](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9713). Цитата из [CL-08](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9713): «**Один Warlock policy layer на общей инфраструктуре, а не самостоятельный модуль-ротационный движок.** Для shards использовать IT-01 inventory/item family и IT-05 reagent budget; логический `SoulShardObservation` не создает второй bag scanner. `DemonPetObservation` расширяет PE-01–PE-05 единого `PetObservation` по owner/pet GUID, идентичность демона и pet spell availability; pet actions только AC-03, guardians и ритуал PE-06. `CurseFamilyProvider` — **конфигурация общего `AuraStateProvider`**: на пару (`t»

## DruidFormPolicy

- Имя первичного определения: `DruidFormPolicy` ([CL-09](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9827)).
- Число ID: **1**.
- ID и приоритеты: [CL-09](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9827) — P0.
- Затрагиваемые модули (03): EventBus, AbilityEligibility, DevTools; [CL-09](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9827).

- `DruidFormPolicy`: [CL-09](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9827). Цитата из [CL-09](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9827): «1. **`FormStanceObservation` (PL-09/AC-05)** — единый shared provider для Warrior stance, Druid form и иных переключаемых режимов; Druid-specific `DruidFormPolicy` только задаёт допустимые переходы, form family, spell requirements и manual exit. Состояние `currentFormIndex`, `formSpellID`, `formFamily`, `active`, `source/reason/revision` независимо от aura state.»

## EnemyCastObservation

- Имя первичного определения: `EnemyCastObservation` ([EN-07](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3579)).
- Число ID: **1**.
- ID и приоритеты: [EN-07](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3579) — P2.
- Затрагиваемые модули (03): AbilityEligibility, DevTools; [EN-07](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3579).

- `EnemyCastObservation`: [EN-07](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3579). Цитата из [EN-07](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3579): «На основе единого наблюдаемого списка врагов предлагать (а) ближайшую **достоверно различимую по доступным данным** подходящую цель для ручного переключения и (б) врага с подтверждённым активным прерываемым cast/channel, когда можно корректно сопоставить каст, GUID, адресуемый unit token и подходящую способность прерывания. Разделить `TargetSwitchCandidateObservation`, `EnemyCastObservation`, `InterruptCandidateObservation` и окончательную проверку `AbilityEligibility`; эти названия — логические контракты»

## EnemyProximityObservation

- Имя первичного определения: `EnemyProximityObservation` ([EN-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3455)).
- Число ID: **1**.
- ID и приоритеты: [EN-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3455) — P1.
- Затрагиваемые модули (03): EventBus, AbilityEligibility, UI; [EN-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3455).

- `EnemyProximityObservation`: [EN-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3455). Цитата из [EN-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3455): «Добавить в общий `RotationSettings` параметр `aoeMinTargets` (целое число, диапазон и значение по умолчанию определяются контрактом UI/профиля; не выдавать произвольный default за существующий). `AoEPolicyObservation` читает `targetMode`, `aoeMinTargets`, подтверждённое `EnemyProximityObservation` EN-01, канонический GUID index EN-03 и `AoEControlSafetyObservation` EN-04. Для `auto`: `count >= N` и подтверждённая применимость → `AoE`; `count < N` только при достаточном coverage → `single`; при неполном по»

## EnemySchoolLockoutObservation

- Имя первичного определения: `EnemySchoolLockoutObservation` ([CC-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5949)).
- Число ID: **1**.
- ID и приоритеты: [CC-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5949) — P2.
- Затрагиваемые модули (03): EventBus, RotationConditions, DevTools; [CC-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5949).

- `EnemySchoolLockoutObservation`: [CC-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5949). Цитата из [CC-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5949): «Расширить CC-04 единым **`EnemySchoolLockoutObservation`**, привязанным к вражескому GUID и общему cast/event observation. Для подтверждения факта `мой interrupt` использовать **только** надёжный источник, содержащий interrupter/source GUID и interrupted target GUID; если combat log/событие на Forever не предоставляет доступных branchable GUID, сохранить `UNKNOWN`. `UNIT_SPELLCAST_INTERRUPTED` без проверяемого source — лишь `cast interrupted`, не `my interrupt`.»

## EquipmentObservation

- Имя первичного определения: `EquipmentObservation` ([PL-12](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L830)).
- Число ID: **1**.
- ID и приоритеты: [PL-12](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L830) — P2.
- Затрагиваемые модули (03): GameAPI, AbilityEligibility, RotationConditions; [PL-12](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L830).

- `EquipmentObservation`: [PL-12](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L830). Цитата из [PL-12](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L830): «**Основной референс — Sonah**, поскольку у него есть проверенная цепочка «слот → itemID → класс/подкласс → тип оружия → боеприпасы», с secret-safe чтениями и реальными условиями охотника. **Из JustAC** взять точное различение щита и других предметов левой руки. **Из ForeverAuras** взять разделение экипированных боеприпасов и запасов в сумках. **Из RotationMaster** — паттерн `nil+reason` и отдельный platform-провайдер. Всё реализовать через `GameAPI` и ленивый `EquipmentObservation`, без прямых WoW API в п»

## ExclusiveAuraModeProvider

- Имя первичного определения: `ExclusiveAuraModeProvider` ([CL-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9039)).
- Число ID: **2**.
- ID и приоритеты: [CL-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9039) — P0; [CL-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9152) — P0.
- Затрагиваемые модули (03): UI; [CL-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9039), [CL-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9152).

- `ExclusiveAuraModeProvider`: [CL-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9039), [CL-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9152). Цитата из [CL-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9039): «3. **`ExclusiveAuraModeProvider`** — общая модель взаимоисключающих режимов для паладинских аур, не приравнивая их к `STANCE_OR_FORM` в текущем контракте.»

## FearControlObservation

- Имя первичного определения: `FearControlObservation` ([CL-08](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9713)).
- Число ID: **1**.
- ID и приоритеты: [CL-08](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9713) — P0.
- Затрагиваемые модули (03): GameAPI, EventBus, AbilityEligibility, DevTools; [CL-08](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9713).

- `FearControlObservation`: [CL-08](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9713). Цитата из [CL-08](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9713): «**Один Warlock policy layer на общей инфраструктуре, а не самостоятельный модуль-ротационный движок.** Для shards использовать IT-01 inventory/item family и IT-05 reagent budget; логический `SoulShardObservation` не создает второй bag scanner. `DemonPetObservation` расширяет PE-01–PE-05 единого `PetObservation` по owner/pet GUID, идентичность демона и pet spell availability; pet actions только AC-03, guardians и ритуал PE-06. `CurseFamilyProvider` — **конфигурация общего `AuraStateProvider`**: на пару (`t»

## FormStanceObservation

- Имя первичного определения: `FormStanceObservation` ([AC-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L6305)).
- Число ID: **2**.
- ID и приоритеты: [AC-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L6305) — P1; [CL-09](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9827) — P0.
- Затрагиваемые модули (03): GameAPI, GameState, EventBus, AbilityEligibility, DevTools; [AC-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L6305), [CL-09](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9827).

- `FormStanceObservation`: [AC-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L6305), [CL-09](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9827). Цитата из [AC-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L6305): «Добавить **`FormStanceObservation`** в существующий GameState, используя capability-probed `GetNumShapeshiftForms/GetShapeshiftFormInfo/GetShapeshiftFormID` и доступные `UnitAura` для переключаемых аур. Нормализовать `activeFormSpellID`, `formSlot`, `activeExclusiveAuraSpellID`, `knownForms`, `status/reason/source/revision`; `nil`/secret/отсутствующий API не трактовать как «обычная форма». Проверять различия интерфейса Forever по классу/талантам/спеку и уровню.»

## FormStateProvider

- Имя первичного определения: `FormStateProvider` ([CL-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9376)).
- Число ID: **1**.
- ID и приоритеты: [CL-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9376) — P0.
- Затрагиваемые модули (03): AbilityEligibility; [CL-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9376).

- `FormStateProvider`: [CL-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9376). Цитата из [CL-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9376): «1. **`FormStateProvider`** — Shadowform, transitions и restrictions; общий `STANCE_OR_FORM` AC-05 с Warrior и другими классами, без автоматического разрешения Holy/healing spells в Shadowform.»

## FriendlyUnitSelectionProvider

- Имя первичного определения: `FriendlyUnitSelectionProvider` ([CL-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9039)).
- Число ID: **4**.
- ID и приоритеты: [CL-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9039) — P0; [CL-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9376) — P0; [CL-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9492) — P0; [CL-09](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9827) — P0.
- Затрагиваемые модули (03): UI, AbilityEligibility, WeaponEnchantProvider, EventBus, DevTools; [CL-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9039), [CL-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9376), [CL-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9492), [CL-09](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9827).

- `FriendlyUnitSelectionProvider`: [CL-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9039), [CL-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9376), [CL-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9492), [CL-09](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9827). Цитата из [CL-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9039): «4. **`FriendlyUnitSelectionProvider`** — безопасный список `player/target/focus/party/raid` только если подтверждены unit tokens и доступность API; recipient policy, dead/alive, assistable, range, party membership, group/class blessing. Никаких вымышленных GUID или выбора недоступной цели.»

## GCDObservation

- Имя первичного определения: `GCDObservation` ([SP-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L1106)).
- Число ID: **1**.
- ID и приоритеты: [SP-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L1106) — P0.
- Затрагиваемые модули (03): AbilityEligibility, UI; [SP-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L1106).

- `GCDObservation`: [SP-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L1106). Цитата из [SP-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L1106): «1. Ввести `GCDObservation` с `active:{status,value,reason,source}`, `remaining:{status,seconds,reason,source}` и `gcdSpellID=29515` только для подтверждённого Forever-контракта.»

## GetAuraDataByIndex

- Имя первичного определения: `GetAuraDataByIndex` ([NO-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L10367)).
- Число ID: **1**.
- ID и приоритеты: [NO-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L10367) — P0.
- Затрагиваемые модули (03): EventBus, DevTools, UI; [NO-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L10367).

- `GetAuraDataByIndex`: [NO-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L10367). Цитата из [NO-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L10367): «7. **RotationMaster** — `Platform/auras.lua` использует `GetAuraDataByIndex`, `Core/aura_conditions.lua` — адресные player aura checks. Переносить только typed API/secret guard, не предполагать безопасность произвольного полного обхода.»

## GroupAoEHealCoverageObservation

- Имя первичного определения: `GroupAoEHealCoverageObservation` ([GR-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4196)).
- Число ID: **1**.
- ID и приоритеты: [GR-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4196) — P2.
- Затрагиваемые модули (03): EventBus, DevTools, UI; [GR-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4196).

- `GroupAoEHealCoverageObservation`: [GR-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4196). Цитата из [GR-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4196): «3. Ввести spell-specific `AoEHealGeometryPolicy` и `GroupAoEHealCoverageObservation` с раздельными count injured vs count eligible vs count geometrically confirmed, coverage/UNKNOWN.»

## GroupCareCandidateObservation

- Имя первичного определения: `GroupCareCandidateObservation` ([GR-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4125)).
- Число ID: **1**.
- ID и приоритеты: [GR-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4125) — P2.
- Затрагиваемые модули (03): AbilityEligibility, DevTools; [GR-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4125).

- `GroupCareCandidateObservation`: [GR-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4125). Цитата из [GR-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4125): «3. Реализовать `GroupCareCandidateObservation` с независимыми statuses и источниками, не смешивать unknown health, dead, disconnected, out of range и non-healable.»

## GroupMemberRoleObservation

- Имя первичного определения: `GroupMemberRoleObservation` ([GR-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3951)).
- Число ID: **1**.
- ID и приоритеты: [GR-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3951) — P1.
- Затрагиваемые модули (03): EventBus, AbilityEligibility, DevTools; [GR-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3951).

- `GroupMemberRoleObservation`: [GR-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3951). Цитата из [GR-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3951): «4. Реализовать `GroupMemberRoleObservation`: `TANK/HEALER/DAMAGER/NONE/UNKNOWN`, source и revision, без выводов по классу, специализации или threat.»

## GroupMemberVitalsObservation

- Имя первичного определения: `GroupMemberVitalsObservation` ([GR-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3951)).
- Число ID: **1**.
- ID и приоритеты: [GR-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3951) — P1.
- Затрагиваемые модули (03): EventBus, AbilityEligibility, DevTools; [GR-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3951).

- `GroupMemberVitalsObservation`: [GR-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3951). Цитата из [GR-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3951): «3. Реализовать `GroupMemberVitalsObservation` с отдельными health/power statuses, powerType, current/max/percent, source, observedAt и reason; не смешивать ресурсы и не делить на 0.»

## GroupRosterObservation

- Имя первичного определения: `GroupRosterObservation` ([GR-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3888)).
- Число ID: **2**.
- ID и приоритеты: [GR-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3888) — P1; [GR-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3951) — P1.
- Затрагиваемые модули (03): EventBus, DevTools, UI, AbilityEligibility; [GR-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3888), [GR-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3951).

- `GroupRosterObservation`: [GR-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3888), [GR-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3951). Цитата из [GR-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3888): «Один канонический общеклассовый `GroupRosterObservation` должен выдавать для каждого подтверждённого члена party/raid (включая player, без двойного счёта) `memberGUID`, актуальный адресуемый unit token, членство, `exists`, `alive/dead/ghost`, `connected`, `visible` и `spellInRange(spellID,memberGUID)` как **независимые** наблюдения с `READY/UNKNOWN`, reason и временем. Не смешивать «состоит в группе», `UnitExists`, `UnitIsConnected`, `UnitIsVisible`, фазу/LOS и `IsSpellInRange`: каждый сигнал доказывает л»

## HealEligibilityProvider

- Имя первичного определения: `HealEligibilityProvider` ([CL-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9376)).
- Число ID: **1**.
- ID и приоритеты: [CL-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9376) — P0.
- Затрагиваемые модули (03): AbilityEligibility; [CL-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9376).

- `HealEligibilityProvider`: [CL-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9376). Цитата из [CL-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9376): «4. **`HealEligibilityProvider`** — healing target, mana, cast, range, effective healing when reliable, no invented overheal predictions; финальное READY только `AbilityEligibility`.»

## HealPriorityPolicy

- Имя первичного определения: `HealPriorityPolicy` ([GR-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4125)).
- Число ID: **1**.
- ID и приоритеты: [GR-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4125) — P2.
- Затрагиваемые модули (03): AbilityEligibility, DevTools; [GR-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4125).

- `HealPriorityPolicy`: [GR-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4125). Цитата из [GR-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4125): «**Основа — GR-01 roster + GR-02 member vitals/role + RotationMaster role/unit/dead observations + Sonah приоритет ручного friendly target и честное разделение emergency/maintenance + JustAC раздельные heal/resurrection spell categories.** Общий логический `GroupCareCandidateObservation(memberGUID)` предоставляет независимые `life`, `healthDeficit`, `healthPercent`, `role`, `incomingDamageEvidence` (только если доказано), `manualTargetPreference`, `range`, `observedAt`, `reason`. Производные `HealPriorityP»

## HoTCoverageObservation

- Имя первичного определения: `HoTCoverageObservation` ([CL-09](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9827)).
- Число ID: **1**.
- ID и приоритеты: [CL-09](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9827) — P0.
- Затрагиваемые модули (03): EventBus, AbilityEligibility, DevTools; [CL-09](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9827).

- `HoTCoverageObservation`: [CL-09](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9827). Цитата из [CL-09](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9827): «4. **`AuraStateProvider` + `HoTCoverageObservation` (CL-05/CL-08)** — один per-caster/per-recipient GUID aura scanner с HoT family/rank/remaining/stacks/refresh/ownership; `FriendlyUnitSelectionProvider` для party/raid, без второго сканера лечения.»

## HunterRangeObservation

- Имя первичного определения: `HunterRangeObservation` ([SP-08](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L1298)).
- Число ID: **1**.
- ID и приоритеты: [SP-08](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L1298) — P0.
- Затрагиваемые модули (03): AbilityEligibility; [SP-08](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L1298).

- `HunterRangeObservation`: [SP-08](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L1298). Цитата из [SP-08](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L1298): «**Архитектурная поправка:** универсальное ядро обязано обслуживать все классы. Название `HunterRangeObservation` было ошибочным; заменено на `RangeObservation`. Особенность мёртвой зоны задаётся конфигурацией/профилем, а не отдельным Hunter-провайдером.»

## InterruptAbilityCatalog

- Имя первичного определения: `InterruptAbilityCatalog` ([CC-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5889)).
- Число ID: **1**.
- ID и приоритеты: [CC-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5889) — P1.
- Затрагиваемые модули (03): GameState, EventBus, AbilityEligibility, RotationConditions, DevTools; [CC-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5889).

- `InterruptAbilityCatalog`: [CC-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5889). Цитата из [CC-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5889): «3. Ввести проверенный `InterruptAbilityCatalog` по классам/формам/талантам/рангам с различением прямого interrupt и CC-stop.»

## InterruptCandidateObservation

- Имя первичного определения: `InterruptCandidateObservation` ([EN-07](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3579)).
- Число ID: **1**.
- ID и приоритеты: [EN-07](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3579) — P2.
- Затрагиваемые модули (03): AbilityEligibility, DevTools; [EN-07](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3579).

- `InterruptCandidateObservation`: [EN-07](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3579). Цитата из [EN-07](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3579): «На основе единого наблюдаемого списка врагов предлагать (а) ближайшую **достоверно различимую по доступным данным** подходящую цель для ручного переключения и (б) врага с подтверждённым активным прерываемым cast/channel, когда можно корректно сопоставить каст, GUID, адресуемый unit token и подходящую способность прерывания. Разделить `TargetSwitchCandidateObservation`, `EnemyCastObservation`, `InterruptCandidateObservation` и окончательную проверку `AbilityEligibility`; эти названия — логические контракты»

## InterruptOpportunityObservation

- Имя первичного определения: `InterruptOpportunityObservation` ([CC-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5889)).
- Число ID: **1**.
- ID и приоритеты: [CC-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5889) — P1.
- Затрагиваемые модули (03): GameState, EventBus, AbilityEligibility, RotationConditions, DevTools; [CC-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5889).

- `InterruptOpportunityObservation`: [CC-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5889). Цитата из [CC-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5889): «Расширить имеющийся cast observation в GameState до **`InterruptOpportunityObservation`**, используя один `UnitCastingInfo/UnitChannelInfo` reader для target/focus/nameplate по доступности и безопасной идентификации GUID. Нормализовать **разные tuple** для cast/channel и проверить сигнатуры на Forever: `notInterruptible`, spellID, start/end, secret-значения. В случае `notInterruptible=true` direct interrupt BLOCKED; при `false` подтверждённо допустим; при `nil`/secret — UNKNOWN. При отсутствующем касте и »

## InterruptStateProvider

- Имя первичного определения: `InterruptStateProvider` ([CL-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L8925)).
- Число ID: **2**.
- ID и приоритеты: [CL-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L8925) — P0; [CL-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9267) — P0.
- Затрагиваемые модули (03): AbilityEligibility, WeaponEnchantProvider; [CL-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L8925), [CL-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9267).

- `InterruptStateProvider`: [CL-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L8925), [CL-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9267). Цитата из [CL-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L8925): «6. `InterruptStateProvider` — cast/channel/interruptible, remaining, latency, stance/equipment; общий механизм для других классов.»

## InventoryObservation

- Имя первичного определения: `InventoryFamilyObservation` ([IT-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4852)).
- Число ID: **9**.
- ID и приоритеты: [AC-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L6082) — в файле не указано; [IT-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4852) — P0; [IT-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4932) — P0; [IT-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5005) — P0; [IT-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5080) — P0; [IT-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5155) — P1; [IT-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5212) — P1; [IT-07](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5276) — P1; [IT-09](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5397) — P1.
- Затрагиваемые модули (03): EventBus, AbilityEligibility, RotationEngine, DevTools, UI, RotationConditions, InventoryObservation, GameAPI, GameState; [AC-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L6082), [IT-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4852), [IT-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4932), [IT-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5005), [IT-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5080), [IT-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5155), [IT-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5212), [IT-07](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5276), [IT-09](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5397).

- `InventoryFamilyObservation`: [IT-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4852). Цитата из [IT-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4852): «**Один логический `InventoryObservation` в GameState/GameAPI с `InventoryItemObservation` и `InventoryFamilyObservation`, единым `ItemFamilyCatalog` и revision-based кэшем**, по архитектуре RotationMaster, с Forever каталогом JustAC и обновлением ForeverAuras. `InventoryReadAdapter` сперва пробует проверенный `C_Item.GetItemCount(itemID,false,false)`, а если semantics/secret/capability не позволяют доказать bags-only count, использует **один** bounded `C_Container` bag snapshot (только подтверждённые ID с»
- `InventoryItemObservation`: [IT-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4852). Цитата из [IT-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4852): «**Один логический `InventoryObservation` в GameState/GameAPI с `InventoryItemObservation` и `InventoryFamilyObservation`, единым `ItemFamilyCatalog` и revision-based кэшем**, по архитектуре RotationMaster, с Forever каталогом JustAC и обновлением ForeverAuras. `InventoryReadAdapter` сперва пробует проверенный `C_Item.GetItemCount(itemID,false,false)`, а если semantics/secret/capability не позволяют доказать bags-only count, использует **один** bounded `C_Container` bag snapshot (только подтверждённые ID с»
- `InventoryObservation`: [IT-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4852), [IT-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4932), [IT-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5005), [IT-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5080), [IT-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5155), [IT-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5212), [IT-07](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5276), [IT-09](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5397), [AC-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L6082). Цитата из [IT-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4852): «**Один логический `InventoryObservation` в GameState/GameAPI с `InventoryItemObservation` и `InventoryFamilyObservation`, единым `ItemFamilyCatalog` и revision-based кэшем**, по архитектуре RotationMaster, с Forever каталогом JustAC и обновлением ForeverAuras. `InventoryReadAdapter` сперва пробует проверенный `C_Item.GetItemCount(itemID,false,false)`, а если semantics/secret/capability не позволяют доказать bags-only count, использует **один** bounded `C_Container` bag snapshot (только подтверждённые ID с»

## InventoryReadAdapter

- Имя первичного определения: `InventoryReadAdapter` ([IT-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4852)).
- Число ID: **1**.
- ID и приоритеты: [IT-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4852) — P0.
- Затрагиваемые модули (03): EventBus, AbilityEligibility, RotationConditions, DevTools, InventoryObservation; [IT-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4852).

- `InventoryReadAdapter`: [IT-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4852). Цитата из [IT-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4852): «**Один логический `InventoryObservation` в GameState/GameAPI с `InventoryItemObservation` и `InventoryFamilyObservation`, единым `ItemFamilyCatalog` и revision-based кэшем**, по архитектуре RotationMaster, с Forever каталогом JustAC и обновлением ForeverAuras. `InventoryReadAdapter` сперва пробует проверенный `C_Item.GetItemCount(itemID,false,false)`, а если semantics/secret/capability не позволяют доказать bags-only count, использует **один** bounded `C_Container` bag snapshot (только подтверждённые ID с»

## ItemCooldownAdapter

- Имя первичного определения: `ItemCooldownAdapter` ([IT-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4932)).
- Число ID: **1**.
- ID и приоритеты: [IT-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4932) — P0.
- Затрагиваемые модули (03): GameAPI, EventBus, AbilityEligibility, RotationConditions, DevTools; [IT-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4932).

- `ItemCooldownAdapter`: [IT-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4932). Цитата из [IT-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4932): «**Один логический `ItemCooldownObservation` + `SharedItemCooldownObservation` поверх IT-01 `InventoryObservation`/`ItemFamilyCatalog` и единого EventBus.** `ItemCooldownAdapter` — read-only `C_Item.GetItemCooldown`, fallback `C_Container.GetItemCooldown` и legacy **только** после Forever API probe; `C_Item.GetItemSpell` — дополнительная проверка item use-spell identity, не замена itemID. Нормализовать `enabled` (bool/0/1), проверять secret/finite/start/duration/clock. `active=true` при подтверждённом cool»

## ItemCooldownObservation

- Имя первичного определения: `ItemCooldownObservation` ([IT-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4932)).
- Число ID: **6**.
- ID и приоритеты: [IT-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4932) — P0; [IT-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5005) — P0; [IT-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5080) — P0; [IT-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5155) — P1; [IT-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5212) — P1; [IT-07](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5276) — P1.
- Затрагиваемые модули (03): GameAPI, EventBus, AbilityEligibility, RotationConditions, DevTools, GameState, UI; [IT-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4932), [IT-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5005), [IT-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5080), [IT-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5155), [IT-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5212), [IT-07](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5276).

- `ItemCooldownObservation`: [IT-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4932), [IT-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5005), [IT-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5080), [IT-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5155), [IT-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5212), [IT-07](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5276). Цитата из [IT-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4932): «**Один логический `ItemCooldownObservation` + `SharedItemCooldownObservation` поверх IT-01 `InventoryObservation`/`ItemFamilyCatalog` и единого EventBus.** `ItemCooldownAdapter` — read-only `C_Item.GetItemCooldown`, fallback `C_Container.GetItemCooldown` и legacy **только** после Forever API probe; `C_Item.GetItemSpell` — дополнительная проверка item use-spell identity, не замена itemID. Нормализовать `enabled` (bool/0/1), проверять secret/finite/start/duration/clock. `active=true` при подтверждённом cool»

## ItemFamilyCatalog

- Имя первичного определения: `ItemFamilyCatalog` ([IT-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4852)).
- Число ID: **9**.
- ID и приоритеты: [IT-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4852) — P0; [IT-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4932) — P0; [IT-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5080) — P0; [IT-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5155) — P1; [IT-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5212) — P1; [IT-07](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5276) — P1; [IT-08](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5340) — P2; [IT-09](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5397) — P1; [IT-10](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5454) — P1.
- Затрагиваемые модули (03): EventBus, AbilityEligibility, RotationConditions, DevTools, InventoryObservation, GameAPI, GameState, UI; [IT-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4852), [IT-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4932), [IT-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5080), [IT-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5155), [IT-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5212), [IT-07](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5276), [IT-08](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5340), [IT-09](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5397), [IT-10](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5454).

- `ItemFamilyCatalog`: [IT-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4852), [IT-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4932), [IT-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5080), [IT-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5212), [IT-07](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5276), [IT-09](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5397), [IT-10](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5454), [IT-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5155), [IT-08](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5340). Цитата из [IT-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4852): «**Один логический `InventoryObservation` в GameState/GameAPI с `InventoryItemObservation` и `InventoryFamilyObservation`, единым `ItemFamilyCatalog` и revision-based кэшем**, по архитектуре RotationMaster, с Forever каталогом JustAC и обновлением ForeverAuras. `InventoryReadAdapter` сперва пробует проверенный `C_Item.GetItemCount(itemID,false,false)`, а если semantics/secret/capability не позволяют доказать bags-only count, использует **один** bounded `C_Container` bag snapshot (только подтверждённые ID с»

## ItemFamilySelectionObservation

- Имя первичного определения: `ItemFamilySelectionObservation` ([IT-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5080)).
- Число ID: **5**.
- ID и приоритеты: [IT-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5080) — P0; [IT-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5155) — P1; [IT-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5212) — P1; [IT-07](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5276) — P1; [IT-09](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5397) — P1.
- Затрагиваемые модули (03): EventBus, AbilityEligibility, RotationConditions, DevTools, GameState, UI; [IT-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5080), [IT-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5155), [IT-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5212), [IT-07](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5276), [IT-09](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5397).

- `ItemFamilySelectionObservation`: [IT-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5080), [IT-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5155), [IT-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5212), [IT-07](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5276), [IT-09](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5397). Цитата из [IT-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5080): «**Один `ItemFamilySelectionObservation` поверх IT-01 `ItemFamilyCatalog`/`InventoryObservation`, IT-02 `ItemCooldownObservation`/`SharedItemCooldownObservation` и IT-03 `ItemUseEligibilityObservation`.** Добавить в **тот же** `ItemFamilyCatalog` для каждого itemID `familyID`, `tierOrder`, `requiredPlayerLevel` (с source и проверкой client metadata), `clientEdition`, `variant`, `tieBreakGroup`, `classificationConfidence`. Нет нового универсального файла или второго каталога. `tierOrder` — проверенный rank/»

## ItemMetadataAdapter

- Имя первичного определения: `ItemMetadataAdapter` ([IT-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5005)).
- Число ID: **1**.
- ID и приоритеты: [IT-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5005) — P0.
- Затрагиваемые модули (03): GameAPI, EventBus, AbilityEligibility, RotationConditions, DevTools; [IT-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5005).

- `ItemMetadataAdapter`: [IT-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5005). Цитата из [IT-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5005): «**Один `ItemUseEligibilityObservation` поверх IT-01 `InventoryObservation`, IT-02 `ItemCooldownObservation`/`SharedItemCooldownObservation`, общего `Player/TargetObservation`, `WorldContextObservation` и `ItemRestrictionCatalog`; финальный READY исключительно в `AbilityEligibility`.** Логические adapters, не обязательные новые Lua-файлы. `ItemUsabilityAdapter` через `C_Item.IsUsableItem` (legacy только после probe), `ItemTargetAdapter` через `C_Item.IsItemInRange` с подтверждённым target kind/self/no-targ»

## ItemRestrictionCatalog

- Имя первичного определения: `ItemRestrictionCatalog` ([IT-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5005)).
- Число ID: **1**.
- ID и приоритеты: [IT-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5005) — P0.
- Затрагиваемые модули (03): GameAPI, EventBus, AbilityEligibility, RotationConditions, DevTools; [IT-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5005).

- `ItemRestrictionCatalog`: [IT-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5005). Цитата из [IT-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5005): «**Один `ItemUseEligibilityObservation` поверх IT-01 `InventoryObservation`, IT-02 `ItemCooldownObservation`/`SharedItemCooldownObservation`, общего `Player/TargetObservation`, `WorldContextObservation` и `ItemRestrictionCatalog`; финальный READY исключительно в `AbilityEligibility`.** Логические adapters, не обязательные новые Lua-файлы. `ItemUsabilityAdapter` через `C_Item.IsUsableItem` (legacy только после probe), `ItemTargetAdapter` через `C_Item.IsItemInRange` с подтверждённым target kind/self/no-targ»

## ItemTargetAdapter

- Имя первичного определения: `ItemTargetAdapter` ([IT-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5005)).
- Число ID: **1**.
- ID и приоритеты: [IT-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5005) — P0.
- Затрагиваемые модули (03): GameAPI, EventBus, AbilityEligibility, RotationConditions, DevTools; [IT-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5005).

- `ItemTargetAdapter`: [IT-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5005). Цитата из [IT-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5005): «**Один `ItemUseEligibilityObservation` поверх IT-01 `InventoryObservation`, IT-02 `ItemCooldownObservation`/`SharedItemCooldownObservation`, общего `Player/TargetObservation`, `WorldContextObservation` и `ItemRestrictionCatalog`; финальный READY исключительно в `AbilityEligibility`.** Логические adapters, не обязательные новые Lua-файлы. `ItemUsabilityAdapter` через `C_Item.IsUsableItem` (legacy только после probe), `ItemTargetAdapter` через `C_Item.IsItemInRange` с подтверждённым target kind/self/no-targ»

## ItemUsabilityAdapter

- Имя первичного определения: `ItemUsabilityAdapter` ([IT-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5005)).
- Число ID: **1**.
- ID и приоритеты: [IT-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5005) — P0.
- Затрагиваемые модули (03): GameAPI, EventBus, AbilityEligibility, RotationConditions, DevTools; [IT-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5005).

- `ItemUsabilityAdapter`: [IT-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5005). Цитата из [IT-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5005): «**Один `ItemUseEligibilityObservation` поверх IT-01 `InventoryObservation`, IT-02 `ItemCooldownObservation`/`SharedItemCooldownObservation`, общего `Player/TargetObservation`, `WorldContextObservation` и `ItemRestrictionCatalog`; финальный READY исключительно в `AbilityEligibility`.** Логические adapters, не обязательные новые Lua-файлы. `ItemUsabilityAdapter` через `C_Item.IsUsableItem` (legacy только после probe), `ItemTargetAdapter` через `C_Item.IsItemInRange` с подтверждённым target kind/self/no-targ»

## ItemUseEligibilityObservation

- Имя первичного определения: `ItemUseEligibilityObservation` ([IT-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5005)).
- Число ID: **6**.
- ID и приоритеты: [IT-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5005) — P0; [IT-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5080) — P0; [IT-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5155) — P1; [IT-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5212) — P1; [IT-07](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5276) — P1; [IT-09](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5397) — P1.
- Затрагиваемые модули (03): GameAPI, EventBus, AbilityEligibility, RotationConditions, DevTools, GameState, UI; [IT-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5005), [IT-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5080), [IT-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5155), [IT-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5212), [IT-07](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5276), [IT-09](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5397).

- `ItemUseEligibilityObservation`: [IT-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5005), [IT-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5080), [IT-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5155), [IT-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5212), [IT-07](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5276), [IT-09](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5397). Цитата из [IT-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5005): «**Один `ItemUseEligibilityObservation` поверх IT-01 `InventoryObservation`, IT-02 `ItemCooldownObservation`/`SharedItemCooldownObservation`, общего `Player/TargetObservation`, `WorldContextObservation` и `ItemRestrictionCatalog`; финальный READY исключительно в `AbilityEligibility`.** Логические adapters, не обязательные новые Lua-файлы. `ItemUsabilityAdapter` через `C_Item.IsUsableItem` (legacy только после probe), `ItemTargetAdapter` через `C_Item.IsItemInRange` с подтверждённым target kind/self/no-targ»

## LifeTapSafetyPolicy

- Имя первичного определения: `LifeTapSafetyPolicy` ([CL-08](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9713)).
- Число ID: **1**.
- ID и приоритеты: [CL-08](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9713) — P0.
- Затрагиваемые модули (03): GameAPI, EventBus, AbilityEligibility, DevTools; [CL-08](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9713).

- `LifeTapSafetyPolicy`: [CL-08](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9713). Цитата из [CL-08](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9713): «**Один Warlock policy layer на общей инфраструктуре, а не самостоятельный модуль-ротационный движок.** Для shards использовать IT-01 inventory/item family и IT-05 reagent budget; логический `SoulShardObservation` не создает второй bag scanner. `DemonPetObservation` расширяет PE-01–PE-05 единого `PetObservation` по owner/pet GUID, идентичность демона и pet spell availability; pet actions только AC-03, guardians и ритуал PE-06. `CurseFamilyProvider` — **конфигурация общего `AuraStateProvider`**: на пару (`t»

## MeleeSwingQueueProvider

- Имя первичного определения: `MeleeSwingQueueProvider` ([CL-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L8925)).
- Число ID: **1**.
- ID и приоритеты: [CL-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L8925) — P0.
- Затрагиваемые модули (03): в файле не указано; [CL-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L8925).

- `MeleeSwingQueueProvider`: [CL-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L8925). Цитата из [CL-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L8925): «3. `MeleeSwingQueueProvider` — состояние melee autoattack и **проверяемая** очередь next-swing action. Не использовать `autoShot.swing` Hunter; если API queue state не подтверждён, возвращать UNKNOWN. Таймер удара без источника не выдумывать.»

## MovementImpairmentRemovalPolicy

- Имя первичного определения: `MovementImpairmentRemovalPolicy` ([CC-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5834)).
- Число ID: **1**.
- ID и приоритеты: [CC-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5834) — P2.
- Затрагиваемые модули (03): EventBus, AbilityEligibility, RotationConditions, DevTools; [CC-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5834).

- `MovementImpairmentRemovalPolicy`: [CC-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5834). Цитата из [CC-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5834): «Ввести **`MovementImpairmentRemovalPolicy`** поверх **единого** `PlayerControlObservation` (CC-01) и `ControlBreakSelection` (CC-02). Сначала установить, что именно действует: `ROOT`, `SNARE` или оба; при отсутствии достоверного LoC API и неизвестной aura mapping не утверждать `FALSE`. Отдельно определить `movementNeeded` по уже имеющимся проверенным сигналам движка (расстояние до цели/нужна позиция, маршрут отступления, опасная зона только при наличии достоверного источника, ручной приоритет PvP). **Не в»

## MovementObservation

- Имя первичного определения: `MovementObservation` ([PL-08](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L634)).
- Число ID: **1**.
- ID и приоритеты: [PL-08](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L634) — P0.
- Затрагиваемые модули (03): GameAPI, RotationConditions; [PL-08](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L634).

- `MovementObservation`: [PL-08](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L634). Цитата из [PL-08](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L634): «2. Создать `MovementObservation` с независимыми `moving`, `speed`, `falling`, `swimming`, `onTaxi`, `inVehicle`, `mounted`, `standing` и индивидуальными `status/reason/source/estimated`. Не подменять защищённую скорость оценкой без маркировки.»

## MultiDotCandidateObservation

- Имя первичного определения: `MultiDotCandidateObservation` ([EN-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3516)).
- Число ID: **1**.
- ID и приоритеты: [EN-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3516) — P2.
- Затрагиваемые модули (03): в файле не указано; [EN-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3516).

- `MultiDotCandidateObservation`: [EN-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3516). Цитата из [EN-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3516): «6. Дать `MultiDotCandidateObservation` только подтверждённые/оценочные факты с provenance/confidence и причины UNKNOWN.»

## NextSwingEmpowerObservation

- Имя первичного определения: `NextSwingEmpowerObservation` ([SW-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4790)).
- Число ID: **1**.
- ID и приоритеты: [SW-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4790) — P2.
- Затрагиваемые модули (03): EventBus, AbilityEligibility, RotationConditions, DevTools; [SW-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4790).

- `NextSwingEmpowerObservation`: [SW-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4790). Цитата из [SW-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4790): «**Единый логический `NextSwingEmpowerObservation` поверх SW-01 `PlayerAutoAttackObservation`, SW-02 `PlayerSwingObservation`, общего `PlayerResourceObservation` и `AbilityEligibility`, с `NextSwingSpellCatalog` по семействам/рангам и `ResourceReservePolicy`.** Никакого второго swing scanner, class-specific queue observer или нового универсального resource provider. Для каждого изученного highest rank next-swing family проверять `C_Spell.IsCurrentSpell` через GameAPI secret-safe read; `true=QUEUED`, `false»

## NextSwingNeedPolicy

- Имя первичного определения: `NextSwingNeedPolicy` ([SW-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4790)).
- Число ID: **1**.
- ID и приоритеты: [SW-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4790) — P2.
- Затрагиваемые модули (03): EventBus, AbilityEligibility, RotationConditions, DevTools; [SW-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4790).

- `NextSwingNeedPolicy`: [SW-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4790). Цитата из [SW-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4790): «`NextSwingNeedPolicy` рекомендует только при `NOT_QUEUED`, доказанном запасе, нужном target/range, EN-04 CC safety, EN-05 AoE count для Cleave, применимой форме/оружии, достаточной фазе SW-02 (если требуется профилем), отсутствии более важной способности и итоговом `AbilityEligibility READY`. `UNKNOWN` не означает «нажать ещё раз»; не обходить финальный READY через `ignoreReady`. `Needs.nextSwingEmpower` лениво получает существующие observations и memo по revisions player/target/spellbook/resource/queue/s»

## NextSwingSpellCatalog

- Имя первичного определения: `NextSwingSpellCatalog` ([SW-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4790)).
- Число ID: **1**.
- ID и приоритеты: [SW-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4790) — P2.
- Затрагиваемые модули (03): EventBus, AbilityEligibility, RotationConditions, DevTools; [SW-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4790).

- `NextSwingSpellCatalog`: [SW-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4790). Цитата из [SW-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4790): «**Единый логический `NextSwingEmpowerObservation` поверх SW-01 `PlayerAutoAttackObservation`, SW-02 `PlayerSwingObservation`, общего `PlayerResourceObservation` и `AbilityEligibility`, с `NextSwingSpellCatalog` по семействам/рангам и `ResourceReservePolicy`.** Никакого второго swing scanner, class-specific queue observer или нового универсального resource provider. Для каждого изученного highest rank next-swing family проверять `C_Spell.IsCurrentSpell` через GameAPI secret-safe read; `true=QUEUED`, `false»

## ObservedEnemyIndex

- Имя первичного определения: `ObservedEnemyIndex` ([EN-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3226)).
- Число ID: **4**.
- ID и приоритеты: [EN-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3226) — P1; [EN-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3376) — P1; [EN-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3516) — P2; [EN-07](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3579) — P2.
- Затрагиваемые модули (03): RotationConditions, EventBus, AbilityEligibility, DevTools; [EN-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3226), [EN-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3376), [EN-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3516), [EN-07](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3579).

- `ObservedEnemyIndex`: [EN-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3226), [EN-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3376), [EN-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3516), [EN-07](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3579). Цитата из [EN-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3226): «**Расширить EN-01, а не создавать второй nameplate scanner.** Общий bounded `ObservedEnemyIndex` по GUID получает видимые unit tokens и событие lifecycle; `EnemyCombatObservation(enemyGUID)` хранит `inCombat`, `engagedWithGroup`, `engagementEvidence`, `matchedGroupMemberGUID`, `status/reason/observedAt`. Источники связи: достоверное `enemy target-of-target` в составе группы/питомцев, подтверждённые threat relations с каждым доступным членом группы и, если валидировано на Forever, боевые события с GUID обе»

## OOMObservation

- Имя первичного определения: `OOMObservation` ([IT-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5212)).
- Число ID: **1**.
- ID и приоритеты: [IT-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5212) — P1.
- Затрагиваемые модули (03): GameState, EventBus, RotationConditions, DevTools, UI; [IT-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5212).

- `OOMObservation`: [IT-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5212). Цитата из [IT-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5212): «`ResourceConsumablePolicy` хранит `combatThresholdPct`, `oocThresholdPct`, `enabledInCombat`, `enabledOutOfCombat`, `powerType`, `minimumMissingResource` (только при readable numbers), `preferOOCDrink`, `potionConservation`, `oomFallbackEnabled` (явная настройка), `combatUrgency` и `recoveryPriority`. Для mana potion требуется **именно mana** или подтверждённый relevant typed mana pool; low rage/energy не является доказательством, что mana potion восстановит этот ресурс. `OOMObservation` на основе провере»

## OutOfCombatRecoveryObservation

- Имя первичного определения: `OutOfCombatRecoveryObservation` ([IT-09](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5397)).
- Число ID: **1**.
- ID и приоритеты: [IT-09](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5397) — P1.
- Затрагиваемые модули (03): EventBus, DevTools, UI; [IT-09](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5397).

- `OutOfCombatRecoveryObservation`: [IT-09](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5397). Цитата из [IT-09](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5397): «Вне боя рекомендовать **еду для здоровья**, **питьё для маны**, **комбинированную еду/питьё** для двух ресурсов и **кормление питомца охотника** как разные политики поверх общего инвентаря. `OutOfCombatRecoveryObservation` содержит `mode=OUT_OF_COMBAT/COMBAT/UNKNOWN`, `healthNeed`, `manaNeed`, `activeEating`, `activeDrinking`, `activeCombinedRecovery`, `bestFoodItemID`, `bestDrinkItemID`, `bestCombinedItemID`, `decision=EAT/DRINK/EAT_DRINK/WAIT/SUPPRESS/UNKNOWN`, `reason/source/revisions`. `PetFeedingNeed»

## PetActionCooldownObservation

- Имя первичного определения: `PetActionCooldownObservation` ([PE-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4431)).
- Число ID: **1**.
- ID и приоритеты: [PE-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4431) — P1.
- Затрагиваемые модули (03): GameAPI, EventBus, AbilityEligibility, DevTools; [PE-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4431).

- `PetActionCooldownObservation`: [PE-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4431). Цитата из [PE-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4431): «4. Разработать `PetActionCooldownObservation` по **slot**, не считать обычный `GetSpellCooldown` доказательством pet cooldown; учесть start/duration/enabled и источник времени.»

## PetActionUsabilityObservation

- Имя первичного определения: `PetActionUsabilityObservation` ([PE-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4431)).
- Число ID: **1**.
- ID и приоритеты: [PE-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4431) — P1.
- Затрагиваемые модули (03): GameAPI, EventBus, AbilityEligibility, DevTools; [PE-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4431).

- `PetActionUsabilityObservation`: [PE-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4431). Цитата из [PE-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4431): «**Один `PetActionbarObservation(petGUID,actionbarRevision)` внутри PE-01 PetObservation**: общий bounded slot scan `GetPetActionInfo` обеспечивает PE-03 режимы/команды и PE-04 spell/autocast; `PetActionCooldownObservation(petGUID,slot)` — guarded `GetPetActionCooldown` из RotationMaster, `PetActionUsabilityObservation` — guarded `GetPetActionSlotUsable` (если существует на Forever), `PetAutocastObservation` — `autoCastAllowed/autoCastEnabled` из ForeverAuras. Никакого второго pet actionbar scanner и никак»

## PetAttackActivityObservation

- Имя первичного определения: `PetAttackActivityObservation` ([PE-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4373)).
- Число ID: **1**.
- ID и приоритеты: [PE-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4373) — P1.
- Затрагиваемые модули (03): GameState, EventBus, AbilityEligibility, RotationConditions, DevTools; [PE-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4373).

- `PetAttackActivityObservation`: [PE-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4373). Цитата из [PE-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4373): «**Основа — PE-01 `PetObservation` + ForeverAuras активная pet stance button и `UNIT_TARGET("pet")` + JustAC pet-target comparison + RotationMaster осторожные `PET_ATTACK_START/STOP` и pet action API guards + существующий Kord GameState.** Добавить логические поля `PetTargetObservation`, `PetAttackActivityObservation`, `PetStanceObservation` в **тот же petGUID-scoped snapshot**, без второго scanner. Для target: читать `UnitExists("pettarget")`, `UnitGUID("pettarget")`, после чтения подтверждать, что petGUI»

## PetAutocastObservation

- Имя первичного определения: `PetAutocastObservation` ([PE-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4431)).
- Число ID: **1**.
- ID и приоритеты: [PE-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4431) — P1.
- Затрагиваемые модули (03): GameAPI, EventBus, AbilityEligibility, DevTools; [PE-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4431).

- `PetAutocastObservation`: [PE-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4431). Цитата из [PE-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4431): «**Один `PetActionbarObservation(petGUID,actionbarRevision)` внутри PE-01 PetObservation**: общий bounded slot scan `GetPetActionInfo` обеспечивает PE-03 режимы/команды и PE-04 spell/autocast; `PetActionCooldownObservation(petGUID,slot)` — guarded `GetPetActionCooldown` из RotationMaster, `PetActionUsabilityObservation` — guarded `GetPetActionSlotUsable` (если существует на Forever), `PetAutocastObservation` — `autoCastAllowed/autoCastEnabled` из ForeverAuras. Никакого второго pet actionbar scanner и никак»

## PetCareNeedPolicy

- Имя первичного определения: `PetCareNeedPolicy` ([PE-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4497)).
- Число ID: **1**.
- ID и приоритеты: [PE-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4497) — P2.
- Затрагиваемые модули (03): EventBus, AbilityEligibility, DevTools; [PE-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4497).

- `PetCareNeedPolicy`: [PE-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4497). Цитата из [PE-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4497): «Отдельная `PetCareNeedPolicy` выбирает `DISMISS/REVIVE/CALL/MEND/NO_ACTION/UNKNOWN`: Dismiss только при явной политике (например, подтверждённый талант Lone Wolf), Revive только при подтверждённой смерти, Call при доказанном отсутствии и применимости, Mend при доказанном HP threshold и отсутствии подтверждённого достаточного текущего HoT; при UNKNOWN не объявлять READY. Проверить клиентскую возможность лечения во время боя, cast interruption, range, learned highest rank, GCD/cooldown/resources и отсутстви»

## PetCareTimingObservation

- Имя первичного определения: `PetCareTimingObservation` ([PE-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4497)).
- Число ID: **1**.
- ID и приоритеты: [PE-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4497) — P2.
- Затрагиваемые модули (03): EventBus, AbilityEligibility, DevTools; [PE-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4497).

- `PetCareTimingObservation`: [PE-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4497). Цитата из [PE-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4497): «3. Ввести `PetCareTimingObservation` с независимыми cast, since-success, aura remaining, cooldown remaining, pet transition и явными UNKNOWN; не смешивать duration и cooldown.»

## PetCommandProvider

- Имя первичного определения: `PetCommandProvider` ([CL-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9152)).
- Число ID: **1**.
- ID и приоритеты: [CL-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9152) — P0.
- Затрагиваемые модули (03): в файле не указано; [CL-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9152).

- `PetCommandProvider`: [CL-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9152). Цитата из [CL-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9152): «3. `PetStateProvider` + `PetCommandProvider`: exists/dead/HP/target/behavior/happiness/food, commands, Mend/Revive/Call; общий контракт AC-03, fail-closed.»

## PetFeedingNeedObservation

- Имя первичного определения: `PetFeedingNeedObservation` ([IT-09](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5397)).
- Число ID: **1**.
- ID и приоритеты: [IT-09](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5397) — P1.
- Затрагиваемые модули (03): EventBus, DevTools, UI; [IT-09](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5397).

- `PetFeedingNeedObservation`: [IT-09](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5397). Цитата из [IT-09](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5397): «Вне боя рекомендовать **еду для здоровья**, **питьё для маны**, **комбинированную еду/питьё** для двух ресурсов и **кормление питомца охотника** как разные политики поверх общего инвентаря. `OutOfCombatRecoveryObservation` содержит `mode=OUT_OF_COMBAT/COMBAT/UNKNOWN`, `healthNeed`, `manaNeed`, `activeEating`, `activeDrinking`, `activeCombinedRecovery`, `bestFoodItemID`, `bestDrinkItemID`, `bestCombinedItemID`, `decision=EAT/DRINK/EAT_DRINK/WAIT/SUPPRESS/UNKNOWN`, `reason/source/revisions`. `PetFeedingNeed»

## PetFeedingPolicy

- Имя первичного определения: `PetFeedingPolicy` ([IT-09](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5397)).
- Число ID: **1**.
- ID и приоритеты: [IT-09](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5397) — P1.
- Затрагиваемые модули (03): EventBus, DevTools, UI; [IT-09](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5397).

- `PetFeedingPolicy`: [IT-09](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5397). Цитата из [IT-09](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5397): «**Один `OutOfCombatRecoveryObservation`/`RecoveryConsumablePolicy` и `PetFeedingNeedObservation`/`PetFeedingPolicy` поверх IT-01 `InventoryObservation`/`ItemFamilyCatalog`, IT-03 `ItemUseEligibilityObservation`, IT-04 `ItemFamilySelectionObservation`, SP-01 общего aura reader, GameState player health/mana/combat и PE-02 `PetHappinessObservation`.** Это два логических policy consumers **одних универсальных источников**, а не два новых inventory/aura/pet engines. В том же `ItemFamilyCatalog` расширить `FOOD»

## PetHappinessObservation

- Имя первичного определения: `PetHappinessObservation` ([PE-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4313)).
- Число ID: **2**.
- ID и приоритеты: [IT-09](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5397) — P1; [PE-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4313) — P1.
- Затрагиваемые модули (03): EventBus, DevTools, UI, GameAPI, GameState, AbilityEligibility, RotationConditions; [IT-09](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5397), [PE-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4313).

- `PetHappinessObservation`: [PE-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4313), [IT-09](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5397). Цитата из [PE-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4313): «**Выбрать единый PE-01 `PetObservation`, расширенный `PetVitalsObservation` и `PetHappinessObservation` как логические поля того же snapshot; Kord GameState/GameAPI — numeric validation, RotationMaster — edition-gated secret-safe mood provider, Sonah — classic happiness thresholds и hunter upkeep, JustAC — API probe/диагностика.** Pet health использует существующий `cleanHealth("pet")`; pet power определяется **сначала** `UnitPowerType("pet")`, затем `UnitPower/Max("pet", confirmedType)`, native `UnitPowe»

## PetObservation

- Имя первичного определения: `PetObservation` ([PE-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4251)).
- Число ID: **4**.
- ID и приоритеты: [CL-08](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9713) — P0; [PE-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4251) — P1; [PE-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4313) — P1; [PE-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4373) — P1.
- Затрагиваемые модули (03): GameAPI, EventBus, AbilityEligibility, DevTools, GameState, UI, RotationConditions; [CL-08](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9713), [PE-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4251), [PE-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4313), [PE-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4373).

- `PetObservation`: [PE-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4251), [PE-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4313), [PE-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4373), [CL-08](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9713). Цитата из [PE-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4251): «1. Расширить существующий `GameState.pet` единым `PetObservation` с независимыми `exists/alive/visible/active/controllable`, petGUID/ownerGUID, source, reason и revision; не создавать новый pet scanner.»

## PetStanceObservation

- Имя первичного определения: `PetStanceObservation` ([PE-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4373)).
- Число ID: **1**.
- ID и приоритеты: [PE-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4373) — P1.
- Затрагиваемые модули (03): GameState, EventBus, AbilityEligibility, RotationConditions, DevTools; [PE-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4373).

- `PetStanceObservation`: [PE-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4373). Цитата из [PE-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4373): «**Основа — PE-01 `PetObservation` + ForeverAuras активная pet stance button и `UNIT_TARGET("pet")` + JustAC pet-target comparison + RotationMaster осторожные `PET_ATTACK_START/STOP` и pet action API guards + существующий Kord GameState.** Добавить логические поля `PetTargetObservation`, `PetAttackActivityObservation`, `PetStanceObservation` в **тот же petGUID-scoped snapshot**, без второго scanner. Для target: читать `UnitExists("pettarget")`, `UnitGUID("pettarget")`, после чтения подтверждать, что petGUI»

## PetStateProvider

- Имя первичного определения: `PetStateProvider` ([CL-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9152)).
- Число ID: **1**.
- ID и приоритеты: [CL-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9152) — P0.
- Затрагиваемые модули (03): в файле не указано; [CL-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9152).

- `PetStateProvider`: [CL-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9152). Цитата из [CL-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9152): «3. `PetStateProvider` + `PetCommandProvider`: exists/dead/HP/target/behavior/happiness/food, commands, Mend/Revive/Call; общий контракт AC-03, fail-closed.»

## PetTargetObservation

- Имя первичного определения: `PetTargetObservation` ([PE-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4373)).
- Число ID: **1**.
- ID и приоритеты: [PE-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4373) — P1.
- Затрагиваемые модули (03): GameState, EventBus, AbilityEligibility, RotationConditions, DevTools; [PE-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4373).

- `PetTargetObservation`: [PE-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4373). Цитата из [PE-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4373): «**Основа — PE-01 `PetObservation` + ForeverAuras активная pet stance button и `UNIT_TARGET("pet")` + JustAC pet-target comparison + RotationMaster осторожные `PET_ATTACK_START/STOP` и pet action API guards + существующий Kord GameState.** Добавить логические поля `PetTargetObservation`, `PetAttackActivityObservation`, `PetStanceObservation` в **тот же petGUID-scoped snapshot**, без второго scanner. Для target: читать `UnitExists("pettarget")`, `UnitGUID("pettarget")`, после чтения подтверждать, что petGUI»

## PetVitalsObservation

- Имя первичного определения: `PetVitalsObservation` ([PE-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4313)).
- Число ID: **1**.
- ID и приоритеты: [PE-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4313) — P1.
- Затрагиваемые модули (03): GameAPI, GameState, EventBus, AbilityEligibility, RotationConditions, DevTools; [PE-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4313).

- `PetVitalsObservation`: [PE-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4313). Цитата из [PE-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4313): «**Выбрать единый PE-01 `PetObservation`, расширенный `PetVitalsObservation` и `PetHappinessObservation` как логические поля того же snapshot; Kord GameState/GameAPI — numeric validation, RotationMaster — edition-gated secret-safe mood provider, Sonah — classic happiness thresholds и hunter upkeep, JustAC — API probe/диагностика.** Pet health использует существующий `cleanHealth("pet")`; pet power определяется **сначала** `UnitPowerType("pet")`, затем `UnitPower/Max("pet", confirmedType)`, native `UnitPowe»

## PlayerAutoAttackObservation

- Имя первичного определения: `AutoAttackModeObservation` ([SW-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4623)).
- Число ID: **4**.
- ID и приоритеты: [SW-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4623) — P0; [SW-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4680) — P1; [SW-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4735) — P1; [SW-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4790) — P2.
- Затрагиваемые модули (03): GameState, EventBus, AbilityEligibility, RotationConditions, DevTools; [SW-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4623), [SW-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4680), [SW-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4735), [SW-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4790).

- `AutoAttackModeObservation`: [SW-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4623). Цитата из [SW-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4623): «**Единый логический `PlayerAutoAttackObservation` в GameState с тремя `AutoAttackModeObservation`, по образцу RotationMaster tri-state API и JustAC Forever-specific проверки, плюс Sonah auto-switch awareness.** Не создавать class-specific scanners. `MELEE_ATTACK`: `C_Spell.IsCurrentSpell(6603)`; `RANGED_AUTO_SHOT`: `C_Spell.IsAutoRepeatSpell(75)`; `WAND_SHOOT`: `C_Spell.IsAutoRepeatSpell(5019)`; отдельный `currentSpell` для каждого — диагностический факт, а не замена autoRepeat. Если client API возвращает»
- `PlayerAutoAttackObservation`: [SW-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4623), [SW-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4680), [SW-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4735), [SW-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4790). Цитата из [SW-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4623): «**Единый логический `PlayerAutoAttackObservation` в GameState с тремя `AutoAttackModeObservation`, по образцу RotationMaster tri-state API и JustAC Forever-specific проверки, плюс Sonah auto-switch awareness.** Не создавать class-specific scanners. `MELEE_ATTACK`: `C_Spell.IsCurrentSpell(6603)`; `RANGED_AUTO_SHOT`: `C_Spell.IsAutoRepeatSpell(75)`; `WAND_SHOOT`: `C_Spell.IsAutoRepeatSpell(5019)`; отдельный `currentSpell` для каждого — диагностический факт, а не замена autoRepeat. Если client API возвращает»

## PlayerCastObservation

- Имя первичного определения: `PlayerCastObservation` ([SP-09](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L1370)).
- Число ID: **1**.
- ID и приоритеты: [SP-09](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L1370) — P1.
- Затрагиваемые модули (03): GameAPI, AbilityEligibility; [SP-09](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L1370).

- `PlayerCastObservation`: [SP-09](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L1370). Цитата из [SP-09](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L1370): «3. Отдельно расширить `PlayerCastObservation` для текущих `UnitCastingInfo`/`UnitChannelInfo` с безопасными start/end, spellID и статусом; не путать текущий канал с будущим channeled spell.»

## PlayerControlObservation

- Имя первичного определения: `PlayerControlObservation` ([CC-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5706)).
- Число ID: **2**.
- ID и приоритеты: [CC-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5706) — P0; [CC-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5834) — P2.
- Затрагиваемые модули (03): GameAPI, GameState, EventBus, AbilityEligibility, RotationConditions, DevTools; [CC-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5706), [CC-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5834).

- `PlayerControlObservation`: [CC-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5706), [CC-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5834). Цитата из [CC-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5706): «**Архитектурная актуализация CC-03:** для root/snare и решения об освобождении использовать общий `PlayerControlObservation` CC-01 и `ControlBreakSelection` CC-02; CC-03 добавляет отдельную политику необходимости снятия замедления/обездвиживания, а не второй LoC reader или breaker catalog (см. CC-03).»

## PlayerResourceObservation

- Имя первичного определения: `PlayerResourceObservation` ([SW-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4790)).
- Число ID: **9**.
- ID и приоритеты: [CL-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L8925) — P0; [CL-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9039) — P0; [CL-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9267) — P0; [CL-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9376) — P0; [CL-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9492) — P0; [CL-08](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9713) — P0; [CL-09](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9827) — P0; [IT-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5212) — P1; [SW-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4790) — P2.
- Затрагиваемые модули (03): UI, AbilityEligibility, WeaponEnchantProvider, GameAPI, EventBus, DevTools, GameState, RotationConditions; [CL-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L8925), [CL-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9039), [CL-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9267), [CL-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9376), [CL-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9492), [CL-08](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9713), [CL-09](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9827), [IT-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5212), [SW-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4790).

- `PlayerResourceObservation`: [SW-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4790), [IT-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5212). Цитата из [SW-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4790): «**Единый логический `NextSwingEmpowerObservation` поверх SW-01 `PlayerAutoAttackObservation`, SW-02 `PlayerSwingObservation`, общего `PlayerResourceObservation` и `AbilityEligibility`, с `NextSwingSpellCatalog` по семействам/рангам и `ResourceReservePolicy`.** Никакого второго swing scanner, class-specific queue observer или нового универсального resource provider. Для каждого изученного highest rank next-swing family проверять `C_Spell.IsCurrentSpell` через GameAPI secret-safe read; `true=QUEUED`, `false»
- `ResourceStateProvider`: [CL-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L8925), [CL-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9039), [CL-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9267), [CL-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9376), [CL-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9492), [CL-08](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9713), [CL-09](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9827). Цитата из [CL-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L8925): «2. `ResourceStateProvider` — typed RAGE, current/max, costs, reserve policy и проверка freshness; переиспользуется другими классами для их типов ресурсов.»

## PlayerSwingObservation

- Имя первичного определения: `PlayerSwingObservation` ([SW-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4680)).
- Число ID: **4**.
- ID и приоритеты: [AC-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L6382) — P1; [CL-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9152) — P0; [SW-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4680) — P1; [SW-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4790) — P2.
- Затрагиваемые модули (03): GameState, EventBus, DevTools, UI, AbilityEligibility, RotationConditions; [AC-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L6382), [CL-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9152), [SW-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4680), [SW-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4790).

- `PlayerSwingObservation`: [SW-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4680), [SW-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4790). Цитата из [SW-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4680): «**Один `PlayerSwingObservation` поверх SW-01 `PlayerAutoAttackObservation`, с `SwingEventAdapter` + `SwingSpeedAdapter`, общим EventBus и единым monotonic clock.** Не создавать hunter/rogue/warrior-specific swing scanners. События `PLAYER_SWING` (если действительно доступны Forever) и `COMBAT_LOG_EVENT_UNFILTERED` после client probe дают подтверждённый last swing anchor, с фильтром `sourceGUID==playerGUID` и классификацией `main/off/ranged`. Для Auto Shot/Wand проверять тип и семантику `RANGE_*` (wand мож»
- `SwingStateProvider`: [CL-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9152). Цитата из [CL-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9152): «5. `SwingStateProvider`: **раздельные ranged Auto Shot и melee swing**; read-only, confirmed duration/expiration, clip-safe window, fake clock и invalidation; при UNKNOWN — STOP для зависящих от swing правил, а не искусственный WAIT.»
- `SwingTimingObservation`: [AC-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L6382). Цитата из [AC-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L6382): «**Автострельба:** переиспользовать `GameState.ReadAutoShot` для факта активности, добавить отдельный capability-probed `SwingTimingObservation` на подтверждённом Forever `PLAYER_SWING`/swingDuration/swingType или доступном `C_SwingTimer`. Для ranged измерять ближайший выстрел и окно, в котором конкретное заклинание рискует его отложить, учитывая cast time, GCD, задержку, движение и range только по подтверждённым данным. **Не считать всякий instant spell клиппингом** и не утверждать безопасное окно по тайм»

## RangeObservation

- Имя первичного определения: `RangeObservation` ([SP-08](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L1298)).
- Число ID: **1**.
- ID и приоритеты: [SP-08](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L1298) — P0.
- Затрагиваемые модули (03): AbilityEligibility; [SP-08](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L1298).

- `RangeObservation`: [SP-08](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L1298). Цитата из [SP-08](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L1298): «2. Добавить ленивый **общеклассовый** `RangeObservation` с `spellInRange`, `melee`, необязательными `rangeBand`/`deadZone`, `status/reason/source`; никакого `Hunter*`-провайдера в ядре. Специфические пары ближних/дальних spellID и применимость dead zone определяются профилем, а не классом, зашитым в движок.»

## RecentlyBandagedAuraCatalog

- Имя первичного определения: `RecentlyBandagedAuraCatalog` ([IT-08](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5340)).
- Число ID: **1**.
- ID и приоритеты: [IT-08](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5340) — P2.
- Затрагиваемые модули (03): EventBus, DevTools; [IT-08](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5340).

- `RecentlyBandagedAuraCatalog`: [IT-08](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5340). Цитата из [IT-08](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5340): «**Один `BandageNeedAndSafetyObservation` + `BandagePolicy` поверх IT-01 inventory/catalog, IT-02 item cooldown, IT-03 item eligibility, IT-04 family selector, общего health snapshot, SP-01 aura provider, GR-05 target selection и TH-01 threat.** Не создавать отдельный scanner бинтов, дебафов, DoT или здоровья. Расширить **тот же IT-01 ItemFamilyCatalog**: `BANDAGE` itemIDs, `tierOrder`, `requiredPlayerLevel`, `healingAmount`, `channelDuration`, `clientEdition`, `source/verificationStatus`; классические/For»

## RecoveryConsumablePolicy

- Имя первичного определения: `RecoveryConsumablePolicy` ([IT-09](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5397)).
- Число ID: **1**.
- ID и приоритеты: [IT-09](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5397) — P1.
- Затрагиваемые модули (03): EventBus, DevTools, UI; [IT-09](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5397).

- `RecoveryConsumablePolicy`: [IT-09](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5397). Цитата из [IT-09](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5397): «**Один `OutOfCombatRecoveryObservation`/`RecoveryConsumablePolicy` и `PetFeedingNeedObservation`/`PetFeedingPolicy` поверх IT-01 `InventoryObservation`/`ItemFamilyCatalog`, IT-03 `ItemUseEligibilityObservation`, IT-04 `ItemFamilySelectionObservation`, SP-01 общего aura reader, GameState player health/mana/combat и PE-02 `PetHappinessObservation`.** Это два логических policy consumers **одних универсальных источников**, а не два новых inventory/aura/pet engines. В том же `ItemFamilyCatalog` расширить `FOOD»

## RequiredMaterialsObservation

- Имя первичного определения: `RequiredMaterialsObservation` ([IT-11](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5509)).
- Число ID: **1**.
- ID и приоритеты: [IT-11](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5509) — P1.
- Затрагиваемые модули (03): в файле не указано; [IT-11](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5509).

- `RequiredMaterialsObservation`: [IT-11](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5509). Цитата из [IT-11](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5509): «Ввести один `RequiredMaterialsObservation` (провайдер, не второй eligibility engine), вызываемый лениво через `Needs.materials`. Вход: `actionKind`, `spellID/itemID`, `rank`, `weaponSlot`, контекст клиента; выход: `requirementKind`, `itemID`, `requiredCount`, `availableCount`, `compatible`, `status`, `reason`, `source`, `revision`. Список требований — из проверяемого каталога/достоверного API; неизвестное требование не трактовать как отсутствие требований. Несколько материалов: все обязательные должны быт»

## ResourceConsumableNeedObservation

- Имя первичного определения: `ResourceConsumableNeedObservation` ([IT-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5212)).
- Число ID: **1**.
- ID и приоритеты: [IT-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5212) — P1.
- Затрагиваемые модули (03): GameState, EventBus, RotationConditions, DevTools, UI; [IT-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5212).

- `ResourceConsumableNeedObservation`: [IT-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5212). Цитата из [IT-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5212): «**Один логический `ResourceConsumableNeedObservation` и `ResourceConsumablePolicy` поверх общего typed `PlayerResourceObservation` из GameState, IT-01 `ItemFamilyCatalog`/`InventoryObservation`, IT-02 `ItemCooldownObservation`, IT-03 `ItemUseEligibilityObservation`, IT-04 `ItemFamilySelectionObservation`.** Никакого второго resource scanner, item scanner, ranked selector или отдельного cooldown engine. `ResourceThresholdObservation(powerType,thresholdPct)` предоставляет **два явно разных режима**: (A) `BR»

## ResourceConsumablePolicy

- Имя первичного определения: `ResourceConsumablePolicy` ([IT-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5212)).
- Число ID: **1**.
- ID и приоритеты: [IT-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5212) — P1.
- Затрагиваемые модули (03): GameState, EventBus, RotationConditions, DevTools, UI; [IT-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5212).

- `ResourceConsumablePolicy`: [IT-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5212). Цитата из [IT-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5212): «**Один логический `ResourceConsumableNeedObservation` и `ResourceConsumablePolicy` поверх общего typed `PlayerResourceObservation` из GameState, IT-01 `ItemFamilyCatalog`/`InventoryObservation`, IT-02 `ItemCooldownObservation`, IT-03 `ItemUseEligibilityObservation`, IT-04 `ItemFamilySelectionObservation`.** Никакого второго resource scanner, item scanner, ranked selector или отдельного cooldown engine. `ResourceThresholdObservation(powerType,thresholdPct)` предоставляет **два явно разных режима**: (A) `BR»

## ResourceReservePolicy

- Имя первичного определения: `ResourceReservePolicy` ([SW-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4790)).
- Число ID: **1**.
- ID и приоритеты: [SW-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4790) — P2.
- Затрагиваемые модули (03): EventBus, AbilityEligibility, RotationConditions, DevTools; [SW-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4790).

- `ResourceReservePolicy`: [SW-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4790). Цитата из [SW-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4790): «**Единый логический `NextSwingEmpowerObservation` поверх SW-01 `PlayerAutoAttackObservation`, SW-02 `PlayerSwingObservation`, общего `PlayerResourceObservation` и `AbilityEligibility`, с `NextSwingSpellCatalog` по семействам/рангам и `ResourceReservePolicy`.** Никакого второго swing scanner, class-specific queue observer или нового универсального resource provider. Для каждого изученного highest rank next-swing family проверять `C_Spell.IsCurrentSpell` через GameAPI secret-safe read; `true=QUEUED`, `false»

## ResourceTickProvider

- Имя первичного определения: `ResourceTickProvider` ([CL-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9267)).
- Число ID: **1**.
- ID и приоритеты: [CL-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9267) — P0.
- Затрагиваемые модули (03): AbilityEligibility, WeaponEnchantProvider; [CL-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9267).

- `ResourceTickProvider`: [CL-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9267). Цитата из [CL-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9267): «2. **`ResourceStateProvider`**: typed ENERGY, current/max, costs, reserve; `ResourceTickProvider` только с подтверждённым timing, fake clock и event invalidation. Общий с CL-01 Rage/CL-02 Mana, но без смешения единиц.»

## ResurrectionCandidatePolicy

- Имя первичного определения: `ResurrectionCandidatePolicy` ([GR-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4125)).
- Число ID: **1**.
- ID и приоритеты: [GR-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4125) — P2.
- Затрагиваемые модули (03): AbilityEligibility, DevTools; [GR-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4125).

- `ResurrectionCandidatePolicy`: [GR-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4125). Цитата из [GR-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4125): «**Основа — GR-01 roster + GR-02 member vitals/role + RotationMaster role/unit/dead observations + Sonah приоритет ручного friendly target и честное разделение emergency/maintenance + JustAC раздельные heal/resurrection spell categories.** Общий логический `GroupCareCandidateObservation(memberGUID)` предоставляет независимые `life`, `healthDeficit`, `healthPercent`, `role`, `incomingDamageEvidence` (только если доказано), `manualTargetPreference`, `range`, `observedAt`, `reason`. Производные `HealPriorityP»

## ResurrectionStateProvider

- Имя первичного определения: `ResurrectionStateProvider` ([CL-09](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9827)).
- Число ID: **1**.
- ID и приоритеты: [CL-09](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9827) — P0.
- Затрагиваемые модули (03): EventBus, AbilityEligibility, DevTools; [CL-09](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9827).

- `ResurrectionStateProvider`: [CL-09](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9827). Цитата из [CL-09](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9827): «5. **`ResurrectionStateProvider` (CL-02/CL-05/CL-06)** — общий выбор умершего союзника и ограничения боя, с отдельными policy `Revive` и `Rebirth`; client-only battle resurrection quota не выдумывать.»

## SealJudgementStateProvider

- Имя первичного определения: `SealJudgementStateProvider` ([CL-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9039)).
- Число ID: **1**.
- ID и приоритеты: [CL-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9039) — P0.
- Затрагиваемые модули (03): UI; [CL-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9039).

- `SealJudgementStateProvider`: [CL-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9039). Цитата из [CL-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9039): «2. **`SealJudgementStateProvider`** — typed seal ID/rank, compatible Judgement, verified consume/persist state, transition events; не считать Judgement всегда снимающим печать. При неизвестном результате применения — refresh snapshot/UNKNOWN, не угадывать.»

## SelfResurrectionStateProvider

- Имя первичного определения: `SelfResurrectionStateProvider` ([CL-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9492)).
- Число ID: **1**.
- ID и приоритеты: [CL-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9492) — P0.
- Затрагиваемые модули (03): WeaponEnchantProvider; [CL-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9492).

- `SelfResurrectionStateProvider`: [CL-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9492). Цитата из [CL-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9492): «6. **`SelfResurrectionStateProvider`** — отдельный typed status Reincarnation: dead/available/reagent/cooldown/client UI action; общий контракт для других self-resurrection mechanics, без имитации активной способности.»

## SharedCooldownGroupCatalog

- Имя первичного определения: `SharedCooldownGroupCatalog` ([IT-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4932)).
- Число ID: **1**.
- ID и приоритеты: [IT-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4932) — P0.
- Затрагиваемые модули (03): GameAPI, EventBus, AbilityEligibility, RotationConditions, DevTools; [IT-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4932).

- `SharedCooldownGroupCatalog`: [IT-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4932). Цитата из [IT-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4932): «`SharedCooldownGroupCatalog` **переиспользует** IT-01 family itemIDs, но **не** приравнивает все функциональные семейства к общему cooldown: `healthPotion` и `manaPotion` могут разделять `POTION_SHARED`, тогда как healthstone, bandage, food, mana gem, trinket и GCD требуют отдельных подтверждённых связей. Группа получает `CONFIRMED_ACTIVE` только если (a) валидированные cooldown-состояния нескольких подходящих членов/категорий подтверждают общую блокировку, либо (b) подтверждённое применение itemID и пров»

## SharedItemCooldownObservation

- Имя первичного определения: `SharedItemCooldownObservation` ([IT-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4932)).
- Число ID: **3**.
- ID и приоритеты: [IT-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4932) — P0; [IT-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5005) — P0; [IT-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5080) — P0.
- Затрагиваемые модули (03): GameAPI, EventBus, AbilityEligibility, RotationConditions, DevTools; [IT-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4932), [IT-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5005), [IT-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5080).

- `SharedItemCooldownObservation`: [IT-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4932), [IT-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5005), [IT-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5080). Цитата из [IT-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4932): «**Один логический `ItemCooldownObservation` + `SharedItemCooldownObservation` поверх IT-01 `InventoryObservation`/`ItemFamilyCatalog` и единого EventBus.** `ItemCooldownAdapter` — read-only `C_Item.GetItemCooldown`, fallback `C_Container.GetItemCooldown` и legacy **только** после Forever API probe; `C_Item.GetItemSpell` — дополнительная проверка item use-spell identity, не замена itemID. Нормализовать `enabled` (bool/0/1), проверять secret/finite/start/duration/clock. `active=true` при подтверждённом cool»

## ShotInteractionPolicy

- Имя первичного определения: `ShotInteractionPolicy` ([SW-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4735)).
- Число ID: **1**.
- ID и приоритеты: [SW-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4735) — P1.
- Затрагиваемые модули (03): EventBus, AbilityEligibility, RotationConditions, DevTools; [SW-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4735).

- `ShotInteractionPolicy`: [SW-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4735). Цитата из [SW-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4735): «**Критический нюанс:** не каждый instant spell клиппит Auto Shot и не всякий cast сбрасывает таймер; необходимо тестировать на Forever, что реально останавливает/сдвигает выстрел, включая движение, GCD, Aimed/Multi/Steady Shot, смену дистанции, Feign Death и авто-переключение. `ShotInteractionPolicy` ограничивает рекомендации профиля, но **не** даёт `READY` и не обходит `AbilityEligibility`. Lazy `Needs.autoShotClip` (подразумевает SW-01/SW-02/cast timing), memo на evaluation, event revision и bounded выч»

## SoulShardObservation

- Имя первичного определения: `SoulShardObservation` ([CL-08](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9713)).
- Число ID: **1**.
- ID и приоритеты: [CL-08](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9713) — P0.
- Затрагиваемые модули (03): GameAPI, EventBus, AbilityEligibility, DevTools; [CL-08](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9713).

- `SoulShardObservation`: [CL-08](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9713). Цитата из [CL-08](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9713): «- `KordRotation/Core/GameState.lua:80–102,108–148,184–197,224–243`: общий typed power, player/target/pet snapshot, pet target и combat имеются. Нет typed `SoulShardObservation`, demon species, owner-specific Curse/Bane slots, Life Tap rank cost и portal state.»

## SpatialObservation

- Имя первичного определения: `SpatialObservation` ([PL-10](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L732)).
- Число ID: **1**.
- ID и приоритеты: [PL-10](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L732) — P1.
- Затрагиваемые модули (03): GameAPI, AbilityEligibility, UI; [PL-10](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L732).

- `SpatialObservation`: [PL-10](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L732). Цитата из [PL-10](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L732): «2. Ввести `SpatialObservation` с `playerFacingTarget`, `playerBehindTarget`, `targetBehindPlayer`, `relativePosition`, `distance`; каждый сигнал должен иметь собственные `status/reason/source` и достоверность `exact/estimated`.»

## SpellFamilyCatalog

- Имя первичного определения: `SpellFamilyCatalog` ([CL-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9039)).
- Число ID: **2**.
- ID и приоритеты: [CL-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9039) — P0; [CL-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9376) — P0.
- Затрагиваемые модули (03): UI, AbilityEligibility; [CL-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9039), [CL-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9376).

- `SpellFamilyCatalog`: [CL-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9039), [CL-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9376). Цитата из [CL-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9039): «1. **`AuraStateProvider`** — универсальные buff/debuff, source, duration, unknown/secret, обновление по revision; используется печатями, аурами, благословениями и руками. Класс-специфические **семейства эффектов** задаются проверенным `SpellFamilyCatalog`, не отдельными сканерами.»

## SpellKnowledgeObservation

- Имя первичного определения: `SpellKnowledgeObservation` ([SP-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L932)).
- Число ID: **2**.
- ID и приоритеты: [SP-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L932) — P0; [SP-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L1002) — P0.
- Затрагиваемые модули (03): AbilityEligibility, RotationConditions; [SP-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L932), [SP-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L1002).

- `SpellKnowledgeObservation`: [SP-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L932), [SP-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L1002). Цитата из [SP-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L932): «2. Добавить `SpellKnowledgeObservation` с `spellID`, `known`, `source`, `status/reason`, `player/pet bank`, `rank/override` (когда подтверждены). При противоречии источников не выдавать ложный `BLOCKED`.»

## SpellRangeProvider

- Имя первичного определения: `SpellRangeProvider` ([CL-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L8925)).
- Число ID: **2**.
- ID и приоритеты: [CL-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L8925) — P0; [CL-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9152) — P0.
- Затрагиваемые модули (03): в файле не указано; [CL-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L8925), [CL-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9152).

- `SpellRangeProvider`: [CL-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L8925), [CL-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9152). Цитата из [CL-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L8925): «5. `TargetHealthProvider` и `SpellRangeProvider` — точный HP%, min/max distance для конкретного Charge/Intercept/Execute; запрещён fallback «цель существует → дистанция подходит».»

## SpellRequirementsObservation

- Имя первичного определения: `SpellRequirementsObservation` ([SP-14](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L1620)).
- Число ID: **1**.
- ID и приоритеты: [SP-14](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L1620) — P1.
- Затрагиваемые модули (03): GameState, AbilityEligibility; [SP-14](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L1620).

- `SpellRequirementsObservation`: [SP-14](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L1620). Цитата из [SP-14](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L1620): «2. Общий `SpellRequirementsObservation` выдаёт отдельные `targetSatisfied`, `positionSatisfied`, `stealthSatisfied`, `formSatisfied`, `aurasSatisfied` с индивидуальными `READY/BLOCKED/UNKNOWN`, причиной и источником; агрегирование не теряет неизвестность.»

## StanceStateProvider

- Имя первичного определения: `StanceStateProvider` ([CL-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L8925)).
- Число ID: **1**.
- ID и приоритеты: [CL-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L8925) — P0.
- Затрагиваемые модули (03): в файле не указано; [CL-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L8925).

- `StanceStateProvider`: [CL-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L8925). Цитата из [CL-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L8925): «1. `StanceStateProvider` — canonical current stance, доступность, spell requirements, revision, проверка перехода; общая основа AC-05 и других классов.»

## StatObservation

- Имя первичного определения: `StatObservation` ([PL-11](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L785)).
- Число ID: **1**.
- ID и приоритеты: [PL-11](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L785) — P2.
- Затрагиваемые модули (03): GameAPI; [PL-11](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L785).

- `StatObservation`: [PL-11](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L785). Цитата из [PL-11](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L785): «1. Создать ленивый `StatObservation` с явными ключами `attackPower.melee/ranged`, `hit.melee/ranged/spell`, `crit.melee/ranged/spell`, `haste.melee/ranged/spell` — **только для реально используемых профилем показателей**.»

## StealthStateProvider

- Имя первичного определения: `StealthStateProvider` ([CL-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9267)).
- Число ID: **1**.
- ID и приоритеты: [CL-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9267) — P0.
- Затрагиваемые модули (03): AbilityEligibility, WeaponEnchantProvider; [CL-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9267).

- `StealthStateProvider`: [CL-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9267). Цитата из [CL-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9267): «3. **`StealthStateProvider`**: verified stealth and transitions, opener requirements, Vanish pending/confirmed, immunity and target positioning facts where supported; общий с формами/невидимостью других классов.»

## StoneFamilyCatalog

- Имя первичного определения: `StoneFamilyCatalog` ([IT-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5155)).
- Число ID: **1**.
- ID и приоритеты: [IT-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5155) — P1.
- Затрагиваемые модули (03): EventBus, AbilityEligibility, DevTools; [IT-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5155).

- `StoneFamilyCatalog`: [IT-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5155). Цитата из [IT-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5155): «**Один логический `WarlockStoneObservation` / `StoneLifecyclePolicy` поверх IT-01 `InventoryObservation`, IT-02 `ItemCooldownObservation`, IT-03 `ItemUseEligibilityObservation`, IT-04 `ItemFamilySelectionObservation`, общего spellbook/cast/aura/AbilityEligibility.** Не создавать второй item scanner, cooldown adapter, rank selector или независимый class engine. `StoneFamilyCatalog` — **расширение того же IT-01 ItemFamilyCatalog**: HEALTHSTONE (classic/improved), SOULSTONE item variants (validated on Foreve»

## StoneLifecyclePolicy

- Имя первичного определения: `StoneLifecyclePolicy` ([IT-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5155)).
- Число ID: **2**.
- ID и приоритеты: [CL-08](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9713) — P0; [IT-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5155) — P1.
- Затрагиваемые модули (03): GameAPI, EventBus, AbilityEligibility, DevTools; [CL-08](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9713), [IT-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5155).

- `StoneLifecyclePolicy`: [IT-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5155), [CL-08](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9713). Цитата из [IT-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5155): «**Один логический `WarlockStoneObservation` / `StoneLifecyclePolicy` поверх IT-01 `InventoryObservation`, IT-02 `ItemCooldownObservation`, IT-03 `ItemUseEligibilityObservation`, IT-04 `ItemFamilySelectionObservation`, общего spellbook/cast/aura/AbilityEligibility.** Не создавать второй item scanner, cooldown adapter, rank selector или независимый class engine. `StoneFamilyCatalog` — **расширение того же IT-01 ItemFamilyCatalog**: HEALTHSTONE (classic/improved), SOULSTONE item variants (validated on Foreve»

## SummonedEntityObservation

- Имя первичного определения: `SummonedEntityObservation` ([PE-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4568)).
- Число ID: **1**.
- ID и приоритеты: [PE-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4568) — P2.
- Затрагиваемые модули (03): GameAPI, EventBus, AbilityEligibility, DevTools; [PE-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4568).

- `SummonedEntityObservation`: [PE-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4568). Цитата из [PE-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4568): «1. Ввести единый `SummonedEntityObservation` и **один** slot adapter для всех тотемов, не дублировать class-specific scans; guardian adapter отдельный источник того же контракта.»

## SummoningRitualObservation

- Имя первичного определения: `SummoningRitualObservation` ([CL-08](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9713)).
- Число ID: **1**.
- ID и приоритеты: [CL-08](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9713) — P0.
- Затрагиваемые модули (03): GameAPI, EventBus, AbilityEligibility, DevTools; [CL-08](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9713).

- `SummoningRitualObservation`: [CL-08](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9713). Цитата из [CL-08](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9713): «**Один Warlock policy layer на общей инфраструктуре, а не самостоятельный модуль-ротационный движок.** Для shards использовать IT-01 inventory/item family и IT-05 reagent budget; логический `SoulShardObservation` не создает второй bag scanner. `DemonPetObservation` расширяет PE-01–PE-05 единого `PetObservation` по owner/pet GUID, идентичность демона и pet spell availability; pet actions только AC-03, guardians и ритуал PE-06. `CurseFamilyProvider` — **конфигурация общего `AuraStateProvider`**: на пару (`t»

## SwingEventAdapter

- Имя первичного определения: `SwingEventAdapter` ([SW-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4680)).
- Число ID: **1**.
- ID и приоритеты: [SW-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4680) — P1.
- Затрагиваемые модули (03): EventBus, AbilityEligibility, RotationConditions, DevTools; [SW-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4680).

- `SwingEventAdapter`: [SW-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4680). Цитата из [SW-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4680): «**Один `PlayerSwingObservation` поверх SW-01 `PlayerAutoAttackObservation`, с `SwingEventAdapter` + `SwingSpeedAdapter`, общим EventBus и единым monotonic clock.** Не создавать hunter/rogue/warrior-specific swing scanners. События `PLAYER_SWING` (если действительно доступны Forever) и `COMBAT_LOG_EVENT_UNFILTERED` после client probe дают подтверждённый last swing anchor, с фильтром `sourceGUID==playerGUID` и классификацией `main/off/ranged`. Для Auto Shot/Wand проверять тип и семантику `RANGE_*` (wand мож»

## SwingSpeedAdapter

- Имя первичного определения: `SwingSpeedAdapter` ([SW-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4680)).
- Число ID: **1**.
- ID и приоритеты: [SW-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4680) — P1.
- Затрагиваемые модули (03): EventBus, AbilityEligibility, RotationConditions, DevTools; [SW-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4680).

- `SwingSpeedAdapter`: [SW-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4680). Цитата из [SW-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4680): «**Один `PlayerSwingObservation` поверх SW-01 `PlayerAutoAttackObservation`, с `SwingEventAdapter` + `SwingSpeedAdapter`, общим EventBus и единым monotonic clock.** Не создавать hunter/rogue/warrior-specific swing scanners. События `PLAYER_SWING` (если действительно доступны Forever) и `COMBAT_LOG_EVENT_UNFILTERED` после client probe дают подтверждённый last swing anchor, с фильтром `sourceGUID==playerGUID` и классификацией `main/off/ranged`. Для Auto Shot/Wand проверять тип и семантику `RANGE_*` (wand мож»

## TalentObservation

- Имя первичного определения: `TalentObservation` ([PL-13](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L878)).
- Число ID: **1**.
- ID и приоритеты: [PL-13](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L878) — P1.
- Затрагиваемые модули (03): GameAPI; [PL-13](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L878).

- `TalentObservation`: [PL-13](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L878). Цитата из [PL-13](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L878): «**Основа — RotationMaster + Sonah + ForeverAuras**. Из RotationMaster взять разделение `talent selected/rank` и платформенных адаптеров; из Sonah — актуальное `C_Traits` наблюдение с secret-safe чтением и отделением статической карты от живых рангов; из ForeverAuras — точную модель `nodeID → entryID → spellID → activeEntry/rank`. Существующий `KordRotation/Core/Talents.lua` **расширить**, не заменять: сохранить вычисление сумм для `SpecDetector`, но добавить независимый ленивый `TalentObservation` для кон»

## TargetHealthProvider

- Имя первичного определения: `TargetHealthProvider` ([CL-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L8925)).
- Число ID: **1**.
- ID и приоритеты: [CL-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L8925) — P0.
- Затрагиваемые модули (03): в файле не указано; [CL-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L8925).

- `TargetHealthProvider`: [CL-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L8925). Цитата из [CL-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L8925): «5. `TargetHealthProvider` и `SpellRangeProvider` — точный HP%, min/max distance для конкретного Charge/Intercept/Execute; запрещён fallback «цель существует → дистанция подходит».»

## TargetRangeObservation

- Имя первичного определения: `TargetRangeObservation` ([EN-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3153)).
- Число ID: **3**.
- ID и приоритеты: [EN-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3153) — P1; [EN-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3376) — P1; [TG-09](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L2981) — P0.
- Затрагиваемые модули (03): EventBus; [EN-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3153), [EN-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3376), [TG-09](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L2981).

- `TargetRangeObservation`: [EN-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3153), [EN-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3376), [TG-09](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L2981). Цитата из [EN-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3153): «Один `EnemyProximityObservation(radius, origin="player")`, опирающийся на общий `UnitObservation(unitToken)`, `TargetRangeObservation` TG-09 и bounded GUID-index AU-06. Читает только подтверждённые на Forever `nameplateN`/другие наблюдаемые unit tokens; сохраняет `GUID`, `exists`, `alive`, `hostile`, `attackable`, `rangeBounds`, `source`, `observedAt`. Дедупликация по GUID обязательна; отсутствие nameplates **не** означает отсутствие врагов.»

## TargetSuggestionPolicy

- Имя первичного определения: `TargetSuggestionPolicy` ([AC-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L6235)).
- Число ID: **1**.
- ID и приоритеты: [AC-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L6235) — P2.
- Затрагиваемые модули (03): DevTools, UI; [AC-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L6235).

- `TargetSuggestionPolicy`: [AC-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L6235). Цитата из [AC-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L6235): «Расширить **общий `ActionRecommendation`** (AC-01–AC-03) типом `TARGET`, с отдельным `TargetSuggestionPolicy` и `TargetSuggestionEligibility` внутри существующего `RotationEngine/RotationConditions/AbilityEligibility` маршрута. Не создавать второй target engine и не вызывать protected actions. Источник кандидатов — общие EN-01–EN-06 enemy observations с дедупликацией EN-03, фильтрами враждебности/живости/доступности, защитой ломаемого CC EN-04 и приоритетом конкретной задачи. Если EN-06 не предоставляет н»

## TargetSwitchCandidateObservation

- Имя первичного определения: `TargetSwitchCandidateObservation` ([EN-07](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3579)).
- Число ID: **1**.
- ID и приоритеты: [EN-07](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3579) — P2.
- Затрагиваемые модули (03): AbilityEligibility, DevTools; [EN-07](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3579).

- `TargetSwitchCandidateObservation`: [EN-07](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3579). Цитата из [EN-07](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3579): «На основе единого наблюдаемого списка врагов предлагать (а) ближайшую **достоверно различимую по доступным данным** подходящую цель для ручного переключения и (б) врага с подтверждённым активным прерываемым cast/channel, когда можно корректно сопоставить каст, GUID, адресуемый unit token и подходящую способность прерывания. Разделить `TargetSwitchCandidateObservation`, `EnemyCastObservation`, `InterruptCandidateObservation` и окончательную проверку `AbilityEligibility`; эти названия — логические контракты»

## TauntNeedObservation

- Имя первичного определения: `TauntNeedObservation` ([TH-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3826)).
- Число ID: **1**.
- ID и приоритеты: [TH-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3826) — P2.
- Затрагиваемые модули (03): DevTools; [TH-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3826).

- `TauntNeedObservation`: [TH-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3826). Цитата из [TH-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3826): «- `KordRotation/Core/RotationConditions.lua:21,55`: есть `target.threat` и `target.targetsPlayer`, но нет `TauntNeedObservation` и отдельного результата для `taunt.ready` против `taunt.needed`.»

## ThreatObservation

- Имя первичного определения: `ThreatObservation` ([TH-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3701)).
- Число ID: **5**.
- ID и приоритеты: [CL-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9152) — P0; [CL-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9267) — P0; [TH-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3701) — P1; [TH-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3770) — P2; [TH-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3826) — P2.
- Затрагиваемые модули (03): AbilityEligibility, WeaponEnchantProvider, DevTools, UI; [CL-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9152), [CL-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9267), [TH-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3701), [TH-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3770), [TH-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3826).

- `ThreatObservation`: [TH-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3701), [TH-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3826), [TH-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3770). Цитата из [TH-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3701): «**Базовый контракт RotationMaster (единый lazy `ThreatObservation` с per-evaluation cache и `UNKNOWN(reason)`) + структурированные поля `UnitDetailedThreatSituation` по модели ForeverAuras + secret-safe ограничения Sonah + общий GUID-index EN-03 и EN-08 budget.** Это лучше прямых player-only проверок Sonah/MaxDps и повторных per-consumer обходов: одна общеклассовая точка получения фактов, явное разделение `onThreatTable`, `threatStatus`, `isTanking`, `percent` и `ownerEvidence`, без фиктивного владельца а»
- `ThreatStateProvider`: [CL-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9152), [CL-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9267). Цитата из [CL-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9152): «7. `ThreatStateProvider`: solo/dungeon/raid, actual aggro, HP, Feign Death policy, independent defensive routing; общая модель защитных действий.»

## ThreatRiskObservation

- Имя первичного определения: `ThreatRiskObservation` ([TH-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3770)).
- Число ID: **1**.
- ID и приоритеты: [TH-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3770) — P2.
- Затрагиваемые модули (03): AbilityEligibility, DevTools, UI; [TH-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3770).

- `ThreatRiskObservation`: [TH-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3770). Цитата из [TH-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3770): «- `KordRotation/Core/RotationConditions.lua:21,55`: `target.threat` и `target.targetsPlayer` присутствуют, но нет общего `ThreatRiskObservation` и политики `REDUCE_THREAT/PAUSE_DPS`.»

## ThreatRiskPolicy

- Имя первичного определения: `ThreatRiskPolicy` ([TH-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3770)).
- Число ID: **1**.
- ID и приоритеты: [TH-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3770) — P2.
- Затрагиваемые модули (03): AbilityEligibility, DevTools, UI; [TH-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3770).

- `ThreatRiskPolicy`: [TH-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3770). Цитата из [TH-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3770): «**Расширение единого TH-01 `ThreatObservation(enemyGUID,actorGUID)` полями detailed threat по модели ForeverAuras + lazy UNKNOWN-safe condition RotationMaster + отдельная общеклассовая `ThreatRiskPolicy` и class-data выбора threat-drop по Sonah.** Не создавать второй `ThreatScanner` или собственную альтернативную threat table. `ThreatRiskObservation` — производная функция от TH-01, а не новый API-reader. Если клиент достоверно возвращает `threatPercent` (процент **порога перехвата**, не raw доля танка), с»

## TotemStateProvider

- Имя первичного определения: `TotemStateProvider` ([CL-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9492)).
- Число ID: **1**.
- ID и приоритеты: [CL-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9492) — P0.
- Затрагиваемые модули (03): WeaponEnchantProvider; [CL-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9492).

- `TotemStateProvider`: [CL-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9492). Цитата из [CL-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9492): «1. **`TotemStateProvider`** — typed slots `Earth/Fire/Water/Air`, spellID, exists/UNKNOWN, remaining, position, radius, per-member coverage, replaced/destroyed events; **универсальный deployable-unit provider** пригоден для других временных объектов, без отдельного движка шамана. Не выводить позицию из наличия баффа.»

## TTDObservation

- Имя первичного определения: `TTDObservation` ([EN-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3516)).
- Число ID: **1**.
- ID и приоритеты: [EN-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3516) — P2.
- Затрагиваемые модули (03): в файле не указано; [EN-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3516).

- `TTDObservation`: [EN-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3516). Цитата из [EN-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3516): «3. Расширить общий TG-06 `TTDObservation` до bounded GUID-keyed history для нескольких врагов; никакого отдельного `MultiDotTTD`.»

## UnitHealthObservation

- Имя первичного определения: `UnitHealthObservation` ([EN-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3516)).
- Число ID: **1**.
- ID и приоритеты: [EN-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3516) — P2.
- Затрагиваемые модули (03): в файле не указано; [EN-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3516).

- `UnitHealthObservation`: [EN-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3516). Цитата из [EN-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3516): «Для каждого **подтверждённого уникального enemyGUID** в общем наблюдаемом списке получать отдельный `UnitHealthObservation` (exact current/max/percent, если plain; пороговый percent отдельно) и `TTDObservation` (estimate/range/confidence/status/reason). `nil/UNKNOWN` при недостаточной истории, secret values, stale aliases или неопределённом DPS. Не выводить TTD из имени, уровня, одного процента здоровья или чужого GUID. Multi-DoT выбор должен учитывать время окупаемости эффекта, aura remaining, eligibilit»

## UnitIdentityIndex

- Имя первичного определения: `UnitIdentityIndex` ([EN-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3376)).
- Число ID: **2**.
- ID и приоритеты: [EN-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3376) — P1; [EN-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3516) — P2.
- Затрагиваемые модули (03): EventBus; [EN-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3376), [EN-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3516).

- `UnitIdentityIndex`: [EN-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3376), [EN-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3516). Цитата из [EN-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3376): «**Не создавать новый CC scanner, nameplate scanner, GUID index или отдельный AoE engine.** Использовать один `UnitIdentityIndex` EN-03, `ObservedEnemyIndex` EN-01/02, `TargetControlObservation(unitGUID)` TG-07, `AuraPresenceObservation` AU-01/06 и `TargetRangeObservation` TG-09. Добавить только логический производный `AoEControlSafetyObservation` в общий pipeline условий.»

## V14Registry

- Имя первичного определения: `V14Registry` ([QA-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L8357)).
- Число ID: **2**.
- ID и приоритеты: [QA-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L8357) — P0; [QA-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L8580) — P0.
- Затрагиваемые модули (03): EventBus, DevTools, UI; [QA-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L8357), [QA-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L8580).

- `V14Registry`: [QA-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L8357), [QA-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L8580). Цитата из [QA-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L8357): «- `KordRotationDevTools/Probe.lua:4–34,36–68`: метод сверяется с `V14Registry`, `ProbeAll` проходит строки, возвращает `presence_only_not_client_pass`; при активной записи сохраняет row-specific API entries. `:72–...` есть `Why()` с санитизированным read-only core bridge.»

## WaitDecisionPolicy

- Имя первичного определения: `WaitDecisionPolicy` ([AC-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L6382)).
- Число ID: **1**.
- ID и приоритеты: [AC-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L6382) — P1.
- Затрагиваемые модули (03): GameState, EventBus, DevTools, UI; [AC-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L6382).

- `WaitDecisionPolicy`: [AC-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L6382). Цитата из [AC-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L6382): «Ввести **`WaitDecisionPolicy`** как один typed action selector в общем `RotationEngine → RotationConditions → AbilityEligibility → recommendation`, без второго ротационного движка. `WAIT` — самостоятельный READY-кандидат с доказанной причиной и условием выхода, конкурирующий с SPELL/ITEM/PET_COMMAND/STANCE_OR_FORM через общий арбитр; TARGET остаётся информационной рекомендацией. Обычный `UNKNOWN` по обязательному наблюдению не превращается в WAIT и не должен маскировать диагностическую ошибку. `WAIT` не д»

## WarlockStoneObservation

- Имя первичного определения: `WarlockStoneObservation` ([IT-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5155)).
- Число ID: **1**.
- ID и приоритеты: [IT-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5155) — P1.
- Затрагиваемые модули (03): EventBus, AbilityEligibility, DevTools; [IT-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5155).

- `WarlockStoneObservation`: [IT-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5155). Цитата из [IT-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5155): «**Один логический `WarlockStoneObservation` / `StoneLifecyclePolicy` поверх IT-01 `InventoryObservation`, IT-02 `ItemCooldownObservation`, IT-03 `ItemUseEligibilityObservation`, IT-04 `ItemFamilySelectionObservation`, общего spellbook/cast/aura/AbilityEligibility.** Не создавать второй item scanner, cooldown adapter, rank selector или независимый class engine. `StoneFamilyCatalog` — **расширение того же IT-01 ItemFamilyCatalog**: HEALTHSTONE (classic/improved), SOULSTONE item variants (validated on Foreve»

## WeaponEnchantProvider

- Имя первичного определения: `WeaponTemporaryEnchantObservation` ([IT-10](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5454)).
- Число ID: **3**.
- ID и приоритеты: [CL-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9267) — P0; [CL-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9492) — P0; [IT-10](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5454) — P1.
- Затрагиваемые модули (03): AbilityEligibility, WeaponEnchantProvider, EventBus, DevTools; [CL-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9267), [CL-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9492), [IT-10](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5454).

- `WeaponEnchantProvider`: [CL-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9267), [CL-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9492). Цитата из [CL-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9267): «4. **`WeaponEnchantProvider`**: MH/OH enchant, family, remaining/charges, item inventory/usable, applied poison; **канонический общий модуль IT-10**, не Rogue-only scanner.»
- `WeaponTemporaryEnchantObservation`: [IT-10](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5454). Цитата из [IT-10](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5454): «**Один `WeaponTemporaryEnchantObservation` с `WeaponEnchantRefreshPolicy`** поверх `GameAPI` read-only adapter, общего `ItemFamilyCatalog` IT-01, IT-02 item cooldown, IT-03 eligibility, IT-04 family selection и единого `AbilityEligibility`. Не создавать по сканеру для rogue/shaman/warlock, не создавать отдельный consumable catalog, не использовать SP-01 player aura как доказательство отсутствия покрытия. В `GameAPI` добавить capability-probed `C_Item.GetWeaponEnchantInfo` для Forever, `C_PaperDollInfo.Get»

## WeaponEnchantRefreshPolicy

- Имя первичного определения: `WeaponEnchantRefreshPolicy` ([IT-10](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5454)).
- Число ID: **1**.
- ID и приоритеты: [IT-10](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5454) — P1.
- Затрагиваемые модули (03): EventBus, DevTools; [IT-10](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5454).

- `WeaponEnchantRefreshPolicy`: [IT-10](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5454). Цитата из [IT-10](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5454): «**Один `WeaponTemporaryEnchantObservation` с `WeaponEnchantRefreshPolicy`** поверх `GameAPI` read-only adapter, общего `ItemFamilyCatalog` IT-01, IT-02 item cooldown, IT-03 eligibility, IT-04 family selection и единого `AbilityEligibility`. Не создавать по сканеру для rogue/shaman/warlock, не создавать отдельный consumable catalog, не использовать SP-01 player aura как доказательство отсутствия покрытия. В `GameAPI` добавить capability-probed `C_Item.GetWeaponEnchantInfo` для Forever, `C_PaperDollInfo.Get»

## WeaponEquipmentObservation

- Имя первичного определения: `WeaponEquipmentObservation` ([IT-10](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5454)).
- Число ID: **1**.
- ID и приоритеты: [IT-10](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5454) — P1.
- Затрагиваемые модули (03): EventBus, DevTools; [IT-10](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5454).

- `WeaponEquipmentObservation`: [IT-10](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5454). Цитата из [IT-10](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5454): «3. Ввести общий `WeaponEquipmentObservation` main/off weapon presence/type/identity и equip revision, без второго scanner.»

## WorldContextObservation

- Имя первичного определения: `WorldContextObservation` ([IT-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5005)).
- Число ID: **1**.
- ID и приоритеты: [IT-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5005) — P0.
- Затрагиваемые модули (03): GameAPI, EventBus, AbilityEligibility, RotationConditions, DevTools; [IT-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5005).

- `WorldContextObservation`: [IT-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5005). Цитата из [IT-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5005): «**Один `ItemUseEligibilityObservation` поверх IT-01 `InventoryObservation`, IT-02 `ItemCooldownObservation`/`SharedItemCooldownObservation`, общего `Player/TargetObservation`, `WorldContextObservation` и `ItemRestrictionCatalog`; финальный READY исключительно в `AbilityEligibility`.** Логические adapters, не обязательные новые Lua-файлы. `ItemUsabilityAdapter` через `C_Item.IsUsableItem` (legacy только после probe), `ItemTargetAdapter` через `C_Item.IsItemInRange` с подтверждённым target kind/self/no-targ»

## Без общего контракта

- [PR-PR-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L55) — Сквозная трёхзначная логика (true / false / nil). Причина: общий именованный контракт из выбранного пути и требований не установлен; выбранный путь: в файле не указано.
- [PR-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L109) — Проверка защищённых (secret) значений до сравнений и арифметики. Причина: общий именованный контракт из выбранного пути и требований не установлен; выбранный путь: в файле не указано.
- [PR-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L147) — Только чтение данных и рекомендации; без автоматического управления персонажем. Причина: общий именованный контракт из выбранного пути и требований не установлен; выбранный путь: в файле не указано.
- [PR-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L177) — Единственный арбитр доступности действия: AbilityEligibility; профиль без игрового API. Причина: общий именованный контракт из выбранного пути и требований не установлен; выбранный путь: в файле не указано.
- [PR-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L207) — Объяснимость каждого решения. Причина: общий именованный контракт из выбранного пути и требований не установлен; выбранный путь: в файле не указано.
- [PR-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L239) — Единый адаптер игрового API с белым списком и безопасным отсутствием функций. Причина: общий именованный контракт из выбранного пути и требований не установлен; выбранный путь: в файле не указано.
- [PR-07](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L273) — Изоляция ошибок профилей и провайдеров: ошибка → UNKNOWN, не READY. Причина: общий именованный контракт из выбранного пути и требований не установлен; выбранный путь: в файле не указано.
- [PL-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L306) — Существует, жив, призрак, в сознании (CC). Причина: общий именованный контракт из выбранного пути и требований не установлен; выбранный путь: в файле не указано.
- [PL-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L347) — Класс, специализация, уровень, раса, фракция. Причина: общий именованный контракт из выбранного пути и требований не установлен; выбранный путь: в файле не указано.
- [PL-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L387) — Здоровье игрока: текущее, максимальное, процент. Причина: общий именованный контракт из выбранного пути и требований не установлен; выбранный путь: в файле не указано.
- [PL-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L437) — Ресурсы игрока: мана, ярость, энергия, фокус (если поддерживается). Причина: общий именованный контракт из выбранного пути и требований не установлен; выбранный путь: в файле не указано.
- [PL-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L483) — Вторичные ресурсы: очки комбо, осколки душ, руны и гравировки WoW Forever. Причина: общий именованный контракт из выбранного пути и требований не установлен; выбранный путь: в файле не указано.
- [PL-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L531) — Регенерация: пятисекундное правило маны и тики энергии. Причина: общий именованный контракт из выбранного пути и требований не установлен; выбранный путь: в файле не указано.
- [PL-07](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L578) — Боевой статус, группа/рейд/соло и режим подземелья. Причина: общий именованный контракт из выбранного пути и требований не установлен; выбранный путь: в файле не указано.
- [PL-09](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L681) — Скрытность, форма, стойка, облик и аура-статус класса. Причина: общий именованный контракт из выбранного пути и требований не установлен; выбранный путь: в файле не указано.
- [SP-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L1055) — Кулдаун способности: активен / нет, остаток времени, если безопасно. Причина: общий именованный контракт из выбранного пути и требований не установлен; выбранный путь: в файле не указано.
- [SP-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L1153) — Заряды: текущее число, максимум, время до следующего. Причина: общий именованный контракт из выбранного пути и требований не установлен; выбранный путь: в файле не указано.
- [SP-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L1199) — Пригодность: хватает ли ресурса, есть ли нужная форма/стойка/реагенты. Причина: общий именованный контракт из выбранного пути и требований не установлен; выбранный путь: в файле не указано.
- [SP-07](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L1250) — Стоимость: ресурс и количество, скидки (проки, талант). Причина: общий именованный контракт из выбранного пути и требований не установлен; выбранный путь: в файле не указано.
- [SP-10](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L1420) — Подтверждено ли заклинание на видимой панели (слот), клавиша привязки. Причина: общий именованный контракт из выбранного пути и требований не установлен; выбранный путь: в файле не указано.
- [SP-11](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L1468) — Подмена заклинания (override, вторая форма кнопки). Причина: общий именованный контракт из выбранного пути и требований не установлен; выбранный путь: в файле не указано.
- [SP-12](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L1515) — Реактивные способности: окно действует, подсветка кнопки (после уворота, парирования, крита). Причина: общий именованный контракт из выбранного пути и требований не установлен; выбранный путь: в файле не указано.
- [SP-13](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L1572) — Общие кулдауны и общие ресурсы (ловушки, шоки, печати, проклятия и т. п.). Причина: общий именованный контракт из выбранного пути и требований не установлен; выбранный путь: в файле не указано.
- [CA-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L1769) — Игрок кастует / ведёт канал: заклинание, оставшееся время, можно ли прервать. Причина: общий именованный контракт из выбранного пути и требований не установлен; выбранный путь: в файле не указано.
- [CA-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L1818) — Очередь способности на следующий удар (Heroic Strike, Raptor Strike и т. д.). Причина: общий именованный контракт из выбранного пути и требований не установлен; выбранный путь: в файле не указано.
- [CA-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L1869) — Последнее успешное, неудавшееся, прерванное заклинание игрока. Причина: общий именованный контракт из выбранного пути и требований не установлен; выбранный путь: в файле не указано.
- [CA-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L1918) — Каст цели: что кастует, прерываем ли, оставшееся время. Причина: общий именованный контракт из выбранного пути и требований не установлен; выбранный путь: в файле не указано.
- [CA-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L1971) — Окно «когда можно двигаться без потери каста». Причина: общий именованный контракт из выбранного пути и требований не установлен; выбранный путь: в файле не указано.
- [AU-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L2102) — Длительность, остаток времени, число стаков. Причина: общий именованный контракт из выбранного пути и требований не установлен; выбранный путь: в файле не указано.
- [AU-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L2162) — Тип: магия, яд, болезнь, проклятие, кровотечение; можно ли снять. Причина: общий именованный контракт из выбранного пути и требований не установлен; выбранный путь: в файле не указано.
- [AU-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L2219) — Поиск ауры по имени и семейству рангов, а не только по одному ID. Причина: общий именованный контракт из выбранного пути и требований не установлен; выбранный путь: в файле не указано.
- [AU-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L2282) — Подсчёт моих DoT и дебаффов на нескольких целях. Причина: общий именованный контракт из выбранного пути и требований не установлен; выбранный путь: в файле не указано.
- [AU-07](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L2351) — Проки и временные бонусы (таланты, экипировка, руны). Причина: общий именованный контракт из выбранного пути и требований не установлен; выбранный путь: в файле не указано.
- [AU-08](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L2401) — Защитные ауры цели (иммунитет, щит, отражение): не бить впустую. Причина: общий именованный контракт из выбранного пути и требований не установлен; выбранный путь: в файле не указано.
- [AU-09](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L2456) — Обновление ауры: «осталось меньше N секунд» без неоправданных мерцаний. Причина: общий именованный контракт из выбранного пути и требований не установлен; выбранный путь: в файле не указано.
- [TG-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L2506) — Цель существует, жива, враждебна, доступна для атаки, видима. Причина: общий именованный контракт из выбранного пути и требований не установлен; выбранный путь: в файле не указано.
- [TG-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L2591) — Здоровье цели: процент, текущее (если не защищено). Причина: общий именованный контракт из выбранного пути и требований не установлен; выбранный путь: в файле не указано.
- [TG-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L2649) — Уровень относительно игрока, классификация (обычная, элита, босс, редкая). Причина: общий именованный контракт из выбранного пути и требований не установлен; выбранный путь: в файле не указано.
- [TG-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L2704) — Тип существа (нежить, зверь, гуманоид, демон…) для способностей с условиями. Причина: общий именованный контракт из выбранного пути и требований не установлен; выбранный путь: в файле не указано.
- [TG-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L2754) — Цель в бою, цель цели (агро на мне / на питомце / на другом). Причина: общий именованный контракт из выбранного пути и требований не установлен; выбранный путь: в файле не указано.
- [TG-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L2813) — Время жизни цели (TTD): оценка с границей уверенности, nil если мало данных. Причина: общий именованный контракт из выбранного пути и требований не установлен; выбранный путь: в файле не указано.
- [TG-08](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L2928) — Бежит ли цель (Hamstring/Wing Clip etc нужен). Причина: общий именованный контракт из выбранного пути и требований не установлен; выбранный путь: в файле не указано.
- [TG-10](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3043) — Цель — игрок (PvP) или NPC; флаг PvP. Причина: общий именованный контракт из выбранного пути и требований не установлен; выбранный путь: в файле не указано.
- [TG-11](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3092) — Фокус-цель и мышь-цель (если профиль их использует). Причина: общий именованный контракт из выбранного пути и требований не установлен; выбранный путь: в файле не указано.
- [EN-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3295) — Распознавание одной и той же цели в разных источниках (без двойного счёта). Причина: общий именованный контракт из выбранного пути и требований не установлен; выбранный путь: в файле не указано.
- [EN-08](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3636) — Бюджет: чтение nameplates не чаще заданного интервала, без постоянного сканирования. Причина: общий именованный контракт из выбранного пути и требований не установлен; однозначный общий контракт в файле не указан.
- [GR-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4014) — Дебаффы, которые можно рассеять, у кого они. Причина: общий именованный контракт из выбранного пути и требований не установлен; однозначный общий контракт в файле не указан.
- [IT-12](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5554) — Активируемые предметы (аксессуары, инженерные устройства): кулдаун, пригодность — P1. Причина: общий именованный контракт из выбранного пути и требований не установлен; однозначный общий контракт в файле не указан.
- [IT-13](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5597) — Экстренное спасение: камень, зелье, щит; порог HP, смерть цели рядом — P1. Причина: общий именованный контракт из выбранного пути и требований не установлен; выбранный путь: в файле не указано.
- [IT-14](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5650) — Настройка: выбранные игроком предметы, пороги, автоподбор. Причина: общий именованный контракт из выбранного пути и требований не установлен; однозначный общий контракт в файле не указан.
- [AC-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L6006) — SPELL: заклинание или способность (первый обязательный тип действия). Причина: общий именованный контракт из выбранного пути и требований не установлен; однозначный общий контракт в файле не указан.
- [AC-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L6156) — PET_COMMAND: команда питомцу (после PE-04). Причина: общий именованный контракт из выбранного пути и требований не установлен; однозначный общий контракт в файле не указан.
- [AC-07](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L6453) — STOP: остановка рекомендаций при неизвестном ключевом факте. Причина: общий именованный контракт из выбранного пути и требований не установлен; однозначный общий контракт в файле не указан.
- [UI-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L7812) — Иконка рекомендуемого действия и следующая в очереди. Причина: общий именованный контракт из выбранного пути и требований не установлен; однозначный общий контракт в файле не указан.
- [UI-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L7947) — Окно настроек из схемы CFG: группы, подсказки, конфликты источников. Причина: общий именованный контракт из выбранного пути и требований не установлен; однозначный общий контракт в файле не указан.
- [UI-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L8023) — Профили настроек для спека и контента, импорт, экспорт. Причина: общий именованный контракт из выбранного пути и требований не установлен; однозначный общий контракт в файле не указан.
- [UI-07](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L8229) — Локализация (ru, en), единые ключи. Причина: общий именованный контракт из выбранного пути и требований не установлен; однозначный общий контракт в файле не указан.
- [UI-08](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L8293) — Реакция на скрытие панелей и аддоны панелей (Bartender, Dominos, ElvUI и др.). Причина: общий именованный контракт из выбранного пути и требований не установлен; однозначный общий контракт в файле не указан.
- [DA-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L7283) — Шина событий с ревизиями каналов, пакетная обработка. Причина: общий именованный контракт из выбранного пути и требований не установлен; однозначный общий контракт в файле не указан.
- [DA-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L7352) — Кэш на одну оценку и долгий кэш только с инвалидацией по событиям. Причина: общий именованный контракт из выбранного пути и требований не установлен; однозначный общий контракт в файле не указан.
- [DA-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L7428) — Провайдеры данных подключаются через список Needs; без разрешения профиль данные не получит. Причина: общий именованный контракт из выбранного пути и требований не установлен; однозначный общий контракт в файле не указан.
- [DA-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L7502) — Бюджет времени на оценку, замер, предупреждение при превышении. Причина: общий именованный контракт из выбранного пути и требований не установлен; однозначный общий контракт в файле не указан.
- [DA-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L7562) — Нет постоянного сканирования: данные читаются по запросу. Причина: общий именованный контракт из выбранного пути и требований не установлен; однозначный общий контракт в файле не указан.
- [DA-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L7620) — Защита от «шторма» событий (кулдаун, ауры). Причина: общий именованный контракт из выбранного пути и требований не установлен; однозначный общий контракт в файле не указан.
- [DA-07](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L7674) — Сохранение настроек, миграция схемы, сброс на дефолты. Причина: общий именованный контракт из выбранного пути и требований не установлен; однозначный общий контракт в файле не указан.
- [DA-08](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L7736) — Реакция на смену спека, талантов, уровня, панели, привязок. Причина: общий именованный контракт из выбранного пути и требований не установлен; однозначный общий контракт в файле не указан.
- [QA-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L8434) — Журнал с полным списком причин, а не обрезанным белым списком; подпричины для панели и проверок. Причина: общий именованный контракт из выбранного пути и требований не установлен; однозначный общий контракт в файле не указан.
- [QA-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L8506) — Mock-тесты движка и профилей, запуск на Lua 5.1. Причина: общий именованный контракт из выбранного пути и требований не установлен; однозначный общий контракт в файле не указан.
- [QA-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L8665) — Дифференциальные тесты старой и новой логики. Причина: общий именованный контракт из выбранного пути и требований не установлен; однозначный общий контракт в файле не указан.
- [QA-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L8742) — Статическая проверка: профиль не обращается к игровым функциям. Причина: общий именованный контракт из выбранного пути и требований не установлен; однозначный общий контракт в файле не указан.
- [QA-07](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L8820) — Сценарные таблицы «состояние → ожидаемое действие» для каждого профиля. Причина: общий именованный контракт из выбранного пути и требований не установлен; однозначный общий контракт в файле не указан.
- [CL-07](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9599) — Маг: мана и порог, брони и интеллект, Polymorph/контроль, «превосходство», заморозка, «зачарование», создание еды и восстановление маны. Причина: общий именованный контракт из выбранного пути и требований не установлен; выбранный путь: в файле не указано.
- [NO-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9941) — Запрещено нажимать кнопки, выполнять макросы, менять цель и двигать персонажа. Причина: общий именованный контракт из выбранного пути и требований не установлен; однозначный общий контракт в файле не указан.
- [NO-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L10035) — Запрещено читать скрытые значения в бою и подставлять догадки вместо nil. Причина: общий именованный контракт из выбранного пути и требований не установлен; однозначный общий контракт в файле не указан.
- [NO-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L10139) — Запрещено хранить в журнале произвольные данные игрока, цели и чат. Причина: общий именованный контракт из выбранного пути и требований не установлен; однозначный общий контракт в файле не указан.
- [NO-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L10248) — Запрещено включать в пользовательскую сборку другую логику, чем в диагностической. Причина: общий именованный контракт из выбранного пути и требований не установлен; однозначный общий контракт в файле не указан.
- [NO-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L10486) — Запрещено считать расхождение источников ошибкой, если оно становится настройкой CFG. Причина: общий именованный контракт из выбранного пути и требований не установлен; выбранный путь: в файле не указано.
