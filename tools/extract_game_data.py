#!/usr/bin/env python3
"""Extract vanilla Project Zomboid Build 42 data into reviewable CSV/JSON.

Usage:
    python tools/extract_game_data.py "G:/SteamLibrary/steamapps/common/ProjectZomboid"

Outputs to docs/data/. Read-only against the game installation.
"""
from __future__ import annotations

import csv
import json
import re
import sys
from collections import Counter
from pathlib import Path

GAME = Path(sys.argv[1] if len(sys.argv) > 1 else r"G:/SteamLibrary/steamapps/common/ProjectZomboid")
OUT = Path(__file__).resolve().parent.parent / "docs" / "data"
OUT.mkdir(parents=True, exist_ok=True)

ITEM_FILES = sorted((GAME / "media" / "scripts" / "generated" / "items").glob("*.txt"))
RECIPE_FILES = sorted((GAME / "media" / "scripts" / "generated" / "recipes").glob("*.txt"))
VEHICLE_FILES = sorted((GAME / "media" / "scripts" / "generated" / "vehicles").rglob("*.txt"))
TRANSLATE_EN = GAME / "media" / "lua" / "shared" / "Translate" / "EN"

PROP_RE = re.compile(r"^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*?),\s*$")
MODULE_RE = re.compile(r"^\s*module\s+([A-Za-z0-9_]+)\s*\{?", re.M)


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="replace")


def module_at(text: str, pos: int) -> str:
    name = ""
    for m in MODULE_RE.finditer(text, 0, pos):
        name = m.group(1)
    return name


def match_brace(text: str, open_pos: int) -> int:
    depth = 0
    for i in range(open_pos, len(text)):
        ch = text[i]
        if ch == "{":
            depth += 1
        elif ch == "}":
            depth -= 1
            if depth == 0:
                return i
    return len(text) - 1


def parse_blocks(text: str, keyword: str):
    """Yield (name, module, props, start_line) for `keyword Name { ... }` blocks."""
    pattern = re.compile(rf"(?m)^[ \t]*{keyword}[ \t]+([A-Za-z0-9_]+)[ \t]*\r?\n[ \t]*\{{")
    for m in pattern.finditer(text):
        name = m.group(1)
        brace = text.find("{", m.start())
        end = match_brace(text, brace)
        body = text[brace + 1 : end]
        props: dict[str, str] = {}
        depth = 0
        for line in body.splitlines():
            stripped = line.strip()
            depth += stripped.count("{") - stripped.count("}")
            if depth != 0:
                continue
            pm = PROP_RE.match(line)
            if pm and pm.group(1) not in props:
                props[pm.group(1)] = pm.group(2).strip()
        yield name, module_at(text, m.start()), props, text.count("\n", 0, m.start()) + 1


def to_set(value: str) -> set[str]:
    return {p.strip().lower() for p in re.split(r"[;]", value or "") if p.strip()}


def is_truthy(value: str | None) -> bool:
    return (value or "").strip().lower() == "true"


# ---------------------------------------------------------------- items
items = []
for path in ITEM_FILES:
    text = read(path)
    for name, module, props, line in parse_blocks(text, "item"):
        cats = to_set(props.get("Categories", ""))
        tags = to_set(props.get("Tags", ""))
        item_type = props.get("ItemType", "")
        items.append(
            {
                "id": f"{module}.{name}" if module else name,
                "name": name,
                "module": module,
                "file": path.name,
                "line": line,
                "item_type": item_type,
                "display_category": props.get("DisplayCategory", ""),
                "categories": ";".join(sorted(cats)),
                "tags": ";".join(sorted(tags)),
                "weight": props.get("Weight", ""),
                "is_firearm": int(
                    is_truthy(props.get("IsAimedFirearm"))
                    or "base:firearm" in cats
                    or bool(props.get("AmmoType"))
                ),
                "ammo_type": props.get("AmmoType", ""),
                "clip_size": props.get("ClipSize") or props.get("MaxAmmo", ""),
                "is_ammo": int("base:ammo" in cats or "base:ammo" in tags),
                "is_vehicle_part": int("base:vehiclepart" in cats or "vehiclepart" in item_type.lower()),
            }
        )

with (OUT / "items.csv").open("w", newline="", encoding="utf-8-sig") as f:
    writer = csv.DictWriter(f, fieldnames=list(items[0].keys()))
    writer.writeheader()
    writer.writerows(items)

# ---------------------------------------------------------------- recipes
recipes = []
for path in RECIPE_FILES:
    text = read(path)
    for name, module, props, line in parse_blocks(text, "craftRecipe"):
        recipes.append(
            {
                "name": name,
                "module": module,
                "file": path.name,
                "line": line,
                "category": props.get("category", ""),
                "time": props.get("time", ""),
                "skill": props.get("skillRequired", ""),
                "tool": props.get("tool", ""),
            }
        )

with (OUT / "recipes.csv").open("w", newline="", encoding="utf-8-sig") as f:
    writer = csv.DictWriter(f, fieldnames=list(recipes[0].keys()))
    writer.writeheader()
    writer.writerows(recipes)

