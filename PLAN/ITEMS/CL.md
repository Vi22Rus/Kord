# Карточки CL

Источник: REQUIREMENTS.md, blob 9efdec1900398c978ea121818fb5950cb1620337.

### CL-01 — Воин: стойки, ярость, очередь удара, крики, добивание, рывок/перехват и прерывание

ID: [CL-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L8925). Приоритет: P0. Lua: упомянут (точный статус в источнике).

**Вердикт / статус**

**Вердикт**

**ЧАСТИЧНО ПО ОБЩИМ ПРИМИТИВАМ / WARRIOR-SPECIFIC ПОДДЕРЖКА НЕ ДОКАЗАНА / P0.** Есть базовые ресурсы, Eligibility, условия и категории стойки/прерывания, но нет подтверждённых canonical providers для Warrior stance/rage reserve/melee queue и полного набора QA-07 сценариев. **SOURCE/DOC AUDIT PASS; LUA 5.1 NOT RUN; CI NOT RUN; WOW FOREVER NOT RUN; CLIENT PASS 0/101.** Это спецификация, **не реализация**. Lua/TOC/ZIP не менялись.

**Ретроактивные ссылки:** AC-05, AC-06, QA-07, SP-01, EN-A1.

**Ретроактивное уточнение CL-02:** CL-02: StanceStateProvider/ауры паладина используют общий переключаемый режим состояния, но паладинская aura не считается warrior stance; общие AuraStateProvider, ResourceStateProvider и AbilityEligibility расширяются без дублирования.

**Ретроактивное уточнение CL-03:** CL-03: Warrior next-swing melee queue и Hunter ranged Auto Shot clipping — разные состояния; общий SwingStateProvider должен типизировать melee/ranged, не переносить Hunter autoShot.swing на Warrior.

**Ретроактивное уточнение CL-04:** CL-04: Rogue energy ticks не равны Warrior rage; общий ResourceStateProvider типизирует ENERGY/RAGE и проверяет разные источники.

**Выбранный путь Kord**

**Выбранная архитектура**

**Универсальные провайдеры, без отдельного второго warrior-engine:**
1. `StanceStateProvider` — canonical current stance, доступность, spell requirements, revision, проверка перехода; общая основа AC-05 и других классов.
2. `ResourceStateProvider` — typed RAGE, current/max, costs, reserve policy и проверка freshness; переиспользуется другими классами для их типов ресурсов.
3. `MeleeSwingQueueProvider` — состояние melee autoattack и **проверяемая** очередь next-swing action. Не использовать `autoShot.swing` Hunter; если API queue state не подтверждён, возвращать UNKNOWN. Таймер удара без источника не выдумывать.
4. `AuraStateProvider` — player buffs, target debuffs, remaining, ownership и UNKNOWN, общий механизм для криков.
5. `TargetHealthProvider` и `SpellRangeProvider` — точный HP%, min/max distance для конкретного Charge/Intercept/Execute; запрещён fallback «цель существует → дистанция подходит».
6. `InterruptStateProvider` — cast/channel/interruptible, remaining, latency, stance/equipment; общий механизм для других классов.
7. `AbilityEligibility` — единственный финальный gate READY, с валидированными spellID/rank, stance, cost, equipment, target, range, cast/GCD/cooldown.
8. `Profile_Contract` — расширять `Needs` и `actionType` **только через версионированное изменение контракта**, не протаскивать произвольные поля в существующий v1.

**Критические зависимости:** AC-05 (STANCE_OR_FORM), AC-06 (WAIT, не очередь), QA-04 (матрица API), QA-06 (pure profiles), QA-07 (scenario oracle), SP-01 (spellbook), EN-A1 (контракт), общие EN/TTD/range/auras/interrupt requirements. Если общий провайдер введён позднее, старые задачи должны ссылаться на него; здесь обратные ссылки добавляются сразу.

**Требуемые изменения (полный текст)**

**Требуемые работы**

1. Составить реестр Warrior spells/ranks/stance restrictions и отметить каждое неподтверждённое условие по QA-04.
2. Проверить доступные WoW Forever API стойки, rage, melee autoattack и queued-next-swing; зафиксировать подтверждённые/неподтверждённые методы и безопасные UNKNOWN.
3. Реализовать `StanceStateProvider` и события инвалидации при смене стойки/спека/талантов.
4. Расширить общий `ResourceStateProvider` typed rage/cost/reserve, без дублирования вычисления стоимости в профиле.
5. Спроектировать и отдельно утвердить контракт next-swing queue; не включать неподтверждённый action type в текущий registry.
6. Подключить крики через общий Aura provider, с ownership, remaining и unknown semantics.
7. Уточнить target health threshold и spell-specific range policies для Execute, Charge и Intercept; без жёстко вшитых значений без evidence.
8. Подключить interrupt через общий InterruptStateProvider, stance/equipment gate и Eligibility.
9. Добавить 17+ Warrior сценариев в QA-07 с граничными состояниями и статическими checks QA-06.
10. После реализации и подтверждения API — регрессия общих providers на Hunter и другие классы; отдельно MOCK PASS/CLIENT PASS, без запуска GitHub Actions до ручного финального этапа.

**Диагностика:** `warrior_stance_unknown`, `warrior_stance_unavailable`, `warrior_stance_transition_pending`, `warrior_rage_unknown`, `warrior_rage_insufficient`, `warrior_rage_reserve`, `warrior_queue_state_unknown`, `warrior_next_swing_already_queued`, `warrior_shout_aura_unknown`, `warrior_execute_threshold_unknown`, `warrior_charge_range_unknown`, `warrior_charge_too_close`, `warrior_intercept_wrong_stance`, `warrior_interrupt_cast_unknown`, `warrior_interrupt_not_interruptible`, `warrior_interrupt_equipment_missing`, `warrior_revision_stale`. В логах не сохранять secret values.

**Тесты и диагностика**

**Исполняемые сценарии QA-07 для Warrior (спецификация, не PASS)**

| ID | Состояние | Ожидаемый результат |
|---|---|---|
| `WAR-STANCE-01` | нужная стойка активна | не рекомендовать повторное переключение |
| `WAR-STANCE-02` | стойка другая, смена разрешена и подтверждена | `STANCE_OR_FORM` только после Eligibility |
| `WAR-STANCE-03` | текущая стойка UNKNOWN | STOP для правила, которому стойка обязательна |
| `WAR-RAGE-01` | ярости меньше стоимости+резерва | BLOCKED, не ложный READY |
| `WAR-RAGE-02` | тип ресурса UNKNOWN | STOP для rage-dependent правила |
| `WAR-QUEUE-01` | Heroic Strike уже queued | не рекомендовать повторно queued action |
| `WAR-QUEUE-02` | queue state UNKNOWN | STOP для обязательного queue rule |
| `WAR-SHOUT-01` | нужный крик активен, время достаточно | не обновлять раньше утверждённого порога |
| `WAR-SHOUT-02` | aura duration UNKNOWN | не считать бафф отсутствующим |
| `WAR-EXECUTE-01` | HP цели на границе утверждённого порога | проверить обе стороны порога, включая exact boundary |
| `WAR-CHARGE-01` | дистанция меньше min / в dead zone | Charge BLOCKED |
| `WAR-CHARGE-02` | дистанция UNKNOWN | STOP, не предполагать range |
| `WAR-INTERCEPT-01` | подходящая дистанция, неверная стойка | проверить смену стойки как отдельное действие, не выдать Intercept READY |
| `WAR-INTERRUPT-01` | target cast interruptible, valid spell and range | READY только если все gates подтверждены |
| `WAR-INTERRUPT-02` | cast interruptibility UNKNOWN | STOP для interrupt rule |
| `WAR-INTERRUPT-03` | Shield Bash без обязательного экипирования | BLOCKED при подтверждённом требовании |
| `WAR-REVISION-01` | после смены стойки/цели/талантов | новый snapshot, никаких stale READY |

Для каждого сценария — `profileID`, версия, конкретный spellID, входы, expected action, reason, priority, channel, provider reads, evidence и `NOT_RUN` до реального теста. Символические сценарии не повышают coverage реального Warrior-профиля.

**Архитектурные и обратные ссылки:** CL-09, AC-05, QA-07, QA-04, AC-06, QA-06, SP-01, WAR-RAGE-01, WAR-RAGE-02, WAR-QUEUE-01, WAR-QUEUE-02, WAR-SHOUT-01, WAR-SHOUT-02, CL-02, CL-03, CL-04.

---

### CL-02 — Паладин: печати и суд, ауры, благословения, руки, Divine Shield, Consecration, воскрешение, снятие яда и болезни

ID: [CL-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9039). Приоритет: P0. Lua: упомянут (точный статус в источнике).

**Вердикт / статус**

**Вердикт**

**ЧАСТИЧНО ПО ОБЩИМ ПРИМИТИВАМ / PALADIN-SPECIFIC КОНТРАКТ НЕ РЕАЛИЗОВАН / P0.** Базовые ресурсы, target, aura, Eligibility существуют, но `friendly_dead`, выбор союзников, dispel-type, seal/Judgement transition, blessing recipient и полноценные paladin-specific QA-07 сценарии отсутствуют или не доказаны. **SOURCE/DOC AUDIT PASS; LUA 5.1 NOT RUN; CI NOT RUN; WOW FOREVER NOT RUN; CLIENT PASS 0/101.** Только документация, Lua/TOC/ZIP без изменений.

**Ретроактивные ссылки:** CL-01, AC-05, QA-07, EN-A1, QA-04, SP-01.

**Ретроактивное уточнение CL-03:** CL-03: Hunter Aspect и Paladin Aura используют общий AuraStateProvider/ExclusiveAuraModeProvider, но различаются семантикой и условиями смены; не создавать дублирующие сканеры.

**Ретроактивное уточнение CL-05:** CL-05: Priest Resurrection использует ту же universal friendly_dead eligibility, FriendlyUnitSelectionProvider и DispelStateProvider; нельзя создавать priest-only альтернативы.

**Ретроактивное уточнение CL-06:** CL-06: Shaman cleanse и Ancestral Spirit должны переиспользовать DispelStateProvider, FriendlyUnitSelectionProvider и friendly_dead eligibility; Reincarnation — отдельная self-resurrection policy, не friendly_dead.

**Ретроактивное уточнение CL-07:** CL-07: Mage Arcane Intellect/Brilliance используют общий FriendlyUnitSelectionProvider, AuraStateProvider и SpellFamilyCatalog для buff recipients, как Paladin blessings.

**Выбранный путь Kord**

**Выбранная архитектура**

