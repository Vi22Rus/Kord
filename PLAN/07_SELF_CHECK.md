# 7. Таблица самопроверки

| Проверка | Вычисленное значение |
|---|---|
| ID в REQUIREMENTS.md | 149 |
| ID в PLAN/01_INVENTORY.md | 149 |
| ID в PLAN/ITEMS/*.md | 149 |
| ID в PLAN/05_FINAL_PLAN.md | 149 |
| Пропущенные ID | пусто |
| Прежних заголовков групп, включая «Без общего контракта» | 137 |
| Прежних групп без модулей | 122 |
| Именованных контрактов до объединения | 160 |
| Контрактов после объединения | 147 |
| Пунктов «Без общего контракта» | 77 |
| Рёбер зависимостей | 42 |
| Рёбер без цитат | 0 |
| Циклических компонент | 0 |

| Проверенных строк модульных правок в итоговом плане | 725 |
| Строк модульных правок без ссылки на ID | 0 |

**Список строк модульных правок без ID:** пусто.

Остальные полные фрагменты «Требуемых изменений» и тестов приведены в секциях, заголовки которых содержат ссылки на исходные ID; построчные источники там не переименовывались.

## Доказательства объединений

### AuraPresenceObservation / AuraObservation / AuraStateProvider / PlayerAuraObservation

- AuraPresenceObservation — [EN-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3376): «**Не создавать новый CC scanner, nameplate scanner, GUID index или отдельный AoE engine.** Использовать один `UnitIdentityIndex` EN-03, `ObservedEnemyIndex` EN-01/02, `TargetControlObservation(unitGUID)` TG-07, `AuraPresenceObservation` AU-01/06 и `TargetRangeObservation` TG-09. Добавить только логический производный `AoEControlSafetyObservation` в общий pipeline условий.»
- AuraObservation — [GR-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4070): «**Выбрать GR-01 GUID-keyed roster + общий per-member `AuraObservation` GR-03/RotationMaster + проверку `HELPFUL` семейств и post-cast suppression JustAC + классовые декларации семейств Sonah + event/secret boundary ForeverAuras.** Один логический `GroupBuffCoverageObservation(memberGUID,buffFamilyID)` возвращает подтверждённые `PRESENT/MISSING_CONFIRMED/REFRESH_DUE/NOT_APPLICABLE/UNKNOWN`, matching auraID/rank, source, observedAt, completeness. Отдельный `GroupBuffRecommendation(buffFamilyID,castSpellID)`»
- AuraStateProvider — [CL-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L8925): «4. `AuraStateProvider` — player buffs, target debuffs, remaining, ownership и UNKNOWN, общий механизм для криков.»
- PlayerAuraObservation — [IT-07](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5276): «**Один логический `ConsumableBuffMaintenanceObservation` + `ConsumableBuffPolicy` поверх существующего общего `PlayerAuraObservation` (SP-01), IT-01 `ItemFamilyCatalog`/`InventoryObservation`, IT-02 `ItemCooldownObservation`, IT-03 `ItemUseEligibilityObservation` и IT-04 `ItemFamilySelectionObservation`.** Не создавать отдельный buff scanner, bag scanner, item cooldown reader, tier selector или отдельный READY gate. В **тот же** `ItemFamilyCatalog` добавить `itemID`, `auraSpellIDs`, `category=FLASK/ELIXIR»

### ThreatObservation / ThreatStateProvider

- ThreatObservation — [TH-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3701): «**Базовый контракт RotationMaster (единый lazy `ThreatObservation` с per-evaluation cache и `UNKNOWN(reason)`) + структурированные поля `UnitDetailedThreatSituation` по модели ForeverAuras + secret-safe ограничения Sonah + общий GUID-index EN-03 и EN-08 budget.** Это лучше прямых player-only проверок Sonah/MaxDps и повторных per-consumer обходов: одна общеклассовая точка получения фактов, явное разделение `onThreatTable`, `threatStatus`, `isTanking`, `percent` и `ownerEvidence`, без фиктивного владельца а»
- ThreatStateProvider — [CL-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9152): «7. `ThreatStateProvider`: solo/dungeon/raid, actual aggro, HP, Feign Death policy, independent defensive routing; общая модель защитных действий.»

### ComboPointStateProvider / ComboPointObservation

- ComboPointStateProvider — [CL-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9267): «1. **`ComboPointStateProvider`**: typed current/max, `targetIdentity`/revision, reset/move semantics только после проверки клиента, fail-closed при смене цели; переиспользуется другими классами, если combo resource применим.»
- ComboPointObservation — [CL-09](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9827): «3. **`ComboPointObservation` (CL-04)** — target GUID, current/cap, finisher requirements, loss/transfer on target change, form-specific gates; общая инфраструктура, отдельная Feral policy.»

### PlayerResourceObservation / ResourceStateProvider

- PlayerResourceObservation — [SW-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4790): «**Единый логический `NextSwingEmpowerObservation` поверх SW-01 `PlayerAutoAttackObservation`, SW-02 `PlayerSwingObservation`, общего `PlayerResourceObservation` и `AbilityEligibility`, с `NextSwingSpellCatalog` по семействам/рангам и `ResourceReservePolicy`.** Никакого второго swing scanner, class-specific queue observer или нового универсального resource provider. Для каждого изученного highest rank next-swing family проверять `C_Spell.IsCurrentSpell` через GameAPI secret-safe read; `true=QUEUED`, `false»
- ResourceStateProvider — [CL-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L8925): «2. `ResourceStateProvider` — typed RAGE, current/max, costs, reserve policy и проверка freshness; переиспользуется другими классами для их типов ресурсов.»

### InventoryObservation / InventoryItemObservation / InventoryFamilyObservation

- InventoryObservation — [IT-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4852): «**Один логический `InventoryObservation` в GameState/GameAPI с `InventoryItemObservation` и `InventoryFamilyObservation`, единым `ItemFamilyCatalog` и revision-based кэшем**, по архитектуре RotationMaster, с Forever каталогом JustAC и обновлением ForeverAuras. `InventoryReadAdapter` сперва пробует проверенный `C_Item.GetItemCount(itemID,false,false)`, а если semantics/secret/capability не позволяют доказать bags-only count, использует **один** bounded `C_Container` bag snapshot (только подтверждённые ID с»
- InventoryItemObservation — [IT-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4852): «**Один логический `InventoryObservation` в GameState/GameAPI с `InventoryItemObservation` и `InventoryFamilyObservation`, единым `ItemFamilyCatalog` и revision-based кэшем**, по архитектуре RotationMaster, с Forever каталогом JustAC и обновлением ForeverAuras. `InventoryReadAdapter` сперва пробует проверенный `C_Item.GetItemCount(itemID,false,false)`, а если semantics/secret/capability не позволяют доказать bags-only count, использует **один** bounded `C_Container` bag snapshot (только подтверждённые ID с»
- InventoryFamilyObservation — [IT-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4852): «**Один логический `InventoryObservation` в GameState/GameAPI с `InventoryItemObservation` и `InventoryFamilyObservation`, единым `ItemFamilyCatalog` и revision-based кэшем**, по архитектуре RotationMaster, с Forever каталогом JustAC и обновлением ForeverAuras. `InventoryReadAdapter` сперва пробует проверенный `C_Item.GetItemCount(itemID,false,false)`, а если semantics/secret/capability не позволяют доказать bags-only count, использует **один** bounded `C_Container` bag snapshot (только подтверждённые ID с»

### PlayerAutoAttackObservation / AutoAttackModeObservation

- PlayerAutoAttackObservation — [SW-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4623): «**Единый логический `PlayerAutoAttackObservation` в GameState с тремя `AutoAttackModeObservation`, по образцу RotationMaster tri-state API и JustAC Forever-specific проверки, плюс Sonah auto-switch awareness.** Не создавать class-specific scanners. `MELEE_ATTACK`: `C_Spell.IsCurrentSpell(6603)`; `RANGED_AUTO_SHOT`: `C_Spell.IsAutoRepeatSpell(75)`; `WAND_SHOOT`: `C_Spell.IsAutoRepeatSpell(5019)`; отдельный `currentSpell` для каждого — диагностический факт, а не замена autoRepeat. Если client API возвращает»
- AutoAttackModeObservation — [SW-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4623): «**Единый логический `PlayerAutoAttackObservation` в GameState с тремя `AutoAttackModeObservation`, по образцу RotationMaster tri-state API и JustAC Forever-specific проверки, плюс Sonah auto-switch awareness.** Не создавать class-specific scanners. `MELEE_ATTACK`: `C_Spell.IsCurrentSpell(6603)`; `RANGED_AUTO_SHOT`: `C_Spell.IsAutoRepeatSpell(75)`; `WAND_SHOOT`: `C_Spell.IsAutoRepeatSpell(5019)`; отдельный `currentSpell` для каждого — диагностический факт, а не замена autoRepeat. Если client API возвращает»

### PlayerSwingObservation / SwingTimingObservation / SwingStateProvider

- PlayerSwingObservation — [SW-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4680): «**Один `PlayerSwingObservation` поверх SW-01 `PlayerAutoAttackObservation`, с `SwingEventAdapter` + `SwingSpeedAdapter`, общим EventBus и единым monotonic clock.** Не создавать hunter/rogue/warrior-specific swing scanners. События `PLAYER_SWING` (если действительно доступны Forever) и `COMBAT_LOG_EVENT_UNFILTERED` после client probe дают подтверждённый last swing anchor, с фильтром `sourceGUID==playerGUID` и классификацией `main/off/ranged`. Для Auto Shot/Wand проверять тип и семантику `RANGE_*` (wand мож»
- SwingTimingObservation — [AC-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L6382): «**Автострельба:** переиспользовать `GameState.ReadAutoShot` для факта активности, добавить отдельный capability-probed `SwingTimingObservation` на подтверждённом Forever `PLAYER_SWING`/swingDuration/swingType или доступном `C_SwingTimer`. Для ranged измерять ближайший выстрел и окно, в котором конкретное заклинание рискует его отложить, учитывая cast time, GCD, задержку, движение и range только по подтверждённым данным. **Не считать всякий instant spell клиппингом** и не утверждать безопасное окно по тайм»
- SwingStateProvider — [CL-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9152): «5. `SwingStateProvider`: **раздельные ranged Auto Shot и melee swing**; read-only, confirmed duration/expiration, clip-safe window, fake clock и invalidation; при UNKNOWN — STOP для зависящих от swing правил, а не искусственный WAIT.»

### CastObservation / CastTimingObservation

- CastObservation — [PE-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4497): «**Один логический `PetCareTimingObservation(petGUID,careActionFamily)` поверх PE-01/02/04, общего `CastObservation` GameState, `AuraObservation` GR-03/GR-04 и единого cooldown provider AbilityEligibility.** Отдельные поля `castDuration/remaining`, `lastStartedAt`, `lastSucceededAt`, `auraDuration/remaining`, `cooldownRemaining`, `petIdentityTransitionAt`, каждый со `status/source/reason/revision`; все времена в секундах после подтверждённого преобразования из клиентских миллисекунд, часы — единый валидиро»
- CastTimingObservation — [SW-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4735): «**Один `AutoShotClipWindowObservation` поверх SW-01 `PlayerAutoAttackObservation`, SW-02 `PlayerSwingObservation.ranged`, общего `CastTimingObservation` и spell metadata/policy.** Никакого второго swing scanner и отдельного hunter event loop. `ShotInteractionPolicy(spellFamily,clientBuild)` — проверенный Forever-каталог `PRESERVES/RESETS/PAUSES/UNKNOWN` (на базе ForeverAuras, но с валидацией конкретного билда); `ActionLockObservation` — реальный cast/channel duration + проверенные GCD/animation/shot locks»

### WeaponEnchantProvider / WeaponTemporaryEnchantObservation

- WeaponEnchantProvider — [CL-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9267): «4. **`WeaponEnchantProvider`**: MH/OH enchant, family, remaining/charges, item inventory/usable, applied poison; **канонический общий модуль IT-10**, не Rogue-only scanner.»
- WeaponTemporaryEnchantObservation — [IT-10](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5454): «**Один `WeaponTemporaryEnchantObservation` с `WeaponEnchantRefreshPolicy`** поверх `GameAPI` read-only adapter, общего `ItemFamilyCatalog` IT-01, IT-02 item cooldown, IT-03 eligibility, IT-04 family selection и единого `AbilityEligibility`. Не создавать по сканеру для rogue/shaman/warlock, не создавать отдельный consumable catalog, не использовать SP-01 player aura как доказательство отсутствия покрытия. В `GameAPI` добавить capability-probed `C_Item.GetWeaponEnchantInfo` для Forever, `C_PaperDollInfo.Get»

## Обнаруженные циклы

не обнаружены

## Способ подсчёта

```text
source_ids = set(REQUIREMENTS.md headings)
card_ids = set(PLAN/ITEMS/*.md headings)
plan_ids = union(contract_member_ids, ungrouped_ids)
missing = source_ids - plan_ids
before = unique_named_contracts_excluding_modules
merged = unique_canonical_names_after_quote_supported_aliases
edges = sum(len(graph[contract]) for contract in graph)
uncited = [edge for edge in graph if not edge.source_id or not edge.quote]
cycles = tarjan_strongly_connected_components(graph) with size > 1
```
