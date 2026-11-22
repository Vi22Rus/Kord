# Карточки TH

Источник: REQUIREMENTS.md, blob 9efdec1900398c978ea121818fb5950cb1620337.

### TH-01 — Состояние угрозы: есть ли агро у игрока, питомца, танка

ID: [TH-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3701). Приоритет: P1.

**Вердикт**

**Вердикт**

**ЧАСТИЧНО РЕАЛИЗОВАНО — ДОРАБОТАТЬ (P1).** Kord уже читает уровень угрозы игрока на текущем target и имеет GUID guards, но нет доказанного универсального actor-specific per-enemy threat/aggro ownership provider для игрока, питомца и танка.

**Архитектурные ссылки:** TG-05, EN-02, EN-03, EN-08, PL-07, SP-14. Обратные архитектурные ссылки в TG-05, EN-02, EN-03 и EN-08 добавлены в том же коммите; PL-07/SP-14 используют существующие общие контракты без замены их механизмов.

**Изменения Lua:** отсутствуют. Только документация.

**Выбранный путь**

**Выбранный путь Kord (решение по результатам сравнения)**

**Базовый контракт RotationMaster (единый lazy `ThreatObservation` с per-evaluation cache и `UNKNOWN(reason)`) + структурированные поля `UnitDetailedThreatSituation` по модели ForeverAuras + secret-safe ограничения Sonah + общий GUID-index EN-03 и EN-08 budget.** Это лучше прямых player-only проверок Sonah/MaxDps и повторных per-consumer обходов: одна общеклассовая точка получения фактов, явное разделение `onThreatTable`, `threatStatus`, `isTanking`, `percent` и `ownerEvidence`, без фиктивного владельца агро. `UnitGroupRolesAssigned`/другой подтверждённый roster-role источник может обозначить кандидата-танка, но **роль не доказывает удержание агро**. Сначала доказать API shape и secret behavior в Forever v14, затем разрешать соответствующие поля. `UnitIsUnit("targettarget",actor)` использовать только как отдельное косвенное свидетельство с проверкой GUID и моментом наблюдения. Движок не делает protected actions; окончательный `READY` способности остаётся за `AbilityEligibility`.

**Требуемые изменения (полный текст)**

**Требуемые изменения**

1. Расширить общий слой наблюдений логическим `ThreatObservation(enemyGUID,actorGUID)`, без отдельного классового файла/сканера; actor aliases: player, pet, подтверждённые party/raid units, назначенные танки.
2. Получать `UnitDetailedThreatSituation(actorUnit,enemyUnit)` и/или `UnitThreatSituation(actorUnit,enemyUnit)` только для проверенных адресуемых пар; возвращать отдельные `isTanking/status/percent/rawPercent/value` с provenance, доступностью и `UNKNOWN` по каждому полю.
3. Различать `hasAggro`, `onThreatTable`, `highThreat`, `isAssignedTank`, `enemyTargetsActor`; не смешивать nil, false, zero и secret.
4. Поддержать player/pet/party/raid/tank и solo; проверить UnitGUID до/после чтения, не переносить угрозу между recycled enemy/actor tokens.
5. Переиспользовать EN-01/02/03/08 индекс врагов и bounded refresh; отдельное чтение threat по `Needs` с per-pass memo, без полного nameplate scan при каждом запросе.
6. Инвалидировать на target/roster/pet/nameplate changes, combat/threat events только при подтверждённой поддержке клиентом, bounded heartbeat; учитывать TTL и revision.
7. Потребителям давать доказательные состояния для защитных и танковых приоритетов; неизвестное агро — консервативная политика профиля, не ложное `READY` и не доказанное `false`.
8. DevTools-only диагностика: `threat_actor_unknown`, `threat_enemy_unknown`, `threat_secret`, `threat_api_unavailable`, `threat_status_invalid`, `threat_is_tanking_unknown`, `tank_role_unconfirmed`, `threat_guid_changed`, `threat_stale`, `threat_target_of_target_only`.
9. Тесты: solo player/pet, party/raid with assigned tank, multiple tanks, role unknown, tank without aggro, pet holds aggro, player highest threat but not tanking, threat table entry without aggro, target-of-target mismatch, nil/0/1/2/3, secret percentages, enemy swaps, recycled aliases, 0/1/many enemies, partial coverage, combat reset/evade, threat transfer, event burst and per-pass caching.

**Тесты и диагностика**

в файле не указано

**Архитектурные и обратные ссылки:** IT-08, PE-04, PE-01, PE-03, PE-02, GR-02, GR-01, TH-03, TH-02, EN-03, EN-08, EN-01, TG-05, EN-02, PL-07, SP-14.

---

### TH-02 — Риск срыва агро (для DPS): нужно ли уменьшить угрозу или остановиться

ID: [TH-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3770). Приоритет: P2.

**Вердикт**

**Вердикт**

**ЧАСТИЧНО РЕАЛИЗОВАНО — ДОРАБОТАТЬ (P2).** Kord читает только threat status игрока на текущем target; достоверной количественной оценки риска срыва агро, политики уменьшения угрозы/паузы DPS и её multi-enemy охвата пока нет.

