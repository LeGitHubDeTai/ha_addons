#!/usr/bin/env python3
"""Rend le frontend Deemix précompilé compatible avec Home Assistant Ingress.

Contexte : derrière l'Ingress, l'app est servie sous
`/api/hassio_ingress/<token>/`, mais le client construit des URLs absolues
depuis `window.location.origin` / `location.host` (donc sans le préfixe) :
  - API  : `${window.location.origin}${location.base}api/...` avec `location.base = "/"`
  - WS   : `(wss://|ws://) + location.host + "/"`
  - CSS  : `url(/fonts/...)` absolus non quotés (invisibles pour sub_filter nginx)

Correctifs (idempotents, avec assertions strictes : le build échoue si
l'upstream change, plutôt que de livrer un frontend cassé) :
  P1. `location.base = "/"` -> calculé depuis `location.pathname`
      (couvre TOUS les appels API + la base du routeur vue-router).
  P2. URL WebSocket -> préfixe ingress calculé en ligne (autonome : le module
      socket s'évalue avant que main.ts n'assigne location.base).
  P3. CSS `url(/fonts/` -> `url(../fonts/` (relatif : valide en accès direct
      comme derrière l'Ingress, sans dépendre de nginx).

Note : les motifs utilisent des littéraux regex (jamais de chaîne `"/api/`),
donc ils survivent intacts au sub_filter nginx de l'add-on.
"""

import pathlib
import sys

PUBLIC_DIR = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else pathlib.Path(
    "/app/packages/webui/dist/public"
)

# Préfixe Ingress HA : /api/hassio_ingress/<token> (+ éventuel suffixe de route SPA)
INGRESS_PREFIX_RE = r"^\/api\/hassio_ingress\/[^/]+"

# P1 : base API + base du routeur (couvre fetchData, postToServer, sendToServer, createWebHistory)
OLD_BASE = 'location.base="/"'
NEW_BASE = (
    "location.base=function(p){var m=p.match(/"
    + INGRESS_PREFIX_RE
    + "/);return m?m[0]+\"/\":\"/\"}(location.pathname)"
)

# P2 : WebSocket (ne DOIT PAS utiliser location.base : ordre d'évaluation des modules)
OLD_WS = 'location.host+"/"'
NEW_WS = (
    "location.host+((location.pathname.match(/"
    + INGRESS_PREFIX_RE
    + '/)||[""])[0]+"/")'
)


def patch_js(old: str, new: str, expect_total: int, what: str) -> None:
    total_old = 0
    total_new = 0
    for f in sorted(PUBLIC_DIR.joinpath("assets").glob("*.js")):
        s = f.read_text(encoding="utf-8")
        n_old = s.count(old)
        n_new = s.count(new)
        total_old += n_old
        total_new += n_new
        if n_old:
            f.write_text(s.replace(old, new), encoding="utf-8")
            print(f"  {f.name} : {n_old} remplacement(s) [{what}]")
    if total_old == 0 and total_new >= 1:
        print(f"  déjà patché [{what}], ignoré")
        return
    if total_old != expect_total:
        print(
            f"ERREUR : motif [{what}] trouvé {total_old} fois (attendu {expect_total}). "
            "L'upstream a changé, patch à revoir !",
            file=sys.stderr,
        )
        sys.exit(1)


def patch_css() -> None:
    total = 0
    already = 0
    for f in sorted(PUBLIC_DIR.joinpath("assets").glob("*.css")):
        s = f.read_text(encoding="utf-8")
        n = s.count("url(/fonts/")
        already += s.count("url(../fonts/")
        if n:
            f.write_text(s.replace("url(/fonts/", "url(../fonts/)"), encoding="utf-8")
            print(f"  {f.name} : {n} remplacement(s) [css fonts relatifs]")
        total += n
    if total == 0 and already >= 1:
        print("  css déjà patché [css fonts relatifs], ignoré")
        return
    if total < 1:
        print(
            "ERREUR : aucun url(/fonts/ dans le CSS. L'upstream a changé, patch à revoir !",
            file=sys.stderr,
        )
        sys.exit(1)


def main() -> None:
    if not PUBLIC_DIR.is_dir():
        print(f"ERREUR : dossier introuvable : {PUBLIC_DIR}", file=sys.stderr)
        sys.exit(1)
    print(f"Patch frontend Deemix dans {PUBLIC_DIR}")
    patch_js(OLD_BASE, NEW_BASE, 1, "location.base ingress-aware (API + router)")
    patch_js(OLD_WS, NEW_WS, 1, "WebSocket ingress-aware")
    patch_css()
    print("Patch frontend OK")


if __name__ == "__main__":
    main()
