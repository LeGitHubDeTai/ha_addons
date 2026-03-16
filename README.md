# Home Assistant Addons - Tai Studio

Ce dépôt contient les addons Home Assistant personnalisés de Tai Studio, avec des builds Docker automatisés via GitHub Actions.

<a href="https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2FLeGitHubDeTai%2Fha_addons">
  <img src="https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg" alt="Open your Home Assistant instance" />
</a>

## 🚀 Fonctionnalités

- **Builds automatiques** : Les images Docker sont construites automatiquement lors des modifications
- **Multi-architecture** : Support AMD64, ARM64 et ARMv7
- **Détection intelligente** : Seuls les addons modifiés sont rebuildés
- **Releases automatisées** : Tags Git pour créer des releases
- **SBOM inclus** : Software Bill of Materials pour chaque image

## 📦 Addons disponibles

- **FossFLOW** : Créez de beaux diagrammes d'infrastructure isométriques
- **dolibarr** : ERP/CRM pour petites entreprises
- **mopidy** : Serveur de musique extensible
- **n8n** : Automatisation et workflow
- **obsidian** : Prise de notes et connaissance
- **planka** : Gestion de projet Kanban
- **syncthing** : Synchronisation de fichiers décentralisée

## 🔧 Installation

### Via Home Assistant Supervisor

1. Allez dans **Supervisor** → **Add-on Store**
2. Cliquez sur les trois points en haut à droite
4. Choisissez **Addons** → **Ajouter un dépôt**
5. Entrez l'URL : `https://github.com/LeGitHubDeTai/ha_addons`
6. Les addons apparaîtront dans la liste

### Manuellement

Ajoutez ce repository à votre configuration Home Assistant :

```yaml
# configuration.yaml
homeassistant:
  # ... votre configuration existante

# Dans Supervisor → Add-on Store → Repositories
# Ajouter : https://github.com/LeGitHubDeTai/ha_addons
```

## 🏗️ Workflow GitHub Actions

### Build automatique (`.github/workflows/build-addons.yml`)

Déclenché par :
- **Push** sur `main/master` dans les dossiers d'addons
- **Pull Request** sur `main/master` 
- **Manuel** via `workflow_dispatch`

Fonctionnalités :
- Détection des addons modifiés avec `dorny/paths-filter`
- Build multi-architecture (AMD64, ARM64, ARMv7)
- Push sur `ghcr.io` uniquement pour les commits (pas les PRs)
- Génération de SBOM
- Cache GitHub Actions pour optimiser les builds

### Release (`.github/workflows/release.yml`)

Déclenché par :
- **Tags Git** (ex: `v1.0.0`)

Fonctionnalités :
- Build de tous les addons
- Création automatique de release GitHub
- Upload des SBOM comme assets de release
- Tags sémantiques automatiques

## 🐳 Images Docker

Les images sont publiées sur :

```
ghcr.io/legithubdetai/addon-name:version
```

Exemples :
- `ghcr.io/legithubdetai/fossflow:26.1.2`
- `ghcr.io/legithubdetai/n8n:latest`

**Note** : Les noms d'images sont automatiquement convertis en minuscules pour respecter les exigences de GitHub Container Registry.

## 🔄 Développement

### Structure d'un addon

```
addon-name/
├── config.yaml      # Configuration Home Assistant
├── Dockerfile       # Build Docker
├── run.sh          # Script de démarrage (optionnel)
└── ...             # Autres fichiers
```

### Ajouter un nouvel addon

1. Créez un nouveau dossier avec le nom de l'addon
2. Ajoutez `config.yaml` et `Dockerfile`
3. Le workflow détectera automatiquement le nouvel addon

### Modifier un addon existant

1. Faites vos modifications dans le dossier de l'addon
2. Push sur `main` pour déclencher un build automatique
3. Seul l'addon modifié sera rebuildé

## 🛠️ Configuration requise

- Home Assistant 2023.1+
- Supervisor (pour les addons)
- Accès internet pour les pulls d'images

## 📝 Support

Pour les problèmes liés aux addons :
- Ouvrez une **issue** sur ce dépôt
- Décrivez le problème et votre configuration

Pour les problèmes liés au workflow :
- Vérifiez les logs GitHub Actions
- Consultez la section "Actions" du dépôt

## 📄 Licence

Ce dépôt est sous licence MIT. Voir le fichier `LICENSE` pour plus de détails.

## 🤝 Contribution

Les contributions sont bienvenues ! 
1. Fork ce dépôt
2. Créez une branche pour votre fonctionnalité
3. Submittez une Pull Request

---

**Tai Studio** - *Solutions Home Assistant personnalisées*
