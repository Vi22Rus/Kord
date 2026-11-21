# Аудит канонического ядра — этап 2.8.1 (101/101)

**Дата:** 2026-11-21. **Baseline:** `main@5a03b1d88f0930c4a3dc87d32cf6dae2e11360ef`. **Нормативный источник:** [Canonical_API_Matrix.md](Canonical_API_Matrix.md), утверждённая v14, 101/101 строк. **Game client PASS:** 0/101, все игровые кейсы NOT RUN.

## Методология и ограничения

Просмотрены действующие исходники: `KordRotation/Core/GameAPI.lua`, `KordRotation/Core/GameState.lua`, `KordRotation/Core/AbilityEligibility.lua`, `KordRotation/Core/RotationEngine.lua`, `KordRotation/Core/RotationProfiles.lua`, `KordRotation/Core/BindingResolver.lua`, `KordRotation/Core/ActionBarScanner.lua`, `KordRotation/Core/SpellCatalogue.lua`, `KordRotation/Core/EventBus.lua`, `KordRotation/UI/RotationDisplay.lua`. Для каждой строки v14 выполнена предварительная сверка упомянутых API-методов с именами в этих файлах и установлен потребитель. **Это статический inventory, а не проверка выполнения метода**: совпадение имени в allowlist, комментарии или строке кода не доказывает корректный вызов или поддержку клиента. Показатели ниже НЕ являются статусами исходниковой доказанности 58/20/23 самой v14. Следующий подэтап должен проверить аргументы, типы результатов, Secret API, события и все потребители непосредственно.

- `ALL_NAMES_PRESENT`: 30 строк.
- `SOME_NAMES_PRESENT`: 19 строк.
- `NO_NAMES_PRESENT`: 42 строк.
- `NEEDS_MANUAL_REVIEW`: 10 строк.

## Сверка 101 возможностей

