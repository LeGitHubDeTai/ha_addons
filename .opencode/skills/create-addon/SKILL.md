---
name: create-addon
description: Crée/scaffold un nouvel add-on Home Assistant dans le dépôt ha_addons (config.yaml, build.yaml, Dockerfile, translations en/fr, README, icônes, ligne dans le README racine) en respectant strictement les conventions de développement du repo. À utiliser UNIQUEMENT quand l'utilisateur veut créer un addon, demande un "nouveau addon", "new addon", "scaffold", "générer la structure d'un addon", ou "ajouter une application" au dépôt. Ne pas utiliser pour modifier, corriger ou upgrader un addon existant.
---

# Créer un add-on — workflow

Ce skill génère la structure complète d'un add-on Home Assistant conforme aux
conventions de ce dépôt (`ha_addons`), puis la valide automatiquement.

## Règle absolue

**Générer les fichiers uniquement : aucun `git add`, aucun `git commit`, aucun
`git push`, aucune PR.** L'utilisateur review et commit lui-même.
À la fin, se contenter de lister les fichiers créés (`git status --short`).

Tous les fichiers sont écrits en **UTF-8 sans BOM**, fins de ligne **LF**.

---

## Étape 1 — Collecter les informations

Si l'utilisateur n'a pas tout fourni, pose les questions avec l'outil `question`
(une seule appelée, questions groupées) :

| Champ | Obligatoire | Défaut / règle |
|---|---|---|
| Nom affiché (`name`) | oui | ex. `N8N`, `isoman` |
| Slug (dossier) | oui | kebab-case minuscule, **= nom du dossier**, ex. `n8n` |
| Description | oui | 1 phrase, sans saut de ligne, sans `"` non échappés |
| Port interne | oui | port de l'app elle-même, **libre** (voir étape 2) |
| Source de l'app | oui | image upstream (linuxserver, officielle…) / build depuis GitHub |
| Architectures | non | `amd64` + `aarch64` (défaut) |
| Ingress HA | non | `true` si l'app a une UI web |
| Icône `mdi:` | non | ex. `mdi:folder-network` |

---

## Étape 2 — Vérifications préalables

Exécuter **avant** toute génération :

```powershell
# 1. Le dossier existe déjà ?
Test-Path "<slug>"
# si True -> STOP, l'addon existe (utiliser plutôt une modif d'addon existant)

# 2. Slug conforme (kebab-case) : doit matcher ^[a-z0-9]+(-[a-z0-9]+)*$
# 3. Ports déjà utilisés (ingress_port + clés de ports) :
Select-String -Path "*\config.yaml" -Pattern 'ingress_port:|^\s+\d+/tcp:' |
  ForEach-Object { "$($_.Filename): $($_.Line.Trim())" }
# -> le port choisi (et tout port secondaire) ne doit apparaitre nulle part

# 4. Version courante à générer : YY.M.patch, année sur 2 digits, mois SANS zéro initial
#    ex. en septembre 2026 -> "26.9.1"
```

STOP et signaler le conflit si le slug ou un port est déjà pris.

---

## Étape 3 — Générer les fichiers

Arborescence minimale (le dossier doit être **à la racine du dépôt**, profondeur 1,
car la CI détecte les addons avec `find . -maxdepth 2 -name config.yaml`) :

```
<slug>/
├── config.yaml          # obligatoire (déclencheur CI)
├── build.yaml           # obligatoire
├── Dockerfile           # obligatoire
├── README.md            # obligatoire (français)
├── icon.png             # obligatoire (carré, 512x512 de préférence)
├── logo.png             # obligatoire (peut être un bandeau)
├── translations/
│   ├── en.yaml          # obligatoire
│   └── fr.yaml          # obligatoire
└── root/                # optionnel (scripts cont-init / s6) -> aussi un déclencheur CI
```

### 3.1 `config.yaml` — modèle canonique

Remplacer `{{...}}`. Ne jamais inclure de clé inutile, mais **toutes** les clés
ci-dessous font partie du standard du dépôt.

```yaml
name: {{NAME}}
version: "{{VERSION}}"
slug: {{SLUG}}
panel_title: {{NAME}}
panel_icon: "{{MDI_ICON}}"
description: {{DESCRIPTION}}
url: https://github.com/LeGitHubDeTai/ha_addons/tree/main/{{SLUG}}
image: ghcr.io/legithubdetai/ha_addons/{{SLUG}}-{arch}
arch:
  - amd64
  - aarch64
startup: application
boot: auto
init: false
apparmor: true
hassio_role: default
ingress: true
ingress_port: {{PORT}}
ingress_stream: true
webui: http://[HOST]:[PORT:{{PORT}}]/
ports:
  {{PORT}}/tcp: null
ports_description:
  {{PORT}}/tcp: Interface web {{NAME}}. Ingress recommandé, exposition optionnelle.
map:
  - addon_config:rw
  - share:rw
  - media:rw
  - backup:rw
backup_exclude:
  - "{{SLUG}}/logs/*"
options:
  TZ: Europe/Paris
  data_dir: /share/{{SLUG}}
  env_vars_list: []
schema:
  TZ: str
  data_dir: match(/share/.+|/media/.+)
  env_vars_list: [
    "match(^[A-Z_0-9]+: .*$)"
  ]
```

