# Этап 2.8 — RotationProfiles, RotationEngine и UI

**Дата:** 2026-11-21. **Версия:** 0.1.8.3-rc9. **Статус:** IMPLEMENTED / AWAITING IN-GAME QA.

## Источники и согласование

По правилу № 1 исследованы **локальные ZIP Sonah, MaxDps, JustAC, ForeverRotation, RotationGuide, ForeverAuras**. Основные исходники: `Sonah/Core/Organisms/Engine.lua`, `Sonah/Core/Organisms/CustomRotation.lua`, `MaxDps/Core.lua`, `JustAC/Data/SimcRotations.lua`, `JustAC/RotationImport.lua`, `ForeverRotation/Engine.lua`, `RotationGuide/Core/Engine.lua`. Выбран независимый по классу упорядоченный список правил, как Sonah/JustAC/RotationGuide, с ограниченным количеством вызовов и без переноса сторонних библиотек. Архитектура прямо одобрена заказчиком до изменения GitHub.

## Алгоритм

- `Core/RotationProfiles.lua`: **нет ни одного зарегистрированного профиля** в игровом пакете. Будущие классовые файлы должны вызвать `Register(classToken, specIndex, {verified=true,single={...},aoe={...}})` и передать массивы не более 64 валидных правил с целочисленным Spell ID, известной категорией и явными `target=enemy|friendly|self|none`, `cast=idle|allow`, `chargesRequired=boolean`. Невалидные/дублирующие регистрации отвергаются; `Get` отдаёт копию, а не внутреннюю таблицу. `verified=true` является декларацией автора профиля, **не** результатом игрового теста.
- `Core/RotationEngine.lua`: в `Evaluate()` сначала подтверждается идентификатор специализации и наличие профиля, затем `RotationSettings:GetProfile(false)` и явное включение `enabled=true`. В режиме `auto` неизвестное число противников => UNKNOWN (без угадывания ST/AoE). Выбор только `single`/ `aoe`, по порядку правил; учитываются категории и пользовательские исключения, затем `AbilityEligibility:Evaluate`. Для STATUS BLOCKED идёт к следующему, но для UNKNOWN **останавливает выбор** и возвращает пустую очередь. При READY требуется проверенная name/texture из `SpellCatalogue`; клавиша только из `BindingResolver` (UNKNOWN => подпись пустая). Возвращается одна текущая рекомендация и короткая диагностика проверенных правил. **Вторая и последующие иконки не являются достоверными будущими заклинаниями** до прогноза GCD/ресурсов.
- `UI/RotationDisplay.lua`: testMode остаётся отдельной демонстрацией. В обычном режиме на панели выводится **только** verified_profile recommendation, если весь список условий пройден; прочие слоты очищаются и скрываются; без действительного профиля и результата панель скрыта. События интерфейса выполняют Refresh, а ограниченный таймер 0,4с проверяет только включённый зарегистрированный профиль. Настройки отображения, размеры и шесть локализаций не меняются. Прямые клики/автокаст не добавлены.
- `.toc`, `Init.lua`: порядок `GameAPI → SpellCatalogue/GameState/ActionBarScanner/BindingResolver/AbilityEligibility → RotationProfiles → RotationEngine → UI`, версия rc9. Регистру профилей и движку не нужна фоновая инициализация.

## Проверки

- **PASS (реально выполнено):** `texlua tests/stage_02_08_rotation_engine.lua` — **29 утверждений** на байт-в-байт совпадающих с опубликованными blob исходниках `RotationProfiles.lua`, `RotationEngine.lua` и тесте. SHA проверены перед коммитом. `texluac -p` для трёх файлов — PASS.
- Покрытие mock: пустой реестр, неверная декларация, неверная политика, замена таблицы, дубли, explicit opt-in, неустановленный auto, ST/AoE, первый BLOCKED, приоритетный UNKNOWN, фильтр категорий/способностей, отсутствие реального бинда, отсутствие проверенной текстуры, чужая специализация, отсутствие подходящих заклинаний, пустая очередь.
- **Не выполнено:** изолированный запуск реального `RotationDisplay.lua` c WoW UI моками, полная интеграция с настоящим `GameAPI`/`SpellCatalogue`/`AbilityEligibility` и игровая проверка, измерение FPS/RAM. UI подтверждён статически, а не в игре.
- В `tests/stage_02_08_rotation_engine.lua` отсутствует боевой классовый профиль: WARRIOR mock создаётся **только тестом**, в рабочую игру он не загружается.

## Остаточные ограничения

Уже имеющийся `AbilityEligibility` может возвращать UNKNOWN, если Forever API секретен или контракт не подтверждён; этот этап не пытается обходить защиту. Режим auto пока не выбирает наугад одну цель; для будущей игры потребуется достоверное определение AoE. UI отображает одну текущую рекомендацию, но не прогнозирует вторую. `RotationSettings.keyLabel` не считается автоматически определённой клавишей. OPie не интегрируется. Первый профиль «Воин — Оружие» остаётся задачей этапа 3, по предварительному исследованию и одобрению.

## 2.8.4a–d — каноническая оценка GameData (2026-11-21)
**Статус:** IMPLEMENTED / MOCK CI PASS / AWAITING IN-GAME QA. Утверждено заказчиком до изменения исходников. Коммиты KR-20261121-028..031; итоговый CI [44888049693](https://github.com/Vi22Rus/Kord/actions/runs/44888049693), SHA `28104bbb9920fdba46170426e8c6eb621a243b17`, completed/success.

- **a:** `RotationEngine` получает один `GameState:GetSnapshot()` через pcall на проход, после выбора режима. Поле `status` снимка не обязано быть глобально READY. Отсутствие структуры → UNKNOWN. `AbilityEligibility` принимает опциональный `stateSnapshot`, прямые вызовы без него сохраняются. Оценка требования цели использует этот же снимок.
- **b:** `RotationProfiles` валидирует и копирует необязательные `requires={{field="context.inGroup",equals=false}}` (до 8 уникальных проверок). Разрешены только `player.moving`, `target.isPlayer`, `pet.exists`, `pet.dead`, `context.inGroup`, `context.inRaid`, `context.inInstance`. Фактические GameData-сигналы статуса READY и обычного boolean сравниваются; отсутствие/Secret/не-boolean → UNKNOWN, явное несовпадение → BLOCKED. Проверка не объявляет кандидатные поля реализованными.
- **c:** недействительный ответ Eligibility, неожиданный статус или несовпадение `spellID` → UNKNOWN, а не пропуск следующего правила.
- **d:** добавлен интеграционный mock реальных модулей `RotationProfiles + RotationEngine + AbilityEligibility`, подключён девятым Lua suite к Actions. По итоговому логу 9/9 PASS: Eligibility 57 checks; RotationEngine 38 assertions; GameState v14 31; guards 26; integration 28 assertions. `luac5.1 -p` PASS.
- **Границы:** классные профили по-прежнему не активированы; Hunter priorities, ранги, v14 API, механизм двух аддонов и UI не менялись. Максимальный изученный ранг v14 #20, все 101 клиентских проверки, FPS/RAM и настоящая игра — **NOT RUN**. CI не доказывает клиентский API.

