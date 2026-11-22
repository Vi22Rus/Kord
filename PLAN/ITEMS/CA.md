# Карточки CA

Источник: REQUIREMENTS.md, blob 9efdec1900398c978ea121818fb5950cb1620337.

### CA-01 — Игрок кастует / ведёт канал: заклинание, оставшееся время, можно ли прервать

ID: [CA-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L1769). Приоритет: P0.

**Вердикт**

**Вердикт**

**ЧАСТИЧНО РЕАЛИЗОВАНО — ДОРАБОТАТЬ (P0).** Факт каста/канала и базовая блокировка есть, но spellID, достоверный остаток и свойство interruptible отсутствуют в текущем контракте Kord.

**Выбранный путь**

в файле не указано

**Требуемые изменения (полный текст)**

**Требуемые изменения**

1. Расширить общую `GameState.castingSnapshot` с защищённым кортежем `UnitCastingInfo("player")`/`UnitChannelInfo("player")`: `active/kind/spellID/name/startTimeMs/endTimeMs/remainingSeconds/durationSeconds/notInterruptible/interruptible` и отдельными `status/reason/source` каждого поля.
2. Верифицировать порядок полей `UnitCastingInfo` vs `UnitChannelInfo` на Forever; не переносить без проверки retail индексы. `notInterruptible` для cast/channel находится в разных позициях. `nil` или secret → UNKNOWN.
3. Вычислять remaining только из подтверждённых endTime и `GetTime`; отрицательные значения нормализовать лишь после безопасных числовых проверок; различать отсутствие каста, скрытый каст и недоступный API.
4. Не трактовать `notInterruptible` как `canCancelOwnCast`. Если требуется именно добровольная отмена игроком, выделить самостоятельный факт `canCancelOwnCast` с UNKNOWN до подтверждения игровым контрактом. Никаких `SpellStopCasting`, `SpellStopChanneling` или защищённых действий.
5. Сверять spellID с SP-02 (ранг) и SP-11 (override), не подменяя фактический ID ожидаемым из профиля. При channel/empower корректно отличать канал от обычного каста.
6. Инвалидировать и обновлять при cast/channel событиях, включая delay/update/interruptibility где доступны; вычисляемое remaining должно обновляться по времени, а не только при старте/конце.
7. Тесты: обычный каст, канал, empower, прерывание/отмена, pushback/delay, нулевой/отрицательный остаток, разные индексы кортежа, secret time/ID/flag, отсутствующий API, быстрый переход cast→channel, смена ранга/override, подтверждённое отсутствие каста. Диагностика не должна раскрывать secret значения.

**Изменения кода:** не выполнялись; внесён аудит CA-01.

**Тесты и диагностика**

в файле не указано

**Архитектурные и обратные ссылки:** CA-04, CA-05, SP-02, SP-11.

---

### CA-02 — Очередь способности на следующий удар (Heroic Strike, Raptor Strike и т. д.)

ID: [CA-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L1818). Приоритет: P1.

**Вердикт**

**Вердикт**

**НЕ РЕАЛИЗОВАНО КАК ОТДЕЛЬНЫЙ КОНТРАКТ — ЕСТЬ ЧАСТИЧНЫЕ API-ПРИМИТИВЫ (P1).** В Kord есть `IsCurrentSpell` и melee-range observation, но нет доказательного queued-state, membership и защиты от повторной рекомендации.

**Выбранный путь**

в файле не указано

**Требуемые изменения (полный текст)**

**Требуемые изменения**

