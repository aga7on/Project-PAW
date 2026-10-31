# Брифинг: Артём (`@aga7on`)

Роль: удаление современного мира, инфраструктура репозитория, релизы.
Ветки: `artem/*`, `infra/*`.

## Зона

| Путь | Что |
|---|---|
| `ProjectPAW/media/scripts/ProjectPAW/items/` | предметы: удаление и замена |
| `ProjectPAW/media/scripts/ProjectPAW/recipes/` | рецепты |
| `ProjectPAW/media/lua/shared/ProjectPAW/PZM_Removal.lua` | флаги и логика удаления |
| `ProjectPAW/media/lua/client/ProjectPAW/` | UI стрельбы и перезарядки |
| `ProjectPAW/media/textures/ProjectPAW/` | иконки, которые добавляешь ты |
| `.github/`, `tools/`, `docs/00`–`07` | инфраструктура и документация |
| `mod.info`, `workshop.txt` | метаданные и публикация |

## Текущие задачи

1. **Блокирующий тест:** `Obsolete = true` на `Base.Pistol` в новом мире.
   Проверить: предмет не спавнится, отсутствует в отладочном списке, рецепты с ним
   не падают. Результат — в `docs/02`, раздел 0.
2. После теста — пачка удаления: 20 стволов, 6 магазинов, 9 патронов, 30 коробок,
   11 обвесов (76 предметов).
3. Электрика и электроника: 63 кандидата, 29 рецептов, батарейки, приборы.
4. Запчасти машин: 105 предметов `VehicleMaintenance`.
5. Радио, ТВ, кассеты, будильники.
6. Пороховое оружие: скрипты, `ISReloadMuzzleloader`, рецепты пороха (числа — Андрей).

## Не трогать

- `media/maps/**` — Влад.
- `media/lua/server/**` — Влад.
- `media/scripts/characters/**` — Андрей.
- `media/lua/shared/Sandbox/**` — Андрей. Свои значения передавай issue, не правь файл.
- `docs/world/**`, `docs/balance/**` — соответствующие владельцы.

## Первые шаги в репозитории

```bash
git switch main && git pull --ff-only
git switch -c artem/obsolete-smoke-test
# добавить item Pistol { Obsolete = true } в media/scripts/items/
python tools/validate_mod.py
```

Тест в игре: новый мир, отладочное меню предметов, поиск `Pistol`.

## Полезное

- `docs/02-modern-systems-removal.md` — что и чем вырезать.
- `docs/05-data-report.md` — откуда числа.
- `tools/extract_game_data.py` — перегенерировать `docs/data/`.
- `docs/03-blackpowder-firearms.md` — дизайн замены огнестрела.