# ---------------------------------------------------------------- vehicles
vehicles = []
for path in VEHICLE_FILES:
    text = read(path)
    for name, module, props, line in parse_blocks(text, "vehicle"):
        vehicles.append(
            {
                "name": name,
                "file": str(path.relative_to(GAME / "media" / "scripts" / "generated" / "vehicles")),
                "line": line,
                "template": props.get("template!", ""),
                "model": props.get("file", ""),
                "is_burnt_or_smashed": int(
                    "burnt" in path.name.lower() or "smashed" in path.name.lower()
                ),
            }
        )
    for name, module, props, line in parse_blocks(text, "template vehicle"):
        vehicles.append(
            {
                "name": name,
                "file": str(path.relative_to(GAME / "media" / "scripts" / "generated" / "vehicles")),
                "line": line,
                "template": "TEMPLATE",
                "model": props.get("file", ""),
                "is_burnt_or_smashed": 0,
            }
        )

with (OUT / "vehicles.csv").open("w", newline="", encoding="utf-8-sig") as f:
    writer = csv.DictWriter(f, fieldnames=list(vehicles[0].keys()))
    writer.writeheader()
    writer.writerows(vehicles)

# ---------------------------------------------------------------- derived tables
firearms = [i for i in items if i["is_firearm"] and not i["is_ammo"]]
ammo = [i for i in items if i["is_ammo"]]
vehicle_parts = [i for i in items if i["is_vehicle_part"]]

for filename, rows in (
    ("firearms.csv", firearms),
    ("ammo.csv", ammo),
    ("vehicle_parts.csv", vehicle_parts),
):
    with (OUT / filename).open("w", newline="", encoding="utf-8-sig") as f:
        writer = csv.DictWriter(f, fieldnames=list(items[0].keys()))
        writer.writeheader()
        writer.writerows(rows)

# ---------------------------------------------------------------- translations
def load_json(name: str) -> dict:
    path = TRANSLATE_EN / name
    if not path.exists():
        return {}
    data = json.loads(read(path))
    return data if isinstance(data, dict) else {}


ui = load_json("UI.json")
professions = {
    k: v
    for k, v in ui.items()
    if k.startswith("UI_prof_") and "desc" not in k.lower()
}
traits = {k: v for k, v in ui.items() if k.startswith("UI_trait_")}
skills = {k: v for k, v in ui.items() if k.lower().startswith(("ui_skill_", "ui_perk_"))}

# Authoritative definition counts come from the character scripts, not from UI keys:
# UI.json holds both a name key and a *Desc key per trait, which inflates the count.
character_scripts = GAME / "media" / "scripts" / "generated" / "characters"
profession_def_re = re.compile(r"character_profession_definition\s+([\w:]+)")
trait_def_re = re.compile(r"character_trait_definition\s+([\w:]+)")
profession_defs = sorted(
    {
        m.group(1)
        for m in profession_def_re.finditer(read(character_scripts / "character_professions.txt"))
    }
)
trait_defs = sorted(
    {
        m.group(1)
        for m in trait_def_re.finditer(read(character_scripts / "character_traits.txt"))
    }
)

(OUT / "professions.json").write_text(
    json.dumps(professions, ensure_ascii=False, indent=2), encoding="utf-8"
)
(OUT / "traits.json").write_text(
    json.dumps(traits, ensure_ascii=False, indent=2), encoding="utf-8"
)
(OUT / "skills.json").write_text(
    json.dumps(skills, ensure_ascii=False, indent=2), encoding="utf-8"
)

# sandbox keys worth reviewing for a medieval conversion
sandbox = load_json("Sandbox.json")
sandbox_keys = sorted(
    k
    for k in sandbox
    if re.search(r"elec|water|vehicle|generator|loot|gas|fuel|power|battery|radio|tv", k, re.I)
)

# ---------------------------------------------------------------- summary
item_types = Counter(i["item_type"] for i in items if i["item_type"])
categories = Counter(c for i in items for c in i["categories"].split(";") if c)
tags = Counter(t for i in items for t in i["tags"].split(";") if t)
recipe_categories = Counter(r["category"] for r in recipes if r["category"])
files = Counter(i["file"] for i in items)

summary = {
    "game_dir": str(GAME),
    "item_definitions": len(items),
    "items_by_file": dict(sorted(files.items())),
    "item_types": dict(item_types.most_common()),
    "top_categories": dict(categories.most_common(40)),
    "top_tags": dict(tags.most_common(60)),
    "firearms": len(firearms),
    "firearm_ids": sorted(i["id"] for i in firearms),
    "ammo_items": len(ammo),
    "ammo_types": sorted({i["ammo_type"] for i in firearms if i["ammo_type"]}),
    "vehicle_part_items": len(vehicle_parts),
    "vehicles": len([v for v in vehicles if v["template"] != "TEMPLATE"]),
    "vehicle_templates": len([v for v in vehicles if v["template"] == "TEMPLATE"]),
    "burnt_or_smashed": len([v for v in vehicles if v["is_burnt_or_smashed"]]),
    "craft_recipes": len(recipes),
    "recipe_categories": dict(recipe_categories.most_common()),
    "professions": len(professions),
    "profession_definitions": len(profession_defs),
    "profession_definition_ids": profession_defs,
    "traits": len(traits),
    "trait_definitions": len(trait_defs),
    "trait_definition_ids": trait_defs,
    "skills": len(skills),
    "sandbox_keys_review": {k: sandbox[k] for k in sandbox_keys},
}

(OUT / "summary.json").write_text(
    json.dumps(summary, ensure_ascii=False, indent=2), encoding="utf-8"
)

print(json.dumps({
    "items": len(items),
    "firearms": len(firearms),
    "ammo": len(ammo),
    "vehicles": summary["vehicles"],
    "craft_recipes": len(recipes),
    "professions": len(professions),
    "traits": len(traits),
    "output": str(OUT),
}, ensure_ascii=False, indent=2))
