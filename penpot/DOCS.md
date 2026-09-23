# Penpot - Home Assistant Add-on

## Base de données externe (requis)

L'add-on ne fournit plus de PostgreSQL : il se connecte à **votre** serveur (PostgreSQL 15+),
que vous gérez vous-même (autre add-on, conteneur dédié, NAS, etc.).

1. Créez le rôle et la base :
   ```sql
   CREATE USER penpot WITH PASSWORD 'un-mot-de-passe-sûr';
   CREATE DATABASE penpot OWNER penpot;
   ```
2. Renseignez le groupe `DATABASE` dans la configuration de l'add-on :
   ```yaml
   DATABASE:
     db_host: "192.168.1.10"
     db_port: 5432
     db_user: penpot
     db_password: "un-mot-de-passe-sûr"
     db_name: penpot
   ```
3. Vérifiez que le serveur accepte les connexions depuis Home Assistant
   (`listen_addresses`, `pg_hba.conf`, pare-feu).

Le backend applique les migrations automatiquement au démarrage.
Valkey/Redis reste **embarqué et éphémère** par défaut (`REDIS.redis_host: localhost`) ;
pointez `REDIS` vers un serveur externe si vous préférez.

## Premier démarrage

1. Démarrez l'add-on et patientez 1 à 3 minutes (migrations backend sur votre base).
2. Ouvrez `http://homeassistant.local:9001` (accès direct — **pas via l'Ingress**, non supporté par Penpot).
3. Créez votre premier compte via "Create account" (l'inscription est activée par défaut).
4. (Optionnel) Repassez ensuite `allow_registration` à `false` et redémarrez pour verrouiller l'instance.

## Page noire / `Failed to fetch` sur `localhost:9001` ?

C'est le symptôme d'une `public_uri` forcée à tort : le navigateur tentait d'appeler l'API sur
`localhost:9001` (le serveur vu depuis le conteneur, pas depuis votre PC). Laissez `public_uri`
**vide** : le frontend utilisera automatiquement l'URL avec laquelle vous accédez à Penpot.
Ne renseignez `public_uri` que si vous voulez forcer une URL canonique (ex. pour des liens
d'emails corrects avec SMTP) : mettez-y l'URL exacte vue par le navigateur.

## SMTP

Sans SMTP configuré, la vérification d'e-mail est désactivée (`disable-email-verification`) et les
comptes sont utilisables immédiatement. Pour un usage sérieux, renseignez un vrai fournisseur SMTP :

```yaml
smtp_host: "smtp.example.com"
smtp_port: 587
smtp_username: "penpot@example.com"
smtp_password: "xxx"
smtp_from: "penpot@example.com"
smtp_reply_to: "penpot@example.com"
```

## Ports

| Port | Description |
|---|---|
| 9001 | Web UI Penpot (accès direct, mappé par défaut) |
| 8080 | Frontend nginx interne (non exposé) |
| 6060 / 6061 / 4401-4402 | Backend / Exporter / MCP internes (non exposés) |

## Dépannage

- **`[backend] FATAL: DATABASE.db_host is not configured`** : renseignez votre serveur PostgreSQL
  dans les options, puis redémarrez.
- **`still waiting for PostgreSQL ... check host/credentials/firewall`** : l'add-on ne joint pas la base.
  Vérifiez hôte/port, rôle + mot de passe, `listen_addresses` / `pg_hba.conf` côté serveur et le pare-feu.
- **Page blanche / 502 au premier démarrage** : le backend migre encore la base. Attendez et rechargez.
- **L'export SVG/PDF échoue** : l'exporter (Chromium) demande ~1 Go de RAM. Sur Raspberry Pi, limitez les exports simultanés.
- **Changer `secret_key` invalide sessions et invitations** : à éviter après le premier démarrage.
- **Logs utiles** : chaque service est préfixé (`[backend]`, `[frontend]`, `[exporter]`, `[mcp]`, `[valkey]`).
