# Карточки TG

Источник: REQUIREMENTS.md, blob 9efdec1900398c978ea121818fb5950cb1620337.

### TG-01 — Цель существует, жива, враждебна, доступна для атаки, видима

ID: [TG-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L2506). Приоритет: P0.

**Вердикт**

**Вердикт**

**ЧАСТИЧНО РЕАЛИЗОВАНО — ДОРАБОТАТЬ (P0).** Exists/dead/attackable уже есть; самостоятельных hostile/visible/LoS нет.

**Выбранный путь**

в файле не указано

**Требуемые изменения (полный текст)**

**Требуемые изменения**

1. Сохранить существующие `exists`, `dead`, `attackable`, `assistable` и GUID в `GameState.unitSnapshot`; нормализовать `alive` без потери UNKNOWN.
2. Проверить на Forever `UnitIsEnemy` и `UnitIsVisible`, добавить в GameAPI только при поддержке и секретной безопасности; `hostile` не подменять `attackable`.
3. `visible` не приравнивать к LoS. Если API не позволяет достоверно проверить LoS, оставить `lineOfSight=UNKNOWN`; не использовать `IsSpellInRange` как LoS.
4. При отсутствии цели `exists=READY(false)` и spell-specific BLOCKED, но остальные поля не читать как значения от предыдущего target.
5. Сохранять identity guard `targetGUID` для снимка и перед/после асинхронно-неустойчивых API чтений; смена цели → UNKNOWN/новый snapshot.
6. `AbilityEligibility` использует подтверждённые exists/alive/attackable и дополнительные visibility/LoS только по установленным правилам; UNKNOWN visibility не трактовать как гарантированную невозможность атаки.
7. Инвалидация `PLAYER_TARGET_CHANGED`, `UNIT_FLAGS`, `UNIT_FACTION`, `UNIT_HEALTH`, `UNIT_CONNECTION` — только если события реально доступны на Forever; heartbeat как fallback, не доказательство.
8. Диагностика `target_visibility_unknown`, `target_hostility_unknown`, `target_identity_changed`, `target_los_unverified`; тесты нет цели, труп, ghost, нейтральная/враждебная/дружественная, attackable=false при hostile, скрытая цель, target swap, секретный API, дальность есть/нет, LoS blocked, pet target, инстанс/мир.

**Архитектурные ссылки:** SP-08 — range, SP-14 — spell requirements, AU-08 — target defenses, PL-10 — facing. В прежних требованиях внесены обратные сноски на TG-01.

**Изменения кода:** не выполнялись; внесён аудит TG-01 и перекрёстные ссылки.

**Тесты и диагностика**

в файле не указано

**Архитектурные и обратные ссылки:** GR-01, EN-03, EN-01, TG-11, TG-10, TG-09, TG-08, TG-06, TG-05, TG-04, TG-03, TG-02, AU-08, SP-08, SP-14, PL-10.

---

### TG-02 — Здоровье цели: процент, текущее (если не защищено)

ID: [TG-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L2591). Приоритет: P0.

**Вердикт**

**Вердикт**

**ЧАСТИЧНО РЕАЛИЗОВАНО — ДОРАБОТАТЬ (P0).** Точное здоровье и обычный процент уже читаются в разрешённых случаях; защищённые процентные пороги предусмотрены, но не интегрированы в единый целевой контракт.

**Выбранный путь**

в файле не указано

**Требуемые изменения (полный текст)**

**Требуемые изменения**

1. Объединить PL-03 и TG-02 на общем `UnitHealthObservation(unit)`, без отдельного player/target reader; сохранить независимые статусы current, max, exactPercent и threshold.
2. Для числовых `UnitHealth/UnitHealthMax` проверять finite, 0<=current<=max, max>0, secret-safe; при неконсистентных значениях UNKNOWN с причиной, а не clamp до фиктивного здоровья.
3. Для процентных порогов использовать только подтверждённый на Forever `UnitHealthPercent(unit,true,curve)` с безопасной curve; сохранить идентичность threshold/curve и не выдавать дискретный результат за точный процент.
4. При отсутствии curve или secret чисел возвращать UNKNOWN; не интерполировать по combat log, healthbar пикселям, соседним процентным ступеням или прежнему snapshot.
5. Согласовывать `unitGUID` до/после чтения, проверять `UnitExists`, при target swap/потере GUID немедленно инвалидировать; отдельные status для отсутствующей и мёртвой цели.
6. Для `AbilityEligibility` execute/health-based abilities использовать подтверждённый threshold result, а не `current/max` из неподтверждённого источника. Классовые пороги — декларативные данные, единый provider.
7. Инвалидация по `UNIT_HEALTH`, `UNIT_MAXHEALTH`, `PLAYER_TARGET_CHANGED`, GUID и ревизиям EventBus; кэш не должен переживать смену цели.
8. Диагностика `target_health_secret`, `target_health_percent_unknown`, `target_health_curve_unavailable`, `target_health_guid_changed`; тесты 100/99/50/20/0%, max=0, secret current/max, разрешённый порог при secret, разные curves, target swap, player/pet/focus, без цели, смерть, regen, UNKNOWN в бою.

