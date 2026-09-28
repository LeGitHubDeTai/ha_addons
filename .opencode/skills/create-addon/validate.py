#!/usr/bin/env python3
"""Valide un add-on de ce depot contre les conventions de developpement.

Usage:
    python .opencode/skills/create-addon/validate.py <slug>

Sortie: liste des checks (OK / ECHEC / AVERTISSEMENT), code retour 0 si aucun echec.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

try:
    import yaml
except ImportError:  # pragma: no cover
    print("PyYAML requis: pip install pyyaml")
    sys.exit(2)

REPO = Path(__file__).resolve().parents[3]
IMAGE_RE = re.compile(r"^ghcr\.io/legithubdetai/ha_addons/[a-z0-9-]+-\{arch\}$")
VERSION_RE = re.compile(r"^\d{2}\.\d{1,2}\.\d+$")
SLUG_RE = re.compile(r"^[a-z0-9]+(-[a-z0-9]+)*$")

REQUIRED_CONFIG_KEYS = [
    "name", "version", "slug", "description", "url", "image", "arch",
    "startup", "boot", "panel_icon",
]
VALID_ARCHES = {"amd64", "aarch64", "armv7", "armhf", "i386"}

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


def load_yaml(path: Path):
    try:
        return yaml.safe_load(path.read_text(encoding="utf-8"))
    except Exception as exc:  # noqa: BLE001
        fail(f"{path.relative_to(REPO)} illisible / YAML invalide: {exc}")
        return None


def check_text_encoding(path: Path) -> None:
    raw = path.read_bytes()
    if raw.startswith(b"\xef\xbb\xbf"):
        fail(f"{path.relative_to(REPO)} contient un BOM (attendu: UTF-8 sans BOM)")
    else:
        ok(f"{path.relative_to(REPO)}: UTF-8 sans BOM")
    if b"\r\n" in raw:
        warn(f"{path.relative_to(REPO)}: fins de ligne CRLF (LF conseille)")


def collect_ports() -> tuple[dict[str, set[str]], dict[str, list[str]]]:
    """Retourne (ports exposes sur l'hote par addon, ports utilises en interne).

    Seuls les mappings non nuls (`8080/tcp: 8080`) occupent un port hote :
    `8080/tcp: null` n'est pas exposé et ne peut donc pas entrer en conflit.
    """
    host_ports: dict[str, set[str]] = {}
    internal: dict[str, list[str]] = {}
    for cfg in sorted(REPO.glob("*/config.yaml")):
        addon = cfg.parent.name
        try:
            data = yaml.safe_load(cfg.read_text(encoding="utf-8")) or {}
        except Exception:  # noqa: BLE001
            continue
        if not isinstance(data, dict):
            continue
        for port, value in (data.get("ports") or {}).items():
            port = str(port).split("/")[0]
            internal.setdefault(port, []).append(addon)
            if value is not None:
                host_ports.setdefault(addon, set()).add(port)
        if data.get("ingress_port") is not None:
            port = str(data["ingress_port"])
            internal.setdefault(port, []).append(f"{addon}(ingress)")
    return host_ports, internal


def main() -> int:
    if len(sys.argv) != 2:
        print(__doc__)
        return 2

    slug = sys.argv[1]
    addon = REPO / slug
    print(f"\nValidation de l'add-on '{slug}' ({addon})\n")

    if not SLUG_RE.match(slug):
        fail(f"slug '{slug}' invalide (attendu: kebab-case minuscule)")
    else:
        ok("slug en kebab-case")

    if not addon.is_dir():
        fail(f"dossier '{slug}' introuvable a la racine du depot")
        return 1
    if addon.parent != REPO:
        fail("l'add-on doit etre un dossier de premiere niveau (profondeur 1)")
    else:
        ok("dossier de premiere niveau (detecte par la CI)")

    # --- fichiers requis -------------------------------------------------
    print("\nFichiers requis")
    config_path = addon / "config.yaml"
    for name in ("config.yaml", "build.yaml", "Dockerfile", "README.md",
                 "icon.png", "logo.png"):
        path = addon / name
        if not path.is_file() or path.stat().st_size == 0:
            fail(f"{name} absent ou vide")
        else:
            ok(name)

    for name in ("translations/en.yaml", "translations/fr.yaml"):
        path = addon / name
        if not path.is_file() or path.stat().st_size == 0:
            fail(f"{name} absent ou vide")
        else:
            ok(name)

    for png in ("icon.png", "logo.png"):
        path = addon / png
        if path.is_file() and path.read_bytes()[:8] != b"\x89PNG\r\n\x1a\n":
            fail(f"{png} n'est pas un PNG valide")

    for name in ("config.yaml", "build.yaml", "Dockerfile"):
        path = addon / name
        if path.is_file():
            check_text_encoding(path)

    if not config_path.is_file():
        return report()

    # --- config.yaml -----------------------------------------------------
    print("\nconfig.yaml")
    config = load_yaml(config_path)
    if not isinstance(config, dict):
        return report()

    for key in REQUIRED_CONFIG_KEYS:
        if key not in config:
            fail(f"cle requise manquante: {key}")
    ok(f"cles requises presentes ({len(REQUIRED_CONFIG_KEYS)} attendues)")

    if config.get("slug") != slug:
        fail(f"slug '{config.get('slug')}' != nom du dossier '{slug}'")
    else:
        ok("slug == nom du dossier")

    version = str(config.get("version", ""))
    if not VERSION_RE.match(version):
        fail(f"version '{version}' invalide (attendu YY.M.patch, ex: 26.9.1)")
    else:
        ok(f"version {version} (format YY.M.patch)")

    image = str(config.get("image", ""))
    if not IMAGE_RE.match(image):
        fail(f"image '{image}' invalide (attendu ghcr.io/legithubdetai/ha_addons/<slug>-{{arch}})")
    elif not image.startswith(f"ghcr.io/legithubdetai/ha_addons/{slug}-"):
        fail(f"image '{image}' ne correspond pas au slug")
    else:
        ok(f"image {image}")

    url = str(config.get("url", ""))
    if not url.endswith(f"/{slug}"):
        warn(f"url '{url}' ne se termine pas par /{slug}")
    else:
        ok("url pointe vers le dossier de l'add-on")

    arches = config.get("arch") or []
    if not arches:
        fail("liste 'arch' vide")
    for arch in arches:
        if arch not in VALID_ARCHES:
            fail(f"architecture inconnue: {arch}")
    ok(f"architectures: {', '.join(map(str, arches))}")

    if not str(config.get("startup", "")) == "application" or config.get("boot") != "auto":
        warn("startup/boot non conformes (attendu startup: application, boot: auto)")

    # --- build.yaml ------------------------------------------------------
    print("\nbuild.yaml")
    build_path = addon / "build.yaml"
    build = load_yaml(build_path) if build_path.is_file() else None
    if isinstance(build, dict):
        build_from = build.get("build_from")
        if build_from is None:
            fail("build_from absent")
        elif isinstance(build_from, dict):
            missing = [a for a in arches if a not in build_from]
            if missing:
                fail(f"build_from sans entree pour: {', '.join(map(str, missing))}")
            else:
                ok("build_from couvre toutes les architectures")
        elif arches:
            warn("build_from unique (pas par architecture)")
        extra = [a for a in build_from if a not in arches] if isinstance(build_from, dict) else []
        if extra:
            warn(f"build_from declare pour des arch non listees: {', '.join(extra)}")

    # --- Dockerfile ------------------------------------------------------
    print("\nDockerfile")
    dockerfile = addon / "Dockerfile"
    if dockerfile.is_file():
        content = dockerfile.read_text(encoding="utf-8", errors="replace")
        if "ARG BUILD_FROM" not in content:
            fail("ARG BUILD_FROM manquant")
        else:
            ok("ARG BUILD_FROM")
        if "FROM ${BUILD_FROM}" not in content:
            fail("FROM ${BUILD_FROM} manquant")
        else:
            ok("FROM ${BUILD_FROM}")
        if 'io.hass.type="addon"' not in content:
            warn('label io.hass.type="addon" absent')
        else:
            ok('label io.hass.type="addon"')
        if not re.search(r"^(HEALTHCHECK|CMD|ENTRYPOINT)", content, re.M):
            warn("aucun HEALTHCHECK/CMD/ENTRYPOINT")

    # --- ingress / ports -------------------------------------------------
    print("\nIngress et ports")
    ingress = bool(config.get("ingress"))
    ports = config.get("ports") or {}
    if not isinstance(ports, dict):
        fail("'ports' n'est pas un mapping")
        ports = {}
    ingress_port = config.get("ingress_port")
    webui = str(config.get("webui", ""))

    if ingress:
        if ingress_port is None:
            fail("ingress: true mais ingress_port absent")
        else:
            if f"{ingress_port}/tcp" not in ports:
                fail(f"ingress_port {ingress_port} absent de 'ports'")
            else:
                ok(f"ingress_port {ingress_port} declare dans ports")
            if f"[PORT:{ingress_port}]" not in webui:
                warn(f"webui ne reference pas [PORT:{ingress_port}]")
            else:
                ok("webui coherent avec ingress_port")
            if ports.get(f"{ingress_port}/tcp") is not None:
                warn(f"port {ingress_port} expose host alors que l'Ingress est actif "
                     "(convention: valeur null)")
        if not ports:
            fail("ingress: true mais section 'ports' vide")
        if "ports_description" not in config:
            warn("ports_description absent")
    else:
        ok("pas d'Ingress (UI non web ou port expose volontairement)")

    host_ports, internal = collect_ports()
    my_host = {str(v).split("/")[0] for v in ports.values() if v is not None}
    for port in sorted(my_host):
        clash = sorted(a for a, used in host_ports.items() if a != slug and port in used)
        if clash:
            fail(f"port hote {port} deja expose par: {', '.join(clash)}")
        else:
            ok(f"port hote {port} libre")

    my_internal = {str(k).split("/")[0] for k in ports}
    if ingress_port is not None:
        my_internal.add(str(ingress_port))
    for port in sorted(my_internal - my_host):
        others = sorted({a for a in internal.get(port, []) if not a.startswith(slug)})
        if others:
            ok(f"port {port} deja utilise en interne par {', '.join(others)} "
               f"(conflit hote: non)")
        else:
            ok(f"port {port} disponible")

    # --- options / schema ------------------------------------------------
    print("\noptions / schema")
    options = config.get("options") or {}
    schema = config.get("schema") or {}
    if not isinstance(options, dict) or not isinstance(schema, dict):
        fail("options/schema ne sont pas des mappings")
    else:
        missing = sorted(set(options) - set(schema))
        extra = sorted(set(schema) - set(options))
        if missing:
            fail(f"cles sans schema: {', '.join(missing)}")
        if extra:
            fail(f"cles de schema sans option: {', '.join(extra)}")
        if not missing and not extra:
            ok(f"parfait parallele options/schema ({len(options)} cles)")
        if "env_vars_list" not in options:
            warn("env_vars_list absent (convention du depot)")

    # --- traductions -----------------------------------------------------
    print("\nTraductions")
    for lang in ("en", "fr"):
        path = addon / "translations" / f"{lang}.yaml"
        if not path.is_file():
            continue
        data = load_yaml(path)
        if not isinstance(data, dict):
            continue
        conf = data.get("configuration") or {}
        net = data.get("network") or {}
        opt_keys = set(options) if isinstance(options, dict) else set()
        missing_opts = sorted(opt_keys - set(conf))
        unknown_opts = sorted(set(conf) - opt_keys)
        if missing_opts:
            fail(f"{lang}: options non traduites: {', '.join(missing_opts)}")
        if unknown_opts:
            fail(f"{lang}: traductions orphelines: {', '.join(unknown_opts)}")
        if not missing_opts and not unknown_opts:
            ok(f"{lang}: configuration complete ({len(conf)} cles)")
        port_keys = {str(k) for k in ports} if isinstance(ports, dict) else set()
        missing_ports = sorted(port_keys - {str(k) for k in net})
        if missing_ports:
            fail(f"{lang}: ports non traduits: {', '.join(missing_ports)}")
        elif port_keys:
            ok(f"{lang}: network complet ({len(net)} entrees)")

    # --- README racine ---------------------------------------------------
    print("\nREADME racine")
    root_readme = REPO / "README.md"
    if root_readme.is_file():
        if f"(./{slug}/)" in root_readme.read_text(encoding="utf-8", errors="replace"):
            ok(f"ligne presente pour {slug}")
        else:
            fail(f"ligne absente du tableau 'Add-ons disponibles' du README racine")
    else:
        fail("README.md racine introuvable")

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
