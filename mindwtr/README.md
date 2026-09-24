# Mindwtr Add-on

Mind mapping et gestion de tâches auto-hébergés (basé sur [Mindwtr](https://github.com/dongdongbh/Mindwtr), image construite depuis `docker/` upstream).

**Principe : vous ne configurez que la synchronisation, tout le reste est automatique** (dossier de données, ports, CORS, URL Cloud pré-remplie).

## Installation

1. Dans Home Assistant : **Paramètres → Modules complémentaires → ⋮ → Dépôts**, ajoutez `https://github.com/LeGitHubDeTai/ha_addons`
2. Cherchez **Mindwtr**, installez, démarrez
3. Ouvrez l'interface web (port `8080` ou via Ingress)

## Configuration : un seul choix à faire

```yaml
sync_mode: local
```

| Mode | Ce que fait l'add-on | À faire dans l'app |
|------|----------------------|--------------------|
| `local` (défaut) | Aucun serveur de sync. L'interface web seule. | Rien : les données restent dans ce navigateur (dossiers locaux). |
| `selfhosted` | Démarre le serveur **Mindwtr Cloud** intégré (sync multi-appareils + API REST). | `Paramètres → Sync → Self-Hosted` : URL `http://<ip-ha>:8787`, jeton = votre `cloud_tokens`. |
| `webdav` | Aucun serveur. Interface web seule. | `Paramètres → Sync → WebDAV` : URL, identifiant, mot de passe de votre serveur (ex. Nextcloud `https://serveur/remote.php/dav/files/USER/Mindwtr`). |
| `dropbox` | Aucun serveur. Interface web seule. | Dropbox OAuth **ne fonctionne que dans les apps natives** bureau/mobile (limitation upstream, pas de support dans la vue web/PWA). Utilisez une app native, ou passez en `selfhosted`/`webdav` pour synchroniser depuis le navigateur. |

Si aucun mode n'est configuré, c'est `local` : dossiers locaux uniquement, rien d'autre à faire.

### Mode selfhosted : les 2 champs utiles

```yaml
sync_mode: selfhosted
cloud_tokens: "changez-moi-avec-un-jeton-d-au-moins-20-caracteres"
```

1. Générez un jeton (min. 20 caractères, lettres/chiffres) :
   ```bash
   cat /dev/urandom | LC_ALL=C tr -dc 'a-zA-Z0-9' | fold -w 50 | head -n 1
   ```
2. Collez-le dans `cloud_tokens`, redémarrez l'add-on
3. Dans l'app : `Paramètres → Sync → Self-Hosted`, URL `http://<ip-home-assistant>:8787` (l'app ajoute `/v1/data` toute seule), puis le même jeton

Plusieurs jetons séparés par des virgules = plusieurs espaces privés sur le même serveur (les appareils avec le même jeton se synchronisent ensemble) :
```yaml
cloud_tokens: "jeton-long-d-alice,jeton-long-de-bob"
```

`cors_origin` : laissez vide dans presque tous les cas. Ne renseignez que si un navigateur d'une autre machine parle **directement** au port `8787` (adresse exacte de la PWA, ex. `http://192.168.1.20:8080`).

## API (mode selfhosted)

Base URL : `http://<ip-home-assistant>:8787/v1` (même jeton Bearer que la sync).

```bash
curl -X POST \
  -H "Authorization: Bearer votre_jeton" \
  -H "Content-Type: application/json" \
  -d '{"input":"Relire facture /due:tomorrow #finance"}' \
  http://<ip-home-assistant>:8787/v1/tasks

curl -H "Authorization: Bearer votre_jeton" \
  "http://<ip-home-assistant>:8787/v1/tasks?status=next"
```

## Ports et données

- **8080/tcp** — interface web Mindwtr (proxy `/v1/` vers le Cloud inclus, détection same-origin automatique)
- **8787/tcp** — API du serveur Cloud (utilisé uniquement en mode `selfhosted`)
- Données Cloud persistées dans `/share/mindwtr` (mappage `share`)

## Support

Logs de l'add-on en cas de problème, ou [dépôt GitHub](https://github.com/LeGitHubDeTai/ha_addons).
Référence upstream : [Mindwtr `docker/`](https://github.com/dongdongbh/Mindwtr/tree/main/docker) et [docs sync](https://docs.mindwtr.app/data-sync/).
