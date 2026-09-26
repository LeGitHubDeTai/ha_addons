# NZBGet Home Assistant Addon

[NZBGet](https://nzbget.net) auto-h�berg� pour Home Assistant
: client de t�l�chargement Usenet bas� sur le web avec une
interface de contr�le distante, capable de t�l�charger et de
traiter automatiquement des fichiers NZB.

- Web UI : `:6789` (Ingress recommand�)
- Dossiers : t�l�chargements `/share/nzbget/downloads`, complets `/share/nzbget/completed`
- Compatible **amd64** et **arm64**
- Fuseau horaire, PUID et PGID configurables depuis l'UI

---

## �✨ Fonctionnalit�s

* T�l�chargement Usenet automatique via fichiers NZB
* Parcourir et contr�ler les t�l�chargements via une interface web moderne
* Support du par2/par checking et r�paration automatique
* Gestion de la bande passante (limitation upload/download)
* Notifications par e-mail (alertes de fin, erreurs)
* Interface web expos�e directement sur le port `6789` (Ingress recommand�)
* Configuration persistante dans `/config` (stockage priv� de l'add-on)
* Compatible **amd64** et **aarch64**
* Dossiers `/share/nzbget/downloads`, `/share/nzbget/completed`, `/share/nzbget/queue` cr��s au premier d�marrage

---

## 🚀 Installation

1. Ouvrir **Param�tres → Add-ons → Magasin → D�p�t**
2. Ajouter :

```
https://github.com/LeGitHubDeTai/ha_addons
```

3. Installer l'add-on **NZBGet**
4. D�marrer
5. Acc�der � NZBGet via le bouton **Ouvrir l'interface Web** (port `6789`)

---

## ⚙️ Configuration

Exemple de configuration par d�faut :

```yaml
PUID: 0
PGID: 0
TZ: Europe/Paris
DOWNLOAD_DIR: /share/nzbget/downloads
COMPLETED_DIR: /share/nzbget/completed
```

| Option | Description |
| ------ | ----------- |
| `PUID` | UID Linux utilis� pour lire/�crire vos fichiers (`0` = root, acc�s total) |
| `PGID` | GID Linux associ� |
| `TZ` | Fuseau horaire (ex. `Europe/Paris`) |
| `DOWNLOAD_DIR` | Dossier pour les t�l�chargements en cours |
| `COMPLETED_DIR` | Dossier pour les t�l�chargements termin�s |
| `QUEUE_DIR` | Dossier pour la file d'attente |
| `INTERFACE_PORT` | Port de l'interface web NZBGet |
| `BANDWIDTH_MAX` | Limite de bande passante totale (0 = illimit�e) |
| `BANDWIDTH_UL` | Limite de bande passante en upload (0 = illimit�e) |
| `BANDWIDTH_DL` | Limite de bande passante en download (0 = illimit�e) |
| `PAR_CHECK` | V�rifier automatiquement les par2 (true/false) |
| `PAR_REPAIR` | R�parer automatiquement les archives (true/false) |
| `DELETE_INCOMPLETE` | Supprimer les t�l�chargements incomplets |
| `KEEP_DAYS` | Nombre de jours pour garder les t�l�chargements termin�s |
| `MAIL_ON_WARN` | Envoyer un e-mail en cas d'avertissement |
| `MAIL_ON_ERROR` | Envoyer un e-mail en cas d'erreur |
| `MAIL_FROM` | Adresse exp�diteur des e-mails |
| `MAIL_TO` | Adresse destinataire des e-mails |
| `MAIL_SERVER` | Serveur SMTP pour les notifications |
| `MAIL_PORT` | Port du serveur SMTP |
| `MAIL_USER` | Nom d'utilisateur SMTP |
| `MAIL_PASS` | Mot de passe SMTP |

> 💡 Si vos fichiers appartiennent � un utilisateur pr�cis (ex. `1000:1000`),
> ajustez `PUID`/`PGID` en cons�quence. En cas de doute, gardez `0`/`0`.

---

## 🌐 Acc�s � l'interface

L'add-on utilise l'**Ingress** de Home Assistant : l'interface Web de NZBGet
est accessible directement depuis le panel Home Assistant sans ouvrir de port.

Pour une exposition directe, le port `6789` peut �tre ouvert sur le r�seau local.

---

## 📂 Emplacements des donn�es

| Chemin | Description |
| ------ | ----------- |
| `/config` | Configuration et base de donn�es NZBGet (stockage priv� de l'add-on) |
| `/share/nzbget/downloads` | Dossier sugg�r� pour les t�l�chargements en cours |
| `/share/nzbget/completed` | Dossier sugg�r� pour les t�l�chargements termin�s |
| `/share/nzbget/queue` | Dossier sugg�r� pour la file d'attente |
| `/share` | Partage g�n�ral avec Home Assistant |
| `/media` | M�dias partag�s avec Home Assistant |
| `/backup` | Sauvegardes Home Assistant (accessible en lecture/�criture) |

---

## 🧪 Architectures support�es

| Architecture | Support |
| ------------ | ------- |
| amd64 | ✅ |
| arm64 (aarch64) | ✅ |

---

## 🛠️ Mise � jour

Les mises � jour suivent celles de l'image **LinuxServer.io NZBGet**.
Vous les obtiendrez automatiquement via la mise � jour du d�p�t Home Assistant.

---

## 🤝 Cr�dit

Bas� sur :

* **LinuxServer.io — NZBGet Docker**
* **NZBGet** (GPL-2.0-or-later) — https://nzbget.net
* Home Assistant Add-on Framework
* Adaptation par **@LeGitHubDeTai**

---

## 📜 Licence

NZBGet est distribu� sous licence **GPL-2.0-or-later**. L'emballage de l'add-on
suit la licence du d�p�t (MIT).
