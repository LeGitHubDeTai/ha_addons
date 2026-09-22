/**
 * Patch ISOMan UI at build time to make it Home Assistant Ingress compatible.
 *
 * Problemes corriges :
 *  - fetch("/api/...") absolu -> sort de l'ingress (/api/isos au lieu de
 *    /api/hassio_ingress/<token>/api/isos) => liste vide, ajout impossible.
 *  - new WebSocket("wss://host/ws") -> hors ingress => progression HS.
 *  - BrowserRouter avec routes absolues (/isos, /stats) -> NotFound sous
 *    sous-chemin ingress. HashRouter (#/isos) fonctionne partout.
 *
 * Execute avec `bun patch-ui.mjs` dans le Dockerfile avant `bun run build`.
 */
import fs from "node:fs";
import path from "node:path";

const root = process.cwd();
console.log(`[ingress-patch] working dir: ${root}`);

function patchFile(relPath, fn) {
  const full = path.join(root, relPath);
  if (!fs.existsSync(full)) {
    console.warn(`[ingress-patch] SKIP (not found): ${relPath}`);
    return false;
  }
  const before = fs.readFileSync(full, "utf8");
  const after = fn(before);
  if (after === before) {
    console.warn(`[ingress-patch] SKIP (no change): ${relPath}`);
    return false;
  }
  fs.writeFileSync(full, after);
  console.log(`[ingress-patch] patched: ${relPath}`);
  return true;
}

// 1) Routage : BrowserRouter -> HashRouter (indispensable sous ingress)
patchFile("src/App.tsx", (s) => {
  let out = s;
  out = out.replaceAll("BrowserRouter", "HashRouter");
  return out;
});

// 2) API REST : base ingress-aware
patchFile("src/lib/api.ts", (s) => {
  const needle =
    "const API_BASE_URL = import.meta.env.PUBLIC_API_URL || '';";
  const replacement = `const getIngressBase = () => {
  try {
    const m = window.location.pathname.match(/(\\/api\\/hassio_ingress\\/[^/]+)/);
    if (m) return m[1];
  } catch {
    /* ignore */
  }
  return '';
};
const API_BASE_URL = import.meta.env.PUBLIC_API_URL || getIngressBase();`;
  if (s.includes(needle)) return s.replace(needle, replacement);
  // Variante avec guillemets doubles
  const needle2 =
    'const API_BASE_URL = import.meta.env.PUBLIC_API_URL || "";';
  if (s.includes(needle2)) return s.replace(needle2, replacement);
  console.warn("[ingress-patch] API_BASE_URL pattern not found, appending helper");
  return s + "\n" + replacement + "\n";
});

// 3) WebSocket : inclure le prefixe ingress (/api/hassio_ingress/<token>/ws)
patchFile("src/hooks/useWebSocket.ts", (s) => {
  const needle =
    "  // In production, use same origin\n  const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';\n  return `${protocol}//${window.location.host}/ws`;";
  const replacement =
    "  // In production, use same origin (ingress-aware for Home Assistant)\n  const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';\n  let ingressBase = '';\n  try {\n    const m = window.location.pathname.match(/(\\/api\\/hassio_ingress\\/[^/]+)/);\n    if (m) ingressBase = m[1];\n  } catch {\n    /* ignore */\n  }\n  return `${protocol}//${window.location.host}${ingressBase}/ws`;";
  if (s.includes(needle)) return s.replace(needle, replacement);
  // Fallback generique : reecrit tout `...host}/ws` en version ingress-aware
  if (s.includes("${window.location.host}/ws")) {
    return s.replaceAll(
      "${window.location.host}/ws",
      "${window.location.host}${(() => { try { const m = window.location.pathname.match(/(\\/api\\/hassio_ingress\\/[^/]+)/); if (m) return m[1]; } catch {} return ''; })()}/ws",
    );
  }
  console.warn("[ingress-patch] useWebSocket pattern not found");
  return s;
});

// 4) Helper global exporte pour d'eventuels liens /images hardcodes
const helper = `export const ingressBase = (() => {
  try {
    const m = window.location.pathname.match(/(\\/api\\/hassio_ingress\\/[^/]+)/);
    if (m) return m[1];
  } catch {
    /* ignore */
  }
  return '';
})();
`;

patchFile("src/lib/api.ts", (s) => {
  if (s.includes("export const ingressBase")) return s;
  return helper + s;
});

console.log("[ingress-patch] done");
