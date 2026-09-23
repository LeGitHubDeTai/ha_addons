# Penpot - Home Assistant Add-on

Penpot est la première plateforme open-source de design et de prototypage pour les équipes design & code.
Dessins, prototypes interactifs, design systems : tout fonctionne avec des standards ouverts (SVG, CSS, HTML).

Cet add-on embarque Penpot en un seul conteneur : backend + frontend + exporter + MCP + Valkey (cache éphémère),
avec accès via l'Ingress Home Assistant.

> **PostgreSQL externe requis** : l'add-on n'embarque plus de base de données. Pointez-le vers votre
> serveur PostgreSQL (géré par vous, via Home Assistant ou ailleurs) avec les options `DATABASE` ci-dessous.

## Installation

[![Open your Home Assistant instance and show the dashboard of an add-on.](https://my.home-assistant.io/badges/supervisor_addon.svg)](https://my.home-assistant.io/redirect/supervisor_addon/?repository_url=https%3A%2F%2Fgithub.com%2FLeGitHubDeTai%2Fha_addons%2F&addon=penpot)

Ou manuellement :

1. Préparez un serveur PostgreSQL 15+ accessible depuis Home Assistant et créez-y un rôle + une base :
   ```sql
   CREATE USER penpot WITH PASSWORD 'un-mot-de-passe-sûr';
   CREATE DATABASE penpot OWNER penpot;
   ```
2. Ajoutez ce dépôt : `https://github.com/LeGitHubDeTai/ha_addons`
3. Cherchez "Penpot" dans la boutique, cliquez **Installer**.
4. Renseignez `DATABASE` (voir ci-dessous), puis **Démarrer**.
5. Ouvrez l'interface via **Ouvrir l'interface utilisateur** (Ingress).

> Premier démarrage : Penpot exécute les migrations sur votre base (~1-3 min selon la machine).
> Laissez l'add-on démarrer, puis créez votre compte depuis la page d'inscription.

## Configuration

```yaml
timezone: Europe/Paris
secret_key: ""
allow_registration: true
disable_telemetry: true
DATABASE:
  db_host: "192.168.1.10"
  db_port: 5432
  db_user: penpot
  db_password: "un-mot-de-passe-sûr"
  db_name: penpot
REDIS:
  redis_host: "localhost"
  redis_port: 6379
  redis_db: 0
smtp_host: ""
smtp_port: 587
smtp_username: ""
smtp_password: ""
smtp_from: "no-reply@example.com"
smtp_reply_to: "no-reply@example.com"
```

| Option | Description | Défaut |
|---|---|---|
| `timezone` | Fuseau horaire | `Europe/Paris` |
| `secret_key` | Clé maîtresse Penpot (`PENPOT_SECRET_KEY`). Laisser vide = générée et persistée dans `/data/penpot/.secret_key` | (auto) |
| `allow_registration` | Autoriser la création de comptes (`enable-registration`) | `true` |
| `disable_telemetry` | Désactiver la télémétrie anonyme Penpot | `true` |
| `DATABASE.db_host` | Hôte du serveur PostgreSQL externe (**requis**, ex. IP ou nom d'hôte) | (vide) |
| `DATABASE.db_port` | Port PostgreSQL | `5432` |
| `DATABASE.db_user` / `DATABASE.db_password` / `DATABASE.db_name` | Rôle, mot de passe et base (doivent exister, voir installation) | `penpot` / (vide) / `penpot` |
| `REDIS.redis_host` / `redis_port` / `redis_db` | Valkey/Redis. `localhost` = cache éphémère embarqué ; renseignez un hôte pour utiliser un serveur externe | `localhost` / `6379` / `0` |
| `smtp_host` | Serveur SMTP (vide = emails désactivés) | (vide) |
| `smtp_port` | Port SMTP | `587` |
| `smtp_username` / `smtp_password` | Authentification SMTP | (vide) |
| `smtp_from` / `smtp_reply_to` | Adresses d'expédition | `no-reply@example.com` |

⚠️ Ne changez pas `secret_key` après le premier démarrage : vous invalideriez sessions et invitations
(restaurez depuis un backup le cas échéant). Les migrations du schéma sont appliquées automatiquement
au démarrage par le backend.

Pour verrouiller l'instance après avoir créé vos comptes : `allow_registration: false` + redémarrer.

## Accès réseau

- **Ingress (recommandé)** : port interne `9001`, authentification Home Assistant incluse.
- **Port `9001/tcp`** : exposé à `null` par défaut. Exposez-le si vous voulez contourner l'Ingress
  (ex. reverse-proxy externe). La vérification d'e-mail et les cookies sécurisés sont désactivés
  par défaut pour rester compatibles avec un usage en HTTP local ; ne les activez que derrière HTTPS.

## Données & sauvegardes

- Données persistées dans `/data/penpot` : assets (fichiers uploadés) et clé secrète générée.
  Le cache Valkey embarqué est **éphémère** (rien à sauvegarder).
- **La base PostgreSQL vit sur votre serveur externe : pensez à la sauvegarder de votre côté**
  (l'add-on ne la sauvegarde pas). Pensez aussi aux backups Home Assistant pour les assets.

## Ressources

- Penpot : <https://penpot.app>
- Documentation self-hosting : <https://help.penpot.app/technical-guide/getting-started/docker>
- Configuration : <https://help.penpot.app/technical-guide/configuration/>
- Dépôt : <https://github.com/penpot/penpot>

## Licence

Penpot est distribué sous licence MPL-2.0. Cet add-on ne fait que l'empaqueter pour Home Assistant.
