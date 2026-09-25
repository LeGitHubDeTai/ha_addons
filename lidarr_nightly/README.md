# 🌙 Home Assistant Add-on — Lidarr Nightly

Accédez à **Lidarr (branche `nightly`)** directement depuis votre réseau local, via son interface Web exposée sur le port `8688`.

Basé sur l'image **LinuxServer.io Lidarr (`nightly`)**, cet add-on suit les builds quotidiens de développement : le code le plus récent, mais aussi le plus instable.

> ⚠️ **Builds quotidiens instables.** Réservés aux tests et aux remontées de bugs.
> Pour un usage quotidien, préférez l'add-on [**Lidarr**](../lidarr/) (branche stable).
> Pour un compromis nouveautés/stabilité, essayez [**Lidarr Develop**](../lidarr_develop/).

---

## ✨ Fonctionnalités

* Toutes les fonctionnalités de [**Lidarr**](../lidarr/), en version nightly (quotidienne)
* Mises à jour au rythme des builds amont
* Configuration **isolée** des autres variantes (stockage privé `lidarr_nightly`)
* Interface Web exposée directement sur le port `8688` (pas d'Ingress)
* Compatible **amd64** et **arm64**

---

## 🚀 Installation

1. Ouvrir **Paramètres → Add-ons → Magasin → Dépôt**
2. Ajouter :

```
https://github.com/LeGitHubDeTai/ha_addons
```

3. Installer l'add-on **Lidarr Nightly**
4. Démarrer
5. Accéder à Lidarr via le bouton **Ouvrir l'interface Web** (port `8688`)

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
et [**Lidarr Develop**](../lidarr_develop/) :

* chaque variante possède sa **propre configuration** (`/config` isolé) ;
* utilisez des **dossiers racine distincts** (ex. `/share/music-nightly`) pour éviter
  que deux variantes ne réorganisent la même médiathèque ;
* chaque variante expose par défaut un port hôte différent (`8686` stable,
  `8687` develop, `8688` nightly) — modifiable dans l'onglet **Réseau**.

---

## 🌐 Accès à l'interface

L'add-on n'utilise **pas** l'Ingress de Home Assistant : l'interface Web est
exposée directement sur le port hôte `8688` (modifiable dans l'onglet **Réseau**).

```
http://[IP_DE_HOME_ASSISTANT]:8688
```

---

## 📂 Emplacements des données

| Chemin | Description |
| ------ | ----------- |
| `/config` | Configuration et base de données (stockage privé `lidarr_nightly`) |
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

Les mises à jour suivent les tags `nightly-*` de **LinuxServer.io Lidarr**
(rebuilds quasi quotidiens).
Vous les obtiendrez automatiquement via la mise à jour du dépôt Home Assistant.

> 💡 Ne mettez jamais à jour Lidarr depuis sa propre interface avec une installation
> Docker : les mises à jour sont livrées via les nouvelles versions de l'add-on.
> Les builds nightly peuvent contenir des migrations de base irréversibles :
> sauvegardez avant toute mise à jour.

---

## 🤝 Crédit

Basé sur :

* **LinuxServer.io — Lidarr Docker** (branche nightly)
* **Lidarr** (GPL-3.0) — https://github.com/Lidarr/Lidarr
* Home Assistant Add-on Framework
* Adaptation par **@LeGitHubDeTai**

---

## 📜 Licence

Lidarr est distribué sous licence **GPL-3.0**. L'emballage de l'add-on suit la
licence du dépôt (MIT).
