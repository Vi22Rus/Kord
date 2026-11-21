# Profile Registry — инвентарь и допуск к использованию

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