1. **`AuraStateProvider`** — универсальные buff/debuff, source, duration, unknown/secret, обновление по revision; используется печатями, аурами, благословениями и руками. Класс-специфические **семейства эффектов** задаются проверенным `SpellFamilyCatalog`, не отдельными сканерами.
2. **`SealJudgementStateProvider`** — typed seal ID/rank, compatible Judgement, verified consume/persist state, transition events; не считать Judgement всегда снимающим печать. При неизвестном результате применения — refresh snapshot/UNKNOWN, не угадывать.
3. **`ExclusiveAuraModeProvider`** — общая модель взаимоисключающих режимов для паладинских аур, не приравнивая их к `STANCE_OR_FORM` в текущем контракте.
4. **`FriendlyUnitSelectionProvider`** — безопасный список `player/target/focus/party/raid` только если подтверждены unit tokens и доступность API; recipient policy, dead/alive, assistable, range, party membership, group/class blessing. Никаких вымышленных GUID или выбора недоступной цели.
5. **`DispelStateProvider`** — общий по классам provider типов `Poison/Disease/Magic/Curse` с per-spell allowed dispel types; паладинские Purify/Cleanse получают только подтверждённые возможности. Aura `UNKNOWN` не равна dispellable.
6. **`ResourceStateProvider`** — typed MANA, current/cost/reserve, Consecration AoE gate, отдельные ресурсы для support/resurrection; не подменять порог маны произвольным фиксированным процентом.
7. **`AbilityEligibility`** — единственный final READY; новые явно типизированные policies `friendly_dead`, `friendly_group`, `self`, `enemy`, плюс validated restrictions for combat/cast/target/range/reagent/effect conflict. Существующая `friendly` остаётся live-only, чтобы не сломать лечение и buffs.
8. **`Profile_Contract`/QA-06** — новые `Needs` и target policies только через versioned schema, profiles pure, lazy reads и `UNKNOWN→STOP`. Общие провайдеры не должны создавать отдельный paladin engine.

**Требуемые изменения (полный текст)**

**Требуемые изменения**

1. Подтвердить Paladin spell/rank/family catalog по WoW Forever: seal, Judgement, aura, blessing, Hand, shield, Consecration, Redemption, Purify/Cleanse.
2. Проверить seal→Judgement→reseal semantics и реализовать `SealJudgementStateProvider` с safe UNKNOWN.
3. Подключить ауры через общий exclusive-mode contract, с отдельной семантикой от warrior stance.
4. Реализовать `FriendlyUnitSelectionProvider` для player/party/raid, target life state и scope групповых благословений.
5. Подключить Blessing/Hand через общий `AuraStateProvider` + `SpellFamilyCatalog`, с target, duration, ownership и конфликтами.
6. Ввести `friendly_dead` eligibility для Redemption, не меняя safety-поведение существующей `friendly` policy.
7. Реализовать `DispelStateProvider` с проверкой типа Poison/Disease и подтверждённых возможностей Purify/Cleanse.
8. Добавить typed mana reserve и AoE/CC checks Consecration через общие Resource/EnemyCount/CC providers.
9. Добавить Divine Shield defensive checks, cooldown, target=self, конфликтующие эффекты и безопасное UI routing.
10. Добавить 22+ сценария QA-07, QA-06 purity gate, QA-05 differential при наличии legacy oracle; синхронизировать QA-04, Priority Matrix, Test Matrix, Registry; регрессия общих providers на Hunter/Warrior, без выдуманных CLIENT PASS.

**Диагностика:** `paladin_seal_unknown`, `paladin_judgement_seal_incompatible`, `paladin_seal_transition_unconfirmed`, `paladin_aura_unknown`, `paladin_blessing_recipient_unknown`, `paladin_blessing_conflict`, `paladin_hand_conflict_unknown`, `paladin_shield_blocked`, `paladin_consecration_mana_reserve`, `paladin_consecration_cc_risk`, `paladin_resurrection_target_alive`, `paladin_resurrection_target_life_unknown`, `paladin_resurrection_combat_restricted`, `paladin_dispel_type_unknown`, `paladin_dispel_target_unavailable`, `paladin_revision_stale`. Не логировать secret payload.

**Тесты и диагностика**

**Сценарные таблицы QA-07 (спецификация, не PASS)**

| ID | Состояние | Ожидаемый результат |
|---|---|---|
| `PAL-SEAL-01` | нужная печать активна и не истекает | не обновлять без необходимости |
| `PAL-SEAL-02` | seal state UNKNOWN | STOP для зависящего правила |
| `PAL-JUDGE-01` | seal/Judgement compatible, target hostile, Eligibility READY | допустим Judgement; приоритет из профиля |
| `PAL-JUDGE-02` | после Judgement неизвестно, сохранена ли печать | не угадывать reseal; повторное наблюдение |
| `PAL-AURA-01` | нужная аура активна | не переключать повторно |
| `PAL-AURA-02` | текущая аура UNKNOWN | не выдавать слепое переключение |
| `PAL-BLESS-01` | благословение на player, но отсутствует на выбранном ally | оценивать именно ally, не player |
| `PAL-BLESS-02` | цель вне группы/недоступна | BLOCKED либо UNKNOWN по фактическому наблюдению |
| `PAL-BLESS-03` | конфликтующее благословение | учитывать verified family conflict |
| `PAL-HAND-01` | Hand effect конфликтует с действующим ограничением | BLOCKED при подтверждённом конфликте |
| `PAL-SHIELD-01` | Divine Shield unavailable/cooldown | BLOCKED; не ложный READY |
| `PAL-CONSECRATE-01` | маны меньше cost+reserve | BLOCKED |
| `PAL-CONSECRATE-02` | рядом breakable CC, AoE иначе eligible | не рекомендовать опасное AoE |
| `PAL-CONSECRATE-03` | число целей или mana UNKNOWN | STOP для соответствующего правила |
| `PAL-REZ-01` | dead friendly, OOC, spell eligible | `friendly_dead` разрешает Redemption |
| `PAL-REZ-02` | alive friendly | Resurrection BLOCKED |
| `PAL-REZ-03` | target life state UNKNOWN | STOP, не лечить и не воскрешать наугад |
| `PAL-DISPEL-01` | ally имеет подтверждённый Poison | разрешённый dispel spell только после Eligibility |
| `PAL-DISPEL-02` | ally имеет подтверждённый Disease | разрешённый dispel spell только после Eligibility |
| `PAL-DISPEL-03` | debuff type UNKNOWN/secret | STOP, не утверждать очищаемость |
| `PAL-DISPEL-04` | несколько союзников, один недоступен | выбор recipient по профилю, никаких выдуманных целей |
| `PAL-REVISION-01` | смена цели, группы, ауры, seal или уровня | invalidate snapshot; никаких stale READY |

Каждый case должен получить реальные spellID/rank, `profileID`, exact expected status/action/priority/channel/reason, provider read counts, evidence и отдельный статус `MOCK PASS`/`CLIENT PASS`. Пока Paladin-профилей нет, это **сценарная спецификация**, не покрытие готового профиля.

**Архитектурные и обратные ссылки:** CL-09, QA-04, QA-07, QA-06, PAL-SEAL-01, PAL-SEAL-02, PAL-JUDGE-01, PAL-JUDGE-02, PAL-AURA-01, PAL-AURA-02, PAL-BLESS-01, PAL-BLESS-02, PAL-BLESS-03, PAL-HAND-01, PAL-REZ-01, PAL-REZ-02, PAL-REZ-03, QA-05, CL-01, AC-05, SP-01, CL-03, CL-05, CL-06, CL-07.

---

### CL-03 — Охотник: аспекты, ловушки, питомец, боеприпасы, автострельба, мёртвая зона, метка и имитация смерти

ID: [CL-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9152). Приоритет: P0. Lua: упомянут (точный статус в источнике).

**Вердикт / статус**

**Вердикт**

**ЧАСТИЧНО В ИСТОРИЧЕСКОМ HUNTER И ОБЩИХ ПРИМИТИВАХ / ПОЛНЫЙ CL-03 НЕ РЕАЛИЗОВАН / P0.** Исторический BM содержит большинство именованных механик, но не зарегистрирован как v1, отсутствует доказанное сквозное поведение shared trap CD, pet commands/happiness, ammo, ranged swing clipping и dead-zone safety; известные UI/target регрессии не признаны исправленными. **SOURCE/DOC AUDIT PASS; LUA 5.1 NOT RUN; CI NOT RUN; WOW FOREVER NOT RUN; CLIENT PASS 0/101.** Только документация; Lua/TOC/ZIP без изменений.

**Ретроактивные ссылки:** CL-01, CL-02, AC-03, AC-05, AC-06, QA-07, QA-04, EN-A1.

**Ретроактивное уточнение CL-04:** CL-04: Rogue weapon poisons используют общий WeaponEnchantProvider/EquipmentProvider, но не Hunter ammo; interrupt/cast providers общие, а Rogue energy ticks отличаются от Auto Shot swing.

**Ретроактивное уточнение CL-05:** CL-05: Priest wand Shoot и Hunter Auto Shot требуют общего типизированного AutoAttackStateProvider, но отдельной семантики wand/ranged и проверки остановки; swing timings не угадываются.

**Ретроактивное уточнение CL-06:** CL-06: shared shock cooldown должен использовать тот же универсальный CooldownGroupProvider, что trap shared cooldown; не создавать отдельный таймер шоков.

**Ретроактивное уточнение CL-07:** CL-07: Mage Polymorph/Freeze и Hunter trap используют общий CrowdControlStateProvider, EnemyCCSafetyProvider и AoE breakable CC gate; Conjure Food/Water используют общий ItemInventoryProvider.

**Выбранный путь Kord**

**Выбранная архитектура: общие провайдеры**

1. `AuraStateProvider` + `ExclusiveAuraModeProvider`: Hunter aspects, mark, Mend Pet aura, travel vs combat, owner/remaining; общий с CL-02, но разная семантика переключения.
2. `CooldownGroupProvider`: per-spell и shared cooldown groups для trap family; общий для других классов/предметов, без отдельных таймеров в профиле.
3. `PetStateProvider` + `PetCommandProvider`: exists/dead/HP/target/behavior/happiness/food, commands, Mend/Revive/Call; общий контракт AC-03, fail-closed.
4. `AmmoEquipmentProvider`: ammo count/type, weapon compatibility, equip/availability; общий equipment gate `AbilityEligibility`.
5. `SwingStateProvider`: **раздельные ranged Auto Shot и melee swing**; read-only, confirmed duration/expiration, clip-safe window, fake clock и invalidation; при UNKNOWN — STOP для зависящих от swing правил, а не искусственный WAIT.
6. `SpellRangeProvider`: per-spell melee/ranged/dead-zone eligibility, target validation, actual min/max if proven; не конвертировать неизвестную дальность в «можно».
7. `ThreatStateProvider`: solo/dungeon/raid, actual aggro, HP, Feign Death policy, independent defensive routing; общая модель защитных действий.
8. `AbilityEligibility`: **единственный** final READY для SPELL/PET_COMMAND/STANCE_OR_FORM/WAIT после расширения контракта; все новые `Needs`/action types — только через versioned `Profile_Contract`, без обхода QA-06.

**Требуемые изменения (полный текст)**

**Требуемые работы**

