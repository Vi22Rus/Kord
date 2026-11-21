# Profile Registry — инвентарь и допуск к использованию

**Утверждённый первый перенос и игровой пилот:** Hunter BM `Leveling` `PVE` (уровни 1–59) **после** канонического ядра v14 и `KordRotationDevTools`. Реестр содержит исходники других Hunter, но они не становятся активными автоматически и не загружаются ради проб. См. [две сборки](../BUILD_VARIANTS_AND_DIAGNOSTICS.md).

Нормативное имя: `Kord_<Class>_<Spec>_<Leveling|60>_<PVE|PVP>.lua`; PVP — отдельный профиль. ClassCommon и SpecCore — вспомогательные модули, не самостоятельные профили.

| Class | Spec | Mode | Content | File | Exists in GitHub | Registered/TOC | Game verified |
|---|---|---|---|---|---|---|---|
| HUNTER | BM | Leveling | PVE | Kord_Hunter_BM_Leveling_PVE.lua | YES | NO | NO |
| HUNTER | BM | 60 | PVE | Kord_Hunter_BM_60_PVE.lua | YES | NO | NO |
| HUNTER | MM | Leveling | PVE | Kord_Hunter_MM_Leveling_PVE.lua | YES | NO | NO |
| HUNTER | MM | 60 | PVE | Kord_Hunter_MM_60_PVE.lua | YES | NO | NO |
| HUNTER | SV | Leveling | PVE | Kord_Hunter_SV_Leveling_PVE.lua | YES | NO | NO |
| HUNTER | SV | 60 | PVE | Kord_Hunter_SV_60_PVE.lua | YES | NO | NO |

Другие восемь классов: **не создавать неподтверждённые профили**. При старте каждого класса добавить записи для реально согласованных специализаций и режимов; 9×3=27 — проектная цель специализаций, не утверждение о 27 готовых Lua-файлах. Определение спека — по очкам талантов, с политикой ничьей/unknown из PROJECT_CONTEXT.

## Карточка каждого профиля
`profile id | version | client/server build | class/spec | level range | content | role | source register | ability register | GameData dependencies | priority matrix | CFG keys | module dependencies | TOC | registration | test IDs | static/unit/integration/in-game status | open questions`.

**Ни один существующий Hunter-профиль не помечен интегрированным или проверенным в игре.** Статусы обновлять только по доказательствам.


## Hunter BM/MM/SV — исследование 2026-11-21

Подробный реестр по шести PVE-профилям Hunter, включая подтверждённые исходники, буквальные spellID, несовместимые поля, источники, открытые конфликты и тест-кейсы: [Hunter_Research_2026-11-21.md](Hunter_Research_2026-11-21.md). **SOURCE REVIEWED / WEB PARTIAL / IN-GAME NOT RUN**. Не переносить неизвестные свойства в рабочие таблицы как подтверждённые. Для полного заполнения этой таблицы требуются дополнительные проверки клиента и адаптера.
