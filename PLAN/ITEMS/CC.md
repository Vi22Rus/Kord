# Карточки CC

Источник: REQUIREMENTS.md, blob 9efdec1900398c978ea121818fb5950cb1620337.

### CC-01 — Игрок под контролем: оглушён, испуган, обездвижен, обезмолвлен, не может кастовать

ID: [CC-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5706). Приоритет: P0. Lua: упомянут (точный статус в источнике).

**Вердикт / статус**

**Вердикт**

**НЕ РЕАЛИЗОВАНО КАК УНИВЕРСАЛЬНАЯ ВОЗМОЖНОСТЬ — ДОРАБОТАТЬ (P0).** Есть базовая проверка пригодности заклинания, но нет подтверждённой typed LoC observation, per-school lockout и условий контроля.

**Архитектурные ссылки:** SP-01, SP-14, EventBus/AbilityEligibility; обратные ссылки внесены непосредственно в SP-01 и SP-14 в этом коммите.

**Изменения Lua:** отсутствуют. Только документация.

**Выбранный путь Kord**

**Выбранный путь Kord**

**Один `PlayerControlObservation`** в GameState поверх read-only GameAPI adapter и `C_LossOfControl`, с tri-state per-category и списком активных событий, где доступны `locType`, `spellID`, `lockoutSchool`, `timeRemaining` и причина неизвестности. Использовать Sonah для typed mappings, RotationMaster для проверки доступности/secret и JustAC для per-spell lockout. Аура `UNIT_AURA` — только дополнительный сигнал; отсутствие найденного дебафа не означает отсутствие LoC. `C_Spell.GetSpellLossOfControlCooldownInfo` — дополнительный per-spell источник, его `isActive` не приравнивать к глобальной немоте; проверять реальную семантику и секретность на Forever.

**Разделить наблюдение и право рекомендации:** `PlayerControlObservation` сообщает факты, `AbilityEligibility` решает доступность конкретного spell/item, учитывая школу, разрешённость использования под CC, ограничения передвижения/позиции, stun/fear/incapacitate, root, silence и spell-specific lockout. `ROOT` подавляет требующие перемещения действия, но не все касты; `SILENCE`/school lockout подавляют только затронутые заклинания. Для breaker/escape abilities не вводить общий запрет по `anyCC`, иначе нельзя рекомендовать освобождение. Если проверка неизвестна — `UNKNOWN` с reason, не `READY`; при подтверждённом BLOCKED по другому обязательному условию — BLOCKED.

**UI и обновления:** не удалять очередь рекомендаций целиком при временном CC: показывать заблокированное состояние/причину либо рекомендовать допустимый breaker, согласно уже действующей политике слотов. EventBus проверяет поддерживаемые `LOSS_OF_CONTROL_*` события Forever, `UNIT_AURA`, `SPELL_UPDATE_USABLE`, смену формы/спека/цели и корректно инвалидирует `playerControl` revision; ограниченный heartbeat только при необходимости. `Needs.playerControl` ленивый, memo на оценку; не сканировать LoC отдельно для каждого правила. В логах различать `control_unknown`, `stunned`, `feared`, `rooted`, `silenced`, `incapacitated`, `school_locked`, `spell_loc_locked`, `control_api_missing`, `control_secret`.

**Требуемые изменения (полный текст)**

**Требуемые изменения**

