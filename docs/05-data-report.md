# 05 — Отчёт по данным

## 1. Методика

Источник — **файлы установленной игры**, а не вики и не датамайны третьих лиц.
Это важно: числа ниже проверяемы и обновляемы при выходе новой версии.

- Игра: `G:\SteamLibrary\steamapps\common\ProjectZomboid`
- Версия: **42.21.0** (стабильная; pre-release на момент исследования — 42.22.0)
- Скрипт: `tools/extract_game_data.py`
- Выход: `docs/data/`

Запуск:

```
python tools/extract_game_data.py "G:/SteamLibrary/steamapps/common/ProjectZomboid"
```

Скрипт **только читает** игру. Ничего не пишет в каталог установки.

## 2. Что парсится

| Источник | Что извлекается |
|---|---|
| `media/scripts/generated/items/*.txt` | 15 файлов, все блоки `item` |
| `media/scripts/generated/recipes/*.txt` | все блоки `craftRecipe` |
| `media/scripts/generated/vehicles/**/*.txt` | блоки `vehicle` и `template vehicle` |
| `media/lua/shared/Translate/EN/UI.json` | названия профессий, трейтов |
| `media/lua/shared/Translate/EN/Sandbox.json` | названия и подсказки опций песочницы |
| `media/scripts/generated/characters/character_professions.txt` | определения профессий |
| `media/scripts/generated/characters/character_traits.txt` | определения трейтов |

## 3. Точные числа

### 3.1 Предметы

| Показатель | Значение |
|---|---:|
| Определений предметов | **5 105** |
| Из них `base:clothing` | 1 395 |
| `base:normal` | 1 099 |
| `base:food` | 722 |
| `base:literature` | 561 |
| `base:weapon` | 409 |
| `base:moveable` | 393 |
| `base:container` | 308 |
| `base:drainable` | 150 |
| `base:radio` | 17 |
| `base:alarmclockclothing` | 16 |
| `base:map` | 15 |
| `base:weaponpart` | 11 |
| `base:key` | 6 |
| `base:alarmclock` | 2 |
| `base:animal` | 1 |

По файлам:

| Файл | Предметов |
|---|---:|
| `clothing.txt` | 1 395 |
| `normal.txt` | 1 099 |
| `food.txt` | 722 |
| `literature.txt` | 561 |
| `weapon.txt` | 409 |
| `moveable.txt` | 393 |
| `container.txt` | 308 |
| `drainable.txt` | 150 |
| `radio.txt` | 17 |
| `alarmclockclothing.txt` | 16 |
| `map.txt` | 15 |
| `weaponpart.txt` | 11 |
| `key.txt` | 6 |
| `alarmclock.txt` | 2 |
| `animal.txt` | 1 |

Самый частый тег — `base:hasmetal` (930 предметов), затем `base:ignorezombiedensity` (680).

### 3.2 Рецепты

**623** рецепта `craftRecipe`. По категориям:

| Категория | Кол-во | | Категория | Кол-во |
|---|---:|---|---|---:|
| Tailoring | 183 | | Metalworking | 19 |
| Cooking | 86 | | Assembly | 16 |
| Miscellaneous | 50 | | Repair | 14 |
| Carving | 47 | | Farming | 13 |
| Weaponry | 42 | | Knapping | 11 |
| Packing | 32 | | Glassmaking | 8 |
| Electrical | 29 | | Medical | 8 |
| Carpentry | 28 | | Fishing | 6 |
| | | | Pottery | 5 |
| | | | Masonry | 3 |

### 3.3 Транспорт

| Показатель | Значение |
|---|---:|
| Определений `vehicle` | **241** |
| Шаблонов `template vehicle` | 77 |
| Сгоревших и разбитых | 84 |
| Файлов скриптов машин | 139 |

### 3.4 Огнестрел

| Показатель | Значение |
|---|---:|
| Всего записей | **28** |
| Оружие | 22 |
| Магазины | 6 |
| Типов патронов (предметы) | 9 |
| Зарегистрированных типов боеприпасов (`AmmoType`) | 10 |
| Обвесов (`weaponpart.txt`) | 11 |
| Коробок патронов (`base:ammo` в `container.txt`) | 30 |

Список типов боеприпасов (жёстко зашит в Java, см. `03`):
`bullets_3030`, `bullets_308`, `bullets_357`, `bullets_38`, `bullets_44`,
`bullets_45`, `bullets_556`, `bullets_9mm`, `cap_gun_cap`, `shotgun_shells`.

### 3.5 Персонажи

