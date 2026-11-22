# GameData Contract — все классы

**Актуальный целевой контракт этапа 2.9:** [Profile Contract v1](Profile_Contract.md) определяет `Needs`, ленивый контролируемый доступ к сигналам и `UNKNOWN`; он НЕ реализован в исходниках. Настоящий документ различает подтверждённые поля GameState и кандидатные будущие провайдеры. Ни одно предполагаемое поле или API не становится `READY` от записи в документации. Прежние булевы условия 2.8 остаются исполняемым наследием только до проверенной миграции.



**Статус:** проектная таблица для согласования, не описание уже доступного игрового API. Источник фактического контракта: `Core/GameState.lua`, `Core/GameAPI.lua`, `Core/AbilityEligibility.lua`. Существующие `status=READY/UNKNOWN/UNAVAILABLE` нельзя бездумно превращать в boolean.

## Утверждённый слой v14 — прямые поля GameState (начальный охват 2.8.2)

**Канон API:** [Canonical_API_Matrix.md](Canonical_API_Matrix.md) v14. Канон имен полей — этот GameData Contract совместно с фактическим `GameState`; 101-строчная матрица **не** объявляет себя словарём `state` ключей. **Никаких временных runtime-адаптеров старых ротаций.** Имена новых профилей фиксировать после реализации прямого контракта. Отдельные черновые Hunter-профили не подключены в TOC и должны переноситься на эту схему позднее.

| Поле снимка GameState | Тип | API из v14 | Матрица № | Статус nil/secret/error | Потребитель |
|---|---|---|---:|---|---|
| `player.moving` | `{status,value:boolean?}` | `IsPlayerMoving()` | 9 | UNKNOWN/UNAVAILABLE, не false | GameData, будущий Eligibility |
| `target.isPlayer` | `{status,value:boolean?}` | `UnitIsPlayer("target")` | 38, 67, 100 | UNKNOWN/UNAVAILABLE, не false | target/context |
| `target.threat` | `{status,value:0..3?}` | `UnitThreatSituation("player","target")` | 14,78,92 | UNKNOWN при nil и защищённых значениях | defensive policy |
| `pet.exists` | `{status,value:boolean?}` | `UnitExists("pet")` | 5,77,99 | подтверждённое false = отсутствие; nil = UNKNOWN | Hunter |
| `pet.dead` | `{status,value:boolean?}` | `UnitIsDeadOrGhost("pet")` | 5,77,99 | UNKNOWN если pet не подтверждён | Hunter |
| `pet.health` | `{current,maximum,percent?,status}` | `UnitHealth("pet")`, `UnitHealthMax("pet")` | 5 | при secret нет числового процента | Hunter |
| `context.inGroup` | `{status,value:boolean?}` | `IsInGroup()` | 17,72,73 | UNKNOWN/UNAVAILABLE | world/instance classification |
| `context.inRaid` | `{status,value:boolean?}` | `IsInRaid()` | 17,72,73 | UNKNOWN/UNAVAILABLE | world/instance classification |
| `context.inInstance` | `{status,value:boolean?}` | `IsInInstance()` — первый bool результата | 18,72,90–91 | UNKNOWN/UNAVAILABLE | instance classification |

`player` и `target` остаются совместимы со старым ядром; новые данные добавляются без скрытого преобразования полей ротаций. `GameState` НЕ утверждает `isDungeon`, `isRaid`, `inPvP`, полное число врагов, TTD или safe AoE только по `inInstance=true`. Этим сигналам нужен отдельный подтверждённый контракт v14. Не сравнивать secret числовые значения; `GameAPI` отбрасывает их до `GameState`. Старые кандидаты ниже — исторические предварительные имена, **не перечень реализованных полей**.

## Дополнительные прямые поля v14 (2.8.2b)

