# Penpot - Home Assistant Add-on

Penpot est la première plateforme open-source de design et de prototypage pour les équipes design & code.
Dessins, prototypes interactifs, design systems : tout fonctionne avec des standards ouverts (SVG, CSS, HTML).

Cet add-on embarque Penpot en un seul conteneur : PostgreSQL + Valkey + backend + frontend + exporter + MCP,
avec accès via l'Ingress Home Assistant.

## Installation

[![Open your Home Assistant instance and show the dashboard of an add-on.](https://my.home-assistant.io/badges/supervisor_addon.svg)](https://my.home-assistant.io/redirect/supervisor_addon/?repository_url=https%3A%2F%2Fgithub.com%2FLeGitHubDeTai%2Fha_addons%2F&addon=penpot)

Ou manuellement :

1. Ajoutez ce dépôt : `https://github.com/LeGitHubDeTai/ha_addons`
2. Cherchez "Penpot" dans la boutique, cliquez **Installer**.
3. Configurez (voir ci-dessous), puis **Démarrer**.
4. Ouvrez l'interface via **Ouvrir l'interface utilisateur** (Ingress).

> Premier démarrage : Penpot initialise PostgreSQL et exécute les migrations (~1-3 min selon la machine).
> Laissez l'add-on démarrer, puis créez votre compte depuis la page d'inscription.

## Configuration

```yaml
timezone: Europe/Paris
secret_key: ""
db_password: ""
allow_registration: true
disable_telemetry: true
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
| `db_password` | Mot de passe PostgreSQL interne. Laisser vide = généré et persisté | (auto) |
| `allow_registration` | Autoriser la création de comptes (`enable-registration`) | `true` |
| `disable_telemetry` | Désactiver la télémétrie anonyme Penpot | `true` |
| `smtp_host` | Serveur SMTP (vide = emails désactivés) | (vide) |
| `smtp_port` | Port SMTP | `587` |
| `smtp_username` / `smtp_password` | Authentification SMTP | (vide) |
| `smtp_from` / `smtp_reply_to` | Adresses d'expédition | `no-reply@example.com` |

⚠️ Ne changez pas `secret_key` / `db_password` après le premier démarrage : vous perdriez l'accès
aux sessions et à la base (restaurez depuis un backup le cas échéant).

Pour verrouiller l'instance après avoir créé vos comptes : `allow_registration: false` + redémarrer.

## Accès réseau

- **Ingress (recommandé)** : port interne `9001`, authentification Home Assistant incluse.
- **Port `9001/tcp`** : exposé à `null` par défaut. Exposez-le si vous voulez contourner l'Ingress
  (ex. reverse-proxy externe). La vérification d'e-mail et les cookies sécurisés sont désactivés
  par défaut pour rester compatibles avec un usage en HTTP local ; ne les activez que derrière HTTPS.

## Données & sauvegardes

- Données persistées dans `/data/penpot` : base PostgreSQL, assets, secrets générés.
- `backup_exclude` ignore déjà le dossier PostgreSQL volumineux ; pensez à sauvegarder
  régulièrement via les backups Home Assistant.

## Ressources

- Penpot : <https://penpot.app>
- Documentation self-hosting : <https://help.penpot.app/technical-guide/getting-started/docker>
- Configuration : <https://help.penpot.app/technical-guide/configuration/>
- Dépôt : <https://github.com/penpot/penpot>

## Licence

Penpot est distribué sous licence MPL-2.0. Cet add-on ne fait que l'empaqueter pour Home Assistant.
