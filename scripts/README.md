# Scripts de Build Local

Ce répertoire contient des scripts pour builder les addons Home Assistant en local, en se basant sur les workflows GitHub Actions.

## build-local.sh

Script de build local pour les addons Home Assistant, basé sur le workflow `.github/workflows/docker-build-publish.yml`.

### Prérequis

- Docker et Docker Buildx
- `yq` (YAML processor) - https://github.com/mikefarah/yq
- `jq` (JSON processor)
- Git (pour la détection des changements)

### Installation des dépendances

```bash
# Installer yq (Linux/macOS)
wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/local/bin/yq
chmod +x /usr/local/bin/yq

# Ou avec brew (macOS)
brew install yq

# Installer jq (Ubuntu/Debian)
sudo apt-get install jq

# Ou avec brew (macOS)
brew install jq
```

### Usage

```bash
# Rendre le script exécutable
chmod +x scripts/build-local.sh

# Détecter les changements et builder les addons modifiés
./scripts/build-local.sh

# Builder un addon spécifique
./scripts/build-local.sh planka

# Builder tous les addons
./scripts/build-local.sh -a

# Builder et pousser vers le registre
./scripts/build-local.sh -p planka

# Forcer le rebuild même si l'image existe
./scripts/build-local.sh -f planka

# Afficher l'aide
./scripts/build-local.sh -h
```

### Options

- `-h, --help` : Afficher l'aide
- `-p, --push` : Pousser les images vers le registre (défaut: local seulement)
- `-f, --force` : Forcer le build même si l'image existe déjà
- `-a, --all` : Builder tous les addons (défaut: détecter les changements)
- `-c, --container` : Builder dans un container Docker isolé
- `--skip-existing` : Skipper les builds si l'image existe déjà (défaut: true)
- `--no-skip-existing` : Ne pas skipper les builds même si l'image existe

### Build dans un container Docker

Le script peut builder dans un container Docker isolé avec l'option `-c`. C'est utile pour:

- **Isolation complète** : Le build s'exécute dans un environnement propre et isolé
- **Pas de dépendances locales** : Seul Docker est requis sur la machine hôte
- **Cohérence** : Environnement de build identique à celui des CI/CD
- **Sécurité** : Les builds ne polluent pas l'environnement local

#### Fonctionnalités du mode container:

1. **Docker-in-Docker** : Utilise l'image `docker:24-dind` pour exécuter Docker dans le container
2. **Volume persistant** : Le cache Docker est conservé entre les builds
3. **Auto-installation** : Les dépendances (yq, jq) sont installées automatiquement
4. **Nettoyage automatique** : Le container est automatiquement supprimé à la fin

#### Prérequis pour le mode container:

- Docker (sur la machine hôte)
- Accès internet (pour télécharger les dépendances)

#### Exemples d'utilisation:

```bash
# Builder dans un container
./scripts/build-local.sh -c planka

# Builder tous les addons dans un container et pousser
./scripts/build-local.sh -c -a -p

# Forcer le rebuild dans un container
./scripts/build-local.sh -c -f planka
```

### Fonctionnalités

1. **Détection automatique des changements** : Utilise `git diff` pour détecter les addons modifiés depuis le dernier commit
2. **Vérification des versions** : Compare les versions locales avec celles sur GHCR pour éviter les builds inutiles
3. **Support multi-architectures** : Build pour toutes les architectures définies dans `config.yaml`
4. **Cache Docker** : Utilise le cache local pour accélérer les builds
5. **Build local ou push** : Option pour builder uniquement en local ou pousser vers le registre
6. **Gestion des erreurs** : Arrête le script en cas d'erreur avec des messages clairs

### Exemples d'utilisation

```bash
# Builder uniquement les addons modifiés depuis le dernier commit
./scripts/build-local.sh

# Builder l'addon planka et pousser vers GHCR
./scripts/build-local.sh -p planka

# Forcer le rebuild de tous les addons
./scripts/build-local.sh -a -f

# Builder tous les addons mais skipper ceux qui existent déjà
./scripts/build-local.sh -a --skip-existing

# Builder dans un container Docker isolé
./scripts/build-local.sh -c planka

# Builder tous les addons dans un container et pousser
./scripts/build-local.sh -c -a -p
```

### Structure des fichiers

Le script s'attend à trouver la structure suivante pour chaque addon:

```
addon/
├── config.yaml      # Configuration de l'addon (version, slug, arch)
├── build.yaml       # Configuration de build (images de base)
├── Dockerfile       # Instructions de build Docker
└── root/            # Fichiers de l'addon (optionnel)
```

### Variables d'environnement

Les variables suivantes peuvent être configurées dans le script:

- `REGISTRY` : Registre Docker (défaut: ghcr.io)
- `OWNER` : Propriétaire du registre (défaut: legithubdetai)
- `REPO_PREFIX` : Préfixe du dépôt (défaut: ha_addons)

### Cache

Le script utilise un cache local dans `./.build-cache` pour accélérer les builds successifs. Le cache est automatiquement géré entre les builds.

### Logs

Le script fournit des logs colorés et détaillés pour suivre le processus de build:

- 📦 Information sur les addons
- 🔨 Étapes de build
- ✅ Succès
- ⚠️ Avertissements
- ❌ Erreurs
