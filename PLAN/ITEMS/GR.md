# Карточки GR

Источник: REQUIREMENTS.md, blob 9efdec1900398c978ea121818fb5950cb1620337.

### GR-01 — Члены группы: существует, жив, в зоне видимости, в радиусе способности

ID: [GR-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3888). Приоритет: P1.

**Вердикт**

**Вердикт**

**ЧАСТИЧНО РЕАЛИЗОВАНО — ДОРАБОТАТЬ (P1).** Kord имеет базовые existence/death/GUID и target spell-range API, но не подтверждён единый roster-wide provider с жизнью/видимостью/connected и spell-specific range по каждому члену группы/рейда.

**Архитектурные ссылки:** TG-01, TG-09, TG-11, SP-08, SP-14, TH-01. Обратные ссылки внесены в перечисленные ранее задачи в том же коммите.

**Изменения Lua:** отсутствуют. Только документация.

**Выбранный путь**

**Выбранный путь Kord (решение по результатам сравнения)**

**Выбрать универсальный platform/roster resolver RotationMaster + событийный `rosterDirty` Sonah/ForeverAuras + раздельные secret-safe member states ForeverAuras/JustAC + spell-specific range Sonah/RotationMaster.** Один общий `GroupRosterObservation` обслуживает будущие heal/dispel/buff/group/raid, TH-01 tank identity и другие потребители, без отдельного списка для каждого класса. `GROUP_ROSTER_UPDATE` и подтверждённые lifecycle events инвалидируют roster revision, ленивый rebuild по `Needs` выдаёт GUID-keyed snapshot с alias map и `coverage`; per-spell range вычисляется **только по запросу** и memoized на `(revision,memberGUID,spellID)` в рамках оценки, не сканирует весь рейд при каждом кадре. Численный TTL/rate budget измерить на клиенте Forever. `UnitIsVisible` не гарантирует line-of-sight и не доказывает, что spell применим; `IsSpellInRange` не доказывает castability, LOS или отсутствие immunity. При неизвестном результате вернуть UNKNOWN, а не `false`. Смена состава/фазы/алиаса или GUID между чтениями отменяет stale result. В solo учитывать `player` как единственного локального члена для запросов self, не объявлять его party1. Общий `AbilityEligibility` — единственный источник final READY.

**Требуемые изменения (полный текст)**

**Требуемые изменения**

1. Валидировать на Forever roster API (`GetNumGroupMembers`, `GetNumSubgroupMembers`, `IsInRaid`, `UnitExists`, `UnitGUID`, `UnitIsConnected`, `UnitIsVisible`, `UnitIsDeadOrGhost`, spell range), secret semantics и реальные unit aliases; расширить allowlist только подтверждёнными вызовами.
2. Ввести один GUID-keyed `GroupRosterObservation` с `player/partyN/raidN` aliases, dedup и snapshot `revision/observedAt/coverage`, без двойного учёта player в рейде.
3. Независимые tri-state поля existence, life, connected, visible и membership, с причиной/источником; `UNKNOWN` не подменять false.
4. Реализовать `GroupMemberSpellRangeObservation(memberGUID,spellID)` через общий spell range adapter, с alias+GUID guard, supported target policy и lazy per-evaluation memo; не использовать произвольную фиксированную дальность.
5. EventBus invalidation: `GROUP_ROSTER_UPDATE`, `PLAYER_ENTERING_WORLD`, смена GUID/phase/connectivity и подтверждённые unit events; bounded coalescing/heartbeat, без roster scans в `OnUpdate`.
6. Связать TH-01 tank role/actor aliases, TG-01/09/11 и SP-08/14 с новым единым roster provider, без замены их существующих contracts.
7. DevTools-only диагностика: `roster_api_unavailable`, `roster_secret`, `roster_incomplete`, `member_guid_changed`, `member_exists_unknown`, `member_dead_unknown`, `member_visible_unknown`, `member_connected_unknown`, `member_spell_range_unknown`, `member_spell_range_target_mismatch`, `roster_budget_exceeded`.
8. Тесты: solo/party/raid, player duplicate in raid, 0/1/40 members, join/leave/reorder, disconnect/reconnect, dead/ghost, visible but out of range, invisible but spell range unknown, same names different GUID, recycled party token, range spell A vs B, target-only spell on friendly, secret/nil, phase/LOS unknown, rapid roster updates, many consumers sharing one snapshot, stale revision, final Eligibility fails despite range true.
9. UI/DevTools: если добавлены настройки roster refresh, предоставить локализацию и подсказки на шести языках; не добавлять настройку без измеримого эффекта и документированной семантики.