**Архитектурные ссылки:** TH-01, TG-05, EN-03, EN-08, SP-14. Обратные архитектурные ссылки добавлены в эти ранее записанные требования в том же коммите.

**Изменения Lua:** отсутствуют. Только документация.

**Выбранный путь**

**Выбранный путь Kord (решение по результатам сравнения)**

**Расширение единого TH-01 `ThreatObservation(enemyGUID,actorGUID)` полями detailed threat по модели ForeverAuras + lazy UNKNOWN-safe condition RotationMaster + отдельная общеклассовая `ThreatRiskPolicy` и class-data выбора threat-drop по Sonah.** Не создавать второй `ThreatScanner` или собственную альтернативную threat table. `ThreatRiskObservation` — производная функция от TH-01, а не новый API-reader. Если клиент достоверно возвращает `threatPercent` (процент **порога перехвата**, не raw доля танка), сравнивать с **настраиваемыми** порогами `warnPercent` и `pausePercent` (валидировать `0 < warnPercent < pausePercent <= 100`); значения по умолчанию выбрать после игрового замера, не выдумывать. При status 2/3 («уже танкует») это отдельное `AGGRO_ALREADY_LOST`/urgent mitigation, не прогноз будущего перехвата. При доступном только status 0/1 не делать численного прогноза: `UNKNOWN(risk_percent_unavailable)` или документированная грубая policy без ложного ETA. Скорость изменения угрозы/ETA допускается только по bounded сравнимой GUID-keyed истории, а при нестабильности — UNKNOWN. На нескольких врагах оценивать риски отдельно и агрегировать только по подтверждённым данным; отсутствие видимости не означает безопасный AoE.

Выбор рекомендации: при подтверждённом повышенном риске `REDUCE_THREAT` — предложить доступную классовую способность снижения угрозы через общую `AbilityEligibility`; при критическом риске или отсутствии подходящего действия — `PAUSE_DPS` как **информационная рекомендация**. `CONTINUE_DPS` только при достаточной свежести и доказанно низком риске в выбранном охвате; UNKNOWN не равен SAFE. Режимы solo/group, роль игрока, PvP, таунт/смена танка, иммунитет/резист threat drop и конкретная механика spell должны быть учтены данными профиля. Не путать «уменьшить угрозу» с защитной способностью, которая не снижает threat на данном клиенте.

**Требуемые изменения (полный текст)**

**Требуемые изменения**

1. Использовать единый TH-01 per-GUID/per-actor `ThreatObservation` и EN-03 identity, без дополнительного threat reader и nameplate scanner.
2. Валидировать `UnitDetailedThreatSituation` на Forever: порядок возвращаемых полей, isTanking, threatPercent vs rawThreatPercent, secret, nil и 0; при отсутствии данных не моделировать точный процент.
3. Ввести производный `ThreatRiskObservation(enemyGUID,playerGUID)`: risk status, percent-to-pull если plain, trend/ETA только при достаточной истории, confidence, reason, observedAt.
4. Разделить `SAFE/AT_RISK/CRITICAL/ALREADY_TANKING/UNKNOWN` и policy `CONTINUE_DPS/REDUCE_THREAT/PAUSE_DPS/UNKNOWN`; угрозу игрока, питомца и танка не смешивать.
5. Настраиваемые пороги warning/pause с безопасной валидацией, сохранением и шестиязычными UI подсказками; числовые defaults согласовать по клиентским замерам.
6. Использовать общий `AbilityEligibility` для Feign Death/Fade/Feint/Cower/других подтверждённых способностей, с class-data/SpellID и проверкой фактической механики; отсутствие способности не блокирует информационную PAUSE рекомендацию.
7. Ленивая оценка по `Needs`, per-pass cache, bounded threat history, EN-08 refresh budget; invalidation по target/GUID, combat, roster, pet, threat updates и bounded heartbeat при подтверждённых событиях.
8. Диагностика DevTools: `threat_risk_percent_unknown`, `threat_risk_secret`, `threat_risk_stale`, `threat_risk_threshold_warning`, `threat_risk_threshold_critical`, `threat_risk_already_tanking`, `threat_risk_multi_enemy_partial`, `threat_drop_unavailable`, `threat_pause_recommended`.
9. Тесты: 0/1/many enemies, player vs pet vs tank, solo/group/PvP, percent below/at/above both thresholds, rawPercent not percent-to-pull, status 0/1/2/3, nil/secret, missing tank, taunt/aggro transfer, melee/ranged unknown, threat reset/resist, stale GUID, partial nameplates, cooldown/no threat-drop ability, equal evaluations, rapid threat increase, pause recommendation never issues protected action.

**Тесты и диагностика**

в файле не указано

**Архитектурные и обратные ссылки:** TH-03, TH-01, EN-03, EN-08, TG-05, SP-14.

---

### TH-03 — Таунт и способности танка: готовы, нужны ли, цель вне агро

