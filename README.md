# Kord Rotation

**Актуальный этап: 2.9 — контракт v1 внедрён в исходники, проверка ещё впереди (2026-11-21).** Существующее ядро v14 и DevTools опубликованы в исходниках, но новые профили ещё не подключены, полный локальный прогон и игровой WoW Forever QA — NOT RUN; CLIENT PASS API v14 = 0/101.

## Архитектура
- `KordRotation-user.zip`: один исходный каталог `KordRotation/`.
- `KordRotation-dev.zip`: те же файлы `KordRotation/` байт-в-байт плюс отдельный `KordRotationDevTools/`.
- Никаких автоматических кастов; DevTools записывает диагностику только по ручному запросу.
- Старые Hunter-профили остаются исследовательской основой и не подключены через TOC.

## Действующий порядок
1. Очистка документации и сборки без утраты исходников/доказательств.
2. Исправленные mock-фикстуры — SOURCE DONE; [Profile Contract v1](docs/rotation/Profile_Contract.md) теперь SOURCE IMPLEMENTED (`RotationProfiles`, `RotationConditions`, `RotationEngine`), но LUA 5.1 / CLIENT NOT RUN.
3. Ревизия **17 актуальных** Lua suites, целевые и полный локальный прогон новой архитектуры (Actions остаётся ручным).
4. Подключение проверенных провайдеров GameState по [v14](docs/rotation/Canonical_API_Matrix.md); неподтверждённое остаётся `UNKNOWN`.
5. Mock/дифференциальные тесты, затем пилот Hunter BM Leveling PvE 1–59.

## Действующие документы
- [AGENTS.md](AGENTS.md) — процесс, согласования и GitHub Actions.
- [ROADMAP.md](docs/ROADMAP.md) — актуальные этапы.
- [Profile Contract v1](docs/rotation/Profile_Contract.md) — проект новой границы движка.
- [Creation Guide](docs/Kord_Rotation_Creation_Guide.md) — исследования и реализация профилей.
- [GameData Contract](docs/rotation/GameData_Contract.md) — данные и их неопределённость.
- [Two Builds](docs/BUILD_VARIANTS_AND_DIAGNOSTICS.md) — идентичный общий код в двух ZIP.
- [CHANGELOG](CHANGELOG.md) — изменения по коммитам.
- [Архив старого README](docs/archive/README_HISTORY_2026-11-21.md) — прежние релиз-кандидаты и исторические заметки, не текущие инструкции.

**Не объявлять SOURCE, MOCK и CLIENT PASS одним и тем же статусом.**