1. Сверить Hunter spell/rank/ability catalogue по клиенту, отдельно BM/MM/SV Leveling/60; не создавать фальшивые PvP профили.
2. Подключить аспекты через общий aura/mode provider и исправить target-independent OOC defensive recommendations и disabled main transfer.
3. Ввести `CooldownGroupProvider` для trap shared cooldown, учитывать талантные модификаторы только после QA-04.
4. Реализовать PetState/PetCommand с command availability, Mend, Revive, Call, happiness/food, без protected automation.
5. Подключить AmmoEquipmentProvider и общий ranged ability gate, различать ammo absent/UNKNOWN.
6. Реализовать подтверждённый ranged SwingStateProvider, clipping-aware WAIT, раздельно от melee, без выдуманного swing timer.
7. Ввести spell-specific range/dead-zone policy, проверить Raptor Strike на дальних целях и ranged spells слишком близко.
8. Подключить Hunter's Mark через общий debuff ownership/remaining и Feign Death через ThreatStateProvider.
9. Добавить 23+ QA-07 cases для каждого применимого Hunter-профиля и проверить все старые регрессии, включая OOC/defensive/main.
10. Интегрировать QA-04/QA-06/QA-05, диагностические reason codes, синхронизировать матрицу и реестр; Lua 5.1 mocks до клиентской проверки, без автоматического GitHub Actions.

**Диагностика:** `hunter_aspect_unknown`, `hunter_aspect_channel_mismatch`, `hunter_trap_shared_cooldown`, `hunter_trap_shared_cd_unknown`, `hunter_pet_absent`, `hunter_pet_dead`, `hunter_pet_happiness_unknown`, `hunter_pet_command_unknown`, `hunter_ammo_missing`, `hunter_ammo_unknown`, `hunter_ranged_swing_unknown`, `hunter_autoshot_clip_risk`, `hunter_dead_zone`, `hunter_melee_out_of_range`, `hunter_mark_ownership_unknown`, `hunter_feign_threat_unknown`, `hunter_feign_solo_hp_high`, `hunter_snapshot_stale`.

**Тесты и диагностика**

**Сценарные таблицы QA-07 (нормативные кейсы, НЕ тестовый PASS)**

| ID | Состояние | Ожидаемое решение |
|---|---|---|
| `HUN-ASPECT-01` | OOC без цели, нужна combat aura | defensive recommendation без обязательного target, если policy позволяет |
| `HUN-ASPECT-02` | in combat, `defensiveInCombatMain=false` | aura остаётся в defensive, main не захватывает её |
| `HUN-ASPECT-03` | travel aspect active, target далеко | не предлагать melee attack или неверное переключение |
| `HUN-TRAP-01` | одна trap на общем cooldown | другие trap не выдавать READY |
| `HUN-TRAP-02` | shared trap cooldown UNKNOWN | STOP для обязательного trap rule |
| `HUN-TRAP-03` | рядом breakable CC | не рекомендовать AoE trap, разрушающую CC |
| `HUN-PET-01` | pet отсутствует, death unknown | не предлагать Revive Pet как подтверждённый READY |
| `HUN-PET-02` | pet dead confirmed | Revive Pet только после Eligibility |
| `HUN-PET-03` | pet alive, HP low, Mend missing | Mend Pet при подтверждённом пороге и mana |
| `HUN-PET-04` | pet happiness UNKNOWN | не выдумывать Feed Pet |
| `HUN-PET-05` | pet attack state/target unknown | не повторять команду без подтверждения |
| `HUN-AMMO-01` | ammo count=0, ammo required | ranged action BLOCKED |
| `HUN-AMMO-02` | ammo type/availability UNKNOWN | STOP для ammo-dependent action |
| `HUN-SWING-01` | Auto Shot about to fire, cast clips it | WAIT только при подтверждённом swing и policy |
| `HUN-SWING-02` | ranged swing UNKNOWN | не рекомендовать WAIT наугад |
| `HUN-RANGE-01` | target в подтверждённой dead zone | ranged action BLOCKED, melee только по своей проверке |
| `HUN-RANGE-02` | target далеко, melee ability | melee BLOCKED, никакого Raptor Strike на 50 м |
| `HUN-MARK-01` | mark отсутствует, цель valid | Hunter's Mark при eligibility и утверждённом правиле |
| `HUN-MARK-02` | чужая mark или duration UNKNOWN | учитывать ownership/UNKNOWN, не угадывать |
| `HUN-FEIGN-01` | solo aggro, HP high | не предлагать Feign Death только по aggro |
| `HUN-FEIGN-02` | dungeon/raid aggro, spell eligible | defensive Feign Death по утверждённой policy |
| `HUN-REVISION-01` | target/pet/aspect/ammo changed | invalidate stale data, reevaluate |
| `HUN-CHANNEL-01` | OOC aura без target → combat при disabled transfer | без исчезновения DPS из main и без неправильного переноса aura |

Каждый кейс должен иметь конкретный `profileID` BM/MM/SV, spellID/rank, source evidence, exact expected action/status/priority/channel/reason, provider reads, `NOT_RUN` до реального теста. Сценарии **не означают**, что Hunter уже исправлен или работает.

**Архитектурные и обратные ссылки:** CL-08, PE-01, PE-05, AC-03, QA-04, CL-02, QA-06, QA-07, HUN-TRAP-01, HUN-TRAP-02, HUN-TRAP-03, HUN-PET-01, HUN-PET-02, HUN-PET-03, HUN-PET-04, HUN-PET-05, HUN-AMMO-01, HUN-AMMO-02, HUN-SWING-01, HUN-SWING-02, HUN-RANGE-01, HUN-RANGE-02, HUN-MARK-01, HUN-MARK-02, HUN-FEIGN-01, HUN-FEIGN-02, QA-05, CL-01, AC-05, AC-06, CL-04, CL-05, CL-06, CL-07.

---

### CL-04 — Разбойник: очки комбо, финишеры, скрытность, яды, энергия и такты, прерывания, уход и срыв каста

ID: [CL-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9267). Приоритет: P0. Lua: упомянут (точный статус в источнике).

**Вердикт / статус**

**Вердикт**

**ЧАСТИЧНО ПО ОБЩИМ ПРИМИТИВАМ / ROGUE-SPECIFIC КОНТРАКТ НЕ РЕАЛИЗОВАН / P0.** Есть ресурсы, target, cooldown/cast Eligibility, но не доказаны combo target binding, stealth, MH/OH poison, energy ticks и CC cast disruption. Rogue профили отсутствуют. **SOURCE/DOC AUDIT PASS; LUA 5.1 NOT RUN; CI NOT RUN; WOW FOREVER NOT RUN; CLIENT PASS 0/101.** Lua/TOC/ZIP не менялись, только документация.

**Ретроактивные ссылки:** CL-01, CL-03, IT-10, QA-07, QA-04, EN-A1, AC-07.

**Ретроактивное уточнение CL-05:** CL-05: Priest Shadowform и Rogue Stealth используют общие StateTransition/ModeProvider с разными restrictions; mana resource отдельно от energy ticks.

**Ретроактивное уточнение CL-06:** CL-06: Shaman weapon imbues и Rogue poisons используют один WeaponEnchantProvider, раздельные MH/OH slots, duration/charges и UNKNOWN.

**Выбранный путь Kord**

**Выбранная архитектура (универсальные провайдеры)**

1. **`ComboPointStateProvider`**: typed current/max, `targetIdentity`/revision, reset/move semantics только после проверки клиента, fail-closed при смене цели; переиспользуется другими классами, если combo resource применим.
2. **`ResourceStateProvider`**: typed ENERGY, current/max, costs, reserve; `ResourceTickProvider` только с подтверждённым timing, fake clock и event invalidation. Общий с CL-01 Rage/CL-02 Mana, но без смешения единиц.
3. **`StealthStateProvider`**: verified stealth and transitions, opener requirements, Vanish pending/confirmed, immunity and target positioning facts where supported; общий с формами/невидимостью других классов.
4. **`WeaponEnchantProvider`**: MH/OH enchant, family, remaining/charges, item inventory/usable, applied poison; **канонический общий модуль IT-10**, не Rogue-only scanner.
5. **`InterruptStateProvider`**: cast/channel/interruptible, cast remaining and Kick eligibility; **`CastDisruptionProvider`** отдельно оценивает CC break, DR/immunity, target validity; не маркировать Gouge гарантированным interrupt.
6. **`ThreatStateProvider`**: defensive Vanish/Feint/Evasion, aggro/HP/escape, main vs defensive; общий с Hunter Feign Death CL-03.
7. **`AbilityEligibility`**: единственный final READY, typed combo/energy/stealth/poison/interrupt/CC gates, spellbook/rank/range/cooldown; профиль определяет приоритет, но не подтверждает пригодность.
8. **`Profile_Contract`**: новые `Needs`/условия/действия только через versioned schema, QA-06 static purity, lazy reads, UNKNOWN→STOP. Не создавать отдельный Rogue engine.

**Требуемые изменения (полный текст)**

**Требуемые работы**

1. Подтвердить Rogue spell/rank/poison catalog и ограничения в WoW Forever; QA-04 для combo, energy ticks, stealth, weapon enchant, cast/interrupt.
2. Реализовать ComboPointStateProvider с target identity и event revisions.
3. Подключить typed ENERGY и ResourceTickProvider только при доказанном источнике timing; WAIT без подтверждения запрещён.
4. Реализовать StealthStateProvider и подтверждение Vanish transitions.
5. Подключить MH/OH poisons через общий WeaponEnchantProvider **IT-10**, включая remaining/charges/inventory.
6. Подключить финальные combo/stealth/cost/target/range gates через AbilityEligibility.
7. Реализовать InterruptStateProvider для Kick и CastDisruptionProvider для Gouge/Kidney Shot/Blind с DR/immunity.
8. Добавить ThreatStateProvider и defensive routing для Vanish/Feint/Evasion, не выдумывать threat reset.
9. Добавить 21+ QA-07 scenarios для каждого реально созданного Rogue профиля, проверять смену цели и stale combo.
10. Интегрировать QA-06/QA-05, обновить реестры и диагностику; тесты Lua 5.1 mock, затем WoW Forever; без автозапуска GitHub Actions.

**Диагностика:** `rogue_combo_unknown`, `rogue_combo_target_stale`, `rogue_finisher_insufficient_combo`, `rogue_stealth_unknown`, `rogue_vanish_pending`, `rogue_poison_mh_missing`, `rogue_poison_oh_unknown`, `rogue_energy_insufficient`, `rogue_energy_tick_unknown`, `rogue_kick_cast_unknown`, `rogue_kick_not_interruptible`, `rogue_cast_disruption_immunity_unknown`, `rogue_defensive_threat_unknown`, `rogue_snapshot_stale`.

**Тесты и диагностика**

**Сценарные таблицы QA-07 (спецификация, не PASS)**

