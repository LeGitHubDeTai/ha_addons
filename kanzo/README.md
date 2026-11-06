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
- **Architecture** : un reverse proxy nginx (`nginx.conf`) expose le port
  conteneur `4243`, à la fois pour l'Ingress HA (non publié par défaut) et
  pour l'accès réseau direct (publié sur le port hôte). Kanzo lui-même
  écoute sur `127.0.0.1:4242` : nginx réécrit Host/Origin et les URLs
  absolues de Kanzo, qui ne supporte pas nativement l'Ingress.
- Au premier démarrage, l'add-on crée `config.toml` avec `port = 4242`,
  `listen = "127.0.0.1"` et `mcp_http = true` (le serveur MCP est disponible
  sur `/mcp`). `port` et `listen` sont forcés à ces valeurs à chaque
  démarrage : nginx attend Kanzo sur `127.0.0.1:4242`.

## Ports

| Port | Usage |
|------|-------|
| `4243/tcp` | Interface web Kanzo via nginx. Normalement non exposée : l'Ingress Home Assistant est recommandé. Vous pouvez exposer ce port (idéalement sur le port hôte `4242`, celui que Kanzo affiche dans ses instructions de partage) pour un accès réseau direct (panel_iframe, clients MCP externes…). |

## Ingress

L'add-on supporte l'**Ingress** Home Assistant : l'interface est accessible depuis la sidebar HA sans ouvrir de port, de manière sécurisée (recommandé).

Kanzo n'est pas compatible avec l'Ingress de sa version actuelle (URLs absolues `fetch("/api")`, `src="/app.js"`… et contrôles Host/Origin stricts). L'add-on place donc un reverse proxy nginx devant lui, qui :

- reconnaît les requêtes Ingress (`X-Ingress-Path`, posé par HA core après filtrage, non falsifiable par le navigateur) et réécrit les URLs relatives (`/api`, `/images`, `/app.js`, `/logo.png`) avec le préfixe d'Ingress ;
- présente à Kanzo une identité `localhost:4242` acceptée par ses contrôles, après avoir vérifié le vrai Host/Origin reçus (anti DNS-rebinding / CSRF) ;
- n'autorise la gestion du réseau Kanzo (rejoindre/quitter un board) que depuis l'Ingress authentifié, comme Kanzo upstream ne l'autorise qu'à l'ordinateur qui porte le board.

### Accès réseau direct (sans Ingress)

Exposez le port `4243/tcp` de l'add-on (port hôte suggéré : `4242`). Depuis un autre poste :

- interface web : `http://<IP-HA>:4242/` — le Host doit être une adresse IP ou `localhost` (les noms de domaine sont refusés, comme chez Kanzo upstream) ;
- MCP : `http://<IP-HA>:4242/mcp`.

À savoir : les adresses IP affichées par Kanzo (`kanzo join …`) sont celles du conteneur Docker ; utilisez l'IP de l'hôte Home Assistant et le port `4242`.

## Support

- Issues upstream : [github.com/emanuele-em/kanzo/issues](https://github.com/emanuele-em/kanzo/issues)
- Issues sur l'add-on : [github.com/LeGitHubDeTai/ha_addons/issues](https://github.com/LeGitHubDeTai/ha_addons/issues)

## Licence

Kanzo est sous licence [AGPL-3.0](https://github.com/emanuele-em/kanzo/blob/main/LICENSE). Cet add-on est fourni sans garantie.