| № | Возможность | Выбранная цепочка из v14 | Текстовые совпадения в коде | Предварительный статус |
|---:|---|---|---|---|
| 1 | Цель существует | UnitExists(unit) | `UnitExists` | ALL_NAMES_PRESENT |
| 2 | Цель враждебна | UnitCanAttack('player',unit) | `UnitCanAttack` | ALL_NAMES_PRESENT |
| 3 | Здоровье цели | UnitHealth(unit); UnitHealthMax(unit); UnitHealthPercent(unit,false,curve) | `UnitHealth`, `UnitHealthMax` | SOME_NAMES_PRESENT |
| 4 | Здоровье игрока | UnitHealth('player'); UnitHealthMax('player'); UnitHealthPercent('player',false,curve) | `UnitHealth`, `UnitHealthMax` | SOME_NAMES_PRESENT |
| 5 | Здоровье питомца | UnitExists('pet'); UnitIsDeadOrGhost('pet'); UnitHealthPercent('pet',false,curve) | `UnitExists`, `UnitIsDeadOrGhost` | SOME_NAMES_PRESENT |
| 6 | Мана / ресурс | UnitPowerType(unit); UnitPower(unit,powerType); UnitPowerMax(unit,powerType); UnitPowerPercent(unit,powerType,false,curve) | `UnitPowerType`, `UnitPower`, `UnitPowerMax` | SOME_NAMES_PRESENT |
| 7 | Уровень игрока | UnitLevel('player') | `UnitLevel` | ALL_NAMES_PRESENT |
| 8 | Класс игрока | UnitClass('player') | `UnitClass` | ALL_NAMES_PRESENT |
| 9 | Игрок движется | IsPlayerMoving() | — | NO_NAMES_PRESENT |
| 10 | Дистанция применения способности | C_Spell.IsSpellInRange(spellID,unit) -> bool? (nil=invalid) | `C_Spell.IsSpellInRange` | ALL_NAMES_PRESENT |
| 11 | Кулдаун способности | C_Spell.GetSpellCooldown(spellID) -> SpellCooldownInfo? (secret possible) | `C_Spell.GetSpellCooldown` | ALL_NAMES_PRESENT |
| 12 | Баффы игрока | C_UnitAuras.GetAuraDataByIndex('player',index,'HELPFUL') -> AuraData?; C_UnitAuras.GetPlayerAuraBySpellID(spellID) -> AuraData? (RequiresNonSecretAura) | `C_UnitAuras.GetAuraDataByIndex` | SOME_NAMES_PRESENT |
| 13 | Дебаффы цели | C_UnitAuras.GetAuraDataByIndex('target',index,'HARMFUL') -> AuraData?; C_UnitAuras.GetUnitAuraBySpellID(unit,spellID) (RequiresNonSecretAura) | `C_UnitAuras.GetAuraDataByIndex` | SOME_NAMES_PRESENT |
| 14 | Агро / угроза | UnitThreatSituation('player',unit); UnitDetailedThreatSituation('player',unit) | — | NO_NAMES_PRESENT |
| 15 | Каст противника | UnitCastingInfo(unit); UnitChannelInfo(unit) | `UnitCastingInfo`, `UnitChannelInfo` | ALL_NAMES_PRESENT |
| 16 | Число врагов | C_NamePlate.GetNamePlates(); UnitCanAttack; range filter | — | NO_NAMES_PRESENT |
| 17 | Группа / рейд | IsInGroup(); IsInRaid(); GetNumGroupMembers() — confirmed global calls in Blizzard Shared/RaidFinder.lua and Shared/GroupFrameVisibility.lua | — | NO_NAMES_PRESENT |
| 18 | Подземелье / рейд | IsInInstance(); GetInstanceInfo() | — | NO_NAMES_PRESENT |
| 19 | Изученность заклинания | C_SpellBook.IsSpellKnown(spellID,Enum.SpellBookSpellBank.Player); C_SpellBook.FindSpellBookSlotForSpell(spellID) | — | NO_NAMES_PRESENT |
| 20 | Ранг заклинания | C_SpellBook.GetNumSpellBookSkillLines(); C_SpellBook.GetSpellBookSkillLineInfo(line); C_SpellBook.GetSpellBookItemInfo(slot,bank); C_SpellBook.GetSpellBookItemName(slot,bank) | `C_SpellBook.GetNumSpellBookSkillLines`, `C_SpellBook.GetSpellBookSkillLineInfo`, `C_SpellBook.GetSpellBookItemInfo`, `C_SpellBook.GetSpellBookItemName` | ALL_NAMES_PRESENT |
| 21 | Доступность / стоимость | C_Spell.IsSpellUsable(spellID) -> isUsable,insufficientPower; C_Spell.GetSpellPowerCost(spellID) -> table<SpellPowerCostInfo>? | `C_Spell.IsSpellUsable` | SOME_NAMES_PRESENT |
| 22 | Прерывание | UnitCastingInfo('target'); UnitChannelInfo('target'); notInterruptible; interrupt usability | `UnitCastingInfo`, `UnitChannelInfo` | ALL_NAMES_PRESENT |
| 23 | Контроль / CC | C_UnitAuras CC states; C_LossOfControl; UnitIsCrowdControlled candidate | — | NEEDS_MANUAL_REVIEW |
| 24 | Автовыстрел / автоатака | C_Spell.IsCurrentSpell(autoShotID); C_Spell.IsAutoRepeatSpell(autoShotID); cast events for queued state (official transition guide 11.0) | — | NO_NAMES_PRESENT |
| 25 | GCD | C_Spell.GetSpellCooldown(gcdSpellID) -> SpellCooldownInfo? | `C_Spell.GetSpellCooldown` | ALL_NAMES_PRESENT |
| 26 | Заряды способности | C_Spell.GetSpellCharges(spellID) -> SpellChargeInfo? {currentCharges,maxCharges,cooldownStartTime,cooldownDuration,chargeModRate,isActive} | `C_Spell.GetSpellCharges` | ALL_NAMES_PRESENT |
| 27 | Остаток баффа | C_UnitAuras.GetAuraDataByIndex(unit,index,'HELPFUL') -> AuraData?; C_UnitAuras.GetAuraDuration(unit,auraInstanceID) -> LuaDurationObject [not guaranteed Lua numeric] | `C_UnitAuras.GetAuraDataByIndex` | SOME_NAMES_PRESENT |
| 28 | Остаток дебаффа | C_UnitAuras.GetAuraDataByIndex(unit,index,'HARMFUL') -> AuraData?; C_UnitAuras.GetAuraDuration(unit,auraInstanceID) -> LuaDurationObject [not guaranteed Lua numeric] | `C_UnitAuras.GetAuraDataByIndex` | SOME_NAMES_PRESENT |
| 29 | Таланты / специализация | C_SpecializationInfo.GetTalentInfo({specializationIndex,talentIndex,isInspect,isPet,groupIndex}) for Vanilla-style talent ranks; C_Traits.GetConfigInfo(configID) / GetNodeInfo(configID,nodeI | — | NO_NAMES_PRESENT |
| 30 | Питомец атакует цель | UnitExists('pettarget'); UnitIsUnit('pettarget','target'); pet action state | `UnitExists`, `UnitIsUnit` | ALL_NAMES_PRESENT |
| 31 | Время до смерти цели | UnitHealth/UnitHealthMax snapshots; GetTime(); unknown if protected | — | NEEDS_MANUAL_REVIEW |
| 32 | Доступность action bar | GetActionInfo(slot) — confirmed used in Blizzard_SpellPickUpIndicator.lua and Blizzard_BoostTutorial.lua (global outside generated index) | `GetActionInfo` | ALL_NAMES_PRESENT |
| 33 | Привязка клавиши | GetBindingKey(command); GetBindingAction(key) — confirmed used in Blizzard_SharedXML/BindingUtil.lua and Blizzard_FrameXML/Mainline/CoinPickupFrame.lua | `GetBindingKey`, `GetBindingAction` | ALL_NAMES_PRESENT |
| 34 | Изменение формы / стойки | GetShapeshiftForm(); GetShapeshiftFormInfo(index) — confirmed in Blizzard_SharedXML/StanceBar.lua | — | NO_NAMES_PRESENT |
| 35 | Условия лечения / диспела | UnitIsFriend; UnitCanAssist; UnitHealthPercent(unit,false,curve); aura dispelName | — | NO_NAMES_PRESENT |
| 36 | Тринкеты / расовые / предметы | GetInventoryItemID('player',slot) — Blizzard FrameXML confirmed; C_Item.IsUsableItem(itemID); C_Item.GetItemCooldown(itemID); C_SpellBook.IsSpellKnown(racialID) | — | NO_NAMES_PRESENT |
| 37 | Опасный входящий урон | UnitThreatSituation; UNIT_COMBAT history; incoming-damage prediction unresolved | — | NEEDS_MANUAL_REVIEW |
| 38 | PvP / игрок-цель | UnitIsPlayer(unit); UnitIsPVP(unit) | — | NO_NAMES_PRESENT |
| 39 | Воскрешение / смерть | UnitExists(unit); UnitIsDead(unit); UnitIsDeadOrGhost(unit) | `UnitExists`, `UnitIsDead`, `UnitIsDeadOrGhost` | ALL_NAMES_PRESENT |
| 40 | Процент здоровья союзника / выбор цели лечения | UnitHealthPercent(unit,false,curve); JustAC IsUnitHealthBelow / GetHealthBand | — | NO_NAMES_PRESENT |
| 41 | Невидимое/защищённое значение здоровья | UnitHealthPercent(unit,false,curve) -> LuaCurveEvaluatedResult; C_CurveUtil.CreateCurve(); in-Lua bands unproven | — | NO_NAMES_PRESENT |
| 42 | Порог здоровья цели / execute | UnitHealthPercent('target',false,curve); exact threshold curve | — | NO_NAMES_PRESENT |
| 43 | Наличие/обновление DoT по времени | C_UnitAuras.GetAuraDataByIndex(unit,index,'HARMFUL'); C_UnitAuras.GetAuraDataByAuraInstanceID(unit,auraInstanceID); auraInstanceID/spellId/sourceUnit/expirationTime subject to secret restric | `C_UnitAuras.GetAuraDataByIndex` | SOME_NAMES_PRESENT |
| 44 | Проверка владельца HoT/DoT | C_UnitAuras.GetAuraDataByIndex(unit,index,'HELPFUL'/'HARMFUL'); aura.sourceUnit; UnitIsUnit(sourceUnit,'player') при читаемости | `C_UnitAuras.GetAuraDataByIndex`, `UnitIsUnit` | ALL_NAMES_PRESENT |
| 45 | Стеки ауры | C_UnitAuras.GetAuraDataByIndex(unit,index,filter); aura.applications if readable; C_UnitAuras.GetAuraApplicationDisplayCount(unit,auraInstanceID) for display text | `C_UnitAuras.GetAuraDataByIndex` | SOME_NAMES_PRESENT |
| 46 | Стеки проков | C_UnitAuras.GetAuraDataByIndex(unit,index,filter); aura.applications and aura.spellId subject to secret; unavailable remains unknown | `C_UnitAuras.GetAuraDataByIndex` | ALL_NAMES_PRESENT |
| 47 | Оружейное зачарование | C_Item.GetWeaponEnchantInfo(weaponSlot) where weaponSlot is Enum.WeaponSlot.MainHand / OffHand / Ranged | — | NO_NAMES_PRESENT |
| 48 | Тотем активен / нужен | GetTotemInfo(slot); GetTotemTimeLeft(slot) [SecretWhenTotemSlotSecret] | — | NO_NAMES_PRESENT |
| 49 | Комбо-поинты | UnitPower('player', Enum.PowerType.ComboPoints); UnitPowerPercent('player', Enum.PowerType.ComboPoints,false,curve) — powerType availability verify | `UnitPower` | SOME_NAMES_PRESENT |
| 50 | Энергия | UnitPower('player',Enum.PowerType.Energy); UnitPowerPercent('player',Enum.PowerType.Energy,false,curve) | `UnitPower` | SOME_NAMES_PRESENT |
| 51 | Ярость | UnitPower('player',Enum.PowerType.Rage); UnitPowerPercent('player',Enum.PowerType.Rage,false,curve) | `UnitPower` | SOME_NAMES_PRESENT |
| 52 | Нехватка ресурса / starved | C_Spell.IsSpellUsable(spellID) -> isUsable,insufficientPower | `C_Spell.IsSpellUsable` | ALL_NAMES_PRESENT |
| 53 | Прогноз расхода ресурса | C_Spell.GetSpellPowerCost(spellID) -> table<SpellPowerCostInfo>? {type,cost,minCost,requiredAuraID,hasRequiredAura} | — | NO_NAMES_PRESENT |
| 54 | Доступность предмета в сумке | C_Item.GetItemCount(itemID) -> count [SecretArguments=AllowedWhenUntainted] | — | NO_NAMES_PRESENT |
| 55 | Недавнее применение способности | UNIT_SPELLCAST_SUCCEEDED; spellID; GetTime() history | — | NEEDS_MANUAL_REVIEW |
| 56 | Очередь/ожидание каста | UNIT_SPELLCAST_SENT/START/SUCCEEDED/FAILED; UnitCastingInfo('player') | `UnitCastingInfo` | ALL_NAMES_PRESENT |
| 57 | Проверка возможности закончить каст | UnitCastingInfo('player'); UnitChannelInfo('player'); endTime | `UnitCastingInfo`, `UnitChannelInfo` | ALL_NAMES_PRESENT |
| 58 | Окно автоатаки / swing timer | UnitRangedDamage; UnitAttackSpeed; cast events; ranged swing estimator | — | NEEDS_MANUAL_REVIEW |
| 59 | Тик периодического урона | C_UnitAuras expirationTime; COMBAT_LOG_EVENT_UNFILTERED tick timestamps | — | NEEDS_MANUAL_REVIEW |
| 60 | Стелс | IsStealthed(); C_UnitAuras.GetAuraDataByIndex('player',index,'HELPFUL') as optional aura evidence | `C_UnitAuras.GetAuraDataByIndex` | SOME_NAMES_PRESENT |
| 61 | Контроль персонажа / root | C_LossOfControl.GetActiveLossOfControlData(index); C_LossOfControl.GetActiveLossOfControlDataCount() | — | NO_NAMES_PRESENT |
| 62 | Прерываемость вражеского каста | UnitCastingInfo('target'); UnitChannelInfo('target'); notInterruptible | `UnitCastingInfo`, `UnitChannelInfo` | ALL_NAMES_PRESENT |
| 63 | Снятие дебафа с союзника | C_UnitAuras.GetAuraDataByIndex(ally,index,'HARMFUL') -> AuraData?; dispelName; UnitCanAssist('player',ally) | `C_UnitAuras.GetAuraDataByIndex`, `UnitCanAssist` | ALL_NAMES_PRESENT |
| 64 | Самодиспел | C_UnitAuras.GetAuraDataByIndex('player',index,'HARMFUL') -> AuraData?; dispelName | `C_UnitAuras.GetAuraDataByIndex` | ALL_NAMES_PRESENT |
| 65 | Групповой баф отсутствует | IsInGroup/IsInRaid; party/raid enumeration; C_UnitAuras helpful | — | NEEDS_MANUAL_REVIEW |
| 66 | Классовый баф отсутствует | C_UnitAuras helpful aura spellID | — | NEEDS_MANUAL_REVIEW |
| 67 | Тип цели: игрок | UnitIsPlayer('target') | — | NO_NAMES_PRESENT |
| 68 | Тип цели: элита/босс | UnitClassification(unit); UnitLevel(unit) | `UnitLevel` | SOME_NAMES_PRESENT |
| 69 | Класс вражеской цели | UnitClass(unit) | `UnitClass` | ALL_NAMES_PRESENT |
| 70 | Наличие оружия дальнего боя | GetInventoryItemID('player',INVSLOT_RANGED) (Blizzard global; inspect ranged slot conventions) | — | NO_NAMES_PRESENT |
| 71 | Достаточное количество противников для AoE | C_NamePlate.GetNamePlates(); UnitCanAttack; range filter | — | NO_NAMES_PRESENT |
| 72 | Состояние игрока в соло/квестах | IsInGroup(); IsInRaid(); IsInInstance(); GetInstanceInfo() — globals confirmed by Blizzard usage, details verify | — | NO_NAMES_PRESENT |
| 73 | Наличие группы и число участников | GetNumGroupMembers(); IsInGroup(); IsInRaid() — globals confirmed by Blizzard UI usage | — | NO_NAMES_PRESENT |
| 74 | Наличие талантов/рангов талантов | C_SpecializationInfo.GetTalentInfo({specializationIndex,talentIndex,groupIndex,isPet}) -> rank,maxRank (Vanilla compatibility); C_Traits.GetNodeInfo for modern ClassTalents separately | — | NO_NAMES_PRESENT |
| 75 | Специализация / дерево | C_SpecializationInfo.GetSpecializationInfo(specIndex,isInspect,isPet,inspectTarget,sex,groupIndex); C_SpecializationInfo.GetTalentInfo(query) for Vanilla talent trees; C_Traits GetConfigInfo | — | NO_NAMES_PRESENT |
| 76 | Изменение формы и запрет способностей | GetShapeshiftForm(); GetShapeshiftFormInfo(index); C_Spell.IsSpellUsable(spellID) | `C_Spell.IsSpellUsable` | SOME_NAMES_PRESENT |
| 77 | Состояние pet отсутствует / призыв | UnitExists('pet'); UnitIsDeadOrGhost('pet') | `UnitExists`, `UnitIsDeadOrGhost` | ALL_NAMES_PRESENT |
| 78 | Агро отсутствует / высокое агро | UnitThreatSituation('player','target'); UnitDetailedThreatSituation | — | NO_NAMES_PRESENT |
| 79 | Защитная рекомендация вне ротации | UnitHealthPercent('player',false,curve); UnitThreatSituation; defensive signals | — | NO_NAMES_PRESENT |
| 80 | Проверка ограничения секретных чисел | issecretvalue(value); guarded reads; unknown state | `issecretvalue` | ALL_NAMES_PRESENT |
| 81 | Условие неизвестности заклинания | C_SpellBook.IsSpellKnown(spellID,Enum.SpellBookSpellBank.Player); C_SpecializationInfo.GetTalentInfo(query) for Vanilla talent selection; C_Traits.GetNodeInfo for distinct ClassTalents | — | NO_NAMES_PRESENT |
| 82 | Проверка таланта / уровня до применения | UnitLevel('player'); C_SpellBook.IsSpellKnown(spellID); C_SpecializationInfo.GetTalentInfo(query) for Vanilla ranks; C_Traits.GetNodeInfo for ClassTalents | `UnitLevel` | SOME_NAMES_PRESENT |
| 83 | Проверка GCD vs общего/shared cooldown | C_Spell.GetSpellCooldown(spellID); SpellCooldownInfo.isOnGCD only during SPELL_UPDATE_COOLDOWN; category/startRecoveryCategory from event | `C_Spell.GetSpellCooldown` | ALL_NAMES_PRESENT |
| 84 | Слот экипировки → itemID | GetInventoryItemID('player',slot) — confirmed Blizzard_FrameXML/Mainline/EquipmentManager.lua | — | NO_NAMES_PRESENT |
| 85 | Кулдаун экипированного предмета | GetInventoryItemCooldown('player',slot) (Blizzard UI global); C_Item.GetItemCooldown(itemID) -> start,duration,enabled (distinct APIs) | — | NO_NAMES_PRESENT |
| 86 | Наличие оружия дальнего боя по слоту | GetInventoryItemID('player',INVSLOT_RANGED) — confirmed Blizzard EquipmentManager.lua; slot semantics verify | — | NO_NAMES_PRESENT |
| 87 | Боеприпасы: слот/количество | UnitUsesAmmo('player'); GetInventoryItemID('player',ammoSlot); GetInventoryItemCount('player',ammoSlot) — confirmed Blizzard EquipmentManager use of GetInventoryItemCount | — | NO_NAMES_PRESENT |
| 88 | Считывание tooltip экипировки | GetInventoryItemLink('player',slot) — confirmed Blizzard Shared/ChatFrameUtil.lua; C_TooltipInfo.GetInventoryItem tooltip candidate | — | NO_NAMES_PRESENT |
| 89 | Ссылка предмета экипировки | GetInventoryItemLink('player',slot) — confirmed Blizzard Shared/ChatFrameUtil.lua | — | NO_NAMES_PRESENT |
| 90 | Идентификатор инстанса | GetInstanceInfo() instanceID | — | NO_NAMES_PRESENT |
| 91 | Контекст вне инстанса | IsInInstance(); GetInstanceInfo() | — | NO_NAMES_PRESENT |
| 92 | Threat по паре юнитов | UnitDetailedThreatSituation(unit,mob); UnitThreatSituation(unit,mob) | — | NO_NAMES_PRESENT |
| 93 | Время последнего изменения cooldown | SPELL_UPDATE_COOLDOWN(spellID?,baseSpellID?,category?,startRecoveryCategory?,itemID?) + GetTime() to record LOCAL observation time | — | NEEDS_MANUAL_REVIEW |
| 94 | Форма друида через кэш | GetShapeshiftForm(); UPDATE_SHAPESHIFT_FORM event; cached value (FrameXML usage) | — | NO_NAMES_PRESENT |
| 95 | Предбоевое состояние/подготовка | UnitAffectingCombat('player'); IsInInstance; precombat state | `UnitAffectingCombat` | ALL_NAMES_PRESENT |
| 96 | Защитная ветка вне обычного DPS | UnitAffectingCombat; UnitHealthPercent; UnitThreatSituation | — | NEEDS_MANUAL_REVIEW |
| 97 | Диапазон действия предмета | C_Item.IsItemInRange(itemID,unit) -> bool?; C_ActionBar.IsActionInRange(slot) -> bool? (distinct) | — | NO_NAMES_PRESENT |
| 98 | Статус видимости/доступности кнопки | GetActionInfo(slot) — Blizzard FrameXML confirmed; C_ActionBar.HasAction(slot); C_ActionBar.IsUsableAction(slot); visible button state | `GetActionInfo`, `C_ActionBar.HasAction` | SOME_NAMES_PRESENT |
| 99 | Наличие питомца в контексте классового профиля | UnitExists('pet'); UnitIsDeadOrGhost('pet'); UnitCanAssist | `UnitExists`, `UnitIsDeadOrGhost` | ALL_NAMES_PRESENT |
| 100 | Определение цели-игрока и классификации | UnitIsPlayer(unit); UnitClassification(unit); UnitCreatureType(unit) | — | NO_NAMES_PRESENT |
| 101 | Различие combat lockdown и actual combat | InCombatLockdown(); UnitAffectingCombat('player') — two distinct globals; Blizzard RestrictedActionsDocumentation.lua confirms InCombatLockdown | `InCombatLockdown`, `UnitAffectingCombat` | ALL_NAMES_PRESENT |

## Технические конфликты, нуждающиеся в переработке

1. **Не реализован единый GameData:** `GameState` предоставляет низкоуровневые записи, а часть существующих Hunter-профилей использует собственные именованные поля и `Next(state,options)`; `RotationEngine` пока принимает только зарегистрированные числовые Spell ID. Обязателен **единый новый контракт**, не временный runtime-адаптер старых ротаций. Профили переводятся на этот контракт позже без сознательного изменения стратегии.
2. **Spell cooldown/GCD:** v14 № 11, 25, 26, 83 требует аккуратной оценки `isActive/isOnGCD` и защищённых значений. Порядок проверок и формат modern/legacy ответов должен быть предметом отдельной регрессии; случайные legacy fallbacks не добавлять молча.
3. **Здоровье/ресурсы:** № 3–6, 41, 49–53; Lua numeric от Secret/Curve не гарантирован, неизвестное нельзя заменять на 0/false.
4. **Spellbook и специализация:** № 19–20, 29, 74–75, 81–82. Различать Vanilla дерево, ClassTalents, известность и ранг. Ни одна лишь запись книги, ни `index` не доказывают всё содержимое способностей.
5. **Hunter BM:** № 24, 30, 58, 70–71, 77, 87, 99 требуют подтверждённых pet/Auto Shot/ammo/swing сигналов до пилотной интеграции.
6. **Slot/binding:** № 32–33, 98. Проверять отдельное соответствие видимой кнопки, актуального слота, action type, Spell ID, binding-command; не читать чужой protected frame без secret guards.
7. **Контекст и угроза:** № 14, 16–18, 71–72, 78, 92, 95–96. Visible nameplates != все противники; combat lockdown != actual combat; отсутствие threat данных != безопасно.
8. **EventBus/UI:** инвалидация отдельных доменов; diagnostic observation hooks только с минимальными издержками. Девелоперский логгер — **отдельный** `KordRotationDevTools`, не интерфейс пользовательского аддона, в соответствии с [BUILD_VARIANTS_AND_DIAGNOSTICS.md](../BUILD_VARIANTS_AND_DIAGNOSTICS.md).

## Сравнение референсов и дальнейший план

- **Sonah** `Core/Atoms/Spells.lua` — `C_Spell.GetSpellCooldown` и `Secret.Field` для отдельных полей, `C_Spell.IsSpellUsable`, осторожный `IsSpellInRange`; явно не обещает числовое значение Secret.
- **MaxDps** `SpellData.lua` и другие модули дают классовое применение, но не меняют выбранных v14 API без новой проверки.
- **JustAC** `BlizzardAPI/SpellQuery.lua` — cooldown/GCD и отдельный fail-open option; для Kord нельзя активировать fail-open в опасных случаях.
- **ForeverAuras/ForeverRotation/RotationGuide** — источники сравнительных идей, не замена канонической v14.
- Все 101 строки v14 сохраняют свои исходные статусы, без выдуманных CLIENT PASS.

**После данного коммита:** 2.8.2 — реализовать безопасное чтение утверждённых API и нормализованный GameData, тесты nil/secret/error, затем 2.8.3–2.8.6. Следующая публикация отделена от аудита, чтобы можно было сравнить старые и новые контракты.
