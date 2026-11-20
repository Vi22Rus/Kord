# Этап 2.4a — исправления после аудита Sonah и MaxDps

**Дата:** 2026-11-20. **Версия:** 0.1.8.3-rc4. **Основа:** [STAGE_02_04_SELF_AUDIT.md](STAGE_02_04_SELF_AUDIT.md); решение пользователя одобрено перед кодированием по правилу № 1 из AGENTS.md.

## Сверка первоисточников и выбор

- **Sonah.zip**, `Sonah/Core/Atoms/Secret.lua:12–35,125–146`: проверки `issecretvalue`, `issecrettable`, `canaccessvalue` и безопасное обращение к полям. Использована общая идея, без копирования лицензированного кода и без отдельного большого модуля.
- **Sonah.zip**, `Sonah/Core/Atoms/Spells.lua:33–36,74–90`: явные типы Spell и FutureSpell. Kord принимает Spell; FutureSpell/Flyout пропускаются только если соответствующие enum известны, любой другой тип прекращает сканирование.
- **MaxDps.zip**, `MaxDps/SecretHelper.lua:17–46`: отдельный modern-обход книги; не копировались дополнительные кэши/библиотеки.
- **MaxDps.zip**, `MaxDps/Core.lua:376–395`: разрешение `LEARNED_SPELL_IN_TAB`/ `LEARNED_SPELL_IN_SKILL_LINE` через `C_EventUtils.IsEventValid` и узко направленная регистрация событий; реализация Kord компактная.

## Реализованные изменения

1. `Core/GameAPI.lua`: централизованный `secret(value)` с защищёнными проверками `issecretvalue`, `issecrettable`, `canaccessvalue`; `ReadField(record,key,expectedType?)` возвращает статус READY/UNKNOWN/UNAVAILABLE/ERROR и не отдаёт поле при secret или исключении индексирования. Защита не обходит ограничения WoW.
2. `Core/SpellCatalogue.lua`: `safeField` использует `GameAPI:ReadField`; unknown modern itemType вызывает ошибку сканирования с пустым entries; только известные Enum.FutureSpell/Flyout можно игнорировать; ноль вкладок/секций/прочитанных заклинаний не превращается без проверки в `ready/empty`; legacy пробует modern fallback. Более консервативный результат `unavailable` допустим.
3. `Core/EventBus.lua`: `C_EventUtils.IsEventValid` используется если существует; исключения и false запрещают регистрацию отдельного события, результат отражается в `Status().unregistered`. Добавлены `LEARNED_SPELL_IN_SKILL_LINE`, `PLAYER_SPECIALIZATION_CHANGED`, `CHARACTER_POINTS_CHANGED` к соответствующим каналам.
4. `tests/stage_02_04_spell_catalogue.lua`: новые mock-сценарии secret table/field, unknown itemType, пустая legacy/modern книга, фильтр недопустимого события.

Старые поля `Read().entries` (`id`, `name`, `texture`) и UI редактора не изменены. Режим автоматического применения заклинаний отсутствует.

## Проверки и границы

- **PASS:** 8 целевых Lua-утверждений на `texlua` в локальном воспроизводящем сценарии (`verify_24a.lua`); это *не* запуск полной копии исходников с GitHub. Статический анализ опубликованного дерева (TOC, версии, обработчики) зафиксировать после коммита.
- **NOT RUN:** полный `tests/stage_02_04_spell_catalogue.lua` на актуальном репозитории, синтаксис всех Lua-модулей реальной сборки, WoW Forever, реальные secret tables и события клиента.
- **Риск:** наличие и смысл API/enums варьируются по сборкам; сверхконсервативный результат `unavailable` требует диагностики при итоговой игровой приёмке. Простое наличие `issecretvalue` и `issecrettable` не подтверждает отсутствие будущих защитных режимов. Точное CPU/RAM не профилировалось.
- **Осталось на 2.5/2.7:** фактическая панель Blizzard и проверка способности/ранга; известные вне книги способности нельзя автоматически рекомендовать.

## Следующее действие

В соответствии с правилом № 1 **перед реализацией 2.5** представить заказчику отдельное сравнение Sonah + MaxDps (+ остальные доступные), обоснование подхода и дождаться одобрения.
