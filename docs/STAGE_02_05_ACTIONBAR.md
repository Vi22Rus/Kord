# Этап 2.5 — ActionBarScanner, стандартные и сторонние панели

**Версия:** 0.1.8.3-rc5. **Статус:** IMPLEMENTED / AWAITING IN-GAME QA. Точная поддержка конкретных установленных версий Bartender4, Dominos, ElvUI и LibActionButton требует игрового тестирования.

## Правило № 1 — сравнительный анализ до реализации

Согласованная архитектура основана на локальных ZIP проекта:
- **Sonah:** `Sonah/Core/Atoms/ActionSlots.lua:21–34` сканирует `C_ActionBar.HasAction` (fallback `HasAction`) и `GetActionInfo`; `Sonah/UI/ActionBars.lua:359–392,400–470,503–544,582–587` находит Blizzard, BT4Button, DominosActionButton, ElvUI_Bar и LibActionButton, проверяет атрибуты и страницы.
- **MaxDps:** `MaxDps/Buttons.lua:348–395,493–529,565–650,765–795` ищет реальные кнопки, action-slot и дополнительные интерфейсы; его крупную систему подсветок и сторонние библиотеки не переносим.
- **JustAC:** `JustAC/ActionBarScanner.lua:227–257,429–439,1006–1027` получает сопоставление библиотечных кнопок и кэширует slot. Используем принцип кэша, но не макро-парсер.
- **ForeverRotation:** `ForeverRotation/Bars.lua:1–48` рассматривает основные префиксы и `GetAttribute("action")`; используем только подтверждаемые слоты.
- **ForeverAuras / RotationGuide:** сравнительная матрица `API_REFERENCE_MATRIX.md`; совместимые API чтения при отсутствии отдельного надёжного универсального сканера.

Из референсов взяты идеи и контракты, не исходный код. Положения о совместимости с Wow Forever — гипотезы до игрового теста.

## Реализация

`Core/ActionBarScanner.lua` предоставляет `Initialize()`, `Invalidate(reason)`, `ReadNow()`, `GetSnapshot()`, `FindSpell(spellID)`. Модуль не управляет кнопками, не выполняет макросы и не предоставляет автоматического каста.

Обнаружение без обязательных библиотек: штатные Blizzard `ActionButton`, `MultiBar*`; `BT4Button1..180`, `DominosActionButton1..180`, отдельные `MultiBar*ActionButton`, `ElvUI_Bar1..15Button1..12`; при уже загруженном `LibStub` — `GetAllButtons()` пяти известных вариантов LibActionButton. Не найденная библиотека не загружается. Границы обхода 180 игровых слотов и 1200 кандидатных кнопок.

**Фактическое действие:** кнопка должна быть видимой по `IsVisible()`; её slot берётся из защищённо прочитанного `GetAttribute("action")`, затем `GetPagedID()`, затем `GetAction()` при результате `("action", slot)`, затем `button.action`. Индекс по имени или просто `button.id` НЕ считается подтверждением. Отрицательный/нулевой/вне 1..180 slot отвергается. Для полученного slot требуется `C_ActionBar.HasAction` с fallback `HasAction`, затем `GetActionInfo(slot)` с типом spell и числовым Spell ID. Только подтверждённые пары входят в записи; macro/item/pet/flyout/direct spell без игрового слота исключаются.

**Безопасность:** метод `GameAPI:IsSafeValue` повторно использует проверки `issecretvalue`, `issecrettable`, `canaccessvalue`; вызовы полей/методов кнопки защищены `pcall`. Никакого `SetAttribute`, hook, `UseAction`, `CastSpell`, RGB и добавления LibActionButton в сборку.

