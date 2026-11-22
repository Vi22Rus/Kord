# Карточки SW

Источник: REQUIREMENTS.md, blob 9efdec1900398c978ea121818fb5950cb1620337.

### SW-01 — Автоатака включена / выключена; автострельба и волшебная палочка

ID: [SW-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4623). Приоритет: P0. Lua: упомянут (точный статус в источнике).

**Вердикт / статус**

**Вердикт**

**ЧАСТИЧНО РЕАЛИЗОВАНО — ДОРАБОТАТЬ (P0).** В Kord уже существует Auto Shot observation и C_Spell API allowlist, но не подтверждён единый надёжный статус ближней автоатаки, wand Shoot и auto-switch клиента с tri-state и безопасной политикой рекомендаций.

**Архитектурные ссылки:** SP-14, PE-03, PE-04, EN-04, EN-07, PE-05. Обратные ссылки внесены в эти требования в том же коммите.

**Изменения Lua:** отсутствуют. Только документация.

**Выбранный путь Kord**

**Выбранный путь Kord (решение по сравнению)**

**Единый логический `PlayerAutoAttackObservation` в GameState с тремя `AutoAttackModeObservation`, по образцу RotationMaster tri-state API и JustAC Forever-specific проверки, плюс Sonah auto-switch awareness.** Не создавать class-specific scanners. `MELEE_ATTACK`: `C_Spell.IsCurrentSpell(6603)`; `RANGED_AUTO_SHOT`: `C_Spell.IsAutoRepeatSpell(75)`; `WAND_SHOOT`: `C_Spell.IsAutoRepeatSpell(5019)`; отдельный `currentSpell` для каждого — диагностический факт, а не замена autoRepeat. Если client API возвращает secret/nil, `UNKNOWN(reason)`; legacy fallback только после подтверждения на Forever и GameAPI allowlist. События `START_AUTOREPEAT_SPELL`/`STOP_AUTOREPEAT_SPELL` используются как **инвалидация и подтверждающие сигналы**, не вечный источник true/false при пропущенном событии; target change, weapon swap, player death, combat leave, zone, form, mount/vehicle сбрасывают устаревшие предположения. `C.autoSwapping`-подобный client policy flag хранить отдельно `autoSwitchEnabled=TRUE/FALSE/UNKNOWN`; при true и уже активной Attack/Auto Shot не предлагать противоположное переключение. Проверить на Forever точный API флага настройки и изменение поведения; не угадывать по классу. Wand Shoot требует подтверждённую wand, learned Shoot, range, отсутствие несовместимого каста/движения; Auto Shot — ranged weapon, ammo если актуально Forever, minimum range, movement/standing requirements. Attack — confirmed melee range and CC safety. Оценка `autoAttackNeeded` отдельно от факта `active`, `UNKNOWN` блокирует повторную рекомендацию включения. `AbilityEligibility` остаётся **единственным** финальным READY; никаких защищённых вызовов. Lazy `Needs.autoAttack`, event coalescing, per-evaluation memo; SW-02 позже использует тот же identity/revision, не повторяет active-state reader.

**Требуемые изменения (полный текст)**

**Требуемые изменения**

1. Ввести единый `PlayerAutoAttackObservation` для Attack 6603, Auto Shot 75, Wand Shoot 5019, три независимых tri-state status, provenance и revision.
2. Переиспользовать существующий `GameState.ReadAutoShot`, уточнить его семантику; добавить Attack/Wand без отдельного сканера и совместимость `autoShot.active`.
3. Проверить на Forever `C_Spell.IsCurrentSpell`, `C_Spell.IsAutoRepeatSpell`, legacy fallbacks, secret/nil, cast/queued semantics и типы значений; не считать nil false.
4. Проверить клиентскую настройку Auto Attack / Auto Shot auto-switch, event/API и влияние на Attack/Auto Shot при смене дистанции; хранить отдельно от active state.
5. EventBus `START_AUTOREPEAT_SPELL`, `STOP_AUTOREPEAT_SPELL`, combat/target/weapon/form/vehicle/zone revisions, bounded memo, без вечного доверия к событиям.
6. Добавить `autoAttack.active`, `autoShot.active`, `wandShoot.active` и `autoAttack.autoSwitchEnabled` в RotationConditions с явным UNKNOWN; не путать `IsCurrentSpell` с auto-repeat.
7. Отдельная `AutoAttackNeedPolicy`: alive attackable target, EN-04 breakable CC, proven melee/ranged range, weapon/ammo/standing/cast, no harmful toggles; fail-closed unknown.
8. Согласовать fallback policy с `AbilityEligibility` и SP-14: не обходить финальный READY через `ignoreReady`, не выполнять protected actions.
9. DevTools-only диагностика: `autoattack_melee_unknown`, `autoattack_ranged_unknown`, `autoattack_wand_unknown`, `autoattack_secret`, `autoattack_current_vs_repeat_disagree`, `autoattack_auto_switch_unknown`, `autoattack_auto_switch_suppressed`, `autoattack_target_unverified`, `autoattack_cc_unsafe`, `autoattack_repeat_event_stale`, `autoattack_mode_changed`.
10. Тесты: Attack on/off, Auto Shot on/off, Wand Shoot on/off, switch melee/ranged with auto-switch enabled/disabled, target change/death, range minimum/dead zone, wand vs bow/gun/crossbow, no ammo, moving/standing, cast/channel, queued melee next-swing vs active attack, secret/nil/missing API, event missed/out of order, combat leave, pet autoattack independent, no duplicate toggles, no protected actions.

