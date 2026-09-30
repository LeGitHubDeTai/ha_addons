# Requestly — Open-Source HTTP Interceptor & API Mocks
# Source : https://github.com/requestly/interceptor (branche master, app/ = web UI Vite)
# Build : compilation du front (app/build) puis servi en statique via nginx (comme storybook).
ARG BUILD_FROM
ARG BUILD_CONFIG_FILE
ARG BUILD_VERSION
ARG BUILD_ARCH

# Version informative de l'app upstream (app/package.json). Mise à jour par le workflow auto-upgrade-requestly.
ARG REQUESTLY_APP_VERSION=26.8.14
ARG REQUESTLY_REF=master

# ===============================
# BUILDER : compile la web UI
# ===============================
FROM node:20-bookworm AS builder

ARG REQUESTLY_REF
ARG REQUESTLY_APP_VERSION

ENV CI=false
ENV GENERATE_SOURCEMAP=false
ENV NODE_OPTIONS=--max-old-space-size=4096

RUN apt-get update \
    && apt-get install -y --no-install-recommends git python3 make g++ \
    && rm -rf /var/lib/apt/lists /var/cache/apt/archives

WORKDIR /src

# Clone peu profond de la branche suivie (défaut: master)
RUN git clone --depth 1 --branch ${REQUESTLY_REF} https://github.com/requestly/interceptor.git .

# Installation complète (root core + shared + app + rule-processor + analytics-vendors + extension).
# L'extension navigateur n'est pas servie par l'add-on, mais install.sh l'installe — on l'accepte pour rester fidèle à l'upstream.
RUN sh ./install.sh

# Build des modules requis par app/ (sans l'extension navigateur pour gagner du temps)
RUN cd common/analytics-vendors && sh build.sh && cd ../..
RUN cd common/rule-processor && sh build.sh && cd ../..
RUN npm run build
RUN cd shared && npm run build && cd ..

# Self-host (HA) : l'upstream redirige tout hostname non allowlisté vers
# https://app.requestly.io (voir le <script> en tête de app/index.html : seuls
# localhost, IP nues et *.requestly.io passent). Derrière HA (ingress,
# homeassistant.local, duckdns...) ça rend l'add-on inutilisable.
# On neutralise donc cette redirection avant compilation. Le build échoue
# volontairement si le motif upstream change, pour le détecter.
RUN python3 <<'EOF'
import pathlib
p = pathlib.Path("app/index.html")
s = p.read_text()
old = 'window.location.href = "https://app.requestly.io";'
assert old in s, "motif de redirection introuvable dans app/index.html (l'upstream a changé ?)"
p.write_text(s.replace(old, "/* self-hosted (HA addon) : redirection cloud desactivee */;"))
print("index.html patche : redirection cloud neutralisee")
EOF

# Self-host (HA) : le bundle charge tree-sitter*.wasm via Emscripten avec
# `locateFile: (f) => "/" + f` (URL construite a l'execution, jamais en
# litteral : sub_filter ne peut pas la voir — verifie sur l'image publiee).
# Sous ingress, /tree-sitter.wasm sort du prefixe -> 404 HA.
# On injecte donc un shim fetch/XHR en tete de index.html, qui re-prefixe ces
# URLs sous ingress (no-op en acces direct). Independant des noms minifies,
# teste avec node (syntaxe + comportement ingress/direct).
# Le build echoue volontairement si l'ancre upstream change, pour le detecter.
RUN python3 <<'PYEOF'
import pathlib
p = pathlib.Path("app/index.html")
s = p.read_text()
marker = "HA-INGRESS-WASM-SHIM"
assert marker not in s, "shim wasm deja present dans app/index.html ?!"
anchor = "<head>"
assert s.count(anchor) == 1, "ancre <head> introuvable ou ambigue dans app/index.html (l'upstream a change ?)"
shim = """
<script>
/* HA-INGRESS-WASM-SHIM : l'app charge /tree-sitter*.wasm en absolu (Emscripten
   locateFile => "/" + f), ce qui sort du prefixe ingress -> 404. Ce shim
   re-prefixe ces requetes fetch/XHR sous ingress. No-op en acces direct. */
(function () {
  var m = window.location.pathname.match(/^\\/api\\/hassio_ingress\\/[^/]+/);
  if (!m) return;
  var prefix = m[0];
  var ROOTS = { "/tree-sitter.wasm": 1, "/tree-sitter-bash.wasm": 1 };
  function fixUrl(u) {
    try {
      var p = new URL(u, window.location.href);
      if (p.origin === window.location.origin && ROOTS[p.pathname]) {
        return prefix + p.pathname + p.search;
      }
    } catch (e) {}
    return u;
  }
  var origFetch = window.fetch;
  window.fetch = function (input, init) {
    if (typeof input === "string") {
      input = fixUrl(input);
    } else if (typeof Request !== "undefined" && input instanceof Request) {
      var u = fixUrl(input.url);
      if (u !== input.url) input = new Request(new URL(u, window.location.href).href, input);
    }
    return origFetch.call(this, input, init);
  };
  var origOpen = XMLHttpRequest.prototype.open;
  XMLHttpRequest.prototype.open = function (method, url, async, user, password) {
    return origOpen.call(this, method, fixUrl(url), async, user, password);
  };
})();
</script>
"""
p.write_text(s.replace(anchor, anchor + shim, 1))
print("index.html patche : shim wasm ingress injecte")
PYEOF

