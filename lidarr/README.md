# 🎵 Home Assistant Add-on — Lidarr

Accédez à **Lidarr** directement depuis votre réseau local, via son interface Web exposée sur le port `8686`.

Basé sur l'image officielle **LinuxServer.io Lidarr**, cet add-on fournit un gestionnaire de collection musicale pour Usenet et BitTorrent, persistant et géré directement par Home Assistant.

---

## ✨ Fonctionnalités

* Gestion automatique de votre médiathèque musicale (artistes, albums, qualité, métadonnées)
* Intégration avec Prowlarr, SABnzbd, NZBGet, qBittorrent, Transmission…
* Interface Web exposée directement sur le port `8686` (pas d'Ingress)
* Configuration persistante dans `/config` (stockage privé de l'add-on)
* Compatible **amd64** et **arm64**
* Fuseau horaire, PUID et PGID configurables depuis l'UI
* Dossiers `/share/music` et `/share/downloads` créés au premier démarrage

---

## 🚀 Installation

1. Ouvrir **Paramètres → Add-ons → Magasin → Dépôt**
2. Ajouter :

```
https://github.com/LeGitHubDeTai/ha_addons
```

3. Installer l'add-on **Lidarr**
4. Démarrer
5. Accéder à Lidarr via le bouton **Ouvrir l'interface Web** (port `8686`)

---

## ⚙️ Configuration

Exemple de configuration par défaut :

```yaml
PUID: 0
PGID: 0
TZ: Europe/Paris
```

| Option | Description |
| ------ | ----------- |
| `PUID` | UID Linux utilisé pour lire/écrire vos fichiers musicaux (`0` = root, accès total à `/share` et `/media`) |
| `PGID` | GID Linux associé |
| `TZ` | Fuseau horaire (ex. `Europe/Paris`) |

> 💡 Si vos fichiers musicaux appartiennent à un utilisateur précis (ex. `1000:1000`),
> ajustez `PUID`/`PGID` en conséquence. En cas de doute, gardez `0`/`0`.

---

## 🌐 Accès à l'interface

L'add-on n'utilise **pas** l'Ingress de Home Assistant : l'interface Web de Lidarr
est exposée directement sur le port `8686` (modifiable dans l'onglet **Réseau**).

```
http://[IP_DE_HOME_ASSISTANT]:8686
```

Ce mode d'accès direct est requis pour connecter Prowlarr et vos clients de
téléchargement.

---

## 📂 Emplacements des données

| Chemin | Description |
| ------ | ----------- |
| `/config` | Configuration et base de données Lidarr (stockage privé de l'add-on) |
| `/share/music` | Dossier suggéré pour votre médiathèque (créé au premier démarrage) |
| `/share/downloads` | Dossier suggéré pour les téléchargements terminés |
| `/media` | Médias partagés avec Home Assistant |
| `/backup` | Sauvegardes Home Assistant (accessible en lecture/écriture) |

Pointez votre **dossier racine musical** (Settings → Media Management → Root Folders)
vers `/share/music` ou `/media/music`, et vos clients de téléchargement vers
`/share/downloads`.

Les données persistent après mise à jour ou redémarrage.

---

## 🧪 Architectures supportées

| Architecture | Support |
| ------------ | ------- |
| amd64 | ✅ |
| arm64 (aarch64) | ✅ |

---

## 🔀 Variantes (branches de développement)

* [**Lidarr Develop**](../lidarr_develop/) — pré-versions (`develop`), nouveautés en avant-première
* [**Lidarr Nightly**](../lidarr_nightly/) — builds quotidiens, les plus instables

Les trois variantes peuvent coexister (configurations isolées) : utilisez des dossiers
racine distincts. Chaque variante expose par défaut un port hôte différent
(`8686`, `8687` pour Develop, `8688` pour Nightly) — modifiable dans l'onglet
**Réseau** de chaque add-on.

---

## 🛠️ Mise à jour

Les mises à jour suivent celles de l'image **LinuxServer.io Lidarr**.
Vous les obtiendrez automatiquement via la mise à jour du dépôt Home Assistant.

---

## 🤝 Crédit

Basé sur :

* **LinuxServer.io — Lidarr Docker**
* **Lidarr** (GPL-3.0) — https://github.com/Lidarr/Lidarr
* Home Assistant Add-on Framework
* Adaptation par **@LeGitHubDeTai**

---

## 📜 Licence

Lidarr est distribué sous licence **GPL-3.0**. L'emballage de l'add-on suit la
licence du dépôt (MIT).
