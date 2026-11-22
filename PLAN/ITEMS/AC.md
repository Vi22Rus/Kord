# Карточки AC

Источник: REQUIREMENTS.md, blob 9efdec1900398c978ea121818fb5950cb1620337.

### AC-01 — SPELL: заклинание или способность (первый обязательный тип действия)

ID: [AC-01](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L6006). Приоритет: в файле не указано. Lua: упомянут (точный статус в источнике).

**Вердикт / статус**

**Вердикт**

**БАЗОВЫЙ ТИП SPELL УЖЕ РЕАЛИЗОВАН; ПОЛНОЕ ПОКРЫТИЕ ТРЕБУЕТ ДОПОЛНИТЕЛЬНОЙ ПРОВЕРКИ.** AC-01 не требует нового spell engine, а фиксирует контракт и проверку полноты существующего.

**Архитектурные ссылки:** SP-01–SP-14, CC-01–CC-05, `RotationEngine`, `RotationConditions`, `AbilityEligibility`. Последующие типы действий должны использовать общий recommendation contract и не подменять SPELL.

**Изменения Lua:** отсутствуют. Только документация.

**Выбранный путь Kord**

**Выбранный путь Kord**

**Сохранить существующий маршрут `RotationEngine → RotationConditions → AbilityEligibility → recommendation`** как единственный маршрут `SPELL`. Ввести/зафиксировать общий `ActionRecommendation` contract с `actionType="SPELL"`, `spellID`, `targetContext`, `status`, `reason`, `priority`, `channel`, `source`, `revision`, `name/texture` (только безопасно полученные). Обратная совместимость с текущими `spellID`-записями обязательна; не менять UI-поля без адаптера.

Изученность/ранг, ресурсы, cooldown/charges/GCD, дальность, target, формы, позицию, движение, cast/channel, собственный CC, LoC и school lockout проверять через существующие общие SP/CC providers; `AbilityEligibility` — единственный итоговый gate. `UNKNOWN` не превращать в READY; поддерживать lazy conditions и memo на оценку. Для breaker и interrupt действия остаются `SPELL`, а их ситуационная пригодность приходит из CC-02/CC-04, без нового типа действия. Item use относится к отдельному типу, даже если предмет запускает spell effect.

**Требуемые изменения (полный текст)**

**Требуемые изменения**

1. Зафиксировать `SPELL` как обязательный `ActionRecommendation.actionType` и сохранить совместимость с действующим `rule.type="SPELL"` и текущим выводом.
2. Не переписывать работающий spell recommendation pipeline; проверить единый путь `RotationEngine/RotationConditions/AbilityEligibility` для всех классовых профилей.
3. Проверить обязательные eligibility: learned/max rank, resource, cooldown/charges/GCD, range, target, form, cast/channel, movement, CC, school lockout и применимые Forever ограничения.
4. Добавить явные typed `READY/BLOCKED/UNKNOWN` причины и DevTools трассировку для SPELL, не расширяя public recommendation секретными данными.
5. Обеспечить правильный канал и визуализацию обычного, defensive, aura и situational SPELL без пропажи следующего допустимого действия.
6. Тесты: known/unlearned, max rank, cast/channel, instant, target/no target, melee/ranged, cooldown/charges/GCD, ресурс, moving, own stun/silence, interrupt, defensive, pet spell, form, смена спека, nil/secret, правильный icon/keybind, отсутствие ложного READY и protected cast.

**Тесты и диагностика**

в файле не указано

**Архитектурные и обратные ссылки:** AC-07, AC-06, AC-05, AC-04, AC-03, PE-04, PE-01, AC-02, IT-01, IT-04, CC-02, CC-04, SP-01, SP-14, CC-01, CC-05.

---

### AC-02 — ITEM: предмет, зелье, камень (после IT-01–IT-04)

ID: [AC-02](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L6082). Приоритет: в файле не указано. Lua: упомянут (точный статус в источнике).

**Вердикт / статус**

**Вердикт**

**НЕ РЕАЛИЗОВАНО КАК САМОСТОЯТЕЛЬНЫЙ ТИП РЕКОМЕНДАЦИИ — ДОБАВИТЬ ПОСЛЕ IT-01–IT-04.** Существующий SPELL pipeline является основой; предметный typed dispatch и item-specific gate ещё необходимо внедрить.

**Архитектурные ссылки:** AC-01, IT-01–IT-14, `RotationEngine`, `RotationConditions`, `AbilityEligibility`. Обратные ссылки на AC-02 внесены в IT-01–IT-04 и AC-01 в этом коммите.

**Изменения Lua:** отсутствуют. Только документация.

**Выбранный путь Kord**

**Выбранный путь Kord**

**Расширить существующий `RotationEngine → RotationConditions → AbilityEligibility → recommendation`** до typed action dispatch, сохраняя действующую SPELL ветку AC-01 без регрессий. `ActionRecommendation` содержит `actionType`, `actionID`, `itemID` для ITEM и `spellID` для SPELL, `inventorySlot` для экипировки, status/reason/priority/channel/source/revision. Не создавать второй item rotation engine. Слой условий может использовать единый интерфейс, но `ITEM` проверяется **item-specific** eligibility и возвращает окончательный READY через общий `AbilityEligibility`, без вызова spell-known для itemID.

**Обязательный порядок зависимости:** IT-01 `InventoryObservation/ItemFamilyCatalog` → IT-02 item/shared cooldown → IT-03 item usability/level/target/combat/zone → IT-04 best eligible item in family → AC-02 typed recommendation. IT-05–IT-14 добавляют специальные политики: камни, мана/HP, бинты, еда, покрытия оружия, материалы, on-use экипировка, emergency и ручной выбор. Использовать существующие каталоги и сканеры, а не создавать отдельные.

Если ITEM находится в сумке — хранить itemID и подтверждённый bag count/доступность; если on-use в слоте — slot identity и revision оборудования. Иконка/название/кнопка могут иметь разные способы привязки: для ITEM UI не должен ошибочно искать spell keybind; при отсутствии доступного бинда отображать предмет без выдуманного хоткея. Приоритеты SPELL и ITEM сравниваются общим арбитром; неизвестный предмет не блокирует навсегда следующие правила. Защищённые игровые действия не выполняются.

**Требуемые изменения (полный текст)**

**Требуемые изменения**

1. После IT-01–IT-04 добавить `actionType="ITEM"` и typed item dispatch в существующий RotationEngine, не изменяя семантику `SPELL`.
2. Зафиксировать единый `ActionRecommendation` контракт и адаптер UI для itemID/slot, названия, иконки, причины, приоритета, канала и keybind без подмены spellID.
3. Реиспользовать IT-01 inventory/catalog, IT-02 cooldown, IT-03 eligibility, IT-04 family selection; итоговый READY через общий `AbilityEligibility`.
4. Для on-use экипировки проверять слот, текущий itemID, shared cooldown и equipment revision; для расходников — count/level/zone/combat/target restrictions.
5. Применять пороги/настройки IT-05–IT-14, включая MANUAL/AUTO/OFF и экономию расходников, без дублирования policy.
6. EventBus bag/equipment/item cooldown/config revisions, lazy Needs и memo на оценку; DevTools reasons `item_missing`, `item_unknown`, `item_on_cooldown`, `item_unusable`, `item_below_threshold`, `item_manual_unavailable`, `item_ready`.
7. Тесты: SPELL-only regression, item in bag/equipment, potion/healthstone/soulstone, count=0/1, shared cooldown, level/zone/combat/target, slot changed, auto/manual/off, missing/secret item data, item icon/name/bind, конкуренция SPELL/ITEM, no false READY, no protected use.

**Тесты и диагностика**

в файле не указано

**Архитектурные и обратные ссылки:** NO-01, AC-01, AC-07, AC-06, AC-04, AC-03, PE-04, PE-01, IT-01, IT-04, IT-02, IT-03, IT-05, IT-14.

---

### AC-03 — PET_COMMAND: команда питомцу (после PE-04)

ID: [AC-03](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L6156). Приоритет: в файле не указано. Lua: упомянут (точный статус в источнике).

**Вердикт / статус**

**Вердикт**

**НЕ РЕАЛИЗОВАНО КАК САМОСТОЯТЕЛЬНЫЙ ТИП РЕКОМЕНДАЦИИ — ДОБАВИТЬ ПОСЛЕ PE-04.** Частичные pet observations уже есть, но typed command dispatch, command-state eligibility и вывод PET_COMMAND отсутствуют.

**Архитектурные ссылки:** PE-01–PE-04, AC-01, AC-02, EN-04, `RotationEngine`, `RotationConditions`, `AbilityEligibility`. Обратные ссылки внесены в PE-04, AC-01 и AC-02.

**Изменения Lua:** отсутствуют. Только документация.

**Ретроактивное уточнение CL-03:** CL-03: PET_COMMAND охотника должен использовать общий PetCommandProvider и отдельные команды attack/follow/stay/passive, с UNKNOWN/STOP и без автоматического нажатия.

**Выбранный путь Kord**

**Выбранный путь Kord**

**После PE-04** расширить общий `ActionRecommendation` typed dispatch до `PET_COMMAND`, сохраняя SPELL (AC-01) и ITEM (AC-02). Команды формировать в том же `RotationEngine → RotationConditions → AbilityEligibility → recommendation`, но с отдельной проверкой `PetCommandEligibility` внутри общего итогового gate; не запускать отдельный pet engine. `PET_COMMAND` не требует изученности spell игрока и не может проходить через spell cooldown только потому, что pet action bar содержит spellID.

Существующие `GameState.pet.exists/targetExists/attackingTarget` переиспользовать как основу PE-01–PE-04. Добавить только отсутствующие наблюдения `petGUID`, `petControllable`, `petStance`, `petCommandState`, `petActionSlots` и фактическую доступность команды через capability-probed Forever APIs. `ATTACK`: есть управляемый питомец, подходящая подтверждённая враждебная цель, не атакует её уже, нет запрета на ломаемый CC; `FOLLOW`: нужно отозвать питомца и приказ не дублирует уже установленный режим; `STAY/stance`: применять только при доказанной необходимости/изменении. Если pet GUID/command state/target relation неизвестны — `UNKNOWN`, не READY. При смерти/отсутствии/смене питомца сбрасывать command context.

Профиль может указывать команду символическим `commandKey`, который резолвится в verified command/slot на текущем клиенте; не хардкодить позиции панели и не выдавать `spellID` команды за player SPELL. Для интерфейса добавить иконку/название/подсказку команды, корректный тип бинда, fallback при неизвестной клавише, отдельный reason. Согласовать с PE-04 и EN-04; не давать команду атаки на цель под ломаемым контролем, если отсутствует подтверждённая безопасная политика.