| ID | Состояние | Ожидаемое решение |
|---|---|---|
| `ROG-COMBO-01` | 5 combo на текущей цели, finisher eligible | finisher по утверждённому профилю |
| `ROG-COMBO-02` | combo count UNKNOWN | STOP для обязательного finisher rule |
| `ROG-COMBO-03` | target сменился, старые combo stale | не рекомендовать finisher по старым очкам |
| `ROG-COMBO-04` | combo=0, finisher требует очки | BLOCKED |
| `ROG-STEALTH-01` | Stealth confirmed, opener eligible | opener по утверждённому правилу |
| `ROG-STEALTH-02` | stealth UNKNOWN | STOP для stealth-only opener |
| `ROG-STEALTH-03` | Vanish recommended, state not yet confirmed | не считать персонажа скрытым до обновления |
| `ROG-POISON-01` | MH poison missing, OH present | обновить только MH при eligible item |
| `ROG-POISON-02` | OH enchant remaining UNKNOWN | не перезаписывать вслепую |
| `ROG-POISON-03` | poison item absent | BLOCKED, не ложный READY |
| `ROG-ENERGY-01` | energy меньше стоимости+резерва | BLOCKED |
| `ROG-ENERGY-02` | tick phase verified, выгодно подождать | WAIT только по подтверждённому правилу |
| `ROG-ENERGY-03` | tick phase UNKNOWN | не выдумывать таймер, STOP для зависимого правила |
| `ROG-KICK-01` | interruptible cast, Kick ready/in range | READY при всех подтверждённых gates |
| `ROG-KICK-02` | cast interruptibility UNKNOWN | STOP для interrupt rule |
| `ROG-GOUGE-01` | cast active, Gouge available, target CC-susceptible | отдельное cast disruption, не `interrupt=true` |
| `ROG-GOUGE-02` | target immune/DR unknown | не гарантировать срыв каста |
| `ROG-VANISH-01` | threat high, defensive eligible | defensive Vanish только по утверждённому порогу |
| `ROG-VANISH-02` | Vanish cast, stealth not yet confirmed | не запускать stealth-only opener |
| `ROG-REVISION-01` | target/energy/weapon/stealth changed | invalidate stale snapshot и reevaluate |
| `ROG-CHANNEL-01` | defensive escape eligible, main DPS independent | не подменять main защитной рекомендацией вопреки настройке |

Каждый case привязывается к конкретному `profileID`, spellID/rank, evidence, priority, channel, reason, read counts, `NOT_RUN` до запуска. Никаких фиктивных Rogue профилей или MOCK/CLIENT PASS.

**Архитектурные и обратные ссылки:** CL-09, CL-08, QA-04, QA-07, CL-01, CL-02, IT-10, CL-03, QA-06, ROG-COMBO-01, ROG-COMBO-02, ROG-COMBO-03, ROG-COMBO-04, ROG-KICK-01, ROG-KICK-02, ROG-GOUGE-01, ROG-GOUGE-02, QA-05, AC-07, CL-05, CL-06.

---

### CL-05 — Жрец: Shadowform, щит и Weakened Soul, DoT/мана, палочка, групповое лечение, диспел, воскрешение, баффы группы

ID: [CL-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9376). Приоритет: P0. Lua: упомянут (точный статус в источнике).

**Вердикт / статус**

**Вердикт**

**ЧАСТИЧНО ПО ОБЩИМ ПРИМИТИВАМ / PRIEST-SPECIFIC КОНТРАКТ НЕ РЕАЛИЗОВАН / P0.** Общие health, mana, target, aura, spell Eligibility существуют, но нет доказанного full party heal/dispel target selection, shield+Weakened Soul, Shadowform restriction, wand toggle и group buff contracts. Priest профилей нет. **SOURCE/DOC AUDIT PASS; LUA 5.1 NOT RUN; CI NOT RUN; WOW FOREVER NOT RUN; CLIENT PASS 0/101.** Только документация; Lua/TOC/ZIP не менялись.

**Ретроактивные ссылки:** CL-02, CL-03, CL-04, QA-07, QA-04, EN-A1, AC-05, AC-07.

**Ретроактивное уточнение CL-06:** CL-06: Shaman party cleansing и resurrection используют общие friendly unit selection, dispel types и dead-target policies; не копировать Priest реализацию.

**Ретроактивное уточнение CL-07:** CL-07: Mage Mana, Armor/Intellect и Evocation используют общие ResourceStateProvider, AuraStateProvider, FriendlyUnitSelectionProvider; Mage не создаёт собственный mana engine.

**Выбранный путь Kord**

**Выбранная архитектура: только общие провайдеры**

1. **`FormStateProvider`** — Shadowform, transitions и restrictions; общий `STANCE_OR_FORM` AC-05 с Warrior и другими классами, без автоматического разрешения Holy/healing spells в Shadowform.
2. **`AuraStateProvider`** — shield buff, Weakened Soul debuff на одном unit, DoT owner/remaining, group buffs; typed `UNKNOWN`, secret-safe, event revision; absorb amount только при подтверждённом API.
3. **`FriendlyUnitSelectionProvider`** — canonical player/party/raid units, per-unit health/dead/assistable/range, target identity, explicit recipient; общий с Paladin CL-02.
4. **`HealEligibilityProvider`** — healing target, mana, cast, range, effective healing when reliable, no invented overheal predictions; финальное READY только `AbilityEligibility`.
5. **`DispelStateProvider`** — types `Magic/Disease` for verified priest spells, friendly/enemy direction, debuff identity, target and immunity; общий с Paladin CL-02.
6. **`ResourceStateProvider`** — typed MANA current/cost/reserve, regeneration when verified; не вводить фиксированные пороги в ядро.
7. **`AutoAttackStateProvider`** — typed wand Shoot auto-repeat, toggle on/off, equipped wand, range, channel/cast interactions; общий с Hunter CL-03, но `wand` не равно `Auto Shot`.
8. **`SpellFamilyCatalog`** — Fortitude/Prayer, Spirit/Prayer, Shadow Protection, shield, dispel, resurrection spell IDs/ranks and optional reagent rules; источник — проверенный spellbook.
9. **`AbilityEligibility`** — единственный final READY для friendly/alive, friendly_dead, enemy, self, form/recipient/range/mana/auras/toggle; расширения только через versioned `Profile_Contract` EN-A1, QA-06 purity и lazy Needs.

**Особое правило:** при подтверждённом Weakened Soul щит BLOCKED, но лечение союзника оценивается независимо; Shadowform не должна блокировать показ безопасной рекомендации выхода из формы, если профиль разрешает и клиент подтверждает ограничения. Не подменять main DPS рекомендацией group buff или defensive action вопреки UI policy.

**Требуемые изменения (полный текст)**

**Требуемые работы**

1. Подтвердить Priest spell IDs/ranks/families, Shadowform restrictions, shield/Weakened Soul, wand, group buffs, dispel and resurrection в WoW Forever (QA-04).
2. Подключить Shadowform к общему FormStateProvider и проверкам `AbilityEligibility`.
3. Реализовать shield+Weakened Soul pair check на одном unit через AuraStateProvider, safe UNKNOWN.
4. Добавить DoT owner/remaining и typed mana reserve, без лишнего обновления DoT.
5. Подключить wand Shoot к общему AutoAttackStateProvider, с confirmed toggle и equipment checks.
6. Реализовать FriendlyUnitSelectionProvider для party/raid, health/dead/target identity, затем HealEligibilityProvider.
7. Подключить DispelStateProvider с friendly/enemy direction и per-spell Magic/Disease capabilities.
8. Использовать общий `friendly_dead` из CL-02 для Resurrection, не менять live-friendly healing gate.
9. Подключить group buff families/recipient/reagents, исключить self-only spells из group recommendation.
10. Добавить 24 QA-07 сценария для каждого реального Priest профиля, QA-06 purity, diagnostics, Lua 5.1 mocks и отдельный WoW Forever validation, без GitHub Actions до финальной ручной QA.

**Диагностика:** `priest_shadowform_unknown`, `priest_form_spell_restricted`, `priest_weakened_soul_active`, `priest_weakened_soul_unknown`, `priest_shield_aura_unknown`, `priest_dot_owner_unknown`, `priest_mana_reserve`, `priest_wand_active`, `priest_wand_state_unknown`, `priest_wand_missing`, `priest_heal_recipient_unknown`, `priest_heal_target_dead`, `priest_dispel_type_unknown`, `priest_dispel_direction_invalid`, `priest_resurrection_target_alive`, `priest_group_buff_missing`, `priest_group_buff_reagent_missing`, `priest_snapshot_stale`. Secret payload не писать в журнал.

**Тесты и диагностика**

**QA-07: сценарии «состояние → ожидаемое действие» (спецификация, NOT RUN)**

| ID | Состояние | Ожидаемый результат |
|---|---|---|
| `PRI-FORM-01` | Shadowform активна, Shadow spell eligible | не переключать форму повторно |
| `PRI-FORM-02` | требуется heal, форма подтверждённо запрещает spell | отдельная рекомендация выхода из формы, не heal READY |
| `PRI-FORM-03` | form restrictions UNKNOWN | STOP для зависящего правила |
| `PRI-SHIELD-01` | на ally есть Weakened Soul | Power Word: Shield BLOCKED |
| `PRI-SHIELD-02` | Weakened Soul UNKNOWN | не считать отсутствующим |
| `PRI-SHIELD-03` | shield active, remaining enough | не обновлять по ошибке |
| `PRI-DOT-01` | свой DoT истекает, target valid, mana sufficient | разрешить refresh по profile threshold |
| `PRI-DOT-02` | DoT owner UNKNOWN | STOP для ownership-dependent rule |
| `PRI-MANA-01` | mana ниже cost+reserve | BLOCKED |
| `PRI-WAND-01` | Shoot уже active | не рекомендовать повторный toggle |
| `PRI-WAND-02` | Shoot state UNKNOWN | STOP для wand-toggle rule |
| `PRI-WAND-03` | wand не экипирована | Shoot BLOCKED |
| `PRI-HEAL-01` | ally low HP, self full HP | heal конкретного ally, не self |
| `PRI-HEAL-02` | ally dead | heal BLOCKED; resurrection оценивается отдельно |
| `PRI-HEAL-03` | ally HP UNKNOWN | STOP для health-dependent heal |
| `PRI-DISPEL-01` | friendly Disease confirmed, spell capable | dispel по Eligibility |
| `PRI-DISPEL-02` | enemy dispellable Magic buff | enemy dispel только при verified capability |
| `PRI-DISPEL-03` | debuff dispel type UNKNOWN | STOP, не обещать очищение |
| `PRI-REZ-01` | dead friendly, OOC, spell eligible | Resurrection через `friendly_dead` |
| `PRI-REZ-02` | alive friendly | Resurrection BLOCKED |
| `PRI-BUFF-01` | party member lacks Fortitude | выбрать именно этого recipient |
| `PRI-BUFF-02` | Prayer variant requires missing reagent | BLOCKED при verified requirement |
| `PRI-REVISION-01` | party member/HP/form/aura changed | invalidate stale snapshot |
| `PRI-CHANNEL-01` | group buff OOC, combat DPS active | main/defensive/maintenance routing согласно настройкам |