| Показатель | Значение | Комментарий |
|---|---:|---|
| Определений профессий | **25** | `character_professions.txt` |
| Ключей `UI_prof_*` в UI.json | 27 | включает дубли (`Metalworker`/`MetalWorker`) |
| Определений трейтов | **97** | `character_traits.txt` |
| Ключей `UI_trait_*` в UI.json | 173 | включает `*Desc`-ключи: 97 имён + 76 описаний |

### 3.6 Электрика и современный лут

| Показатель | Значение |
|---|---:|
| Предметов категории `Electronics` | 43 |
| Предметов категории `Communications` | 16 |
| Кандидатов в «электрические» (теги + категории) | 63 |
| Предметов с тегом `base:usesbattery` | 16 |
| Предметов с тегом `cookablemicrowave` | 29 |
| Предметов категории `VehicleMaintenance` | 105 |
| Рецептов категории `Electrical` | 29 |
| Рецептов в `recipes_electrical.txt` | 9 |

### 3.7 Карта

| Карта | Ячеек | Файлов | Размер |
|---|---:|---:|---:|
| Muldraugh, KY | 4 065 | 17 126 | 4 286.7 МБ |
| challengemaps | 47 | 169 | 30.7 МБ |
| Остальные 10 | 0 | 3 каждая | 0.1 МБ каждая |

Только Малдро содержит реальные данные. Остальные каталоги — заглушки.

## 4. Исправления предыдущих оценок

При уточнении данных три числа изменились. Ниже — что было, что стало и почему.

| Показатель | Было | Стало | Причина |
|---|---:|---:|---|
| Трейты | 173 | **97** | 173 — это ключи `UI_trait_*`, включая описания. Реальных определений 97 |
| Профессии | 27 | **25** | 27 ключей в UI.json, включая дубль `Metalworker`/`MetalWorker` и служебные |
| Огнестрел | 21 ствол + 7 магазинов | **22 ствола + 6 магазинов** | Пересчёт по `firearms.csv` |

Ещё одна поправка, не про числа:

- **`LootItemRemovalList` — не глобальный фильтр лута.** Проверено: единственное
  использование в `forageSystem.lua:765`. Работает только для собирательства.
  Для мира есть `WorldItemRemovalList`.

## 5. Ограничения парсера

1. **Скобочный разбор, не полноценный парсер.** Считаются блоки вида
   `keyword Name { ... }` и свойства верхнего уровня. Вложенные компоненты
   (`component FluidContainer { ... }`) пропускаются намеренно.
2. **Наследование не разрешается.** `template!` у машин только фиксируется как строка,
   но не разворачивается в итоговые свойства.
3. **`itemMapper` не вычисляется.** Рецепты с `mappers[...]` дают один рецепт, а не
   по одному на каждый вариант.
4. **`vehicle_parts.csv` пуст (0 строк).** Причина: в B42 запчасти не имеют категории
   `base:vehiclepart`. Реальное число — 105 предметов с `DisplayCategory = VehicleMaintenance`;
   их надо брать из `items.csv` фильтром по `display_category`.
5. **Моды не учитываются.** Если в `Zomboid\mods` или Workshop подписаны моды,
   их предметы в выгрузку не попадают — парсер читает только установку игры.
6. **`skills.json` пуст.** Навыки (`Perks`) — перечисление в Java, а не данные в
   `UI.json`. Их список берётся из `IG_UI.json` (`IGUI_perks_*`), но в выгрузку
   он не включён.
7. **Локализация.** Названия предметов берутся из скриптов (английский), а не из
   `ItemName.json`. Для русских подписей нужен отдельный проход.

## 6. Проверка воспроизводимости

Контрольные значения — сравнить после повторного запуска:

```
items: 5105
firearms: 28
ammo: 9
vehicles: 241
craft_recipes: 623
professions: 27        <- ключи UI
profession_definitions: 25
traits: 173            <- ключи UI
trait_definitions: 97
```

Если числа отличаются — либо обновилась игра, либо изменился парсер. В обоих случаях
отчёт `01`–`03` надо перечитать: выводы опираются на эти числа.

## 7. Что стоит добавить в выгрузку дальше

| Данные | Зачем |
|---|---|
| `IGUI_perks_*` | Полный список навыков для правки UI |
| `ProceduralDistributions.lua` → таблица | Знать, где именно лежит современный лут |
| `ItemName.json` → русские названия | Локализация |
| Список `SoundGunshot`-звуков | Подбор звуков для пороха |
| Модели и иконки оружия | Инвентаризация ассетов для замены |
| `physics_hit_reactions.txt` | Понять, как урон связан с типом боеприпаса |
