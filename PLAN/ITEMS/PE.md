# Карточки PE

Источник: REQUIREMENTS.md, blob 9efdec1900398c978ea121818fb5950cb1620337.

### PE-01 — Питомец существует, жив, в зоне видимости, активен

ID: [PE-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4251). Приоритет: P1. Lua: упомянут (точный статус в источнике).

**Вердикт / статус**

**Вердикт**

**ЧАСТИЧНО РЕАЛИЗОВАНО — ДОРАБОТАТЬ (P1).** Kord уже отслеживает pet exists/GUID/dead/health/target и события `UNIT_PET`/`PET_BAR_UPDATE`, но нет доказанного независимого `visible`, `active/actionable`, `controllable` и строгой pet capability readiness.

**Архитектурные ссылки:** GR-01, GR-02, TH-01, TH-03, SP-14. Обратные ссылки внесены в эти требования в том же коммите.

**Изменения Lua:** отсутствуют. Только документация.

**Выбранный путь Kord**

**Выбранный путь Kord (решение по сравнению)**

**Основа — существующий `GameState.pet` + JustAC `actionable` как отдельное состояние + RotationMaster owner-scoped `UNIT_PET`/pet spell refresh + Sonah GUID-scoped reset + ForeverAuras pet-bar invalidation.** Ввести единый логический `PetObservation(ownerGUID,petGUID)` поверх GameAPI/GameState, не отдельный scanner. Состояния: `exists` подтверждается `UnitExists("pet")`; `alive` — только `UnitIsDeadOrGhost("pet")` при confirmed exists; `visible` — только валидированным `UnitIsVisible("pet")`, не через наличие `pettarget`/range; `active/actionable` — конъюнкция **доказанных** условий (exists, alive, owner identity, не dismissed/stale, pet UI/actionbar/vehicle/mount constraints только если проверены клиентом). Если actionability нельзя доказать, `UNKNOWN(pet_actionability_unverified)`; не объявлять pet absent. `controllable` отдельно от `active`: guardians могут существовать без pet bar. Смена `petGUID` немедленно инвалидирует aura/health/target/abilities/threat memo; `UNIT_PET("player")` обновляет owner-scoped pet revision, `PET_BAR_UPDATE` — pet capability revision. `PLAYER_ENTERING_WORLD`, mount/vehicle/zone и подтверждённые pet events — coalesced invalidation. Проверить, может ли Forever надёжно читать `UnitIsVisible` и pet UI APIs, не копировать retail-специфичные assumptions. `pet.exists=false` допускается только при доказанном UnitExists=false; pet active UNKNOWN не означает отсутствие pet. `AbilityEligibility` — единственный final READY для pet spells; пет-команды не рекомендовать по одной лишь видимости/живости. Различать summonable temporary units и controlled pet, не считать totems в `pet` без подтверждённой семантики.

**Требуемые изменения (полный текст)**

**Требуемые изменения**

1. Расширить существующий `GameState.pet` единым `PetObservation` с независимыми `exists/alive/visible/active/controllable`, petGUID/ownerGUID, source, reason и revision; не создавать новый pet scanner.
2. Проверить на Forever `UnitExists`, `UnitGUID`, `UnitIsDeadOrGhost`, `UnitIsVisible`, `HasPetUI`, `GetPetActionInfo`, `UnitHasVehicleUI`, `IsMounted`, `PET_BAR_UPDATE`, secret/nil и временные особенности mount/vehicle.
3. Добавить в GameAPI allowlist только подтверждённые вызовы; отдельные statuses `UNKNOWN` для visible/actionable/controllable, без fail-open.
4. EventBus: owner-scoped `UNIT_PET("player")`, `PET_BAR_UPDATE`, pet health/death/target/identity revisions, entering world/mount/vehicle invalidation по подтверждённым событиям.
5. Общий pet capability/ability gate по pet actionbar, known rank, cooldown, usability, target/range; final READY остаётся AbilityEligibility, не в профиле/провайдере.
6. Согласовать TH-01/TH-03 pet actor threat, GR-01/GR-02 roster distinction и будущие pet-heal/pet-revive профили с единым pet GUID, без дублирования.
7. Lazy `Needs.pet`, per-evaluation memo и GUID guard, bounded refresh; не переносить старый health/auras/ability state на нового питомца.
8. DevTools-only диагностика: `pet_exists_unknown`, `pet_guid_changed`, `pet_dead_unknown`, `pet_visible_unknown`, `pet_actionability_unverified`, `pet_inactive_confirmed`, `pet_controllability_unknown`, `pet_actionbar_unavailable`, `pet_mount_stale_unit`, `pet_vehicle_state_unknown`, `pet_owner_mismatch`.
9. Тесты: pet absent/present/dead/ghost, visible vs out-of-view, active vs inactive, mount/dismount transient UnitExists, vehicle, pet dismissed, resummon new GUID, same pet alias recycled, pet UI absent, actionbar missing, guardian/totem/summoned swarm, secret/nil API, hunter/warlock pet, mage elemental, pet revive/heal, threat attribution, cooldown, rapid UNIT_PET/PET_BAR_UPDATE, stale revision, no protected actions.

