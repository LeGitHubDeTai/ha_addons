# YouTube-DLP Add-on for Home Assistant

Téléchargeur de vidéos YouTube et autres sites (yt-dlp) avec interface web intégrée.

## Installation

1. Installez et démarrez l'add-on depuis Home Assistant
2. Ouvrez l'interface web via **Ingress** ou `http://<home-assistant>:5000`
3. Collez une URL YouTube ou autre site supporté et cliquez sur **Télécharger**

## Configuration

| Option | Description | Défaut |
|--------|-------------|--------|
| `timezone` | Fuseau horaire du conteneur | `Europe/Berlin` |
| `download_folder` | Dossier des téléchargements | `/media/youtube-dlp` |
| `config_folder` | Dossier de configuration yt-dlp | `/share/youtube-dlp` |
| `max_parallel` | Nombre max de téléchargements parallèles | `3` |
| `env_vars_list` | Variables d'environnement supplémentaires (`CLE: valeur`) | `[]` |

### Formats disponibles

- **Meilleure qualité (MP4)** : vidéo + audio mergeés en MP4
- **MP4 uniquement** : meilleure qualité MP4 disponible
- **Audio uniquement** : télécharge et convertit en MP3 (nécessite ffmpeg)

### Dossiers

- `/media/youtube-dlp` : vidéos téléchargées (accessible via Lecteur multimédia, Samba, Plex…)
- `/share/youtube-dlp` : configuration yt-dlp — **à sauvegarder**

### Ports

| Port | Description |
|------|-------------|
| `5000/tcp` | Interface web YouTube-DLP (Ingress recommandé) |

### Ingress (barre latérale HA)

L'interface est accessible via le bouton **Ouvrir l'interface** (Ingress). L'accès direct `http://<homeassistant>:5000` fonctionne aussi.

### Sites supportés

yt-dlp supporte des centaines de sites : YouTube, Twitch, TikTok, Instagram, Twitter/X, Reddit, et bien plus. Pour la liste complète, consultez la documentation [yt-dlp](https://github.com/yt-dlp/yt-dlp).

### Utilisation avancée (CLI)

yt-dlp est installé dans le conteneur. Via un terminal HA, vous pouvez utiliser la CLI :

```bash
yt-dlp "https://www.youtube.com/watch?v=EXAMPLE"
yt-dlp -f "bestaudio" --extract-audio --audio-format mp3 "https://www.youtube.com/watch?v=EXAMPLE"
```

## Support

Si vous rencontrez des problèmes, consultez les logs de l'add-on ou visitez le [dépôt GitHub](https://github.com/LeGitHubDeTai/ha_addons).

## Licence

yt-dlp est distribué sous licence [unlicense](https://github.com/yt-dlp/yt-dlp).
