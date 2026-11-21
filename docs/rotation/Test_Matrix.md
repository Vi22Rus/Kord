# Test Matrix — от unit до WoW Forever

| Test ID | Scope | Scenario | Inputs / setup | Expected action + reason | Static | Unit | Integration | In-game | Evidence/log |
|---|---|---|---|---|---|---|---|---|---|
| CORE-001 | all profiles | state=nil | nil | safe nil / documented no recommendation, no crash | NOT RUN | NOT RUN | NOT RUN | NOT RUN | TODO |
| CORE-002 | all profiles | moving=nil | cast requiring stationary | no unsafe cast | NOT RUN | NOT RUN | NOT RUN | NOT RUN | TODO |
| CORE-003 | all profiles | unknown ready | ready[key]=nil | no unverified ability | NOT RUN | NOT RUN | NOT RUN | NOT RUN | TODO |
| CORE-004 | all profiles | invalid CFG | unexpected enum/number | validated fallback, no crash | NOT RUN | NOT RUN | NOT RUN | NOT RUN | TODO |
| CORE-005 | all profiles | missing binding | valid action, no bound button | safe UI status; no invented key | NOT RUN | NOT RUN | NOT RUN | NOT RUN | TODO |
| HUNTER-001 | BM/MM/SV | CC near AoE | breakableCCNearby=true | no unsafe AoE; safe ST if eligible | NOT RUN | NOT RUN | NOT RUN | NOT RUN | TODO |
| HUNTER-002 | BM/MM/SV | solo aggro + high HP | solo, aggro=true, HP high | no premature Feign Death per agreed policy | NOT RUN | NOT RUN | NOT RUN | NOT RUN | TODO |
| HUNTER-003 | BM/MM/SV | dungeon aggro | dungeon=true, aggro=true | evaluate Feign Death if known/eligible | NOT RUN | NOT RUN | NOT RUN | NOT RUN | TODO |
| HUNTER-004 | BM/MM/SV | pet absent | petExists=false | no pet-dependent attacks | NOT RUN | NOT RUN | NOT RUN | NOT RUN | TODO |
| PROFILE-001 | all | level boundary | level 59 then 60 | correct profile only | NOT RUN | NOT RUN | NOT RUN | NOT RUN | TODO |
| PROFILE-002 | all | invalid target | dead/friendly/no target | no harmful recommendation | NOT RUN | NOT RUN | NOT RUN | NOT RUN | TODO |
| INTEGRATION-001 | all | real TOC load | addon startup | common before dependent profiles | NOT RUN | NOT RUN | NOT RUN | NOT RUN | TODO |
| INTEGRATION-002 | all | recommendation chain | GameData→Next→Eligibility→BindingResolver→UI | consistent action/phase/reason | NOT RUN | NOT RUN | NOT RUN | NOT RUN | TODO |

## Обязательное покрытие
Для каждого профиля добавить отдельные проверки: уровень, talents/runes, ST/AoE, CC, TTD, движение, ресурс, range, proc, угрозу, питомца, пулл, смерть, бой, unknown, неверный CFG, отсутствующий bind. Для танков — mitigation/taunt, для хилов — friendly target/heal urgency, для DPS — damage priorities; только при появлении соответствующих классов.

**PASS** только с фактическим тестом и логом; **NOT RUN** — не проверено; **FAIL** — воспроизводимый сбой. Изменение общего контракта запускает регрессию всех зависимых профилей. Игровой тест выполняется на реальном клиенте и не выводится из Lua-моков.


## Hunter BM/MM/SV — исследование 2026-11-21

Подробный реестр по шести PVE-профилям Hunter, включая подтверждённые исходники, буквальные spellID, несовместимые поля, источники, открытые конфликты и тест-кейсы: [Hunter_Research_2026-11-21.md](Hunter_Research_2026-11-21.md). **SOURCE REVIEWED / WEB PARTIAL / IN-GAME NOT RUN**. Не переносить неизвестные свойства в рабочие таблицы как подтверждённые. Для полного заполнения этой таблицы требуются дополнительные проверки клиента и адаптера.
