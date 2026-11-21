# GameData Contract — все классы

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
| `context.instanceType` | `GetInstanceInfo()` second result, only after confirmed inInstance | #18/#90/#91 | UNKNOWN when instance type unavailable; `none` only outside instance |
| `pet.targetExists` | `UnitExists("pettarget")` | #30 | UNKNOWN when pet missing/unknown |
| `pet.attackingTarget` | `UnitIsUnit("pettarget","target")` after existence checks | #30 | UNKNOWN when relation unconfirmed |
| `ReadAutoShot(spellID).active` | `C_Spell.IsAutoRepeatSpell(spellID)` | #24 | UNKNOWN/UNAVAILABLE, no inferred swing |
| `ReadAutoShot(spellID).current` | `C_Spell.IsCurrentSpell(spellID)` | #24 | UNKNOWN/UNAVAILABLE, no queued inference |

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