**Актуальность:** `EventBus` помечает `actionbar` при paging, stealth, override, modifier, entering world и ADDON_LOADED. `GetSnapshot` пересчитывается по событию/ревизии или через 0,6 секунды. `FindSpell` перед выдачей повторно проверяет видимость, слот и текущий spell ID, даже если cache ещё действителен; stale запись становится UNKNOWN. Неизвестное отсутствие способности не классифицируется как доказанное `ABSENT`, поскольку полнота обхода сторонних кнопок не подтверждена.

`GetSnapshot().status=READY` означает наличие хотя бы одной подтверждённой видимой spell-кнопки, **не** полноту всех панелей. Поле `coverage=CONFIRMED_BUTTONS_ONLY` предотвращает ошибочную трактовку списка как полного. `FindSpell` не проверяет изученность, cooldown, дальность или бинды: это требования следующих 2.6 и 2.7. Несколько кнопок для одного Spell ID обрабатываются детерминированно (минимальный slot), но позже может понадобиться приоритет по действительному бинду.

## Проверки, влияние на размер и остаточные риски

- `tests/stage_02_05_actionbar.lua`: mock-кейсы для каждой поддержанной системы, LibActionButton, скрытых/прямых кнопок, предметов/макросов, paging без события, таймера, read-only fail-closed.
- **Нужно проверить в игре:** какая именно версия Forever предоставляет `GetAttribute("action")`/`GetPagedID`/LibActionButton API и допустимую нумерацию слотов; скрытые страницы, бар 5–8, формы/стойки, 180-slot границу, видимость в бою и реальный modifier paging. Отсутствие соответствия означает UNKNOWN, а не опасное угадывание.
- **Потребление CPU/RAM/FPS:** ещё не измерялось в реальном клиенте. Во избежание нагрузки нет полного скана каждый кадр, но поиск кандидатов и повторная валидация имеют стоимость. События могут быть неприменимы для отдельных билдов — их регистрация уже защищена проверкой валидности.
- **Процесс:** статические и Lua-тесты описываются в CHANGELOG фактически. Ни игровой runtime, ни поддержка любой конкретной версии стороннего аддона пока не подтверждены.

**Следующий пункт 2.6:** реальные бинды и надписи; сначала сравнение минимум Sonah и MaxDps, отдельное согласование по правилу № 1.

## Корректировка после выполнения Lua-тестов

Отдельным исправляющим коммитом уточнены два случая: (1) ошибка или protected результат `GetAttribute("action")`/`GetPagedID()` останавливает анализ кнопки, а не позволяет подхватить потенциально устаревшее `button.action`; (2) для LibActionButton допускается только `GetAction() -> ("action", подтверждённый slot)`, но не прямое `("spell", id)` и не макросы.

**Выполненный тест:** `texlua tests/stage_02_05_actionbar.lua` на локальной копии *точно того же* `ActionBarScanner.lua` и тестового файла (Git blob SHA совпали с GitHub), с локальными mock-реализациями `GameAPI` и `EventBus` вместо настоящих модулей. Результат: `PASS stage 2.5 mocked action bar scenarios`. Тестируются Blender/BT4/Dominos/ElvUI/LAB, скрытые кнопки, page change, secret, GetAction fallback, предметы и макросы. Это **не является** подтверждением полного набора реальных GameAPI/EventBus и не заменяет WoW Forever.

## Расширение 2.5a — EllesmereUI

В отдельном согласованном подэтапе добавлен префикс `EABButton` для индексов `1..180`, в той же структуре поиска, что BT4/Dominos. Исходный код EllesmereUI `EllesmereUIActionBars/EUI_ActionBars_Secure.lua` создаёт `EABButton` по игровому слоту, `EUI_ActionBars_Bars.lua` записывает `GetAttribute("action")`, а `EUI_ActionBars_Paging.lua` обновляет атрибут при смене страницы. Это основание для повторного использования существующего `inspect`, но не доказательство работы всех версий в WoW Forever.

Полная методика и QA: [STAGE_02_05A_ELLESMERE.md](STAGE_02_05A_ELLESMERE.md). Кольца OPie не сканируются и не считаются подтверждёнными слотами.