**Тесты и диагностика**

в файле не указано

**Архитектурные и обратные ссылки:** CL-08, PE-06, PE-05, PE-04, PE-03, PE-02, TH-01, TH-03, GR-01, GR-02, SP-14.

---

### PE-02 — Здоровье, фокус/мана, настроение (для охотника)

ID: [PE-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4313). Приоритет: P1. Lua: упомянут (точный статус в источнике).

**Вердикт / статус**

**Вердикт**

**ЧАСТИЧНО РЕАЛИЗОВАНО — ДОРАБОТАТЬ (P1).** Kord уже наблюдает здоровье питомца и допускает health percent, но pet-specific typed power/focus/mana и hunter happiness не реализованы как подтверждённые общие факты.

**Архитектурные ссылки:** PE-01, GR-02, GR-05, SP-14, TH-01. Обратные ссылки внесены в эти требования в том же коммите.

**Изменения Lua:** отсутствуют. Только документация.

**Выбранный путь Kord**

**Выбранный путь Kord (решение по сравнению)**

**Выбрать единый PE-01 `PetObservation`, расширенный `PetVitalsObservation` и `PetHappinessObservation` как логические поля того же snapshot; Kord GameState/GameAPI — numeric validation, RotationMaster — edition-gated secret-safe mood provider, Sonah — classic happiness thresholds и hunter upkeep, JustAC — API probe/диагностика.** Pet health использует существующий `cleanHealth("pet")`; pet power определяется **сначала** `UnitPowerType("pet")`, затем `UnitPower/Max("pet", confirmedType)`, native `UnitPowerPercent` только с валидированной Forever curve и type. Max=0/secret/nil не объявлять «0 focus» или «0 mana»; `powerType=UNKNOWN` блокирует типозависимые решения. Happiness читается **только если** hunter + confirmed controlled pet + API supported + edition feature exists; проверить отдельно `GetPetHappiness` и `C_PetInfo.GetPetHappiness` на Forever и диапазон 1..3; если оба отсутствуют, `UNKNOWN(happiness_api_unavailable)`, а не «доволен». `UNIT_HAPPINESS` инвалидирует только mood revision, `UNIT_POWER_*` — pet power, `UNIT_HEALTH` — pet health, `UNIT_PET("player")`/petGUID change — **все** pet facts. `PET_BAR_UPDATE` обновляет capability и при необходимости identity; events использовать после клиентской проверки. Lazy `Needs.petVitals`/`Needs.petHappiness`, per-evaluation memo, без дополнительных scans. Feed Pet reminder — отдельная политика по confirmed unhappy/content, out-of-combat, pet alive/active и доступной еде; **не** выводить READY заклинания из mood. Итоговый ability READY — общий `AbilityEligibility`.

**Требуемые изменения (полный текст)**

**Требуемые изменения**

