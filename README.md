# Project PAW

Средневековая конверсия **Project Zomboid Build 42.21.0**: нет электросети, автомобилей и
патронного огнестрела, вместо них — пороховое оружие и ремесленная экономика.

> Статус: **исследование и проектирование**. Собран инвентарь механик, план удаления и
> каркас мода. Игровой контент ещё не написан, мод не предназначен для игры.

Репозиторий: `https://github.com/aga7on/Project-PAW`

---

## Команда

| Участник | Зона | Ветки |
|---|---|---|
| **Артём** (`@aga7on`) | Удаление современного, инфраструктура, релизы | `artem/*`, `infra/*` |
| **Влад** | Карта, сюжет, мир | `vlad/*` |
| **Андрей** | Механики, баланс, прогрессия | `andrey/*` |

Зоны, горячие точки и журнал решений — [`docs/07-teamwork.md`](docs/07-teamwork.md).
Личные брифинги — [`docs/team/`](docs/team/artem.md).

**Перед первой правкой прочитайте:**

1. [`AGENTS.md`](AGENTS.md) — правила для ИИ-агентов: зоны, запреты, проверки, формат отчёта.
2. [`CONTRIBUTING.md`](CONTRIBUTING.md) — процесс для людей: ветки, коммиты, ревью, тесты.
3. [`docs/07-teamwork.md`](docs/07-teamwork.md) — кто чем владеет и как принимаются решения.
4. Свой брифинг: [`docs/team/artem.md`](docs/team/artem.md),
   [`docs/team/vlad.md`](docs/team/vlad.md), [`docs/team/andrey.md`](docs/team/andrey.md).

Коротко: работаем в ветке `<зона>/<имя>`, в `main` напрямую не пушим, один PR — одна зона,
перед PR запускаем `python tools/validate_mod.py`.

---

## Структура

```
ProjectPAW/                  папка мода (её видит игра)
  mod.info                   метаданные мода
  poster.png                 картинка в меню модов
  media/
    lua/shared/ProjectPAW/   общий код: удаление, сюжет, утилиты
    lua/shared/Sandbox/      пресет песочницы
    lua/client/ProjectPAW/   клиентский код
    lua/server/ProjectPAW/   серверный код, мир
    scripts/ProjectPAW/      .txt скрипты: items, recipes, characters
    textures/ProjectPAW/     текстуры
    models/ProjectPAW/       модели
    sound/ProjectPAW/        звуки
    maps/                    карты (пока нет)
    ui/                      элементы интерфейса
docs/                        исследование, в Workshop не уходит
  team/                      брифинги участников
  world/                     карта и сюжет (Влад)
  balance/                   баланс (Андрей)
  data/                      выгрузка данных игры (генерируется)
tools/                       extract_game_data.py, validate_mod.py
.github/                     шаблоны PR/issue, CODEOWNERS, CI
sync.ps1                     pull/push для локальной копии
site/                        сайт-визитка (Next.js), к моду отношения не имеет, в git не входит
```

`docs/` и `tools/` лежат рядом с папкой мода, а не внутри неё, поэтому в пакет Workshop
не попадают.

Пустые папки держатся в репозитории файлами `.gitkeep` — удаляй их, когда положишь туда
реальные файлы.

---

## Быстрый старт

1. Клонировать репозиторий в любое удобное место:

   ```powershell
   git clone https://github.com/aga7on/Project-PAW.git
   cd Project-PAW
   ```

2. Подключить мод к игре символической ссылкой (junction), чтобы править файлы прямо
   в репозитории:

   ```powershell
   New-Item -ItemType Junction -Path "$env:USERPROFILE\Zomboid\mods\ProjectPAW" `
     -Target "C:\путь\к\Project-PAW\ProjectPAW"
   ```

   Альтернатива — скопировать `ProjectPAW` в `%USERPROFILE%\Zomboid\mods\`.
   **Не держите копию и junction одновременно**: у них одинаковый `id`, и загрузчик
   возьмёт случайный.

3. Проверить, что всё на месте:

   ```powershell
   python tools/validate_mod.py
   ```

4. В игре: главное меню → **Mods** → включить `Project PAW` → перезапустить игру.
   Логи: `%USERPROFILE%\Zomboid\console.txt`.

Требования: Python 3.10+ для `tools/`. Игра — для ручных тестов.

Пересобрать выгрузку данных игры (нужна установленная игра):

```powershell
python tools/extract_game_data.py "G:/SteamLibrary/steamapps/common/ProjectZomboid"
```

Файлы в `docs/data/` руками не правятся — только перегенерацией.

---

## Git

Короткий путь — скрипт `sync.ps1` в корне репозитория:

```powershell
.\sync.ps1 status              # что изменено и последние коммиты
.\sync.ps1 pull                # забрать свежие файлы из GitHub
.\sync.ps1 push "что сделал"   # закоммитить изменения и отправить ветку
```

`sync.ps1 push` **не пушит в `main`**: скрипт создаёт рабочую ветку и отправляет её,
дальше — PR. Прямой push в `main` запрещён branch protection.

Вручную то же самое:

```powershell
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

Ветка по умолчанию — `main`. Вход в GitHub уже сохранён в Git Credential Manager,
пароль спрашивать не будет.

---

## Документы

| Документ | Что внутри |
|---|---|
| [`docs/00-index.md`](docs/00-index.md) | Карта документов и главные выводы |
| [`docs/01-mechanics-inventory.md`](docs/01-mechanics-inventory.md) | Все механики игры с вердиктом по каждой |
| [`docs/02-modern-systems-removal.md`](docs/02-modern-systems-removal.md) | План удаления современного мира |
| [`docs/03-blackpowder-firearms.md`](docs/03-blackpowder-firearms.md) | Дизайн порохового оружия |
| [`docs/04-mod-architecture.md`](docs/04-mod-architecture.md) | Структура мода и загрузка |
| [`docs/05-data-report.md`](docs/05-data-report.md) | Откуда числа и как их проверить |
| [`docs/06-roadmap.md`](docs/06-roadmap.md) | Этапы работ и оценки |
| [`docs/07-teamwork.md`](docs/07-teamwork.md) | Командный процесс, зоны, журнал решений |

Начните с [`docs/00-index.md`](docs/00-index.md).
