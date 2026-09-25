# 🧪 Home Assistant Add-on — Lidarr Develop

Accédez à **Lidarr (branche `develop`)** directement depuis votre réseau local, via son interface Web exposée sur le port `8687`.

Basé sur l'image **LinuxServer.io Lidarr (`develop`)**, cet add-on suit les pré-versions de Lidarr : nouveautés en avant-première, mais stabilité non garantie.

> ⚠️ **Version instable.** Réservée aux tests. Pour un usage quotidien, préférez l'add-on [**Lidarr**](../lidarr/) (branche stable).

---

## ✨ Fonctionnalités

* Toutes les fonctionnalités de [**Lidarr**](../lidarr/), en version de développement
* Mises à jour fréquentes (nouvelles fonctionnalités et correctifs en avant-première)
* Configuration **isolée** de la version stable (stockage privé `lidarr_develop`)
* Interface Web exposée directement sur le port `8687` (pas d'Ingress)
* Compatible **amd64** et **arm64**

---

## 🚀 Installation

1. Ouvrir **Paramètres → Add-ons → Magasin → Dépôt**
2. Ajouter :

```
https://github.com/LeGitHubDeTai/ha_addons
```

3. Installer l'add-on **Lidarr Develop**
4. Démarrer
5. Accéder à Lidarr via le bouton **Ouvrir l'interface Web** (port `8687`)

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
| `PUID` | UID Linux utilisé pour lire/écrire vos fichiers musicaux (`0` = root) |
| `PGID` | GID Linux associé |
| `TZ` | Fuseau horaire (ex. `Europe/Paris`) |

---

## 🔀 Coexistence avec les autres variantes

Cet add-on peut être installé **côte à côte** avec [**Lidarr**](../lidarr/) (stable)
et [**Lidarr Nightly**](../lidarr_nightly/) :

* chaque variante possède sa **propre configuration** (`/config` isolé) ;
* utilisez des **dossiers racine distincts** (ex. `/share/music-develop`) pour éviter
  que deux variantes ne réorganisent la même médiathèque ;
* chaque variante expose par défaut un port hôte différent (`8686` stable,
  `8687` develop, `8688` nightly) — modifiable dans l'onglet **Réseau**.

---

## 🌐 Accès à l'interface

L'add-on n'utilise **pas** l'Ingress de Home Assistant : l'interface Web est
exposée directement sur le port hôte `8687` (modifiable dans l'onglet **Réseau**).

```
http://[IP_DE_HOME_ASSISTANT]:8687
```

---

## 📂 Emplacements des données

| Chemin | Description |
| ------ | ----------- |
| `/config` | Configuration et base de données (stockage privé `lidarr_develop`) |
| `/share/music` | Dossier suggéré pour la médiathèque |
| `/share/downloads` | Dossier suggéré pour les téléchargements terminés |
| `/media` | Médias partagés avec Home Assistant |
| `/backup` | Sauvegardes Home Assistant |

---

## 🧪 Architectures supportées

| Architecture | Support |
| ------------ | ------- |
| amd64 | ✅ |
| arm64 (aarch64) | ✅ |

---

## 🛠️ Mise à jour

Les mises à jour suivent les tags `develop-*` de **LinuxServer.io Lidarr**.
Vous les obtiendrez automatiquement via la mise à jour du dépôt Home Assistant.

> 💡 Ne mettez jamais à jour Lidarr depuis sa propre interface avec une installation
> Docker : les mises à jour sont livrées via les nouvelles versions de l'add-on.

---

## 🤝 Crédit

Basé sur :

* **LinuxServer.io — Lidarr Docker** (branche develop)
* **Lidarr** (GPL-3.0) — https://github.com/Lidarr/Lidarr
* Home Assistant Add-on Framework
* Adaptation par **@LeGitHubDeTai**

---

## 📜 Licence

Lidarr est distribué sous licence **GPL-3.0**. L'emballage de l'add-on suit la
licence du dépôt (MIT).