| Поле | Источник | Строка v14 | Fail closed |
|---|---|---|---|
| `context.status` | `inGroup`, `inRaid`, `inInstance` **and** `instanceType` | #17/#18/#90/#91 | UNKNOWN if any required context component cannot be checked |
| `target.threat` | `UnitThreatSituation("player","target")` strictly integer 0..3 | #14/#78/#92 | UNKNOWN on nil, secret, noninteger, outside range |
| `context.instanceType` | `GetInstanceInfo()` second result, only after confirmed inInstance | #18/#90/#91 | UNKNOWN when instance type unavailable; `none` only outside instance |
| `pet.targetExists` | `UnitExists("pettarget")` | #30 | UNKNOWN when pet missing/unknown |
| `pet.attackingTarget` | `UnitIsUnit("pettarget","target")` after existence checks | #30 | UNKNOWN when relation unconfirmed |
| `ReadAutoShot(spellID).active` | `C_Spell.IsAutoRepeatSpell(spellID)` | #24 | UNKNOWN/UNAVAILABLE, no inferred swing |
| `ReadAutoShot(spellID).current` | `C_Spell.IsCurrentSpell(spellID)` | #24 | UNKNOWN/UNAVAILABLE, no queued inference |

## Проверяемые Curve-проценты — прямые методы 2.8.2c

Матрица **v14 № 3–6, 41, 49–51**: `GameAPI:ReadHealthPercent(unit, curve)` и `GameAPI:ReadPowerPercent(unit,powerType,curve)` (переадресованы в `GameState`) возвращают обычный `{status,value?,source,reason,observedAt}`. Они **только читают** `UnitHealthPercent(unit,false,curve)` и `UnitPowerPercent(unit,powerType,false,curve)`; принимают только `player/target/pet`, обычный незащищённый `curve`, конечный Lua number `0..100`. Иначе — `UNKNOWN` или `UNAVAILABLE`, без заполнения ложным `0`, `100` или группой 5%-полос. В v14 **не доказано**, что Curve может выдать доступную Lua-цифру в бою. Сами Curve-объекты и их допустимые источники требуют отдельного клиентского подтверждения. Эти функции не активируют новые рекомендации и не создают адаптеров прежних профилей.

## Обязательные колонки
`key | type/range | meaning | source/API | READY value | false/zero | nil/UNKNOWN | refresh trigger | consumers | evidence | implementation status`.

**Нормализация:** прямой утверждённый GameData внутри ядра; без временных runtime-адаптеров. Старые snake_case и camelCase профилей подлежат будущему переносу на утверждённый контракт, не скрытому alias-mapping. Ниже — **кандидаты**, не утверждённый контракт; перед реализацией сверить с реальными потребителями.

| Кандидат ключа | Тип/диапазон | Смысл | При UNKNOWN/nil | Источник/статус |
|---|---|---|---|---|
| playerLevel | integer 1+ | уровень игрока | не угадывать профиль | GameState identity; mapping TODO |
| inCombat | boolean | игрок в бою | не предполагать бой/покой | GameState combat; TODO |
| hasTarget | boolean | существует цель | не атаковать | GameState target; TODO |
| targetAttackable | boolean | подтверждённая враждебная доступная цель | блокировать вредоносное действие | target + API; TODO |
| targetDead | boolean | цель мертва | не считать живой | target; TODO |
| playerHealthPercent | number 0..100 | здоровье игрока | не подменять 100 | GameState health; TODO |
| manaPercent | number 0..100 | ресурс, только если действительно мана | не подменять 100 | GameState resources; TODO |
| moving | boolean | движение игрока | блокировать требующие неподвижности касты | API evidence TODO |
| targetDistance | number >=0 | дистанция | не считать дальнюю/ближнюю | API evidence TODO |
| inDungeon | boolean | контекст подземелья | не считать соло | context evidence TODO |
| inRaid | boolean | контекст рейда | не считать соло | context evidence TODO |
| hasAggro | boolean | фактическое агро на игроке | не предполагать агро | threat evidence TODO |
| enemyCount | integer >=0 | число подтверждённых целей | не разрешать AoE | evidence TODO |
| aoeSafe | boolean | AoE не разрушит контроль | блокировать опасное AoE | evidence TODO |
| breakableCCNearby | boolean | рядом разрушаемый контроль | не считать отсутствие контроля | evidence TODO |
| targetTTD | number >=0 | оценка времени жизни | не считать бой долгим | estimator TODO |
| petExists | boolean | активный питомец | не рекомендовать зависимое от питомца | pet evidence TODO |
| petHealthPercent | number 0..100 | здоровье питомца | не подменять 100 | pet evidence TODO |
| petAttackingTarget | boolean | питомец атакует нужную цель | не утверждать обратное | pet evidence TODO |
| autoShotActive | boolean | автострельба активна | не предполагать состояние | combat evidence TODO |
| ready | map[canonical ability key] -> boolean? | агрегированная готовность (определить строго) | не разрешать действие | Eligibility integration TODO |
| known | map[canonical ability key] -> boolean? | изученность, отдельно от готовности | не считать изученным | SpellCatalogue integration TODO |