**Тесты и диагностика**

в файле не указано

**Архитектурные и обратные ссылки:** PE-01, GR-06, GR-05, GR-04, GR-03, GR-02, TH-01, TG-01, SP-08, TG-09, TG-11, SP-14.

---

### GR-02 — Здоровье и ресурс членов группы, роль (танк, лекарь, ДД)

ID: [GR-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3951). Приоритет: P1.

**Вердикт**

**Вердикт**

**ЧАСТИЧНО РЕАЛИЗОВАНО — ДОРАБОТАТЬ (P1).** Kord имеет базовые health/power adapters для отдельных units, но не общий per-member roster-wide health/resource/role provider.

**Архитектурные ссылки:** GR-01, TH-01, TH-03, TG-02, SP-07. Обратные ссылки внесены в эти ранее существовавшие задачи в том же коммите.

**Изменения Lua:** отсутствуют. Только документация.

**Выбранный путь**

**Выбранный путь Kord (решение по результатам сравнения)**

**Основа — единый GR-01 `GroupRosterObservation` + role resolver RotationMaster/Sonah + секретобезопасные независимые health/power observations по существующему Kord GameAPI/GameState и паттерну ForeverAuras.** Не создавать второй список группы, class-specific roster, отдельный healing scanner или собственный вывод ролей по классам. Ввести логические `GroupMemberVitalsObservation(memberGUID)` и `GroupMemberRoleObservation(memberGUID)` поверх общего roster snapshot с per-pass memo и GUID guards. Для здоровья отдавать validated current/max и percent; если численные поля secret, использовать подтверждённый native percent API с самостоятельным статусом, не восстанавливать скрытые current/max. Для ресурса сначала проверять `UnitPowerType(memberUnit)`, затем `UnitPower/Max` с правильным типом и клиентскими исключениями; отсутствие power/max=0 не является «мана закончилась» без проверки. Для ролей использовать подтверждённый клиентский `UnitGroupRolesAssigned`/roster-role source; `NONE` сохранять как NONE и не угадывать DPS. Изменение состава, GUID, роли, unit state, power type и фазы инвалидирует соответствующую ревизию. При отсутствии подтверждённой поддержки API на Forever вернуть UNKNOWN с reason, не подменять speculative role inference.

**Требуемые изменения (полный текст)**

**Требуемые изменения**

