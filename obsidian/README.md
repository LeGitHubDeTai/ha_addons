# 📝 Home Assistant Add-on — Obsidian Notes

Accédez à l’application **Obsidian** directement depuis Home Assistant, via une interface Web intégrée (Ingress ou HTTP classique).

Basé sur l’image officielle **LinuxServer.io Obsidian**, cet add-on fournit un environnement graphique isolé, persistant, et géré directement par Home Assistant.

---

## ✨ Fonctionnalités

* Interface Obsidian accessible depuis Home Assistant
* Fonctionne parfaitement via **Ingress**
* Aucun SSL interne → Obsidian tourne uniquement en HTTP (géré ensuite par HA)
* Vaults persistants dans `/config` ou `/share`
* Compatible **amd64** et **arm64**
* Configuration extrêmement simple
* Auto-création des fichiers Obsidian au premier démarrage

---

## 🚀 Installation

1. Ouvrir **Paramètres → Add-ons → Magasin → Dépôt**
2. Ajouter :

```
https://github.com/LeGitHubDeTai/ha_addons
```

3. Installer l’add-on **Obsidian**
4. Démarrer
5. Accéder à Obsidian via **Ingress** (panneau latéral)

---

## ⚙️ Configuration

Cet add-on ne requiert **aucune option spécifique**.

Exemple de configuration (vide) :

```yaml
{}
```

---

## 🌐 Accès à l'interface

### ✔️ Via Ingress (recommandé)

➡️ Automatique
➡️ Affiché directement dans Home Assistant
➡️ Pas de ports à ouvrir

### ✔️ Via HTTP direct

Si vous souhaitez accéder directement à Obsidian :

```
http://[IP_DE_HOME_ASSISTANT]:3000
```

---

## 📂 Emplacements des données

| Chemin                     | Description           |
| -------------------------- | --------------------- |
| `/config/.config/obsidian` | Paramètres d’Obsidian |
| `/share/obsidian`          | Vault recommandé      |

Les données persistent après mise à jour ou redémarrage.

---

## 🔧 Variables d’environnement utilisées

| Variable         | Valeur       | Description                         |
| ---------------- | ------------ | ----------------------------------- |
| `PUID`           | `1000`       | UID utilisateur                     |
| `PGID`           | `1000`       | GID utilisateur                     |
| `NO_DECOR`       | `true`       | Supprime les décorations de fenêtre |
| `HARDEN_DESKTOP` | `true`       | Sécurisation minimale               |
| `HARDEN_OPENBOX` | `true`       | Environnement optimisé              |
| `TITLE`          | `"Obsidian"` | Titre de fenêtre                    |

---

## 🧪 Architectures supportées

| Architecture | Support |
| ------------ | ------- |
| amd64        | ✅       |
| arm64        | ✅       |

---

## 🛠️ Mise à jour

Les mises à jour suivent celles de l’image **LinuxServer.io Obsidian**.
Vous les obtiendrez automatiquement via la mise à jour du dépôt Home Assistant.

---

## ❓ Problèmes connus

* Certains plugins graphiques peuvent être limités en environnement virtualisé.
* Glisser-déposer dépend du navigateur utilisé.

---

## 🤝 Crédit

Basé sur :

* **LinuxServer.io — Obsidian Docker**
* Home Assistant Add-on Framework
* Adaptation par **@LeGitHubDeTai**

---

## 📜 Licence

Licence : **MIT**
