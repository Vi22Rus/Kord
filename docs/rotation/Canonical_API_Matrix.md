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


## Дополнительная сверка потребностей по реальным профилям (2026-11-21)

**Результат:** исходные 39 строк НЕ покрывали все условия. Дополнительно выявлено **44** отдельных потребностей из классовых профилей Sonah, 27 файлов MaxDps `Specialization/Forever`, Forever-APL JustAC и профилей ForeverRotation. Это **список обнаруженных пропусков**, не заявление о полном покрытии. В столбце источника приводится файл/строка или явно обозначен требующий аудита участок. Прочерк в основной таблице нельзя считать доказательством отсутствия функции. В этой сверке не утверждается, что клиент Forever проверен.

| Пропущенная потребность (отдельная строка) | Реальный референс / свидетельство | Почему требуется отдельный контракт |
|---|---|---|
| Процент здоровья союзника / выбор цели лечения | Sonah/Classes/Druid.lua:527 C.healBelow; Sonah/Classes/Paladin.lua:202 C.healingOther | healing target != enemy target |
| Невидимое/защищённое значение здоровья | Sonah/Classes/Druid.lua:162 C.healHidden; ForeverRotation/Rotations/Signals.lua:1–15 | secret-safe hint != numeric HP available to priority engine |
| Порог здоровья цели / execute | Sonah/Classes/Mage.lua:189 C.targetBelow; JustAC/Data/Forever/Rotations.lua:633 t=execute | execute threshold separate from target health |
| Наличие/обновление DoT по времени | Sonah/Classes/Druid.lua:185–186 C.dotRefresh; JustAC/Data/Forever/Rotations.lua:46 t=dot | refresh window separate from aura existence |
| Проверка владельца HoT/DoT | Sonah/Classes/Priest.lua (header: own Renew) | own aura != any aura; exact implementation audit |
| Стеки ауры | Sonah/Classes/Druid.lua:151 C.stacksBelow; MaxDps_Druid/Specialization/Forever/Balance.lua:28 MaxDps.Stacks; JustAC/Data/Forever/Rotations.lua:83 t=stack | count separate from aura active |
| Стеки проков | Sonah/Classes/Druid.lua:338 C.proc | proc activation/stack semantics audit |
| Оружейное зачарование | Sonah/Classes/Rogue.lua:196 C.weaponEnchantMissing | weapon enchant != player aura |
| Тотем активен / нужен | JustAC/Data/Forever/Rotations.lua:492 t=totem | totem slot/existence audit |
| Комбо-поинты | Sonah/Classes/Druid.lua:178 C.combo; JustAC/Data/Forever/Rotations.lua:71 res=combo_points | resource combo points separate from mana |
| Энергия | JustAC/Data/Forever/Rotations.lua:68 res=energy; ForeverRotation/Rotations/Signals.lua:49 | resource typed and secret-safe |
| Ярость | JustAC/Data/Forever/Rotations.lua:84 res=rage; ForeverRotation/Rotations/Signals.lua:59 | resource typed and secret-safe |
| Нехватка ресурса / starved | MaxDps_Druid/Specialization/Forever/Balance.lua:45 MaxDps.Starved; JustAC/Data/Forever/Rotations.lua:45 t=starved | not equivalent to numeric mana |
| Прогноз расхода ресурса | Sonah/Classes/Hunter.lua:136 C.spareMana; Sonah/Classes/Druid.lua:322 C.efficient | requires explicit resource cost and policy |
| Доступность предмета в сумке | Sonah/Classes/Mage.lua:243 C.hasItem | inventory ownership vs cooldown |
| Недавнее применение способности | Sonah/Classes/Druid.lua:540 C.notRecent | cast history separate from cooldown |
| Очередь/ожидание каста | Sonah/Classes/Druid.lua:156 C.castPending | pending cast separate from currently casting |
| Проверка возможности закончить каст | Sonah/Classes/Mage.lua:302 C.notCasting; Sonah/Classes/Druid.lua:156 C.castPending | channel/cast interruption audit |
| Окно автоатаки / swing timer | JustAC/Data/Forever/Rotations.lua:121 t=swing; Sonah/Classes/Druid.lua:447 C.autoActive | timing != autoattack active |
| Тик периодического урона | JustAC/Data/Forever/Rotations.lua:450 t=tick | tick timing distinct from DoT duration |
| Стелс | JustAC/Data/Forever/Rotations.lua:435 t=stealth | stealth state != combat |
| Контроль персонажа / root | Sonah/Classes/Druid.lua:197 C.lossOfControl('root') | root/stun/silence separate signals |
| Прерываемость вражеского каста | Sonah/Classes/Druid.lua:26 C.targetInterruptible | cast present != interruptible |
| Снятие дебафа с союзника | Sonah/Classes/Druid.lua:548–550 C.healDispellable('Curse'/'Poison') | debuff type and dispel capability |
| Самодиспел | Sonah/Classes/Mage.lua:309 C.selfDispellable | self vs party target |
| Групповой баф отсутствует | Sonah/Classes/Mage.lua:231 C.partyBuffMissing | party coverage != player buff |
| Классовый баф отсутствует | Sonah/Classes/Druid.lua:233 C.buffMissing | buff scope / owner |
| Тип цели: игрок | Sonah/Classes/Druid.lua:196 C.targetIsPlayer | PVP player-target detection |
| Тип цели: элита/босс | Sonah/Classes/Druid.lua:176 C.targetElite; Sonah/Classes/Hunter.lua:310 C.targetBoss | elite != boss |
| Класс вражеской цели | Sonah/Classes/Hunter.lua:129 C.targetClass; Sonah/Classes/Druid.lua:199 C.targetClassOrUnknown | class-aware PVP |
| Наличие оружия дальнего боя | Sonah/Classes/Hunter.lua:219 C.rangedWeapon | equipment prerequisite |
| Достаточное количество противников для AoE | MaxDps_Druid/Specialization/Forever/Balance.lua:24 MaxDps:SmartAoe; JustAC/Data/Forever/Rotations.lua:58 t=targets | observable count + thresholds |
| Состояние игрока в соло/квестах | Sonah/Classes/Druid.lua:237 C.solo; Sonah/Classes/Druid.lua:319 C.questing | solo != open world != dungeon |
| Наличие группы и число участников | Sonah/Classes/Druid.lua:219 C.inGroup; Sonah/Classes/Druid.lua:531 C.groupBelow | group count separate from instance type |
| Наличие талантов/рангов талантов | Sonah/Classes/Druid.lua:147 C.talent; Sonah/Classes/Druid.lua:243 C.noTalent | known spell != talent rank |
| Специализация / дерево | Sonah/Classes/Hunter.lua:149 C.spec | spec ID mapping |
| Изменение формы и запрет способностей | Sonah/Classes/Druid.lua:164 C.form; Sonah/Classes/Druid.lua:169 C.noForm | form gating |
| Состояние pet отсутствует / призыв | Sonah/Classes/Hunter.lua:110 C.noPet; Sonah/Classes/Hunter.lua:159 C.hasPet | pet existence separate from alive/dead |
| Агро отсутствует / высокое агро | Sonah/Classes/Druid.lua:184 C.aggro; Sonah/Classes/Druid.lua:430 C.noAggro | threat thresholds and roles |
| Защитная рекомендация вне ротации | ForeverRotation/Rotations/Signals.lua:1–15,31–42 | UI hint separate from priority action |
| Проверка ограничения секретных чисел | ForeverRotation/Rotations/Signals.lua:1–15 | curve UI cannot imply readable percentage |
| Условие неизвестности заклинания | Sonah/Classes/Druid.lua:180 C.unknown; JustAC/Data/Forever/Rotations.lua:160 t=unconfirmed | unknown != unavailable |
| Проверка таланта / уровня до применения | Sonah/Classes/Druid.lua:325 C.level; Sonah/Classes/Druid.lua:322 C.levelBelow | level-gated rank |
| Проверка GCD vs общего/shared cooldown | Sonah/Classes/Hunter.lua:24–27 sharedCd fields | shared cooldown separate from GCD and spell CD |

### Обнаруженная архитектурная проблема

`ForeverRotation/Rotations/Signals.lua` прямо описывает `UnitPowerPercent`/`UnitHealthPercent` с `C_CurveUtil`: **скрытый процент передаётся в прозрачность индикатора, аддон не читает число**. Поэтому `playerHealthPercent`, `manaPercent`, `targetHealthPercent` нельзя объявлять универсально доступными числовыми сигналами без проверки на актуальном билде. Необходимо отдельно учитывать: (a) точный числовой сигнал, (b) защищённый/нечитаемый сигнал, (c) визуальный threshold hint, который не влияет на приоритет ротации. Это критическая недоработка первоначальной матрицы.

### Статус полноты

**Минимум 83 выявленных строк** в основном реестре и дополнении; это НЕ окончательное число. Полный построчный cross-reference по всем методам шести архивов, полное заполнение шести столбцов каждой строки и игровой тест НЕ завершены. Перед переписыванием движка нужно объединить строки в одну таблицу, проверить все альтернативы и классифицировать каждую по SOURCE VERIFIED / CLIENT PASS / CLIENT FAIL / NOT RUN.