1. В `GameAPI` добавить capability-probed read-only `C_LossOfControl.GetActiveLossOfControlDataCount/GetActiveLossOfControlData` и `C_Spell.GetSpellLossOfControlCooldownInfo` только после проверки Forever API Matrix, сигнатур и secret semantics.
2. В `GameState` реализовать единый `PlayerControlObservation` с `TRUE/FALSE/UNKNOWN` по типам и причинами, безопасным чтением locType/school/duration и ограниченным бюджетом.
3. Расширить `AbilityEligibility` per-spell запретами stun/fear/incapacitate, silence/school lockout и исключениями для breaker; root не трактовать как запрет всех кастов.
4. Добавить `RotationConditions` условия `player.stunned/feared/rooted/silenced/incapacitated`, `player.canCast(spellID)`, `Needs.playerControl`; использовать существующий общий порядок приоритетов.
5. Добавить в EventBus подтверждённые Forever события контроля и ревизии, не считать `UNIT_AURA` достаточным универсальным источником.
6. DevTools-only диагностика: тип, источник, доступность данных, школа, длительность (если читается), reason, per-spell decision, revision; не пытаться вычислять secret.
7. Тесты: свободное состояние, stun/fear/root/silence/incapacitate, pacify, charm, school interrupt одной школы, несколько одновременных эффектов, breaker под CC, physical spell под silence, обычный каст под root, каст во время движения, missing/secret API, смена состояния между тиками, ложное `IsUsableSpell=false`, сохранение/серость иконки, отсутствие false READY и protected cast.

**Тесты и диагностика**

в файле не указано

**Архитектурные и обратные ссылки:** CC-05, CC-04, CC-02, CC-03, SP-01, SP-14.

---

### CC-02 — Каким способом можно разорвать контроль (способность, предмет)

ID: [CC-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5772). Приоритет: P1. Lua: упомянут (точный статус в источнике).

**Вердикт / статус**

**Вердикт**

**НЕ РЕАЛИЗОВАНО КАК УНИВЕРСАЛЬНАЯ ВОЗМОЖНОСТЬ — ДОРАБОТАТЬ (P1).** Базовые usability и cooldown checks существуют, но подтверждённого mechanic-aware подбора освобождающей способности/предмета нет.

**Архитектурные ссылки:** CC-01, SP-01, SP-14, IT-01–IT-04, IT-11–IT-14. Обратная ссылка на CC-02 внесена в CC-01 в этом коммите; для прочих общих модулей связь зафиксирована здесь, без создания дублирующих провайдеров.

**Изменения Lua:** отсутствуют. Только документация.

**Выбранный путь Kord**

**Выбранный путь Kord**

Расширить CC-01 **единым `ControlBreakSelection`** (политика, а не второй движок и не второй LoC scanner) и проверенным `CCBreakerCatalog`. Каталог строить по Forever-specific mechanic/effect data из JustAC с `mechanicID/locType`, `spellID`, `itemID`, `effectKind`, `canUseWhileControlled`, `class/race/spec/level`, `target/self`, `source/verified`; не копировать автоматически все retail ID. Для предметов пользоваться IT-01–IT-04, IT-11–IT-14 (количество, экипировка, cooldown, shared cooldown, выбор игрока, разрешённость в бою), для заклинаний — SP-01/SP-14 и CC-01 per-spell lockout. Не использовать один `IsUsableSpell=false` как доказательство, что breaker невозможен, но и не повышать сомнительный кандидат до READY.

Сначала получить текущие эффекты CC-01 и их типы. Для каждого подтверждённого активного эффекта отобрать **снимающие текущий контроль** кандидаты, проверить известность/наличие, ресурсы, кулдауны, ограничения школы/контроля, цели и подтверждённую возможность использовать **именно под текущим CC**. При нескольких эффектах учитывать coverage и оставшиеся запреты после одного применения. Сохранить пользовательский приоритет/экономию PvP trinket и редких предметов; не рекомендовать дорогой breaker при кратком оставшемся CC без учёта настраиваемого `minimumRemainingSeconds`, если время достоверно. Не угадывать время при secret. В спорных случаях `UNKNOWN` с reason, а не ложный READY.

EventBus инвалидирует по подтверждённым Forever `LOSS_OF_CONTROL_*`, cooldown, equipment, bag, spellbook, talent/race/spec и config revisions; lazy `Needs.controlBreakers`, per-evaluation memo, bounded budget. Диагностика DevTools: active mechanics, candidate list, effect kind, usable-under-control, cooldown/item reason, final selection, unknown source, no secret coercion. Не рекомендовать предметы, которые дают лишь **иммунитет перед контролем**, как способ разорвать уже наложенный stun/fear.