Variantes autorisées selon le besoin :

- **Sans UI web** : retirer `ingress*`, `webui`, `ports`, `ports_description`
  (ou ne garder qu'un port expose volontairement : `{{PORT}}/tcp: {{PORT}}`).
- **map** : entrées possibles `config`, `ssl:ro`, `share`, `media`, `backup`,
  `addon_config`, `homeassistant_config`, `all_addons`, `ssh`.
  Forme longue acceptée aussi :
  ```yaml
  map:
    - type: addon_config
      read_only: false
      path: /config
  ```
- **Option sensible** : type `password`. **Port** : type `port`. **Choix** :
  `list(a|b|c)`. **Chemins partagés** : `match(/share/.+|/media/.+)`.

### 3.2 `build.yaml`

```yaml
build_from:
  amd64: ghcr.io/home-assistant/amd64-base:3.24
  aarch64: ghcr.io/home-assistant/aarch64-base:3.24
labels:
  org.opencontainers.image.title: "{{NAME}}"
  org.opencontainers.image.description: "{{DESCRIPTION}}"
  org.opencontainers.image.source: "https://github.com/LeGitHubDeTai/ha_addons/tree/main/{{SLUG}}"
```

- Toute architecture listée dans `config.yaml: arch` **doit** avoir une entrée
  `build_from` (sinon la CI la « skip » silencieusement).
- Derniers addons du repo : base `ghcr.io/home-assistant/<arch>-base:3.24`.
- Addon « proxy » d'une image upstream (style linuxserver) : mettre l'image
  upstream dans `build_from` à la place (voir `nzbget/build.yaml`).

### 3.3 `Dockerfile`

Squelette obligatoire — la CI passe `BUILD_FROM`, `BUILD_VERSION`, `BUILD_ARCH` :

```dockerfile
ARG BUILD_FROM
ARG BUILD_VERSION
ARG BUILD_ARCH

FROM ${BUILD_FROM}

ARG BUILD_VERSION
ARG BUILD_ARCH

LABEL \
    io.hass.version="${BUILD_VERSION}" \
    io.hass.type="addon" \
    io.hass.arch="${BUILD_ARCH}"

RUN apk add --no-cache \
    bash \
    ca-certificates \
    curl \
    tzdata

# --- installation de l'application ---
# ARG {{SLUG_UPPER}}_VERSION={{UPSTREAM_VERSION}}
# (voir webdav/Dockerfile pour un téléchargement d'upstream multi-arch,
#  planka/Dockerfile pour un build, nzbget/Dockerfile pour une image linuxserver)

# --- scripts partagés du dépôt (.scripts/) ---
# La CI copie dans le contexte : ha_automodules.sh, ha_autoapps.sh,
# ha_entrypoint.sh, bashio-standalone.sh, ha_lsio.sh
# MAIS scripts/build-local.sh ne les copie pas -> préférer le téléchargement
# direct (cf. nzbget/Dockerfile) :
#   curl -fL -sS https://raw.githubusercontent.com/LeGitHubDeTai/ha_addons/main/.scripts/bashio-standalone.sh \
#     -o /usr/local/lib/bashio-standalone.sh

EXPOSE {{PORT}}

HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD curl -fsS http://127.0.0.1:{{PORT}}/ || exit 1

ENTRYPOINT ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
# ou CMD ["/run.sh"] / ENTRYPOINT ["/init"] selon l'image de base
```

### 3.4 `README.md` (français)

Sections attendues : `# Add-on {{NAME}} pour Home Assistant`, phrase
d'introduction, `## Installation`, `## Configuration` (tableau
Option | Description | Défaut), `## Ports` (si UI), `## Ingress`, `## Support`,
`## Licence`.

### 3.5 `translations/en.yaml` et `translations/fr.yaml`

**Une entrée par option ET par port**, clés identiques au `config.yaml` :

```yaml
configuration:
  TZ:
    name: Timezone
    description: Set the timezone for the container.
  data_dir:
    name: Data directory
    description: Folder used by the add-on (e.g. /share/{{SLUG}}).
  env_vars_list:
    name: Extra environment variables
    description: 'Free environment variables as "KEY: value".'
network:
  {{PORT}}/tcp: {{NAME}} web interface (Ingress recommended)
```

```yaml
configuration:
  TZ:
    name: Fuseau horaire
    description: Définit le fuseau horaire du conteneur.
  data_dir:
    name: Dossier de données
    description: Dossier utilisé par l'add-on (ex. /share/{{SLUG}}).
  env_vars_list:
    name: Variables d'environnement supplémentaires
    description: 'Variables d''environnement libres au format "CLE: valeur".'
network:
  {{PORT}}/tcp: Interface web {{NAME}} (Ingress recommandé)
```

### 3.6 `icon.png` / `logo.png`

