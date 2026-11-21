# Stage 2.7 — AbilityEligibility (0.1.8.3-rc8)

**Статус:** IMPLEMENTED / AWAITING IN-GAME QA. Решение утверждено пользователем перед кодированием.

## Исследование источников по правилу №1
- Sonah.zip, `Sonah/Core/Atoms/Spells.lua:289–309,345–353,408–417,594–599,804–808`: защищённые cooldown-поля; различение `isActive`, `isOnGCD`, read-only проверки применимости/дальности/зарядов.
- MaxDps.zip, `MaxDps/Cooldowns.lua` и `MaxDps/SpellData.lua`: разделение кулдаунов, способностей и ресурсов. Полноценный движок MaxDps не копируется.
- JustAC.zip, `JustAC/BlizzardAPI/SpellQuery.lua:478–535`, `JustAC/BlizzardAPI/CooldownTracking.lua:573–607,699–708`: явная диагностика cooldown/GCD и secret, не использовать fail-open.
- ForeverAuras.zip, `ForeverAuras/CooldownViewerCatalog.lua`; ForeverRotation.zip, `ForeverRotation/Engine.lua`; RotationGuide.zip, `RotationGuide/Core/State.lua`: дополнительные идеи кэша/простых проверок, не копируются, приоритет fail-closed.

## Реализовано
- `Core/AbilityEligibility.lua` — `Initialize()`, `Invalidate(reason)`, `Evaluate(spellID, options)`; только рекомендационный read-only gate, не приоритеты и не применение.
- Кандидат должен быть подтверждён каталогом (`SpellCatalogue:Read().status=ready`) и иметь актуальную видимую кнопку (`ActionBarScanner:FindSpell().status=READY`). Неподтверждённый слот → UNKNOWN, подтверждённо неизученная способность → BLOCKED.
- Проверка игрока (наличие и жизнь), занятости кастом/каналом, `IsUsableSpell`/modern `C_Spell.IsSpellUsable` с `noPower`, зарядов по выбранной политике, индивидуального кулдауна, GCD spell 61304, отношения к цели и `IsSpellInRange`/modern аналог. Modern секретные `startTime/duration` не читаются: используются `isActive/isOnGCD` с безопасной проверкой; если невозможно отделить индивидуальный cooldown от GCD — UNKNOWN. Legacy: только подтверждённые числовые start/duration + GetTime.
- Опции **обязательны**: `target=` `enemy|friendly|self|none`, `cast=` `idle|allow`, `chargesRequired=` `true|false`. Это явные свойства конкретного заклинания, которые будут задаваться профилем. Никаких предположений о целях баффов, лекарей и off-GCD заклинаний. Отсутствие политики → UNKNOWN.
- `READY` только при достаточных подтверждениях; `BLOCKED` при доказанном препятствии; `UNKNOWN` при отсутствии обязательных данных или protected API. Если одновременно встречаются UNKNOWN и определённый BLOCKED, приоритет BLOCKED. Результат содержит `status`, `reason`, `spellID`, `source`, для READY также `slot`, `target`.
- `GameAPI.lua`: расширен **только read-only** allowlist: modern usable/range/charges и legacy GetSpellCharges. `EventBus.lua`: каналы `cooldowns` (обновление spell cooldown/charges/usability) и дополнения к cast-инвалидации, с уже существующей проверкой `C_EventUtils.IsEventValid`. Нет постоянного cache READY и нет отдельного OnUpdate, чтобы не выдавать stale readiness.
- `Init.lua` и `KordRotation.toc`: подключение после SpellCatalogue, GameState, ActionBarScanner, BindingResolver.
- `tests/stage_02_07_eligibility.lua`: 23 автономные mock-проверки включая modern/legacy, GCD, ресурс, target, cast, security и несоответствие политики.

## Проведённые проверки
- **PASS**: `texlua tests/stage_02_07_eligibility.lua` в `/mnt/data/kord27` — 23 проверки, на точном опубликованном содержимом `AbilityEligibility.lua` и тестового файла (SHA Git blob совпали до публикации). `GameAPI`, `SpellCatalogue`, `GameState`, `ActionBarScanner`, `EventBus` в тесте представлены mock-объектами.
- **NOT RUN**: полноценная интеграция с настоящими модулями, runtime WoW Forever, измерение CPU/RAM/FPS, все 27 профилей.
- **Риск**: `C_Spell.GetSpellCooldown` и range возвращают разные типы/секретность в разных клиентах; наш conservative UNKNOWN может уменьшать число рекомендуемых заклинаний, пока конкретная версия не подтверждена.
- **Важно**: компонент подготовлен как API ядра; не подключён непосредственно к визуальной выдаче ротаций. Нельзя утверждать, что 27 профилей уже работают.

## Следующий шаг
Классовые политики и настоящая интеграция движка приоритетов — следующие этапы, только после отдельного сравнения референсов и одобрения по правилу №1.