1. Расширить PE-01 `PetObservation` полями health, `powerType/current/max/percent`, `happiness`, независимыми statuses, provenance, petGUID/revision, без второго pet scanner.
2. Проверить на Forever `UnitHealth/Max/Percent("pet")`, `UnitPowerType/Power/PowerMax/PowerPercent("pet")`, secret/nil, focus/mana semantics, zero max, numeric bounds.
3. Проверить `GetPetHappiness`, `C_PetInfo.GetPetHappiness`, `UNIT_HAPPINESS`, supported editions, return range 1..3 и поведение при non-hunter/absent/dead pet.
4. Добавить в GameAPI только подтверждённый mood API; реализовать edition-gated `PetHappinessObservation` с `UNKNOWN` и без class-based mood inference.
5. Расширить GameState/RotationConditions typed pet power и mood с lazy `Needs`, не переносить player power type и не использовать secret как число.
6. EventBus per-pet health/power/happiness revisions, `UNIT_PET` owner GUID invalidation, pet swap and resummon, coalescing и bounded evaluation.
7. Согласовать pet heal, Mend Pet, Feed Pet, revive и pet ability costs с общим PE-01/PE-02; финальное READY через AbilityEligibility.
8. DevTools-only диагностика: `pet_health_secret`, `pet_health_invalid`, `pet_power_type_unknown`, `pet_power_secret`, `pet_power_max_zero`, `pet_happiness_api_unavailable`, `pet_happiness_secret`, `pet_happiness_out_of_range`, `pet_happiness_not_applicable`, `pet_vitals_guid_changed`, `pet_mood_changed`.
9. Тесты: hunter pet happy/content/unhappy, Feed Pet OOC vs combat, warlock pet without hunter happiness, no pet, dead pet, mounted/vehicle/inactive, focus/mana/other power, powerType change, zero max, secret numeric with native percent, API missing, edition disabled, rapid `UNIT_HAPPINESS` and power events, GUID swap/resummon, stale memo, owner mismatch, no duplicate scans/protected actions.

**Тесты и диагностика**

в файле не указано

**Архитектурные и обратные ссылки:** IT-09, SW-04, PE-05, PE-04, PE-03, PE-01, GR-02, GR-05, SP-14, TH-01.

---

### PE-03 — Что атакует питомец, режим (атака, защита, пассив)

ID: [PE-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4373). Приоритет: P1. Lua: упомянут (точный статус в источнике).

**Вердикт / статус**

**Вердикт**

**ЧАСТИЧНО РЕАЛИЗОВАНО — ДОРАБОТАТЬ (P1).** Kord умеет проверять наличие `pettarget` и совпадение с `target`, но не определяет надёжно факт атаки и активный режим поведения питомца.

**Архитектурные ссылки:** PE-01, PE-02, TH-01, TH-03, SP-14. Обратные ссылки внесены в эти требования в том же коммите.

**Изменения Lua:** отсутствуют. Только документация.

**Выбранный путь Kord**

**Выбранный путь Kord (решение по сравнению)**

**Основа — PE-01 `PetObservation` + ForeverAuras активная pet stance button и `UNIT_TARGET("pet")` + JustAC pet-target comparison + RotationMaster осторожные `PET_ATTACK_START/STOP` и pet action API guards + существующий Kord GameState.** Добавить логические поля `PetTargetObservation`, `PetAttackActivityObservation`, `PetStanceObservation` в **тот же petGUID-scoped snapshot**, без второго scanner. Для target: читать `UnitExists("pettarget")`, `UnitGUID("pettarget")`, после чтения подтверждать, что petGUID и target GUID не сменились; `attackingPlayerTarget` переименовать/сопроводить корректной семантикой `petTargetMatchesPlayerTarget` и отдельно хранить `isAttacking`. Для атаки: использовать `PET_ATTACK_START/STOP` только как **событийное свидетельство** с TTL/revision; при пропущенном STOP, смене цели, потере pet или неоднозначном combat вернуть `UNKNOWN(attack_state_unverified)`, а не устойчивый true. `UnitAffectingCombat("pet")` — отдельный combat факт, не равен attack-on-GUID. Для stance: читать только confirmed active mode tokens из `GetPetActionInfo`, хранить raw token и нормализованное значение; не угадывать при missing/secret/нескольких active mode buttons. Проверить реальные mode token names и events на Forever, включая `PET_BAR_UPDATE` и возможный `PET_BAR_UPDATE_USABLE`; режим `ASSIST` может быть самостоятельным и не должен автоматически теряться. Смена petGUID/owner, `UNIT_PET("player")`, `UNIT_TARGET("pet")`, mode/bar events и confirmed attack events инвалидируют соответствующие revisions. Lazy `Needs.petTarget/petStance`, per-pass memo, bounded action-slot scan **только при необходимости**, без постоянного polling. Никаких protected pet mode commands; итоговый pet action READY остаётся у `AbilityEligibility`.