**Архитектурные ссылки:** PL-03 — общий health provider; TG-01 — идентичность/жизнь цели; SP-14 — execute/health requirements. Обратные сноски добавлены.

**Изменения кода:** не выполнялись; внесён аудит TG-02 и обратные ссылки.

**Тесты и диагностика**

в файле не указано

**Архитектурные и обратные ссылки:** GR-02, EN-06, TG-06, PL-03, TG-01, SP-14.

---

### TG-03 — Уровень относительно игрока, классификация (обычная, элита, босс, редкая)

ID: [TG-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L2649). Приоритет: P1.

**Вердикт**

**Вердикт**

**ЧАСТИЧНО РЕАЛИЗОВАНО — ДОРАБОТАТЬ (P1).** Классификация и уровень игрока есть, уровень цели/разница и нормализованные boss-флаги отсутствуют.

**Выбранный путь**

в файле не указано

**Требуемые изменения (полный текст)**

**Требуемые изменения**

1. Добавить защищённое `UnitLevel("target")` в существующий `unitSnapshot`, без нового API bypass; при secret/invalid вернуть UNKNOWN.
2. `relativeLevel` считать только из двух READY положительных уровней; `-1` и другие sentinel значения выделять отдельно как `levelIsSkull`, не выполнять арифметику.
3. Нормализовать `normal/elite/rare/rareelite/worldboss/trivial/minus` с сохранением raw и независимых `isElite/isRare/isBoss`. `rareelite` → одновременно rare и elite, `worldboss` → boss; остальные категории не автоматически «не босс», если у клиента есть иные boss flags.
4. Проверить `UnitIsBossMob` на Forever и secret-safe чтение; при недоступности не выдавать неподтверждённый false для всех boss encounters.
5. Привязать playerLevel/targetLevel/classification к одному стабильному targetGUID; после смены цели не переиспользовать старую разницу/классификацию.
6. `RotationConditions` и `AbilityEligibility` должны брать требования по уровню/элитности из общего TargetObservation; class-specific правила только декларативные.
7. Инвалидация `PLAYER_TARGET_CHANGED`, relevant unit changes и heartbeat fallback с проверкой поддержки; не считать cached target classification актуальной для другого GUID.
8. Диагностика `target_level_unknown`, `target_level_skull`, `target_classification_unknown`, `boss_status_unverified`; тесты lower/equal/higher, -1 skull, normal/elite/rare/rareelite/worldboss/trivial/minus, secret, target swap, boss without worldboss, no target.

**Архитектурные ссылки:** TG-01 — target identity; PL-02 — player level; SP-14 — target restrictions. Обратные сноски добавлены.

**Изменения кода:** не выполнялись; внесён аудит TG-03.

**Тесты и диагностика**

в файле не указано

**Архитектурные и обратные ссылки:** TG-10, TG-04, TG-01, PL-02, SP-14.

---

### TG-04 — Тип существа (нежить, зверь, гуманоид, демон…) для способностей с условиями

ID: [TG-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L2704). Приоритет: P1.

**Вердикт**

**Вердикт**

**НЕ РЕАЛИЗОВАНО КАК ТИПИЗИРОВАННЫЙ ТИП ЦЕЛИ — ДОРАБОТАТЬ (P1).** Существуют target snapshot и classification, но `creatureType` отсутствует.

**Выбранный путь**

в файле не указано

**Требуемые изменения (полный текст)**

**Требуемые изменения**