Для каждого теста — реальные `profileID`, spellID/rank, входной snapshot, expected action/status/reason/channel, provider reads и evidence. Пока профилей и runner нет, **все эти сценарии NOT RUN**; они не считаются реальным покрытием.

**Архитектурные и обратные ссылки:** CL-09, CL-08, QA-04, CL-02, AC-05, CL-03, QA-06, QA-07, PRI-FORM-01, PRI-FORM-02, PRI-FORM-03, PRI-DOT-01, PRI-DOT-02, PRI-MANA-01, PRI-WAND-01, PRI-WAND-02, PRI-WAND-03, PRI-HEAL-01, PRI-HEAL-02, PRI-HEAL-03, PRI-REZ-01, PRI-REZ-02, PRI-BUFF-01, PRI-BUFF-02, CL-04, AC-07, CL-06, CL-07.

---

### CL-06 — Шаман: тотемы, шоки и общий кулдаун, усиления оружия, очищение и воскрешение

ID: [CL-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9492). Приоритет: P0. Lua: упомянут (точный статус в источнике).

**Вердикт / статус**

**Вердикт**

**ЧАСТИЧНО ПО ОБЩИМ ПРИМИТИВАМ / SHAMAN-SPECIFIC КОНТРАКТ НЕ РЕАЛИЗОВАН / P0.** Базовые cooldown, mana, auras, target, Eligibility существуют, но нет доказанного TotemStateProvider, shared shock group, imbue per-hand, group dispel, friendly_dead и Reincarnation contract. Shaman профили отсутствуют. **SOURCE/DOC AUDIT PASS; LUA 5.1 NOT RUN; CI NOT RUN; WOW FOREVER NOT RUN; CLIENT PASS 0/101.** Только документация; Lua/TOC/ZIP не менялись.

**Ретроактивные ссылки:** CL-02, CL-03, CL-04, CL-05, IT-10, QA-07, QA-04, EN-A1.

**Ретроактивное уточнение CL-07:** CL-07: Mage Freeze и Shaman Frost Shock требуют общей типизированной модели slow/root/CC, но не считать любое замедление заморозкой.

**Выбранный путь Kord**

**Выбранная архитектура — единые провайдеры для всех классов**

1. **`TotemStateProvider`** — typed slots `Earth/Fire/Water/Air`, spellID, exists/UNKNOWN, remaining, position, radius, per-member coverage, replaced/destroyed events; **универсальный deployable-unit provider** пригоден для других временных объектов, без отдельного движка шамана. Не выводить позицию из наличия баффа.
2. **`CooldownGroupProvider`** — `shock` shared cooldown family, тот же универсальный механизм, что `trap` из CL-03; per-spell + group status, event revision, no guessed timer.
3. **`WeaponEnchantProvider`** — общий модуль IT-10/CL-04: mainhand/offhand imbues, duration/charges, inventory/equipment, rank, conflict; никакого shaman-only сканера.
4. **`DispelStateProvider`** — общий с CL-02/CL-05: poison/disease types, per-spell capabilities, friendly recipient, group target, instantaneous vs periodic totem dispel distinction.
5. **`FriendlyUnitSelectionProvider`** — конкретный player/party/raid recipient, alive/dead, assistable, range; общий Ancestral Spirit через `friendly_dead`.
6. **`SelfResurrectionStateProvider`** — отдельный typed status Reincarnation: dead/available/reagent/cooldown/client UI action; общий контракт для других self-resurrection mechanics, без имитации активной способности.
7. **`ResourceStateProvider`** — typed MANA, current/cost/reserve, totem/shock/imbue/dispels; thresholds принадлежат профилю.
8. **`AbilityEligibility`** — единственный final READY, per-spell rank/target/range/cooldown group/resource/recipient/equipment/reagent; `UNKNOWN→STOP` при критическом неизвестном факте. Все новые `Needs`/action types только через versioned `Profile_Contract`, QA-06 purity, lazy reads.

**Требуемые изменения (полный текст)**

**Требуемые работы**

1. Подтвердить Shaman spell IDs/ranks/families, totem API, shock group, weapon imbues, dispel capabilities и resurrection по WoW Forever QA-04.
2. Реализовать универсальный TotemStateProvider с per-element slot, remaining, destroyed/replaced и UNKNOWN.
3. Проверить position/radius API и per-party member coverage; если источник недоступен — UNKNOWN, не эвристика по buff.
4. Подключить shock shared CD через **существующую запланированную общую задачу CL-03 CooldownGroupProvider**; никакого отдельного shaman cooldown таймера.
5. Подключить imbues через **IT-10 WeaponEnchantProvider** и per-hand equipment eligibility.
6. Подключить Cure Poison/Disease через общий DispelStateProvider и FriendlyUnitSelectionProvider; тотемное очищение учитывать отдельно.
7. Подключить Ancestral Spirit через **CL-02/CL-05 friendly_dead**, не изменять live-only healing gate.
8. Спроектировать SelfResurrectionStateProvider для Reincarnation и проверить, допускает ли клиент показ рекомендуемого действия.
9. Добавить 24 QA-07 scenarios, reason codes, QA-06 purity, unit/mock tests Lua 5.1, затем client QA, без GitHub Actions до ручного финального этапа.
10. Синхронизировать Profile Registry, Test/Priority Matrix и API Matrix при реализации, провести регрессию CooldownGroup/WeaponEnchant/Dispel/FriendlyUnit на Hunter/Rogue/Paladin/Priest.

**Диагностика:** `shaman_totem_unknown`, `shaman_totem_slot_replaced`, `shaman_totem_expired`, `shaman_totem_radius_unknown`, `shaman_totem_ally_out_of_range`, `shaman_shock_shared_cd_active`, `shaman_shock_shared_cd_unknown`, `shaman_imbue_mh_missing`, `shaman_imbue_oh_unknown`, `shaman_imbue_weapon_missing`, `shaman_dispel_type_unknown`, `shaman_dispel_target_unavailable`, `shaman_resurrection_target_alive`, `shaman_reincarnation_unavailable`, `shaman_reincarnation_state_unknown`, `shaman_snapshot_stale`. Secret payload не логировать.

**Тесты и диагностика**

**QA-07: сценарии «состояние → ожидаемое действие» (спецификация, NOT RUN)**

| ID | Состояние | Ожидаемое решение |
|---|---|---|
| `SHA-TOTEM-01` | нужный totem стоит и не истекает | не обновлять |
| `SHA-TOTEM-02` | слот занят другим totem | replacement только по profile policy и Eligibility |
| `SHA-TOTEM-03` | totem exists UNKNOWN | STOP для зависящего правила |
| `SHA-TOTEM-04` | totem существует, ally вне подтверждённого радиуса | не считать ally покрытым buff |
| `SHA-TOTEM-05` | position/radius UNKNOWN | не утверждать coverage |
| `SHA-TOTEM-06` | totem уничтожен/истёк | re-evaluate после revision, не stale READY |
| `SHA-SHOCK-01` | Earth Shock применён, shared CD активен | Flame/Frost Shock BLOCKED |
| `SHA-SHOCK-02` | per-spell CD ready, shared CD UNKNOWN | STOP |
| `SHA-SHOCK-03` | shared CD ready, конкретный shock blocked | BLOCKED по per-spell Eligibility |
| `SHA-SHOCK-04` | Flame Shock DoT активен и срок достаточен | не обновлять без profile threshold |
| `SHA-IMBUE-01` | MH Windfury есть, OH отсутствует | оценивать только OH |
| `SHA-IMBUE-02` | OH remaining UNKNOWN | не перезаписывать вслепую |
| `SHA-IMBUE-03` | нет совместимого оружия | imbue BLOCKED |
| `SHA-IMBUE-04` | другой enchant на слоте | replacement только по утверждённой policy |
| `SHA-DISPEL-01` | ally имеет подтверждённый Poison | Cure Poison eligible после gate |
| `SHA-DISPEL-02` | ally имеет подтверждённый Disease | Cure Disease eligible после gate |
| `SHA-DISPEL-03` | dispel type UNKNOWN | STOP, не гарантировать очищение |
| `SHA-DISPEL-04` | Poison Cleansing Totem стоит, дебафф ещё есть | не считать dispel уже завершённым |
| `SHA-REZ-01` | dead friendly OOC, Ancestral Spirit eligible | `friendly_dead` READY |
| `SHA-REZ-02` | alive friendly | Ancestral Spirit BLOCKED |
| `SHA-REINC-01` | player alive | Reincarnation не рекомендовать |
| `SHA-REINC-02` | player dead, availability confirmed | показывать только если клиентский action contract разрешает |
| `SHA-REINC-03` | reagent/cooldown UNKNOWN | STOP, не фиктивный READY |
| `SHA-REVISION-01` | totem/shock/weapon/party/death changed | invalidate stale state, reevaluate |

Каждый сценарий должен иметь `profileID`, spellID/rank, evidence, expected action/status/reason/channel, reads и статусы MOCK/CLIENT отдельно. **Все сценарии пока NOT RUN**; это не тестовое покрытие реальных Shaman профилей.

**Архитектурные и обратные ссылки:** CL-09, CL-02, CL-05, CL-03, IT-10, CL-04, QA-06, QA-07, SHA-TOTEM-01, SHA-TOTEM-02, SHA-TOTEM-03, SHA-TOTEM-04, SHA-TOTEM-05, SHA-TOTEM-06, SHA-SHOCK-01, SHA-SHOCK-02, SHA-SHOCK-03, SHA-SHOCK-04, SHA-IMBUE-01, SHA-IMBUE-02, SHA-IMBUE-03, SHA-IMBUE-04, SHA-REZ-01, SHA-REZ-02, SHA-REINC-01, SHA-REINC-02, SHA-REINC-03, QA-04, CL-07.

---

### CL-07 — Маг: мана и порог, брони и интеллект, Polymorph/контроль, «превосходство», заморозка, «зачарование», создание еды и восстановление маны

ID: [CL-07](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9599). Приоритет: P0. Lua: упомянут (точный статус в источнике).

**Вердикт / статус**

**Вердикт**

**ЧАСТИЧНО ПО ОБЩИМ ПРИМИТИВАМ / MAGE-SPECIFIC КОНТРАКТ НЕ РЕАЛИЗОВАН / P0.** Есть ресурсы, target, aura, spell Eligibility; нет доказанного CC safety, frozen/root semantics, group buff recipient, conjure inventory и mana gem gates. «Превосходство» и «зачарование» остаются неразрешёнными терминами. Mage профилей нет. **SOURCE/DOC AUDIT PASS; LUA 5.1 NOT RUN; CI NOT RUN; WOW FOREVER NOT RUN; CLIENT PASS 0/101.** Lua/TOC/ZIP не менялись.

**Ретроактивные ссылки:** CL-02, CL-03, CL-05, CL-06, IT-04, IT-06, EN-04, QA-07, QA-04, EN-A1.

**Выбранный путь Kord**

в файле не указано

**Требуемые изменения (полный текст)**

**Требуемые работы**