**Требуемые изменения (полный текст)**

**Требуемые изменения**

1. Завершить CC-01 typed LoC observation и capability-probed Forever API; использовать один общий источник активных эффектов.
2. Ввести `CCBreakerCatalog` с Forever-specific mechanic/effect mappings и разделением снятия действующего контроля, профилактической иммунности, dispel союзника и escape root/snare.
3. Ввести `ControlBreakSelection` с фильтрацией по активным эффектам, классу/расе/спеку, известности, предмету, кулдауну, ресурсу, типу цели, school lockout и возможностью применения под CC.
4. Подключить общий `AbilityEligibility` и IT-01–IT-04/IT-11–IT-14, без отдельного item scanner, второго cooldown engine и автоприменения.
5. Добавить пользовательские настройки приоритета и экономии PvP trinket/редких расходников, минимального остатка контроля для расхода, явные значения по умолчанию.
6. Добавить в `RotationConditions` `player.hasBreakableControl`, `player.breakerAvailable`, `Needs.controlBreakers` и EventBus revisions только по подтверждённым событиям.
7. Добавить DevTools-only reasons: `breaker_not_known`, `breaker_item_missing`, `breaker_on_cooldown`, `breaker_wrong_mechanic`, `breaker_prevention_only`, `breaker_cannot_use_while_controlled`, `breaker_school_locked`, `breaker_unknown`, `breaker_ready`.
8. Тесты: stun/fear/root/snare/silence/incapacitate/charm/polymorph, school interrupt, 2 одновременных CC, racials, class breaker, PvP trinket equipped/unequipped/on cooldown, расходуемый предмет, иммунитет-only, мгновенный/почти закончившийся CC, secret/nil, config conserve, смена экипировки/класса, отсутствие ложного READY и protected use.

**Тесты и диагностика**

в файле не указано

**Архитектурные и обратные ссылки:** CC-04, CC-03, CC-01, IT-01, IT-04, IT-11, IT-14, SP-01, SP-14.

---

### CC-03 — Замедление и обездвиживание на игроке, нужно ли убрать

ID: [CC-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5834). Приоритет: P2. Lua: упомянут (точный статус в источнике).

**Вердикт / статус**

**Вердикт**

**НЕ РЕАЛИЗОВАНО КАК УНИВЕРСАЛЬНАЯ ВОЗМОЖНОСТЬ — ДОРАБОТАТЬ (P2).** Различение root/snare и решение, стоит ли расходовать освобождающее действие, не подтверждены как единая возможность в проверенном Kord.

**Архитектурные ссылки:** CC-01, CC-02, SP-14, IT-01–IT-03, IT-12–IT-14. Обратные ссылки внесены в CC-01 и CC-02 в этом коммите.

**Изменения Lua:** отсутствуют. Только документация.

**Выбранный путь Kord**

**Выбранный путь Kord**

Ввести **`MovementImpairmentRemovalPolicy`** поверх **единого** `PlayerControlObservation` (CC-01) и `ControlBreakSelection` (CC-02). Сначала установить, что именно действует: `ROOT`, `SNARE` или оба; при отсутствии достоверного LoC API и неизвестной aura mapping не утверждать `FALSE`. Отдельно определить `movementNeeded` по уже имеющимся проверенным сигналам движка (расстояние до цели/нужна позиция, маршрут отступления, опасная зона только при наличии достоверного источника, ручной приоритет PvP). **Не выдумывать универсальный детектор опасной зоны или направление движения**, если соответствующего провайдера нет.

Если `movementNeeded=FALSE` — `KEEP`; если `TRUE` и root блокирует необходимое перемещение либо snare подтверждённо мешает достижению цели — `REMOVE` только при доступном подходящем breaker из CC-02 и приемлемой цене. Если необходимость движения неизвестна, возвращать `UNKNOWN` либо `KEEP` по явной консервативной настройке, не форсировать расход предметов. Учитывать остаток эффекта, `minRemainingSeconds`, `allowBreakRoot`, `allowBreakSnare`, `conserveCooldowns`, `combatOnly`, `pvpPreference` и важность способности; secret time не трактовать как ноль. Под root допустимы касты, не требующие движения; под snare обычные заклинания не должны блокироваться только из-за slow.

