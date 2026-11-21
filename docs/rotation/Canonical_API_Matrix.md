# Kord Rotation — матрица потребностей профилей и выбора API (reference-first)

**Версия:** v3, 2026-11-21. **Статус:** инвентаризация / сравнительный аудит в процессе. **Не является утверждением работоспособности в игровом клиенте.** Существующий Kord не является источником выбора методов.

## Принцип заполнения

**Первый столбец — конкретная потребность профиля.** Каждая операция (наличие баффа, длительность баффа, здоровье цели, дальность применения, GCD и т.д.) — отдельная строка. Далее идут конкретный метод и **все шесть референсов**; последний столбец — выбор для будущего Kord. `—` означает **в текущем проходе не зафиксировано доказательство**, а не отсутствие функциональности. `(audit)` означает **файл-кандидат, точный вызов и строка ещё не проверены**; такой пример не может быть основанием для окончательного выбора. Только записи с конкретным местом исходника являются проверяемым статическим свидетельством. Проверка работоспособности в Forever требует отдельного теста в клиенте.

Источники: архивы `Sonah.zip`, `MaxDps.zip`, `JustAC.zip`, `ForeverAuras.zip`, `ForeverRotation.zip`, `RotationGuide.zip`. Для MaxDps анализировать прежде всего `Specialization/Forever/`, не смешивать с Classic/Cata/Retail. Изучать **профили всех классов**, а не только Hunter; дополнять матрицу по мере обнаружения новых потребностей. Статический проход по исходникам выявил следующие подтверждаемые местоположения, а непроверенные направления помечены.

## Реестр потребностей и решений (39 отдельных строк)

