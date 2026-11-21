# GameData Contract — все классы

**Статус:** проектная таблица для согласования, не описание уже доступного игрового API. Источник фактического контракта: `Core/GameState.lua`, `Core/GameAPI.lua`, `Core/AbilityEligibility.lua`. Существующие `status=READY/UNKNOWN/UNAVAILABLE` нельзя бездумно превращать в boolean.

## Обязательные колонки
`key | type/range | meaning | source/API | READY value | false/zero | nil/UNKNOWN | refresh trigger | consumers | evidence | implementation status`.

**Нормализация:** один адаптер между GameState и Next. В профилях только утверждённые ключи; старые snake_case и camelCase — алиасы лишь внутри адаптера. Ниже — **кандидаты**, не утверждённый контракт; перед реализацией сверить с реальными потребителями.

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
- При изменении поля: реестр → адаптер → профили → тесты → CHANGELOG.
- До согласования нельзя объявлять перечисленные кандидаты существующими сигналами.

## Контроль расхождений
BM сегодня использует snake_case и названия способностей в ready; MM/SV — camelCase и символьные ключи. Решение об алиасах/канонических ключах принять при интеграции; не плодить преобразователи в каждом профиле.


## Hunter BM/MM/SV — исследование 2026-11-21

Подробный реестр по шести PVE-профилям Hunter, включая подтверждённые исходники, буквальные spellID, несовместимые поля, источники, открытые конфликты и тест-кейсы: [Hunter_Research_2026-11-21.md](Hunter_Research_2026-11-21.md). **SOURCE REVIEWED / WEB PARTIAL / IN-GAME NOT RUN**. Не переносить неизвестные свойства в рабочие таблицы как подтверждённые. Для полного заполнения этой таблицы требуются дополнительные проверки клиента и адаптера.