1. Проверить native `UnitCreatureType(unit)` на Forever: число/локализованное имя, второй результат, secret restrictions, отсутствие/невалидные unit. Добавить allowlist `GameAPI` только после подтверждения.
2. Привязать `creatureTypeID` к текущему `targetGUID`, проверить идентичность до/после чтения. Нет цели/смена GUID → не переносить тип с прежней цели.
3. Использовать подтверждённый numeric ID как каноническое сравнение; строковые переводы — только отображение или проверенный fallback, не hardcoded английские `lower():find` для шести локалей.
4. `UnitCreatureFamily` хранить отдельно при необходимости; `UnitClassification` TG-03 и тип существа не смешивать.
5. Декларативный `allowedCreatureTypeIDs` и `typeRestrictionObservation` в SP-14/AbilityEligibility, с независимыми READY(true/false)/UNKNOWN. Проверять и максимальный изученный ранг, если ограничения отличаются.
6. При secret creature type в бою UNKNOWN; ранее виденный тип можно сохранить как историческую подсказку с GUID+TTL, но **не** выдавать как свежий READY, особенно после смены цели. Не наследовать тип от соседнего моба/pack.
7. Инвалидация PLAYER_TARGET_CHANGED, смена GUID, unit changes, выход из restricted identity, heartbeat fallback; кэш по GUID+revision, не глобальная переменная типа.
8. Диагностика `creature_type_secret`, `creature_type_unavailable`, `creature_type_mapping_unknown`, `creature_type_guid_changed`, `spell_creature_restriction_unknown`; тесты undead/beast/humanoid/demon/dragonkin/elemental/mechanical, type vs classification, pet family, локали, combat secret, target swap, no target, restricted spell Shackle/Hibernate/Banish.

**Архитектурные ссылки:** TG-01 — target identity, TG-03 — classification, SP-14 — ограничения заклинаний. Обратные сноски добавлены в старые требования.

**Изменения кода:** не выполнялись; внесён аудит TG-04.

**Тесты и диагностика**

в файле не указано

**Архитектурные и обратные ссылки:** TG-01, TG-03, SP-14.

---

### TG-05 — Цель в бою, цель цели (агро на мне / на питомце / на другом)

ID: [TG-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L2754). Приоритет: P1.

**Вердикт**

**Вердикт**

**ЧАСТИЧНО РЕАЛИЗОВАНО — ДОРАБОТАТЬ (P1).** Есть player combat, player threat status и targettarget→player, но нет target combat, targettarget→pet/other и доказательного владельца агро.

**Выбранный путь**

в файле не указано

**Требуемые изменения (полный текст)**

**Требуемые изменения**

1. В `unitSnapshot("target")` добавить `UnitAffectingCombat("target")` через GameAPI и tri-state. Не подменять `targetInCombat` состоянием боя игрока.
2. Добавить `targetOfTargetExists/GUID` и независимо `targetTargetsPlayer`, `targetTargetsPet`, `targetTargetsOther`, с `UnitIsUnit` и проверенной идентичностью player/pet. При `targettarget` отсутствует — все отношения не должны ссылаться на предыдущего юнита.
3. Ввести чёткое разделение `currentTargetRelation` (кого сейчас выбрал моб) и `threatLeader` (кто лидирует по угрозе). `player.hasAggro` переопределить или заменить без нарушения существующих потребителей, добавить migration diagnostics.
4. Общий `ThreatObservation(sourceUnit,targetUnit)` использует `UnitThreatSituation` и, если безопасно, `UnitDetailedThreatSituation`; player/pet/other сравнивать только по подтверждённым наблюдениям. Угроза по party/raid не гарантирует полную картину неизвестных игроков.
5. Привязать чтения к targetGUID до и после, к petGUID при проверке pet, а targettargetGUID не переносить после смены цели. Отсутствие питомца не означает «агро на другом».
6. Проверить `UNIT_TARGET`, `UNIT_THREAT_LIST_UPDATE`, `UNIT_THREAT_SITUATION_UPDATE`, `UNIT_FLAGS` на Forever; инвалидировать target/threat при поддержке; fallback heartbeat только для свежести, не как доказательство.
7. Использовать общие target/identity/party observations из TG-01/PL-02/PL-07, не классовые hunters-only решения. Итоговая готовность способности — `AbilityEligibility`.
8. Диагностика `target_combat_unknown`, `targettarget_guid_changed`, `pet_target_relation_unknown`, `threat_leader_unknown`, `target_vs_threat_mismatch`; тесты player target, pet target, party tank target, no targettarget, mob switches target, taunt, threat leader differs from current target, pet absent, pet changes, combat secret, two mobs, target swap.

