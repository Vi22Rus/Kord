# Configuration Registry — единый контракт настроек

| Scope | Key | Type | Default | Allowed values / min..max | Meaning / strategy evidence | Consumer | UI group | Locale label key | Locale tooltip key | Migration | Test | Status |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Hunter shared | TODO | bool/enum/number | TODO | TODO | TODO | Hunter_Common | TODO | TODO | TODO | TODO | TODO | UNDEFINED |
| Hunter BM | feign_hp (existing, verify canonical name) | number | 30 in current BM source | 0..100 (proposed) | solo threshold, agreed policy | BM profiles / shared policy | survival | TODO | TODO | TODO | TODO | NEEDS VALIDATION |

- Общие настройки определяются **один раз** и используются всеми соответствующими профилями.
- Каждый ключ должен иметь потребителя; тип, enum, диапазоны и default валидируются централизованно; неверные SavedVariables не должны ломать Next.
- Локализация: `ruRU/enUS/frFR/deDE/ptBR/esES` для label/tooltip, fallback проверять. Не создавать фиктивные переводы или UI-поля.
- Нельзя мутировать входные `options` или общие таблицы значений. `Next(state, options)` — чистая функция.
- Отдельно фиксировать миграции при переименовании ключей и конфликте настроек.
- Новые классы используют этот же реестр; не создавать девять разрозненных схем без необходимости.


## Hunter BM/MM/SV — исследование 2026-11-21

Подробный реестр по шести PVE-профилям Hunter, включая подтверждённые исходники, буквальные spellID, несовместимые поля, источники, открытые конфликты и тест-кейсы: [Hunter_Research_2026-11-21.md](Hunter_Research_2026-11-21.md). **SOURCE REVIEWED / WEB PARTIAL / IN-GAME NOT RUN**. Не переносить неизвестные свойства в рабочие таблицы как подтверждённые. Для полного заполнения этой таблицы требуются дополнительные проверки клиента и адаптера.