1. Добавить проверенные Forever `nextSwingSpellFamilies` с рангами и override alias (SP-02/SP-11), включая Heroic Strike/Cleave/Raptor Strike/Maul только для реально подтверждённых клиентских вариантов; без классовых движков.
2. Ленивая `NextSwingQueueObservation(spellID)`: отдельно проверять membership и `C_Spell.IsCurrentSpell(effectiveSpellID)`; если невозможно отличить queued от иных current состояний, возвращать `UNKNOWN` о queued, сохраняя исходный API-факт.
3. Не использовать `C_SwingTimer.IsTargetWithinSwingRange` для времени. Отдельно проверять наличие Forever `C_SwingTimer`/другого защищённого источника remaining до next swing; при отсутствии — `UNKNOWN`, без расчёта по несуществующим событиям.
4. В `AbilityEligibility` не рекомендовать повторно **подтверждённо queued** способность, сохраняя единственного арбитра READY. При UNKNOWN не заявлять «уже queued» и не выдавать ложную уверенность.
5. Инвалидация по обновлению current spell, autoattack, swing, target, form/stance, spellbook/override и доступным событиям Forever; не полагаться только на `UNIT_SPELLCAST_START`.
6. Диагностика: `not_next_swing_ability`, `queued_confirmed`, `queued_unknown`, `current_spell_unavailable`, `swing_time_unknown`; не раскрывать secret.
7. Тесты: Heroic Strike/Cleave/Raptor Strike/Maul всех подтверждённых рангов; нажата кнопка до удара; очередь погашена ударом/отменена; повторное нажатие; смена цели/стойки; override; обычный `IsCurrentSpell` не next-swing; secret API; отсутствие swing timer; переход в бой и выход.

**Изменения кода:** не выполнялись; внесён аудит CA-02.

**Тесты и диагностика**

в файле не указано

**Архитектурные и обратные ссылки:** SP-02, SP-11, CA-01.

---

### CA-03 — Последнее успешное, неудавшееся, прерванное заклинание игрока

ID: [CA-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L1869). Приоритет: P1.

**Вердикт**

**Вердикт**

**ЧАСТИЧНО РЕАЛИЗОВАНО — ДОРАБОТАТЬ (P1).** События доступны, но идентичность/исход последнего заклинания каждого типа не сохраняются в ротационном ядре.

**Выбранный путь**

в файле не указано

**Требуемые изменения (полный текст)**

**Требуемые изменения**

1. В общем `EventBus` добавить защищённую передачу только подтверждённых player event payload или отдельный типизированный consumer; существующие revision/invalidation не ломать. Проверять сигнатуру каждого события на Forever и фильтр `unit=="player"`.
2. В существующем `GameState` реализовать независимые `lastSucceeded`, `lastFailed`, `lastInterrupted`: `rawSpellID`, `baseSpellID` (только проверенная связь), `castGUID`, `observedAt`, `event`, `reason`, `status/source`.
3. Для channel events отдельно проверить семантику `CHANNEL_STOP` и успех канала; не объявлять завершение канала успешным SUCCEEDED без соответствующего подтверждения.
4. Не превращать отсутствующий/секретный ID в известный по старому состоянию. Для `FAILED` сохранять причину только если её действительно даёт безопасный API/event; `INTERRUPTED` не приписывать автоматически противнику.
5. Предоставить ленивые запросы `lastCast.succeeded`, `lastCast.failed`, `lastCast.interrupted` с `Needs`, независимым возрастом и статусом; **никогда не считать отсутствие истории доказательством, что игрок ничего не кастовал до загрузки аддона**.
6. Не смешивать очередь следующего удара CA-02, текущий cast CA-01, последнюю рекомендацию ротации и последнее фактическое событие.
7. Тесты: успешный каст, ошибка/промах, interrupt собственного каста, отмена, канал, отсутствие события, secret ID/GUID/reason, смена цели, одинаковый spellID при разных исходах, base/rank/override, повторная загрузка, logout/login, DevTools не раскрывает secret.

**Изменения кода:** не выполнялись; внесён аудит CA-03.

**Тесты и диагностика**

в файле не указано

**Архитектурные и обратные ссылки:** CA-01, SP-02, SP-11, CA-02.

---

### CA-04 — Каст цели: что кастует, прерываем ли, оставшееся время

ID: [CA-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L1918). Приоритет: P1.

**Вердикт**

**Вердикт**

**ЧАСТИЧНО РЕАЛИЗОВАНО — ДОРАБОТАТЬ (P1).** API разрешены и есть player cast presence, но нет полного target cast observation.

**Выбранный путь**

в файле не указано

