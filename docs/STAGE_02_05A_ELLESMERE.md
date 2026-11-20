# Этап 2.5a — EllesmereUI EABButton

**Дата:** 2026-11-21. **Версия:** `0.1.8.3-rc6`. **Результат:** исходники и mock-сценарии реализованы, QA в WoW Forever не проводился.

## Основание и сравнительное решение

- В рамках обязательного правила №1 ранее рассматривались `Sonah/Core/Atoms/ActionSlots.lua`, `Sonah/UI/ActionBars.lua`, `MaxDps/Buttons.lua`, `JustAC/ActionBarScanner.lua` и другие проекты. Выбран уже согласованный сканер реальных игровых action-слотов, а не импорт чужого кода.
- В первоисточнике EllesmereUI ([репозиторий](https://github.com/EllesmereGaming/EllesmereUI)) подтверждено:
  - `EllesmereUIActionBars/EUI_ActionBars_Secure.lua` создаёт именованные `EABButton` и назначает `SetAttribute("action",slot)`;
  - `EllesmereUIActionBars/EUI_ActionBars_Bars.lua` рассчитывает игровые слоты, присваивает атрибут `action`;
  - `EllesmereUIActionBars/EUI_ActionBars_Paging.lua` изменяет `action` при смене страницы.
- Поэтому достаточно минимального обнаружения `EABButton1..180` и переиспользования `ActionBarScanner.inspect()`: `IsVisible()`, безопасный `GetAttribute("action")`, `C_ActionBar.HasAction`/`HasAction`, `GetActionInfo` типа spell и допустимый spellID. Прямое `button.spell` без подтверждённого action-слота не разрешается.

## Содержимое реализации

- `KordRotation/Core/ActionBarScanner.lua`: один вызов `add(safeGlobal("EABButton"..i),"EllesmereUI")` в уже существующем ограниченном цикле `1..180`. Нет новых зависимостей и хуков, не меняются макросы, защищённые атрибуты и кнопки.
- `tests/stage_02_05_actionbar.lua`: проверяется подтверждённый EAB spell и точный `source`, скрытая EAB-кнопка, макрос вместо spell, смена `action` (устаревший кэш не даёт старый spell), переключение страницы, secret attribute и `ADDON_LOADED`.
- `Init.lua`, `.toc`: версия синхронизирована; новый модуль не создан и порядок загрузки не изменён.
- **OPie не интегрирован.** Его кольца не подтверждают обычные action-слоты Blizzard.

## Реальные проверки

- **PASS:** локально запущен `texlua tests/stage_02_05_actionbar.lua` в каталоге `/mnt/data/kord25`. Точный тестируемый `ActionBarScanner.lua` имеет Git blob SHA `9c89217e10ca402562f694516bc9e3266b4ca619`, тест `ff42482161a0b7d7a094e305ea14784c483c8d7d`. Эти хеши совпали с созданными GitHub blob перед коммитом.
- **Ограничение теста:** `GameAPI` и `EventBus` в данном локальном сценарии — короткие mock-реализации; тест настоящего интерфейса WoW и реального защитного API **NOT RUN**.
- **План игровой приёмки:** EAB-панели 1 и 10–15, скрытие/показ, переходы формы/стойки, смена страницы/специализации, макрос, пустой слот, разный ранг, исчезновение EAB, наличие/отсутствие OPie, конфликт названий кнопок. Критерий PASS: достоверный игровой action-слот; в иных случаях UNKNOWN.

## Размер и совместимость

Добавлена одна ветка обнаружения в текущем проходе. Библиотеки и новый OnUpdate не добавлены, нагрузку на клиент/FPS измерить только в реальном WoW Forever. **Нельзя обещать полную совместимость со всеми версиями EllesmereUI без игрового теста.** Следующий шаг — 2.6 по правилу №1, предварительное сравнение и отдельное одобрение.
