# Ability Catalogue — общая схема для 9 классов

**Не подменяет** `Core/SpellCatalogue.lua`: существующий модуль читает реальную книгу заклинаний; этот документ хранит **исследованные** свойства и соответствие логических ключей реальным spellID/рангам.

| Class | Spec applicability | Canonical key | Kind spell/command | SpellID/ranks | Learned level | Talent/rune | Resource/cost | CD/shared CD | GCD/cast/channel | Range/dead zone | Target/conditions | Aura/proc/TTD | Autoattack interaction | Source/version | In-game verification | Status |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| HUNTER | BM/MM/SV (verify) | AimedShot (candidate) | spell | TODO | TODO | TODO | TODO | TODO | TODO | TODO | TODO | TODO | TODO | TODO | NO | UNVERIFIED |
| HUNTER | BM (verify) | SummonHawk (candidate) | spell | TODO | TODO | TODO | TODO | TODO | TODO | TODO | TODO | TODO | TODO | TODO | NO | UNVERIFIED |
| HUNTER | BM/MM/SV | PetAttack (candidate) | command | N/A: verify actual command identity | TODO | TODO | TODO | TODO | TODO | TODO | target/pet required | TODO | TODO | TODO | NO | UNVERIFIED |

**Запрет:** не заполнять SpellID, ранги, стоимость, уровни и тайминги догадками из обычного WoW. Для каждого значения нужны версия WoW Forever, ссылка/референс, статус и способ игровой проверки. Действия-команды питомцу не притворяются заклинаниями.

## Для каждого нового класса
Заполнить все релевантные способности; отделить общие классовые способности от уникальных спековых; проверить пассивные таланты/руны, ресурсы, касты, реактивные окна, позиции, дальность, threat, взаимодействия с автоатакой. Не создавать новый Lua-каталог без необходимости: сначала расширять существующий источник идентичностей.


## Hunter BM/MM/SV — исследование 2026-11-21

Подробный реестр по шести PVE-профилям Hunter, включая подтверждённые исходники, буквальные spellID, несовместимые поля, источники, открытые конфликты и тест-кейсы: [Hunter_Research_2026-11-21.md](Hunter_Research_2026-11-21.md). **SOURCE REVIEWED / WEB PARTIAL / IN-GAME NOT RUN**. Не переносить неизвестные свойства в рабочие таблицы как подтверждённые. Для полного заполнения этой таблицы требуются дополнительные проверки клиента и адаптера.