1. Расширить GR-01 общим GUID-keyed roster member observation, переиспользовать его aliases/revision/coverage и lifecycle; не создавать дублирующий сканер.
2. Валидировать на Forever `UnitHealth/Max/Percent`, `UnitPower/Max/Type/Percent`, `UnitGroupRolesAssigned`, roster-role alternatives, значения `NONE`, secret/nil и доступность `partyN/raidN`.
3. Реализовать `GroupMemberVitalsObservation` с отдельными health/power statuses, powerType, current/max/percent, source, observedAt и reason; не смешивать ресурсы и не делить на 0.
4. Реализовать `GroupMemberRoleObservation`: `TANK/HEALER/DAMAGER/NONE/UNKNOWN`, source и revision, без выводов по классу, специализации или threat.
5. Ввести lazy `Needs` для member health/power/role, per-evaluation cache, bounded group refresh; не читать здоровье/ресурсы 40 человек при каждом запросе без потребности.
6. EventBus invalidation для roster/role changes, `UNIT_HEALTH`/power events, смены GUID, power type, disconnect/phase и heartbeat только после подтверждения поддержки событий; не считать событие гарантией наличия plain данных.
7. Связать будущие healing/dispel/buff/raid решения и TH-01/TH-03 tank role с единым GR-02; окончательная пригодность способности — через AbilityEligibility.
8. DevTools-only диагностика: `member_health_unknown`, `member_health_secret`, `member_health_invalid`, `member_power_type_unknown`, `member_power_secret`, `member_power_max_zero`, `member_role_unknown`, `member_role_none`, `member_role_changed`, `member_guid_changed`, `group_vitals_stale`.
9. Тесты: solo/party/raid, player duplicated in raid, 40 members, dead/ghost/disconnected, class with multiple power types, mana/energy/rage/focus, zero max, secret numeric vs native percent, nil, health > max, roles tank/healer/damage/none, assigned tank not holding aggro, role swap, roster reorder, recycled alias, rapid health/power events, multiple consumers share snapshot, stale coverage, unavailable API.

**Тесты и диагностика**

в файле не указано

**Архитектурные и обратные ссылки:** PE-02, PE-01, GR-06, GR-05, GR-04, GR-03, GR-01, TH-01, TH-03, TG-02, SP-07.

---

### GR-03 — Дебаффы, которые можно рассеять, у кого они

ID: [GR-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4014). Приоритет: P2.

**Вердикт**

**Вердикт**

**ЧАСТИЧНО РЕАЛИЗОВАНО — ДОРАБОТАТЬ (P2).** В Kord есть базовый aura API, обработка player buff/target debuff и события `UNIT_AURA`, но нет подтверждённого roster-wide per-member dispellable-debuff index, capability mapping и безопасной dispel recommendation.

**Архитектурные ссылки:** GR-01, GR-02, SP-01, SP-08, SP-14, TG-07, EN-08. Обратные ссылки внесены в GR-01, GR-02, SP-01, SP-08, SP-14, TG-07; EN-08 остаётся общим бюджетным контрактом без отдельного nameplate scan.

**Изменения Lua:** отсутствуют. Только документация.

**Выбранный путь**

**Выбранный путь Kord (решение по результатам сравнения)**

**Выбрать общий `AuraObservation(memberGUID)` по архитектуре RotationMaster, фильтры/разделение типов и секретности по ForeverAuras, spell capability mapping по Sonah, GUID+instanceID индексацию MaxDps и bounded secret-safe reads JustAC.** Источник членов — **только GR-01**, жизненные статусы — GR-02, общий aura reader — существующий Kord GameAPI/сигналы, расширенные до адресуемых friendly units; без второго roster scan и без отдельного классового dispel engine. `UNIT_AURA` инвалидирует только подтверждённый memberGUID; `GROUP_ROSTER_UPDATE`, смена алиаса/GUID и auraInstanceID — revision/TTL invalidation. Чтение `HARMFUL` и `HARMFUL|RAID` допускается лишь при подтверждённой Forever API semantics; ограниченный обход только по `Needs.dispels`/кандидатам, не каждый кадр и не все 40 участников без запроса. На secret/access-denied вернуть `UNKNOWN(aura_secret)`; отсутствие записи не доказывает отсутствие дебаффа, пока не доказаны coverage и полнота фильтра. Способности и dispel families проверяются по реально изученному максимальному рангу, классу, доступным эффектам, cooldown/ресурсам и конкретному member unit через **общую AbilityEligibility**. Отдельная policy допускает приоритет (смертельный/контроль/обычный) только на подтверждённых spellID и явных исключениях (опасный dispel, PvP и т.д.); неизвестный эффект не считать безопасным. Не смешивать defensive friendly dispel с offensive purge/enrage.