**Архитектурные ссылки:** TG-01 — target identity, PL-02 — player/pet identity, PL-07 — combat/group, SP-14 — target restrictions. Обратные сноски внесены.

**Изменения кода:** не выполнялись; внесён аудит TG-05.

**Тесты и диагностика**

в файле не указано

**Архитектурные и обратные ссылки:** TH-03, TH-01, TH-02, EN-02, TG-01, PL-02, PL-07, SP-14.

---

### TG-06 — Время жизни цели (TTD): оценка с границей уверенности, nil если мало данных

ID: [TG-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L2813). Приоритет: P1.

**Вердикт**

**Вердикт**

**НЕ РЕАЛИЗОВАНО КАК ДОСТОВЕРНАЯ ОЦЕНКА TTD — ДОРАБОТАТЬ (P1).** Есть health primitives и декларация `needs.ttd`, но нет модели истории, границ и правил отказа.

**Выбранный путь**

в файле не указано

**Требуемые изменения (полный текст)**

**Требуемые изменения**

1. Ввести ограниченную по размеру/времени историю `(timestamp,confirmedHealth,confirmedMax,GUID)` только из TG-02; хранить по GUID, учитывать смену maxHP и резкие фазы отдельно.
2. Не смешивать health percentage с absolute без явной нормализации; если известен только точный percent — допускается относительный тренд с явно отдельной моделью, но step-curve threshold не превращать в непрерывные проценты.
3. Минимальное число независимых отсчётов и минимальная длина окна задаются конфигурацией модели; если недостаточно — `estimateSeconds=nil`, `status=UNKNOWN`, `reason=insufficient_samples`.
4. Оценить устойчивый отрицательный тренд (например, robust regression/weighted slope) и неопределённость по разбросу/окнам; интервалы описывать как model bounds, не как доказанные 95% CI без калибровки.
5. Отрицательный или нулевой burn rate, лечение, восстановление здоровья, reset/phase, большая дисперсия, отсутствующие/секретные точки → UNKNOWN, не бесконечный TTD.
6. Историю и confidence сбрасывать/понижать при target GUID switch, смерти/исчезновении, выходе из боя/сбросе боя, смене maxHP, фазовых скачках. Краткое исчезновение nameplate не доказывает смерть; допускается bounded stale history только как неготовая оценка.
7. `RotationConditions` поддерживает явные `ttd.estimate`, `ttd.confidence`, `ttd.lowerBound`, `ttd.upperBound` и пороговые условия только если модель готова. Не выдавать `target.dyingSoon` или `willSurviveBurst` из недоказанного TTD.
8. `AbilityEligibility` остаётся единственным авторитетом READY; TTD влияет на экономическую выгодность/приоритет ротации, не является фактом физической возможности заклинания.
9. Диагностика `ttd_insufficient_samples`, `ttd_health_secret`, `ttd_no_negative_trend`, `ttd_phase_reset`, `ttd_high_variance`, `ttd_guid_changed`; тесты стабильный DPS, burst, heal, stop DPS, maxHP change, 2 targets, target swap, secret, step curve, percent exact, short fight, death, out of combat, confidence bounds.

**Архитектурные ссылки:** TG-02/PL-03 — здоровье, TG-01 — targetGUID, AU-06 — multi-GUID lifecycle. Обратные сноски внесены.

**Изменения кода:** не выполнялись; внесён аудит TG-06.

**Тесты и диагностика**

в файле не указано

**Архитектурные и обратные ссылки:** EN-06, EN-01, TG-02, PL-03, TG-01, AU-06.

---

### TG-07 — Состояние контроля цели: превращена, заморожена, оглушена, в страхе, и сломается ли от урона

ID: [TG-07](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L2869). Приоритет: P1.

**Вердикт**

**Вердикт**

**НЕ РЕАЛИЗОВАНО КАК УНИВЕРСАЛЬНЫЙ CC-КОНТРАКТ — ДОРАБОТАТЬ (P1).** Есть запрос отдельного target debuff, но нет классификации CC, достоверного break-on-damage и защиты ротации от разрушения контроля.