Интеграция: CC-01/CC-02, SP-14 (позиция/ограничения способности), общие проверки дистанции/движения только при подтверждённом API, IT-01–IT-03/IT-12–IT-14 для предметов. `AbilityEligibility` остаётся окончательным gate. EventBus использует подтверждённые Forever LoC/aura, изменения позиции/цели/каста и config revisions; ленивое `Needs.movementImpairment`, memo на оценку, bounded updates. DevTools reasons: `movement_not_needed`, `movement_needed`, `root_active`, `snare_active`, `impairment_unknown`, `breaker_unavailable`, `effect_too_short`, `conserve_breaker`, `removal_ready`.

**Требуемые изменения (полный текст)**

**Требуемые изменения**

1. Реиспользовать CC-01 typed `ROOT/SNARE` observation и CC-02 verified breaker catalog; не создавать собственный LoC reader и сканер предметов.
2. Добавить отдельное условие необходимости перемещения/позиции с `TRUE/FALSE/UNKNOWN`, опирающееся только на доступные и подтверждённые источники.
3. Ввести `MovementImpairmentRemovalPolicy` с `REMOVE/KEEP/UNKNOWN`, независимыми настройками root/snare, минимальным остатком эффекта и экономией кулдаунов/предметов.
4. Для `REMOVE` проверять фактическую способность снять именно текущий эффект, известность, ресурс, кулдаун, возможность применения под контролем и итоговый `AbilityEligibility`.
5. Добавить `RotationConditions` условия `player.rooted`, `player.snared`, `player.needsMovementImpairmentRemoval`, `Needs.movementImpairment` и EventBus invalidation.
6. DevTools-only диагностика типа контроля, остатка (если читается), потребности движения, выбранного breaker, причин отказа и источника UNKNOWN.
7. Тесты: root/snare/both, бой/OOC, PvP/PvE, стоит и кастует, цель вне дистанции, требуется сближение/отход, короткий эффект, неизвестная длительность, недоступный breaker, эффект снимает только slow, эффект снимает только root, иммунитет-only, несколько CC, смена цели/позиции, secret/nil, отсутствие ложного REMOVE/READY и protected use.

**Тесты и диагностика**

в файле не указано

**Архитектурные и обратные ссылки:** CC-02, CC-01, SP-14, IT-01, IT-03, IT-12, IT-14.

---

### CC-04 — Прерывания: можно ли прервать цель, какая способность у меня есть, готова ли она

ID: [CC-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5889). Приоритет: P1. Lua: упомянут (точный статус в источнике).

**Вердикт / статус**

**Вердикт**

**НЕ ПОДТВЕРЖДЕНО КАК ПОЛНАЯ УНИВЕРСАЛЬНАЯ ВОЗМОЖНОСТЬ — ДОРАБОТАТЬ (P1).** Базовые cast и spell-API уже есть, но единый безопасный выбор готового interrupt под конкретный каст не подтверждён.

**Архитектурные ссылки:** CC-01, CC-02, SP-01, SP-14, EventBus/AbilityEligibility; обратные ссылки внесены в CC-01 и CC-02.

**Изменения Lua:** отсутствуют. Только документация.

**Выбранный путь Kord**

**Выбранный путь Kord**

Расширить имеющийся cast observation в GameState до **`InterruptOpportunityObservation`**, используя один `UnitCastingInfo/UnitChannelInfo` reader для target/focus/nameplate по доступности и безопасной идентификации GUID. Нормализовать **разные tuple** для cast/channel и проверить сигнатуры на Forever: `notInterruptible`, spellID, start/end, secret-значения. В случае `notInterruptible=true` direct interrupt BLOCKED; при `false` подтверждённо допустим; при `nil`/secret — UNKNOWN. При отсутствующем касте и достоверном источнике — WAIT. Не переносить устаревший каст между сменами целей/GUID.