ID: [TH-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3826). Приоритет: P2.

**Вердикт**

**Вердикт**

**ЧАСТИЧНО РЕАЛИЗОВАНО — ДОРАБОТАТЬ (P2).** Общие cooldown/eligibility и player-target threat facts существуют, но нет доказанной actor-specific threat ownership, универсального решения о необходимости таунта, классификации taunt effects и разграничения «враг вне агро»/«агро потеряно».

**Архитектурные ссылки:** TH-01, TH-02, TG-05, EN-02, EN-03, EN-07, EN-08, SP-14. Обратные ссылки добавлены в TH-01, TH-02, TG-05, EN-03, EN-08, SP-14; EN-02/EN-07 остаются потребителями существующих контрактов без их замены.

**Изменения Lua:** отсутствуют. Только документация.

**Выбранный путь**

**Выбранный путь Kord (решение по результатам сравнения)**

**Основа — единый TH-01 `ThreatObservation` и общий `AbilityEligibility`, дополненные Sonah role/form/need gating и разделением taunt effect vs threat status по RotationMaster; справочные SpellID и свойства из JustAC/ForeverAuras использовать только после валидации на Forever.** Один производный `TankControlRecommendation(enemyGUID,tankGUID,abilityID)` возвращает отдельно `readiness` (результат общего Eligibility), `need` (`NEEDED/NOT_NEEDED/UNKNOWN`), `reason`, `targetGUID`, `effectKind` (`THREAT_EQUALIZE`, `FORCED_ATTACK`, `THREAT_GENERATION`, `DEFENSIVE` или UNKNOWN), `confidence`, `observedAt`. Названия — логические контракты, не требование создавать новые Lua-файлы. Таунт необходим только при подтверждённом контексте танка и фактическом враге, который должен быть возвращён под контроль танка: например, подтверждённый enemy атакует другого участника и это не запланированная смена танков. Не рекомендовать таунт на цели, которую уже контролирует назначенный танк, только из-за чужого высокого threat или отсутствия полной информации. Проверить immunity, DR, boss mechanics, taunt swap, PvP, pets, AoE radius, target addressability и range в рамках доступных доказательств; UNKNOWN не равен безопасному использованию.

Для **«цель вне агро»** различать: (1) враг подтверждённо взаимодействует с группой, но не удерживается танком; (2) враг вне боя с группой; (3) coverage/threat неизвестны. Случай (2) не объявлять «потерянным агро» и не инициировать таунт автоматически. Случай (3) — `UNKNOWN`. Все данные ленивые, GUID-keyed, EN-08 budgeted. Если выбранная цель не текущий адресуемый target, показывать только подсказку ручного переключения по EN-07; окончательное `READY` остаётся у AbilityEligibility.

**Требуемые изменения (полный текст)**

**Требуемые изменения**

1. Расширить TH-01 threat observation производной `TauntNeedObservation`, не создавать второй scanner/таблицу угрозы.
2. Ввести общий `TankControlRecommendation` с независимыми `readiness` и `need`; не смешивать cooldown-ready с тактической необходимостью.
3. Поддержать actor tank/pet/group roles и enemy GUID с доказанной идентичностью, текущим владельцем агро и историей transfer/taunt, отличать роль от фактического агро.
4. Реестр танковых способностей по SpellID/effectKind, требованиям формы/стойки, target policy, range, cooldown, зарядам, GCD и подтверждённой клиентской механике; общий Eligibility — единственный final READY.
5. Разделить taunt, forced attack, threat generation и defensive; не объявлять временное принуждение устойчивым переносом threat.
6. Учитывать групповое взаимодействие EN-02, ручную смену цели EN-07, иммунитет, taunt-swap и неизвестные механики босса; не инициировать pull чужого врага.
7. Общий GUID index EN-03, bounded enemy refresh EN-08, lazy Needs и per-evaluation memo; события threat/target/roster/pet/taunt и TTL инвалидируют по доказанным данным.
8. DevTools-only диагностика: `taunt_need_unknown`, `taunt_ready_but_not_needed`, `taunt_needed_but_unavailable`, `taunt_target_not_engaged`, `taunt_target_unaddressable`, `taunt_tank_role_unknown`, `taunt_effect_unverified`, `taunt_immunity_unknown`, `taunt_swap_policy_unknown`, `taunt_guid_changed`.
9. Тесты: tank holds aggro, tank loses aggro to DPS/healer/pet, enemy outside group combat, unknown threat, tank role missing, two tanks with planned swap, taunt immune/resist, taunt on cooldown, ready but unnecessary, form/stance wrong, forced attack without threat transfer, AoE taunt, ranged/unaddressable enemy, boss/PvP, 0/1/many enemies, recycled GUID, stale/secret data, manual switch and no protected actions.

**Тесты и диагностика**

в файле не указано

**Архитектурные и обратные ссылки:** PE-04, TH-01, PE-03, PE-01, GR-02, EN-08, EN-07, EN-02, EN-03, TH-02, TG-05, SP-14.

---

