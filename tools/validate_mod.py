#!/usr/bin/env python3
"""Валидатор репозитория Project PAW.

Проверяет то, что можно проверить без установленной игры:

* ``mod.info`` на месте, обязательные поля заполнены, ``id`` не дублируется;
* в скриптах мода нет двух предметов с одинаковым именем;
* рецепты ссылаются на существующие предметы (ваниль + мод);
* относительные ссылки в markdown-документах не битые;
* в репозитории нет файлов больше 10 МБ.

Запуск::

    python tools/validate_mod.py

Код возврата: 0 — чисто, 1 — есть ошибки.
"""

from __future__ import annotations

import csv
import re
import sys
from pathlib import Path
from urllib.parse import unquote

ROOT = Path(__file__).resolve().parent.parent
MODS_DIR = ROOT / "Contents" / "mods"
DATA_ITEMS = ROOT / "docs" / "data" / "items.csv"
MAX_FILE_BYTES = 10 * 1024 * 1024

ITEM_RE = re.compile(r"^[ \t]*item[ \t]+([A-Za-z0-9_]+)[ \t]*$", re.M)
MODULE_RE = re.compile(r"^[ \t]*module[ \t]+([A-Za-z0-9_]+)", re.M)
RECIPE_RE = re.compile(r"^[ \t]*craftRecipe[ \t]+([A-Za-z0-9_]+)", re.M)
OUTPUT_ITEM_RE = re.compile(r"\bitem[ \t]+\d+[ \t]+(Base\.[A-Za-z0-9_]+)")
LINK_RE = re.compile(r"\[[^\]]*\]\(([^)\s]+)(?:[ \t]+\"[^\"]*\")?\)")

errors: list[str] = []
warnings: list[str] = []


def error(message: str) -> None:
    errors.append(message)


def warn(message: str) -> None:
    warnings.append(message)


def rel(path: Path) -> str:
    try:
        return path.relative_to(ROOT).as_posix()
    except ValueError:
        return path.as_posix()


def iter_files(suffix: str):
    for path in ROOT.rglob(f"*{suffix}"):
        if ".git" in path.parts:
            continue
        if path.is_file():
            yield path


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8-sig", errors="replace")


def block_body(text: str, brace_index: int) -> str:
    """Содержимое блока от '{' в brace_index до парной '}'."""
    depth = 0
    for i in range(brace_index, len(text)):
        char = text[i]
        if char == "{":
            depth += 1
        elif char == "}":
            depth -= 1
            if depth == 0:
                return text[brace_index + 1 : i]
    return text[brace_index + 1 :]


def parse_mod_info(path: Path) -> dict[str, str]:
    data: dict[str, str] = {}
    for raw in read_text(path).splitlines():
        line = raw.strip()
        if not line or line.startswith("#") or line.startswith("//") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        data[key.strip().lower()] = value.strip()
    return data


def check_mod_info() -> list[tuple[Path, dict[str, str]]]:
    infos = list(iter_files("mod.info"))
    if not infos:
        error("не найден ни один mod.info — мод не загрузится")
        return []

    by_id: dict[str, list[str]] = {}
    result: list[tuple[Path, dict[str, str]]] = []

    for path in infos:
        data = parse_mod_info(path)
        missing = [key for key in ("name", "id", "versionmin") if not data.get(key)]
        if missing:
            error(f"{rel(path)}: нет обязательных полей: {', '.join(missing)}")
        mod_id = data.get("id", "")
        if mod_id:
            by_id.setdefault(mod_id, []).append(rel(path))
        result.append((path.parent, data))

    for mod_id, paths in by_id.items():
        if len(paths) > 1:
            error(
                f"id '{mod_id}' объявлен в нескольких mod.info ({', '.join(paths)}): "
                "игра загрузит только один, отладка станет непредсказуемой"
            )

    return result


