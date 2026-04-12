#!/usr/bin/env python3
"""Generate a GeoJSON FeatureCollection of department boundaries for covered targets.

Downloads the simplified French department boundaries from france-geojson
and filters them for the regions, aliases or departments listed in the
coverage catalog.

Usage:
    python generate_coverage_geojson.py <coverage_catalog.json> <output.geojson> [target_ids...]

Examples:
    # All regions in the catalog
    python generate_coverage_geojson.py catalog.json coverage.geojson

    # Alias, region or department
    python generate_coverage_geojson.py catalog.json coverage.geojson normandie
    python generate_coverage_geojson.py catalog.json coverage.geojson basse-normandie
    python generate_coverage_geojson.py catalog.json coverage.geojson 50
"""

from __future__ import annotations

import json
import sys
import urllib.request
import urllib.error
from pathlib import Path

FRANCE_GEOJSON_URL = (
    "https://raw.githubusercontent.com/gregoiredavid/france-geojson"
    "/master/departements-version-simplifiee.geojson"
)


def fetch_all_departments_geojson() -> dict:
    """Download the full simplified French department boundaries."""
    req = urllib.request.Request(FRANCE_GEOJSON_URL, headers={"User-Agent": "nominatim-coverage/1.0"})
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            return json.loads(resp.read().decode("utf-8"))
    except (urllib.error.URLError, urllib.error.HTTPError) as exc:
        print(f"Erreur lors du téléchargement des contours départementaux: {exc}", file=sys.stderr)
        sys.exit(2)


def load_catalog(catalog_path: Path) -> dict:
    return json.loads(catalog_path.read_text(encoding="utf-8"))


def resolve_requested_departments(catalog: dict, requested_ids: list[str]) -> list[tuple[str, str, str]]:
    """Resolve alias, region or department identifiers to concrete departments."""
    alias_map = {alias["id"]: alias["region_ids"] for alias in catalog.get("aliases", [])}
    regions_by_id = {region["id"]: region for region in catalog.get("regions", [])}
    departments = catalog.get("departments", [])
    resolved: list[tuple[str, str, str]] = []
    seen_codes: set[str] = set()

    def add_region_departments(region_id: str):
        region = regions_by_id.get(region_id)
        if not region:
            return
        region_name = region["name"]
        for dept in region.get("departments", []):
            code = dept.get("code")
            if code and code not in seen_codes:
                resolved.append((code, dept.get("name", code), region_name))
                seen_codes.add(code)

    for rid in requested_ids:
        if rid in alias_map:
            for actual_id in alias_map[rid]:
                add_region_departments(actual_id)
            continue

        if rid in regions_by_id:
            add_region_departments(rid)
            continue

        matched_department = None
        for dept in departments:
            candidates = {dept.get("code"), dept.get("normalized_name"), dept.get("name")}
            if rid in {candidate for candidate in candidates if candidate}:
                matched_department = dept
                break

        if matched_department:
            code = matched_department.get("code")
            if code and code not in seen_codes:
                resolved.append(
                    (
                        code,
                        matched_department.get("name", code),
                        matched_department.get("region_name", matched_department.get("region_id", "")),
                    )
                )
                seen_codes.add(code)
            continue

        print(f"  ⚠ Cible inconnue: {rid}", file=sys.stderr)

    return resolved


def build_geojson(departments: list[tuple[str, str, str]]) -> dict:
    """Build a GeoJSON FeatureCollection filtered for the given departments."""

    if not departments:
        print("Aucun département trouvé pour les régions demandées.", file=sys.stderr)
        return {"type": "FeatureCollection", "features": []}

    # Build lookup: code -> (dept_name, region_name)
    dept_lookup = {code: (dept_name, region_name) for code, dept_name, region_name in departments}
    wanted_codes = set(dept_lookup.keys())

    print(f"Téléchargement des contours départementaux depuis france-geojson...")
    source = fetch_all_departments_geojson()

    features: list[dict] = []
    for feature in source.get("features", []):
        code = feature.get("properties", {}).get("code", "")
        if code not in wanted_codes:
            continue

        dept_name, region_name = dept_lookup[code]
        # Enrich properties with region info
        feature["properties"]["region"] = region_name
        features.append(feature)
        print(f"  ✓ {code} {feature['properties'].get('nom', dept_name)} ({region_name})")
        wanted_codes.discard(code)

    for code in sorted(wanted_codes):
        dept_name, region_name = dept_lookup[code]
        print(f"  ✗ {code} {dept_name} — contour non trouvé dans la source")

    return {"type": "FeatureCollection", "features": features}


def main() -> int:
    if len(sys.argv) < 3:
        print(
            "Usage: generate_coverage_geojson.py <coverage_catalog.json> <output.geojson> [target_ids...]",
            file=sys.stderr,
        )
        return 1

    catalog_path = Path(sys.argv[1]).resolve()
    output_path = Path(sys.argv[2]).resolve()
    requested_ids = sys.argv[3:] if len(sys.argv) > 3 else []

    if not catalog_path.exists():
        print(f"Catalogue introuvable: {catalog_path}", file=sys.stderr)
        return 1

    catalog = load_catalog(catalog_path)

    if requested_ids:
        departments = resolve_requested_departments(catalog, requested_ids)
    else:
        departments = resolve_requested_departments(
            catalog,
            [region["id"] for region in catalog.get("regions", [])],
        )

    if not departments:
        print("Aucune cible valide sélectionnée.", file=sys.stderr)
        return 1

    print(f"Départements ciblés: {', '.join(code for code, _, _ in departments)}")
    geojson = build_geojson(departments)

    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps(geojson, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"\nGeoJSON écrit: {output_path} ({len(geojson['features'])} features)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
