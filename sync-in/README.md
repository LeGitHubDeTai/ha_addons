# Add-on Sync-in pour Home Assistant

Sync-in est une suite collaborative auto-hébergée : documents, tableurs,
présentations et synchronisation de fichiers, avec édition en temps réel.

Cet add-on embarque le serveur **Sync-in** (image officielle
[`syncin/server`](https://hub.docker.com/r/syncin/server)) et une base
**MariaDB** dans un seul conteneur.

## Installation

1. Ajoutez ce dépôt de add-ons à Home Assistant (ou mettez-le à jour).
2. Installez l'add-on **Sync-in**.
3. Ajustez les options (voir ci-dessous) puis démarrez l'add-on.
4. Ouvrez l'interface web via **Ingress** (recommandé) ou le port `8080`.

Au premier démarrage, un compte administrateur est créé avec les identifiants
par défaut :

- identifiant : `sync-in`
- mot de passe : `sync-in`

➡️ Changez ces identifiants dès la première connexion, ou définissez les
options `init_admin_login` / `init_admin_password` **avant** le premier
démarrage.

## Configuration

| Option | Description | Défaut |
|--------|-------------|--------|
| `TZ` | Fuseau horaire du conteneur | `Europe/Paris` |
| `data_dir` | Dossier de stockage des fichiers Sync-in (doit être dans `/share` ou `/media`). Sync-in impose le chemin interne `/app/data` : ce lien y est redirigé. | `/share/sync-in` |
| `public_url` | URL publique utilisée pour les notifications et les éditeurs bureautiques (optionnelle pour l'instant). | vide |
| `db_root_password` | Mot de passe root de MariaDB. Laisser vide pour en générer un automatiquement. | vide |
| `encryption_key` | Clé de chiffrement des secrets MFA (fortement recommandée). Laisser vide pour en générer une. | vide |
| `access_secret` | Secret des jetons d'accès. Laisser vide pour en générer un. | vide |
| `refresh_secret` | Secret des jetons de rafraîchissement. Laisser vide pour en générer un. | vide |
| `init_admin_login` | Identifiant du compte administrateur créé au premier démarrage. | vide (`sync-in`) |
| `init_admin_password` | Mot de passe du compte administrateur créé au premier démarrage. | vide (`sync-in`) |
| `env_vars_list` | Variables d'environnement supplémentaires au format `CLE: valeur` (ex. `SYNCIN_SERVER_PUBLICURL: https://exemple.fr`). | `[]` |

Les secrets laissés vides sont générés aléatoirement au premier démarrage puis
mémorisés dans `/data/.secrets` : ils restent stables après redémarrage et
sont inclus dans les sauvegardes de l'add-on.

> Les options sont réappliquées dans `environment.yaml` à chaque démarrage :
> l'add-on est la source de vérité pour ces valeurs.

## Ports

| Port | Usage |
|------|-------|
| `8080/tcp` | Interface web Sync-in. Non exposé par défaut (Ingress recommandé). |

## Ingress

L'add-on est accessible via Home Assistant Ingress. Si vous utilisez les
éditeurs bureautiques (Collabora, OnlyOffice, draw.io), exposez le port `8080`
et renseignez `public_url` avec l'URL utilisée par les navigateurs.

## Limites connues

- Les **éditeurs bureautiques** (Collabora, OnlyOffice, draw.io, EuroOffice)
  ne sont pas inclus : ils exigent des conteneurs supplémentaires. Ils peuvent
  être pointés vers des instances externes via `env_vars_list` (variables
  `SYNCIN_APPLICATIONS_FILES_EDITORS_*`).
- **MariaDB** est embarqué dans l'add-on (base `sync_in`) : ses données sont
  stockées dans `/data/mariadb` et incluses dans les sauvegardes de l'add-on.
  Les fichiers Sync-in, eux, vivent dans `data_dir` (`/share/sync-in` par
  défaut), donc dans les sauvegardes **complètes** Home Assistant.
- Add-on non encore testé en production : signalez tout souci via les issues
  du dépôt.

## Support

- Documentation upstream : https://sync-in.com/fr/docs/setup-guide/docker/
- Issues du dépôt : https://github.com/LeGitHubDeTai/ha_addons/issues

## Licence

Ce add-on est distribué selon les conditions de licence du projet Sync-in
(https://github.com/Sync-in/server).
