# Add-on CTFREAK pour Home Assistant

[CTFREAK](https://ctfreak.com) est un planificateur de tâches IT auto-hébergé : une application web unique pour créer, planifier, exécuter et surveiller des tâches sur vos serveurs et bases de données. Aucun agent n'est installé sur les cibles — CTFREAK se connecte via SSH ou WinRM, et aux bases de données via leurs protocoles natifs.

## Installation

1. Installez l'add-on depuis la boutique de modules complémentaires de Home Assistant.
2. Démarrez l'add-on.
3. Connectez-vous à l'interface web avec les identifiants par défaut : **admin** / **ctfreak**.
4. Changez immédiatement le mot de passe par défaut dans les paramètres.

## Configuration

| Option | Description | Défaut |
|--------|-------------|--------|
| `TZ` | Fuseau horaire utilisé pour planifier les tâches | `Europe/Paris` |
| `data_dir` | Dossier de données (configuration, base embarquée, journaux) | `/share/ctfreak` |
| `env_vars_list` | Variables d'environnement supplémentaires au format `CLE: valeur` | *vide* |

## Ports

| Port | Description |
|------|-------------|
| `6700/tcp` | Interface web CTFREAK. Normalement non exposé — Home Assistant Ingress est recommandé. |

## Ingress

L'add-on supporte Home Assistant Ingress : l'interface web est accessible directement depuis le panneau Home Assistant, sans exposer le port sur le réseau local.

## Support

- [Documentation officielle CTFREAK](https://ctfreak.com/docs)
- [Dépôt de l'add-on](https://github.com/LeGitHubDeTai/ha_addons/tree/main/ctfreak)

## Licence

CTFREAK est un logiciel propriétaire de [JYP Software](https://jyp.software). L'édition Free est utilisable gratuitement avec des limites (tâches, utilisateurs, exécutions concurrentes). Consultez la [page pricing](https://ctfreak.com/#pricing) pour plus de détails.
