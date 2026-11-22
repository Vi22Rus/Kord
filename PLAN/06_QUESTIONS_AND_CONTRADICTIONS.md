# 6. Вопросы и противоречия

Цитаты не разрешаются автором плана.

## PL-01

> 1. Определить раздельные тристейтные поля `player.exists`, `player.alive`, `player.dead`, `player.ghost` и категории `player.cc.stun`, `player.cc.fear`, `player.cc.charm` (при необходимости другие CC); уточнить, какие из них реально наблюдаемы в целевом клиенте. Не выводить `ghost=false` из одного `UnitIsDeadOrGhost=false` без явной формальной модели.

## PL-13

> - [`KordRotation/Core/GameAPI.lua`](KordRotation/Core/GameAPI.lua): чтения `C_Traits` выполняются в `Talents.lua` через собственный `guarded(pcall)`, а не через канонический `GameAPI`; это противоречит PR-06 и не обеспечивает унифицированный secret-guard для полей таблиц.

## SP-01

> 2. Добавить `SpellKnowledgeObservation` с `spellID`, `known`, `source`, `status/reason`, `player/pet bank`, `rank/override` (когда подтверждены). При противоречии источников не выдавать ложный `BLOCKED`.

## PE-03

> 2. Исправить/уточнить семантику `pet.attackingTarget` в GameState/RotationConditions: фактически это `pettarget == target`, не подтверждённая атака; обеспечить совместимость профилей.

## SW-01

> 2. Переиспользовать существующий `GameState.ReadAutoShot`, уточнить его семантику; добавить Attack/Wand без отдельного сканера и совместимость `autoShot.active`.

## AC-07

> 5. Уточнить, может ли необязательная визуальная metadata приводить к UNKNOWN после READY; не маскировать отсутствие иконки под отсутствие пригодного действия.

> - `KordRotation/Core/RotationConditions.lua:232–242`: `methods:all(...)` получает функции, вызывает последовательно, прекращает при `false` (стр. 238), **но также немедленно возвращает `nil` на первой UNKNOWN (стр. 239)**. Это противоречит строгой трёхзначной семантике: `all(nil, function() return false end)` сейчас возвращает nil вместо false.

## UI-03

> 2. В `RotationProfiles` расширить валидацию **необязательных** `group/order/tooltip/visibleWhen/enabledWhen`, если они нужны; значения и ссылки должны быть data-only, без функций из SavedVariables. Уточнить `schemaRevision`/fingerprint и immutable registration snapshot; не менять контракт профиля без version bump.

## CL-01

> 7. Уточнить target health threshold и spell-specific range policies для Execute, Charge и Intercept; без жёстко вшитых значений без evidence.

## CL-07

> | «Превосходство» | **НЕРАЗРЕШЁННЫЙ ТЕРМИН**: точное русское название, spellID, spell family и эффект не подтверждены | запрещено автоматически подменять на Arcane Power, Presence of Mind, Combustion или иной cooldown; добавить `catalog_alias_unresolved`, STOP для зависящего правила до проверки spellbook и уточнения смысла |

> | «Зачарование» | **НЕРАЗРЕШЁННЫЙ ТЕРМИН**: spell/item/enchant effect необходимо установить по WoW Forever | не выдумывать mage weapon enchant; если речь о создаваемых предметах — ItemCreationProvider, если об ауре — AuraStateProvider, если об equipment enchant — WeaponEnchantProvider из IT-10; до определения никакого фиктивного READY |

> 1. Сверить по WoW Forever spell/rank/family catalog и уточнить «превосходство», «зачарование», «подкрепление маны» без догадок.

## CL-09

> 8. Уточнить пользовательский термин «срыв ауры» по игровому эффекту; до этого сохранить unresolved alias и запрет protected automatic cancel. Отдельно проверять форму, self buff и channel.

## NO-04

> 4. Уточнить schema `DecisionObservationEnvelope` совместно с QA-02/NO-03, зафиксировать `NOT_EVALUATED` для непрочитанных условий; отсутствие данных — `UNKNOWN`, не дополнительная проверка.

