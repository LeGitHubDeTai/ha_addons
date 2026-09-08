# Tai Studio - Home Assistant Add-ons

> Une collection d'applications auto-hébergées empaquetées en add-ons Home Assistant

<a href="https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2FLeGitHubDeTai%2Fha_addons">
  <img src="https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg" alt="Ajouter le dépôt à Home Assistant" />
</a>

---

## Installation

1. Ouvrez **Home Assistant** > **Paramètres** > **Modules complémentaires** > **Boutique de modules complémentaires**
2. Cliquez sur le menu ⋮ (3 points) et sélectionnez **Dépôt**
3. Ajoutez cette URL : `https://github.com/LeGitHubDeTai/ha_addons`
4. Les add-ons seront disponibles dans la boutique

---

## Add-ons disponibles

| Add-on | Description | Port |
|--------|-------------|------|
| [**n8n**](./n8n/) | Automatisation de workflows (alternative à Zapier) | 5690 |
| [**Gitea**](./gitea/) | Service Git auto-hébergé | 3000 |
| [**Syncthing**](./syncthing/) | Synchronisation décentralisée de fichiers | 8384 |
| [**Cloudflared**](./cloudflared/) | Tunnel Cloudflare pour l'accès distant sécurisé | - |
| [**Draw.io**](./drawio/) | Éditeur de diagrammes | 1665 |
| [**Drawnix**](./drawnix/) | Tableau blanc (cartes mentales, organigrammes) | 7200 |
| [**FossFLOW**](./FossFLOW/) | Outil de diagrammes isométriques d'infrastructure | 4000 |
| [**Docmost**](./docmost/) | Wiki et documentation auto-hébergée | 5200 |
| [**Planka**](./planka/) | Tableau Kanban (alternative à Trello) | 1337 |
| [**Dolibarr**](./dolibarr/) | Système ERP/CRM | 8080 |
| [**Obsidian**](./obsidian/) | Gestion de notes et connaissances | 3000 |
| [**Mopidy**](./mopidy/) | Serveur musical avec support Spotify/Bandcamp | 6680 |
| [**ISOMan**](./isoman/) | Gestionnaire d'ISOs Linux | 50145 |

---

## Fonctionnalités

- **Multi-architectures** : Supporte `amd64` et `aarch64`
- **Home Assistant Ingress** : Accès web sécurisé via l'interface HA
- **CI/CD automatisé** : Build et publication via GitHub Actions
- **Montages SMB/NFS** : Support pour le stockage réseau
- **Variables d'environnement** : Injection des options HA vers les conteneurs
- **Secrets supportés** : Via `secrets.yaml` de Home Assistant
- **Exclusion de backup** : Configuration pour les gros volumes de données

---

## Développement local

### Prérequis

- Docker avec Buildx
- `yq` (processeur YAML)
- `jq` (processeur JSON)
- Git

### Commandes

```bash
# Cloner le dépôt
git clone https://github.com/LeGitHubDeTai/ha_addons.git
cd ha_addons

# Builder un add-on spécifique
./scripts/build-local.sh planka

# Builder tous les add-ons
./scripts/build-local.sh -a

# Builder et pousser vers le registry
./scripts/build-local.sh -p planka

# Builder dans un conteneur isolé
./scripts/build-local.sh -c planka
```

### Options du script de build

| Option | Description |
|--------|-------------|
| `-h, --help` | Afficher l'aide |
| `-p, --push` | Pousser les images vers GHCR |
| `-f, --force` | Forcer le rebuild même si l'image existe |
| `-a, --all` | Builder tous les add-ons |
| `-c, --container` | Builder dans un conteneur Docker isolé |

---

## Architecture du projet

```
ha_addons/
├── .scripts/              # Scripts partagés (entrée, variables, mounts)
├── .github/workflows/     # CI/CD (13 workflows)
├── scripts/               # Script de build local
├── n8n/                   # Chaque add-on contient :
├── gitea/                 #   - config.yaml (métadonnées)
├── syncthing/             #   - Dockerfile
├── planka/                #   - build.yaml
├── ...                    #   - logo.png
└── repository.yaml
```

---

## Scripts partagés (`.scripts/`)

| Script | Description |
|--------|-------------|
| `ha_entrypoint.sh` | Point d'entrée principal du conteneur |
| `ha_automodules.sh` | Téléchargement auto de scripts depuis GitHub |
| `00-global_var.sh` | Conversion des options HA en variables d'env |
| `00-smb_mounts.sh` | Support mounts SMB/NFS |
| `01-config_yaml.sh` | Traitement de la configuration YAML |
| `bashio-standalone.sh` | Bibliothèque bashio autonome |

---

## License

Les add-ons sont basés sur les licences de leurs projets respectifs. Consultez chaque dossier pour plus d'informations.

---

## Soutenir le projet

<a href="https://github.com/sponsors/LeGitHubDeTai">
  <img src="https://img.shields.io/badge/Sponsor-GitHub%20Sponsors-ea4aaa" alt="Sponsor sur GitHub" />
</a>

**Maintenu par** [Tai Studio](mailto:tai.studio@outlook.fr)