## Непреложные инварианты
- Boolean: `true`, `false`, `nil` различаются; `~= false` не означает подтверждённую безопасность.
- Number: только finite, в границах; NaN/Infinity/отрицательные TTD запрещены.
- `known`, `ready`, `usable`, `inRange`, `procActive` — разные факты; определить агрегирование совместно с Eligibility.
- Указывать источник, событие/TTL, потребителя и тест для **каждого** нового поля.
- При изменении поля: реестр → прямой provider GameState/GameAPI → профили (после согласованного переноса) → тесты → CHANGELOG.
- До согласования нельзя объявлять перечисленные кандидаты существующими сигналами.

## Контроль расхождений
BM сегодня использует snake_case и названия способностей в ready; MM/SV — camelCase и символьные ключи. Алиасы и runtime-адаптеры не использовать; канонические ключи зафиксировать в GameData Contract и переносить профили на них позднее.


## Hunter BM/MM/SV — исследование 2026-11-21

Подробный реестр по шести PVE-профилям Hunter, включая подтверждённые исходники, буквальные spellID, несовместимые поля, источники, открытые конфликты и тест-кейсы: [Hunter_Research_2026-11-21.md](Hunter_Research_2026-11-21.md). **SOURCE REVIEWED / WEB PARTIAL / IN-GAME NOT RUN**. Не переносить неизвестные свойства в рабочие таблицы как подтверждённые. Для полного заполнения этой таблицы требуются дополнительные проверки клиента и адаптера.


## Canonical API Matrix — binding rule (2026-11-21)

**Mandatory normative dictionary:** [Canonical_API_Matrix.md](Canonical_API_Matrix.md). This matrix defines canonical API capabilities and selected read-only methods, **not** the spellings of profile-facing state keys. Those are specified here in GameData Contract and verified against the engine implementation. The current GameData table contains earlier candidate names; interpret them through the canonical matrix, never invent aliases. Source-level archive review is documented in that matrix. New profiles must use lowerCamelCase `state` keys and PascalCase ability keys. An unknown provider must remain UNKNOWN, never be guessed. Implementation and client verification are separate statuses.

**Актуальная версия:** [Canonical_API_Matrix.md](Canonical_API_Matrix.md) **v14** заменяет прежний Kord-first выбор на утверждённую source-baseline. Не реализовывать кандидатные методы без проверки клиента. Имена являются проектным контрактом, не свидетельством работающего провайдера.

## Eligibility v14 #83 — активный cooldown (2.8.3a)

