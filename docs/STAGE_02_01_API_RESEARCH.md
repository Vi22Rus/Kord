# STAGE 02.1 — инвентаризация API, референсов и контрактов Kord Rotation

**Дата:** 2026-11-20. **Основа:** `main` @ `521473edccd8a431f91381b60828278be9e596cc`. **Статус:** исследование исходников выполнено; подтверждение API в WoW Forever — NOT RUN. **Применение:** входные требования к шагам 2.2–2.12, не реализация боевого движка.

## 1. Что реально существует в Kord Rotation

| Модуль | Сейчас | Что потребуется в этапе 2 |
|---|---|---|
| `Core/Character.lua` | `UnitClass`, `UnitLevel` с `pcall`, статус класса | общий контракт неизвестных данных, snapshot |
| `Core/Talents.lua`, `Core/SpecDetector.lua` | чтение `C_Traits`, вычисление дерева; пространственный fallback предварителен | инвалидация и проверка действительной ветки, запрещено угадывать |
| `Core/SpellCatalogue.lua` | чтение книги по `GetNumSpellTabs`, `GetSpellBookItemInfo`; ID, имя, текстура | ранги, защита от устаревания, разные варианты spellbook API |
| `Core/RotationSettings.lua` | настройки классов/деревьев и поле `keyLabel` (ручное) | не путать с системным биндингом; использовать как отдельное предпочтение |
| `Core/Diagnostics.lua` | наличие некоторых API, кольцевой лог из 80 записей | capability matrix по реальному результату, причины UNKNOWN |
| `Core/SafeActions.lua` | очередь отложенных защищённых UI-действий | не использовать для автокаста; проверить включение в .toc |
| `UI/RotationDisplay.lua`, `UI/SpellIcon.lua` | тестовые иконки; `SetSlotData`/`SetDisplayData`, визуальное поле `keybind` | только проверенный provider; `nil` очищает данные; отдельный режим работы |
| `Init.lua` | события загрузки/талантов/уровня; версия `0.1.8.2-rc5` | будущая шина событий с ограничением частоты |
| `KordRotation.toc` | `Interface: 16001`; `Version: 0.1.7.8-rc1` | синхронизировать версию и список загрузки до игры |

**Выявленные конкретные дефекты интеграции для исправления до/в 2.2:** в `.toc` отсутствуют `Core/SafeActions.lua` и `UI/MinimapButton.lua` при существующих ссылках на них; `Init.lua` и `.toc` имеют разные версии. Признак найден статически, фактическое влияние в клиенте не проверялось. `SpellCatalogue` требует функции старого spellbook API и при их отсутствии возвращает `unavailable`; совместимость с реальным Forever ещё не проверена.

## 2. Исследование референсов (архивы проекта)

| Референс, просмотренный файл | Наблюдение из исходников | Решение для Kord |
|---|---|---|
| Sonah: `Core/Atoms/ActionSlots.lua` | `C_ActionBar.HasAction` с fallback `HasAction`, `GetActionInfo`, optional `FindSpellActionButtons`, проверка secret | тонкий адаптер слотов, feature detection, неизвестное не равно false |
| JustAC: `ActionBarScanner.lua` | отдельный scanner, `GetBindingKey`, кэши хоткеев, инвалидация при изменении назначений | отделить `ActionBarScanner` от `BindingResolver`; данные из слота не выводить из книги |
| JustAC: `BlizzardAPI/StateHelpers.lua` | изоляция сложных игровых проверок и power API | общий `GameState` возвращает статус/источник вместо «сырых» результатов |
| MaxDps: `Buttons.lua`, `Core.lua` | `HasAction`/`GetActionInfo`, перечисление кнопок и `ACTIONBAR_SLOT_CHANGED` | использовать события для dirty-флагов; не копировать привязку к сторонним action-bar библиотекам |
| ForeverRotation: `Engine.lua` | `C_Spell.GetSpellCooldown` и `UnitPower` с проверками | учитывать новый вариант cooldown API и границы доступности значений |
| RotationGuide: `Core/State.lua` | `C_SpellBook.GetSpellBookItemInfo`, `C_Spell.GetSpellCooldownDuration` | поддержать вариант нового spellbook API при его подтверждении |
| ForeverAuras: API/специализационные и rank-данные | большой фреймворк с отдельными данными и лицензиями | использовать как ориентир исследования, не импортировать базы без необходимости и соблюдения лицензий |

**Лицензии в архивах:** Sonah — permissive with name restriction; JustAC — GPLv3; MaxDps — all rights reserved; ForeverRotation — GPLv3; RotationGuide — MIT; ForeverAuras — GPLv2 с отдельными лицензиями на данные/ресурсы. **Ни один фрагмент кода или база заклинаний не переносились.** Сравнение ограничено архитектурой и публичными именами API.