**Требуемые изменения (полный текст)**

**Требуемые изменения**

1. Расширить общий reader из CA-01 для `unit="target"` с независимыми `active/kind/spellID/name/start/end/remaining/interruptible`; отдельно защищать каждое поле, не считать скрытый name отсутствием каста.
2. Сверять `UnitGUID("target")` до/после чтения, учитывать `targetGUID` в кэше и результате; смена цели инвалидирует запись без переноса старого каста.
3. Проверить реальные Forever индексы `UnitCastingInfo` vs `UnitChannelInfo`: cast `notInterruptible` slot8, spellID slot9; channel `notInterruptible` slot7, spellID slot8 — только после подтверждения на целевом клиенте.
4. Remaining считать из безопасного endTime и времени; учитывать pushback/delay/channel updates и таймерное обновление. Невалидное/secret время → UNKNOWN.
5. `interruptible` от игрового API — самостоятельный факт; `canPlayerInterruptNow` — отдельное вычисление через AbilityEligibility/range/cooldown/resource (SP-03, SP-06, SP-08, SP-14), без смешения.
6. Подписки на target change и unit cast/channel start/stop/update/interruptible события с учётом поддержки Forever; lazy Needs и EventBus revisions. Не считать `UNIT_SPELLCAST_STOP` доказательством успеха.
7. Диагностика `target_cast_hidden`, `target_cast_time_unknown`, `target_cast_interruptible_unknown`, `target_guid_changed`; тесты cast/channel, hidden ID/name/flag, смена цели, обновление таймера, target absent/dead, каст прерываемый, но player interrupt unavailable, и повторный interrupt после завершения.

**Изменения кода:** не выполнялись; внесён аудит CA-04.

**Тесты и диагностика**

в файле не указано

**Архитектурные и обратные ссылки:** TG-11, CA-01, SP-03, SP-06, SP-08, SP-14.

---

### CA-05 — Окно «когда можно двигаться без потери каста»

ID: [CA-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L1971). Приоритет: P2.

**Вердикт**

**Вердикт**

**НЕ РЕАЛИЗОВАНО — ТРЕБУЕТСЯ ИССЛЕДОВАНИЕ ВОЗМОЖНОСТИ ДОСТОВЕРНОГО НАБЛЮДЕНИЯ (P2).** Доступны только исходные примитивы движения и каста, не безопасное окно.

**Выбранный путь**

в файле не указано

**Требуемые изменения (полный текст)**

**Требуемые изменения**

1. Сначала завершить CA-01: безопасные `castStart/end/remaining`, различение cast/channel/empower, событие задержки/обновления, время на том же clock.
2. Исследовать на WoW Forever поведение окончания каста при начале движения, отдельно обычный каст, канал, instant, cast-while-moving и способности с проком; документировать, что реально доказуемо, а что лишь вероятностная эвристика.
3. При наличии измеряемой задержки использовать событийный подход ForeverAuras с защищённой проверкой timestamp, ограничением выборки и отсутствием гарантии. Не приравнивать `GetNetStats`, `SpellQueueWindow`, latency castbar и ping к моменту подтверждения сервером.
4. Раздельно возвращать `remaining`, `estimatedLatency`, `safeToMove`; если нельзя доказать безопасное окно, `safeToMove=UNKNOWN`, даже когда remaining меньше ping. Не рекомендовать начать движение по неподтверждённой оценке.
5. Не автоматизировать движение/отмену; read-only. Инвалидация при cast/channel start/stop/delayed/update, движении, смене формы/прока/ауры, secret time.
6. Диагностика `safe_window_unverified`, `latency_estimate_only`, `channel_tick_loss_unknown`, `cast_time_unknown`; тесты на разных задержках, pushback, конце каста, потерянных channel ticks, касте на ходу, мгновенных способностях и тайных значениях.

**Изменения кода:** не выполнялись; внесён аудит CA-05.


## 4. Ауры (баффы и дебаффы)

**Тесты и диагностика**

в файле не указано

**Архитектурные и обратные ссылки:** CA-01, CA-04.

---