1. Сверить по WoW Forever spell/rank/family catalog и уточнить «превосходство», «зачарование», «подкрепление маны» без догадок.
2. Подключить typed mana cost/reserve и configurable thresholds к ResourceStateProvider.
3. Реализовать Mage armor exclusive family, intellect group coverage через общие Aura/FriendlyUnit providers.
4. Подключить Polymorph и breakable CC к общему CrowdControl/EnemyCCSafetyProvider, EN-04.
5. Реализовать RootFreezeStateProvider, не путать slow и frozen, подтвердить freeze/pet mechanics.
6. Подключить Conjure Food/Water к общему ItemCreation/InventoryProvider, учитывать bags, rank, quantity.
7. Подключить Conjure Mana Gem/consume к IT-06, различать SPELL и ITEM, проверять charges/cooldown.
8. Подключить Evocation через ChannelStateProvider и mana recovery, Mana Shield через defensive/mana spend.
9. Добавить 26 QA-07 сценариев, QA-06 purity, diagnostics, Lua 5.1 mocks и затем отдельную проверку в WoW Forever.
10. Синхронизировать API/Test/Priority Matrix и Profile Registry при реализации, регрессия общих providers на Paladin/Hunter/Priest/Shaman; не запускать GitHub Actions автоматически.

**Диагностика:** `mage_mana_reserve`, `mage_mana_cost_unknown`, `mage_armor_unknown`, `mage_intellect_recipient_unknown`, `mage_polymorph_break_risk`, `mage_polymorph_immunity_unknown`, `mage_frozen_unknown`, `mage_slow_not_frozen`, `mage_catalog_alias_unresolved`, `mage_conjure_inventory_unknown`, `mage_conjure_bag_full`, `mage_mana_gem_missing`, `mage_mana_gem_charges_unknown`, `mage_evocation_channel_active`, `mage_mana_shield_resource_spend`, `mage_snapshot_stale`.

**Тесты и диагностика**

**QA-07: сценарные таблицы «состояние → ожидаемое действие» (NOT RUN)**

| ID | Состояние | Ожидаемое решение |
|---|---|---|
| `MAG-MANA-01` | mana ниже cost+reserve | BLOCKED |
| `MAG-MANA-02` | mana cost UNKNOWN | STOP для зависимого правила |
| `MAG-ARMOR-01` | нужная armor активна, срок достаточен | не обновлять |
| `MAG-ARMOR-02` | armor family UNKNOWN | не переключать вслепую |
| `MAG-INT-01` | ally lacks Arcane Intellect | выбрать именно ally |
| `MAG-INT-02` | Arcane Brilliance требует отсутствующий reagent | BLOCKED при подтверждённом требовании |
| `MAG-POLY-01` | target Polymorph active, AoE может разбить | не рекомендовать опасное AoE |
| `MAG-POLY-02` | target CC immunity UNKNOWN | STOP для обязательного CC rule |
| `MAG-POLY-03` | Polymorph remaining достаточен | не обновлять |
| `MAG-POLY-04` | breakable CC рядом с Blizzard/Arcane Explosion | запретить unsafe AoE |
| `MAG-SUPER-01` | «превосходство» не сопоставлено spellID | `catalog_alias_unresolved`, STOP |
| `MAG-FREEZE-01` | target slowed, not frozen | не считать frozen |
| `MAG-FREEZE-02` | frozen confirmed, spell eligible | применить профильное frozen-dependent правило |
| `MAG-FREEZE-03` | frozen state UNKNOWN | STOP |
| `MAG-ENCHANT-01` | «зачарование» не сопоставлено эффекту | `catalog_alias_unresolved`, STOP |
| `MAG-CONJURE-01` | food absent, conjure eligible, bag space | Conjure Food по профилю |
| `MAG-CONJURE-02` | conjured food exists enough | не создавать повторно |
| `MAG-CONJURE-03` | inventory/bag space UNKNOWN | STOP для dependent rule |
| `MAG-GEM-01` | gem exists, usable, mana below threshold | ITEM только после Eligibility |
| `MAG-GEM-02` | gem absent, Conjure Mana Gem eligible | SPELL conjure, не ITEM consume |
| `MAG-GEM-03` | gem charges/cooldown UNKNOWN | STOP |
| `MAG-EVOC-01` | mana low, Evocation ready, channel safe | SPELL по профилю |
| `MAG-EVOC-02` | Evocation channel active | не повторять cast и не клиппить |
| `MAG-SHIELD-01` | Mana Shield active | учитывать расход маны, не восстановление |
| `MAG-REVISION-01` | mana/CC/armor/inventory/party changed | invalidate stale snapshot |
| `MAG-CHANNEL-01` | buff/food OOC vs combat DPS | channel routing согласно UI policy |

Все кейсы требуют реальных `profileID`, spellID/rank, snapshot, expected action/status/reason/channel, provider read counts и evidence. Пока нет зарегистрированных Mage профилей, это **сценарная спецификация**, не готовое тестовое покрытие.

**Архитектурные и обратные ссылки:** CL-09, CL-08, IT-10, QA-04, CL-02, CL-05, CL-06, CL-03, EN-04, IT-04, IT-06, QA-07, MAG-MANA-01, MAG-MANA-02, MAG-ARMOR-01, MAG-ARMOR-02, MAG-INT-01, MAG-INT-02, MAG-POLY-01, MAG-POLY-02, MAG-POLY-03, MAG-POLY-04, MAG-SUPER-01, MAG-GEM-01, MAG-GEM-02, MAG-GEM-03, MAG-EVOC-01, MAG-EVOC-02, QA-06.

---

### CL-08 — Чернокнижник: осколки душ, питомец (призыв, смена), проклятия, DoT, жизненный отвод, камни здоровья, страх, портал

ID: [CL-08](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9713). Приоритет: P0. Lua: упомянут (точный статус в источнике).

**Вердикт / статус**

**Вердикт**

**ЧАСТИЧНО ПО ОБЩИМ ПРИМИТИВАМ / WARLOCK-SPECIFIC КОНТРАКТ НЕ РЕАЛИЗОВАН / P0.** Есть общие resources, target, pet, aura, spell Eligibility; shard budget, demon family, dual Curse/Bane, safe Life Tap, stone/ritual lifecycle и Fear safety end-to-end не подтверждены. **SOURCE/DOC AUDIT PASS; LUA 5.1 NOT RUN; CI NOT RUN; WOW FOREVER NOT RUN; CLIENT PASS 0/101.** Lua/TOC/ZIP не менялись.

**Архитектурные и ретроактивные ссылки:** IT-01, IT-05, IT-03, PE-01–PE-06, CL-03, CL-04, CL-05, CL-07, EN-04, EN-06, AC-02, AC-03, AC-07, QA-04, QA-07, EN-A1. В этом коммите обратные ссылки внесены в CL-03/04/05/07, IT-01/05, PE-01/04/06, EN-04/06, AC-03, QA-04/07. Остальные механизмы остаются прежними без дублирования.

**Выбранный путь Kord**

**Выбранный путь Kord**

**Один Warlock policy layer на общей инфраструктуре, а не самостоятельный модуль-ротационный движок.** Для shards использовать IT-01 inventory/item family и IT-05 reagent budget; логический `SoulShardObservation` не создает второй bag scanner. `DemonPetObservation` расширяет PE-01–PE-05 единого `PetObservation` по owner/pet GUID, идентичность демона и pet spell availability; pet actions только AC-03, guardians и ритуал PE-06. `CurseFamilyProvider` — **конфигурация общего `AuraStateProvider`**: на пару (`targetGUID`, `casterGUID`) два независимых exclusive slots `BANE` и `CURSE`, а остальные DoT остаются отдельными `DotCoverageObservation`; это расширение общих CL-05/EN-04/EN-06, без второго per-class aura scanner. `LifeTapSafetyPolicy` использует CL-05/CL-07 `ResourceStateProvider` и health evidence, стоимость **конкретного ранга**; `StoneLifecyclePolicy` существует строго по IT-05. `FearControlObservation` использует общие `CrowdControlStateProvider`/EN-04; `SummoningRitualObservation` — world/group constraints и PE-06, но не выводит portal present из завершения cast.

Lazy `Needs`, per-evaluation cache, EventBus revisions `bag/pet/auras/target/resources/cast/group/world` с доказанными событиями; непрочитанное/secret `UNKNOWN`, обязательное `UNKNOWN→STOP` по AC-07, разрешённый `skip` только если профиль доказал безопасность. Конечный `READY` выдаёт **только `AbilityEligibility`**. `SPELL`, `ITEM`, `PET_COMMAND`, `WAIT`, `STOP` строго по существующему versioned Profile_Contract EN-A1/AC-01–AC-07; не вызывать protected действия. Новые имена — **логические контракты**, отдельные Lua-файлы не обязательны без доказанной необходимости.

**Требуемые изменения (полный текст)**

**Требуемые изменения**

1. На WoW Forever подтвердить все Warlock spellID/ranks, items, costs, Curse/Bane exclusive behavior, pet species и ritual; внести только доказанные сведения в `Ability_Catalogue.md`, `Research_Evidence.md` и QA-04, неизвестное — UNKNOWN.
2. Реализовать `SoulShardObservation` поверх IT-01/IT-05: validated `C_Item.GetItemCount`/legacy, bag revisions, reserved/current/available, pending creation arrival; не использовать `or 0` при secret и не считать каст фактом получения shard.
3. PE-01–PE-05: demon species/owner GUID, health/exists/dead/actionability, pending summon, смена демона, Fel Domination/Demonic Sacrifice; invalidation при `UNIT_PET`, event correlation с ограниченным TTL, без ложного present.
4. Pet Spell Lock/Seduction/Devour Magic: PE-04/AC-03, petbook/actionbar/cooldown/target, immunity и secret; проверка availability именно для current species; no protected pet execution.
5. `AuraStateProvider`: `BANE` и `CURSE` отдельно по target/caster GUID, overwriting и собственный aura owner, rank/remaining; обычные Corruption/Immolate/Siphon Life/Wrack отдельно, safe refresh, TTL/revisions.
6. EN-06 per-GUID мультидот и TTD (estimated) и сохранение EN-04 CC safety; безопасный channel check для Drain Soul/Drain Life/Health Funnel, не клиппить без доказанной policy.
7. Life Tap: HP cost и mana gain по рангу, health reserve, combat policy, source provenance; при secret/unknown здоровье STOP, не подставлять фиксированные 40% из референса.
8. IT-05/IT-01–04/AC-02: полный healthstone/soulstone create/use/apply lifecycle, rank, reagent budget, shared CD и delayed item arrival, без копий providers.
9. Fear/Howl/Banish/Death Coil/Seduction по общему CC provider, AoE/control safety EN-04, иммунитет/DR только если подтверждён.
10. Ritual of Summoning: проверить party/participant/reagent/zone/combat/channel/portal lifecycle; отличить Ritual of Doom, без protected interaction, при непроверяемом portal state вернуть UNKNOWN.
11. Versioned Needs, `GameAPI` allowlist, `EventBus` и `AbilityEligibility` обновлять после API validation, с DevTools-only `reason/source/revision`, без нового движка; профили строго по `Kord_Warlock_<Spec>_<Leveling|60>_<PVE|PVP>.lua` после согласования Spec abbreviations.
12. QA-07 fixtures, QA-06 purity, Lua 5.1 mocks, регрессия IT-05, CL-03 pet, CL-05 Dot, CL-07 mana, EN-04; клиентские проверки отдельно, GitHub Actions только ручной финальный прогон.