| Потребность профиля (одна задача на строку) | API/алгоритм | Sonah | MaxDps Forever | JustAC | ForeverAuras | ForeverRotation | RotationGuide | Предварительное решение Kord |
|---|---|---|---|---|---|---|---|---|---|
| Цель существует | UnitExists | Sonah/Core/Atoms/Units.lua:46 | — | JustAC/BlizzardAPI/StateHelpers.lua:25 | — | ForeverRotation/CC.lua:43 | RotationGuide/Core/State.lua:301 | UnitExists via guarded unit reader; pending client |
| Цель враждебна | UnitCanAttack | Sonah/Core/Atoms/Units.lua:60 | — | JustAC/BlizzardAPI/StateHelpers.lua:26 | — | ForeverRotation/CC.lua:43 | RotationGuide/Core/State.lua:285 | UnitCanAttack; pending client |
| Здоровье цели | UnitHealth / UnitHealthMax | Sonah/Core/Atoms/Units.lua:569 | — | JustAC/BlizzardAPI/StateHelpers.lua:23 | — | — | — | Guarded health pair; pending client |
| Здоровье игрока | UnitHealth / UnitHealthMax | Sonah/Core/Atoms/Units.lua:569 | — | JustAC/BlizzardAPI/StateHelpers.lua:23 | — | — | — | Same unit reader; pending client |
| Здоровье питомца | UnitHealth / UnitHealthMax | Sonah/Core/Atoms/Units.lua:569 | — | JustAC/BlizzardAPI/StateHelpers.lua:23 | — | — | — | Candidate same unit reader; pet case unverified |
| Мана / ресурс | UnitPower | Sonah/Core/Atoms/Units.lua:326 | — | JustAC/BlizzardAPI/StateHelpers.lua:2155 | — | ForeverRotation/Engine.lua:84 | RotationGuide/Core/State.lua:234 | Separate mana from active power type; pending client |
| Уровень игрока | UnitLevel | Sonah/Core/Atoms/Units.lua:158 | — | JustAC/BlizzardAPI/StateHelpers.lua:1597 | — | ForeverRotation/Engine.lua:393 | RotationGuide/Core/State.lua:309 | Centralized unit reader; pending client |
| Класс игрока | UnitClass | Sonah/Core/Atoms/Units.lua:80 | — | JustAC/BlizzardAPI/StateHelpers.lua:2359 | — | ForeverRotation/Core.lua:181 | RotationGuide/Core/API.lua:45 | Class token; pending client |
| Игрок движется | IsPlayerMoving | — | — | JustAC/DebugCommands.lua:8826 (debug only) | — | ForeverRotation/Engine.lua:56 | — | Guarded candidate, no false on error |
| Дистанция применения способности | IsSpellInRange | Sonah/Core/Atoms/Spells.lua:445 | — | JustAC/BlizzardAPI/StateHelpers.lua:397 | — | ForeverRotation/Engine.lua:3 | RotationGuide/Core/State.lua:248 | Spell-specific boolean; not meters |
| Кулдаун способности | GetSpellCooldown / C_Spell | Sonah/Core/Atoms/Spells.lua:289 | — | JustAC/BlizzardAPI/CooldownTracking.lua:15 | — | ForeverRotation/Display.lua:302 | RotationGuide/Core/State.lua:101 | SpellID cooldown + guarded return; pending client |
| Баффы игрока | Aura reader | Sonah/Core/Atoms/Auras.lua:743 | — | JustAC/BlizzardAPI/SecretValues.lua:239 | ForeverAuras/API.lua (review required) | ForeverRotation/Rotations/Buffs.lua (review required) | — | Prefer aura scan with secret handling; exact API TBD |
| Дебаффы цели | Aura reader | Sonah/Core/Atoms/Auras.lua:743 | — | JustAC/BlizzardAPI/SecretValues.lua:239 | ForeverAuras/API.lua (review required) | — | — | Same aura reader, unit-specific; exact API TBD |
| Агро / угроза | UnitThreatSituation | Sonah/Core/Atoms/Units.lua:1318 | — | JustAC/BlizzardAPI/StateHelpers.lua:81 | — | — | — | Threat is not equivalent to hasAggro; unresolved |
| Каст противника | UnitCastingInfo | Sonah/Core/Atoms/Casts.lua:26 | — | JustAC/BlizzardAPI/StateHelpers.lua:129 | — | ForeverRotation/Engine.lua:170 | — | Casting reader; interruptability separate |
| Число врагов | Nameplate enumeration | — | — | JustAC/BlizzardAPI/StateHelpers.lua:82–108 | — | — | — | Observed engaged nameplates only; not exact total |
| Группа / рейд | GetNumGroupMembers | Sonah/Core/Atoms/Units.lua:1214 | — | JustAC/DebugCommands.lua:5474 (debug only) | — | — | — | Candidate, not equivalent to dungeon/raid |
| Подземелье / рейд | Instance context | — | — | JustAC/DebugCommands.lua:284 (debug only) | — | — | — | Unresolved; no confirmed runtime provider |
| Изученность заклинания | Spellbook scan | Sonah/Core/Atoms/Spells.lua:68–96 | — | JustAC/BlizzardAPI/SpellQuery.lua:69–93 | — | — | RotationGuide/Core/State.lua:24–67 | Sonah rank resolver candidate |
| Ранг заклинания | Highest learned rank | Sonah/Core/Atoms/Spells.lua:139–246 | — | JustAC/BlizzardAPI/SpellQuery.lua:69–93 | — | — | RotationGuide/Core/State.lua:24–67 | Central ability-to-rank resolver |
| Доступность / стоимость | Usability query | Sonah/Core/Atoms/Spells.lua (audit) | — | JustAC/BlizzardAPI/SpellQuery.lua (audit) | — | ForeverRotation/Engine.lua (audit) | RotationGuide/Core/State.lua:79–109 | Keep distinct from cooldown/range |
| Прерывание | Enemy cast + interrupt spell | Sonah/Core/Atoms/Casts.lua:26 | — | JustAC/BlizzardAPI/StateHelpers.lua:129 | — | ForeverRotation/Rotations/Interrupts.lua (audit) | — | Requires cast/interruptible/ready separately |
| Контроль / CC | Aura and unit state | Sonah/Core/Atoms/Auras.lua (audit) | — | JustAC/BlizzardAPI/StateHelpers.lua (audit) | — | ForeverRotation/CC.lua (audit) | — | Unresolved CC-safe AoE |
| Автовыстрел / автоатака | Attack state | — | — | — | — | ForeverRotation/Rotations/Hunter.lua (audit) | — | Unresolved |
| GCD | Global cooldown | Sonah/Core/Atoms/Spells.lua (audit) | — | JustAC/BlizzardAPI/CooldownTracking.lua (audit) | — | ForeverRotation/Engine.lua (audit) | RotationGuide/Core/State.lua (audit) | Must distinguish spell cooldown |
| Заряды способности | Charges query | Sonah/Core/Atoms/Spells.lua (audit) | — | JustAC/BlizzardAPI/SpellQuery.lua (audit) | — | — | — | Unresolved exact return |
| Остаток баффа | Aura expiration | Sonah/Core/Atoms/Auras.lua (audit) | — | JustAC/BlizzardAPI/SecretValues.lua (audit) | ForeverAuras/API.lua (audit) | — | — | Expiration and current time; pending |
| Остаток дебаффа | Aura expiration | Sonah/Core/Atoms/Auras.lua (audit) | — | JustAC/BlizzardAPI/SecretValues.lua (audit) | ForeverAuras/API.lua (audit) | — | — | Same aura model |
| Таланты / специализация | Talent reader | Sonah/Core/Atoms/Talents.lua:535 | — | — | — | — | — | Unresolved spec contract |
| Питомец атакует цель | Pet target state | Sonah/Core/Atoms/Units.lua (audit) | — | — | — | ForeverRotation/Rotations/Hunter.lua (audit) | — | Unresolved |
| Время до смерти цели | TTD estimator | — | — | — | — | — | — | Unresolved |
| Доступность action bar | Action bar inspection | — | — | JustAC/ActionBarScanner.lua (audit) | — | — | — | Separate from ability readiness |
| Привязка клавиши | Binding inspection | — | — | JustAC/ActionBarScanner.lua (audit) | — | — | — | Unresolved exact mapping |
| Изменение формы / стойки | Form/stance state | Sonah/Classes/Druid.lua (audit) | — | — | — | ForeverRotation/Rotations/Druid.lua (audit) | — | Unresolved |
| Условия лечения / диспела | Friendly target + aura | Sonah/Classes/Priest.lua (audit) | — | — | ForeverAuras/API.lua (audit) | ForeverRotation/Rotations/Priest.lua (audit) | — | Unresolved |
| Тринкеты / расовые / предметы | Usable action | Sonah/Classes/Racials.lua (audit) | — | — | — | — | — | Unresolved |
| Опасный входящий урон | Threat/health/encounter | — | — | — | — | — | — | Unresolved; no guess |
| PvP / игрок-цель | Unit player test | Sonah/Core/Atoms/Units.lua (audit) | — | JustAC/BlizzardAPI/StateHelpers.lua (audit) | — | — | — | Unresolved |
| Воскрешение / смерть | Unit death | Sonah/Core/Atoms/Units.lua (audit) | — | JustAC/BlizzardAPI/StateHelpers.lua (audit) | — | — | — | Unresolved |

## Следующий обязательный проход

1. Для каждой строки проверить **каждый** из шести референсов, включая профили и вспомогательные API-обёртки; заменить `—` и `(audit)` на точные места либо документированное отсутствие после полного поиска.
2. Для каждого найденного метода записать точную сигнатуру, возвращаемые значения, доступность в Forever, защиту secret values, cache/refresh, поведение при ошибке.
3. Сравнить альтернативы по точности, безопасности, покрытию потребности, ограничениям и частоте обновления; лишь после этого зафиксировать окончательный выбор Kord.
4. Выполнить проверки на актуальном Forever-клиенте; отдельные статусы SOURCE VERIFIED / CLIENT PASS / CLIENT FAIL / NOT RUN.
5. Только после завершения матрицы планировать замену движка. **Никакой метод не сохраняется исключительно потому, что он уже реализован в Kord.**