**Требуемые изменения (полный текст)**

**Требуемые изменения**

1. Переиспользовать GR-01 GUID-keyed roster, GR-02 life state, SP-01/02 spellbook и SP-08/14 common eligibility; не создавать дублирующий roster/dispel scanner.
2. Проверить на Forever фактические `C_UnitAuras.GetUnitAuras/GetAuraDataByIndex`, `UnitAura`, `HARMFUL`, `HARMFUL|RAID`, `RAID_PLAYER_DISPELLABLE`, `dispelName`, `auraInstanceID`, secret и nil; явно документировать различия.
3. Ввести общий `GroupMemberDebuffObservation(memberGUID)` со статусом полноты/достоверности, spellID/instanceID, dispelType, observedAt, reason; не интерпретировать отсутствие как false при неполном обходе.
4. Ввести `DispelCapabilityObservation(spellID)` по изученным способностям/рангам и подтверждённым dispel families; отделить offensive purge от friendly dispel.
5. Вычислять `DispelCandidateObservation(memberGUID,auraID,spellID)` с раздельными `debuffPresent`, `typeKnown`, `canRemove`, `targetAddressable`, `range`, `safety` и UNKNOWN; окончательное READY только AbilityEligibility.
6. EventBus per-member `UNIT_AURA` invalidation, GUID/roster revision, bounded refresh, per-evaluation memo, lazy `Needs.dispels`; запрет непрерывного 40-player aura polling.
7. Безопасная политика triage: dispel priority, dangerous-on-dispel exclusions, death/ghost, range, immunity, PvP, mutually exclusive dispels, limited GCD; не заявлять универсальную безопасность без spellID evidence.
8. DevTools-only диагностика: `group_debuff_unknown`, `group_debuff_secret`, `group_debuff_filter_unverified`, `group_debuff_coverage_partial`, `dispel_type_unknown`, `dispel_spell_unlearned`, `dispel_family_mismatch`, `dispel_target_guid_changed`, `dispel_range_unknown`, `dispel_unsafe_unknown`, `dispel_candidate_ready`.
9. Тесты: solo/party/raid 40, several debuffs on same member, same spellID on multiple GUIDs, same name/different GUID, auraInstanceID recycled, dispel magic/curse/poison/disease, missing family/unknown rank, secret filter, nil aura, hidden dispelName, restricted API, raid filter vs player-capable, dangerous dispel, dispel immunity, dead/disconnected member, stale roster, GUID swap, cooldown/range/GCD, burst `UNIT_AURA`, no unbounded scans, no protected actions.

**Тесты и диагностика**

в файле не указано

**Архитектурные и обратные ссылки:** GR-05, GR-04, GR-01, GR-02, SP-01, SP-08, SP-14, TG-07, EN-08.

---

### GR-04 — Отсутствующие групповые баффы (кого баффать)

ID: [GR-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4070). Приоритет: P2.

**Вердикт**

**Вердикт**

**ЧАСТИЧНО РЕАЛИЗОВАНО — ДОРАБОТАТЬ (P2).** Kord читает отдельные player/target aura facts, но не имеет подтверждённого общего memberGUID-based group-buff coverage, family equivalence и адресной рекомендации «кого баффать».

**Архитектурные ссылки:** GR-01, GR-02, GR-03, SP-01, SP-02, SP-08, SP-14. Обратные ссылки внесены в перечисленные предыдущие задачи в том же коммите.

**Изменения Lua:** отсутствуют. Только документация.

**Выбранный путь**

**Выбранный путь Kord (решение по результатам сравнения)**