**Требуемые изменения (полный текст)**

**Требуемые изменения**

1. Расширить PE-01/PE-02 **тот же** PetObservation полями `petTargetGUID`, `petTargetMatchesPlayerTarget`, `isAttacking`, `stance/rawToken`, независимыми statuses/reasons/revisions.
2. Исправить/уточнить семантику `pet.attackingTarget` в GameState/RotationConditions: фактически это `pettarget == target`, не подтверждённая атака; обеспечить совместимость профилей.
3. Проверить на Forever `GetPetActionInfo`, `NUM_PET_ACTION_SLOTS`, `PET_MODE_*`, `isActive`, secret/nil, `UNIT_TARGET("pet")`, `PET_ATTACK_START/STOP`, `PET_BAR_UPDATE` и особенности отсутствия STOP.
4. Ввести общий secret-safe pet actionbar/mode adapter с active-token validation и явным `UNKNOWN`; переиспользовать PE-01 pet capability, не создавать новый actionbar scanner.
5. Реализовать GUID-safe `PetTargetObservation` и отдельный `PetAttackActivityObservation`; событие attack start не является вечным доказательством атаки конкретного GUID.
6. EventBus: pet target/mode/attack revisions, owner-scoped `UNIT_PET`, petGUID reset, TTL для событий и coalescing; не сканировать action slots на каждом кадре.
7. Согласовать pet threat TH-01/TH-03 и AbilityEligibility SP-14; passive mode может влиять на policy рекомендации, но не доказывает cooldown/готовность команды.
8. DevTools-only диагностика: `pet_target_guid_unknown`, `pet_target_changed`, `pet_target_matches_player`, `pet_attack_state_unknown`, `pet_attack_stop_missing`, `pet_stance_unknown`, `pet_stance_token_unverified`, `pet_stance_changed`, `pet_actionbar_secret`, `pet_mode_multiple_active`, `pet_guid_changed`.
9. Тесты: pet absent/dead/inactive, no pettarget, pettarget equals/differs from player target, target GUID recycled, pet attacking mob A while player targets B, target present but idle, combat without attack, attack start with missing stop, stance aggressive/defensive/passive/assist/defensive-assist, no mode button, multiple active, secret/nil API, missing pet actionbar, pet resummon/GUID change, owner UNIT_PET, rapid target changes, stale event, protected commands never invoked.

**Тесты и диагностика**

в файле не указано

**Архитектурные и обратные ссылки:** SW-01, PE-06, PE-05, PE-04, PE-01, PE-02, TH-01, TH-03, SP-14.

---

### PE-04 — Способности питомца: кулдаун, автокаст включён, команды

ID: [PE-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4431). Приоритет: P1. Lua: упомянут (точный статус в источнике).

**Вердикт / статус**

**Вердикт**

**ЧАСТИЧНО РЕАЛИЗОВАНО — ДОРАБОТАТЬ (P1).** Kord имеет базовые pet existence/target facts, общую spell cooldown проверку и событие PET_BAR_UPDATE, но не реализует подтверждённые pet-slot cooldown, autocast allowed/enabled и доступность команд как общий pet action observation.

**Архитектурные ссылки:** PE-01, PE-02, PE-03, SP-14, TH-01, TH-03. Обратные ссылки внесены в эти требования в том же коммите.

**Изменения Lua:** отсутствуют. Только документация.

**Выбранный путь Kord**

**Выбранный путь Kord (решение по сравнению)**