EventBus: `UNIT_PET`, `PET_BAR_UPDATE`, `PET_BAR_UPDATE_USABLE`, `PET_BAR_UPDATE_COOLDOWN`, `PET_UI_UPDATE`, `UNIT_TARGET`, смена цели/питомца/спека и config — **только события, подтверждённые на Forever**. Lazy `Needs.petCommands`, per-evaluation memo. DevTools: `pet_absent`, `pet_dead`, `pet_not_controllable`, `pet_command_unknown`, `pet_already_attacking`, `pet_target_invalid`, `pet_target_cc_protected`, `pet_action_slot_unknown`, `pet_command_ready`.

**Требуемые изменения (полный текст)**

**Требуемые изменения**

1. После PE-04 добавить `PET_COMMAND` в общий typed `ActionRecommendation` и dispatch, без второго движка ротации.
2. Реиспользовать `GameState.pet` и PE-01–PE-04; добавить только отсутствующие pet command state/stance/slot/controllability readers с capability/secret-safe Forever проверкой.
3. Реализовать `PetCommandEligibility` в общем итоговом `AbilityEligibility`, отдельно от spell/item eligibility.
4. Добавить `ATTACK/FOLLOW/STAY/stance` по реально поддерживаемым командам, с target GUID, pet GUID, защитой EN-04 от атаки ломаемого CC и отсутствием повторных бессмысленных команд.
5. Поддержать `commandKey` → verified action slot/commandID, UI иконку, тип бинда и диагностику, не подменяя команду spellID.
6. EventBus pet/target/actionbar revisions, lazy `Needs.petCommands`, memo и DevTools reasons; только подтверждённые Forever events.
7. Тесты: hunter/warlock pet, no pet/dead pet/new pet, attack same/new target, target friendly/dead/CC, follow recall, stance changes, command unavailable/unknown, pet action slot changed, pet spell vs pet command, nil/secret, combat/OOC, SPELL/ITEM regression, no false READY/protected actions.

**Тесты и диагностика**

в файле не указано

**Архитектурные и обратные ссылки:** NO-01, CL-08, PE-04, AC-01, AC-07, AC-06, AC-05, AC-04, EN-04, AC-02, PE-01, CL-03.

---

### AC-04 — TARGET: смена цели (рекомендация, не действие)

ID: [AC-04](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L6235). Приоритет: P2. Lua: упомянут (точный статус в источнике).

**Вердикт / статус**

**Вердикт**

**НЕ РЕАЛИЗОВАНО КАК ТИП ИНФОРМАЦИОННОЙ РЕКОМЕНДАЦИИ — ДОБАВИТЬ (P2).** Требуется только подсказка пользователю, а не управление его целью.

**Архитектурные ссылки:** AC-01–AC-03, EN-01–EN-06, CC-04, `RotationEngine`, `RotationConditions`, `AbilityEligibility`. Обратные ссылки внесены в AC-01–AC-03, EN-03 и EN-04.

**Изменения Lua:** отсутствуют. Только документация.

**Выбранный путь Kord**

**Выбранный путь Kord**

Расширить **общий `ActionRecommendation`** (AC-01–AC-03) типом `TARGET`, с отдельным `TargetSuggestionPolicy` и `TargetSuggestionEligibility` внутри существующего `RotationEngine/RotationConditions/AbilityEligibility` маршрута. Не создавать второй target engine и не вызывать protected actions. Источник кандидатов — общие EN-01–EN-06 enemy observations с дедупликацией EN-03, фильтрами враждебности/живости/доступности, защитой ломаемого CC EN-04 и приоритетом конкретной задачи. Если EN-06 не предоставляет надёжной идентичности кандидата, возвращать обобщённую подсказку или UNKNOWN; не подменять её последним GUID из предыдущего боя.

Разделять `targetSuggestion` и обычный `spellRecommendation`: TARGET может отображаться в отдельном информационном канале, а SPELL/ITEM/PET_COMMAND продолжают оцениваться по своим правилам. Если политика требует приоритета TARGET, арбитраж должен быть явным, не заставлять основной фрейм зависать на `UNKNOWN` или пустой иконке. После ручной смены цели и обновления `PLAYER_TARGET_CHANGED` рекомендация немедленно пересчитывается и исчезает, если причина устранена. Не использовать названия/иконки из secret значения; при отсутствии читаемого unit/nameplate — нейтральный текст «смените цель», не выдумывать точное имя/дистанцию.

Учитывать ручной контроль пользователя: `enableTargetSuggestions`, `allowInCombat`, `minimumPriority`, `protectCC`, `suggestionCooldown`/anti-spam, `manualOnly=true`. EventBus target/nameplate/combat/health/CC revisions, lazy `Needs.targetSuggestion`, memo и bounded refresh. DevTools reasons: `target_dead`, `target_invalid`, `target_cc_protected`, `higher_priority_target`, `interrupt_target_needed`, `candidate_unknown`, `identity_secret`, `target_already_correct`, `suggestion_suppressed`.

**Требуемые изменения (полный текст)**

**Требуемые изменения**

1. Добавить typed `TARGET` в общий recommendation contract с `requiresManualAction=true`; не выдавать TARGET как SPELL, ITEM или исполняемую команду.
2. Реализовать `TargetSuggestionPolicy/Eligibility` поверх EN-01–EN-06, без отдельного сканирования nameplates/GUID и без автоматической смены цели.
3. Проверять существование, враждебность, живость, CC-защиту, приоритет и подтверждённую идентичность предлагаемого кандидата; secret/nil → UNKNOWN.
4. Добавить информационный UI канал и текст/иконку смены цели, не блокирующие обычные боевые рекомендации без явной настройки.
5. Пересчитывать при смене цели, смерти/исчезновении врага, изменении контроля/приоритетов и событиях EN; убрать устаревшие предложения.
6. Добавить настройки enable/priority/anti-spam и DevTools причины с source/revision.
7. Тесты: нет цели, цель мертва, target already correct, опасный каст у другой цели, несколько врагов, CC на соседней цели, неизвестный GUID/nameplate, secret UnitIsUnit, смена цели вручную, combat/OOC, pet target не равен player target, SPELL/ITEM/PET_COMMAND не подавлены, отсутствие protected actions и taint.

**Тесты и диагностика**

в файле не указано

**Архитектурные и обратные ссылки:** NO-01, AC-01, AC-07, AC-06, AC-05, CC-04, EN-06, EN-04, EN-01, AC-03, EN-03.

---

### AC-05 — STANCE_OR_FORM: смена стойки, ауры, облика

ID: [AC-05](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L6305). Приоритет: P1. Lua: упомянут (точный статус в источнике).

**Вердикт / статус**

**Вердикт**

**НЕ РЕАЛИЗОВАНО КАК САМОСТОЯТЕЛЬНЫЙ ТИП РЕКОМЕНДАЦИИ — ДОБАВИТЬ (P1).** Существующие spell и aura механизмы переиспользовать; отдельная typed form/stance observation и выбор действительно нужного переключения ещё требуются.

**Архитектурные ссылки:** AC-01–AC-04, SP-01–SP-14, CC-01–CC-03, PE-04, `RotationEngine`, `GameState`, `AbilityEligibility`. Обратные ссылки внесены в AC-01, AC-03 и AC-04.

**Изменения Lua:** отсутствуют. Только документация.

**Ретроактивное уточнение CL-01:** CL-01: стойки воина должны реализовываться через общий STANCE_OR_FORM контракт, с проверкой смены стойки и сохранения ярости; не отдельным warrior-only переключателем.

**Ретроактивное уточнение CL-02:** CL-02: паладинские ауры и печати требуют отдельной семантики переключения/поддержания; STANCE_OR_FORM не является автоматическим эквивалентом seal/aura.

**Ретроактивное уточнение CL-03:** CL-03: смена Aspect через общий STANCE_OR_FORM/AuraMode contract с отдельными Hunter аспектами и channel policy; не приравнивать aspect к warrior stance.

**Ретроактивное уточнение CL-05:** CL-05: Shadowform — STANCE_OR_FORM с проверкой допустимости исцеления и иных заклинаний; нельзя считать form toggle безусловно готовым.

**Выбранный путь Kord**

**Выбранный путь Kord**

Добавить **`FormStanceObservation`** в существующий GameState, используя capability-probed `GetNumShapeshiftForms/GetShapeshiftFormInfo/GetShapeshiftFormID` и доступные `UnitAura` для переключаемых аур. Нормализовать `activeFormSpellID`, `formSlot`, `activeExclusiveAuraSpellID`, `knownForms`, `status/reason/source/revision`; `nil`/secret/отсутствующий API не трактовать как «обычная форма». Проверять различия интерфейса Forever по классу/талантам/спеку и уровню.

В `ActionRecommendation` AC-01–AC-04 добавить `STANCE_OR_FORM` как **семантический тип**, использующий тот же `RotationEngine → RotationConditions → AbilityEligibility`. `FormStanceSelection` выбирает требуемое состояние из политики профиля, сравнивает с фактическим, проверяет изученность, ресурс/кулдаун/GCD, доступность смены в текущем контроле, касте, бою, ограничения формы и итоговый spell eligibility. `STANCE_OR_FORM` не обходит spell gate. Для аур, уже реализованных как SPELL, обеспечить адаптер, не создавать дубликаты одновременно в SPELL и STANCE_OR_FORM.

Смена формы может быть **предусловием** последующего SPELL, но не должна провоцировать циклическое переключение туда-обратно между соседними тиками. Ввести приоритет/стабилизацию, учёт отмены формы, временной блокировки переключения, hysteresis и смены цели/ситуации. Настройки `enableFormRecommendations`, `allowOutOfCombat`, `allowInCombat`, `minimumSwitchInterval`, `auraPlacement` должны сохранять действующие правила defensive/maintenance. EventBus: `UPDATE_SHAPESHIFT_FORM`, `UPDATE_SHAPESHIFT_FORMS` при подтверждении на Forever, `UNIT_AURA`, `SPELLS_CHANGED`, talent/spec, cooldown, combat, target, config. Lazy `Needs.formStance`, memo; DevTools reasons `form_already_active`, `form_unknown`, `form_unlearned`, `form_switch_blocked`, `aura_already_active`, `form_switch_ready`, `form_oscillation_suppressed`.

**Требуемые изменения (полный текст)**

**Требуемые изменения**

1. Добавить typed `STANCE_OR_FORM` в общий action contract без второго spell engine; сохранить `SPELL`, `ITEM`, `PET_COMMAND`, `TARGET`.
2. Добавить в GameAPI capability-probed Forever form APIs и `FormStanceObservation` в GameState, различая form slot, spellID, класс и эксклюзивную ауру.
3. Реализовать `FormStanceSelection` с проверкой необходимости, learned/max rank, ресурса, cooldown/GCD, текущего контроля, боя и итогового `AbilityEligibility`.
4. Исключить повтор активной формы, дублирование SPELL-аур и колебания между формами; корректно обрабатывать форму «нет», переходы и потерю состояния.
5. Сохранить пользовательские настройки показа аур/аспектов и разделение main/defensive каналов, включая выключенную настройку показа в бою.
6. Добавить подтверждённые Forever EventBus revisions, lazy Needs, DevTools reasons и диагностику источника UNKNOWN.
7. Тесты: warrior Battle/Defensive/Berserker, druid Bear/Cat/Caster, paladin exclusive aura, hunter aspect при применимости, уже активная форма, неизвестный formID, unlearned spell, GCD/resource/cooldown, combat/OOC, каст/контроль, смена спека, secret/nil, смена цели, предотвращение циклов, сохранение SPELL-рекомендаций, отсутствие protected actions.

