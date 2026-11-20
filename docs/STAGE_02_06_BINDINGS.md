# Этап 2.6 — BindingResolver: реальные назначения клавиш

**Статус:** IMPLEMENTED / AWAITING IN-GAME QA. **Версия:** 0.1.8.3-rc7.
**Решение заказчика:** Sonah + JustAC + MaxDps; Blizzard, Bartender4, Dominos, ElvUI, EllesmereUI и уже загруженный LibActionButton; без новых обязательных библиотек.

## Источники и причины выбора

- Sonah `Core/Atoms/ActionSlots.lua:78–81`: `GetBindingKey(command)` и secret-guard для read-only биндов.
- MaxDps `SpellFrame.lua:227–248`: карта стандартных `ACTIONBUTTON` и `MULTIACTIONBAR`. Сама по себе slot→команда недостаточна для пользовательских панелей или dynamic page.
- JustAC `ActionBarScanner.lua:155–223,226–257,1160–1166`: две клавиши, отдельные команды LibActionButton через `GetBindingAction()`, инвалидация биндов.
- EllesmereUI `EllesmereUIActionBars/EUI_ActionBars_Secure.lua`: `BAR_SLOT_OFFSETS` и `BINDING_MAP`, команды для Bar9/Bar10. `EUI_ActionBars_Keybinds.lua:124–180,209–212`: привязки `GetBindingKey` и возможная смена native/click override при custom paging. Без достоверного API для проверки активного override-роутинга Kord намеренно не показывает якобы подтверждённую клавишу на перепривязанной странице.
- Остальные ForeverAuras, ForeverRotation, RotationGuide изучены как ориентиры API в `API_REFERENCE_MATRIX.md`; не предоставляют более проверяемой общей модели для назначенных клавиш. Никакой чужой код не копировался.

## Реализация

1. `Core/ActionBarScanner.lua`: `GetVerifiedButtons(spellID)` возвращает внутренние ссылки только на **повторно проверенные** видимые кнопки с правильным игровым slot и spellID. UI не получает frame references; при исчезновении кнопки ставится dirty.
2. `Core/BindingResolver.lua`: `Initialize()`, `Invalidate(reason)`, `Resolve(spellID)`. Для каждой подтверждённой кнопки определяется команда: `GetBindingAction()` → `GetAttribute("binding")` → проверенная команда Blizzard по реальному имени кнопки → схема `EABButton` с подтверждённым физическим слотом. Для сторонних кнопок без достоверной команды выдается UNKNOWN, даже если она выглядит стандартной.
3. `GameAPI:ReadValues("GetBindingKey", command)` читает до двух значений. `GameAPI:Read("GetBindingAction","string",key)` при существовании метода выполняет обратную проверку; если бинды переопределены и обратный путь не подтверждает команду, результат UNKNOWN. Методы `GetBindingKey`/`GetBindingAction` уже были в read-only allowlist.
4. Результаты: `READY` с `spellID`, `slot`, `command`, `source`, `bindingSource`, `keys=[{raw,label},...]`, `bindingLabel`, `observedAt`; `UNBOUND`, если есть подтверждённая кнопка и проверенные команды не имеют клавиш; `UNKNOWN` при отсутствующей/скрытой кнопке, защищённом API, неизвестной команде или неоднозначном override.
5. Формат подписи нейтрален для локализации: `SHIFT-`→`S+`, `CTRL-`→`C+`, `ALT-`→`A+`, `META-`→`M+`, `BUTTON4`→`M4`. Исходные raw keys не меняются. PAD/геймпад передаётся при достоверном API.
6. Несколько мест размещения spellID: преимущество подтверждённому связанному биндом действию, затем минимальному игровому слоту. Кэшируются **только** результаты `GetBindingKey` на 0,5 секунды; инвалидируются немедленно по revision `bindings`, `actionbar`, `identity`, `talents`, даже до EventBus.Flush. Кнопка всегда проверяется заново. `RotationSettings.keyLabel` ни для определения, ни для показа автоматических биндов не используется.

## Ограничения и границы этапа

- **Нет новой автоматической ротации и записи в реальную боевую панель**: `SpellIcon:SetDisplayData(data)` уже принимает `data.keybind`, а подключение данных к реальным рекомендациям относится к последующим этапам 2.7–3. Нельзя утверждать, что клавиши уже показываются на боевой панели.
- Не меняются бинды игрока, `SetBinding`/`SetOverrideBindingClick` и другие защищённые действия отсутствуют.
- Custom paging / secure click bindings внешних панелей могут быть недоступны для полной read-only проверки. В таких случаях `UNKNOWN` — сознательное требование безопасности. Не обещать полную поддержку всех версий UI-аддонов до игрового теста.
- `tests/stage_02_06_bindings.lua`: изолированные сценарии всех шести семейств, клавиш и модификаторов, двойного бинда, изменения биндов, обратной проверки, hidden, custom paging, секретных данных и игнорирования ручного keyLabel.
- Запуск Lua-тестов и игровой QA документируются раздельно; версия теста, сканера и Lua-интерпретатора должны быть подтверждены до заявления PASS.
- Приоритет следующего шага 2.7 — предварительное исследование референсов и отдельное согласование по правилу № 1.

## Выполненные автономные тесты и исправление тестового сценария

После публикации исходного коммита 2.6 проверена **байт-в-байт** локальная копия:
- `BindingResolver.lua` — Git blob `05ae933518e9417456946b32a31c3e6f0bc7e646`;
- `ActionBarScanner.lua` — Git blob `d3d8f6c8f0dd6b28078480b3f2943555e12cfa2c`;
- `tests/stage_02_06_bindings.lua` — Git blob `689f4aca23929ba4cd0a9e80ee34b9ae0cbeaba6` после корректировки теста.

`texlua tests/stage_02_06_bindings.lua` **PASS: 25 утверждений** с mock `GameAPI` / `EventBus`. Проверены основные семейства кнопок, модификаторы, два бинда, кнопка без бинда, события, обратная команда, отсутствие stale-подписей после TTL, неизвестный dynamic paging, секретные данные и запрет ручного `keyLabel`.

`texlua tests/stage_02_05_actionbar.lua` **PASS:** регрессия сканера с теми же локальными mock API. `texluac -p` для нового `BindingResolver.lua`, изменённого `ActionBarScanner.lua` и теста 2.6 — **PASS**.

**Первичная ошибка самого теста:** подмена `GetBindingAction` без события и без истечения TTL вызывала ожидаемое сохранение уже проверенной записи; тест ошибочно ожидал немедленное новое чтение. Исправленный тест отдельно ожидает сохранённое значение до TTL и пересчитывает результат после `time=time+1`. Продуктовый Lua-код для этого менять не потребовалось.

**NOT RUN:** загрузка с фактическими `Core/GameAPI.lua` и `Core/EventBus.lua` вместо mock; полная проверка 27 профилей; WoW Forever и установленный сторонний UI; профилирование FPS/RAM. Игровой QA не объявлен пройденным.