**Выбранный путь**

в файле не указано

**Требуемые изменения (полный текст)**

**Требуемые изменения**

1. Повторно использовать AU-01/AU-05 aura reader, AU-02 duration и targetGUID TG-01; не создавать второй scanner.
2. Создать версионированные, проверенные на Forever декларативные соответствия spellID/rank family → `controlMechanics`, `breaksOnDamage`, `damageThreshold`/chance if confirmed; unknown entries remain UNKNOWN.
3. Отдельно учитывать polymorph/incapacitate, frozen/root, stun, fear; множественные одновременные эффекты не сворачивать в одну произвольную метку.
4. Проверять принадлежность ауры текущей цели и статус источника; отсутствие записи в каталоге не доказывает отсутствие контроля.
5. Не смешивать DR/immunity, slow, interrupt/silence и CC break; тип контроля не всегда определяет возможность разрушения уроном.
6. `ControlBreakRiskObservation` оценивает способность (single-target, AoE, cleave, DoT, pet) и текущие подтверждённые эффекты; наличие уже активного DoT и будущие тики учитывать отдельно от немедленного удара.
7. `RotationConditions` получают typed `target.cc.*` и `target.cc.breakRisk` с Needs; `AbilityEligibility` сохраняет финальное READY, а политика избегания breakable CC не должна скрытно блокировать критические defensive/interrupt abilities.
8. Инвалидация по UNIT_AURA, target GUID, смене/снятию эффекта, проверенной механике break; отсутствие доказательства удаления → UNKNOWN, не false.
9. Диагностика `cc_aura_unknown`, `cc_mechanic_unknown`, `cc_break_policy_unknown`, `cc_target_changed`, `cc_break_risk_unknown`; тесты Polymorph, Gouge, Blind, Fear, Frost Nova/root, stun, multi-CC, AoE, DoT tick, pet autoattack, unknown aura, rank variants, dispel, secret aura, target swap.

**Архитектурные ссылки:** AU-01/02/04/05 — ауры, TG-01 — GUID, AU-08 — защиты, SP-14 — spell requirements. Обратные сноски внесены.

**Изменения кода:** не выполнялись; внесён аудит TG-07.

**Тесты и диагностика**

в файле не указано

**Архитектурные и обратные ссылки:** GR-03, EN-04, TG-08, AU-01, AU-05, AU-02, SP-14, TG-01, AU-08.

---

### TG-08 — Бежит ли цель (Hamstring/Wing Clip etc нужен)

ID: [TG-08](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L2928). Приоритет: P2.

**Вердикт**

**Вердикт**

**НЕ РЕАЛИЗОВАНО КАК ДОСТОВЕРНОЕ ОПРЕДЕЛЕНИЕ БЕГСТВА ЦЕЛИ — ДОРАБОТАТЬ (P2).** Есть названия условий slow и общий aura reader, но нет подтверждённого target movement/flee observation.

**Выбранный путь**

в файле не указано

**Требуемые изменения (полный текст)**

**Требуемые изменения**

1. Проверить `GetUnitSpeed("target")`, `UnitIsMoving` и иные возможные API на реальном Forever: наличие, secret flags, боевой режим, GUID-safe reading. Не включать неподтверждённые API в allowlist.
2. Отдельно хранить `moving`, `movingAway`, `fleeing` и `fleeReason` с независимыми статусами. Скорость сама по себе не определяет направление, а движение прочь — не всегда бегство.
3. Если доступна доказательная позиционная динамика, использовать bounded GUID-keyed observations с таймстемпами, фильтром шума и проверкой target switch; если нет — `movingAway/fleeing=UNKNOWN`.
4. Замедление и root читать через AU-01/AU-05/TG-07 с rank-family matching, caster/targetGUID и UNKNOWN при secret. Различать snare, root, fear и иммунитет к замедлению.
5. `slowAbilityUseful` определять по декларативной политике: предотвращение бегства, удержание melee, кайт, PvP, профилактика; отдельно от факта `fleeing`. Не рекомендовать Wing Clip/Hamstring только потому, что target вне melee.
6. Проверять spell-specific `AbilityEligibility` (дистанция, ресурс, cooldown, форма, тип цели), а при UNKNOWN движения не создавать ложное READY из условия профиля.
7. Инвалидировать на смене targetGUID, подтверждённых movement/aura events и revision EventBus; heartbeat только для повторной проверки, не доказательство движения.
8. Диагностика `target_movement_secret`, `target_direction_unknown`, `target_flee_unknown`, `target_slow_aura_unknown`, `slow_policy_preventive`, `target_guid_changed`; тесты неподвижная цель, цель приближается, удаляется, страх, низкое HP NPC flee, кайт, snare already present, slow expiring, root, secret speed, target swap, melee/no-melee, pet target.