**Выбрать GR-01 GUID-keyed roster + общий per-member `AuraObservation` GR-03/RotationMaster + проверку `HELPFUL` семейств и post-cast suppression JustAC + классовые декларации семейств Sonah + event/secret boundary ForeverAuras.** Один логический `GroupBuffCoverageObservation(memberGUID,buffFamilyID)` возвращает подтверждённые `PRESENT/MISSING_CONFIRMED/REFRESH_DUE/NOT_APPLICABLE/UNKNOWN`, matching auraID/rank, source, observedAt, completeness. Отдельный `GroupBuffRecommendation(buffFamilyID,castSpellID)` выбирает кандидатов с подтверждённым отсутствием и валидным unit token; для raid-wide buff агрегирует подтверждённых получателей, учитывает range/target/group semantics и предотвращает повторные предложения на каждого члена группы. Не создавать второй roster scan или buff reader. Для direct auraID point query отрицательный ответ признавать доказательством отсутствия **только если** клиентская семантика, фильтр, GUID и полнота всех эквивалентных auraIDs подтверждены; `nil` при secret/ошибке — UNKNOWN. При неизвестном member state или частичном raid coverage не объявлять `all buffed` или `all missing`. Ленивая обработка по `Needs.groupBuffFamilies` с per-evaluation memo, bounded refresh, event-driven `UNIT_AURA`/roster revision, per-GUID freshness и post-cast grace только для подтверждённого собственного успешного применения. Не копировать hard-coded retail/Midnight API и spellIDs без проверки Forever; `C_CooldownViewer.GetGroupBuffItems` использовать лишь при реальном подтверждении и только как вспомогательный каталог, не как источник applied aura equivalence. Различать buff duration/refresh threshold, group vs single-target ranks, reagent/party subgroup restrictions, death/ghost/disconnect/LOS, class-specific exclusions и duplicate providers. Окончательный `READY` только через `AbilityEligibility`; пользователь получает рекомендацию и при необходимости ручное указание цели, без protected actions.

**Требуемые изменения (полный текст)**

**Требуемые изменения**

1. Переиспользовать GR-01 roster, GR-02 life/connectivity, GR-03 общий aura reader, SP-01/02 spell identity/ranks и SP-08/14 friendly eligibility; не создавать параллельный обход группы.
2. Проверить на Forever `HELPFUL`, by-ID/filtered aura reads, secret/nil, authoritative negative, auraInstanceID, applied aura vs cast ID, buff rank/family и group/raid targeting semantics.
3. Ввести канонический `GroupBuffCoverageObservation(memberGUID,buffFamilyID)` с явной полнотой и доказательством отсутствия; `UNKNOWN` не приравнивать ни к PRESENT, ни к MISSING.
4. Ввести class-data реестр buff family -> cast SpellID/rank -> applied auraIDs/equivalents, исключения, refresh threshold, individual/group mode, target policy, reagents и client validation.
5. Ввести `GroupBuffRecommendation` с dedup по buffFamily/recipient set, выбором одного допустимого group cast либо конкретного individual target; не предлагать рейдовый recast по одному недоступному/непроверенному member.
6. Общий spell-specific range для memberGUID, `UnitCanAssist`, alive/connected/visible, групповая принадлежность, ограничения подгрупп и class applicability; финальная пригодность только через AbilityEligibility.
7. EventBus per-member `UNIT_AURA` + `GROUP_ROSTER_UPDATE`, GUID/revision/TTL, lazy `Needs.groupBuffFamilies`, bounded 40-member coverage, post-cast grace/latch против повторных ложных рекомендаций, без OnUpdate scanner.
8. DevTools-only диагностика: `group_buff_family_unknown`, `group_buff_aura_secret`, `group_buff_missing_confirmed`, `group_buff_coverage_partial`, `group_buff_member_unaddressable`, `group_buff_range_unknown`, `group_buff_duplicate_suppressed`, `group_buff_postcast_grace`, `group_buff_spell_unlearned`, `group_buff_equivalence_unverified`.
9. Тесты: solo/party/raid 40, один участник без баффа, все баффнуты, позднее присоединение, resurrect, group recast vs individual, family equivalent aura, rank variation, multiple casters, group subgroup scope, expired/soon-expiring, secret/nil vs proven absent, target swap, GUID alias recycled, dead/disconnected/out-of-range, wrong faction/non-assistable, postcast aura delay, no duplicate group cue, stale/partial roster, missing reagents/cooldown, no protected actions.

