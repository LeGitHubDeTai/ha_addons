# Soulseek (slskd)

Client Soulseek auto-hébergé ([slskd](https://github.com/slskd/slskd)) pour Home Assistant :
recherche, téléchargements et partages P2P via une interface web moderne,
accessible directement depuis Home Assistant (Ingress).

- Web UI : `:5030` (Ingress recommandé), HTTPS `:5031`
- Écoute Soulseek : `:50300/tcp` (à ouvrir pour de bonnes performances)
- Config : identifiants Soulseek + dossiers `/share/soulseek` et `/media`

Voir [DOCS.md](./DOCS.md) pour la configuration détaillée.
