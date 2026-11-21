# Kord Rotation

**Текущий результат (2026-11-21): минимальный экспериментальный профиль Hunter BM подключён.** Он рекомендует только Arcane Shot (Spell ID 3044) при подтверждённой доступности, не выполняет касты и выключен по умолчанию. Полная BM-ротация, Lua 5.1 QA и проверка в клиенте WoW Forever ещё не завершены. Это прототип для игровой проверки, не релиз.

## Архитектура
- `KordRotation-user.zip`: один исходный каталог `KordRotation/`.
- `KordRotation-dev.zip`: те же файлы `KordRotation/` байт-в-байт плюс отдельный `KordRotationDevTools/`.
- Никаких автоматических кастов; DevTools записывает диагностику только по ручному запросу.
- Старые полные Hunter-профили остаются исследовательской основой и не подключены через TOC. В TOC подключён только `Profiles/Hunter/BM_Pilot_Experimental.lua`, отключённый по умолчанию.

## Как попробовать минимальный пилот в WoW Forever

1. Скачайте [ZIP исходников текущей ветки main](https://github.com/Vi22Rus/Kord/archive/refs/heads/main.zip) и извлеките из архива каталог **`KordRotation`** в `World of Warcraft/_retail_/Interface/AddOns/` (используйте фактическую папку `Interface/AddOns` вашей установки Forever, она может отличаться). Папка должна содержать `KordRotation.toc` прямо внутри. Не копируйте весь каталог `Kord-main` как аддон.
2. В игре включите **Kord Rotation**, откройте **`/kr`**, вкладку настроек ротации. Включите рекомендации, выберите **одну цель / single** (не Auto) и отдельно включите **экспериментальные рекомендации**.
3. Выберите специализацию Hunter BM (дерево 1), проверьте наличие изученного Arcane Shot и его кнопки на панели. Если движок сможет подтвердить способность, появится иконка. Если нет — подсказка не показывается вместо выдуманного READY.
4. Для диагностики можно отдельно установить `KordRotationDevTools`; он не требуется для пользовательской сборки. При неполадках экспериментальный режим можно отключить той же галочкой.

**Ограничение:** пилот — одна способность, не полная ротация. Высший ранг Arcane Shot и работа API в реальном Forever не подтверждены. Нет автокаста, нет автоопределения количества врагов, нет обещания совместимости с игровым клиентом. Для выпуска двух архивов из полного checkout используется `python3 scripts/build_variants.py`.

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