`AbilityEligibility` при **обычном опросе** `C_Spell.GetSpellCooldown(spellID)` не использует `SpellCooldownInfo.isOnGCD`: матрица v14 #83 разрешает доверять этому признаку **только во время SPELL_UPDATE_COOLDOWN**. Если `isActive=true`, способность `BLOCKED` с причиной `cooldown_active_unclassified`; категория индивидуальный/shared/GCD остаётся неизвестной. `isActive=false` даёт прохождение именно этой проверки. Независимая проверка GCD остаётся обязательной. `nil`, secret, ошибка и неполная структура не становятся READY. Дальнейшая реализация event-scoped классификации требует отдельного проверяемого контракта, а не догадки по snapshot. Это исправление **не меняет приоритеты классовых ротаций**.

## Изученность в Eligibility — v14 #19/#81 (2.8.3b)

Известность проверяется без временного адаптера ротаций: подтверждённая запись `SpellCatalogue` с `known=true` допускает дальнейшие проверки. Если запись отсутствует, `AbilityEligibility` запрашивает `C_SpellBook.IsSpellKnown(spellID, Enum.SpellBookSpellBank.Player)`. Только явное `false` этого метода даёт `BLOCKED/not_learned`; отсутствующий банк, метод, защищённый или `nil` ответ → `UNKNOWN/spell_known_unverified`. Это не утверждение, что алгоритм рангов (#20) полностью готов. Защищённый spellID отклоняется до `math.floor` и сравнений.

## v14 Eligibility — граница вывода и неизвестных сигналов (2.8.3c)

`AbilityEligibility:Evaluate(id,options)` не включает исходный Secret/некорректный Spell ID в возвращаемый объект `spellID`; для невалидного ID результат `UNKNOWN/invalid_spell_id`, `spellID=nil`. Перед индексированием/сравнением policy проверяются безопасность `options`, `target`, `cast`, `chargesRequired`; Secret policy → `UNKNOWN/options_protected` или `UNKNOWN/policy_protected`. Это внутренняя проверка данных, **не runtime-адаптер классовых ротаций**. `currentCharges` secret, nil/usability, nil/range не превращаются в ложные READY или BLOCKED; `UNKNOWN` сохраняется. Клиентская применимость и требования рангов по v14 ещё NOT RUN.

## Минимальный уровень и ранг — Eligibility v14 #20/#82 (2.8.3d)

Новый **необязательный** параметр правила `options.minLevel` задаёт требуемый минимальный уровень персонажа (целое число 1–100), а не оценку ранга заклинания. Если параметр отсутствует, новая проверка не влияет на ранее зарегистрированные правила. Если присутствует, `GameState.player.level` должен быть `READY`, обычным целым 1–100: ниже границы → `BLOCKED/player_level_too_low`; неизвестно/secret/нецелое → `UNKNOWN/player_level_unknown`; ошибочный `minLevel` → `UNKNOWN/level_policy_invalid`. Поле `minLevel` охраняется `GameAPI:IsSafeValue` до сравнений. По v14 #20 **проверка максимального изученного ранга отдельно НЕ реализована**: текущий `SpellCatalogue.rankNumber` может быть распознан из локализованной подписи и не доказывает семантику каждой версии клиента. Нельзя утверждать, что опциональная проверка уровня разрешает/определяет конкретный rank Spell ID.

## 2.8.3e — заряды и GCD: запрет косвенного восстановления данных

По v14 #26 `SpellChargeInfo.currentCharges` может быть защищённым, а `maxCharges` и `isActive` не доказывают количество доступных зарядов. `AbilityEligibility` считает заряд доступным только при **подтверждённом обычном целом** `currentCharges>0` и `maxCharges>=currentCharges`. `currentCharges=0` → BLOCKED; отсутствие/Secret/дробное/некорректный максимум → UNKNOWN. `isActive` не подменяет число зарядов. По v14 #25/§83 подтверждённый `GCD_SPELL_ID=61304` в исследовательской основе не прошёл клиентский тест: snapshot `C_Spell.GetSpellCooldown` должен вернуть обычный boolean `isActive`; при отсутствии/Secret → UNKNOWN, `isOnGCD` нельзя использовать вне события `SPELL_UPDATE_COOLDOWN`. Высший ранг (#20) не реализован, приоритеты профилей не меняются.

## 2.8.4 — контракт выполнения правил движка (mock CI PASS)
`RotationEngine:Evaluate()` запрашивает один `GameState:GetSnapshot()` на проход и отдаёт его в `AbilityEligibility:Evaluate(...,{stateSnapshot=snapshot})`. `GameState` с частично UNKNOWN разрешён; конкретные требования проверяются по каждому сигналу, не по глобальному READY. Отсутствие снимка/ошибка чтения — UNKNOWN, пустая очередь. Прямые вызовы Eligibility без снимка остаются совместимы.

Опциональное `rule.requires` — список до 8 уникальных объектов `{field="context.inGroup",equals=false}`; только булевы поля утверждённого прямого GameData: `player.moving`, `target.isPlayer`, `pet.exists`, `pet.dead`, `context.inGroup`, `context.inRaid`, `context.inInstance`. `READY` с совпадающим обычным boolean пропускает проверку; доказанное несовпадение = BLOCKED; любое недоступное, защищённое или неопределённое поле = UNKNOWN. Неизвестные имена отвергаются при регистрации, без alias-mapping. Это не реализация произвольных предусловий профилей.

`Eligibility` должен возвращать ровно `READY/BLOCKED/UNKNOWN` и тот же `spellID`; противоречие = UNKNOWN. CI: [run 44888049693](https://github.com/Vi22Rus/Kord/actions/runs/44888049693) на SHA `28104bbb9920fdba46170426e8c6eb621a243b17`, 9/9 Lua mock suites PASS. Клиентская проверка Forever = NOT RUN. Highest learned rank #20 открытый.

## Реализация провайдеров после диагностических тестов 2026-11-22

Следующие записи описывают **наличие кода**, не утверждают CLIENT PASS матрицы v14.

| Сигнал | Источник / способ | Ограничения | Состояние |
|---|---|---|---|
| `target.classification` | `UnitClassification("target")` в `GameState` | неизвестное/незнакомое значение → UNKNOWN | SOURCE IMPLEMENTED; в пользовательском trace при наличии цели READY |
| `player.travelAspect` | `ReadSignal("player.buff",5118)` (Cheetah) и `ReadSignal("player.buff",13159)` (Pack) | false только при двух достоверных отсутствиях; иные случаи UNKNOWN | SOURCE IMPLEMENTED; отдельный trace READY |
| `player.buff`, `target.debuff` | адресный SpellID lookup → проверенный `C_UnitAuras.GetUnitAuras` batch → `C_UnitAuras.GetAuraDataByIndex` (до 64) | snapshot target GUID; защищённые/неполные/неплотные данные → UNKNOWN; отрицательная полнота API ещё не доказана в игре | SOURCE IMPLEMENTED; новейший batch CLIENT NOT RETESTED |
| `pet.health.percent`, `resources.percent` | `UnitHealth/Max`, `UnitPower/Max` typed snapshot | секретные значения не оборачивать в число; на последнем игровом trace UNKNOWN | PARTIAL / NEEDS CLIENT RESEARCH |
| `target.melee` | `AbilityEligibility.Fact(2973,"inRange")` | подтверждение зависит от цели, слота/ранга API и клиентских ограничений | PARTIAL; иногда READY, иногда UNKNOWN |
| `target.ttd`, `hawk.count`, `hawk.oldestRemaining`, `aoe.safe` | подтверждённого провайдера нет | не выводить из уровня/отсутствия данных | NOT IMPLEMENTED |

`ActionBarScanner` — самостоятельный контракт: подтверждённая видимая кнопка + актуальный action slot + **точный SpellID**, с повторной проверкой. Совпадение локализованного имени допускается лишь для причины `visible_spell_rank_mismatch`, **не** для READY. Последний пользовательский тест показывает `action_slot_unconfirmed` для Hawk при видимой Ctrl+3 кнопке; до независимого подтверждения ID/слота исправление этого случая остаётся открытым.

