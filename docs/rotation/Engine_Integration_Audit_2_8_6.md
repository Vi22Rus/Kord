# 2.8.6 — аудит интеграции канонического ядра (2026-11-21)

**Статус:** SOURCE REVIEWED / IMPLEMENTATION IN PROGRESS / LOCAL RUN NOT RUN / CI NOT RUN / IN-GAME NOT RUN.
**Утверждение:** пользователь явно одобрил 2.8.6a–e. Основа: `docs/rotation/Canonical_API_Matrix.md` v14 (101 пункт; client PASS 0/101) и `docs/BUILD_VARIANTS_AND_DIAGNOSTICS.md`. Новый GitHub Actions до общего QA запрещён решением KR-20261121-033.

## Проверенные референсы и разграничения

- **Sonah.zip**, `Sonah/Core/Organisms/Engine.lua`: `BuildContext` (~490), `Engine:Update` (~1022), контекст на вычисление и обновление вывода. В Kord не переносить движок и прогноз нескольких действий.
- **MaxDps.zip**, `MaxDps/Core.lua`: `InvokeNextSpell` (~749), таймер и разделение выбора и отображения. Не добавлять Ace зависимости или автоматический режим.
- **JustAC.zip**, `JustAC/RotationImport.lua` и `JustAC/BlizzardAPI/CooldownTracking.lua`: отделение декларации ротации от проверки игровых условий; не использовать недоказанную семантику cooldown.
- **ForeverAuras.zip**, `ForeverAuras/SpellCooldown.lua`: `InvalidateSpellCooldownCache` (~113) и guarded cooldown reads; не копировать инфраструктуру аур.
- **ForeverRotation.zip**, `ForeverRotation/Engine.lua`, `ForeverRotation/Display.lua`: последовательный выбор и UI; не копировать чужие приоритеты.
- **RotationGuide.zip**, `RotationGuide/Core/Engine.lua` `Engine.Next` (~86) и `Core/Display.lua` `Display.Refresh` (~225): граница правил/визуализации; не отображать непроверенное.
- Вывод — проверять инварианты между **имеющимися модулями Kord**, а не внедрять внешний runtime-адаптер. Лицензии сторонних аддонов запрещают предполагать свободное копирование; код не копируется.

## Каноническая цепь и потребители

| Шаг | Исполняемый модуль | Результат/инвариант | Риск/регрессия |
|---|---|---|---|
| API | `Core/GameAPI.lua` | `READY/UNKNOWN/UNAVAILABLE/ERROR`, secret before comparison | защищённое значение не преобразовать в boolean |
| Состояние | `Core/GameState.lua` | один `GetSnapshot` на Engine Evaluate | неверная/устаревшая структура, ревизии |
| Правила | `Core/RotationProfiles.lua` + Settings | `verified`, локально проверенные категории/политики | регистрация и смена identity без fallback |
| Eligibility | `Core/AbilityEligibility.lua` | `READY/BLOCKED/UNKNOWN`, SpellID exact, protected guard | GCD/range/charges не угадывать |
| Выбор | `Core/RotationEngine.lua` | единственный элемент; UNKNOWN старшего = стоп | повреждённые catalog/requirement/eligibility ответы |
| Клавиша | `Core/BindingResolver.lua` | только подтверждённый spellID + key | отсутствие/смена бинда = пустая метка |
| События | `Core/EventBus.lua` | revisions + coalescing, bounded | ошибка подписчика, подписка/смена профиля |
| UI | `UI/RotationDisplay.lua` / `UI/SpellIcon.lua` | production != test; blank on UNKNOWN/BLOCKED | stale icon после смены состояния |

## Ограничения до DevTools

1. **2.8.6b:** интеграционный mock должен проверять последовательность нескольких вызовов, влияние изменений `GameState`, identity, profile opt-in, BindingResolver и event revisions. Без реальных API вызовов.
2. **2.8.6c:** все ошибки/secret и несовпадения неизвестны, а не READY; event/UI не выполняют тяжёлого опроса без профиля. Сначала исходниковая фиксация и тест, затем минимальный код.
3. **2.8.6d:** observer API — только pull/read-only, без callbacks записи, SavedVariables, логов и сырого GUID/тайминга. Только контролируемые reason/status и счётчики; не копировать `diagnostics` с ID.
4. **2.8.6e:** проверка загрузочного порядка .toc, кодовых контрактов, шести локалей и тест-плана. Локальные проверки отдельно от CI. `CI NOT RUN` до единого запуска непосредственно перед общим игровым QA.
5. **Не менять** BM Hunter priorities, ранги, source-baseline v14, пользовательское UI и двухаддонную структуру. Проверка highest learned spell rank v14 #20 и WoW Forever остаются NOT RUN.

## Критерий завершения

Подпункты a–e должны быть опубликованы раздельно с CHANGELOG; локальные проверки отмечены по фактическому запуску. Даже при завершении исходников `2.8.6 = IMPLEMENTED / AWAITING COMBINED CI AND IN-GAME QA` — не DONE.
