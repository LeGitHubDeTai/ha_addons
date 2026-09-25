# Soulseek (slskd) - Home Assistant Add-on

Client [Soulseek](https://www.slsknet.org/) auto-hébergé basé sur [slskd](https://github.com/slskd/slskd),
avec interface web complète : recherche multi-critères, téléchargements, téléversements,
salons de discussion, messages privés et API d'automatisation.

## Installation

1. Installez et démarrez l'add-on.
2. Ouvrez l'interface web via **Ingress** (bouton *Ouvrir l'interface*) ou `http://<homeassistant>:5030`.
3. Connectez-vous avec `web_username` / `web_password` (`slskd` / `slskd` par défaut — **à changer**).
4. Renseignez vos identifiants Soulseek dans la configuration de l'add-on et redémarrez
   (ou via *System > Options* dans l'UI si `remote_configuration: true`).

> Un compte Soulseek est requis (gratuit, créable depuis l'UI slskd ou le client officiel).
> Partagez au moins un dossier (`share_dirs`) : le réseau Soulseek
> pénalise les « leechers » sans partage.

## Configuration

```yaml
soulseek_username: "mon-pseudo"
soulseek_password: "mon-mot-de-passe"
soulseek_description: "Home Assistant Soulseek"
web_username: slskd
web_password: changez-moi
download_dir: /share/soulseek/downloads
incomplete_dir: /share/soulseek/incomplete
share_dirs:
  - /share/soulseek/share
  - /media
listen_port: 50300
remote_configuration: true
log_level: Information
env_vars_list: []
```

### Options

| Option | Description | Défaut |
|---|---|---|
| `soulseek_username` | Pseudo Soulseek (requis pour se connecter) | `""` |
| `soulseek_password` | Mot de passe Soulseek (requis) | `""` |
| `soulseek_description` | Description publique du profil | `Home Assistant Soulseek` |
| `web_username` | Identifiant de l'interface web | `slskd` |
| `web_password` | Mot de passe de l'interface web — **à changer** | `slskd` |
| `download_dir` | Dossier des téléchargements terminés | `/share/soulseek/downloads` |
| `incomplete_dir` | Dossier des téléchargements en cours | `/share/soulseek/incomplete` |
| `share_dirs` | Dossiers partagés sur le réseau (au moins 1 requis) | `[/share/soulseek/share, /media]` |
| `listen_port` | Port d'écoute Soulseek (entrants) | `50300` |
| `remote_configuration` | Permet de modifier la config depuis l'UI web | `true` |
| `log_level` | Niveau de logs (`Trace`…`Critical`) | `Information` |
| `env_vars_list` | Variables d'env libres (`CLE: valeur`, ex. `SLSKD_API_KEY: ...`) | `[]` |

> Les secrets HA (`!secret`) sont supportés pour les mots de passe.

### Dossiers

- `/share/soulseek/downloads` : fichiers terminés (accessibles via Samba, File Editor, Plex/Jellyfin…).
- `/share/soulseek/incomplete` : fichiers en cours.
- `/share/soulseek/share` + `/media` : contenus que **vous partagez** avec le réseau.
- `/data/slskd.yml` : configuration générée ; `/data/*.db` : base interne slskd (exclue du backup).

Astuce musique : pointez `download_dir` vers `/share/soulseek/downloads`
puis ajoutez ce dossier à votre serveur musical (Mopidy, Navidrome…).

### Ports

| Port | Description |
|---|---|
| `5030/tcp` | Interface web HTTP (Ingress recommandé, exposition optionnelle) |
| `5031/tcp` | Interface web HTTPS (certificat auto-signé, optionnel) |
| `50300/tcp` | Écoute Soulseek — **à exposer/rediriger (NAT) pour de bonnes performances** |

Sans le port `50300` ouvert, les transferts passent en mode indirect (plus lents, parfois impossibles).
Redirigez `50300/tcp` sur votre box vers Home Assistant si possible.

### Sécurité

- Changez `web_username` / `web_password` dès l'installation.
- N'exposez `5030`/`5031` sur Internet que derrière un reverse-proxy avec authentification ;
  préférez l'accès via Ingress ou VPN (Tailscale, WireGuard, Cloudflared + Access).
- Le réseau Soulseek est public : soignez `soulseek_description` et le contenu de `share_dirs`.
