# Deemix - Home Assistant Add-on

[Deemix](https://github.com/bambanah/deemix) (fork maintenu du projet de RemixDev)
avec interface web complète : recherche, téléchargements de titres, albums,
playlists et discographies depuis le catalogue Deezer, en MP3 (128/320) ou FLAC,
avec métadonnées, pochettes et paroles.

## Installation

1. Installez et démarrez l'add-on.
2. Ouvrez l'interface web via **Ingress** (bouton *Ouvrir l'interface*) ou `http://<homeassistant>:6595`.
3. Connectez votre compte Deezer : dans l'interface Deemix, ouvrez les réglages
   et collez votre **ARL** (jeton de session Deezer).
   - En mode `single_user: true` (défaut), une seule connexion suffit pour tout le foyer.
4. Lancez vos premiers téléchargements : ils arrivent dans `music_folder`.

> Un compte Deezer est requis (gratuit pour MP3 128, payant pour MP3 320 / FLAC —
> la qualité disponible dépend de votre abonnement).
> Pour obtenir l'ARL : connectez-vous à [deezer.com](https://www.deezer.com) dans
> votre navigateur, ouvrez les outils développeur (F12) > *Stockage* > *Cookies* >
> copiez la valeur du cookie `arl`.

## Configuration

```yaml
music_folder: /media/deemix
config_folder: /share/deemix
single_user: true
env_vars_list: []
```

### Options

| Option | Description | Défaut |
|---|---|---|
| `music_folder` | Dossier des téléchargements (musique) | `/media/deemix` |
| `config_folder` | Dossier de configuration Deemix (session ARL, réglages, logs) | `/share/deemix` |
| `single_user` | Mode mono-utilisateur : une seule connexion Deezer partagée, sans login par session | `true` |
| `env_vars_list` | Variables d'env libres (`CLE: valeur`, ex. `DEEMIX_SERVER_PORT: 6596`) | `[]` |

> Les montages réseau `smb://` / `nfs://` sont acceptés pour `music_folder`
> et `config_folder` (montés par le Supervisor).
> Les secrets HA (`!secret`) sont supportés.

### Dossiers

- `/media/deemix` : musique téléchargée (accessible via Lecteur multimédia, Samba, Plex/Jellyfin…).
- `/share/deemix` : session Deezer (ARL), réglages et logs — **à sauvegarder**.
- Astuce musique : ajoutez `music_folder` à votre serveur musical (Mopidy, Navidrome…).

### Ports

| Port | Description |
|---|---|
| `6595/tcp` | Interface web Deemix (Ingress recommandé, exposition optionnelle) |

### Intégration CLI (avancé)

La CLI `deemix` est embarquée dans l'image (`node /app/packages/cli/dist/main.cjs`)
et réutilise la session de l'interface web. Usage via un terminal dans le conteneur :

```bash
node /app/packages/cli/dist/main.cjs https://www.deezer.com/track/3135556
node /app/packages/cli/dist/main.cjs -b flac -p /media/deemix/singles https://www.deezer.com/track/3135556
```

### Sécurité

- N'exposez `6595` sur Internet que derrière un reverse-proxy avec authentification ;
  préférez l'accès via Ingress ou VPN (Tailscale, WireGuard, Cloudflared + Access).
- Respectez les conditions d'utilisation de Deezer et ne téléchargez que des
  contenus auxquels votre abonnement vous donne droit.