## 3. Матрица возможностей — кандидаты, НЕ подтверждённые в игре

Обозначения: `SOURCE` — используется в текущем Kord; `REF` — встречается в изученных референсах; `DOC` — публичная документация WoW API; `GAME?` — обязательно проверить в конкретной версии клиента и во время боя. Наличие в REF или DOC **не доказывает** работу в WoW Forever.

| Данные | API / события-кандидаты | Источник | Риск / контракт при недоступности |
|---|---|---|---|
| Версия клиента | `GetBuildInfo` | SOURCE | журнал build/Interface; если nil — UNKNOWN |
| Класс/уровень | `UnitClass`, `UnitLevel`, `PLAYER_LEVEL_UP` | SOURCE | не угадывать класс |
| Дерево/таланты | `C_ClassTalents`, `C_Traits`, `C_SpecializationInfo`; `TRAIT_CONFIG_UPDATED`, `PLAYER_TALENT_UPDATE` | SOURCE | `provisional` не выдавать за подтверждение |
| Книга и ранги | `GetNumSpellTabs`, `GetSpellTabInfo`, `GetSpellBookItemInfo`, `GetSpellBookItemName`; `C_SpellBook.GetSpellBookItemInfo`; `SPELLS_CHANGED` | SOURCE/REF | неполная книга — UNKNOWN, не создавать синтетический каталог |
| Слоты Blizzard | `HasAction`/`C_ActionBar.HasAction`, `GetActionInfo`, `C_ActionBar.FindSpellActionButtons`; `ACTIONBAR_SLOT_CHANGED` | REF/DOC | сканировать только подтверждённый диапазон; отсутствие функции — UNKNOWN |
| Видимая панель/формы | `GetActionBarPage`, `GetBonusBarOffset`; `ACTIONBAR_PAGE_CHANGED`, `UPDATE_SHAPESHIFT_FORM` | REF/DOC | не считать slot на скрытой/неактивной странице активным без проверки |
| Макросы и предметы | `GetActionInfo`, `GetMacroInfo`, `UPDATE_MACROS` | REF/DOC | типы отдельно; не извлекать spell из произвольного текста макроса |
| Бинды | `GetBindingKey`, `GetBindingAction`, `UPDATE_BINDINGS` | SOURCE-probe/REF | неназначенная клавиша ≠ отсутствующий слот; инвалидировать кэш |
| Бой/цель/смерть | `InCombatLockdown`, `UnitAffectingCombat`, `UnitExists`, `UnitIsDeadOrGhost`; `PLAYER_REGEN_*`, `PLAYER_TARGET_CHANGED` | SOURCE | булево `nil` сохранять как UNKNOWN |
| Ресурсы | `UnitPower`, `UnitPowerMax`, enum типа ресурса; `UNIT_POWER_UPDATE` | REF | неизвестный тип/secret → UNKNOWN |
| Кулдауны/доступность | `C_Spell.GetSpellCooldown`, `GetSpellCooldown`, `IsUsableSpell`, `GetActionCooldown` | REF/DOC | не утверждать READY по одному только `GetSpellInfo` |
| Касты и каналы | `UnitCastingInfo`, `UnitChannelInfo`, `UNIT_SPELLCAST_*` | DOC | в отсутствие API состояние UNKNOWN |
| Ауры | `C_UnitAuras` или `UnitAura`, `UNIT_AURA` | DOC | неизвестная аура ≠ отсутствие ауры |
| Расстояние/валидность цели | `IsSpellInRange`, `IsActionInRange`, `UnitCanAttack` | DOC | неоднозначный return не использовать как `true` |

**Особые тесты клиента:** действие в бою и вне боя; secret/tainted значения, `pcall` и `issecretvalue` только если существует; ручная смена page/stance; несколько слотов; разные ранги; совпадающие имена; `GetActionInfo` для spell/macro/item; две привязки; controller vs keyboard; lua `nil` при защищённом чтении. Не обходить защищённые данные.

Публичные ориентиры (только документация, не подтверждение клиента):
- https://warcraft.wiki.gg/wiki/Events
- https://warcraft.wiki.gg/wiki/Category:API_systems/ActionBar
- https://wowpedia.fandom.com/wiki/API_GetActionInfo

## 4. Контракты данных между будущими модулями

В этапе 2.1 **только договорённости**, следующие типы ещё не реализованы.