**Архитектурные ссылки:** TG-01 — targetGUID, TG-07 — fear/root, AU-01/AU-05 — slow auras, SP-08 — distance. Обратные сноски внесены.

**Изменения кода:** не выполнялись; внесён аудит TG-08.

**Тесты и диагностика**

в файле не указано

**Архитектурные и обратные ссылки:** TG-09, AU-01, AU-05, TG-07, SP-08, TG-01.

---

### TG-09 — Дальность до цели: диапазон (ближний бой, 5–8, 8–30, дальше)

ID: [TG-09](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L2981). Приоритет: P0.

**Вердикт**

**Вердикт**

**ЧАСТИЧНО РЕАЛИЗОВАНО — ДОРАБОТАТЬ (P0).** Melee и spell range есть, доказательных диапазонов 5–8, 8–30, >30 нет.

**Выбранный путь**

в файле не указано

**Требуемые изменения (полный текст)**

**Требуемые изменения**

1. Проверить `LibRangeCheck-3.0` на Forever, включая возвращаемые bounds, secret/combat, погрешности и актуальность spell probes. Не считать наличие библиотеки доказательством корректной работы.
2. Встроить интервальный reader в общий SP-08 `TargetRangeObservation` с targetGUID и source provenance; без параллельного range scanner.
3. `melee` сохранять независимым фактом `C_SwingTimer.IsTargetWithinSwingRange(0)`; `CheckInteractDistance(3)==true` не доказывает melee.
4. Вычислять band READY(true) только если весь подтверждённый интервал внутри полосы; READY(false) только если весь интервал вне полосы; иначе UNKNOWN. Согласовать open/closed границы и округление 5/8/30.
5. Не приравнивать `C_Spell.IsSpellInRange` к числовому расстоянию; допускаются только подтверждённые ограничивающие probes, у которых реально известна геометрия/минимальная дистанция на Forever.
6. Поддержать spell-specific deadzone и min/max range (особенно охотник), независимо от геометрического band; если нет данных о min range, не объявлять [5,8) deadzone для всех.
7. Инвалидировать при targetGUID switch, relevant unit/range changes и heartbeat fallback, bounded TTL; range cache нельзя переиспользовать для другого target.
8. Диагностика `range_interval_unavailable`, `range_interval_crosses_boundary`, `range_probe_unreliable`, `range_target_changed`, `range_secret`; тесты melee, 4.9,5,7.9,8,29.9,30,30.1, >40, moving target, giant hitbox, spell out-of-range despite geometric band, combat secret, target swap.

**Архитектурные ссылки:** SP-08 — canonical range/deadzone; TG-01 — target identity; TG-08 — movement separate; SP-14 — spell requirements. Обратные сноски внесены.

**Изменения кода:** не выполнялись; внесён аудит TG-09.

**Тесты и диагностика**

в файле не указано

**Архитектурные и обратные ссылки:** GR-06, GR-01, EN-07, EN-04, EN-01, SP-08, TG-01, TG-08, SP-14.

---

### TG-10 — Цель — игрок (PvP) или NPC; флаг PvP

ID: [TG-10](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3043). Приоритет: P2.

**Вердикт**

**Вердикт**

**ЧАСТИЧНО РЕАЛИЗОВАНО — ДОРАБОТАТЬ (P2).** Тип player/NPC выводим из уже читаемого `UnitIsPlayer`; собственный PvP-флаг цели и FFA отсутствуют.

**Выбранный путь**

в файле не указано

**Требуемые изменения (полный текст)**

**Требуемые изменения**

