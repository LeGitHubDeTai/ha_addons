#!/usr/bin/env python3
"""Rend la web UI Requestly compatible avec l'ingress Home Assistant.

A executer dans le clone de requestly/interceptor (/src) avant `npm run build`
(voir Dockerfile).

Contexte :
  Home Assistant sert l'add-on sous /api/hassio_ingress/<token>/, mais le proxy
  retire ce prefixe avant d'atteindre nginx. react-router, lui, observe l'URL
  complete : sans basename, aucune route ne matche et l'application reste sur un
  ecran blanc (meme si le bundle se charge correctement).

  Les URL absolues du bundle (/assets/...) sortiraient elles aussi de l'ingress ;
  elles sont reecrites cote nginx au moment de la reponse (sub_filter +
  X-Ingress-Path, cf. nginx.conf). Rien a patcher de ce cote.

Le build echoue volontairement si un motif upstream a bouge, plutot que de
publier un add-on casse en silence.
"""

import pathlib
import sys

ROOT = pathlib.Path.cwd()
FAILURES = []


def patch(rel_path: str, marker: str, old: str, new: str) -> None:
    path = ROOT / rel_path
    if not path.is_file():
        FAILURES.append(f"{rel_path}: fichier introuvable")
        return

    src = path.read_text(encoding="utf-8")
    if marker in src:
        print(f"[ingress-patch] deja applique: {rel_path}")
        return
    if old not in src:
        FAILURES.append(f"{rel_path}: motif introuvable (l'upstream a change ?)")
        return

    path.write_text(src.replace(old, new, 1), encoding="utf-8")
    print(f"[ingress-patch] patche: {rel_path}")


# react-router doit connaitre le prefixe /api/hassio_ingress/<token>/ (basename),
# sinon aucune route ne matche sous ingress -> ecran blanc.
OLD_APP = r"""const App = () => {
  const router = Sentry.wrapCreateBrowserRouterV6(createBrowserRouter)(routesV2);"""

NEW_APP = r"""// HA Ingress : l'app est publiee sous /api/hassio_ingress/<token>/ alors que le
// proxy retire ce prefixe avant nginx. react-router a besoin de ce prefixe en
// basename, sinon il compare /api/hassio_ingress/<token>/ a des routes du type
// /rules et n'en reconnait aucune (ecran blanc).
// En acces direct (port 3000) il n'y a pas de prefixe -> basename indefini.
const getIngressBasename = () => {
  const match = window.location.pathname.match(/^\/api\/hassio_ingress\/[^/]+/);
  return match ? match[0] : undefined;
};

const App = () => {
  const router = Sentry.wrapCreateBrowserRouterV6(createBrowserRouter)(routesV2, {
    basename: getIngressBasename(),
  });"""

patch("app/src/App.tsx", "getIngressBasename", OLD_APP, NEW_APP)

if FAILURES:
    print("[ingress-patch] ECHEC:", file=sys.stderr)
    for failure in FAILURES:
        print(f"  - {failure}", file=sys.stderr)
    sys.exit(1)

print("[ingress-patch] OK")
