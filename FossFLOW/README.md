# FossFLOW Home Assistant Add-on

## Description

FossFLOW est un add-on pour Home Assistant qui vous permet de créer de magnifiques diagrammes d'infrastructure isométriques. Cet outil open source offre une interface intuitive pour visualiser et documenter vos architectures systèmes, réseaux et infrastructures.

## Fonctionnalités

- **Diagrammes isométriques** : Créez des représentations visuelles élégantes de votre infrastructure
- **Interface web moderne** : Interface utilisateur intuitive accessible via Home Assistant
- **Stockage serveur** : Sauvegardez vos diagrammes directement sur le serveur
- **Support Git** : Option de sauvegarde automatique via Git (désactivé par défaut)
- **Accès via Ingress** : Intégration transparente dans l'interface Home Assistant

## Installation

### Prérequis

- Home Assistant avec Supervisor
- Accès internet pour télécharger l'add-on

### Installation

1. Ajoutez ce dépôt à vos dépôts d'add-ons Home Assistant :
   ```
   https://github.com/LeGitHubDeTai/ha_addons
   ```

2. Allez dans `Supervisor` > `Add-on Store`
3. Cherchez `FossFLOW` et cliquez sur `Installer`

## Configuration

### Configuration de base

Après l'installation, configurez les options suivantes dans l'add-on :

- **Port** : Port d'accès à l'interface web (par défaut : 4000)
- **Enable Server Storage** : Active le stockage des diagrammes sur le serveur (par défaut : true)
- **Enable Git Backup** : Active les sauvegardes Git (par défaut : false)

### Variables d'environnement

L'add-on utilise les variables d'environnement suivantes :

- `NODE_ENV=production` : Mode de production Node.js
- `ENABLE_SERVER_STORAGE=true` : Stockage serveur activé
- `STORAGE_PATH=/data/diagrams` : Chemin de stockage des diagrammes
- `ENABLE_GIT_BACKUP=false` : Sauvegarde Git désactivée

### Accès

- **Via Home Assistant** : Accédez à FossFLOW via le panneau latéral ou l'ingress
- **URL directe** : `http://<votre_ip_homeassistant>:4000`

## Utilisation

1. **Lancement** : Démarrez l'add-on depuis l'interface Supervisor
2. **Accès** : Cliquez sur "Ouvrir l'interface web" ou accédez via l'ingress
3. **Création** : Utilisez l'interface pour créer vos diagrammes d'infrastructure
4. **Sauvegarde** : Vos diagrammes sont automatiquement sauvegardés dans `/data/diagrams`

## Stockage des données

Les diagrammes sont stockés dans le dossier de données de l'add-on :
- Chemin interne : `/data/diagrams`
- Accès depuis Home Assistant : Via l'onglet "Stockage" de l'add-on

## Dépannage

### Problèmes courants

**L'add-on ne démarre pas**
- Vérifiez les logs dans Supervisor
- Assurez-vous que le port 4000 n'est pas utilisé par une autre application

**L'interface n'est pas accessible**
- Vérifiez que l'ingress est activé dans la configuration
- Essayez d'accéder directement via `http://<ip>:4000`

**Les diagrammes ne se sauvegardent pas**
- Vérifiez que `Enable Server Storage` est activé dans les options
- Vérifiez les permissions du dossier de données

### Logs

Pour consulter les logs de l'add-on :
1. Allez dans `Supervisor` > `Add-ons` > `FossFLOW`
2. Cliquez sur l'onglet `Logs`

## Développement

### Structure des fichiers

```
FossFLOW/
├── config.yaml          # Configuration de l'add-on
├── build.yaml          # Configuration de build
├── Dockerfile           # Configuration Docker
└── README.md           # Ce fichier
```

### Version

- Version actuelle : 26.1.2
- Image Docker : `stnsmith/fossflow:master-35aaa2c`

## Support

Pour toute question ou problème :
- Créez une issue sur le dépôt GitHub
- Consultez la documentation officielle de FossFLOW

## Licence

Cet add-on est sous licence MIT.
FossFLOW est également un projet open source.

## Liens utiles

- [Dépôt FossFLOW](https://github.com/stan-smith/FossFLOW)
- [Documentation Home Assistant](https://www.home-assistant.io/docs/)
- [Dépôt de cet add-on](https://github.com/LeGitHubDeTai/ha_addons)