Fichiers PNG **réels** (pas de placeholder) : récupérer le logo officiel de
l'upstream (site, repo GitHub, `/assets`, favicon) via `webfetch`/`curl`, ou
dégrossir depuis un PNG existant du dépôt. `icon.png` carré 512×512 de
préférence ; `logo.png` peut être un bandeau. Si aucun logo n'est trouvable,
le signaler explicitement dans le résumé final (TODO).

---

## Étape 4 — Fichiers dérivés (dans le dépôt)

1. **`README.md` à la racine** : ajouter une ligne dans le tableau
   `## Add-ons disponibles` :

   ```markdown
   | [**{{NAME}}**](./{{SLUG}}/) | {{DESCRIPTION courte}} | {{PORT}} |
   ```

   L'ajout se fait en fin de tableau (l'ordre n'est pas alphabétique).

2. **Workflow d'auto-upgrade (optionnel, seulement si demandé)** :
   `.github/workflows/auto-upgrade-<slug>.yml` à copier depuis
   `auto-upgrade-scanopy.yml` en remplaçant le slug, **uniquement** si :
   - l'upstream publie des releases GitHub, **et**
   - le `Dockerfile` contient `ARG <SLUG>_VERSION=...`.
   Les labels `auto-upgrade`, `dependencies`, `latest`, `pre-release`
   doivent déjà exister sur le repo.

---

## Étape 5 — Validation (obligatoire)

```powershell
python .opencode/skills/create-addon/validate.py <slug>
```

Le script vérifie : présence/lecture des fichiers, clés `config.yaml` requises,
`slug == dossier`, format de `version`, schéma `image`, parité
`arch` ⇄ `build_from`, cohérence ingress/webui/ports, unicité des ports dans
tout le dépôt, parité options ⇄ schema, traductions complètes, `Dockerfile`
(`ARG BUILD_FROM`, `FROM ${BUILD_FROM}`, label `io.hass.type`), présence de
`icon.png`/`logo.png`/`README.md` et de la ligne dans le README racine.

**Tout ❌ doit être corrigé avant le résumé.** Relancer jusqu'à :
`All checks passed`.

Puis montrer ce qui a été créé, sans committer :

```powershell
git status --short
```

---

## Étape 6 — Résumé

Lister : dossier créé, fichiers générés, version retenue, port retenu,
éventuels TODO (logo absent, app non testée, Dockerfile à compléter), et
rappeler les étapes **manuelles** suivantes :

1. compléter le `Dockerfile` (installation réelle de l'app) ;
2. tester en local : `./scripts/build-local.sh <slug>` ;
3. committer/pousser soi-même (soit sur `main`, soit sur une branche
   `<slug>-dev` / `dev-<slug>` qui déclenche un build « dev » image
   `dev-<slug>-<arch>`).

---

## Conventions de développement (checklist)

- [ ] Dossier à la racine, nom = slug, kebab-case, pas de point initial.
- [ ] `config.yaml` : `name`, `version "YY.M.patch"`, `slug`, `description`,
      `url`, `image: ghcr.io/legithubdetai/ha_addons/<slug>-{arch}`, `arch`,
      `startup: application`, `boot: auto`, `init: false`, `hassio_role`,
      `panel_icon`, `panel_title`.
- [ ] `image` **exactement** `ghcr.io/legithubdetai/ha_addons/<slug>-{arch}`
      (owner en minuscules : la CI pousse `ghcr.io/legithubdetai/ha_addons/<slug>-<arch>:<version>`).
- [ ] `version` entre guillemets, format `YY.M.patch` (mois sans zéro initial).
- [ ] `build.yaml` : `build_from` avec **une entrée par architecture**.
- [ ] `Dockerfile` : `ARG BUILD_FROM` avant `FROM`, labels `io.hass.*`.
- [ ] Si `ingress: true` → `ingress_port` + `webui` + `ports: <p>/tcp: null`
      + `ports_description` qui recommande l'Ingress.
- [ ] Ports non utilisés par un autre addon du dépôt.
- [ ] `options` et `schema` ont **exactement les mêmes clés**, plus `env_vars_list`.
- [ ] `translations/en.yaml` **et** `fr.yaml` : chaque option + chaque port.
- [ ] `README.md` français, `icon.png`, `logo.png`.
- [ ] Ligne ajoutée dans le `README.md` racine.
- [ ] Aucun commit / push.

## Pièges connus

- La CI (`docker-build-publish.yml`) ne détecte que les addons à profondeur 1
  et déclenche sur `**/config.yaml`, `**/Dockerfile`, `**/build.yaml`,
  `**/root/**` — pas sur `translations/**` ou `README.md`.
- `arch` sans entrée `build_from` correspondante ⇒ build silencieusement sauté.
- Images « dev » : branche `main` → `<slug>-<arch>`, autre branche →
  `dev-<slug>-<arch>`.
- Les scripts `.scripts/` copiés dans le contexte par la CI ne le sont pas en
  build local : privilégier un `curl` sur raw.githubusercontent.com.
- Ne pas écrire de `"` non échappés dans `description` (YAML).
- Vérifier l'unicité du port **avant** d'écrire le `config.yaml`, pas après.