**DevTools-only причины:** `warlock_shard_count_unknown`, `warlock_shard_insufficient`, `warlock_shard_reserved`, `warlock_shard_arrival_pending`, `warlock_pet_species_unknown`, `warlock_pet_dead`, `warlock_pet_not_actionable`, `warlock_pet_summon_pending`, `warlock_pet_spell_unknown`, `warlock_bane_slot_active`, `warlock_curse_slot_active`, `warlock_aura_owner_unknown`, `warlock_dot_remaining_unknown`, `warlock_dot_target_stale`, `warlock_lifetap_cost_unknown`, `warlock_lifetap_health_unsafe`, `warlock_healthstone_unknown`, `warlock_fear_break_risk`, `warlock_fear_immunity_unknown`, `warlock_ritual_participant_unknown`, `warlock_ritual_reagent_unknown`, `warlock_portal_state_unknown`, `warlock_revision_stale`.

**Тесты и диагностика**

**QA-07: сценарии «состояние → ожидаемое действие» (SPECIFIED / NOT RUN)**

| ID | Вход | Ожидаемый ответ |
|---|---|---|
| `WL-SHARD-01` | count 0, spell requires shard | BLOCKED |
| `WL-SHARD-02` | shard count secret | UNKNOWN→STOP |
| `WL-SHARD-03` | count 1, reserved 1 | не тратить на низший приоритет |
| `WL-SHARD-04` | Drain Soul success, bag unchanged | shard generation не подтверждена |
| `WL-PET-01` | pet absent, dead unknown | не выдавать revive/summon READY без policy |
| `WL-PET-02` | живой Imp, требуется Felhunter | проверять switch policy, reagent, cast |
| `WL-PET-03` | `UNIT_PET` меняет GUID | invalidate species/spells |
| `WL-PET-04` | нет Felhunter, Spell Lock requested | BLOCKED/UNKNOWN |
| `WL-PET-05` | pet species secret | UNKNOWN→STOP |
| `WL-CURSE-01` | собственный Bane активен, Curse нет | Curse eligible отдельно |
| `WL-CURSE-02` | Curse уже есть, другой Curse requested | замена по explicit policy |
| `WL-CURSE-03` | aura чужого warlock | не считать собственной |
| `WL-CURSE-04` | owner secret | UNKNOWN→STOP |
| `WL-DOT-01` | Corruption remaining достаточен | no refresh |
| `WL-DOT-02` | remaining ниже окна | refresh при Eligibility |
| `WL-DOT-03` | target GUID changed | не переносить cached aura |
| `WL-DOT-04` | multi-target TTD UNKNOWN | no guessed TTD gate |
| `WL-CHANNEL-01` | Drain Soul channel ongoing | no unapproved clip |
| `WL-TAP-01` | mana low, HP reserve verified safe | Life Tap только если eligible |
| `WL-TAP-02` | HP secret | STOP |
| `WL-TAP-03` | rank healthCost unknown | STOP |
| `WL-TAP-04` | Health Funnel channeled | не считать Life Tap free |
| `WL-STONE-01` | Healthstone owned and usable, HP below threshold | ITEM via IT-05 |
| `WL-STONE-02` | stone absent, shard enough, create known | SPELL create via IT-05 |
| `WL-STONE-03` | Soulstone owned, aura absent, friendly eligible | APPLY via IT-05 |
| `WL-STONE-04` | create cast success, bag data pending | WAIT only when pending confirmed |
| `WL-FEAR-01` | target breakable fear, AoE queued | block unsafe AoE |
| `WL-FEAR-02` | fear immunity unknown | STOP for fear-dependent rule |
| `WL-RITUAL-01` | ritual reagent missing | BLOCKED |
| `WL-RITUAL-02` | participants unobservable | UNKNOWN→STOP |
| `WL-RITUAL-03` | cast succeeded, portal entity unknown | no portal-present assertion |
| `WL-REVISION-01` | pet/target/aura/bag changed | invalidate affected cached providers |

Таблица — **спецификация**, не исполняемый suite; для реального профиля требуются approved spellID/rank, priority, channel, source SHA, expected reason, read counts, fixture и игровые доказательства.

**Архитектурные и обратные ссылки:** CL-09, IT-05, QA-04, IT-01, PE-01, PE-05, PE-04, AC-03, EN-06, EN-04, PE-06, CL-05, CL-07, AC-07, AC-01, AC-02, QA-07, QA-06, CL-03, WL-SHARD-01, WL-SHARD-02, WL-SHARD-03, WL-SHARD-04, WL-PET-01, WL-PET-02, WL-PET-03, WL-PET-04, WL-PET-05, WL-CURSE-01, WL-CURSE-02, WL-CURSE-03, WL-CURSE-04, WL-DOT-01, WL-DOT-02, WL-DOT-03, WL-DOT-04, WL-TAP-01, WL-TAP-02, WL-TAP-03, WL-TAP-04, WL-STONE-01, WL-STONE-02, WL-STONE-03, WL-STONE-04, WL-FEAR-01, WL-FEAR-02, IT-03, CL-04.

---

### CL-09 — Друид: облики и смена облика, ярость, энергия, мана в обликах, очки комбо, HoT, воскрешение, снятие яда и проклятий, срыв ауры

ID: [CL-09](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L9827). Приоритет: P0. Lua: упомянут (точный статус в источнике).

**Вердикт / статус**

**Вердикт**

**ЧАСТИЧНО ПО ОБЩИМ ПРИМИТИВАМ / DRUID-SPECIFIC КОНТРАКТ НЕ РЕАЛИЗОВАН / P0.** Существуют общие ресурсы, ауры, spell eligibility и event bus, но нет end-to-end form, parallel typed resources, combo ownership, HoT group coverage, Revive/Rebirth/Dispel и безопасного aura cancel. **SOURCE/DOC AUDIT PASS; LUA 5.1 NOT RUN; CI NOT RUN; WOW FOREVER NOT RUN; CLIENT PASS 0/101.** Lua/TOC/ZIP не менялись.

**Архитектурные ссылки:** PL-09, CL-01/02/04/05/06/07/08, AC-05, AC-07, DA-08, EN-A1, QA-04/07; обратные ссылки в этих ранее существовавших требованиях внесены в этом же коммите. Следующий этап — не считать Druid профиль готовым до реальной реализации и тестов.

**Выбранный путь Kord**

**Выбранный путь Kord: универсальные провайдеры, без дублирования**

1. **`FormStanceObservation` (PL-09/AC-05)** — единый shared provider для Warrior stance, Druid form и иных переключаемых режимов; Druid-specific `DruidFormPolicy` только задаёт допустимые переходы, form family, spell requirements и manual exit. Состояние `currentFormIndex`, `formSpellID`, `formFamily`, `active`, `source/reason/revision` независимо от aura state.
2. **`ResourceStateProvider` (CL-01/CL-04/CL-05/CL-07)** — один typed multi-resource snapshot `MANA/RAGE/ENERGY/COMBO_POINTS`, а не отдельный Druid scanner. Для каждого `value/max/percent/availableInCurrentForm/source/reason`; неактивный тип UNKNOWN, если API не даёт значение. Сохранение энергии/очков после смены формы не предполагать без client proof.
3. **`ComboPointObservation` (CL-04)** — target GUID, current/cap, finisher requirements, loss/transfer on target change, form-specific gates; общая инфраструктура, отдельная Feral policy.
4. **`AuraStateProvider` + `HoTCoverageObservation` (CL-05/CL-08)** — один per-caster/per-recipient GUID aura scanner с HoT family/rank/remaining/stacks/refresh/ownership; `FriendlyUnitSelectionProvider` для party/raid, без второго сканера лечения.
5. **`ResurrectionStateProvider` (CL-02/CL-05/CL-06)** — общий выбор умершего союзника и ограничения боя, с отдельными policy `Revive` и `Rebirth`; client-only battle resurrection quota не выдумывать.
6. **`DispelStateProvider` (CL-02/CL-05/CL-06)** — общий `dispelName`/target/aura eligibility и отдельная capability mapping Cure/Abolish Poison/Remove Curse; периодический эффект Abolish — отдельный тип, не прямой dispel.
7. **`AuraCancellationObservation`** — общий read-only контракт отменяемой self aura и выхода из формы, расширяющий PL-09/AC-05, **не** механизм автоматического `CancelAura`. Неразрешённый «срыв ауры» → `catalog_alias_unresolved`, STOP зависимого правила; пользовательская подсказка только при доказанном безопасном действии.
8. **`AbilityEligibility`** — единственный итоговый READY для `SPELL`/`STANCE_OR_FORM`/`WAIT`/`STOP`; typed `Needs`, lazy short-circuit, `UNKNOWN→STOP` (AC-07), per-evaluation memo и EventBus revisions form/resources/target/auras/group/cast/identity. `UPDATE_SHAPESHIFT_FORM` должен инвалидировать не только actionbar, но и form/resources/eligibility; только при подтверждённой семантике событий.

Все логические имена — **контракты**, не требование создавать отдельный Lua-файл на каждый. Нет второго движка, самостоятельного class scanner, чтения WoW API непосредственно из профилей или автоматического protected action.

**Требуемые изменения (полный текст)**

**Требуемые изменения**

1. Проверить на Forever build `GetShapeshiftForm/Info`, `GetShapeshiftFormID` (если есть), spell/form mapping, rank, action restrictions и формы по QA-04; не смешивать index/formID/spellID.
2. Расширить PL-09/AC-05 общим `FormStanceObservation` и Druid form policy: caster/Cat/Bear/Dire Bear/Moonkin/Travel/Aquatic, explicit manual exit, invalidation и `UNKNOWN`.
3. Расширить общий `ResourceStateProvider` до typed MANA/RAGE/ENERGY/COMBO, включая hidden/inactive mana, safe secret, cost/reserve и form transition; проверить Forever continuous energy vs legacy ticks.
4. Добавить target-GUID combo/finisher eligibility с form/range/energy/CP checks, не переносить комбо на новую цель без доказательства.
5. Добавить HoT family/rank/owner/recipient/remaining, `Swiftmend` requirements и group `Wild Growth` coverage через общий Aura/Friendly provider; secret HP не превращать в low HP.
6. Реализовать единый `ResurrectionStateProvider`: Revive OOC vs Rebirth combat, dead-friendly selection, cooldown, reagent и success confirmation.
7. Расширить общий `DispelStateProvider`: Curse/Poison, Cure/Abolish periodic distinction, recipient/range/mana/form checks, неизвестные dispel flags → STOP.
8. Уточнить пользовательский термин «срыв ауры» по игровому эффекту; до этого сохранить unresolved alias и запрет protected automatic cancel. Отдельно проверять форму, self buff и channel.
9. Связать form/resources/auras/cast/group/target revisions с `EventBus`/DA-08, lazy `Needs` и `AbilityEligibility`; миграция только по EN-A1 с отказом несовместимых профилей.
10. Составить QA-07 Lua 5.1 mock fixtures, раздельные source/client proofs и DevTools trace для Druid, регрессию CL-01/02/04/05/06/07/08, PL-09/AC-05; GitHub Actions только на согласованном финальном QA.

