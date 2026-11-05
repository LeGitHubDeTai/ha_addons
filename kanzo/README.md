# Add-on Kanzo pour Home Assistant

**Kanzo** est un petit tableau Kanban auto-hébergé, pensé pour vous **et** vos agents IA : le board vit dans votre navigateur et un serveur MCP permet à vos agents (Claude Code, Codex…) de déplacer les cartes, commenter et suivre les tâches. Un binaire unique de quelques mégaoctets, sans dépendance de base de données.

- Dépôt upstream : [emanuele-em/kanzo](https://github.com/emanuele-em/kanzo)
- Licence : [AGPL-3.0](https://github.com/emanuele-em/kanzo/blob/main/LICENSE)

## Installation

1. Ajoutez ce dépôt d'add-ons dans Home Assistant (ou cette repo déjà présente).
2. Installez l'add-on **Kanzo** depuis la chaîne d'add-ons.
3. Démarrez l'add-on et ouvrez l'interface via l'**Ingress** (onglet « Open Web UI »).

## Configuration

| Option | Description | Défaut |
|--------|-------------|--------|
| `TZ` | Fuseau horaire du conteneur. | `Europe/Paris` |
| `data_dir` | Dossier de données (board `kanzo.db`, réglages `config.toml`). Doit être sous `/share/` ou `/media/`. | `/share/kanzo` |
| `env_vars_list` | Variables d'environnement supplémentaires au format `CLE: valeur`. | `[]` |

À noter :

- **Construction depuis les sources** : les binaires précompilés upstream
  (releases GitHub) contiennent des instructions BMI2 (`sarx`/`shlx`/`shrx`)
  qui provoquent un crash silencieux (SIGILL) au démarrage sur les CPU sans
  BMI2 (avant Haswell, anciennes VM). L'add-on compile donc Kanzo avec
  l'outilchain Alpine pour garantir l'ISA de base (x86-64 / armv8).
- Au premier démarrage, l'add-on crée `config.toml` avec `port = 4242`, `listen = "0.0.0.0"` et `mcp_http = true` (le serveur MCP est disponible sur `/mcp`).
- L'écoute est forcée sur `0.0.0.0` dans le conteneur, nécessaire pour l'Ingress HA ; l'exposition réseau réelle reste maîtrisée par les options de port de l'add-on.

## Ports

| Port | Usage |
|------|-------|
| `4242/tcp` | Interface web Kanzo. Normalement non exposé : l'Ingress Home Assistant est recommandé. Vous pouvez exposer ce port pour contourner l'Ingress (panel_iframe, client externe…). |

## Ingress

L'add-on supporte l'**Ingress** Home Assistant : l'interface est accessible depuis la sidebar HA sans ouvrir de port, de manière sécurisée (recommandé).

## Support

- Issues upstream : [github.com/emanuele-em/kanzo/issues](https://github.com/emanuele-em/kanzo/issues)
- Issues sur l'add-on : [github.com/LeGitHubDeTai/ha_addons/issues](https://github.com/LeGitHubDeTai/ha_addons/issues)

## Licence

Kanzo est sous licence [AGPL-3.0](https://github.com/emanuele-em/kanzo/blob/main/LICENSE). Cet add-on est fourni sans garantie.