**Тесты и диагностика**

в файле не указано

**Архитектурные и обратные ссылки:** IT-07, GR-05, GR-01, GR-03, GR-02, SP-01, SP-08, SP-02, SP-14.

---

### GR-05 — Кому нужен приоритетный хил, мёртвые для воскрешения

ID: [GR-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4125). Приоритет: P2.

**Вердикт**

**Вердикт**

**ЧАСТИЧНО РЕАЛИЗОВАНО — ДОРАБОТАТЬ (P2).** Kord имеет базовые health/dead/eligibility facts, но не общий per-member heal priority, отдельную resurrection policy и гарантированное покрытие группы/рейда.

**Архитектурные ссылки:** GR-01, GR-02, GR-03, GR-04, SP-08, SP-14. Обратные ссылки внесены в эти предыдущие требования в том же коммите.

**Изменения Lua:** отсутствуют. Только документация.

**Выбранный путь**

**Выбранный путь Kord (решение по сравнению)**

**Основа — GR-01 roster + GR-02 member vitals/role + RotationMaster role/unit/dead observations + Sonah приоритет ручного friendly target и честное разделение emergency/maintenance + JustAC раздельные heal/resurrection spell categories.** Общий логический `GroupCareCandidateObservation(memberGUID)` предоставляет независимые `life`, `healthDeficit`, `healthPercent`, `role`, `incomingDamageEvidence` (только если доказано), `manualTargetPreference`, `range`, `observedAt`, `reason`. Производные `HealPriorityPolicy` и `ResurrectionCandidatePolicy` используют один snapshot, не создают отдельные сканеры. Приоритет лечения — **детерминированная конфигурируемая политика по достоверным фактам**, не фиктивный точный медицинский/игровой прогноз: emergency threshold по подтверждённому HP, затем подтверждённый дефицит, назначенная роль/ручной выбор и доступность; пороги и веса — настройки с шестиязычными подсказками после измерений. При неизвестном HP — `UNKNOWN(health_unreadable)` либо явно обозначенная maintenance рекомендация по подтверждённым условиям, **без заявления о срочном лечении**. Не выводить точный процент из эвристики `UNIT_COMBAT`; если когда-либо вводится estimator, маркировать `ESTIMATED` и никогда не использовать как доказанный порог.

Для воскрешения отдельный список **подтверждённо мёртвых** и допустимые варианты: вне боя `RESURRECT_OOC`, в бою `BATTLE_RES`, массовое воскрешение `MASS_RES`, питомец `PET_REVIVE` как отдельная категория. Не считать отсутствие подтверждённой боевой механики spell признаком доступного battle res; проверять клиент, learned rank, cooldown, ресурсы, реагенты, диапазон, адресуемость, возможные encounter/instance ограничения и доступность цели. Учитывать duplicate pending resurrection только при подтверждённых cast/aura событиях; без доказательств возвращать UNKNOWN. При нескольких мёртвых роль может повышать приоритет, но не заменяет проверку возможности воскрешения. Для текущего неадресуемого ally давать лишь рекомендацию ручного выбора цели. Финальное `READY` — только `AbilityEligibility`.

**Требуемые изменения (полный текст)**

**Требуемые изменения**