**Один `PetActionbarObservation(petGUID,actionbarRevision)` внутри PE-01 PetObservation**: общий bounded slot scan `GetPetActionInfo` обеспечивает PE-03 режимы/команды и PE-04 spell/autocast; `PetActionCooldownObservation(petGUID,slot)` — guarded `GetPetActionCooldown` из RotationMaster, `PetActionUsabilityObservation` — guarded `GetPetActionSlotUsable` (если существует на Forever), `PetAutocastObservation` — `autoCastAllowed/autoCastEnabled` из ForeverAuras. Никакого второго pet actionbar scanner и никакого автоматического переключения autocast. Проверить на Forever фактические поля `GetPetActionInfo`, различия `isToken`, `spellID` vs rank, слоты `NUM_PET_ACTION_SLOTS`, специальные command tokens `PET_ACTION_ATTACK/FOLLOW/STAY` и `PET_MODE_*`, доступность cooldown/usability APIs и события. Команды моделировать **как read-only availability/active state**, а не как spellID: `PetAttack` не является заклинанием с обычным cooldown. Для pet spell readiness учитывать PE-01 active/controllable, PE-02 typed pet resource, learned pet action slot, usable, cooldown, range/target/LOS где подтверждены, и autocast как отдельную политику (ручная рекомендация не должна ошибочно дублировать активный автокаст). Не переносить `GetSpellCooldown` на pet slot без проверки. `UNKNOWN` в любом критичном факте запрещает объявлять `READY`; финальный gate — **AbilityEligibility**, не профиль. GUID change сбрасывает slot map, cooldown, autocast, stance; `PET_BAR_UPDATE` инвалидирует inventory и autocast; подтверждённые pet cooldown/usable events — соответствующие revisions, с bounded lazy `Needs.petActions` и per-pass memo. Pet mode/command recommendations только как информация, не protected actions.

**Требуемые изменения (полный текст)**

**Требуемые изменения**

1. Переиспользовать **один** pet actionbar adapter PE-01/PE-03, расширить slot record PE-04 полями cooldown, usable, autocastAllowed/enabled, command token, status/reason; не дублировать сканирование.
2. Проверить Forever API `GetPetActionInfo`, `GetPetActionCooldown`, `GetPetActionSlotUsable`, `NUM_PET_ACTION_SLOTS`, slot tuple, pet spellID/rank, isToken/isActive, secret/nil, отсутствующий pet bar.
3. Добавить только подтверждённые pet APIs в GameAPI allowlist, безопасные `pcall`/validated outcome, различать `UNKNOWN`, `BLOCKED`, `NOT_APPLICABLE`.
4. Разработать `PetActionCooldownObservation` по **slot**, не считать обычный `GetSpellCooldown` доказательством pet cooldown; учесть start/duration/enabled и источник времени.
5. Разработать `PetAutocastObservation` по slot, различать allowed/enabled, обновлять на подтверждённых autocast/bar events, не переключать автоматически.
6. Разделить spell, command и stance action types; командный availability не объявлять spell READY; не вызывать protected pet actions.
7. Расширить общий AbilityEligibility pet spell branch с PE-01/02/03/04 фактами, ресурсом, range, cooldown и suppression duplicate autocast suggestions; один итоговый READY.
8. EventBus petGUID/actionbar/cooldown/autocast revisions, owner `UNIT_PET`, `PET_BAR_UPDATE`, confirmed cooldown/usable/autocast events, lazy `Needs.petActions`, bounded scan и per-evaluation memo.
9. DevTools-only диагностика: `pet_actionbar_unknown`, `pet_action_slot_missing`, `pet_action_spellid_unknown`, `pet_action_cooldown_unknown`, `pet_action_cooldown_active`, `pet_action_usable_unknown`, `pet_autocast_allowed_unknown`, `pet_autocast_enabled_unknown`, `pet_autocast_active`, `pet_command_token_unknown`, `pet_action_guid_changed`, `pet_action_duplicate_scan_suppressed`.
10. Тесты: hunter/warlock pets, absent/dead/inactive/guardian, pet swap GUID, same spell different slot, rank mismatch, slot spell vs command vs stance, autocast allowed/enabled combinations, toggling autocast by user, cooldown active/ready/disabled, usable false/secret, missing cooldown API, actionbar changes, mode changes PE-03, pet resource low, pet range/target, pet spell in normal spellbook vs pet bar, missing `PET_BAR_UPDATE`/event burst, no per-frame scan, no protected commands.

