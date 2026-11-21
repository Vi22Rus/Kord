# Kord Rotation — единая матрица потребностей профилей и выбора API

**Версия v4 · 2026-11-21 · Reference-first · СТАТУС: НЕ ЗАВЕРШЕНО.** Существующий движок Kord не является эталоном и не используется для выбора API. Все источники — шесть предоставленных архивов. **Один реестр вместо трёх разрозненных таблиц.**

## Как читать

Каждая строка — самостоятельная потребность профиля или отдельная операция получения данных. Колонки референсов показывают **имеющиеся в предыдущем аудите указания на исходники**, а не гарантированно работающие методы. `—` = нет зафиксированного доказательства; `(audit)`, `(review required)` и `уточнить` = не проверены точная сигнатура/вызов/связь с профилем. Кандидатное решение **не является окончательным**. Записи о дебаг-коде и общих библиотеках не считаются подтверждением использования в ротации. Игровой тест: **NOT RUN**.

## Единая матрица (101 строк; 0 точных дубликатов обнаружено)

| Потребность профиля | API / кандидат | Sonah | MaxDps Forever | JustAC | ForeverAuras | ForeverRotation | RotationGuide | Выбор Kord / статус |
|---|---|---|---|---|---|---|---|---|
| 1. Цель существует | UnitExists | Sonah/Core/Atoms/Units.lua:46 | — | JustAC/BlizzardAPI/StateHelpers.lua:25 | — | ForeverRotation/CC.lua:43 | RotationGuide/Core/State.lua:301 | UnitExists via guarded unit reader; pending client |
| 2. Цель враждебна | UnitCanAttack | Sonah/Core/Atoms/Units.lua:60 | — | JustAC/BlizzardAPI/StateHelpers.lua:26 | — | ForeverRotation/CC.lua:43 | RotationGuide/Core/State.lua:285 | UnitCanAttack; pending client |
| 3. Здоровье цели | UnitHealth / UnitHealthMax | Sonah/Core/Atoms/Units.lua:569 | — | JustAC/BlizzardAPI/StateHelpers.lua:23 | — | — | — | Guarded health pair; pending client |
| 4. Здоровье игрока | UnitHealth / UnitHealthMax | Sonah/Core/Atoms/Units.lua:569 | — | JustAC/BlizzardAPI/StateHelpers.lua:23 | — | — | — | Same unit reader; pending client |
| 5. Здоровье питомца | UnitHealth / UnitHealthMax | Sonah/Core/Atoms/Units.lua:569 | — | JustAC/BlizzardAPI/StateHelpers.lua:23 | — | — | — | Candidate same unit reader; pet case unverified |
| 6. Мана / ресурс | UnitPower | Sonah/Core/Atoms/Units.lua:326 | — | JustAC/BlizzardAPI/StateHelpers.lua:2155 | — | ForeverRotation/Engine.lua:84 | RotationGuide/Core/State.lua:234 | Separate mana from active power type; pending client |
| 7. Уровень игрока | UnitLevel | Sonah/Core/Atoms/Units.lua:158 | — | JustAC/BlizzardAPI/StateHelpers.lua:1597 | — | ForeverRotation/Engine.lua:393 | RotationGuide/Core/State.lua:309 | Centralized unit reader; pending client |
| 8. Класс игрока | UnitClass | Sonah/Core/Atoms/Units.lua:80 | — | JustAC/BlizzardAPI/StateHelpers.lua:2359 | — | ForeverRotation/Core.lua:181 | RotationGuide/Core/API.lua:45 | Class token; pending client |
| 9. Игрок движется | IsPlayerMoving | — | — | JustAC/DebugCommands.lua:8826 (debug only) | — | ForeverRotation/Engine.lua:56 | — | Guarded candidate, no false on error |
| 10. Дистанция применения способности | IsSpellInRange | Sonah/Core/Atoms/Spells.lua:445 | — | JustAC/BlizzardAPI/StateHelpers.lua:397 | — | ForeverRotation/Engine.lua:3 | RotationGuide/Core/State.lua:248 | Spell-specific boolean; not meters |
| 11. Кулдаун способности | GetSpellCooldown / C_Spell | Sonah/Core/Atoms/Spells.lua:289 | — | JustAC/BlizzardAPI/CooldownTracking.lua:15 | — | ForeverRotation/Display.lua:302 | RotationGuide/Core/State.lua:101 | SpellID cooldown + guarded return; pending client |
| 12. Баффы игрока | Aura reader | Sonah/Core/Atoms/Auras.lua:743 | — | JustAC/BlizzardAPI/SecretValues.lua:239 | ForeverAuras/API.lua (review required) | ForeverRotation/Rotations/Buffs.lua (review required) | — | Prefer aura scan with secret handling; exact API TBD |
| 13. Дебаффы цели | Aura reader | Sonah/Core/Atoms/Auras.lua:743 | — | JustAC/BlizzardAPI/SecretValues.lua:239 | ForeverAuras/API.lua (review required) | — | — | Same aura reader, unit-specific; exact API TBD |
| 14. Агро / угроза | UnitThreatSituation | Sonah/Core/Atoms/Units.lua:1318 | — | JustAC/BlizzardAPI/StateHelpers.lua:81 | — | — | — | Threat is not equivalent to hasAggro; unresolved |
| 15. Каст противника | UnitCastingInfo | Sonah/Core/Atoms/Casts.lua:26 | — | JustAC/BlizzardAPI/StateHelpers.lua:129 | — | ForeverRotation/Engine.lua:170 | — | Casting reader; interruptability separate |
| 16. Число врагов | Nameplate enumeration | — | — | JustAC/BlizzardAPI/StateHelpers.lua:82–108 | — | — | — | Observed engaged nameplates only; not exact total |
| 17. Группа / рейд | GetNumGroupMembers | Sonah/Core/Atoms/Units.lua:1214 | — | JustAC/DebugCommands.lua:5474 (debug only) | — | — | — | Candidate, not equivalent to dungeon/raid |
| 18. Подземелье / рейд | Instance context | — | — | JustAC/DebugCommands.lua:284 (debug only) | — | — | — | Unresolved; no confirmed runtime provider |
| 19. Изученность заклинания | Spellbook scan | Sonah/Core/Atoms/Spells.lua:68–96 | — | JustAC/BlizzardAPI/SpellQuery.lua:69–93 | — | — | RotationGuide/Core/State.lua:24–67 | Sonah rank resolver candidate |
| 20. Ранг заклинания | Highest learned rank | Sonah/Core/Atoms/Spells.lua:139–246 | — | JustAC/BlizzardAPI/SpellQuery.lua:69–93 | — | — | RotationGuide/Core/State.lua:24–67 | Central ability-to-rank resolver |
| 21. Доступность / стоимость | Usability query | Sonah/Core/Atoms/Spells.lua (audit) | — | JustAC/BlizzardAPI/SpellQuery.lua (audit) | — | ForeverRotation/Engine.lua (audit) | RotationGuide/Core/State.lua:79–109 | Keep distinct from cooldown/range |
| 22. Прерывание | Enemy cast + interrupt spell | Sonah/Core/Atoms/Casts.lua:26 | — | JustAC/BlizzardAPI/StateHelpers.lua:129 | — | ForeverRotation/Rotations/Interrupts.lua (audit) | — | Requires cast/interruptible/ready separately |
| 23. Контроль / CC | Aura and unit state | Sonah/Core/Atoms/Auras.lua (audit) | — | JustAC/BlizzardAPI/StateHelpers.lua (audit) | — | ForeverRotation/CC.lua (audit) | — | Unresolved CC-safe AoE |
| 24. Автовыстрел / автоатака | Attack state | — | — | — | — | ForeverRotation/Rotations/Hunter.lua (audit) | — | Unresolved |
| 25. GCD | Global cooldown | Sonah/Core/Atoms/Spells.lua (audit) | — | JustAC/BlizzardAPI/CooldownTracking.lua (audit) | — | ForeverRotation/Engine.lua (audit) | RotationGuide/Core/State.lua (audit) | Must distinguish spell cooldown |
| 26. Заряды способности | Charges query | Sonah/Core/Atoms/Spells.lua (audit) | — | JustAC/BlizzardAPI/SpellQuery.lua (audit) | — | — | — | Unresolved exact return |
| 27. Остаток баффа | Aura expiration | Sonah/Core/Atoms/Auras.lua (audit) | — | JustAC/BlizzardAPI/SecretValues.lua (audit) | ForeverAuras/API.lua (audit) | — | — | Expiration and current time; pending |
| 28. Остаток дебаффа | Aura expiration | Sonah/Core/Atoms/Auras.lua (audit) | — | JustAC/BlizzardAPI/SecretValues.lua (audit) | ForeverAuras/API.lua (audit) | — | — | Same aura model |
| 29. Таланты / специализация | Talent reader | Sonah/Core/Atoms/Talents.lua:535 | — | — | — | — | — | Unresolved spec contract |
| 30. Питомец атакует цель | Pet target state | Sonah/Core/Atoms/Units.lua (audit) | — | — | — | ForeverRotation/Rotations/Hunter.lua (audit) | — | Unresolved |
| 31. Время до смерти цели | TTD estimator | — | — | — | — | — | — | Unresolved |
| 32. Доступность action bar | Action bar inspection | — | — | JustAC/ActionBarScanner.lua (audit) | — | — | — | Separate from ability readiness |
| 33. Привязка клавиши | Binding inspection | — | — | JustAC/ActionBarScanner.lua (audit) | — | — | — | Unresolved exact mapping |
| 34. Изменение формы / стойки | Form/stance state | Sonah/Classes/Druid.lua (audit) | — | — | — | ForeverRotation/Rotations/Druid.lua (audit) | — | Unresolved |
| 35. Условия лечения / диспела | Friendly target + aura | Sonah/Classes/Priest.lua (audit) | — | — | ForeverAuras/API.lua (audit) | ForeverRotation/Rotations/Priest.lua (audit) | — | Unresolved |
| 36. Тринкеты / расовые / предметы | Usable action | Sonah/Classes/Racials.lua (audit) | — | — | — | — | — | Unresolved |
| 37. Опасный входящий урон | Threat/health/encounter | — | — | — | — | — | — | Unresolved; no guess |
| 38. PvP / игрок-цель | Unit player test | Sonah/Core/Atoms/Units.lua (audit) | — | JustAC/BlizzardAPI/StateHelpers.lua (audit) | — | — | — | Unresolved |
| 39. Воскрешение / смерть | Unit death | Sonah/Core/Atoms/Units.lua (audit) | — | JustAC/BlizzardAPI/StateHelpers.lua (audit) | — | — | — | Unresolved |
| 40. Процент здоровья союзника / выбор цели лечения | уточнить API по указанному референсу | Sonah/Classes/Druid.lua:527 C.healBelow; Sonah/Classes/Paladin.lua:202 C.healingOther | — | — | — | — | — | healing target != enemy target — КАНДИДАТ; требуется трассировка |
| 41. Невидимое/защищённое значение здоровья | уточнить API по указанному референсу | Sonah/Classes/Druid.lua:162 C.healHidden | — | — | — | ForeverRotation/Rotations/Signals.lua:1–15 | — | secret-safe hint != numeric HP available to priority engine — КАНДИДАТ; требуется трассировка |
| 42. Порог здоровья цели / execute | уточнить API по указанному референсу | Sonah/Classes/Mage.lua:189 C.targetBelow | — | JustAC/Data/Forever/Rotations.lua:633 t=execute | — | — | — | execute threshold separate from target health — КАНДИДАТ; требуется трассировка |
| 43. Наличие/обновление DoT по времени | уточнить API по указанному референсу | Sonah/Classes/Druid.lua:185–186 C.dotRefresh | — | JustAC/Data/Forever/Rotations.lua:46 t=dot | — | — | — | refresh window separate from aura existence — КАНДИДАТ; требуется трассировка |
| 44. Проверка владельца HoT/DoT | уточнить API по указанному референсу | Sonah/Classes/Priest.lua (header: own Renew) | — | — | — | — | — | own aura != any aura; exact implementation audit — КАНДИДАТ; требуется трассировка |
| 45. Стеки ауры | уточнить API по указанному референсу | Sonah/Classes/Druid.lua:151 C.stacksBelow | MaxDps_Druid/Specialization/Forever/Balance.lua:28 MaxDps.Stacks | JustAC/Data/Forever/Rotations.lua:83 t=stack | — | — | — | count separate from aura active — КАНДИДАТ; требуется трассировка |
| 46. Стеки проков | уточнить API по указанному референсу | Sonah/Classes/Druid.lua:338 C.proc | — | — | — | — | — | proc activation/stack semantics audit — КАНДИДАТ; требуется трассировка |
| 47. Оружейное зачарование | уточнить API по указанному референсу | Sonah/Classes/Rogue.lua:196 C.weaponEnchantMissing | — | — | — | — | — | weapon enchant != player aura — КАНДИДАТ; требуется трассировка |
| 48. Тотем активен / нужен | уточнить API по указанному референсу | — | — | JustAC/Data/Forever/Rotations.lua:492 t=totem | — | — | — | totem slot/existence audit — КАНДИДАТ; требуется трассировка |
| 49. Комбо-поинты | уточнить API по указанному референсу | Sonah/Classes/Druid.lua:178 C.combo | — | JustAC/Data/Forever/Rotations.lua:71 res=combo_points | — | — | — | resource combo points separate from mana — КАНДИДАТ; требуется трассировка |
| 50. Энергия | уточнить API по указанному референсу | — | — | JustAC/Data/Forever/Rotations.lua:68 res=energy | — | ForeverRotation/Rotations/Signals.lua:49 | — | resource typed and secret-safe — КАНДИДАТ; требуется трассировка |
| 51. Ярость | уточнить API по указанному референсу | — | — | JustAC/Data/Forever/Rotations.lua:84 res=rage | — | ForeverRotation/Rotations/Signals.lua:59 | — | resource typed and secret-safe — КАНДИДАТ; требуется трассировка |
| 52. Нехватка ресурса / starved | уточнить API по указанному референсу | — | MaxDps_Druid/Specialization/Forever/Balance.lua:45 MaxDps.Starved | JustAC/Data/Forever/Rotations.lua:45 t=starved | — | — | — | not equivalent to numeric mana — КАНДИДАТ; требуется трассировка |
| 53. Прогноз расхода ресурса | уточнить API по указанному референсу | Sonah/Classes/Hunter.lua:136 C.spareMana; Sonah/Classes/Druid.lua:322 C.efficient | — | — | — | — | — | requires explicit resource cost and policy — КАНДИДАТ; требуется трассировка |
| 54. Доступность предмета в сумке | уточнить API по указанному референсу | Sonah/Classes/Mage.lua:243 C.hasItem | — | — | — | — | — | inventory ownership vs cooldown — КАНДИДАТ; требуется трассировка |
| 55. Недавнее применение способности | уточнить API по указанному референсу | Sonah/Classes/Druid.lua:540 C.notRecent | — | — | — | — | — | cast history separate from cooldown — КАНДИДАТ; требуется трассировка |
| 56. Очередь/ожидание каста | уточнить API по указанному референсу | Sonah/Classes/Druid.lua:156 C.castPending | — | — | — | — | — | pending cast separate from currently casting — КАНДИДАТ; требуется трассировка |
| 57. Проверка возможности закончить каст | уточнить API по указанному референсу | Sonah/Classes/Mage.lua:302 C.notCasting; Sonah/Classes/Druid.lua:156 C.castPending | — | — | — | — | — | channel/cast interruption audit — КАНДИДАТ; требуется трассировка |
| 58. Окно автоатаки / swing timer | уточнить API по указанному референсу | Sonah/Classes/Druid.lua:447 C.autoActive | — | JustAC/Data/Forever/Rotations.lua:121 t=swing | — | — | — | timing != autoattack active — КАНДИДАТ; требуется трассировка |
| 59. Тик периодического урона | уточнить API по указанному референсу | — | — | JustAC/Data/Forever/Rotations.lua:450 t=tick | — | — | — | tick timing distinct from DoT duration — КАНДИДАТ; требуется трассировка |
| 60. Стелс | уточнить API по указанному референсу | — | — | JustAC/Data/Forever/Rotations.lua:435 t=stealth | — | — | — | stealth state != combat — КАНДИДАТ; требуется трассировка |
| 61. Контроль персонажа / root | уточнить API по указанному референсу | Sonah/Classes/Druid.lua:197 C.lossOfControl('root') | — | — | — | — | — | root/stun/silence separate signals — КАНДИДАТ; требуется трассировка |
| 62. Прерываемость вражеского каста | уточнить API по указанному референсу | Sonah/Classes/Druid.lua:26 C.targetInterruptible | — | — | — | — | — | cast present != interruptible — КАНДИДАТ; требуется трассировка |
| 63. Снятие дебафа с союзника | уточнить API по указанному референсу | Sonah/Classes/Druid.lua:548–550 C.healDispellable('Curse'/'Poison') | — | — | — | — | — | debuff type and dispel capability — КАНДИДАТ; требуется трассировка |
| 64. Самодиспел | уточнить API по указанному референсу | Sonah/Classes/Mage.lua:309 C.selfDispellable | — | — | — | — | — | self vs party target — КАНДИДАТ; требуется трассировка |
| 65. Групповой баф отсутствует | уточнить API по указанному референсу | Sonah/Classes/Mage.lua:231 C.partyBuffMissing | — | — | — | — | — | party coverage != player buff — КАНДИДАТ; требуется трассировка |
| 66. Классовый баф отсутствует | уточнить API по указанному референсу | Sonah/Classes/Druid.lua:233 C.buffMissing | — | — | — | — | — | buff scope / owner — КАНДИДАТ; требуется трассировка |
| 67. Тип цели: игрок | уточнить API по указанному референсу | Sonah/Classes/Druid.lua:196 C.targetIsPlayer | — | — | — | — | — | PVP player-target detection — КАНДИДАТ; требуется трассировка |
| 68. Тип цели: элита/босс | уточнить API по указанному референсу | Sonah/Classes/Druid.lua:176 C.targetElite; Sonah/Classes/Hunter.lua:310 C.targetBoss | — | — | — | — | — | elite != boss — КАНДИДАТ; требуется трассировка |
| 69. Класс вражеской цели | уточнить API по указанному референсу | Sonah/Classes/Hunter.lua:129 C.targetClass; Sonah/Classes/Druid.lua:199 C.targetClassOrUnknown | — | — | — | — | — | class-aware PVP — КАНДИДАТ; требуется трассировка |
| 70. Наличие оружия дальнего боя | уточнить API по указанному референсу | Sonah/Classes/Hunter.lua:219 C.rangedWeapon | — | — | — | — | — | equipment prerequisite — КАНДИДАТ; требуется трассировка |
| 71. Достаточное количество противников для AoE | уточнить API по указанному референсу | — | MaxDps_Druid/Specialization/Forever/Balance.lua:24 MaxDps:SmartAoe | JustAC/Data/Forever/Rotations.lua:58 t=targets | — | — | — | observable count + thresholds — КАНДИДАТ; требуется трассировка |
| 72. Состояние игрока в соло/квестах | уточнить API по указанному референсу | Sonah/Classes/Druid.lua:237 C.solo; Sonah/Classes/Druid.lua:319 C.questing | — | — | — | — | — | solo != open world != dungeon — КАНДИДАТ; требуется трассировка |
| 73. Наличие группы и число участников | уточнить API по указанному референсу | Sonah/Classes/Druid.lua:219 C.inGroup; Sonah/Classes/Druid.lua:531 C.groupBelow | — | — | — | — | — | group count separate from instance type — КАНДИДАТ; требуется трассировка |
| 74. Наличие талантов/рангов талантов | уточнить API по указанному референсу | Sonah/Classes/Druid.lua:147 C.talent; Sonah/Classes/Druid.lua:243 C.noTalent | — | — | — | — | — | known spell != talent rank — КАНДИДАТ; требуется трассировка |
| 75. Специализация / дерево | уточнить API по указанному референсу | Sonah/Classes/Hunter.lua:149 C.spec | — | — | — | — | — | spec ID mapping — КАНДИДАТ; требуется трассировка |
| 76. Изменение формы и запрет способностей | уточнить API по указанному референсу | Sonah/Classes/Druid.lua:164 C.form; Sonah/Classes/Druid.lua:169 C.noForm | — | — | — | — | — | form gating — КАНДИДАТ; требуется трассировка |
| 77. Состояние pet отсутствует / призыв | уточнить API по указанному референсу | Sonah/Classes/Hunter.lua:110 C.noPet; Sonah/Classes/Hunter.lua:159 C.hasPet | — | — | — | — | — | pet existence separate from alive/dead — КАНДИДАТ; требуется трассировка |
| 78. Агро отсутствует / высокое агро | уточнить API по указанному референсу | Sonah/Classes/Druid.lua:184 C.aggro; Sonah/Classes/Druid.lua:430 C.noAggro | — | — | — | — | — | threat thresholds and roles — КАНДИДАТ; требуется трассировка |
| 79. Защитная рекомендация вне ротации | уточнить API по указанному референсу | — | — | — | — | ForeverRotation/Rotations/Signals.lua:1–15,31–42 | — | UI hint separate from priority action — КАНДИДАТ; требуется трассировка |
| 80. Проверка ограничения секретных чисел | уточнить API по указанному референсу | — | — | — | — | ForeverRotation/Rotations/Signals.lua:1–15 | — | curve UI cannot imply readable percentage — КАНДИДАТ; требуется трассировка |
| 81. Условие неизвестности заклинания | уточнить API по указанному референсу | Sonah/Classes/Druid.lua:180 C.unknown | — | JustAC/Data/Forever/Rotations.lua:160 t=unconfirmed | — | — | — | unknown != unavailable — КАНДИДАТ; требуется трассировка |
| 82. Проверка таланта / уровня до применения | уточнить API по указанному референсу | Sonah/Classes/Druid.lua:325 C.level; Sonah/Classes/Druid.lua:322 C.levelBelow | — | — | — | — | — | level-gated rank — КАНДИДАТ; требуется трассировка |
| 83. Проверка GCD vs общего/shared cooldown | уточнить API по указанному референсу | Sonah/Classes/Hunter.lua:24–27 sharedCd fields | — | — | — | — | — | shared cooldown separate from GCD and spell CD — КАНДИДАТ; требуется трассировка |
| 84. Слот экипировки → itemID | уточнить API по указанному референсу | Sonah/Core/Atoms/Items.lua:46 | — | JustAC/PrecombatEngine.lua:115 | ForeverAuras/GenericTrigger.lua:3790 | — | — | GetInventoryItemID; отдельный сигнал от наличия предмета в сумке — КАНДИДАТ; требуется трассировка |
| 85. Кулдаун экипированного предмета | уточнить API по указанному референсу | Sonah/Core/Atoms/Items.lua:124–125 | — | — | — | — | — | GetInventoryItemCooldown; не spell cooldown — КАНДИДАТ; требуется трассировка |
| 86. Наличие оружия дальнего боя по слоту | уточнить API по указанному референсу | Sonah/Core/Atoms/Items.lua:192–193 | — | — | — | — | — | GetInventoryItemID slot RANGED; не дальность цели — КАНДИДАТ; требуется трассировка |
| 87. Боеприпасы: слот/количество | уточнить API по указанному референсу | Sonah/Core/Atoms/Items.lua:206–212 | — | — | — | — | — | GetInventoryItemID/Count; отдельная механика Hunter — КАНДИДАТ; требуется трассировка |
| 88. Считывание tooltip экипировки | уточнить API по указанному референсу | Sonah/Core/Atoms/Items.lua:275–280 | — | — | — | — | — | C_TooltipInfo.GetInventoryItem; защищённые значения — КАНДИДАТ; требуется трассировка |
| 89. Ссылка предмета экипировки | уточнить API по указанному референсу | Sonah/Core/Atoms/Items.lua:310 | MaxDps/Helper.lua:1660 | — | — | — | — | GetInventoryItemLink; не подтверждает применимость — КАНДИДАТ; требуется трассировка |
| 90. Идентификатор инстанса | уточнить API по указанному референсу | — | — | — | ForeverAuras/Prototypes.lua:180 | — | — | GetInstanceInfo select(8); не равен inDungeon/inRaid — КАНДИДАТ; требуется трассировка |
| 91. Контекст вне инстанса | уточнить API по указанному референсу | — | MaxDps/SecretHelper.lua:332 | — | — | — | — | IsInInstance; не гарантирует solo — КАНДИДАТ; требуется трассировка |
| 92. Threat по паре юнитов | уточнить API по указанному референсу | — | — | — | ForeverAuras/Prototypes.lua:97 | — | — | UnitDetailedThreatSituation wrapper; надо изучить возвращаемые значения — КАНДИДАТ; требуется трассировка |
| 93. Время последнего изменения cooldown | уточнить API по указанному референсу | — | — | JustAC/BlizzardAPI/CooldownTracking.lua:15 | — | — | — | Инвалидация/кэш cooldown; отдельно от его числовой длительности — КАНДИДАТ; требуется трассировка |
| 94. Форма друида через кэш | уточнить API по указанному референсу | — | — | JustAC/FormCache.lua:30 | — | — | — | Форма требует отдельной стратегии refresh — КАНДИДАТ; требуется трассировка |
| 95. Предбоевое состояние/подготовка | уточнить API по указанному референсу | — | — | JustAC/PrecombatEngine.lua:115 | — | — | — | Precombat отличается от combat rotation — КАНДИДАТ; требуется трассировка |
| 96. Защитная ветка вне обычного DPS | уточнить API по указанному референсу | — | — | JustAC/DefensiveEngine.lua:228 | — | — | — | Защитные правила/сигналы не смешивать с DPS приоритетом — КАНДИДАТ; требуется трассировка |
| 97. Диапазон действия предмета | уточнить API по указанному референсу | — | — | — | ForeverAuras/ActionRange.lua:18 | — | — | Отдельный диапазон предмета и заклинания — КАНДИДАТ; требуется трассировка |
| 98. Статус видимости/доступности кнопки | уточнить API по указанному референсу | — | — | JustAC/ActionBarScanner.lua:16–17 | ForeverAuras/ActionRange.lua:43 | — | — | Action slot vs binding vs usable — КАНДИДАТ; требуется трассировка |
| 99. Наличие питомца в контексте классового профиля | уточнить API по указанному референсу | Sonah/Core/Atoms/Units.lua:1191 | — | — | — | — | RotationGuide/Core/State.lua:313 | Pet existence vs pet health/attack state — КАНДИДАТ; требуется трассировка |
| 100. Определение цели-игрока и классификации | уточнить API по указанному референсу | — | — | — | — | ForeverRotation/CC.lua:46 | RotationGuide/Core/State.lua:308 | PvP unit vs elite/boss; проверить семантику — КАНДИДАТ; требуется трассировка |
| 101. Различие combat lockdown и actual combat | уточнить API по указанному референсу | Sonah/Core/Atoms/Units.lua:120 | — | — | — | ForeverRotation/Core.lua:127 | — | UI lockdown не означает агро — КАНДИДАТ; требуется трассировка |

