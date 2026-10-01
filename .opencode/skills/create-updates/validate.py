#!/usr/bin/env python3
"""Valide un script de mise à jour automatique généré dans .updates.

Usage:
    python .opencode/skills/create-updates/validate.py <slug>

Sortie: liste des checks (OK / ECHEC / AVERTISSEMENT), code retour 0 si aucun echec.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[3]
UPDATES_DIR = REPO / ".updates"

SLUG_RE = re.compile(r"^[a-z0-9]+(-[a-z0-9]+)*$")

REQUIRED_VARS = [
    "ADDON_DIR",
    "DISPLAY_NAME",
    "UPSTREAM_REPO",
    "VERSION_TYPE",
    "FILES_TO_UPDATE",
]

errors: list[str] = []
warnings: list[str] = []


def ok(msg: str) -> None:
    print(f"  OK       {msg}")


def fail(msg: str) -> None:
    errors.append(msg)
    print(f"  ECHEC    {msg}")


def warn(msg: str) -> None:
    warnings.append(msg)
    print(f"  AVERTIS. {msg}")


def main() -> int:
    if len(sys.argv) != 2:
        print(__doc__)
        return 2

    slug = sys.argv[1]
    script_path = UPDATES_DIR / f"{slug}.sh"

    if not SLUG_RE.match(slug):
        fail(f"slug '{slug}' invalide (attendu: kebab-case minuscule)")
    else:
        ok("slug en kebab-case")

    if not script_path.is_file():
        fail(f"script '.updates/{slug}.sh' introuvable")
        return 1
    else:
        ok(f"script '.updates/{slug}.sh' existe")

    # Lire le contenu du script
    try:
        content = script_path.read_text(encoding="utf-8")
    except Exception as exc:  # noqa: BLE001
        fail(f"impossible de lire le script: {exc}")
        return 1

    # Vérifier qu'il source update-lib.sh
    if ".scripts/update-lib.sh" not in content:
        fail("script ne source pas .scripts/update-lib.sh")
    else:
        ok("script source .scripts/update-lib.sh")

    # Vérifier les variables exportées requises
    for var in REQUIRED_VARS:
        if f"export {var}" not in content:
            fail(f"variable d'environnement manquante: {var}")
        else:
            ok(f"variable d'environnement présente: {var}")

    # Vérifier la structure de base du script
    # Vérifier les patterns courants
    if "get_build_yaml_tag" not in content:
        warn("fonction get_build_yaml_tag non trouvée dans le script")
    else:
        ok("fonction get_build_yaml_tag présente")

    if "get_latest_ls_release" not in content:
        warn("fonction get_latest_ls_release non trouvée dans le script")
    else:
        ok("fonction get_latest_ls_release présente")

    if "check_pr_status" not in content:
        warn("fonction check_pr_status non trouvée dans le script")
    else:
        ok("fonction check_pr_status présente")

    # Vérifier la présence des sed pour les mises à jour
    if 'sed -i "s/^version: ' not in content and "sed -i \"s/^version: " not in content:
        warn("mise à jour de version sed non détectée (peut être normale selon le type)")
    else:
        ok("mise à jour de version sed détectée")

    return report()


def report() -> int:
    print("\n" + "=" * 60)
    if errors:
        print(f"ECHEC: {len(errors)} erreur(s), {len(warnings)} avertissement(s)")
        return 1
    print(f"Tous les checks sont passes ({len(warnings)} avertissement(s)).")
    return 0


if __name__ == "__main__":
    sys.exit(main())