**Тесты и диагностика**

в файле не указано

**Архитектурные и обратные ссылки:** CL-08, AC-03, PE-01, IT-10, IT-01, SW-01, PE-06, PE-05, PE-03, PE-02, SP-14, TH-01, TH-03.

---

### PE-05 — Время отзыва, воскрешения, лечения питомца

ID: [PE-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4497). Приоритет: P2. Lua: упомянут (точный статус в источнике).

**Вердикт / статус**

**Вердикт**

**ЧАСТИЧНО РЕАЛИЗОВАНО — ДОРАБОТАТЬ (P2).** Kord имеет player cast/cooldown events, базовый pet health/life и API для spell information, но не подтверждён единый pet-care timing для Dismiss/Revive/Mend, live cast remaining, Mend aura remaining и доказательное различение pet transitions.

**Архитектурные ссылки:** PE-01, PE-02, PE-03, PE-04, SP-14, GR-05. Обратные ссылки внесены в эти требования в том же коммите.

**Изменения Lua:** отсутствуют. Только документация.

**Выбранный путь Kord**

**Выбранный путь Kord (решение по сравнению)**

**Один логический `PetCareTimingObservation(petGUID,careActionFamily)` поверх PE-01/02/04, общего `CastObservation` GameState, `AuraObservation` GR-03/GR-04 и единого cooldown provider AbilityEligibility.** Отдельные поля `castDuration/remaining`, `lastStartedAt`, `lastSucceededAt`, `auraDuration/remaining`, `cooldownRemaining`, `petIdentityTransitionAt`, каждый со `status/source/reason/revision`; все времена в секундах после подтверждённого преобразования из клиентских миллисекунд, часы — единый валидированный monotonic `GetTime`. События `UNIT_SPELLCAST_START/STOP/SUCCEEDED/FAILED/INTERRUPTED` коррелировать по подтверждённым `spellID` и `castGUID` (если клиент даёт), при несопоставимости — UNKNOWN. `UnitCastingInfo("player")` / `UnitChannelInfo("player")` дают live remaining только при валидированных start/end и spell identity; `C_Spell.GetSpellInfo.castTime` — **базовая справка**, не текущий remaining. Для Mend: подтверждённая `HELPFUL` аура на `pet` и её expiration — авторитетный remaining; при secret aura — `UNKNOWN`, с ограниченным `postcast_grace` лишь для подавления дубликатов, а не ложного утверждения «бафф активен». Для Dismiss: подтверждённый success + PE-01 pet transition, но не один `UnitExists=false`; для Revive: подтверждённый dead pet + success + новая валидная identity/active observation. Если нет событий или petGUID сменился, stale timing сбрасывать, без обратного вычисления из одного health increase.

Отдельная `PetCareNeedPolicy` выбирает `DISMISS/REVIVE/CALL/MEND/NO_ACTION/UNKNOWN`: Dismiss только при явной политике (например, подтверждённый талант Lone Wolf), Revive только при подтверждённой смерти, Call при доказанном отсутствии и применимости, Mend при доказанном HP threshold и отсутствии подтверждённого достаточного текущего HoT; при UNKNOWN не объявлять READY. Проверить клиентскую возможность лечения во время боя, cast interruption, range, learned highest rank, GCD/cooldown/resources и отсутствие двойных рекомендаций. Итоговый READY — только `AbilityEligibility`; без protected casts, dismiss и summon commands.

**Требуемые изменения (полный текст)**

**Требуемые изменения**

