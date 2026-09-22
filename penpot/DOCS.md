# Penpot - Home Assistant Add-on

## Premier démarrage

1. Démarrez l'add-on et patientez 1 à 3 minutes (initialisation PostgreSQL + migrations backend).
2. Ouvrez l'interface (Ingress) : vous arrivez sur la page de connexion Penpot.
3. Créez votre premier compte via "Create account" (l'inscription est activée par défaut).
4. (Optionnel) Repassez ensuite `allow_registration` à `false` et redémarrez pour verrouiller l'instance.

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
| 9001 | Web UI Penpot (Ingress + accès direct optionnel) |
| 8080 | Frontend nginx interne (non exposé) |
| 6060 / 6061 / 4401-4402 | Backend / Exporter / MCP internes (non exposés) |

## Dépannage

- **Page blanche / 502 au premier démarrage** : le backend migre encore la base. Attendez et rechargez.
- **L'export SVG/PDF échoue** : l'exporter (Chromium) demande ~1 Go de RAM. Sur Raspberry Pi, limitez les exports simultanés.
- **Après changement de `db_password`** : le mot de passe du rôle `penpot` est resynchronisé au démarrage.
  En revanche, changer `secret_key` invalide sessions et invitations : à éviter.
- **Logs utiles** : superviseur préfixe chaque service (`[backend]`, `[frontend]`, `[postgres]`, ...).
