# WebDAV - Home Assistant Add-on

Serveur WebDAV simple et autonome (basé sur [hacdias/webdav](https://github.com/hacdias/webdav)),
pour accéder à vos fichiers Home Assistant depuis n'importe quel client WebDAV
(Windows, macOS, Linux, Android, iOS, Nextcloud, Synology, etc.).

## Utilisation

1. Installez et démarrez l'add-on.
2. Exposez le port `6065` si besoin (mappé par défaut à `6065`).
3. Connectez votre client à :
   - `http://<homeassistant>:6065/` (dossier racine ou dossiers virtuels)
   - Exemple avec dossiers virtuels : `http://<homeassistant>:6065/fichiers`, `.../share`, `.../media`, `.../backup`

Un simple navigateur affiche aussi la liste des fichiers.

## Configuration

```yaml
username: hass
password: changeme
anonymous: false
readonly: false
data_dir: /share/webdav
expose_share: true
expose_media: true
expose_backup: true
expose_config: false
extra_users: []
ssl: false
certfile: fullchain.pem
keyfile: privkey.pem
debug: false
prefix: /
```

### Options

| Option | Description | Défaut |
|---|---|---|
| `username` | Utilisateur principal (auth basique) | `hass` |
| `password` | Mot de passe principal | `changeme` |
| `anonymous` | Si `true`, aucun mot de passe requis (dangereux) | `false` |
| `readonly` | Si `true`, accès lecture seule (`R` au lieu de `CRUD`) | `false` |
| `data_dir` | Dossier principal exposé (`/share/webdav` par défaut, créé auto) | `/share/webdav` |
| `expose_share` | Expose `/share` en dossier virtuel `share` | `true` |
| `expose_media` | Expose `/media` en dossier virtuel `media` | `true` |
| `expose_backup` | Expose `/backup` en dossier virtuel `backup` (pratique pour sauvegardes externes) | `true` |
| `expose_config` | Expose la config HA en dossier virtuel `config` | `false` |
| `extra_users` | Utilisateurs supplémentaires `{username, password}` | `[]` |
| `ssl` | Active TLS directement dans WebDAV avec `/ssl/certfile` + `/ssl/keyfile` | `false` |
| `certfile` | Certificat dans `/ssl` | `fullchain.pem` |
| `keyfile` | Clé privée dans `/ssl` | `privkey.pem` |
| `debug` | Logs détaillés | `false` |
| `prefix` | Préfixe URL (laisser `/` sauf reverse-proxy en sous-chemin) | `/` |

Exemple multi-utilisateurs :

```yaml
username: hass
password: motdepasse-fort
extra_users:
  - username: telephone
    password: autre-motdepasse-fort
  - username: invite
    password: invite123
```

> Changez toujours les mots de passe par défaut ! Les secrets HA (`secrets.yaml`) sont supportés via `!secret`.

### Mode d'exposition

- Si au moins un `expose_*` est à `true` : mode **dossiers virtuels**.
  La racine contient `fichiers` (= `data_dir`), `share`, `media`, `backup`, `config` selon vos choix.
- Si tous les `expose_*` sont à `false` : le contenu de `data_dir` est servi **directement à la racine**.

### Ports

| Port | Description |
|---|---|
| `6065/tcp` | Serveur WebDAV (à exposer pour un accès hors HA) |

Pas d'Ingress : WebDAV nécessite les méthodes `PROPFIND/PROPPATCH/MKCOL/COPY/MOVE/LOCK`
qui ne passent pas par le proxy Ingress. Utilisez le port direct.

### Clients testés

- Windows : Explorateur > `Ajouter un emplacement réseau`
- macOS : Finder > `Se connecter au serveur...` (`⌘K`)
- Android : CX Explorateur, Solid Explorer, Round-Sync (rclone)
- iOS : Documents, FileBrowser
- Sauvegardes : Synology Hyper Backup (WebDAV), Nextcloud (montage externe WebDAV)
- Ligne de commande : `rclone`, `cadaver`, `curl -u user:pass -T fichier http://ha:6065/fichiers/`

### Sécurité

- Utilisez un mot de passe fort et, si exposé sur Internet, passez par HTTPS
  (reverse-proxy type Nginx Proxy Manager / Cloudflared) ou activez `ssl`.
- Ne laissez `anonymous: true` que sur un réseau local de confiance, voire jamais.
- Le mode `readonly: true` est utile pour un partage public sans risque de suppression.
