# NZBGet Home Assistant Addon

[NZBGet](https://nzbget.net) auto-hébergé pour Home Assistant
: client de téléchargement Usenet basé sur le web avec une
interface de contrôle distante, capable de télécharger et de
traiter automatiquement des fichiers NZB.

- Web UI : `:6789` (Ingress recommandé)
- Dossiers : téléchargements `/share/nzbget/downloads`, complets `/share/nzbget/completed`
- Compatible **amd64** et **arm64**
- Fuseau horaire, PUID et PGID configurables depuis l'UI

---

## ✨ Fonctionnalités

* Téléchargement Usenet automatique via fichiers NZB
* Parcourir et contrôler les téléchargements via une interface web moderne
* Support du par2/par checking et réparation automatique
* Gestion de la bande passante (limitation upload/download)
* Notifications par e-mail (alertes de fin, erreurs)
* Interface web exposée directement sur le port `6789` (Ingress recommandé)
* Configuration persistante dans `/config` (stockage privé de l'add-on)
* Compatible **amd64** et **aarch64**
* Dossiers `/share/nzbget/downloads`, `/share/nzbget/completed`, `/share/nzbget/queue` créés au premier démarrage

---

## 🚀 Installation

1. Ouvrir **Paramètres → Add-ons → Magasin → Dépôt**
2. Ajouter :

```
https://github.com/LeGitHubDeTai/ha_addons
```

3. Installer l'add-on **NZBGet**
4. Démarrer
5. Accéder à NZBGet via le bouton **Ouvrir l'interface Web** (port `6789`)

---

## ⚙️ Configuration

Exemple de configuration par défaut :

```yaml
PUID: 0
PGID: 0
TZ: Europe/Paris
DOWNLOAD_DIR: /share/nzbget/downloads
COMPLETED_DIR: /share/nzbget/completed
```

| Option | Description |
| ------ | ----------- |
| `PUID` | UID Linux utilisé pour lire/écrire vos fichiers (`0` = root, accès total) |
| `PGID` | GID Linux associé |
| `TZ` | Fuseau horaire (ex. `Europe/Paris`) |
| `DOWNLOAD_DIR` | Dossier pour les téléchargements en cours |
| `COMPLETED_DIR` | Dossier pour les téléchargements terminés |
| `QUEUE_DIR` | Dossier pour la file d'attente |
| `INTERFACE_PORT` | Port de l'interface web NZBGet |
| `BANDWIDTH_MAX` | Limite de bande passante totale (0 = illimitée) |
| `BANDWIDTH_UL` | Limite de bande passante en upload (0 = illimitée) |
| `BANDWIDTH_DL` | Limite de bande passante en download (0 = illimitée) |
| `PAR_CHECK` | Vérifier automatiquement les par2 (true/false) |
| `PAR_REPAIR` | Réparer automatiquement les archives (true/false) |
| `DELETE_INCOMPLETE` | Supprimer les téléchargements incomplets |
| `KEEP_DAYS` | Nombre de jours pour garder les téléchargements terminés |
| `MAIL_ON_WARN` | Envoyer un e-mail en cas d'avertissement |
| `MAIL_ON_ERROR` | Envoyer un e-mail en cas d'erreur |
| `MAIL_FROM` | Adresse expéditeur des e-mails |
| `MAIL_TO` | Adresse destinataire des e-mails |
| `MAIL_SERVER` | Serveur SMTP pour les notifications |
| `MAIL_PORT` | Port du serveur SMTP |
| `MAIL_USER` | Nom d'utilisateur SMTP |
| `MAIL_PASS` | Mot de passe SMTP |

> 💡 Si vos fichiers appartiennent à un utilisateur précis (ex. `1000:1000`),
> ajustez `PUID`/`PGID` en conséquence. En cas de doute, gardez `0`/`0`.

---

## 🌐 Accès à l'interface

L'add-on utilise l'**Ingress** de Home Assistant : l'interface Web de NZBGet
est accessible directement depuis le panel Home Assistant sans ouvrir de port.

Pour une exposition directe, le port `6789` peut être ouvert sur le réseau local.

---

## 📂 Emplacements des données

| Chemin | Description |
| ------ | ----------- |
| `/config` | Configuration et base de données NZBGet (stockage privé de l'add-on) |
| `/share/nzbget/downloads` | Dossier suggéré pour les téléchargements en cours |
| `/share/nzbget/completed` | Dossier suggéré pour les téléchargements terminés |
| `/share/nzbget/queue` | Dossier suggéré pour la file d'attente |
| `/share` | Partage général avec Home Assistant |
| `/media` | Médias partagés avec Home Assistant |
| `/backup` | Sauvegardes Home Assistant (accessible en lecture/écriture) |

---

## 🧪 Architectures supportées

| Architecture | Support |
| ------------ | ------- |
| amd64 | ✅ |
| arm64 (aarch64) | ✅ |

---

## 🛠️ Mise à jour

Les mises à jour suivent celles de l'image **LinuxServer.io NZBGet**.
Vous les obtiendrez automatiquement via la mise à jour du dépôt Home Assistant.

---

## 🤝 Crédit

Basé sur :

* **LinuxServer.io — NZBGet Docker**
* **NZBGet** (GPL-2.0-or-later) — https://nzbget.net
* Home Assistant Add-on Framework
* Adaptation par **@LeGitHubDeTai**

---

## 📜 Licence

NZBGet est distribué sous licence **GPL-2.0-or-later**. L'emballage de l'add-on
suit la licence du dépôt (MIT).