1. Переиспользовать PE-01 petGUID, PE-02 health, PE-04 spell/cooldown, общий cast/aura reader; **не создавать** отдельный pet scanner или cooldown provider.
2. Валидировать на Forever Dismiss/Revive/Mend spellIDs/ranks, `GetSpellInfo.castTime`, `UnitCastingInfo/UnitChannelInfo` start/end/castGUID, `UNIT_SPELLCAST_*`, aura expiration, `GetTime` и secret/nil.
3. Ввести `PetCareTimingObservation` с независимыми cast, since-success, aura remaining, cooldown remaining, pet transition и явными UNKNOWN; не смешивать duration и cooldown.
4. Реализовать событийную корреляцию castGUID/spellID/petGUID с проверкой identity до/после события; `UNIT_PET("player")` сбрасывает устаревшие записи.
5. Для Mend Pet переиспользовать единый helpful aura reader и семейство applied auraIDs/ranks; postcast grace только для предотвращения повторной подсказки, не как доказательство активного HoT.
6. Разделить Dismiss vs Revive vs Call по PE-01 confirmed alive/dead/absent/active, не считать mount/vehicle исчезновением после Dismiss.
7. Разработать `PetCareNeedPolicy` с конфигурируемым порогом Mend и class/talent applicability, при UNKNOWN не выдумывать heal/death; финальный READY только AbilityEligibility.
8. EventBus lazy `Needs.petCareTiming`, cast/aura/pet/cooldown revisions, bounded event history и per-evaluation memo; не запускать бесконечные таймеры/OnUpdate polling.
9. DevTools-only диагностика: `pet_care_cast_timing_unknown`, `pet_care_cast_guid_mismatch`, `pet_care_last_success_unknown`, `pet_care_aura_secret`, `pet_care_mend_remaining_unknown`, `pet_care_postcast_grace`, `pet_care_cooldown_unknown`, `pet_care_dismiss_transition_unverified`, `pet_care_revive_transition_unverified`, `pet_care_pet_guid_changed`, `pet_care_need_unknown`.
10. Тесты: Dismiss success/failed/interrupted, pet missing after mount/vehicle vs actual dismiss, Revive dead vs missing, new petGUID after revive, Call after dismiss, Mend active HoT/expired/secret, heal at threshold and near threshold, spell rank changes, cast time changes, no castGUID, cast start without success, cooldown vs aura duration, 5s anti-repeat, multiple rapid casts, pet resummon during cast, combat restrictions, insufficient mana, unavailable API, no protected actions.

**Тесты и диагностика**

в файле не указано

**Архитектурные и обратные ссылки:** IT-09, IT-05, IT-03, IT-02, IT-01, SW-03, SW-02, SW-01, PE-06, GR-05, PE-01, PE-04, GR-03, GR-04, PE-02, PE-03, SP-14.

---

### PE-06 — Тотемы и стражи: какие стоят, оставшееся время, в радиусе ли

ID: [PE-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4568). Приоритет: P2. Lua: упомянут (точный статус в источнике).

**Вердикт / статус**

**Вердикт**

**НЕ РЕАЛИЗОВАНО КАК УНИВЕРСАЛЬНАЯ ВОЗМОЖНОСТЬ — ДОРАБОТАТЬ (P2).** Kord имеет общие часы, spell metadata и базовые события pet/aura, но не содержит доказанного totem-slot reader, guardian lifecycle observation, оставшегося времени и проверки summon-to-target radius.

**Архитектурные ссылки:** PE-01, PE-03, PE-04, PE-05, GR-06, SP-14, EN-03. Обратные ссылки внесены в эти требования в том же коммите.

**Изменения Lua:** отсутствуют. Только документация.

**Выбранный путь Kord**

**Выбранный путь Kord (решение по сравнению)**

**Единый логический `SummonedEntityObservation(ownerGUID,sourceKind,key)` с двумя адаптерами источника: `TotemSlotObservation(slot)` на основе RotationMaster + ForeverAuras и `GuardianLifecycleObservation(summonGUID/spellFamily)` только при подтверждённых клиентских событиях/identity evidence.** Не создавать отдельный scanner на класс или призыв; слотные тотемы обновлять по `PLAYER_TOTEM_UPDATE(slot)`, guardian lifecycle — по подтверждённым combat-log summon/death/dismiss/zone signals и только при доступных несекретных GUID, с ограниченным TTL. **Не считать каст призыва доказательством появления guardian**, а истечение ожидаемой длительности — подтверждённой смертью: `ESTIMATED`/UNKNOWN отдельно от `CONFIRMED`. Для тотемов хранить `slot,spellID,name,start,duration,expiration,modRate` с проверкой фактического формата Forever; `GetTotemDuration` может возвращать duration object — не использовать арифметику без валидированного извлечения. При secret slot — последний подтверждённый record как `STALE/ESTIMATED`, не как live `PRESENT_CONFIRMED`; если слота нет или его state нечитабелен, `UNKNOWN`. Семейства рангов и slot replacement берутся из проверенного spell catalog, один активный record на slot с атомарной заменой и revision.