def script_files(version_dirs: list[tuple[Path, dict[str, str]]]) -> list[Path]:
    files: list[Path] = []
    for version_dir, _ in version_dirs:
        scripts = version_dir / "media" / "scripts"
        if scripts.is_dir():
            files.extend(sorted(scripts.rglob("*.txt")))
    return files


def check_items(files: list[Path]) -> set[str]:
    defined: set[str] = set()
    for path in files:
        module = "Base"
        for lineno, line in enumerate(read_text(path).splitlines(), 1):
            module_match = MODULE_RE.match(line)
            if module_match:
                module = module_match.group(1)
                continue
            item_match = ITEM_RE.match(line)
            if not item_match:
                continue
            full = f"{module}.{item_match.group(1)}"
            if full in defined:
                error(f"дубль предмета {full}: {rel(path)}:{lineno}")
            defined.add(full)
    return defined


def load_vanilla_ids() -> set[str]:
    if not DATA_ITEMS.is_file():
        warn(f"{rel(DATA_ITEMS)} не найден: проверка ссылок рецептов только по предметам мода")
        return set()
    ids: set[str] = set()
    with DATA_ITEMS.open(encoding="utf-8", newline="") as handle:
        for row in csv.DictReader(handle):
            if row.get("id"):
                ids.add(row["id"])
    return ids


def check_recipes(files: list[Path], defined: set[str]) -> int:
    known = defined | load_vanilla_ids()
    missing: set[tuple[str, str]] = set()
    recipes = 0

    for path in files:
        text = read_text(path)
        for match in RECIPE_RE.finditer(text):
            brace = text.find("{", match.end())
            if brace == -1:
                continue
            recipes += 1
            body = block_body(text, brace)
            outputs_at = body.find("outputs")
            if outputs_at == -1:
                continue
            outputs_brace = body.find("{", outputs_at)
            if outputs_brace == -1:
                continue
            outputs = block_body(body, outputs_brace)
            for item_match in OUTPUT_ITEM_RE.finditer(outputs):
                name = item_match.group(1)
                if name not in known:
                    missing.add((name, rel(path)))

    for name, where in sorted(missing):
        warn(f"{where}: рецепт выдаёт неизвестный предмет {name}")

    return recipes


def check_markdown_links() -> int:
    checked = 0
    for path in iter_files(".md"):
        text = read_text(path)
        for match in LINK_RE.finditer(text):
            target = match.group(1).strip()
            if target.startswith(("http://", "https://", "mailto:", "tel:", "#")):
                continue
            target = unquote(target.split("#", 1)[0])
            if not target:
                continue
            resolved = ROOT / target.lstrip("/") if target.startswith("/") else path.parent / target
            checked += 1
            if not resolved.exists():
                error(f"{rel(path)}: битая ссылка -> {target}")
    return checked


def check_sizes() -> int:
    checked = 0
    for path in ROOT.rglob("*"):
        if not path.is_file() or ".git" in path.parts:
            continue
        checked += 1
        size = path.stat().st_size
        if size > MAX_FILE_BYTES:
            error(f"{rel(path)}: {size / 1048576:.1f} МБ > 10 МБ (см. CONTRIBUTING.md, раздел 8)")
    return checked


def main() -> int:
    try:
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    except Exception:
        pass

    version_dirs = check_mod_info()
    files = script_files(version_dirs)
    defined = check_items(files)
    recipes = check_recipes(files, defined)
    links = check_markdown_links()
    scanned = check_sizes()

    for message in warnings:
        print(f"WARN  {message}")
    for message in errors:
        print(f"ERROR {message}")

    print(
        "\nпроверено: "
        f"{len(version_dirs)} mod.info, "
        f"{len(files)} скриптов, "
        f"{len(defined)} предметов мода, "
        f"{recipes} рецептов, "
        f"{links} ссылок, "
        f"{scanned} файлов"
    )

    if errors:
        print(f"\nРЕЗУЛЬТАТ: ошибок {len(errors)}, предупреждений {len(warnings)}")
        return 1

    print(f"РЕЗУЛЬТАТ: чисто (предупреждений {len(warnings)})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
