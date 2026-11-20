# Этап 2.2 — реализация слоя API и шины событий

Версия `0.1.8.3-rc1`, исходная ветка `main`. Игровая проверка не выполнялась.

## Контракт GameAPI

- `KR.GameAPI:Read("UnitExists", "boolean", "target")` возвращает `{status="READY", value=true|false, source, observedAt?}` только при подтверждённом API и типе.
- При отсутствии функции — `UNAVAILABLE/api_missing`; неизвестном, secret или ошибочном типе — `UNKNOWN`; при ошибке вызова — `ERROR/api_call_failed`. Ни один из статусов не переводится автоматически в usable=true.
- `ReadTuple(name, {"string","string"}, ...)` применяет валидацию к нескольким результатам; `Probe(name)` сообщает только о наличии функции, **не подтверждает успешное игровое чтение**.
- Белый список **только чтения** не включает `CastSpellByID`, `UseAction` и аналогичные функции. `issecretvalue` применяется только если существует; отсутствие этого метода не доказывает отсутствие защищённых полей — проверка в клиенте остаётся обязательной.

## Контракт EventBus

- `KR.EventBus:Subscribe("spellbook", "consumer-id", callback)`, `Unsubscribe(channel,token)`, `MarkDirty(channel)`, `Status()`.
- При событии `SPELLS_CHANGED` выставляется revision для `spellbook`; `ACTIONBAR_SLOT_CHANGED` — `actionbar`; `UPDATE_BINDINGS` — `bindings`; `PLAYER_TARGET_CHANGED` — `target`. События UNIT_* принимаются только для player/target.
- Вместо повторного API-сканирования на каждом событии подписчик уведомляется один раз за 0.20с; резервный heartbeat (2с) существует **только** при подписчике на `heartbeat`. Обработчик не считывает защищённые данные и ничего не рисует.
- `Initialize()` идемпотентен и вызывается после PLAYER_LOGIN; ошибки подписчиков изолированы `pcall`, диагностический спам ограничен.
- Ошибка регистрации события фиксируется в `Status().unregistered`. Успешный `RegisterEvent` не доказывает, что клиент реально отправит событие.

## Статические контрольные сценарии и итоговый игровой чек-лист

1. Отсутствует `UnitExists` -> UNAVAILABLE без value; `UnitExists` возвращает nil -> UNKNOWN; строку -> UNKNOWN; false -> READY/false; исключение -> ERROR.
2. NaN/бесконечность при числовом чтении -> UNKNOWN.
3. Secret-value при существующем `issecretvalue` -> UNKNOWN; не выводить значение в лог.
4. События UPDATE_BINDINGS/ACTIONBAR_SLOT_CHANGED/SPELLS_CHANGED сразу подряд -> один callback на канал за интервал, revision на каждое событие.
5. `UNIT_AURA` для постороннего unit не инвалидация; player/target — инвалидация.
6. Подписчик с исключением не блокирует другого подписчика; лог ограничен; после Unsubscribe не вызывается.
7. Повторная Initialize не создаёт второй frame; отсутствие CreateFrame возвращает false.
8. `SafeActions:Initialize` и `MinimapButton:Create` теперь доступны через `.toc`; отсутствие соответствующего API не вызывает скрытых действий.
9. В игре: фиксировать GetBuildInfo, проверять события вне/в бою; незарегистрированное событие/отсутствующее API должно оставаться UNKNOWN или UNAVAILABLE. **Эти сценарии в игре NOT RUN.**

План не обещает боевой движок после 2.2. Следующие шаги 2.3–2.9 создадут снимки, панели и фильтрацию.
