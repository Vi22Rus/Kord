# IT-01 — матрица проверок инвентаря (этап 1, шаг 1.10)

**Дата:** 2026-11-22. **Статус:** TESTS ADDED / LOCAL NOT RUN / FOREVER NOT RUN.
Это отдельный перечень сценариев. Наличие теста не означает PASS его выполнения. LEGACY означает лишь возраст (см. [LEGACY_TESTS.md](LEGACY_TESTS.md)); исторические тесты не изменены и не исключены.

| Сценарий из IT-01 | Тестовый источник | Фактический статус |
|---|---|---|
| 0/1/N item counts, known zero vs nil/secret | `inventory_observation_contract.lua`, `inventory_integration_regression.lua` | MOCK ADDED, NOT RUN |
| Несколько stacks и один item в разных bags | `inventory_bag_snapshot_mock.lua` | MOCK ADDED, NOT RUN |
| Secret/partial bag slot, nil info, scope | `inventory_bag_snapshot_mock.lua`, `inventory_diagnostics_mock.lua` | MOCK ADDED, NOT RUN |
| Exact C_Item count vs bag scan, false/false | `inventory_integration_regression.lua`, `inventory_bag_snapshot_mock.lua` | PARTIAL: независимо, не сравнительный runtime; NOT RUN |
| Bank-only/equipped-only excluded | `inventory_integration_regression.lua` (false/false), `inventory_conditions_mock.lua` (BANK scope) | PARTIAL, Forever semantics NOT VERIFIED |
| Health/mana potion, healthstones, bandage, food/drink, custom ID, ranks | `item_family_catalog_mock.lua`, `inventory_family_count_mock.lua` | MOCK ADDED, NOT RUN; Forever itemIDs NOT VERIFIED |
| Duplicate ID in one family, overlaps between families | `inventory_family_count_mock.lua`, `inventory_integration_regression.lua` | MOCK ADDED, NOT RUN |
| Split/merge stacks | `inventory_bag_snapshot_mock.lua`, `inventory_event_revisions_mock.lua` | PARTIAL, client NOT RUN |
| Soulwell healthstone refresh without BAG_UPDATE_DELAYED | `inventory_event_revisions_mock.lua`, `inventory_integration_regression.lua` | EXPLICIT RECHECK mocked; event attribution NOT IMPLEMENTED |
| Missing/out-of-order bag event, per-bag revisions, coalescing | `inventory_event_revisions_mock.lua` | MOCK ADDED, NOT RUN |
| Combat secret/UNKNOWN | `inventory_family_count_mock.lua`, `inventory_item_eligibility_mock.lua` | MOCK ADDED; game client NOT RUN |
| Item usability/cooldown separate from count | `inventory_item_eligibility_mock.lua`, `inventory_integration_regression.lua` | MOCK ADDED; IT-02/IT-03 providers NOT IMPLEMENTED |
| No heavy OnUpdate; no protected item use | Source review `EventBus.lua`, `GameState.lua`, `AbilityEligibility.lua` | STATIC REVIEW, runtime NOT RUN |
| DevTools-only codes, no raw item IDs/count | `inventory_diagnostics_mock.lua` | MOCK ADDED, NOT RUN |

**Обычный прогон:** `bash scripts/run_local_lua_regression.sh` — требует именно Lua 5.1, дополнительно запускает Python packaging test. Все новые mock tests добавлены в его стандартный список и к существующему GitHub Actions Lua suite без удаления исторических тестов. Полный игровой QA выполняется один раз после готовности этапа. В текущем окружении Lua 5.1 недоступен; texlua не подменяет Lua 5.1.

**Ограничение:** результаты только после реального запуска, на mock-код не распространяется статус TESTED. Проверки потребления itemID в игре, shared cooldown и Soulwell без bag event остаются предметом будущих IT-02/IT-03 и финальной клиентской регрессии.