1. Экспонировать `isNPC` только при подтверждённом `UnitIsPlayer==false` и подтверждённом существовании target; UNKNOWN identity не становится NPC.
2. Проверить на Forever `UnitIsPVP("target")` и `UnitIsPVPFreeForAll("target")`: доступность, secret flags, ограничения в бою; разрешить в GameAPI только подтверждённые API.
3. Разделить `isPlayer`, `isPvPFlagged`, `isFreeForAllPvP`, `attackable`, `enemyPlayer`, `pvpContext`. `enemyPlayer` требует обоих подтверждённых `isPlayer=true` и `attackable=true`.
4. `pvpContext` получать из существующего PL-07 (arena, battleground, zone), не использовать как замену PvP-флага конкретного юнита.
5. Target GUID guard до/после чтений, invalidation по PLAYER_TARGET_CHANGED, UNIT_FLAGS и подтверждённым PvP/zone events; не наследовать флаг прежней цели.
6. Декларативные `target.isNPC`, `target.isPvPFlagged`, `target.isEnemyPlayer`, `context.inPvP` с Needs и UNKNOWN, без классового PvP движка.
7. Диагностика `pvp_flag_secret`, `pvp_flag_unavailable`, `pvp_flag_target_changed`, `target_identity_unknown`, `pvp_context_not_unit_flag`; тесты NPC enemy/friendly, hostile player, same-faction player, arena/battleground, open-world flagged/unflagged, FFA, secret, target swap, no target.

**Архитектурные ссылки:** TG-01 — target identity, TG-03 — classification, PL-07 — context, SP-14 — spell restrictions. Обратные сноски внесены.

**Изменения кода:** не выполнялись; внесён аудит TG-10.

**Тесты и диагностика**

в файле не указано

**Архитектурные и обратные ссылки:** PL-07, TG-01, TG-03, SP-14.

---

### TG-11 — Фокус-цель и мышь-цель (если профиль их использует)

ID: [TG-11](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L3092). Приоритет: P2.

**Вердикт**

**Вердикт**

**НЕ РЕАЛИЗОВАНО ДЛЯ FOCUS/MOUSEOVER — ДОРАБОТАТЬ (P2).** Есть generic function skeleton `unitSnapshot(unit)`, но снимок, Needs, события, условия и eligibility остаются target-centric.

**Выбранный путь**

в файле не указано

**Требуемые изменения (полный текст)**

**Требуемые изменения**

1. Расширить `Needs.units` до `focus`/`mouseover`; не читать/не подписываться на них, если профиль их не использует.
2. `UnitObservation(unitToken)` — один общий provider для target/focus/mouseover; unit-specific поля independent, guid guard до/после каждого набора данных; отсутствие focus/mouseover не означает отсутствие обычной цели.
3. Подключить `PLAYER_FOCUS_CHANGED`, `UPDATE_MOUSEOVER_UNIT`, `UNIT_TARGET`/UNIT_AURA/UNIT_SPELLCAST события только если подтверждены Forever и нужны профилю; мышь может сменить юнит без смены target.
4. Обобщить aura AU-01/05, cast CA-04 и range SP-08 на разрешённые unit tokens; не переносить `target` GUID, range или aura к focus/mouseover.
5. В `RotationConditions` добавить `focus.*`/`mouseover.*` только для заявленных Needs, включая независимую проверку friendly/enemy и death.
6. В `AbilityEligibility` разделить `targetPolicy` (enemy/friendly/self/none) и `recipientUnit` (target/focus/mouseover), привязать range/identity к **реальному recipient**, а не всегда к `"target"`.
7. Проверять actionbar/macro routing: `@focus`, `@mouseover`, conditional fallback, help/harm; если фактический маршрут защищён/не доказан — UNKNOWN. Не советовать каст в focus при обычной target-only кнопке.
8. Диагностика `focus_missing`, `mouseover_missing`, `recipient_unit_unknown`, `recipient_macro_unverified`, `unit_guid_changed`, `unit_range_secret`; тесты focus present/absent, mouseover moving, friendly heal, enemy interrupt, conditional macro fallback, same GUID target+focus, different GUID, target switch, focus switch, mouseover switch, combat secret, no profile Needs.

**Архитектурные ссылки:** TG-01 — target identity, AU-01 — aura, CA-04 — cast, SP-08 — range, SP-14 — spell restrictions. Обратные сноски внесены.

**Изменения кода:** не выполнялись; внесён аудит TG-11.

**Тесты и диагностика**

в файле не указано

**Архитектурные и обратные ссылки:** GR-01, EN-07, EN-03, EN-02, AU-01, CA-04, SP-08, TG-01, SP-14.

---