**Тесты и диагностика**

в файле не указано

**Архитектурные и обратные ссылки:** SW-04, SW-03, SW-02, EN-04, SP-14, PE-03, PE-04, EN-07, PE-05.

---

### SW-02 — Таймеры ударов: до следующего ближнего и дальнего удара

ID: [SW-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4680). Приоритет: P1. Lua: упомянут (точный статус в источнике).

**Вердикт / статус**

**Вердикт**

**НЕ РЕАЛИЗОВАНО КАК УНИВЕРСАЛЬНАЯ ВОЗМОЖНОСТЬ — ДОРАБОТАТЬ (P1).** В Kord есть range API и Auto Shot active observation, но нет доказанного player swing anchor/speed provider для remaining main/off/ranged.

**Архитектурные ссылки:** SW-01, SP-14, EN-07, PE-05. Обратные ссылки внесены в эти требования в том же коммите.

**Изменения Lua:** отсутствуют. Только документация.

**Выбранный путь Kord**

**Выбранный путь Kord**

**Один `PlayerSwingObservation` поверх SW-01 `PlayerAutoAttackObservation`, с `SwingEventAdapter` + `SwingSpeedAdapter`, общим EventBus и единым monotonic clock.** Не создавать hunter/rogue/warrior-specific swing scanners. События `PLAYER_SWING` (если действительно доступны Forever) и `COMBAT_LOG_EVENT_UNFILTERED` после client probe дают подтверждённый last swing anchor, с фильтром `sourceGUID==playerGUID` и классификацией `main/off/ranged`. Для Auto Shot/Wand проверять тип и семантику `RANGE_*` (wand может приходить как `SPELL_*`); при неясном типе — UNKNOWN. Интервал `UnitAttackSpeed` main/off и `UnitRangedDamage` ranged только при проверенном numeric не-secret value; при secret допускается подтверждённый event-reported interval (Sonah/ForeverAuras), но не угадывание скорости. `remaining=max(0,lastConfirmedSwingAt+validatedInterval-now)` является **ESTIMATED**, если phase/rate может меняться; после missed events/haste/weapon swap/movement/cast reset/auto-repeat stop — invalidation. `remaining=0` означает **ожидаемое окно**, не доказанный совершённый удар. `C_SwingTimer.IsTargetWithinSwingRange` остаётся **только** range observation. Lazy `Needs.swing`, per-evaluation memo, bounded event ring buffer и coalescing; не проводить постоянное дорогое сканирование. Политика next-swing/shot-weaving отдельно от observation, использует SW-01 active/EN-04 CC safety/target range и AbilityEligibility как единственный final READY.

**Требуемые изменения (полный текст)**

**Требуемые изменения**