## Проверка покрытия и пробелы

**Объединены** прежние три набора: 39 первоначальных, 44 добавленных из профилей, 18 добавленных после сканирования архивов. Совпадающие по написанию требования слиты; семантически близкие, но неэквивалентные оставлены отдельными. **Число строк не равно числу полностью подтверждённых API-методов.**

Источники для дальнейшей проверки: `Sonah.zip` (в том числе `Classes/`, `Core/Atoms/`), `MaxDps.zip` (только `Specialization/Forever/` как Forever-специфичная реализация), `JustAC.zip` (`Data/Forever/Rotations.lua`, `BlizzardAPI/`), `ForeverAuras.zip` (API, ауры, range, prototype), `ForeverRotation.zip` (`Rotations/`, `Engine.lua`), `RotationGuide.zip` (`Data/`, `Core/State.lua`).

**Критические незакрытые проверки:** число/секретность HP и ресурсов; реальное число врагов; тип инстанса и solo/open-world; точное расстояние vs проверка радиуса заклинания; threat vs aggro; GCD vs spell/shared/item cooldown; ауры с владельцем, длительностью и стаками; Hunter ammo/auto shot/pet; привязка кнопки vs изученность и доступность способности. Отдельно проверить negative/unknown semantics, секретные значения, ранги и клиентскую версию API.

**Следующая работа:** пройти каждую строку и все шесть колонок, выписать `profile → helper → API` с точным файлом/строкой, аргументами, возвращаемым значением, fallback, ограничениями и статусом `SOURCE VERIFIED / CLIENT PASS / CLIENT FAIL / NOT RUN`. По результатам выбрать метод и объяснить, почему он лучше альтернатив. До этого **движок не переписывать**, отсутствие свидетельства не превращать в `false` или `0`.

## История

v3: 39 строк основной матрицы + 44 строки дополнительной сверки + 18 строк третьего сканирования. v4: объединены в единую таблицу с шестью референсными колонками; ни один непроверенный кандидат не объявлен подтверждённым.
