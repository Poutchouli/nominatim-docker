#!/usr/bin/env python3
"""Generate a JSON coverage catalog from lib/regions.sh."""

from __future__ import annotations

import json
import re
import sys
from collections import defaultdict
from datetime import datetime, timezone
from pathlib import Path


REGION_PATTERN = re.compile(r'^REGIONS\[(?P<region_id>[^\]]+)\]="(?P<name>[^"]+)\|(?P<size>\d+)\|(?P<city>[^"]+)"')
ALIAS_PATTERN = re.compile(r'^REGION_ALIASES\[(?P<alias_id>[^\]]+)\]="(?P<targets>[^"]+)"')
DEPARTMENT_PATTERN = re.compile(r'DEPT_TO_REGION\[(?P<key>[^\]]+)\]="(?P<region_id>[^"]+)"')


def is_department_code(value: str) -> bool:
    return bool(re.fullmatch(r"\d{1,3}[A-Za-z]?", value))


def to_display_name(value: str) -> str:
    if not value:
        return value
    words = value.replace("-", " ").split()
    return " ".join(word[:1].upper() + word[1:] for word in words)


def parse_region_order(lines: list[str]) -> list[str]:
    in_order_block = False
    order: list[str] = []

    for raw_line in lines:
        line = raw_line.strip()

        if line.startswith("REGION_ORDER=("):
            in_order_block = True
            line = line[len("REGION_ORDER=(") :].strip()
            if line:
                line = line.rstrip(")")
                order.extend(token for token in line.split() if token)
                if raw_line.strip().endswith(")"):
                    in_order_block = False
            continue

        if not in_order_block:
            continue

        if line == ")":
            in_order_block = False
            continue

        order.extend(token for token in line.split() if token)

    return order


def parse_departments(lines: list[str]) -> tuple[list[dict], dict[str, list[dict]]]:
    departments: list[dict] = []
    by_region: dict[str, list[dict]] = defaultdict(list)

    for raw_line in lines:
        matches = DEPARTMENT_PATTERN.findall(raw_line)
        if not matches:
            continue

        codes: list[tuple[str, str]] = []
        names: list[tuple[str, str]] = []
        for key, region_id in matches:
            if is_department_code(key):
                codes.append((key.upper(), region_id))
            else:
                names.append((key, region_id))

        paired_count = max(len(codes), len(names))
        for index in range(paired_count):
            code = codes[index][0] if index < len(codes) else None
            region_from_code = codes[index][1] if index < len(codes) else None
            normalized_name = names[index][0] if index < len(names) else None
            region_from_name = names[index][1] if index < len(names) else None
            region_id = region_from_code or region_from_name
            if not region_id:
                continue

            department = {
                "code": code,
                "name": to_display_name(normalized_name) if normalized_name else code,
                "normalized_name": normalized_name,
                "region_id": region_id,
            }
            departments.append(department)
            by_region[region_id].append(department)

    return departments, by_region


def parse_regions_shell(shell_path: Path) -> dict:
    lines = shell_path.read_text(encoding="utf-8").splitlines()
    region_order = parse_region_order(lines)

    regions_by_id: dict[str, dict] = {}
    for raw_line in lines:
        match = REGION_PATTERN.match(raw_line.strip())
        if not match:
            continue

        region_id = match.group("region_id")
        regions_by_id[region_id] = {
            "id": region_id,
            "name": match.group("name"),
            "size_mb": int(match.group("size")),
            "test_city": match.group("city"),
        }

    departments, departments_by_region = parse_departments(lines)
    for region_id, region in regions_by_id.items():
        region_departments = departments_by_region.get(region_id, [])
        region["department_codes"] = [entry["code"] for entry in region_departments if entry["code"]]
        region["departments"] = [
            {
                "code": entry["code"],
                "name": entry["name"],
                "normalized_name": entry["normalized_name"],
            }
            for entry in region_departments
        ]

    aliases: list[dict] = []
    for raw_line in lines:
        match = ALIAS_PATTERN.match(raw_line.strip())
        if not match:
            continue
        alias_id = match.group("alias_id")
        aliases.append(
            {
                "id": alias_id,
                "name": to_display_name(alias_id),
                "region_ids": match.group("targets").split(),
            }
        )

    ordered_regions = []
    seen_region_ids: set[str] = set()
    for region_id in region_order:
        region = regions_by_id.get(region_id)
        if not region:
            continue
        ordered_regions.append(region)
        seen_region_ids.add(region_id)

    for region_id, region in regions_by_id.items():
        if region_id not in seen_region_ids:
            ordered_regions.append(region)

    department_items = []
    for department in departments:
        region = regions_by_id.get(department["region_id"], {})
        department_items.append(
            {
                "code": department["code"],
                "name": department["name"],
                "normalized_name": department["normalized_name"],
                "region_id": department["region_id"],
                "region_name": region.get("name", department["region_id"]),
            }
        )

    return {
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "source": str(shell_path),
        "regions": ordered_regions,
        "departments": department_items,
        "aliases": aliases,
    }


def main() -> int:
    if len(sys.argv) != 3:
        print("Usage: generate_coverage_manifest.py <regions.sh> <output.json>", file=sys.stderr)
        return 1

    shell_path = Path(sys.argv[1]).resolve()
    output_path = Path(sys.argv[2]).resolve()

    manifest = parse_regions_shell(shell_path)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"Manifest written to {output_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())