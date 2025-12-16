# 🗂️ Planka – Home Assistant Add-on

Cet add-on permet d’exécuter **Planka**, un outil Kanban open-source moderne, **directement dans Home Assistant** sous forme d’extension.

Il fournit une intégration simple et fiable de Planka dans l’écosystème Home Assistant, avec une configuration centralisée et un démarrage automatisé.

---

## ✨ Présentation

**Planka** est une application de gestion de projets de type Kanban, inspirée de Trello, permettant d’organiser :

* tableaux
* listes
* cartes
* tâches collaboratives

Cette adaptation permet de l’utiliser facilement dans Home Assistant, sans installation manuelle complexe.

---

## ⚙️ Fonctionnalités de l’add-on

* 🚀 Exécution de Planka comme add-on Home Assistant
* 🧩 Configuration via l’interface Home Assistant
* 🔐 Génération automatique des variables sensibles
* 🗄️ Initialisation automatique de la base de données
* 👤 Création automatique du compte administrateur au premier démarrage
* 🔄 Mise à jour automatique de la configuration lors des changements
* 📁 Données persistantes stockées dans `/config`

---

## 🏗️ Architecture

* **Application** : Planka (Node.js)
* **Base de données** : PostgreSQL
* **Environnement** : Home Assistant OS / Supervised
* **Configuration** : `config.yaml`

---

## ⚠️ Prérequis

* Home Assistant OS ou Home Assistant Supervised
* Une base de données PostgreSQL disponible (locale ou distante)

---

## 🔧 Configuration

### Base de données

```yaml
DATABASE:
  db_host: localhost
  db_port: 5432
  db_user: planka
  db_password: homeassistant
  db_name: planka
```

### Compte administrateur

```yaml
ADMIN:
  email: admin@example.com
  password: homeassistant
  name: Admin
```

> ℹ️ Le compte administrateur est créé automatiquement lors du premier démarrage.

---

## 🚀 Installation

1. Ajouter le dépôt d’add-ons personnalisé
2. Installer l’add-on **Planka**
3. Renseigner la configuration
4. Démarrer l’add-on
5. Accéder à Planka via l’interface Home Assistant

---

## 🔐 Sécurité

* Les secrets sont générés automatiquement
* Les fichiers de configuration utilisent des permissions restrictives
* Aucune configuration manuelle requise dans le conteneur

---

## 📦 Compatibilité

* Architectures supportées :

  * `amd64`
  * `aarch64`
  * `armv7`
  * `armhf`
  * `i386`

* Version Node.js : **22**

* Version Planka : dernière version stable

---

## 🧑‍💻 Auteur

Adaptation Home Assistant par **LeGitHubDeTai**
Planka est un projet open-source maintenu par ses auteurs respectifs.

---

## 📄 Licence

* Planka : licence d’origine
* Add-on Home Assistant : licence de ce dépôt
