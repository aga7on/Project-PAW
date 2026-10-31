# Брифинг: Андрей

Роль: механики, баланс, прогрессия. Ветки: `andrey/*`.

## Зона

| Путь | Что |
|---|---|
| `ProjectPAW/media/scripts/ProjectPAW/characters/` | профессии, трейты |
| `ProjectPAW/media/lua/shared/Sandbox/` | пресет песочницы и его числа |
| `docs/balance/` | балансные решения, таблицы, замеры |
| `docs/team/andrey.md` | этот файл |

## Что важно знать до начала

1. **`Perks` — Java-enum.** Новый навык добавить нельзя. Можно переименовать
   существующий в UI и переиспользовать механику. `Electricity` и `Mechanics`
   удаляются, но их упоминания есть в `XpUpdate.lua:263,370` и
   `XPSystem_SkillBook.lua:43-48` — их надо править вместе с навыком.
2. **Пресет песочницы — твой файл.** Артём присылает значения, которые нужны для
   удаления (`ElecShut=1`, `EnableVehicles=false`, нулевые лут-факторы), ты
   поддерживаешь файл и отвечаешь за баланс остальных чисел.
3. **Холодильник — главная балансная дыра.** Без него еда портится за дни. Пока нет
   замены (погреб, копчение, соление), скорость порчи придётся смягчать.
4. **Порох балансируется здесь.** Числа урона, дальности, осечек и времени
   перезарядки — твои; скрипты и timed action пишет Артём.

## Текущие задачи

1. Пресет `ProjectPAW.lua`: `ElecShut=1`, `WaterShut=1`, `AlarmDecay=1`,
   `GeneratorSpawning=1`, `EnableVehicles=false`, `RangedWeaponLootNew=0`,
   `AmmoLootNew=0`, `MechanicsLootNew=0`, `MediaLootNew=0`.
2. Проверить `WaterShut=1`: хватает ли колодцев на карте, иначе мягкий вариант.
3. Подобрать `FoodRotSpeed` / `FridgeFactor` без холодильника (тест на 30 дней).
4. Профессии: удалить `electrician`, `mechanics`; переписать 6 профессий
   (`burgerflipper`, `fireofficer`, `metalworker`, `policeofficer`, `veteran`,
   `fitnessinstructor`).
5. Трейты: убрать `mechanics`, `mechanics2`, `speeddemon`, `sundaydriver`.
6. Баланс порохового оружия по таблице `docs/03`, раздел 3.

## Не трогать

- `media/scripts/ProjectPAW/items/**`, `media/scripts/ProjectPAW/recipes/**` — Артём.
- `media/lua/server/ProjectPAW/**`, `media/maps/**` — Влад.
- `mod.info`, `workshop.txt` — Артём.
- `docs/01`, `docs/02`, `docs/05` — Артём.

## Метод

- Любое число подтверждается тестом в игре: что мерили, на каком мире, сколько
  игровых дней. Без этого — это не баланс, а мнение.
- Результаты — в `docs/balance/` таблицей: параметр, было, стало, чем проверено.
- Спорные числа — в журнал решений `docs/07-teamwork.md`.

## Полезное

- `docs/01-mechanics-inventory.md`, разделы E–G — ремесло, быт, прогрессия.
- `docs/02-modern-systems-removal.md`, раздел 8 — таблица значений песочницы.
- `docs/03-blackpowder-firearms.md`, раздел 3 — целевые характеристики оружия.
- `docs/data/items.csv` — что вообще есть в игре.