**Тесты и диагностика**

в файле не указано

**Архитектурные и обратные ссылки:** NO-01, CL-09, AC-01, AC-07, AC-06, AC-04, SP-01, SP-14, CC-01, CC-03, PE-04, AC-03, CL-01, CL-02, CL-03, CL-05.

---

### AC-06 — WAIT: ничего не нажимать, ждать (не клиппить автострельбу, копить ресурс)

ID: [AC-06](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L6382). Приоритет: P1. Lua: упомянут (точный статус в источнике).

**Вердикт / статус**

**Вердикт**

**НЕ РЕАЛИЗОВАНО КАК САМОСТОЯТЕЛЬНЫЙ ТИП РЕКОМЕНДАЦИИ — ДОБАВИТЬ (P1).** Частичные наблюдения ресурса и Auto Shot уже есть, но WAIT action, swing-safe policy и общий арбитраж отсутствуют.

**Архитектурные ссылки:** AC-01–AC-05, CC-04, SP-01–SP-14, `GameState`, `EventBus`, `AbilityEligibility`. Обратные ссылки внесены в AC-01–AC-05.

**Изменения Lua:** отсутствуют. Только документация.

**Ретроактивное уточнение CL-01:** CL-01: очередь следующего удара Heroic Strike/Cleave не тождественна WAIT или swing-таймеру; отсутствие подтверждённого queue state приводит к UNKNOWN/STOP для зависящего правила.

**Ретроактивное уточнение CL-03:** CL-03: WAIT при клиппинге Auto Shot разрешён только при подтверждённом ranged swing timing; UNKNOWN swing не превращается в WAIT или ложный READY.

**Выбранный путь Kord**

**Выбранный путь Kord**

Ввести **`WaitDecisionPolicy`** как один typed action selector в общем `RotationEngine → RotationConditions → AbilityEligibility → recommendation`, без второго ротационного движка. `WAIT` — самостоятельный READY-кандидат с доказанной причиной и условием выхода, конкурирующий с SPELL/ITEM/PET_COMMAND/STANCE_OR_FORM через общий арбитр; TARGET остаётся информационной рекомендацией. Обычный `UNKNOWN` по обязательному наблюдению не превращается в WAIT и не должен маскировать диагностическую ошибку. `WAIT` не должен навсегда блокировать последующие правила; нужен явный приоритет и конечное/событийное условие пересмотра.

**Автострельба:** переиспользовать `GameState.ReadAutoShot` для факта активности, добавить отдельный capability-probed `SwingTimingObservation` на подтверждённом Forever `PLAYER_SWING`/swingDuration/swingType или доступном `C_SwingTimer`. Для ranged измерять ближайший выстрел и окно, в котором конкретное заклинание рискует его отложить, учитывая cast time, GCD, задержку, движение и range только по подтверждённым данным. **Не считать всякий instant spell клиппингом** и не утверждать безопасное окно по таймеру, пока не было надёжного swing observation. Если swing timing неизвестен — `UNKNOWN` для swing-aware WAIT, а не выдуманный WAIT/READY. После первого выстрела, остановки Auto Shot, смены оружия, цели, дистанции или боя состояние инвалидируется. Отдельно учитывать melee swing и wand, не смешивая типы.

**Накопление ресурса:** использовать `GameState.resources`, стоимость и известность приоритетного заклинания из общего spell eligibility, скорость регенерации/тик ресурса только если она наблюдаема; `RESOURCE_POOL` разрешён при доказанной стратегической выгоде и явном target threshold, а не просто из-за `not_enough_resource`. Не отказываться от доступной безопасной способности без подтверждённого приоритета. Для combo points учитывать конкретную цель, чтобы не копить очки после смены/смерти цели; rage/energy/mana различать. В случае `CAST_OR_CHANNEL` не клиппить текущий канал без политики разрешённого прерывания, но не скрывать urgent defensive/interrupt.

Приоритеты: `emergency defense/urgent interrupt > обязательная ситуация > подтверждённый WAIT > обычный filler` как настраиваемая политика с явными исключениями; WAIT может иметь отдельный нейтральный UI (пауза, причина, при наличии достоверных данных таймер), не отображаться как вымышленный spell icon и не стирать defensive канал. События: Forever `PLAYER_SWING` только после capability/event verification, `START/STOP_AUTOREPEAT_SPELL`, resource, cast/channel, cooldown, target, weapon, combat, config; ленивый `Needs.waitDecision`, memo на оценку и bounded heartbeat. DevTools: `wait_auto_shot_window`, `wait_resource_pool`, `wait_channel_preserve`, `wait_control_preserve`, `wait_timing_unknown`, `wait_not_beneficial`, `wait_urgent_override`, `wait_condition_expired`.

**Требуемые изменения (полный текст)**

**Требуемые изменения**

1. Добавить `WAIT` в общий `ActionRecommendation` с reason, untilCondition, optional remaining и строгим отличием от `UNKNOWN/BLOCKED/no_action`.
2. Реализовать `WaitDecisionPolicy` как ленивый typed selector в текущем движке; итоговый `READY` выдаёт общий eligibility/arbitration, не профильное условие.
3. Переиспользовать `GameState.ReadAutoShot` и ресурсы; добавить проверенный Forever `SwingTimingObservation` только при подтверждённых API/events, без выдуманных swing таймеров.
4. Для Auto Shot/wand/melee различать active auto-repeat, swing type, достоверное время, cast window и клиппинг; неизвестный таймер → UNKNOWN.
5. Для resource pooling проверять известное приоритетное действие, стоимость, текущий ресурс, условия восстановления и допустимость filler; не заменять отсутствие ресурса безусловным WAIT.
6. Добавить явный арбитраж WAIT против urgent interrupt/defensive, обычного SPELL и прочих типов, anti-stall, событие выхода и UI без фиктивного spellID.
7. EventBus revisions, lazy Needs, DevTools причины и tests: hunter auto shot active/inactive, до первого swing, первый выстрел, wand, melee, cast near shot, instant without clip, движение, range, unknown/secret swing, rogue energy pooling, rage/mana, combo target switch, noPower without benefit, channel, emergency interrupt override, wait expiry, no false READY, no protected actions.

**Тесты и диагностика**

в файле не указано

**Архитектурные и обратные ссылки:** AC-07, AC-01, AC-05, CC-04, SP-01, SP-14, CL-01, CL-03.

---

### AC-07 — STOP: остановка рекомендаций при неизвестном ключевом факте

