# LEGACY TESTS — возрастная маркировка тестов Kord Rotation

> **Назначение:** одноразовая инвентаризация по времени существования тестового артефакта. Метка **LEGACY** означает **только** существование на момент начала рефакторинга; она НЕ означает некорректность, устаревание или необходимость удаления. Все тесты сохраняют обычный запуск и участие в CI.

## Правило и доказательство классификации

- **Дата маркировки:** 2026-11-22.
- **Граница:** 2026-11-22 **19:38:00 (Барнаул, UTC+7)** = `2026-11-22T12:38:00Z` (UTC).
- **Историческая ревизия:** [`56136a91d7fb2e7d4a59fbe1f57f96f39c9cb6f4`](https://github.com/Vi22Rus/Kord/commit/56136a91d7fb2e7d4a59fbe1f57f96f39c9cb6f4); время коммита по Git: `2026-11-22T12:35:21Z` (19:35:21 Барнаул), то есть последняя ревизия, найденная GitHub REST `commits?until=2026-11-22T12:38:00Z`.
- **Метод:** перечислены все файлы исторического дерева `git/trees/56136a91d7fb2e7d4a59fbe1f57f96f39c9cb6f4?recursive=1` и сопоставлены с текущим `main`. Оба ответа содержали `truncated=false`. Для категории исполняемых тестов включены **все** файлы каталога `tests/` (Lua, mock и Python), без выборочной фильтрации по названию. Для отдельных сценарных артефактов включены явно выделенные документы QA-плана, матрицы тестов и статической регрессии, если они были в историческом дереве.
- **Метка установлена только в настоящем реестре, не в исполняемых файлах**, чтобы не затрагивать код, тестовые ожидания, тестовую инфраструктуру и загрузку. Каждая перечисленная строка явно помечена `LEGACY`.
- **Количество:** 28 исполняемых файлов + 3 сценарных документа = **31 LEGACY-артефакт**. По состоянию на срез текущего дерева из 34 файлов `tests/` шесть появились после границы и не получают метку.
- **Контроль версий:** факт исторического присутствия доказан коммитом выше; дата не является датой последнего редактирования каждого теста.

## Исполняемые Lua/mock/Python тесты — 28 LEGACY

| № | Путь | Метка | Основание |
|---:|---|---|---|
| 1 | `tests/aura_cooldown_viewer_reference.lua` | **LEGACY** | Присутствует в [срезе Git до границы](https://github.com/Vi22Rus/Kord/tree/56136a91d7fb2e7d4a59fbe1f57f96f39c9cb6f4/tests/aura_cooldown_viewer_reference.lua) |
| 2 | `tests/bm_full_audit.lua` | **LEGACY** | Присутствует в [срезе Git до границы](https://github.com/Vi22Rus/Kord/tree/56136a91d7fb2e7d4a59fbe1f57f96f39c9cb6f4/tests/bm_full_audit.lua) |
| 3 | `tests/combat_aura_routing.lua` | **LEGACY** | Присутствует в [срезе Git до границы](https://github.com/Vi22Rus/Kord/tree/56136a91d7fb2e7d4a59fbe1f57f96f39c9cb6f4/tests/combat_aura_routing.lua) |
| 4 | `tests/devtools_boot.lua` | **LEGACY** | Присутствует в [срезе Git до границы](https://github.com/Vi22Rus/Kord/tree/56136a91d7fb2e7d4a59fbe1f57f96f39c9cb6f4/tests/devtools_boot.lua) |
| 5 | `tests/devtools_probe.lua` | **LEGACY** | Присутствует в [срезе Git до границы](https://github.com/Vi22Rus/Kord/tree/56136a91d7fb2e7d4a59fbe1f57f96f39c9cb6f4/tests/devtools_probe.lua) |
| 6 | `tests/devtools_recorder.lua` | **LEGACY** | Присутствует в [срезе Git до границы](https://github.com/Vi22Rus/Kord/tree/56136a91d7fb2e7d4a59fbe1f57f96f39c9cb6f4/tests/devtools_recorder.lua) |
| 7 | `tests/devtools_trace.lua` | **LEGACY** | Присутствует в [срезе Git до границы](https://github.com/Vi22Rus/Kord/tree/56136a91d7fb2e7d4a59fbe1f57f96f39c9cb6f4/tests/devtools_trace.lua) |
| 8 | `tests/devtools_trace_signals.lua` | **LEGACY** | Присутствует в [срезе Git до границы](https://github.com/Vi22Rus/Kord/tree/56136a91d7fb2e7d4a59fbe1f57f96f39c9cb6f4/tests/devtools_trace_signals.lua) |
| 9 | `tests/devtools_ui_locale.lua` | **LEGACY** | Присутствует в [срезе Git до границы](https://github.com/Vi22Rus/Kord/tree/56136a91d7fb2e7d4a59fbe1f57f96f39c9cb6f4/tests/devtools_ui_locale.lua) |
| 10 | `tests/devtools_v14_registry.lua` | **LEGACY** | Присутствует в [срезе Git до границы](https://github.com/Vi22Rus/Kord/tree/56136a91d7fb2e7d4a59fbe1f57f96f39c9cb6f4/tests/devtools_v14_registry.lua) |
| 11 | `tests/diagnostics_devtools_launch.lua` | **LEGACY** | Присутствует в [срезе Git до границы](https://github.com/Vi22Rus/Kord/tree/56136a91d7fb2e7d4a59fbe1f57f96f39c9cb6f4/tests/diagnostics_devtools_launch.lua) |
| 12 | `tests/hunter_bm_aspect_bar_rank.lua` | **LEGACY** | Присутствует в [срезе Git до границы](https://github.com/Vi22Rus/Kord/tree/56136a91d7fb2e7d4a59fbe1f57f96f39c9cb6f4/tests/hunter_bm_aspect_bar_rank.lua) |
| 13 | `tests/hunter_bm_aspect_switch.lua` | **LEGACY** | Присутствует в [срезе Git до границы](https://github.com/Vi22Rus/Kord/tree/56136a91d7fb2e7d4a59fbe1f57f96f39c9cb6f4/tests/hunter_bm_aspect_switch.lua) |
| 14 | `tests/hunter_bm_leveling_contract.lua` | **LEGACY** | Присутствует в [срезе Git до границы](https://github.com/Vi22Rus/Kord/tree/56136a91d7fb2e7d4a59fbe1f57f96f39c9cb6f4/tests/hunter_bm_leveling_contract.lua) |
| 15 | `tests/hunter_bm_rank_selection.lua` | **LEGACY** | Присутствует в [срезе Git до границы](https://github.com/Vi22Rus/Kord/tree/56136a91d7fb2e7d4a59fbe1f57f96f39c9cb6f4/tests/hunter_bm_rank_selection.lua) |
| 16 | `tests/indicator_slider_bounds.lua` | **LEGACY** | Присутствует в [срезе Git до границы](https://github.com/Vi22Rus/Kord/tree/56136a91d7fb2e7d4a59fbe1f57f96f39c9cb6f4/tests/indicator_slider_bounds.lua) |
| 17 | `tests/profile_contract_v1.lua` | **LEGACY** | Присутствует в [срезе Git до границы](https://github.com/Vi22Rus/Kord/tree/56136a91d7fb2e7d4a59fbe1f57f96f39c9cb6f4/tests/profile_contract_v1.lua) |
| 18 | `tests/rotation_module_config.lua` | **LEGACY** | Присутствует в [срезе Git до границы](https://github.com/Vi22Rus/Kord/tree/56136a91d7fb2e7d4a59fbe1f57f96f39c9cb6f4/tests/rotation_module_config.lua) |
| 19 | `tests/stage_02_03_game_state.lua` | **LEGACY** | Присутствует в [срезе Git до границы](https://github.com/Vi22Rus/Kord/tree/56136a91d7fb2e7d4a59fbe1f57f96f39c9cb6f4/tests/stage_02_03_game_state.lua) |
| 20 | `tests/stage_02_04_spell_catalogue.lua` | **LEGACY** | Присутствует в [срезе Git до границы](https://github.com/Vi22Rus/Kord/tree/56136a91d7fb2e7d4a59fbe1f57f96f39c9cb6f4/tests/stage_02_04_spell_catalogue.lua) |
| 21 | `tests/stage_02_05_actionbar.lua` | **LEGACY** | Присутствует в [срезе Git до границы](https://github.com/Vi22Rus/Kord/tree/56136a91d7fb2e7d4a59fbe1f57f96f39c9cb6f4/tests/stage_02_05_actionbar.lua) |
| 22 | `tests/stage_02_06_bindings.lua` | **LEGACY** | Присутствует в [срезе Git до границы](https://github.com/Vi22Rus/Kord/tree/56136a91d7fb2e7d4a59fbe1f57f96f39c9cb6f4/tests/stage_02_06_bindings.lua) |
| 23 | `tests/stage_02_07_eligibility.lua` | **LEGACY** | Присутствует в [срезе Git до границы](https://github.com/Vi22Rus/Kord/tree/56136a91d7fb2e7d4a59fbe1f57f96f39c9cb6f4/tests/stage_02_07_eligibility.lua) |
| 24 | `tests/stage_02_08_v14_argument_guards.lua` | **LEGACY** | Присутствует в [срезе Git до границы](https://github.com/Vi22Rus/Kord/tree/56136a91d7fb2e7d4a59fbe1f57f96f39c9cb6f4/tests/stage_02_08_v14_argument_guards.lua) |
| 25 | `tests/stage_02_08_v14_display.lua` | **LEGACY** | Присутствует в [срезе Git до границы](https://github.com/Vi22Rus/Kord/tree/56136a91d7fb2e7d4a59fbe1f57f96f39c9cb6f4/tests/stage_02_08_v14_display.lua) |
| 26 | `tests/stage_02_08_v14_observation.lua` | **LEGACY** | Присутствует в [срезе Git до границы](https://github.com/Vi22Rus/Kord/tree/56136a91d7fb2e7d4a59fbe1f57f96f39c9cb6f4/tests/stage_02_08_v14_observation.lua) |
| 27 | `tests/stage_02_08_v14_state.lua` | **LEGACY** | Присутствует в [срезе Git до границы](https://github.com/Vi22Rus/Kord/tree/56136a91d7fb2e7d4a59fbe1f57f96f39c9cb6f4/tests/stage_02_08_v14_state.lua) |
| 28 | `tests/test_build_variants.py` | **LEGACY** | Присутствует в [срезе Git до границы](https://github.com/Vi22Rus/Kord/tree/56136a91d7fb2e7d4a59fbe1f57f96f39c9cb6f4/tests/test_build_variants.py) |

## Документированные тестовые сценарии и матрицы — 3 LEGACY

| № | Путь | Метка | Основание |
|---:|---|---|---|
| 30 | `docs/STAGE_01_QA_PLAN.md` | **LEGACY** | Присутствует в [срезе Git до границы](https://github.com/Vi22Rus/Kord/tree/56136a91d7fb2e7d4a59fbe1f57f96f39c9cb6f4/docs/STAGE_01_QA_PLAN.md) |
| 31 | `docs/STAGE_01_STATIC_REGRESSION.md` | **LEGACY** | Присутствует в [срезе Git до границы](https://github.com/Vi22Rus/Kord/tree/56136a91d7fb2e7d4a59fbe1f57f96f39c9cb6f4/docs/STAGE_01_STATIC_REGRESSION.md) |
| 32 | `docs/rotation/Test_Matrix.md` | **LEGACY** | Присутствует в [срезе Git до границы](https://github.com/Vi22Rus/Kord/tree/56136a91d7fb2e7d4a59fbe1f57f96f39c9cb6f4/docs/rotation/Test_Matrix.md) |

## НЕ LEGACY — добавлены после границы

Следующие файлы отсутствуют в историческом дереве на 19:38 по Барнаулу, но присутствуют в текущем дереве. **Метка LEGACY им не назначена:**

- `tests/inventory_bag_snapshot_mock.lua` — **NOT LEGACY** (не было в историческом срезе).
- `tests/inventory_conditions_mock.lua` — **NOT LEGACY** (не было в историческом срезе).
- `tests/inventory_event_revisions_mock.lua` — **NOT LEGACY** (не было в историческом срезе).
- `tests/inventory_family_count_mock.lua` — **NOT LEGACY** (не было в историческом срезе).
- `tests/inventory_observation_contract.lua` — **NOT LEGACY** (не было в историческом срезе).
- `tests/item_family_catalog_mock.lua` — **NOT LEGACY** (не было в историческом срезе).

После границы также появились `PLAN/ITEMS/QA.md` и `docs/rotation/IT01_ITEM_COUNT_CLIENT_PROBE.md`; как новые документы, они **не помечены LEGACY**. Файлы `scripts/check_lua_syntax.lua`, `scripts/run_local_lua_regression.sh` и `.github/workflows/lua-regression.yml` являются инфраструктурой исполнения/проверки, а не самостоятельными тест-кейсами; их не маркируем и не изменяем. Другие технические отчёты, релизные инструкции и аудиты также не считаются отдельными тестами только из-за упоминания слова «тест».

## Последствия маркировки

- Ни один исходный тест не удалён, не отредактирован и не исключён из CI, скриптов или ручного запуска.
- Существующая тестовая логика, mock-провайдеры, входные данные, проверки `assert` и ожидаемые результаты не изменены.
- Метка не устанавливает PASS/FAIL и не подтверждает совместимость с новым ядром; актуальность каждого LEGACY-теста должна проверяться позднее отдельно.
- Движок, игровые модули, текущие тесты и CI не изменены в рамках этой классификации.
- Проверка: **PASS** — сравнение двух полных Git-деревьев, историческая датировка и точное соответствие списков; **NOT RUN** — запуск Lua/mock/Python/CI и WoW Forever, поскольку операция только документационная.

**История операции:** `KR-20261122-066` (SHA см. `git log --grep KR-20261122-066`).