1. Переиспользовать GR-01 GUID-keyed roster и GR-02 health/life/role; один общий candidate index для heal/res, без дополнительного полного сканера группы.
2. Валидировать на Forever `UnitHealth/Max/Percent`, `UnitIsDeadOrGhost`, role, secret/curve, party/raid alias и клиентские healing/resurrection spell IDs/ranks.
3. Реализовать `GroupCareCandidateObservation` с независимыми statuses и источниками, не смешивать unknown health, dead, disconnected, out of range и non-healable.
4. Ввести `HealPriorityPolicy` с ручным target preference, role/health evidence, emergency vs maintenance, стабильным tie-break по GUID, hysteresis для предотвращения прыгающего выбора.
5. Ввести `ResurrectionCandidatePolicy` с раздельными OOC/battle/mass/pet modes, проверенной пригодностью, исключением живых и запретом выводить battle-res из общего названия «воскрешение».
6. Применять per-member/per-spell range GR-01/SP-08, class/role/learned-rank, cooldown/GCD/resources/target policy; окончательный READY только через AbilityEligibility.
7. Lazy `Needs.groupCare`, per-pass memo, bounded 40-member refresh, roster/health/death/role/cast revisions, события после подтверждения клиентом; без постоянного polling в OnUpdate.
8. DevTools-only диагностика: `heal_health_unknown`, `heal_priority_candidate`, `heal_priority_hysteresis`, `heal_manual_target_override`, `heal_maintenance_only`, `res_dead_unknown`, `res_candidate_confirmed`, `res_battle_mode_unverified`, `res_spell_unlearned`, `res_target_unaddressable`, `res_pending_unknown`, `group_care_coverage_partial`.
9. Тесты: solo/party/raid 40, several injured, role priority vs critical HP, manual mouseover/target, health secret in combat, unknown HP, disconnected, dead/ghost vs alive, role unknown, equal HP and tie-break, target changes, no ping-pong, one/many dead, battle vs OOC res, mass res, pet revive not member, spell unavailable/cooldown/reagent, range unknown/LOS, pending res, GUID recycled, stale roster, event burst, no protected action.

**Тесты и диагностика**

в файле не указано

**Архитектурные и обратные ссылки:** IT-08, IT-05, IT-04, IT-03, IT-02, IT-01, PE-05, PE-02, GR-06, GR-01, GR-02, SP-08, GR-03, GR-04, SP-14.

---

### GR-06 — Число целей в группе в радиусе для AoE-лечения

ID: [GR-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4196). Приоритет: P2.

**Вердикт**

**Вердикт**

**НЕ РЕАЛИЗОВАНО КАК УНИВЕРСАЛЬНАЯ ВОЗМОЖНОСТЬ — ДОРАБОТАТЬ (P2).** Kord имеет health/range APIs для отдельных units, но нет реализованного roster-wide injured count, spell-specific AoE impact geometry и проверяемого count целей в радиусе. Простое число раненых в группе **не удовлетворяет** формулировке GR-06.

**Архитектурные ссылки:** GR-01, GR-02, GR-05, SP-08, SP-14, TG-09. Обратные ссылки внесены в эти предыдущие задачи в том же коммите.

**Изменения Lua:** отсутствуют. Только документация.

**Выбранный путь**

**Выбранный путь Kord (решение по сравнению)**

**Основа — единые GR-01/GR-02/GR-05 member observations + Sonah пороги и subgroup selection + RotationMaster secret-safe health observation + JustAC осторожный group low-count/hysteresis.** Добавить **производный** `GroupAoEHealCoverageObservation(spellID,anchorGUID/groundPoint,threshold)` поверх общего roster/care index, а не новый сканер. Spell-specific metadata после проверки Forever: `CASTER_CENTERED`, `TARGET_CENTERED`, `GROUND_TARGETED`, `SUBGROUP`, `CHAIN`, `SMART_TARGET`, `RAID_WIDE`; radius, maxTargets, bounce rules, caster/anchor policy и правила включения pets. Для `SUBGROUP` допускается точный счёт **подтверждённо раненых в допустимой подгруппе** только если механика не требует отдельной пространственной проверки; иначе UNKNOWN. Для `CASTER_CENTERED`/ `TARGET_CENTERED`/ `GROUND_TARGETED` нужен подтверждённый **member-to-anchor** distance/geometry provider, не `IsSpellInRange` до кастера. Для `CHAIN` нужен подтверждённый **pairwise** reach и правила прыжков; нельзя приравнивать к числу всех раненых в рейде. `SMART_TARGET` с непроверенной логикой выбора целей выдаёт только bounds/UNKNOWN, не точное попадание. Неподдерживаемые client APIs, secret coordinates, неточные range bands или неопределённый anchor — `UNKNOWN(aoe_geometry_unavailable)`. Никогда не выдавать `READY` способности на основании количества; итог — общий `AbilityEligibility`.

