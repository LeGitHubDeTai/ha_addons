# Add-on TimescaleDB pour Home Assistant

TimescaleDB étend PostgreSQL avec des **hypertables**, des *continuous aggregates*
et une compression adaptée aux séries temporelles : idéal pour stocker les
historiques de capteurs, les métriques ou toute donnée horodatée, avec les
outils SQL classiques (psql, DBeaver, Grafana, Node-RED...).

## Installation

1. Ajoutez ce dépôt dans Home Assistant : **Paramètres > Modules complémentaires > ⋮ > Dépôt** avec l'URL `https://github.com/LeGitHubDeTai/ha_addons`
2. Recherchez **TimescaleDB** dans la boutique et cliquez **Installer**
3. Configurez les options puis démarrez l'add-on
4. Ajoutez le tableau de bord si souhaité

## Configuration

| Option | Description | Défaut |
|--------|-------------|--------|
| `TZ` | Fuseau horaire du conteneur | `Europe/Paris` |
| `data_dir` | Dossier du cluster PostgreSQL (doit être sous `/share` ou `/media`) | `/share/timescaledb` |
| `db_name` | Base créée au premier démarrage | `homeassistant` |
| `db_user` | Utilisateur de connexion créé au premier démarrage (propriétaire de la base) | `hass` |
| `db_password` | Mot de passe de l'utilisateur (aussi appliqué à `postgres`) | `changeme` |
| `env_vars_list` | Variables d'environnement libres (`CLE: valeur`) | `[]` |

> Changez `db_password` avant la première mise en production, puis redémarrez
> l'add-on : le mot de passe est réappliqué à chaque démarrage.

À la première connexion :

```sql
CREATE EXTENSION IF NOT EXISTS timescaledb;
CREATE TABLE mesures (time timestamptz NOT NULL, valeur double precision);
SELECT create_hypertable('mesures', 'time');
```

## Ports

| Port | Description |
|------|-------------|
| `5432/tcp` | Port PostgreSQL/TimescaleDB, exposé sur l'hôte (modifiable, ou `null` pour ne pas exposer) |

## Ingress

Non disponible : TimescaleDB n'a pas d'interface web native. La connexion se
fait en TCP depuis le réseau local (`homeassistant.local:5432`) ou depuis un
autre add-on (Grafana, Node-RED...).

## Support

Ouvrez une issue sur le dépôt [LeGitHubDeTai/ha_addons](https://github.com/LeGitHubDeTai/ha_addons/issues).

## Licence

TimescaleDB est sous licence [Apache 2.0](https://github.com/timescale/timescaledb/blob/main/LICENSE). Les add-ons de ce dépôt sont fournis « en l'état ».
