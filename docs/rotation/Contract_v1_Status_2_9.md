# Этап 2.9-C — контрольная точка минимального Profile Contract v1

**Дата:** 2026-11-21. **Статус:** SOURCE IMPLEMENTED / TARGETED STATIC CHECKS PASS / LUA 5.1 NOT RUN / CLIENT NOT RUN. **Пилот Hunter BM не подключён.**

## Единый канон и код

- [Profile_Contract.md](Profile_Contract.md) — точная исходная версия заказчика, Git blob `17415a2401f9b82bd2c580fa8d69d63483a38a65`. Оригинал **не редактировать** ради смены статуса реализации: это исходное проектное соглашение.
- `KordRotation/Core/RotationProfiles.lua` — новый `contractVersion=1`, Needs allowlist, Spells, Config, Rules, статусы draft/mock_tested/experimental/verified; неперекрывающиеся диапазоны уровней; запрет неразрешённого skip; защитная копия `Get()`, доверенный `ResolveForEngine()` без копирования всех Rules на каждом Evaluate.
- `KordRotation/Core/RotationConditions.lua` — один ограниченный контекст S на оценку, без прямого snapshot и глобального WoW API; ленивые all/any, трёхзначные is/isNot/eq/ge/le; кэш провайдеров и Eligibility на один вызов Evaluate; нет подмены UNKNOWN ложью.
- `KordRotation/Core/RotationEngine.lua` — один ленивый проход с `pcall` по приоритету, stop по умолчанию, контролируемый skip только для неопределённого условия, Eligibility UNKNOWN всегда stop; неподдерживаемая PET_COMMAND пропускается без иконки. Сохраняется единственный текущий результат, отсутствие автокаста и прежний формат display.
- `KordRotation/UI/RotationDisplay.lua` — отдельный gated показ experimental, если `allowUnverifiedProfiles=true`; при отсутствии разрешения такая иконка не отображается.
- `scripts/build_variants.py` продолжает собирать из **единого** `KordRotation/` две побайтово согласованные поставки; неподключённые Hunter не попадают ни в один ZIP.

## Проверяемые исправления, обнаруженные в ходе миграции

1. `S:any` — ошибка `unknown and nil or false` исправлена, `nil` остаётся `nil`.
2. Lua CFG bool и enum — `false` не заменяется дефолтом. Первопричина подтверждена локальной краткой Lua-репродукцией, это не полный тест движка.
3. Числовой CFG отвергает `NaN/+Infinity/-Infinity`, защищённый SpellID проверяется через GameAPI до сравнений.
4. Ошибочный тип результата дочернего `all/any` бросает exception; Engine преобразует его в `UNKNOWN/condition_error`, не в разрешённый skip.
5. Разграничены runtime ID ветки `HUNTER_TREE_1` и ID конкретного диапазона профиля `HUNTER_BM_LEVELING_PVE`.

## Ревизия тестов

**17 актуальных Lua mock suites**: 18 исторических минус два устаревших Engine 2.8 tests плюс новый `tests/profile_contract_v1.lua`. Локальный `scripts/run_local_lua_regression.sh` и ручной workflow имеют одинаковые 17 путей, каждый файл существует. Старые engine tests доступны в Git history, но отсутствуют в текущем checkout.

В новом v1 mock добавлены сценарии: валидатор и уровни профиля, UNKNOWN stop/skip, `pcall`, lazy all/any, per-evaluation Eligibility cache, запрет undeclared needs, экспериментальный explicit opt-in, обнуление иконки при отзыве допуска, `false` CFG, nonfinite CFG и protected SpellID. Исторические GameAPI/GameState/Eligibility/UI/DevTools тесты сохранены.

**Что действительно проверено на актуальных исходниках:**
- Пять изменённых Lua-файлов: статическая проверка баланса скобок/строк/комментариев — PASS. Это не Lua compiler и не runtime.
- TOC `RotationConditions.lua` и перечень файлов — PASS.
- 17/17 тестовых путей совпадают между локальным runner и manual-only GitHub workflow; пропущенных путей нет.
- Точный Git blob пользовательского контракта остался неизменным.
- Референсные архивы Sonah, MaxDps, JustAC, ForeverAuras, ForeverRotation и RotationGuide исследованы на уровне структуры и профильных модулей; без копирования кода.

**Что НЕ выполнялось:** полный `lua5.1/luac5.1` на актуальном Git checkout (в доступной локальной среде нет полного checkout и бинарника Lua 5.1), новый `profile_contract_v1.lua` в полном runtime, GitHub Actions (запрещено запускать до общего QA), клиент WoW Forever. **Не писать 17/17 PASS.**

## Дополнительная правка после контрольной точки (KR-20261121-086…088)

- `RotationConditions.lua`: `spellFact(id, "inRange")` теперь отказывает (`nil`) для ID вне `Needs.ranges` **до обращения к провайдеру**. Наличие ID в `Spells` само по себе недостаточно для запроса дальности.
- `tests/profile_contract_v1.lua`: проверяется отсутствие вызова `Fact` для недекларированного range-ID и наличие вызова для разрешённого ID.
- **Проверка исполнения:** тесты обновлены, но новый Lua 5.1 mock-прогон не выполнен. 17-suite/клиент/CI по-прежнему NOT RUN; изоляция `UNKNOWN` от `READY` сохраняется.

## Уточнение локальной проверки (KR-20261121-090…091)
- Локальный runner теперь требует настоящий `lua5.1` и подтверждает `_VERSION == "Lua 5.1"`; `texlua` не подменяет приёмку (в текущей среде он сообщает `Lua 5.3`).
- Прямая загрузка полного Git checkout из текущего контейнера заблокирована DNS; GitHub доступен через подключение. **Ни один из 17 Lua mock suites пока не имеет подтверждённого runtime PASS.**
- После получения checkout с Lua 5.1 запустить `bash scripts/run_local_lua_regression.sh`, затем зафиксировать результаты пофайлово. До этого статус SOURCE IMPLEMENTED / LUA 5.1 NOT RUN.

## Блокирующие оставшиеся задачи ДО Hunter BM

1. Выполнить целевой контрактный mock на точном checkout в Lua 5.1, затем все 17 пересмотренных Lua tests, синтаксис и Python ZIP parity. Ошибки исправить до итогового общего QA.
2. Доработать и подтвердить по API v14 необходимые `GameState.ReadSignal` (auras по SpellID, range, enemyCount, TTD, swing) и `AbilityEligibility.Fact`. До этого будущие проверки должны возвращать UNKNOWN.
3. Выбор `targetMode=auto` сейчас сознательно возвращает `auto_target_count_unverified`; не включать автоподбор ST/AoE без достоверного счётчика.
4. CFG UI из схемы v1, хранение пользовательских конфигураций и локализация всех новых controls на 6 языков ещё не готовы; не выдавать наличие `Config` у профиля за готовую UI-генерацию.
5. Перед подключением Hunter выполнить статическую проверку запрета прямых WoW API в профиле и дифференциальные тесты против сохранённых исходников BM. Старые Hunter Lua сейчас не в TOC.

## Правила сохранности

История CHANGELOG и старые исследования не удаляются; они помечены историческими. Два ZIP содержат одно общее ядро, DevTools отдельный. `UNKNOWN` не превращается в `READY` ради удобства, игровые данные не выдумываются, автокаст не реализуется.
