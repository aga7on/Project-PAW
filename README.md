# Project PAW

Средневековый мод для **Project Zomboid** (Build 42). Рабочее состояние — скелет проекта.

## Что это

Полная переработка под средневековье: оружие, броня, предметы, профессии, карта, механики.
Пока в репозитории только структура папок и `mod.info` — наполнение идёт по мере разработки.

## Структура

```
ProjectPAW/                  папка мода (её видит игра)
  mod.info                   метаданные мода
  poster.png                 картинка в меню модов
  media/
    lua/shared/ProjectPAW/   общий код (виден клиенту и серверу)
    lua/client/ProjectPAW/   клиентский код
    lua/server/ProjectPAW/   серверный код
    scripts/ProjectPAW/      .txt скрипты предметов и рецептов
    textures/ProjectPAW/     текстуры
    models/ProjectPAW/       модели
    sound/ProjectPAW/        звуки
    ui/                      элементы интерфейса
site/                        сайт-визитка (Next.js), к моду отношения не имеет, в git не входит
```

Пустые папки держатся в репозитории файлами `.gitkeep` — удаляй их, когда положишь туда реальные файлы.

## Разработка

Мод подключается к игре символической ссылкой (junction), поэтому править файлы можно прямо в этом репозитории:

```powershell
New-Item -ItemType Junction -Path "$env:USERPROFILE\Zomboid\mods\ProjectPAW" -Target "W:\VD-Project\ProjectPAW"
```

После правок в игре: главное меню → **Mods** → включить `Project PAW` → перезапустить игру.
Логи: `%USERPROFILE%\Zomboid\console.txt`.

## Git

Короткий путь — скрипт `sync.ps1` в корне репозитория:

```powershell
.\sync.ps1 status              # что изменено и последние коммиты
.\sync.ps1 pull                # забрать свежие файлы из GitHub
.\sync.ps1 push "что сделал"   # закоммитить все изменения и отправить на GitHub
```

Вручную то же самое:

```powershell
git pull            # забрать свежие файлы из GitHub
git add -A
git commit -m "..." # зафиксировать изменения
git push            # отправить на GitHub
```

Ветка по умолчанию — `main`. Вход в GitHub уже сохранён в Git Credential Manager, пароль спрашивать не будет.