1. Ввести `PlayerSwingObservation` с main/off/ranged и `nextMelee`, отдельными status/reason/source/revision, не дублировать SW-01 active-state reader.
2. Проверить Forever `UnitAttackSpeed`, `UnitRangedDamage`, return layout, numeric secret, `PLAYER_SWING`, combat log `SWING_*`/`RANGE_*`, `isOffHand` и sourceGUID.
3. Реализовать один `SwingEventAdapter` с доказательным player attribution, offhand split и проверкой wand/Auto Shot event identity.
4. Реализовать `SwingSpeedAdapter` с validated seconds, independent main/off/ranged, изменениями haste, weapon speed, ranged weapon/ammo и нулевыми/secret значениями.
5. Вычислять predicted next/remaining только при подтверждённом anchor + interval, хранить `ESTIMATED` и `UNKNOWN`, не выдавать `math.huge` или отсутствие события за ноль.
6. EventBus добавить подтверждённые swing/attack-speed/weapon/target/combat/zone invalidation, bounded ring buffer, coalescing и revision; не полагаться на одно пропущенное событие.
7. RotationConditions `swing.main.remaining`, `swing.off.remaining`, `swing.ranged.remaining`, `swing.nextMelee.remaining` с `Needs.swing`, per-pass memo и fail-closed.
8. Связать SW-01 auto-repeat mode, next-swing queue policy и SP-14 AbilityEligibility без автоматического нажатия кнопок.
9. DevTools-only диагностика: `swing_api_unavailable`, `swing_speed_secret`, `swing_anchor_missing`, `swing_source_guid_mismatch`, `swing_hand_unknown`, `swing_ranged_identity_unknown`, `swing_haste_invalidated`, `swing_event_missed`, `swing_remaining_estimated`, `swing_remaining_unknown`, `swing_timer_expired_unconfirmed`.
10. Тесты: main only, dual wield, offhand miss, ranged Auto Shot, wand Shoot, weapon swap, haste gained/lost, combat start before first swing, swing delayed by cast/movement, stopped auto-repeat, target switch, missed/out-of-order combat-log event, secret speed in combat, event-reported duration, offhand ambiguity, sourceGUID pet vs player, estimated zero without swing, absent API, no OnUpdate heavy scan/protected actions.

**Тесты и диагностика**

в файле не указано

**Архитектурные и обратные ссылки:** SW-04, SW-03, SW-01, EN-04, SP-14, EN-07, PE-05.

---

### SW-03 — Окно «не клиппить Auto Shot» для стрелка

ID: [SW-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4735). Приоритет: P1. Lua: упомянут (точный статус в источнике).

**Вердикт / статус**

**Вердикт**

**НЕ РЕАЛИЗОВАНО КАК УНИВЕРСАЛЬНАЯ ВОЗМОЖНОСТЬ — ДОРАБОТАТЬ (P1).** В Kord есть Auto Shot active read и начатый `Needs.swing` contract, но нет подтверждённого ranged phase timer, per-action reset/lock policy и вычисляемого non-clipping window.

**Архитектурные ссылки:** SW-01, SW-02, SP-14, EN-04, PE-05, EN-07. Обратные ссылки внесены в эти требования в том же коммите.

**Изменения Lua:** отсутствуют. Только документация.

**Выбранный путь Kord**

**Выбранный путь Kord**

**Один `AutoShotClipWindowObservation` поверх SW-01 `PlayerAutoAttackObservation`, SW-02 `PlayerSwingObservation.ranged`, общего `CastTimingObservation` и spell metadata/policy.** Никакого второго swing scanner и отдельного hunter event loop. `ShotInteractionPolicy(spellFamily,clientBuild)` — проверенный Forever-каталог `PRESERVES/RESETS/PAUSES/UNKNOWN` (на базе ForeverAuras, но с валидацией конкретного билда); `ActionLockObservation` — реальный cast/channel duration + проверенные GCD/animation/shot locks, а не просто GCD всех инстантов. Для non-reset: `safeBudget = shotRemaining - actionLockDuration - safetyMargin`, `SAFE` только при положительном бюджете и достаточно надёжном shot anchor; reset/pauses — отдельная политика, не маскировать сравнение простым `>0`. Если shot inactive, dead-zone, target/range unconfirmed, event stale, speed secret, action lock неизвестен, haste/weapon swap или mode auto-switch — `UNKNOWN/NOT_APPLICABLE` с reason. При `shotRemaining` близком к нулю допустима отдельная `WAIT_FOR_SHOT` подсказка (не spell READY) только когда есть подтверждённая фаза; после подтверждённого `PLAYER_SWING` окно пересчитывается. Предусмотреть `safetyMargin` настройкой с документированными границами, отдельно от порогов отдельных spell families; не навязывать всем классам или всем hunter abilities один порог.

**Критический нюанс:** не каждый instant spell клиппит Auto Shot и не всякий cast сбрасывает таймер; необходимо тестировать на Forever, что реально останавливает/сдвигает выстрел, включая движение, GCD, Aimed/Multi/Steady Shot, смену дистанции, Feign Death и авто-переключение. `ShotInteractionPolicy` ограничивает рекомендации профиля, но **не** даёт `READY` и не обходит `AbilityEligibility`. Lazy `Needs.autoShotClip` (подразумевает SW-01/SW-02/cast timing), memo на evaluation, event revision и bounded вычисления.