ID: [AC-07](https://github.com/Vi22Rus/Kord/blob/main/REQUIREMENTS.md#L6453). Приоритет: P0. Lua: упомянут (точный статус в источнике).

**Вердикт / статус**

**Вердикт**

**БАЗОВЫЙ FAIL-CLOSED UNKNOWN УЖЕ ЕСТЬ; ЯВНЫЙ STOP-КОНТРАКТ И ОБЛАСТЬ ДЕЙСТВИЯ ТРЕБУЮТ ДОРАБОТКИ (P0).** Не заменять действующую защиту новым движком; усилить её и покрыть тестами.

**Архитектурные ссылки:** AC-01–AC-06, CC-01–CC-05, SP-01–SP-14, `RotationEngine`, `RotationConditions`, `AbilityEligibility`, `GameAPI`, `EventBus`. Обратные ссылки внесены в AC-01–AC-06.

**Изменения Lua:** отсутствуют. Только документация.


**Ретроактивное уточнение EN-A4:** UNKNOWN по умолчанию останавливает приоритетную цепочку. Продолжение возможно только для `condition_unknown` с проверенной записью `SkipExceptions[rule.id]`; одного `rule.onUnknown="skip"` недостаточно. Ошибки и UNKNOWN пригодности способности не пропускаются. Исторический аудит сохранён.


**Ретроактивное уточнение EN-A11:** EN-A11: исключение UNKNOWN требует доказанного теста и причины, не может отключать обязательные проверки пригодности/безопасности. Исторический аудит сохранён.

**Ретроактивное уточнение UI-06:** STOP/UNKNOWN объяснять исходным безопасным reason из AC-07 и приоритетом остановившего правила; UI-06 не заменяет UNKNOWN на BLOCKED или READY и не продолжает вычислять более низкие правила ради красивого объяснения.

**Ретроактивное уточнение QA-01:** остановки UNKNOWN→STOP документируются точными machine-readable reason в безопасном observation bridge; подробный список проверенных приоритетов — только DevTools QA-01 по явному Start, без повторного вычисления правил.

**Ретроактивное уточнение QA-04:** при `UNCONFIRMED/NOT_RUN/DIFFERENT` API, если критический факт не доказан безопасным альтернативным методом из v14, сохранять UNKNOWN→STOP. `DIFFERENT` требует отдельного исследования/согласования матрицы, а не скрытого runtime fallback.

**Ретроактивное уточнение QA-05:** если legacy продолжал выбор при неизвестном критическом факте, новое `UNKNOWN→STOP` фиксировать как `EXPECTED_DELTA`, а не восстанавливать опасный legacy fallback. UNKNOWN/secret в QA-05 нельзя преобразовывать в READY ради совпадения.

**Ретроактивное уточнение QA-06:** QA-06: при обнаружении запрещённого API или динамического обхода в профиле build gate FAIL; нельзя объявлять READY либо обойти UNKNOWN/STOP через прямой игровой вызов.

**Ретроактивное уточнение QA-07:** QA-07 задаёт обязательные `UNKNOWN→STOP` и fail-closed сценарии с отсутствующими/secret фактами для каждого профиля; `UNKNOWN` не допускается маскировать как WAIT или BLOCKED ради совпадения.

**Ретроактивное уточнение CL-04:** CL-04: UNKNOWN combo points, energy timing, stealth или interruptibility должны приводить к STOP для зависящего правила, а не ложному finisher/Kick.

**Ретроактивное уточнение CL-05:** CL-05: неизвестный Weakened Soul, тип диспела, mana reserve, статус wand или состояние группы → STOP для зависимого правила.

**Вердикт**

**БАЗОВОЕ ТРЕБОВАНИЕ УЖЕ РЕАЛИЗОВАНО (v1): РЕЕСТР ОТКЛОНЯЕТ НЕСОВПАДЕНИЕ `contractVersion`.** P0: сохранить гарантию при расширении типов действий, добавить точные причины отказа, тесты и безопасную миграцию. Игровое подтверждение отсутствует.

**Архитектурные ссылки:** `RotationProfiles.lua`, `docs/rotation/Profile_Contract.md`, `docs/rotation/Profile_Registry.md`, AC-01–AC-07. Обратные ссылки внесены в AC-01–AC-07.

**Изменения Lua:** отсутствуют. Только документация.


**Ретроактивное уточнение EN-A4:** UNKNOWN по умолчанию останавливает приоритетную цепочку. Продолжение возможно только для `condition_unknown` с проверенной записью `SkipExceptions[rule.id]`; одного `rule.onUnknown="skip"` недостаточно. Ошибки и UNKNOWN пригодности способности не пропускаются. Исторический аудит сохранён.


**Ретроактивное уточнение EN-A5:** схема `RotationProfiles.Config` — канонический источник типов, дефолтов и UI. Нормализация CFG должна быть единой для `RotationSettings` и `RotationEngine`; недействительное сохранённое значение возвращает default, недействительная схема отклоняется при регистрации. Исторический аудит сохранён.

**Ретроактивное уточнение EN-A6:** `profile.status` — обязательный статус допуска профиля; только `verified` доступен штатно, `experimental` — при явном `allowUnverifiedProfiles==true`, `draft/mock_tested` не допускаются. Статус не заменяет проверок `AbilityEligibility` и UNKNOWN→STOP; подтверждение привязано к версии и доказательствам тестов. Исторический аудит сохранён.

**Ретроактивное уточнение EN-A7:** EN-A7 фиксирует допустимые mode single/aoe/any у правил и отдельные пользовательские single/aoe/auto; не создавать новый профильный mode evaluator. Исторический аудит сохранён.

**Ретроактивное уточнение EN-A8:** EN-A8 уточняет, что levelMin/levelMax включительны, перекрытие диапазонов запрещено, а статус и версия профиля проверяются для конкретного диапазона. Исторический аудит сохранён.

**Ретроактивное уточнение QA-06:** QA-06: статический контроль профилей проверяет исходники и замыкания `when` до допуска через реестр; runtime validation EN-A1 остаётся обязательной и не заменяет статическую проверку.

**Ретроактивное уточнение QA-07:** QA-07 требует версионированный `scenarioID/profileID/profileVersion/contractVersion` для каждого профиля, включая draft/legacy с явным `NOT_RUN`; реестровая валидность не означает прохождение сценариев.

**Ретроактивное уточнение CL-01:** CL-01: класс-специфические данные и условия Warrior должны объявляться через версионированные Needs/Spells; профили не читают API напрямую.

**Ретроактивное уточнение CL-02:** CL-02: паладинские данные и действия объявляются через версионированный профильный контракт; никаких прямых Unit*/C_* API в профиле.

**Ретроактивное уточнение CL-03:** CL-03: Hunter Needs/Spells/Rules расширяются только версионированно; legacy BM.Next(s,cfg) не v1 profile и не читает WoW API напрямую в новой архитектуре.

**Ретроактивное уточнение CL-04:** CL-04: Rogue Needs и action policies расширяются версионированно; combo, energy tick, poison и stealth данные поставляют только общие providers.

**Ретроактивное уточнение CL-05:** CL-05: Priest Needs и target/action policies только через versioned Profile_Contract; profile не читает WoW API.

**Ретроактивное уточнение CL-06:** CL-06: Shaman Needs/Spells/Rules только через версионированный Profile_Contract, lazy providers, без прямых API в профилях.

**Ретроактивное уточнение CL-07:** CL-07: Mage Needs/Actions/Spells — только versioned Profile_Contract и общий Eligibility; unresolved spell aliases не входят в исполняемый каталог.

**Вердикт**

**БАЗОВАЯ СЕМАНТИКА УЖЕ РЕАЛИЗОВАНА В ИСХОДНИКАХ (P0):** правила упорядочены, первое подтверждённое READY побеждает, нижестоящие правила не вычисляются. Требуются формальные тесты, наблюдаемость и распространение гарантий на новые типы действий. Игровое подтверждение отсутствует.

**Архитектурные ссылки:** EN-A1, AC-01–AC-07, `RotationProfiles`, `RotationEngine`, `RotationConditions`, `AbilityEligibility`. Обратные ссылки внесены в EN-A1, AC-01, AC-06 и AC-07.

**Изменения Lua:** отсутствуют. Только документация.


**Ретроактивное уточнение EN-A4:** UNKNOWN по умолчанию останавливает приоритетную цепочку. Продолжение возможно только для `condition_unknown` с проверенной записью `SkipExceptions[rule.id]`; одного `rule.onUnknown="skip"` недостаточно. Ошибки и UNKNOWN пригодности способности не пропускаются. Исторический аудит сохранён.


**Ретроактивное уточнение EN-A5:** схема `RotationProfiles.Config` — канонический источник типов, дефолтов и UI. Нормализация CFG должна быть единой для `RotationSettings` и `RotationEngine`; недействительное сохранённое значение возвращает default, недействительная схема отклоняется при регистрации. Исторический аудит сохранён.

**Ретроактивное уточнение EN-A6:** `profile.status` — обязательный статус допуска профиля; только `verified` доступен штатно, `experimental` — при явном `allowUnverifiedProfiles==true`, `draft/mock_tested` не допускаются. Статус не заменяет проверок `AbilityEligibility` и UNKNOWN→STOP; подтверждение привязано к версии и доказательствам тестов. Исторический аудит сохранён.

**Ретроактивное уточнение EN-A7:** EN-A7: фильтрация режима, burst и категорий выполняется в общем последовательном RotationEngine до rule.when; сохранять порядок и lazy evaluation. Исторический аудит сохранён.

**Ретроактивное уточнение EN-A8:** EN-A8 требует выбирать профиль по достоверному уровню до обхода правил; отсутствие диапазона — UNKNOWN→STOP, не nearest-profile fallback. Исторический аудит сохранён.

**Ретроактивное уточнение EN-A9:** EN-A9 расширяет только контракт выдачи очереди: главный READY остаётся первым подтверждённым правилом, следующая рекомендация не вычисляется спекулятивно из неизменного снимка. Исторический аудит сохранён.

**Ретроактивное уточнение EN-A11:** EN-A11: приоритетный ленивый обход продолжается после UNKNOWN только для разрешённого condition_unknown skip; ошибка/invalid/eligibility UNKNOWN останавливают цепочку. Исторический аудит сохранён.

**Ретроактивное уточнение DA-01:** DA-01 устанавливает ревизии каналов EventBus как канонический источник инвалидации ленивых наблюдений; нельзя считать кэш актуальным после MarkDirty. Исторический аудит сохранён.

**Ретроактивное уточнение DA-02:** DA-02 закрепляет lazy evaluation и evaluation-scoped read/fact/eligibility caches; Needs — allowlist, не eager preload. Исторический аудит сохранён.

**Ретроактивное уточнение DA-03:** DA-03: rule.when получает только ограниченный фасад RotationConditions, не raw GameState/GameAPI; недекларированный факт возвращает UNKNOWN и не вызывает провайдер. Исторический аудит сохранён.

**Ретроактивное уточнение DA-04:** DA-04 вводит измерение полного Evaluate/EvaluateBoth и budget warning; превышение не разрешает пропуск UNKNOWN или обход Eligibility. Исторический аудит сохранён.

**Ретроактивное уточнение UI-01:** UI-01: UI получает только проверенный результат RotationEngine и не выполняет собственную оценку пригодности или прямые игровые сканы. Исторический аудит сохранён.

**Ретроактивное уточнение UI-02:** UI-02: только AbilityEligibility/RotationEngine выдаёт READY; UI glow и keybind не являются альтернативным решателем пригодности. Исторический аудит сохранён.

**Ретроактивное уточнение QA-02:** полнота журнала означает все **реально выполненные** проверки и причины; ленивое правило «первое подходящее побеждает» остаётся обязательным. DevTools `Audit()` не вправе выполнять пропущенные правила в живом бою ради полной таблицы; ставить `NOT_EVALUATED`.

**Ретроактивное уточнение QA-03:** обязательные Lua 5.1 mock-тесты first-match-wins, UNKNOWN→STOP, отсутствие вызовов последующих rules и неизменность результата при подключении DevTools. `AuditFull` не служит доказательством lazy runtime.

**Ретроактивное уточнение QA-05:** first-match-wins сравнивать не только по конечному spellID, но и по вызванным приоритетам, количеству чтений, skip/STOP и `NOT_EVALUATED`. Старый eager/unsafe traversal не является нормативным baseline; ожидаемые отличия фиксируются в QA-05.

**Ретроактивное уточнение QA-06:** QA-06: запрещены прямые WoW API и скрытые вызовы через глобальные алиасы внутри `rule.when`; все факты читаются только через разрешённые `S` и `Needs`, сохраняя lazy first-match-wins.

**Ретроактивное уточнение QA-07:** QA-07 проверяет выбор первого допустимого приоритета и невыполнение нижних правил через `evaluatedPriorities/NOT_EVALUATED` для каждого сценария.

**Вердикт**

**ЧАСТИЧНО РЕАЛИЗОВАНО, НАЙДЕН P0-ДЕФЕКТ:** `any` корректно ленив, `all` неверно останавливается на UNKNOWN до потенциального FALSE. Исправить текущий комбинатор, не создавать второй механизм. Lua-изменения и игровые тесты в рамках аудита не выполнялись.

**Архитектурные ссылки:** EN-A1, EN-A2, AC-07, `RotationConditions`, `RotationEngine`, `AbilityEligibility`. Обратные ссылки внесены в EN-A1, EN-A2 и AC-07.

**Изменения Lua:** отсутствуют. Только документация.

**Ретроактивное уточнение EN-A4:** UNKNOWN по умолчанию останавливает приоритетную цепочку. Продолжение возможно только для `condition_unknown` с проверенной записью `SkipExceptions[rule.id]`; одного `rule.onUnknown="skip"` недостаточно. Ошибки и UNKNOWN пригодности способности не пропускаются. Исторический аудит сохранён.

**Ретроактивное уточнение QA-02:** lazy `all/any` сохраняет short-circuit. В журнале QA-02 отражаются фактические checked child predicates и `NOT_EVALUATED` для непрочитанных; не запускать API-проверки заново ради подпричин.

**Ретроактивное уточнение QA-03:** Lua 5.1 mocks для lazy all/any проверяют точное число чтений и отсутствие вызова непройденных child predicates; NOT_EVALUATED не должен провоцировать чтение.

**Ретроактивное уточнение QA-05:** differential fixtures проверяют точные API read counts и lazy short-circuit `all/any` для нового движка. Изменение старого eager порядка на lazy — `EXPECTED_DELTA` только с утверждённым контрактом и отсутствием ложного READY.

**Ретроактивное уточнение QA-06:** QA-06: составные lazy predicates могут вызывать только разрешённые методы `S` и чистые локальные helper-функции; прямой `Unit*`/`C_*` и побочные эффекты в child closures запрещены.

**Ретроактивное уточнение QA-07:** QA-07 добавляет в сценарные ожидания lazy `all/any`, фактические `providerReadCounts` и отсутствие чтения недостижимых ветвей; проверка обязательна в общей QA-03 инфраструктуре.

**Вердикт**

**ЧАСТИЧНО РЕАЛИЗОВАНО (P0):** default STOP и реестр SkipExceptions уже существуют. Runtime-проверка пока зависит от `rule.onUnknown`, а неизменяемость и безопасность исключений не доказаны. Требуется усилить текущий общий контракт; игровые тесты не проводились.

**Архитектурные ссылки:** PR-PR-01, PR-07, EN-A1, EN-A2, EN-A3, AC-07, RotationProfiles, RotationEngine, RotationConditions, AbilityEligibility. Обратные ссылки на EN-A4 добавлены в EN-A1, EN-A2, EN-A3 и AC-07.

**Изменения Lua:** отсутствуют. Только документация.


**Ретроактивное уточнение EN-A6:** `profile.status` — обязательный статус допуска профиля; только `verified` доступен штатно, `experimental` — при явном `allowUnverifiedProfiles==true`, `draft/mock_tested` не допускаются. Статус не заменяет проверок `AbilityEligibility` и UNKNOWN→STOP; подтверждение привязано к версии и доказательствам тестов. Исторический аудит сохранён.

**Ретроактивное уточнение EN-A9:** EN-A9 не разрешает вычислять нижестоящие правила после UNKNOWN→STOP ради заполнения второго слота; skip допустим только из SkipExceptions. Исторический аудит сохранён.

**Ретроактивное уточнение EN-A11:** EN-A11 является канонической таблицей исключений skip: default STOP, runtime проверяет утверждённые profileID/ruleID/unknownReason/version/testID; нельзя доверять одному onUnknown=skip. Исторический аудит сохранён.

**Вердикт**

**ОСНОВА РЕАЛИЗОВАНА, НУЖНА КОНСОЛИДАЦИЯ И ПРОВЕРКА P0:** типизированная схема, дефолты, runtime validation и генерация UI по Config присутствуют. Не доказаны единый недублируемый нормализатор, неизменность схемы и исчерпывающие тесты. Не создавать новый модуль.

**Архитектурные ссылки:** EN-A1 (валидация/версия профиля), EN-A2 (runtime cfg для правил), EN-A4 (ошибка схемы не должна приводить к небезопасному skip), PR-04, RotationProfiles, RotationSettings, RotationEngine, UI/Pages/RotationAbilities. Ретроактивные уточнения EN-A1 и EN-A2 должны ссылаться на EN-A5 как канонический контракт CFG.

**Изменения Lua:** отсутствуют. Только документация.


**Ретроактивное уточнение EN-A7:** EN-A7: пользовательские настройки режима/burst/категорий должны использовать единый контракт валидации CFG и UI, без дублирующих конфигураций. Исторический аудит сохранён.

**Ретроактивное уточнение DA-07:** DA-07 уточняет: типизированные CFG defaults/validation применяются при загрузке и миграции SavedVariables; недопустимые значения сбрасываются только в пределах своего поля, без потери остальных настроек. Исторический аудит сохранён.

**Ретроактивное уточнение UI-03:** UI-03 устанавливает единый presentation/resolution contract для CFG: `RotationProfiles.Config` остаётся источником схемы, но все UI-контролы, подписи, подсказки и фактические значения обязаны строиться через общий `RotationSettings`-resolver с явной информацией об источнике, конфликте и ревизии; отдельные UI defaults и независимые валидаторы запрещены. См. UI-03.

**Ретроактивное уточнение UI-04:** сериализованные пресеты — только пользовательские значения, а не новая схема `Config`; при импорте каждое поле проверяется по текущему immutable `RotationProfiles.Config`, устаревшие/неизвестные ключи не исполняются, и дефолты/типы не переопределяются. См. UI-04.

**Вердикт**

**БАЗОВЫЕ СТАТУСЫ И RUNTIME-GATE РЕАЛИЗОВАНЫ, НУЖНО ДОКАЗАТЕЛЬНОЕ ПОДТВЕРЖДЕНИЕ (P0):** все четыре значения валидируются, штатный допуск ограничен verified, experimental требует разрешения. Не подтверждены привязка статуса к результатам испытаний, автоматический пересмотр после изменений и исчерпывающие игровые тесты.

**Архитектурные ссылки:** EN-A1, EN-A2, EN-A4, EN-A5, PR-04, AC-07, `RotationProfiles`, `RotationEngine`, `AbilityEligibility`. Ретроактивные уточнения EN-A1, EN-A2, EN-A4 ссылаются на EN-A6 как каноническую политику статусов.

**Изменения Lua:** отсутствуют. Только аудит и документация.


**Ретроактивное уточнение EN-A8:** EN-A8: обновление диапазонов, рангов или правил может аннулировать подтверждение verified и требует повторной проверки соответствующей версии. Исторический аудит сохранён.

**Ретроактивное уточнение EN-A9:** EN-A9 запрещает повышать предварительный прогноз до verified READY без независимой проверки в будущей игровой ситуации. Исторический аудит сохранён.

**Ретроактивное уточнение DA-07:** DA-07: статусы профилей и доказательства verified нельзя автоматически повышать при миграции; изменённые контракты требуют downgrade/revalidation. Исторический аудит сохранён.

**Вердикт**

**ЧАСТИЧНО РЕАЛИЗОВАНО (P1):** ручные single/aoe и группы присутствуют, но auto по умолчанию всегда возвращает UNKNOWN; полноценный burst-mode не подтверждён. Требуется расширение общего движка и доказательные тесты, без создания отдельного механизма.

**Архитектурные ссылки:** EN-01, EN-04, EN-05, EN-A1, EN-A2, EN-A5, AC-07, RotationSettings, RotationEngine, RotationProfiles, RotationAbilities, AbilityEligibility. Обратные уточнения добавлены в EN-01, EN-05, EN-A1, EN-A2, EN-A5.

**Изменения Lua:** отсутствуют. Только аудит и документация.

**Ретроактивное уточнение EN-A10:** EN-A10 потребляет эффективный single/aoe/auto режим EN-A7; мультидот не должен включаться из-за недостоверного числа целей. Исторический аудит сохранён.

**Ретроактивное уточнение UI-03:** вкладки режимов, burst, категорий и профильных CFG используют общий UI-03 resolver и явные namespace/owner. Одноимённые элементы в разных вкладках должны показывать один effective value, если это один ключ; независимые параметры нельзя объединять из-за похожего названия. См. UI-03.

**Ретроактивное уточнение UI-04:** режимы single/aoe/auto, категории и burst-параметры могут входить в именованный пресет настроек, но не обходят Eligibility и UNKNOWN; тип контента не подменяет неподтверждённый подсчёт врагов или выбор режима.

**Ретроактивное уточнение QA-03:** все профили и конфигурационные схемы, зарегистрированные по EN-A7, обязаны входить в единый Lua 5.1 profile contract/selection/config/eligibility test matrix; тест только Hunter BM не равен покрытию всех классов.

**Ретроактивное уточнение QA-04:** профиль не может считать API-возможность доказанной на основании `V14Registry` или mock PASS; зависимости профиля должны ссылаться на конкретные matrixID и актуальные QA-04 client verdict, при непроверенном критическом факте сохранять UNKNOWN→STOP.

**Ретроактивное уточнение QA-06:** QA-06: любое новое profile Needs/condition API должно проходить статический gate на отсутствие прямых глобальных WoW API; разрешённый provider реализуется в ядре и проверяется по QA-04, не через профиль.

**Вердикт**

**ЧАСТИЧНО РЕАЛИЗОВАНО (P0):** валидация диапазонов, включительные границы, запрет пересечений и fail-closed выбор профиля существуют. Полный сквозной выбор максимального изученного ранга, события инвалидации и игровые граничные тесты не подтверждены.

**Архитектурные ссылки:** EN-A1, EN-A2, EN-A4, EN-A6, SP-01, AbilityEligibility, RotationProfiles, RotationEngine, spellbook/identity providers. Ретроактивные уточнения добавлены в EN-A1, EN-A2, EN-A6, SP-01.

**Изменения Lua:** отсутствуют. Только аудит и документация.

**Ретроактивное уточнение DA-01:** DA-01 связывает LEVEL_UP, SPELLS_CHANGED и смену талантов с ревизиями identity/spellbook/talents; выбор уровня и ранга обязан переоцениваться после изменения. Исторический аудит сохранён.

**Ретроактивное уточнение DA-02:** DA-02: rank/spellbook/profile cache инвалидируется по identity/spellbook/talents revision; level-up сам по себе не доказывает новый ранг. Исторический аудит сохранён.

**Ретроактивное уточнение DA-07:** DA-07: миграция профилей с диапазонами уровней сохраняет включительные границы и отвергает конфликтующие/невалидные диапазоны. Исторический аудит сохранён.

**Ретроактивное уточнение DA-08:** DA-08: PLAYER_LEVEL_UP запускает перепроверку профиля по диапазону и изученных максимальных рангов, а не только snapshot invalidation. Исторический аудит сохранён.

**Вердикт**

**НЕ РЕАЛИЗОВАНО КАК ДВУХШАГОВАЯ ОЧЕРЕДЬ (P2):** текущий движок сознательно выдаёт один безопасный READY. Структура queue существует, но `queue[2]` не формируется. Рекомендуется сначала закрепить безопасный контракт необязательного прогноза, затем добавлять реализацию только при доказанной модели будущего состояния.

**Архитектурные ссылки:** EN-A2, EN-A4, EN-A6, EN-A7, AC-07, RotationEngine, AbilityEligibility, UI рекомендаций. Ретроактивные уточнения добавлены в EN-A2, EN-A4, EN-A6.

**Изменения Lua:** отсутствуют. Только аудит и документация.

**Ретроактивное уточнение EN-A10:** EN-A10: цель рекомендации должна быть достоверно привязана к конкретному кандидату; прогноз второго шага не должен автоматически переключать цель. Исторический аудит сохранён.

**Ретроактивное уточнение EN-A11:** EN-A11: заполнение второй рекомендации не является причиной разрешать skip; реестр исключений применяется одинаково к любым слотам. Исторический аудит сохранён.

**Ретроактивное уточнение DA-01:** DA-01: второй прогнозный слот инвалидируется при изменении любой ревизии его Needs; пакетное уведомление не разрешает устаревший прогноз. Исторический аудит сохранён.

**Ретроактивное уточнение DA-02:** DA-02: predicted next slot должен инвалидироваться при изменении любого канала зависимостей; кэш одной оценки не переживает следующий проход. Исторический аудит сохранён.

**Ретроактивное уточнение UI-01:** UI-01 реализует визуальный контракт текущего READY и отдельного PREDICTED next; очередь из двух элементов нельзя валидировать как два READY; неизвестный прогноз очищает второй слот. Исторический аудит сохранён.

**Вердикт**

**НЕ ПОДТВЕРЖДЕНА ПОЛНОЦЕННАЯ РЕАЛИЗАЦИЯ (P2):** текущий движок поддерживает правила/факты текущей цели, но не доказаны общая per-target DoT-модель, безопасный выбор нескольких противников и выдача проверенной рекомендации для другой цели. Реализацию строить на общих EN-01/EN-03/EN-04/EN-06, не создавать второй target engine.

**Архитектурные ссылки:** EN-01, EN-03, EN-04, EN-06, EN-A4, EN-A7, EN-A9, AbilityEligibility, RotationConditions, RotationEngine, aura/TTD providers. Ретроактивные уточнения добавлены в EN-03, EN-04, EN-06, EN-A7, EN-A9.

**Изменения Lua:** отсутствуют. Только аудит и документация.

**Ретроактивное уточнение DA-01:** DA-01 расширяет подписки и каналы для nameplate-unit/аур только после подтверждения безопасного источника; текущий unit-фильтр не покрывает произвольные nameplates. Исторический аудит сохранён.

**Ретроактивное уточнение DA-02:** DA-02: per-target aura/TTD cache привязан к достоверной идентичности цели, ревизиям target/auras/health и не переживает смену/исчезновение nameplate. Исторический аудит сохранён.

**Ретроактивное уточнение DA-03:** DA-03: мультидотные enemy/aura/TTD провайдеры доступны только при явных Needs и доказанной идентичности цели; никакого обхода через прямые API вызовы. Исторический аудит сохранён.

**Ретроактивное уточнение DA-05:** DA-05: список nameplates/мультидот не должен вводить постоянный полный скан всех целей; только ограниченное наблюдение по запросу и событиям. Исторический аудит сохранён.

**Ретроактивное уточнение DA-06:** DA-06: UNIT_AURA/nameplate bursts агрегируются с сохранением identity/scope, не допуская смешивания данных разных целей. Исторический аудит сохранён.

**Вердикт**

**ЧАСТИЧНО РЕАЛИЗОВАНО (P1):** базовый `SkipExceptions` существует и валидируется при регистрации, но runtime доверяет `onUnknown` и не проверяет конкретное утверждённое исключение и успешность теста. Требуется усиление единого реестра и доказательного допуска.

**Архитектурные ссылки:** EN-A2, EN-A4, EN-A6, EN-A9, AC-07, RotationProfiles, RotationEngine, AbilityEligibility. Ретроактивные уточнения добавлены в EN-A4, EN-A2, EN-A9, AC-07.

**Изменения Lua:** отсутствуют. Только аудит и документация.

**Выбранный путь Kord**

**Выбранный путь Kord**

**Сохранить один канонический evaluator** `RotationEngine → RotationConditions → AbilityEligibility` и добавить к уже существующему `UNKNOWN` явную **семантику `STOP`**, не второй action engine. Ленивая проверка правил по приоритету: `READY` → завершить выбор действия; `BLOCKED` (достоверное false) → перейти к следующему правилу; `UNKNOWN` по обязательной проверке → `STOP` и **не оценивать нижестоящие зависимые правила**. Если неизвестность касается только необязательного оформления (например, текст подсказки), она не должна автоматически останавливать всю ротацию; критичность факта задаётся типизированным контрактом условия, а не случайным `nil`.

`STOP` распространяется только по доказанным зависимостям и каналу: основной SPELL/ITEM/PET_COMMAND/STANCE_OR_FORM/WAIT arbitration останавливается при общем ключевом UNKNOWN, а независимая defensive ветка может продолжать оценку при своих достоверных фактах. Для TARGET информационный канал может отдельно показать «цель неизвестна» без подмены STOP на совет выбрать вымышленного врага. При UNKNOWN shared prerequisites (например, недоступный player identity или общий контекст) остановить все **зависимые** каналы, не выдавая ложный READY. Никакой оптимистичной подстановки `false/0/empty` для secret, отсутствующих провайдеров, просроченных snapshot или ошибок чтения.

Внутренний `EvaluationStop` хранит `blockingFact`, `ruleID`, `scope`, `reason/source/revision`, `recoverOn`; наружу сохранять совместимый `status="UNKNOWN"` и пустую очередь, чтобы не ломать UI/DevTools, дополняя отдельным `decision="STOP"` только там, где контракт расширен. При событии инвалидации/следующем безопасном обновлении повторно оценивать с нуля, без зависания на предыдущем STOP. Диагностика не должна читать secret в лог. Различать `stop_condition_unknown`, `stop_eligibility_unknown`, `stop_provider_missing`, `stop_secret_value`, `stop_stale_snapshot`, `stop_critical_context`, `stop_invalid_status`, `stop_dependency_unknown`.

**Выбранный путь Kord**

**Сохранить `RotationProfiles` единственным каноническим реестром.** Ввести явную константу `PROFILE_CONTRACT_VERSION=1` вместо рассеянных чисел и структурированный результат `ValidateProfileContract`, сохранив существующий жёсткий отказ. `Register` и `Replace` обязаны применять одну и ту же валидацию **до** изменения активной карты профилей; при несовпадении версия/причина фиксируются в DevTools, но предыдущий валидный профиль остаётся активен. `Get/Select/Evaluate` не должны обходить gate через прямую вставку или stale cache.

**Версионирование при AC-02–AC-07:** расширение допустимых типов/Needs/правил и их семантики делать через контролируемую миграцию. До реализации типов `ITEM/PET_COMMAND/TARGET/STANCE_OR_FORM/WAIT` не принимать такие правила под v1 как работающие. `STOP` — управляющий результат, а не исполняемый action, поэтому должен быть описан в контракте результата. Если расширение несовместимо с текущими v1 профилями, ввести **новую версию только после явного решения о совместимости**, обновить схемы, документы, примеры и профили атомарно; не объявлять заранее произвольную v2 реализованной. Для старых профилей либо подтверждённый совместимый адаптер с отдельным тестом, либо отказ `profile_contract_version_mismatch`; никаких silent upgrades.

Статическая проверка профиля: типы/границы полей, class/spec/level, уникальные id, supported rule types, корректные references `Spells`, валидные `Needs`, `Config`, `SkipExceptions`, отсутствие запрещённых runtime callbacks и запрещённых побочных эффектов. Runtime `UNKNOWN` и STOP AC-07 не подменять ошибкой версии: невалидный профиль **не запускается**, а не «ждёт восстановления наблюдения». Инвалидировать registry selection/cache только после успешной замены, сохранять диагностику последнего отказа без secret values. Подтвердить поведение в Lua 5.1 и на WoW Forever.

**Выбранный путь Kord**

**Оставить один `RotationEngine` и текущий последовательный `ipairs(profile.Rules)`** как канонический алгоритм. Реестр EN-A1 гарантирует плотный массив и допустимые правила; порядок является частью версии профиля, его нельзя молча пересортировывать по category, spellID, названию или ключу Lua-таблицы. Если у профиля есть разные каналы/режимы, разрешённые правила фильтруются в исходном порядке и не пересчитываются повторно; категории не создают скрытый второй приоритетный список. `READY` останавливает проход немедленно; `BLOCKED` идёт дальше; `UNKNOWN` критичного условия вызывает AC-07 STOP. Только проверенное `SkipExceptions` разрешает продолжение после `condition_unknown`, без bypass eligibility.

`Needs` трактуются как **разрешённые источники наблюдений**, а не предзагрузка всего состояния. Провайдер вызывается при достижении правила, результат кэшируется не дольше одной оценки либо по явно инвалидируемой EventBus revision. Условия профиля не вправе присваивать `READY`; окончательное решение — `AbilityEligibility`. Исключить повторные вызовы условий после первого READY, в том числе через диагностику, UI, preview, defensive и analytics; если требуется независимая оценка другого канала, она имеет отдельный явно обозначенный scope и snapshot, а не повторно вычисляет следующие правила первого канала.

Диагностика хранит только **фактически посещённые** правила: priority, ruleID, status, reason, source/revision, количество вызовов. Не создавать записи о «проверенных» правилах ниже первого READY/STOP. Для disabled/mode/category фильтров использовать достоверный BLOCKED без вызова `when`. Проверить `onUnknown="skip"` на семантику: только `condition_unknown`, никакие `condition_error` или `eligibility_unknown`. При неизвестном факте, от которого зависит несколько каналов, остановить только зависимые scope, согласно AC-07.

**Выбранный путь Kord**

**Исправить существующие `RotationConditions.methods:all/any`**, не создавать универсальный evaluator заново. Для `all` ввести `unknown=false`, при `nil` устанавливать флаг и продолжать; при `false` сразу возвращать false; после полного прохода возвращать `nil`, если unknown, иначе true. Для `any` сохранить текущую симметричную реализацию: `true` немедленно завершает, `nil` запоминается, при отсутствии true итог nil или false. Валидацию функций и `true/false/nil` оставить; исключения не глотать внутри комбинатора — внешний `pcall(rule.when)` превращает их в `condition_error`/STOP.

Ленивая передача: только функции/thunks; все наблюдения читаются **внутри** вызванного thunk. Сначала дешёвые подтверждённые фильтры, затем дорогие API/ауры/TTD/nameplates; однако порядок условий не должен менять логический результат, только число чтений. `Needs` остаются allowlist, memo на оценку и EventBus revision — единственные разрешённые кэши. Проверять, что после решающего false/true не вызываются следующие callbacks и не увеличиваются счётчики провайдеров. UNKNOWN по одному факту допускает дальнейшую проверку только для доказательства определяющего результата; если его нет, возвращает UNKNOWN и запускает AC-07 STOP.

Отдельно проверить использование `S:all/S:any` в профилях: запретить предварительные `S:fact` чтения в аргументах, ошибки/побочные эффекты в callbacks, неочевидные `and/or` Lua, которые сворачивают `nil` в false. Добавить DevTools `condition_combiner`, `evaluatedOperands`, `shortCircuitAt`, `unknownSeen`, `providerCalls` без чтения secret payload. Не вызывать невыполненные callbacks ради логирования.

**Выбранный путь Kord**

**Расширить существующие общие `RotationProfiles` и `RotationEngine`; отдельный UNKNOWN-движок не создавать.** Канонический источник исключений — валидированный `SkipExceptions` с ключом `rule.id`. При регистрации создать неизменяемую нормализованную авторизацию либо обеспечить повторную безопасную проверку при выполнении. Мутация исходной таблицы после регистрации не должна разрешать skip. Разрешать продолжение только после подтверждения ruleID, reason, области optional condition и разрешения. UNKNOWN обязательного факта всегда STOP. Диагностика: ruleID, priority, исходная причина, решение STOP/SKIPPED, reason/testID исключения, scope, фактически вызванные правила; без secret payload и без оценки последующих правил ради лога. Eligibility остаётся единственным арбитром READY.

**Выбранный путь Kord**

**Сохранить `RotationProfiles.Config` единственным источником схемы, `RotationSettings` — хранилищем и нормализатором, `RotationEngine` — потребителем готового `cfg`, `RotationAbilities` — schema-driven UI.** Не создавать отдельный CFG-движок и не дублировать валидатор. Вынести общую функцию нормализации в существующий общий модуль и вызывать её при чтении UI и построении runtime config. При записи неверного значения допустим отказ без сохранения, но следующее чтение обязано вернуть default. Невалидный `default` — ошибка схемы при регистрации, а не runtime fallback. Для enum сравнивать значение и тип; number проверять конечность и границы; bool — строго boolean. Вводить step/precision только при явном описании схемы и совместимой проверке. Схему фиксировать как неизменяемый registration snapshot либо безопасно защищать от мутаций. Локализация label/tooltip не должна влиять на стабильный key или значение enum. UI не вправе обходить `RotationSettings`.

**Выбранный путь Kord**

**Сохранить `RotationProfiles.status` и существующий gate `RotationEngine` без нового status-engine.** Установить формальный процесс переходов `draft → mock_tested → experimental → verified` на основании доказательств; допускается возврат на более ранний статус после изменений или неуспешных тестов. Хранить привязку к profileID, версии/хэшу, клиенту/сборке, идентификаторам тестов, датам и результатам, не считая самопровозглашённое поле `status="verified"` доказательством. Политика runtime: только verified штатно, experimental по явному opt-in, draft/mock_tested никогда. В обоих каналах сохранять fail-closed и `AbilityEligibility`. При несовпадении версии доказательств статус не должен давать прежние права; журнал должен показывать причину блокировки и происхождение допуска. Не вводить class-specific статусы или отдельный движок.

**Выбранный путь Kord**

**Расширить существующие `RotationSettings`, `RotationEngine` и `RotationAbilities` без второго mode/burst engine.** Пользовательский `targetMode` остаётся `single/aoe/auto`; `auto` вычисляет эффективный режим только из общего достоверного EN-01/EN-05 наблюдения с проверкой контекста (радиус, враждебность, доступность, исключение ломаемого контроля по EN-04). При UNKNOWN — STOP зависимого scope, не single fallback. Ручной `aoe` определяет стратегию, но не делает небезопасное AoE пригодным; `AbilityEligibility` остаётся арбитром READY.

Burst — отдельная типизированная настройка политики расходования offensive cooldowns, не синоним общего `cooldowns=true`; зафиксировать состояния `off/on/auto` либо более узкий явный контракт после согласования с существующими категориями. Выбранный для Kord контракт: `burstMode=off/on/auto`, где off запрещает только помеченные burst-правила, on разрешает их обычную проверку, auto требует подтверждённого burst-условия профиля (не выдумывать окно); при UNKNOWN обязательного условия — STOP. Существующая категория cooldowns — внешний gate: выключенная категория всегда побеждает burstMode. Различие «обычный cooldown»/«burst cooldown» — метаданные правил, не классовый модуль.

Категории фильтровать перед вызовом условий; отдельные per-spell overrides не должны обходить выключенную группу или обязательные проверки. Настройки хранить в существующем namespace профиля и отображать через текущий UI, без новых параллельных хранилищ. Сохранять main/defensive scope и диагностику фактически достигнутых правил.

**Выбранный путь Kord**

**Сохранить `RotationProfiles` как единственный реестр диапазонов, `RotationEngine` — выбор по снимку уровня, `AbilityEligibility` — проверку изученности и пригодности; не создавать level-engine.** Для рангов использовать общий нормализованный spellbook/rank resolver (при необходимости расширить существующий провайдер, не добавлять классовые обходы). Семейство spellID разрешается в максимальный **достоверно изученный** ранг; если сведения неполные — UNKNOWN, не rank 1 fallback. Для условий, где важен строго определённый ранг, хранить явную семантику exact-rank, отдельно от family-rank. При level-up и spellbook change обновлять ревизии snapshot и переоценивать профиль/ранги до выдачи READY. Не перезаписывать verified автоматически; существенное изменение профиля требует пересмотра доказательств EN-A6.

**Выбранный путь Kord**

**Сохранить текущую ленивую выдачу первого READY и расширять только общий `RotationEngine`/контракт отображения, без второго rotation-engine.** Первый слот всегда проверяется `AbilityEligibility`. Для второго слота выбрать консервативный контракт: `next` может быть только `PREDICTED` с причиной/источником/ограничениями, а не READY, пока будущие состояние и переход не доказаны. На первом этапе разрешить пустой второй слот; запретить повторный обход того же snapshot как будто первая способность уже применена. Для вычисления прогнозов впоследствии требуется формализованная безопасная модель перехода, поддерживающая изменения ресурсов, GCD, аур, cooldown, целей, проков и рангов; без модели — `next=nil`. На UNKNOWN главной цепочки — не продолжать. Отдельные main/defensive каналы не объединять в один двухшаговый список. Не переносить целиком прогнозы JustAC/RotationMaster без проверки совместимости с Forever и secret API.

**Выбранный путь Kord**

**Не создавать отдельный мультидот-движок.** Расширить общий канонический список противников EN-01/EN-03/EN-06, aura/TTD провайдеры и `RotationConditions`, а выбор цели встроить в общий `RotationEngine` с обязательной финальной проверкой `AbilityEligibility`. Нужен типизированный `TargetCandidate` с подтверждённым источником, безопасным идентификатором/токеном, revision и статусом наблюдения; отсутствие безопасной идентичности — UNKNOWN, а не новый уникальный моб. Для DoT хранить per-candidate `spellID`, caster provenance, remaining/duration и freshness; не создавать второй реестр целей. Приоритет: сначала доказанно нуждающиеся в DoT подходящие цели, затем подтверждённый TTD/выгода, затем стабильный tie-break без предположений. Не обходить EN-04 (ломаемый CC) и ограничения текущей цели. В первой безопасной версии разрешить мультидот только на текущую подтверждённую цель, если произвольный nameplate-unit нельзя проверить; UI может показывать рекомендацию сменить цель как неподтверждённую подсказку, но не READY способности на другой цели. Автоматическое переключение целей запрещено.

**Выбранный путь Kord**

**Расширить существующий `RotationProfiles.SkipExceptions` и gate `RotationEngine`, не создавать отдельный skip-engine.** Канонический реестр утверждений — versioned/immutable при регистрации; записи ссылаются на реальные успешные тесты и точные причины UNKNOWN. Профильное `onUnknown="skip"` — только запрос разрешения, не источник полномочий. Runtime проверяет конкретный approved record перед продолжением обхода; любое расхождение fail-closed. Разрешать только безопасные необязательные условия, где отказ от действия не скрывает опасность и нижестоящая рекомендация независимо проверяется `AbilityEligibility`. Категории interrupts и любые mandatory safety условия не могут быть исключениями. Существующие `reason` (обоснование) и `testID` сохранить; дополнить `unknownReason`, `approvedVersion` и доказательством статуса теста, не путать reason исключения с runtime reason.

**Таблица допуска (каноническая политика):**

| Ситуация | SKIP? | Обоснование/тест |
|---|---|---|
| Явно утверждённое необязательное condition_unknown, точный ruleID/reason/version, успешный testID | Да | Только узкая безопасная область; тест подтверждает отсутствие нарушения приоритетов |
| Необязательное условие без approved record или успешного теста | Нет | Не доказана безопасность |
| `condition_error` или `condition_invalid` | Нет | Ошибка не равна необязательному UNKNOWN |
| UNKNOWN от `AbilityEligibility` (ресурс, range, cooldown, target, spellbook) | Нет | Неизвестна пригодность способности |
| Interrupt, mandatory safety, ломаемый CC | Нет | Пропуск может нарушить обязательную безопасность |
| Несовпадение profile/version/unknownReason или устаревший testID | Нет | Разрешение не относится к текущему состоянию |

На момент аудита **ни одно конкретное исключение не объявлено утверждённым** без подтверждённых результатов тестов.

**Требуемые изменения (полный текст)**

**Требуемые изменения**

1. Формализовать `STOP` как управляющее `decision`, не как нажимаемый action, сохранив существующий `UNKNOWN` и совместимость UI.
2. Зафиксировать tri-state lazy обход: READY выбирается, BLOCKED пропускается, UNKNOWN обязательного условия останавливает зависимую цепочку; не считать UNKNOWN=false.
3. Ввести типизированную критичность фактов, scope/dependency propagation и независимость defensive канала там, где это доказано.
4. Использовать уже существующие `GameAPI`, `GameState`, `RotationConditions`, `AbilityEligibility`; не создавать второй condition/secret scanner.
5. Разграничить `STOP/WAIT/NO_ACTION/BLOCKED/ERROR/DISABLED` в diagnostics/UI, без выдуманного spellID, fake WAIT или таймера.
6. EventBus revision/recovery и bounded retry; гарантировать пересчёт после восстановления API, смены цели/спека, обновления cooldown/resource, без stale STOP.
7. DevTools: blockingFact, ruleID, source, scope, revision, reason; secret-safe logging, без вывода секретных payload.
8. Тесты: READY first, BLOCKED then READY, UNKNOWN first then READY lower (должен STOP), неизвестная необязательная иконка (не общий STOP), secret/nil resource/cooldown/range/CC, отсутствующий провайдер, неверный тип, stale snapshot, shared critical context, независимая defensive READY при main STOP, UNKNOWN defensive при main READY, восстановление по event, WAIT vs STOP, отсутствие ложного READY/protected actions.

**Требуемые изменения**

1. Закрепить `PROFILE_CONTRACT_VERSION` и централизованную `ValidateProfileContract` в существующем `RotationProfiles`, сохранив отказ по версии.
2. Сделать раздельные причины missing/mismatch/unsupported, ожидаемую/фактическую версию, лог DevTools и предсказуемое API результата.
3. Подтвердить одинаковый gate в `Register/Replace`, атомарность отказа и отсутствие обхода через `Get/Select/Evaluate`.
4. Согласовать разрешённые `Rules/Needs/actionType` с AC-01–AC-07 и явным планом версионирования; не объявлять новые типы реализованными преждевременно.
5. Обновлять `docs/rotation/Profile_Contract.md`, `Profile_Registry.md`, тесты и профили при каждой несовместимой миграции; не менять номер без фактического перехода.
6. Тесты: missing/0/1/string/future contractVersion, valid v1, неверный profile.version, duplicate id, unknown rule type/Needs, stale profile cache, Register/Replace failure rollback, experimental bypass prohibited, invalid profile never evaluates, v1 → next version migration, Lua 5.1 и in-game verification.

**Требуемые изменения**

1. Зафиксировать порядок `Rules` как публичный контракт EN-A1 и запретить неявную сортировку/переупорядочение.
2. Сохранить ленивый `ipairs` обход, ранний `return` на первом READY, fail-closed UNKNOWN/STOP и только разрешённый skip.
3. Распространить эту семантику на новые typed actions AC-02–AC-06 после их реализации, без отдельного item/pet/wait движка.
4. Добавить в DevTools трассу фактически посещённых ruleID/priority, count of `when`/eligibility/provider calls, STOP reason и доказательство отсутствия оценки следующих правил.
5. Уточнить, может ли необязательная визуальная metadata приводить к UNKNOWN после READY; не маскировать отсутствие иконки под отсутствие пригодного действия.
6. Тесты: READY на 1-м/среднем/последнем правиле; BLOCKED→READY; UNKNOWN→STOP без вызова следующего; approved skip→следующее; unapproved skip reject; `condition_error` не skip; eligibility UNKNOWN не skip; запрещённые правила не вызывают `when`; dense array validation; side-effect counters; separate main/defensive; lazy Needs; cache revision; стабильность порядка после Replace; Lua 5.1 и in-game.

**Требуемые изменения**

1. Исправить `methods:all`: не завершать при первом `nil`, а продолжать до `false` или конца; возвращать nil, если unknown остался без определяющего false.
2. Сохранить `methods:any` с ранним true и отложенным unknown; явно закрепить таблицу истинности всех 9 пар и трёх аргументов.
3. Проверить, что все аргументы — отложенные функции и никакие данные не читаются до фактического вызова нужного thunk.
4. Сохранить `pcall` границу ошибок и AC-07 STOP, не допуская `nil=false` и не маскируя ошибки как false.
5. Переиспользовать существующие `Needs`, memo и EventBus; без второго provider/condition engine.
6. Тесты счётчиков: `all(false,sideEffect)` → 0 вызовов второго; `any(true,sideEffect)` → 0; `all(nil,false)` → false и второй вызван; `any(nil,true)` → true и второй вызван; `all(nil,true)` → nil; `any(nil,false)` → nil; invalid result/exception → STOP; expensive provider never read after decisive value; Lua 5.1/in-game.

**Требуемые изменения**

1. Формализовать проверяемую и неизменяемую авторизацию `SkipExceptions[rule.id]` и запретить runtime skip по одному `rule.onUnknown`.
2. Проверять соответствие исключения конкретному optional condition; запрещать смешанные обязательные safety-facts, interrupts, condition_error/invalid и eligibility UNKNOWN.
3. Проверить все профили и будущие typed actions на общий контракт, не создавать class-specific обработчики UNKNOWN.
4. Добавить DevTools-трассу STOP/SKIPPED, ruleID, reason, testID, scope и счётчики реально вызванных условий.
5. Тесты: UNKNOWN→STOP; разрешённый optional condition_unknown→SKIP; нет/невалидная запись→STOP; mutation после регистрации не повышает права; condition_error/invalid→STOP; eligibility UNKNOWN→STOP; interrupts→STOP; независимые каналы; отсутствие вычисления нижних правил; Lua 5.1 и in-game.

**Требуемые изменения**

1. Свести повторяющуюся валидацию `RotationProfiles`, `RotationSettings` и `RotationEngine` к единому каноническому контракту, не меняя смысл существующих значений.
2. Гарантировать default для отсутствующих/некорректных сохранённых bool/number/enum; при некорректной записи возвращать явный отказ и не повреждать хранилище.
3. Обеспечить неизменность валидированной схемы после регистрации; namespace по profile.id и корректную реакцию на смену класса/специализации/уровня.
4. Проверить, что UI генерирует все и только элементы `Config`, использует общие getters/setters, показывает дефолты и не допускает значений за границами.
5. DevTools: schema profileID/version, key, type, validation result, fallback reason, UI-control type; не логировать секретные/личные значения.
6. Тесты: bool true/false/invalid; number min/max/ниже/выше/NaN/Infinity/строка; enum first/last/unknown/type mismatch; отсутствующий ключ; повреждённые SavedVariables; invalid default reject; дубли key reject; смена профиля; mutation после регистрации; совпадение UI и runtime; Lua 5.1 и in-game.

**Требуемые изменения**

1. Зафиксировать допустимые статусы и их смысл как публичный контракт версии профиля.
2. Добавить проверяемые свидетельства тестирования/подтверждения, привязанные к версии профиля; определить downgrade при изменении логики.
3. Сохранить gate `RotationEngine`: draft/mock_tested запрещены; experimental только при явном opt-in; verified штатно.
4. Проверить сохранение opt-in, отключение экспериментального допуска, UI-индикацию статуса и независимость main/defensive.
5. Добавить DevTools запись profileID/version/status, основание допуска/блокировки, testID/build, без недостоверных заявлений о проверке.
6. Тесты: все четыре статуса; unknown/missing status reject; experimental flag false/true; draft/mock_tested не проходят даже с флагом; смена версии аннулирует подтверждение; отсутствие доказательств не выдаёт verified; main/defensive; eligibility UNKNOWN→STOP; Lua 5.1 и in-game.

**Требуемые изменения**

1. Подключить `auto` к общему EN-01/EN-05 подсчёту и порогу, заменить безусловный `auto_target_count_unverified` только при достоверном результате; UNKNOWN→STOP.
2. Ввести burstMode off/on/auto и метаданные burst-правил в общую схему, сохранив независимую категорию cooldowns; задокументировать приоритет фильтров.
3. Проверить все категории, per-spell overrides, cooldownsOnlyInCombat, defensiveEnabled и порядок фильтрации до `rule.when`.
4. Добавить UI для burstMode и отображение эффективного auto-mode, источника числа целей, порога и причин отказа.
5. DevTools: requested/effective mode, target count/source/revision, AoE threshold, burstMode, group gate, filtered ruleID, scope и UNKNOWN reason.
6. Тесты: single/aoe/auto при 0/1/N/UNKNOWN целей; nameplates/CC/радиус; переключение режима; burst off/on/auto с выключенной категорией; per-spell override; запрещённые группы не вызывают when; defensive; Lua 5.1/in-game.

**Требуемые изменения**

1. Зафиксировать включительность границ, запрет пересечений и fail-closed выбор по достоверному уровню.
2. Подтвердить или реализовать единый rank resolver по изученным spellID с явным exact/family режимом, без предположения об изучении по уровню.
3. Проверить инвалидацию spellbook, identity, talents, profile snapshot и кэша при level-up/обучении/смене специализации.
4. Проверить `Replace` и привязку статуса профиля к версии/диапазону; исключить использование устаревших данных.
5. DevTools: class/spec/level, выбранный profileID/range, spell family, изученный rankID, источник/ревизия и причины UNKNOWN без secret payload.
6. Тесты: `min-1/min/max/max+1`, однопунктовый диапазон, соседние интервалы, перекрытие, пустой диапазон, invalid/secret level; новый уровень без обучения, новый ранг без level-up, spellbook unavailable, max learned rank, exact-rank, respec, возврат в прежний диапазон, Lua 5.1 и in-game.

**Требуемые изменения**

1. Формализовать контракт `current READY` / `next PREDICTED|nil` и явно разделить независимые каналы.
2. Добавить необязательное поле второго слота в общую модель выдачи и UI с явной маркировкой прогноза; по умолчанию nil.
3. Запретить «прогноз» через простой второй проход текущих правил или пропуск UNKNOWN; любые изменения будущего состояния требуют доказанной модели.
4. Инвалидировать прогноз при изменении цели, ресурсов, аур, spellbook, cooldown, GCD, кастов, режима и профиля; не сохранять устаревший прогноз.
5. DevTools: current ruleID/status, predicted ruleID/confidence source/reason, snapshot revision, invalidation cause, без недоказанного READY.
6. Тесты: один READY; нет второго; UNKNOWN→STOP; смена состояния; проки; GCD; ресурс; новая цель; cooldown; независимый defensive; UI не выдаёт PREDICTED за READY; Lua 5.1 и in-game.

**Требуемые изменения**

1. Определить общий контракт списка `TargetCandidate` и проверяемой идентичности, переиспользуя EN-01/EN-03/EN-06, без GUID-спекуляций.
2. Добавить per-target DoT facts: spellID, источник, остаток, ревизия и причина UNKNOWN; различать «нет эффекта» и «эффект неизвестен».
3. Реализовать общий приоритет выбора подходящей цели с TTD, дальностью, EN-04 CC и выбранным режимом; не дублировать сканеры.
4. Расширить формат рекомендации только проверенными target metadata; non-target eligibility требует отдельного доказательства безопасной API-проверки, иначе current-target-only.
5. UI: отображение цели/причины выбора и статуса её подтверждения без автотаргетинга; DevTools: candidate count, dedup, aura freshness, target selection, CC, TTD, UNKNOWN reason без secret payload.
6. Тесты: 1/N целей, одинаковый противник в разных источниках, GUID secret/unknown, смена цели, аура игрока/чужая, DoT отсутствует/истекает/UNKNOWN, CC, TTD UNKNOWN, out-of-range, despawn, nameplate исчез, смена режима, нет автопереключения, Lua 5.1 и in-game.

**Требуемые изменения**

1. Расширить `SkipExceptions` до версионированного строгого контракта с `unknownReason` и доказательством теста; reject неизвестные/лишние поля и неподтверждённые testID.
2. При регистрации проверять совпадение profileID/ruleID/category, необязательность условия и точную область допуска; запретить опасные категории/mandatory safety.
3. В runtime сверять approved record и конкретную причину UNKNOWN; одного `onUnknown=skip` недостаточно. Ошибка, invalid и eligibility UNKNOWN всегда STOP.
4. Инвалидировать разрешение после изменения версии профиля, правила, условия или теста; запретить использование устаревшего registry.
5. DevTools: profileID, ruleID, observed unknownReason, decision STOP/SKIP, exception ID, testID/version, rejection reason; без secret payload.
6. Тесты: approved optional skip; отсутствующая/лишняя запись; ложный testID; неверный unknownReason/version; interrupts; mandatory safety; condition_error/invalid; eligibility UNKNOWN; сохранение порядка приоритетов; Lua 5.1 и in-game.

**Тесты и диагностика**

в файле не указано

**Архитектурные и обратные ссылки:** NO-02, AC-01, AC-06, CC-01, CC-05, SP-01, SP-14, UI-06, QA-01, QA-04, QA-05, QA-06, QA-07, CL-04, CL-05, NO-01, CL-09, AC-02, CL-01, CL-02, CL-03, CL-06, CL-07, AC-03, DA-01, DA-02, DA-03, DA-04, UI-01, UI-02, QA-02, QA-03, PR-PR-01, PR-07, NO-06, PR-04, DA-07, UI-03, UI-04, EN-05, EN-01, EN-04, DA-08, EN-03, EN-06, DA-05, DA-06.

---