`InterruptSelection` берёт кандидатов из проверенного Forever-specific каталога (JustAC/MaxDps/классовые Sonah), различая `DIRECT_INTERRUPT`, `SILENCE`, `STUN/CC_STOP`. Для каждого проверяет spell known/ранг, доступность для класса/формы/талантов, ресурс, cooldown/charges/GCD, дальность, LoS/позицию только при достоверном API, собственные CC (CC-01), school lockout, ограничения цели и ожидаемое время достижения/применения. Не считать spell `IsUsableSpell` единственным доказательством, что прерывание сработает. При нескольких готовых вариантах выбирать по пользовательской политике (сохранение длинного cooldown, предпочтение direct interrupt), не дублируя итоговый `AbilityEligibility`.

Для PvE/PvP важность и тайминг прерывания — отдельные настраиваемые условия, **не часть** бинарного факта `interruptible`; по умолчанию не выдавать `INTERRUPT`, если время/флаг недоступны и нет подтверждённого безопасного сценария. EventBus: cast/channel start/stop/delayed/update, смена цели, cooldown/charges, spellbook/таланты/форма, CC-01, GUID revisions, ограниченный heartbeat до конца каста; lazy `Needs.interruptOpportunity`, per-evaluation memo. Диагностика DevTools: target GUID, cast ID/type, notInterruptible, remaining (если допустимо), список кандидатов и причины отказа, источник UNKNOWN, event revision.

**Требуемые изменения (полный текст)**

**Требуемые изменения**

1. Расширить GameState единым `InterruptOpportunityObservation` для cast/channel и `notInterruptible` с tri-state/secret-safe и корректной идентификацией цели.
2. Верифицировать Forever сигнатуры `UnitCastingInfo`/`UnitChannelInfo`, включая разницу индексов, время, spellID, protected/secret поля; не угадывать `nil`.
3. Ввести проверенный `InterruptAbilityCatalog` по классам/формам/талантам/рангам с различением прямого interrupt и CC-stop.
4. Реализовать `InterruptSelection` с reuse spell known, cooldown/charges, resource, range, target, CC-01 и итогового `AbilityEligibility`.
5. Добавить `RotationConditions` условия `target.casting`, `target.castInterruptible`, `player.interruptAvailable`, `Needs.interruptOpportunity`; не создавать второй cooldown/cast scanner.
6. Добавить EventBus invalidation для подтверждённых Forever cast/channel update, смены target/GUID, spellbook/формы/спека и cooldown/charges.
7. DevTools reasons: `target_not_casting`, `target_cast_unknown`, `target_not_interruptible`, `interrupt_spell_unknown`, `interrupt_not_known`, `interrupt_cooldown`, `interrupt_out_of_range`, `interrupt_player_controlled`, `interrupt_too_late`, `interrupt_ready`; без попытки раскрыть secret.
8. Тесты: обычный каст/канал, некастующая цель, interruptible true/false/UNKNOWN, cast/channel tuple, цель сменена, фокус, дальность/LoS, learned/unlearned/rank, cooldown/GCD/charges, silence/stun иммунитет, босс, own stun/silence, каст почти завершён, 2+ кандидата, nil/secret, обновление каста и отсутствие ложного READY/protected cast.

**Тесты и диагностика**

в файле не указано

**Архитектурные и обратные ссылки:** CC-05, CC-01, CC-02, SP-01, SP-14.

---

### CC-05 — Школа заблокирована после моего прерывания

ID: [CC-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L5949). Приоритет: P2. Lua: упомянут (точный статус в источнике).

**Вердикт / статус**

**Вердикт**

**НЕ ПОДТВЕРЖДЕНО КАК УНИВЕРСАЛЬНАЯ ВОЗМОЖНОСТЬ — ДОРАБОТАТЬ (P2).** Базовые события прерывания есть, но достоверное определение именно моего interrupt, школы противника и времени lockout не подтверждено.

