# 🧪 Home Assistant Add-on — Lidarr Develop

Accédez à **Lidarr (branche `develop`)** directement depuis Home Assistant, via une interface Web intégrée (Ingress ou HTTP classique).

Basé sur l'image **LinuxServer.io Lidarr (`develop`)**, cet add-on suit les pré-versions de Lidarr : nouveautés en avant-première, mais stabilité non garantie.

> ⚠️ **Version instable.** Réservée aux tests. Pour un usage quotidien, préférez l'add-on [**Lidarr**](../lidarr/) (branche stable).

---

## ✨ Fonctionnalités

* Toutes les fonctionnalités de [**Lidarr**](../lidarr/), en version de développement
* Mises à jour fréquentes (nouvelles fonctionnalités et correctifs en avant-première)
* Configuration **isolée** de la version stable (stockage privé `lidarr_develop`)
* Accessible via **Ingress**
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
5. Accéder à Lidarr via **Ingress** (panneau latéral)

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
* **un seul add-on à la fois** peut exposer le port `8686` de l'hôte (conflit de port),
  l'accès via Ingress reste toujours disponible pour les trois.

---

## 🌐 Accès à l'interface

### ✔️ Via Ingress (recommandé)

➡️ Automatique, pas de ports à ouvrir.

### ✔️ Via HTTP direct

Exposez le port `8686` dans l'onglet **Réseau** de l'add-on :

```
http://[IP_DE_HOME_ASSISTANT]:8686
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
