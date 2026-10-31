# Как работать в репозитории Project PAW

Документ для людей. Агентам — `AGENTS.md`.

## 1. Что это

Project PAW — средневековая конверсия Project Zomboid Build 42. Репозиторий содержит
мод в формате Workshop и исследовательские документы.

```
ProjectPAW/                    папка мода (её видит игра через junction)
  mod.info                     метаданные мода
  poster.png                   постер в меню модов
  media/                       скрипты, Lua, карты, ассеты
docs/                          исследование и решения
docs/data/                     выгрузка данных игры (генерируется)
docs/team/                     брифинги участников
tools/                         скрипты (извлечение данных, валидатор)
.github/                       шаблоны PR/issue, CODEOWNERS, CI
sync.ps1                       pull/push для локальной копии
```

## 2. Первая настройка

```bash
git clone https://github.com/aga7on/Project-PAW.git
cd Project-PAW
python tools/validate_mod.py
```

Игра должна видеть папку мода `ProjectPAW/`. Рекомендуемый способ — junction:

```powershell
New-Item -ItemType Junction -Path "$env:USERPROFILE\Zomboid\mods\ProjectPAW" `
  -Target "C:\путь\к\Project-PAW\ProjectPAW"
```

Альтернатива — скопировать `ProjectPAW` в `%USERPROFILE%\Zomboid\mods\`.
Но не держите копию и junction одновременно: у них одинаковый `id`, и загрузчик
возьмёт случайный.

Требования: Python 3.10+ для `tools/`. Игра — для ручных тестов.

## 3. Ежедневный цикл

```bash
git switch main
git pull --ff-only
git switch -c artem/short-name

# ... работа ...

python tools/validate_mod.py
git add -A
git commit -m "content: remove 9mm ammo and boxes"
git push -u origin artem/short-name
gh pr create --fill
```

Дальше — ревью владельцем зоны и squash-merge. Ветка удаляется.

### Правила веток

| Правило | Значение |
|---|---|
| База | всегда `main` |
| Имя | `<зона>/<краткое-имя>`: `artem/…`, `vlad/…`, `andrey/…`, `infra/…` |
| Жизнь | дни, не недели; большой объём дробится на PR |
| Мерж | squash, линейная история `main` |
| Прямой push в `main` | запрещён branch protection |

## 4. Ревью

- Автор не мержит свой PR сам, если есть доступный ревьюер.
- Ревьюер проверяет: зона соблюдена, валидатор зелёный, ручной тест описан,
  документы обновлены.
- Спорные технические решения фиксируются в журнале решений
  (`docs/07-teamwork.md`, раздел «Журнал решений»), а не только в чате.
- Комментарий «ок» без проверки — не ревью.

## 5. Конфликты

| Тип файла | Как решать |
|---|---|
| Текст, Lua, скрипты | обычный merge; при сомнении — переписать свою часть поверх свежего `main` |
| `docs/data/**` | не мержить вручную: взять версию из `main`, перегенерировать скриптом |
| Бинарники карты | взять версию владельца зоны, свои правки повторить поверх |
| `mod.info`, `workshop.txt` | правит только Артём |

Перед мержем PR ребейзится на свежий `main` (`git fetch && git rebase origin/main`),
конфликты решает автор PR.

## 6. Коммиты

```
<зона>: <краткое описание в повелительном наклонении>
```

Зоны: `content`, `map`, `story`, `balance`, `docs`, `infra`, `fix`.

Примеры:

```
content: mark modern firearms obsolete
balance: set food rot to 2 without fridge
map: add village blockout to test cell
docs: split roadmap by owner
```

Один коммит — одно намерение. «Ещё немного поправил» — плохой коммит.

## 7. Тестирование

Минимальный чек-лист перед PR с игровыми изменениями:

- [ ] Новый мир создан (не старое сохранение)
- [ ] Мод включён, в `console.txt` нет `ERROR` по `ProjectPAW`
- [ ] Проверено конкретное изменение (что именно — в PR)
- [ ] Проверено, что не сломано смежное (лут, рецепт, меню персонажа)
- [ ] В PR написано, что **не** проверено

## 8. Крупные файлы и карта

Git плохо хранит бинарники. Политика:

- Исходники карты (Lua, `.tmx`, раскладки, описания) — в git.
- Сгенерированные `*.pack`, `*.lotheader`, тайлы — **не** в git, а в релиз/Workshop.
- Файл > 10 МБ — только после решения команды (issue) и, при необходимости, Git LFS.

Валидатор и CI падают, если в коммите появился файл > 10 МБ.

## 9. Релизы

- Версия в `ProjectPAW/mod.info` (`modversion`) и тег `vX.Y.Z`.
- Релиз собирает Артём: проверка на чистом профиле, затем загрузка в Workshop.
- `docs/` и `tools/` в пакет Workshop не попадают (лежат рядом с `ProjectPAW/`, а не внутри).

## 10. Связь

- Задачи и баги — GitHub Issues (шаблоны в `.github/ISSUE_TEMPLATE/`).
- Решения — PR + журнал решений.
- Срочное — чат, но итог всё равно переносится в issue или журнал.