Для решения о рекомендации использовать конфигурируемые `minInjuredTargets`, `injuryThreshold`, при необходимости `minConfirmedCoverage` и hysteresis; при count UNKNOWN запрещено заявлять «три союзника точно попадут». Возможен отдельный **явно обозначенный эвристический совет** по подтверждённому числу раненых в группе, но не выдавать его за условие точного AoE радиуса и не обходить UNKNOWN. Lazy `Needs.groupAoEHeal`, per-evaluation memo по `(rosterRevision,spellID,anchor,threshold)`, bounded checks, GUID dedup, event invalidation, без per-frame 40-member geometry scan. Никаких protected target/cast actions.

**Требуемые изменения (полный текст)**

**Требуемые изменения**

1. Переиспользовать GR-01 roster/GUID/range, GR-02 health/life, GR-05 care candidates и SP-08/14 common spell eligibility; запретить отдельный AoE-heal roster scanner.
2. Валидировать на Forever client APIs и механику каждого AoE-heal spellID/rank: anchor, radius, target cap, subgroup, chain bounce, smart selection, pet inclusion, line-of-sight и restrictions; не копировать retail constants.
3. Ввести spell-specific `AoEHealGeometryPolicy` и `GroupAoEHealCoverageObservation` с раздельными count injured vs count eligible vs count geometrically confirmed, coverage/UNKNOWN.
4. Разработать общую безопасную пространственную observation **только если** Forever позволяет получить проверяемые member-to-anchor/pairwise данные; при отсутствии источника оставлять geometry UNKNOWN, не выдумывать координаты.
5. Реализовать subgroup/raid filtering, dedup player/party/raid aliases, death/ghost/disconnect exclusion, min/max targets и partial roster accounting.
6. Конфигурируемые пороги `minInjuredTargets`/`injuryThreshold`, stable tie-break/hysteresis и запрет «точного count» на секретных данных; шесть языков UI/tooltip при появлении настроек.
7. EventBus invalidation по roster/health/target/position только подтверждённым событиям, lazy Needs, per-pass memo, bounded refresh и reason-rich diagnostics.
8. DevTools-only диагностика: `aoe_heal_geometry_unknown`, `aoe_heal_health_secret`, `aoe_heal_roster_partial`, `aoe_heal_anchor_unknown`, `aoe_heal_spell_policy_unverified`, `aoe_heal_subgroup_count`, `aoe_heal_chain_unverified`, `aoe_heal_confirmed_count`, `aoe_heal_min_targets_not_met`, `aoe_heal_heuristic_only`.
9. Тесты: solo/party/raid40, 0/1/3/10 injured, mixed known/secret health, 2 injured near caster vs 3 far, near anchor vs far caster, subgroup Prayer of Healing, Chain Heal bounces, ground targeted, smart heal cap, raid-wide, dead/disconnected, pet inclusion, maxTargets, overlapping aliases, recycled GUID, stale/partial roster, unknown geometry, invalid spell rank, target/range/GCD/cooldown, repeated events, no unbounded scanning/protected actions.

**Тесты и диагностика**

в файле не указано

**Архитектурные и обратные ссылки:** PE-06, GR-01, GR-02, GR-05, SP-08, SP-14, TG-09.

---