# Patch HA Ingress : basename react-router calcule depuis /api/hassio_ingress/<token>.
# Sans ça, react-router compare le chemin ingress a des routes type /rules, n'en
# reconnait aucune et l'ecran reste blanc meme quand le bundle se charge.
# Les URL absolues du bundle (/assets/...) sont reecrites cote nginx (sub_filter +
# X-Ingress-Path, cf. nginx.conf), rien a patcher la-dessus.
COPY patch-ingress.py /tmp/patch-ingress.py
RUN python3 /tmp/patch-ingress.py

# Build de la web app (vite build -> app/build/)
RUN cd app && npm run build && ls -la build | head -20

# Garde-fou : nginx reecrit les URL de type /assets/... (cf. nginx.conf), le HTML
# servi doit donc bien referencer le bundle ainsi. Sinon le build echoue, plutot que
# de publier une image ou le bundle 404 de nouveau sous ingress.
RUN if ! grep -q 'src="/assets/' app/build/index.html; then \
        echo "ERREUR : index.html ne reference pas le bundle via /assets/ (regles sub_filter de nginx.conf inutiles)"; \
        exit 1; \
    fi \
    && echo "OK : bundle reference en /assets/ (sub_filter nginx couvre l'ingress)"

# Garde-fou : les .wasm servis a la racine (cf. regles sub_filter de nginx.conf)
# doivent bien exister dans le build (viteStaticCopy dest "."). Sinon le build
# echoue, plutot que de publier une image ou ils 404 sous ingress.
RUN for f in tree-sitter.wasm tree-sitter-bash.wasm; do \
        if [ ! -f "app/build/$f" ]; then \
            echo "ERREUR : app/build/$f manquant (l'upstream a change le build ?)"; \
            exit 1; \
        fi; \
    done \
    && echo "OK : .wasm racine presents dans le build"

# Garde-fou : le shim wasm doit avoir survécu a la compilation dans le HTML
RUN if ! grep -q 'HA-INGRESS-WASM-SHIM' app/build/index.html; then echo "ERREUR : shim wasm absent du build"; exit 1; fi \
    && echo "OK : shim wasm present dans le build"

# Garde-fou : le HTML servi ne doit plus contenir la redirection cloud
RUN if grep -q 'window.location.href = "https://app.requestly.io"' app/build/index.html; then echo "ERREUR : redirection cloud toujours presente dans le build"; exit 1; fi \
    && echo "OK : pas de redirection cloud dans le build"

# ===============================
# RUNTIME : HA base + nginx statique
# ===============================
FROM ${BUILD_FROM}

ARG BUILD_VERSION
ARG BUILD_ARCH
ARG BUILD_CONFIG_FILE
ARG REQUESTLY_APP_VERSION
ARG REQUESTLY_REF

LABEL \
  io.hass.version="${BUILD_VERSION}" \
  io.hass.type="addon" \
  io.hass.arch="${BUILD_ARCH}" \
  org.opencontainers.image.title="Requestly" \
  org.opencontainers.image.description="Intercepteur HTTP, mocks d'API et débogage réseau (Requestly)" \
  org.opencontainers.image.source="https://github.com/LeGitHubDeTai/ha_addons/tree/main/requestly" \
  org.opencontainers.image.url="https://requestly.com/" \
  org.opencontainers.image.version="${REQUESTLY_APP_VERSION}"

RUN apk add --no-cache \
    nginx \
    supervisor \
    bash \
    ca-certificates \
    tzdata

RUN mkdir -p /usr/share/nginx/html /var/log/supervisor /run/nginx

# Web UI compilée
COPY --from=builder /src/app/build/ /usr/share/nginx/html/

COPY nginx.conf /etc/nginx/nginx.conf
COPY supervisord.conf /etc/supervisord.conf

EXPOSE 3000

ENTRYPOINT ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