**Архитектурные ссылки:** CC-01 (собственный school lockout — другое состояние), CC-04 (interrupt observation/selection), SP-14, EventBus. Обратные ссылки внесены в CC-01 и CC-04.

**Изменения Lua:** отсутствуют. Только документация.

**Выбранный путь Kord**

**Выбранный путь Kord**

Расширить CC-04 единым **`EnemySchoolLockoutObservation`**, привязанным к вражескому GUID и общему cast/event observation. Для подтверждения факта `мой interrupt` использовать **только** надёжный источник, содержащий interrupter/source GUID и interrupted target GUID; если combat log/событие на Forever не предоставляет доступных branchable GUID, сохранить `UNKNOWN`. `UNIT_SPELLCAST_INTERRUPTED` без проверяемого source — лишь `cast interrupted`, не `my interrupt`.

Школу определять по проверенному spellID → school mask или по достоверному payload; длительность — по проверенному **Forever-specific** interrupt spell catalog с поправками только на подтверждённые правила клиента. `VERIFIED_INFERRED` означает вычисленный таймер с явной provenance и сроком жизни, не прямое наблюдение. Если механика, длительность, школа, цель, источник или PvP/PvE modifier неизвестны — `UNKNOWN`, не подставлять retail значения. Несколько прерываний одного GUID/школы обновлять только по доказанным правилам; при новом GUID очищать view, но не переносить старую запись. TTL и bounded storage для GUID; неизвестная/secret school mask не участвует в битовых операциях.

Результат нужен как дополнительный контекст выбора CC-04 и тактических условий: если школа врага уже заблокирована, не рекомендовать бессмысленное повторное прерывание той же школы без нового прерываемого каста; если школа неизвестна, не подавлять interrupt по догадке. Нельзя считать школу заблокированной только потому, что цель перестала кастовать. EventBus: подтверждённые interrupt/combat-log/cast события, target GUID и bounded expiry heartbeat, lazy `Needs.enemySchoolLockout`, per-evaluation memo. DevTools: `interrupt_source_unknown`, `interrupt_target_unknown`, `interrupted_school_unknown`, `lockout_duration_unknown`, `lockout_inferred`, `lockout_active`, `lockout_expired`, `lockout_not_applied`.

**Требуемые изменения (полный текст)**

**Требуемые изменения**

1. Проверить на Forever фактическую доступность combat-log interrupt source/target GUID, spellID, interrupted school и secret-поведение `UNIT_SPELLCAST_INTERRUPTED`; без этого не заявлять надёжный `my interrupt`.
2. Добавить в общий CC-04 cast observation GUID-keyed `EnemySchoolLockoutObservation` без второго сканера каста.
3. Создать проверенные Forever-specific сведения о `interruptSpellID → effectKind/schoolLockoutDuration` и `interruptedSpellID → schoolMask`; не переносить retail длительности без проверки.
4. Различать подтверждённый факт прерывания, доказанную блокировку, вычисленную по проверенным данным блокировку и `UNKNOWN`.
5. Учитывать multi-school masks, разные классовые interrupt, PvP/PvE, повторные прерывания, смену target/GUID, окончание таймера и неизвестные данные.
6. Добавить `RotationConditions` `target.schoolLocked(schoolMask)`, `target.schoolLockoutRemaining`, `Needs.enemySchoolLockout`; использовать для контекста CC-04, не подменять `target.castInterruptible`.
7. EventBus revision/invalidation и ограниченное хранение по GUID, DevTools причины и provenance, без secret coercion.
8. Тесты: interrupt игроком/союзником/другим врагом, direct interrupt без lockout, lockout на 1 школу и multi-school, школа неизвестна, 2 противника, смена цели, прерван channel, повторный interrupt, PvP/PvE, истечение времени, nil/secret payload, недоступный combat log, отсутствие ложного `ACTIVE` и protected actions.

**Тесты и диагностика**

в файле не указано

**Архитектурные и обратные ссылки:** CC-01, CC-04, SP-14.

---