**Требуемые изменения (полный текст)**

**Требуемые изменения**

1. Ввести `AutoShotClipWindowObservation` с SAFE/UNSAFE/UNKNOWN/NOT_APPLICABLE, `safeBudget`, source/reason/revision; не дублировать SW-02.
2. Переиспользовать SW-01 Auto Shot active и SW-02 ranged remaining с подтверждённым phase confidence; неизвестный/устаревший timer — UNKNOWN.
3. Валидировать на Forever `PLAYER_SWING` ranged, `UnitRangedDamage`, cast/channel start/end, ranged reset/pause, тайминг первого выстрела и смену режима.
4. Создать `ShotInteractionPolicy` для spell families `PRESERVES/RESETS/PAUSES/UNKNOWN` с версионированной проверкой Forever; различать Aimed/Multi/Steady/Feign Death и другие действия.
5. Ввести `ActionLockObservation` (cast time, validated animation/shot lock, applicable GCD) и отдельный конфигурируемый `safetyMargin`; не считать каждый instant равным одному GCD без доказательства.
6. Ввести `autoShot.clipSafe(spellID)`/эквивалент как lazy RotationConditions, UNKNOWN fail-closed, без повторного сканирования.
7. Определить `WAIT_FOR_SHOT`/post-shot policy без ложного spell READY, отдельно от обычной приоритетной ротации и AbilityEligibility.
8. EventBus: shot/cast/weapon/haste/target/range/movement/auto-repeat invalidation; bounded per-evaluation memo, no per-frame heavy scan.
9. DevTools-only диагностика: `autoshot_clip_timer_unknown`, `autoshot_clip_anchor_stale`, `autoshot_clip_action_lock_unknown`, `autoshot_clip_reset_policy_unknown`, `autoshot_clip_margin_applied`, `autoshot_clip_unsafe`, `autoshot_clip_wait_for_shot`, `autoshot_clip_auto_switch_invalidated`, `autoshot_clip_spell_family_unknown`.
10. Тесты: Auto Shot off/on, first shot after enable, shot just fired, shot imminent, Aimed/Multi/Steady cast/instant variants, spell reset/pause/no-reset, haste and weapon swap, latency/margin, movement, minimum range/dead zone, auto-switch melee/ranged, target changed, delayed/missing/out-of-order swing event, secret speed, unknown action lock, false-safe prevention, unknown->not safe, no protected casts.

**Тесты и диагностика**

в файле не указано

**Архитектурные и обратные ссылки:** SW-04, SW-01, SW-02, SP-14, EN-04, PE-05, EN-07.

---

### SW-04 — Следующий удар усиливается способностью — запас

ID: [SW-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L4790). Приоритет: P2. Lua: упомянут (точный статус в источнике).

**Вердикт / статус**

**Вердикт**

**ЧАСТИЧНО РЕАЛИЗОВАНО НА УРОВНЕ ОБЩИХ API — ДОРАБОТАТЬ (P2).** Kord уже разрешает `C_Spell.IsCurrentSpell` и `C_Spell.GetSpellPowerCost`, имеет player resources и range logic, но **не подтверждены** универсальный next-swing queue state, ресурсный резерв после стоимости удара и suppression повторной рекомендации.

**Архитектурные ссылки:** SW-01, SW-02, SW-03, SP-14, EN-04, EN-05, PE-02. Обратные ссылки внесены в эти требования в том же коммите.

**Изменения Lua:** отсутствуют. Только документация.

**Выбранный путь Kord**

**Выбранный путь Kord**

**Единый логический `NextSwingEmpowerObservation` поверх SW-01 `PlayerAutoAttackObservation`, SW-02 `PlayerSwingObservation`, общего `PlayerResourceObservation` и `AbilityEligibility`, с `NextSwingSpellCatalog` по семействам/рангам и `ResourceReservePolicy`.** Никакого второго swing scanner, class-specific queue observer или нового универсального resource provider. Для каждого изученного highest rank next-swing family проверять `C_Spell.IsCurrentSpell` через GameAPI secret-safe read; `true=QUEUED`, `false=NOT_QUEUED` **только при валидированной Forever семантике**, secret/nil `UNKNOWN`. Heroic Strike/Cleave взаимоисключающая queue family, но не объявлять Raptor Strike/Maul одинаковыми с warrior при непроверенной механике. Событие `PLAYER_SWING` может подтверждать расход очереди **лишь при подтверждённом совпадении spell/hand/target**, иначе сброс и повторная проверка IsCurrentSpell; событие само по себе не доказывает, что queued attack исполнился.

