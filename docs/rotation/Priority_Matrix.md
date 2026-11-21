# Rotation Priority Matrix — все классы, специализации и контексты

Этот реестр — **спецификация до кода**, а не утверждение, что перечисленные действия оптимальны. Содержит только обоснованные правила, не выдуманные приоритеты для ещё не созданных классов.

| Profile ID | Context | Order | Phase | Preconditions (canonical GameData) | Action key/type | Reason | Failure/UNKNOWN policy | Evidence ID | Test ID | Status |
|---|---|---|---|---|---|---|---|---|---|---|
| HUNTER/BM/Leveling/PVE | solo | TODO | survival | actual aggro and health threshold | FeignDeath/spell (verify) | agreed solo safety policy | unknown aggro/HP must not be treated as true | TODO | TODO | NEEDS RECONCILIATION |
| HUNTER/BM/60/PVE | dungeon/raid | TODO | threat | actual aggro | FeignDeath/spell (verify) | agreed group safety policy | unknown aggro must not trigger | TODO | TODO | NEEDS RECONCILIATION |

## Контексты и сценарии
Для каждой реализации заполнить solo/open world, dungeon, raid; ST, AoE, CC nearby, melee/ranged/dead zone, movement, pull/combat, boss/short fight, low resource, pet/no pet, threat, unknown state. Leveling 1–59 и 60 — отдельные профили PVE; PVP — только отдельный профиль по явному согласованию.

## Шаблон нового правила
`profile ID → context → priority → phase → input signals → condition → spell/command → reason → nil policy → source fact ID → test ID`.

## Правило модульности
ClassCommon — общие правила класса; SpecCore только при реальном дублировании; Profile — различия режимов. Никакого обязательного BM_Core/MM_Core/SV_Core ради структуры. Изменение общей функции требует регрессии всех её потребителей.