### `ApiRead<T>`
```lua
{
    status = "READY" | "UNKNOWN" | "UNAVAILABLE" | "ERROR",
    value = nil,      -- заполнять только для READY
    source = "API name or module",
    reason = "stable_code",
    observedAt = nil, -- время чтения, если API подтверждён
}
```
Правила: не превращать ERROR/UNKNOWN в логическое false; не сохранять значения `secret` в SavedVariables или диагностику; тип и диапазон проверять на входе.

### `GameSnapshot`
```lua
{ status = "READY" | "UNKNOWN", revision = 0, observedAt = nil,
  player = {}, target = {}, combat = {}, resources = {},
  casting = {}, auras = {}, cooldowns = {} }
```
Поля внутри — `ApiRead` либо явно документированные подтверждённые значения. Вопрос `revision` и timestamps решается на 2.2–2.3, snapshot нельзя смешивать с тестовыми данными.

### `ActionSlotRecord` и `BindingRecord`
```lua
{ slot = 1, page = nil, actionType = "spell", spellID = nil,
  status = "READY", isActivePage = nil, source = "GetActionInfo",
  binding = {status = "READY", key = nil, alternateKey = nil,
             source = "GetBindingKey"} }
```
`spellID=nil` для macro/item или неустановленного типа — не основание для рекомендации. Отсутствие key разрешено при подтверждённой панели. Слоты/страницы проверяются отдельно; нельзя автоматически считать все 120 слотов видимыми.

### `RecommendationCandidate` и `RecommendationResult`
```lua
{ spellID = 0, priority = 0, category = "damage",
  ruleID = "fixture-or-profile-rule", conditions = {} }

{ status = "READY" | "EMPTY" | "UNKNOWN",
  entries = {}, rejected = {}, reason = nil }
```
Для каждой `entries[]` требуются подтверждённые `spellID`, разрешённый `actionSlot`, свежая `binding` (ключ может быть nil), прошедшие условия. Фильтр принимает упорядоченный список, пропускает недопущенное, возвращает EMPTY если всё отклонено. Боевых профилей в 2.1 нет; сценарии 2.8 создаются отдельно.

### `DisplayEntry`
```lua
{texture = nil, name = nil, keybind = nil, cooldownText = nil,
 charges = nil, unavailable = false, gcdActive = false}
```
Проецировать только из проверенного `RecommendationResult`; `keybind` уже поддерживается в `SpellIcon:SetDisplayData`. `SetSlotData(index, nil)` очищает изображение. Не возвращать устаревшие данные после изменения слота.

## 5. Решения о безопасности и архитектуре

1. Kord остаётся **визуальным советчиком**, не использует `CastSpellByID`, `UseAction`, `RunMacroText`, внешние каналы передачи или пиксели-команды.
2. Коды/обфускация не дают секретности в открытом Lua, потому что сам интерфейс показывает узнаваемые иконки и клавиши. Сосредоточиться на отсутствии отдельного RGB/machine-readable output и на минимуме служебных данных; нельзя обещать абсолютную невозможность стороннего распознавания экрана.
3. Разделить `GameAPI` (safe calls), `GameState`, `SpellCatalogue`, `ActionBarScanner`, `BindingResolver`, `Eligibility`, `CandidateFilter`, `RotationDisplay`. Новые модули подключать только в порядке .toc и только после проверки их существования.
4. Инвалидация по событиям предпочтительнее полного сканирования каждый кадр. Незнакомое событие нельзя без проверки считать зарегистрированным в Forever.
5. Никакой импорт чужих библиотек и баз; использовать только идеи организации модулей и общедоступные имена функций.
6. Все изменяемые элементы UI и индивидуальные подсказки — шесть языков. Технический контракт сам по себе не создаёт UI-строк.

## 6. Приёмка подэтапа 2.1 и очередь для 2.2

- **PASS — статически:** исследованы существующие Kord-модули и шесть референсных ZIP; оформлены сравнение, матрица кандидатов API, контракты и ограничения лицензий; выявлены несоответствия .toc и версий.
- **NOT RUN:** подтверждение какого-либо API именно в клиенте Forever, манекен, боевые значения, protected/secret, реальные бинды, живые ротации.
- **Следующий подэтап 2.2:** устранить дефекты загрузки/версии в рамках минимальной регрессии, создать `GameAPI` с явными статусами и безопасный диспетчер событий с throttling/dirty-flags; проверить сценарии отсутствия функций и невалидных возвращаемых значений. Если клиент не даёт API, оставить UNKNOWN/BLOCKED, не подменять вымыслом.
- **Итоговый игровой QA (накопительные кейсы):** вывести `GetBuildInfo`; проверить наличие/возвраты API по матрице, включая бой/вне боя; смену биндов, панели, формы, ранга, макросов и профиля; не требовать установки после 2.1.