**DevTools-only reasons:** `druid_form_unknown`, `druid_form_mismatch`, `druid_form_transition_pending`, `druid_form_spell_unavailable`, `druid_resource_type_unknown`, `druid_inactive_mana_unknown`, `druid_energy_regen_unverified`, `druid_combo_target_unknown`, `druid_combo_insufficient`, `druid_hot_owner_unknown`, `druid_hot_remaining_unknown`, `druid_hot_target_unavailable`, `druid_swiftmend_prerequisite_unknown`, `druid_resurrection_target_unknown`, `druid_rebirth_cooldown_unknown`, `druid_dispel_type_unknown`, `druid_abolish_periodic_unknown`, `druid_aura_cancel_unresolved`, `druid_aura_not_cancellable`, `druid_revision_stale`.

**Тесты и диагностика**

**Требование: конкретные способности, состояния и безопасные проверки**

| Механика | Способности / семейства (Forever-oriented источники, не CLIENT PASS) | Нормативные проверки |
|---|---|---|
| Облики и переключение | Bear Form `5487`, Dire Bear Form `9634`, Cat Form `768`, Moonkin Form `24858`, Travel Form `783`, Aquatic Form `1066`, caster/no form; отдельные доступные Forever формы — по каталогу | `GetShapeshiftForm()` + `GetShapeshiftFormInfo(index)` (матрица #34), learned spell/rank, current form identity, mutually exclusive family, action availability, mana cost, cast/GCD, combat/zone/movement restrictions, form-dependent spell eligibility. Не приравнивать Blizzard index к spellID или Forever formID; `nil`/secret → UNKNOWN, не caster. Смена — AC-05 `STANCE_OR_FORM`, не protected `CastShapeshiftForm` |
| Ресурсы по формам | Bear/Dire Bear: RAGE; Cat: ENERGY + COMBO_POINTS; caster/Moonkin: MANA; `Shifting Power` `1322605`, `Enrage` `5229`, `Innervate` `29166` | Typed resource observations одновременно для `MANA`, `RAGE`, `ENERGY`, `COMBO_POINTS`, включая доступность ресурса вне активного облика, cap/percent/regen, spell cost и reserve. Нельзя читать только `UnitPowerType('player')` и заключать, что маны в форме нет; нельзя считать неактивный ресурс нулём. Не переносить Rogue energy ticks в Forever Druid: Sonah отмечает continuous regen; проверить на клиенте. `Shifting Power` — отдельный spell с проверкой mana→energy, cooldown и cat form, **не** классический powershifting |
| Комбо и финишеры | `Claw` `1082`, `Rake` `1822`, `Shred` `5221`, `Rip` `1079`, `Ferocious Bite` `22568`, `Ravage` `6785`, `Pounce` `9005` (ID/ranks client-gated) | Combo count/cap/target GUID/ownership, finisher min CP, energy cost, cat form, target alive/range/position, DoT remaining, reset/transfer semantics on target/form changes **only after Forever validation**. UNKNOWN combo/target → STOP, не финisher READY |
| HoT и лечение | `Rejuvenation` `774` (rank family), `Regrowth` `8936` (rank family), `Swiftmend` `18562`, `Wild Growth` `408120` (Forever variants), `Healing Touch` `5185`, `Tranquility` `740`; `Lifebloom` **не считать существующим в Forever** без проверки | Unit player/party/raid, friendly/exists/alive, source/caster GUID, exact HoT family/rank/stacks/remaining, recipient HP with secret-safe UNKNOWN, refresh window, direct vs periodic heal, `Swiftmend` consumption/eligibility only when verified, Wild Growth group coverage, range/LOS/mana/cast/channel; не считать HoT чужого caster своим и не считать недоступное здоровье низким |
| Воскрешение | `Revive` `437138` и Forever rank family `1237948–1237951`; `Rebirth` `20484/20739/20742/20747/20748` | Разделить обычное out-of-combat Revive и combat resurrection Rebirth: target dead, friendly, accessible, range, mana/reagent (если требуется конкретному рангу), spellbook, cooldown/shared battle-res charges только если подтверждены, combat restriction, cast/zone/group policy. Dead target не пропускать через alive-only friendly selection. Cast success ≠ доказательство alive |
| Снятие яда/проклятия | `Cure Poison` `8946`, `Abolish Poison` `2893`, `Remove Curse` `2782` | `Poison` и `Curse` — разные `dispelName` и spell capabilities; friendly target, aura source/dispel eligibility, remaining/periodic effect, cast/GCD/mana/range, current form restriction, priority between recipients, ability known/rank. `Abolish Poison` как periodic cleansing buff не приравнивать к instant Cure Poison; не обещать Magic/Disease dispel |
| Срыв ауры / отмена формы | `Cancel Shapeshift`/return to caster; `CancelAura` и `CancelUnitBuff` — **только как потенциальные защищённые API, не как разрешённые автоматические действия** | Термин «срыв ауры» неоднозначен: различать (A) выход из формы, (B) отмену собственного отменяемого бафа, (C) снятие hostile/friendly aura заклинанием dispel, (D) прерывание channel. Для каждого нужны exact aura/form, owner, cancellable flag, policy и client capability. Не удалять собственный HoT/defensive buff вслепую, не пытаться снимать чужую/uncancellable aura, не выдавать protected cancel как автоматизируемое действие. Для отмены формы — только `STANCE_OR_FORM`/ручная подсказка при подтверждённой необходимости; до уточнения значения «срыв ауры» — `catalog_alias_unresolved` и STOP для зависимого правила |
| Способности в форме и эффекты смены | `Faerie Fire` `770` (form-specific variant/cooldown проверить), `Barkskin` `22812`, `Prowl` `5215`, `Dash` `1850`, `Frenzied Regeneration` `22842`, `Mark of the Wild` `1126` | Spell form eligibility отдельно от активной ауры, stealth, mount/travel restrictions, GCD/cooldown, resource switch and preservation, threat/defensive effects. Не считать форму и баф взаимозаменяемыми; не советовать выйти из формы ради buff/heal без явной policy, безопасной стоимости и допустимости в текущем бою |

**Нормативные различия Forever:** `Sonah/Classes/Druid.lua:6–24` утверждает, что классический powershifting отсутствует, Furor сохраняет энергию Cat при выходе, `Shifting Power` конвертирует ману в энергию, а `Lifebloom` отсутствует. Это **сведения референса, не доказательство текущего клиента**. Никакого автоматического `Cat→caster→Cat` ради восстановления энергии; не переносить фиксированные пороги, стоимость, уровни изучения и особенности чужих версий без QA-04. При расхождении Forever build — UNKNOWN, не Classic/Retail fallback.

**QA-07: сценарии «состояние → ожидаемое действие» (SPECIFIED / NOT RUN)**

| ID | Состояние | Ожидаемый результат |
|---|---|---|
| `DRU-FORM-01` | Cat already active, Cat requested | не переключать повторно |
| `DRU-FORM-02` | form API nil/secret | UNKNOWN→STOP |
| `DRU-FORM-03` | Bear current, Cat action desired | explicit policy + eligibility before transition |
| `DRU-FORM-04` | `UPDATE_SHAPESHIFT_FORM` | invalidate form/resources/eligibility |
| `DRU-FORM-05` | index and spellID differ | no ID conflation |
| `DRU-RESOURCE-01` | Cat energy known, mana inactive unknown | no fake mana=0 |
| `DRU-RESOURCE-02` | Bear rage insufficient | BLOCKED |
| `DRU-RESOURCE-03` | Shifting Power requested outside Cat | BLOCKED/UNKNOWN per verified policy |
| `DRU-RESOURCE-04` | energy regeneration timing unknown | no fixed tick assumption |
| `DRU-RESOURCE-05` | form changes, energy old snapshot | invalidate, no stale READY |
| `DRU-COMBO-01` | Cat, 5 CP on same GUID, finisher eligible | READY only after Eligibility |
| `DRU-COMBO-02` | CP count secret | STOP |
| `DRU-COMBO-03` | target GUID changes | no stale combo transfer |
| `DRU-COMBO-04` | CP enough, energy insufficient | BLOCKED |
| `DRU-HOT-01` | own Rejuvenation remaining sufficient | no refresh |
| `DRU-HOT-02` | HoT belongs to other caster | not own HoT |
| `DRU-HOT-03` | HoT remaining secret | UNKNOWN→STOP |
| `DRU-HOT-04` | ally health secret | no invented healing threshold |
| `DRU-HOT-05` | Swiftmend prerequisites unknown | STOP |
| `DRU-RES-01` | dead ally OOC, Revive eligible | recommend Revive |
| `DRU-RES-02` | dead ally in combat, Rebirth eligible | recommend Rebirth |
| `DRU-RES-03` | Rebirth cooldown unknown | STOP |
| `DRU-RES-04` | resurrection cast success, target still dead | not confirmed alive |
| `DRU-DISPEL-01` | Poison on ally, Cure Poison known | recommend only after type+eligibility |
| `DRU-DISPEL-02` | Curse on ally, Remove Curse known | recommend only after type+eligibility |
| `DRU-DISPEL-03` | Magic debuff only | do not recommend unsupported dispel |
| `DRU-DISPEL-04` | Abolish Poison periodic effect active | do not confuse with instant cure |
| `DRU-CANCEL-01` | «срыв ауры» unspecified | unresolved alias, STOP |
| `DRU-CANCEL-02` | own noncancellable HoT | no automatic cancel |
| `DRU-CANCEL-03` | leaving Cat requires protected action | manual suggestion only |
| `DRU-REVISION-01` | form/target/group/aura changed | invalidate affected observations |

**QA статус:** сценарии заданы как спецификация, не исполнялись. Для каждого реального Druid profile отдельно потребуются approved priorities, exact source SHA, fixture, expected reason, read counts и client evidence.

**Архитектурные и обратные ссылки:** AC-05, QA-04, PL-09, CL-01, CL-04, CL-05, CL-07, CL-08, CL-02, CL-06, AC-07, DA-08, QA-07, DRU-FORM-01, DRU-FORM-02, DRU-FORM-03, DRU-FORM-04, DRU-FORM-05, DRU-COMBO-01, DRU-COMBO-02, DRU-COMBO-03, DRU-COMBO-04, DRU-HOT-01, DRU-HOT-02, DRU-HOT-03, DRU-HOT-04, DRU-HOT-05, DRU-RES-01, DRU-RES-02, DRU-RES-03, DRU-RES-04.

---