**Радиус — отдельный `SummonEffectCoverageObservation(summonKey,targetGUID,effectFamily)`**, переиспользующий GR-06 общий spatial/effect coverage provider. Различать `caster-to-target cast range`, `summon-to-target effect radius`, `summon attack reach`, `guardian pursuit range`, `group buff effect`; они не взаимозаменяемы. Без подтверждённого summon anchor, target location, spell-specific radius/LOS или доказанной aura effect на target возвращать `UNKNOWN(summon_geometry_unavailable)`; aura presence может доказывать **получение эффекта**, но не универсальную геометрическую близость для иных целей. Не вычислять точный радиус по таймеру/имени тотема или факту установки. Не делать вывод о guardian alive/target по `pet` unit token. Общие event coalescing, GUID/slot revision, lazy `Needs.summons` и `Needs.summonCoverage`, per-evaluation memo и bounded slot scans. Финальная рекомендация обновить тотем/призвать стража — только после `AbilityEligibility`.

**Требуемые изменения (полный текст)**

**Требуемые изменения**

1. Ввести единый `SummonedEntityObservation` и **один** slot adapter для всех тотемов, не дублировать class-specific scans; guardian adapter отдельный источник того же контракта.
2. Проверить Forever `GetTotemInfo`, `GetNumTotemSlots`, `GetTotemDuration`, duration objects, secret fields, `PLAYER_TOTEM_UPDATE`, spellID/rank/slot/expiration semantics.
3. Добавить подтверждённые API в GameAPI allowlist с status/source/reason и `ESTIMATED` vs `CONFIRMED`; секретный слот не превращать в absent.
4. Реализовать slot replacement, spell family mapping, timestamp validation, expiration remaining и bounded per-slot revisions; кэш не считать live proof.
5. Проверить Forever guardian summon/owner GUID events, lifecycle и despawn evidence; при отсутствии доказательного API возвращать `UNKNOWN`, не использовать `pet` вместо guardian.
6. Переиспользовать GR-06 spatial coverage contract для spell-specific summon-to-target effect radius, отдельно от cast range/guardian attack reach; без координат/ауры — UNKNOWN.
7. Интегрировать spell refresh policy с PE-04 cooldown, PE-05 time conventions и SP-14 AbilityEligibility; избегать преждевременного refresh и двойных рекомендаций.
8. EventBus `PLAYER_TOTEM_UPDATE`, подтверждённые guardian/combat log events, zone/death/identity invalidation, lazy Needs, bounded memo, без per-frame полного сканирования.
9. DevTools-only диагностика: `totem_slot_unknown`, `totem_slot_secret`, `totem_slot_replaced`, `totem_remaining_estimated`, `totem_duration_object_unverified`, `totem_spell_family_unknown`, `guardian_summon_unconfirmed`, `guardian_guid_unknown`, `guardian_lifecycle_stale`, `summon_effect_radius_unknown`, `summon_target_coverage_confirmed`, `summon_anchor_unavailable`.
10. Тесты: solo/party/raid, 0/1/4/5 slots, slot replacement, totem recalled/killed/expired, multiple ranks, totem duration secret midcombat, cached estimated vs confirmed, GetTotemDuration object, player death/zone, guardian summon/death/despawn with and without GUID, multiple guardians, totem vs guardian vs pet, target near caster but far from totem, aura present vs unknown geometry, out-of-range/LOS, missing API, event burst, stale revisions, no per-frame scan/protected actions.

**Тесты и диагностика**

в файле не указано

**Архитектурные и обратные ссылки:** CL-08, PE-01, PE-05, GR-06, PE-04, SP-14, PE-03, EN-03.

---