`ResourceReservePolicy` — декларативная **профильная** политика приоритетных действий (например, warrior Mortal Strike/Bloodthirst/Whirlwind, druid bear survival, hunter mana needs), с отдельными `resourceType`, `prioritySpellFamily`, `requiredCost`, `reserveHorizon` и `minSpare`. Нельзя зашивать пороги Sonah/ForeverRotation как универсальные. Если ресурс доступен: `spare = current - validatedQueuedCost - validatedPriorityReserve`; `reserveSatisfied` только при доказанных типе/стоимостях и актуальности. Если rage secret: допускается отдельный **проверенный capability-based** сигнал Sonah (доступность защитной способности как нижняя граница ресурса), но **не** числовое `spareRage=30` и **не** доказательство суммы двух расходов; без доказательства совокупного бюджета `reserveSatisfied=UNKNOWN`. Учитывать момент списания queued cost (queue vs impact) только после Forever validation, refunds/failed attack, queued spell replacement, изменяющиеся затраты/таланты/формы и изменения ресурса между постановкой и swing.

`NextSwingNeedPolicy` рекомендует только при `NOT_QUEUED`, доказанном запасе, нужном target/range, EN-04 CC safety, EN-05 AoE count для Cleave, применимой форме/оружии, достаточной фазе SW-02 (если требуется профилем), отсутствии более важной способности и итоговом `AbilityEligibility READY`. `UNKNOWN` не означает «нажать ещё раз»; не обходить финальный READY через `ignoreReady`. `Needs.nextSwingEmpower` лениво получает существующие observations и memo по revisions player/target/spellbook/resource/queue/swing, с event coalescing и bounded reads. Ни одного protected action.

**Требуемые изменения (полный текст)**

**Требуемые изменения**

1. Ввести `NextSwingEmpowerObservation` и `NextSwingSpellCatalog` по изученным рангам, с явным `QUEUED/NOT_QUEUED/UNKNOWN`; не дублировать SW-02.
2. Валидировать Forever `C_Spell.IsCurrentSpell` на Heroic Strike/Cleave/Maul/Raptor Strike, смену ранга/очереди и secret/nil; unknown никогда не означает not queued.
3. Переиспользовать общий player resource reader, `C_Spell.GetSpellPowerCost`, typed resource и highest rank; проверить списание при queue vs impact, refunds, talents/forms.
4. Ввести `ResourceReservePolicy` с приоритетными spell families, резервом и горизонтом; не использовать один универсальный порог rage/mana.
5. При скрытом combat resource: проверенный capability-based lower-bound только как ограниченный факт, без ложного числового запаса или утверждения, что хватает на два действия.
6. Реализовать `NextSwingNeedPolicy` с suppression уже queued, swing phase, target/range, EN-04 CC, EN-05 Cleave target count, form/weapon и AbilityEligibility.
7. EventBus queue invalidation при resource/spellbook/target/weapon/form/swing/cast/zone и проверенном `PLAYER_SWING`; не считать swing event гарантией исполнения queued spell.
8. RotationConditions `nextSwing.queued(spellFamily)`, `nextSwing.reserveSatisfied(spellFamily)`, `nextSwing.swingRemaining`, lazy `Needs.nextSwingEmpower`, per-evaluation memo.
9. DevTools-only диагностика: `next_swing_queue_unknown`, `next_swing_queue_already_active`, `next_swing_spell_rank_unknown`, `next_swing_cost_unknown`, `next_swing_resource_secret`, `next_swing_reserve_unknown`, `next_swing_reserve_insufficient`, `next_swing_range_unverified`, `next_swing_cc_unsafe`, `next_swing_aoe_count_unknown`, `next_swing_execution_unconfirmed`, `next_swing_duplicate_suppressed`.
10. Тесты: warrior HS/Cleave same queue, bear Maul, hunter Raptor Strike, low/high rage, hidden combat rage, resource type mismatch, reserved Mortal Strike/Bloodthirst, queued spell replacement, rank changes, talents/cost modifiers, cost at queue vs impact, missed/failed swing, weapon swap, target switch, out-of-range false-positive, CC breakable, Cleave one/two/unknown targets, pet spell not player queue, event out-of-order, queue secret, missing API, no duplicate recommendations/protected casts.

**Тесты и диагностика**

в файле не указано

**Архитектурные и обратные ссылки:** IT-06, IT-02, IT-01, SW-02, SW-01, SW-03, EN-04, EN-05, SP-14, PE-02.

---

