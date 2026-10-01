---
name: create-updates
description: Crée un script de mise à jour automatique dans le dossier .updates pour un add-on Home Assistant. Le script suit le modèle des scripts existants (lidarr.sh, nzbget.sh, etc.) et utilise la bibliothèque .scripts/update-lib.sh.
---

# Créer un script de mise à jour automatique — workflow

Ce skill génère un script de mise à jour automatique (`*.sh`) dans le dossier `.updates` du dépôt `ha_addons`, suivant le modèle des scripts existants. Le script créé pourra être utilisé par la CI pour automatiser les mises à jour d'un add-on.

## Règle absolue

**Générer les fichiers uniquement : aucun `git add`, aucun `git commit`, aucun `git push`, aucune PR.** L'utilisateur review et commit lui-même.

À la fin, se contenter de lister les fichiers créés (`git status --short`).

Tous les fichiers sont écrits en **UTF-8 sans BOM**, fins de ligne **LF**.

---

## Étape 1 — Collecter les informations

Si l'utilisateur n'a pas tout fourni, pose les questions avec l'outil `question` (une seule appelée, questions groupées) :

| Champ | Obligatoire | Défaut / règle |
|---|---|---|
| Nom affiché (`name`) | oui | ex. `Lidarr`, `Nzbget` |
| Slug (dossier addon) | oui | kebab-case minuscule, **= nom du dossier**, ex. `lidarr` |
| Dépôt upstream | oui | format `linuxdocker/<nom>` ex. `linuxserver/docker-lidarr` |
| Type de version | oui | `ls` pour LinuxServer, ou autre |
| Préfixe de tag | non | ex. `v`, vide pour aucun |
| Fichiers à mettre à jour | non | `config.yaml build.yaml` (défaut) |

---

## Étape 2 — Vérifications préalables

Vérifier que le script ne remplace pas un script existant :

```powershell
Test-Path ".updates\<slug>.sh"
# si True -> STOP, le script existe déjà (modifier plutôt que recréer)
```

Vérifier que le slug est en kebab-case : `^[a-z0-9]+(-[a-z0-9]+)*$`

---

## Étape 3 — Générer le script

Le script généré sera placé à la racine du dépôt dans `.updates/<slug>.sh` et contiendra :

### Structure minimale du script généré

```bash
#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
source "$SCRIPT_DIR/.scripts/update-lib.sh"

export ADDON_DIR="<slug>"
export DISPLAY_NAME="<Name>"
export VERSION_ARG=""
export USE_BUILD_YAML="true"
export UPSTREAM_REPO="<upstream-repo>"
export VERSION_TYPE="<version-type>"
export TAG_PREFIX="<tag-prefix>"
export FILES_TO_UPDATE="config.yaml build.yaml"
export PKG_PATH=""

BUILD_TAG=$(get_build_yaml_tag "$ADDON_DIR")
CURRENT_TAG=$(echo "$BUILD_TAG" | sed -E 's/^[a-z0-9]+-//' || true)
echo "build_tag=$BUILD_TAG" >> $GITHUB_OUTPUT
echo "current_tag=$CURRENT_TAG" >> $GITHUB_OUTPUT
CONFIG_VERSION=$(get_config_version "$ADDON_DIR")
echo "config_version=$CONFIG_VERSION" >> $GITHUB_OUTPUT
IFS="|" read -r LATEST_TAG LATEST_VERSION LATEST_BUILD RELEASE_TYPE RELEASE_URL MINOR_VERSION <<< "$(get_latest_ls_release "$ADDON_DIR" "$TAG_PREFIX" "<upstream-repo>")"
echo "latest_tag=$LATEST_TAG" >> $GITHUB_OUTPUT
echo "latest_version=$LATEST_VERSION" >> $GITHUB_OUTPUT
echo "latest_build=$LATEST_BUILD" >> $GITHUB_OUTPUT
echo "release_type=$RELEASE_TYPE" >> $GITHUB_OUTPUT
echo "release_url=$RELEASE_URL" >> $GITHUB_OUTPUT
[ -n "$MINOR_VERSION" ] && echo "minor_version=$MINOR_VERSION" >> $GITHUB_OUTPUT
COMPARE_RESULT=$(check_pr_status "$ADDON_DIR" "$DISPLAY_NAME" "$LATEST_TAG" "$RELEASE_TYPE" "$VERSION_TYPE" "$CURRENT_TAG")
echo "$COMPARE_RESULT" | while IFS="=" read -r key value; do echo "$key=$value" >> $GITHUB_OUTPUT; done
NEEDS_UPGRADE=$(echo "$COMPARE_RESULT" | grep "^needs_upgrade=" | cut -d= -f2)
[ "$NEEDS_UPGRADE" = "false" ] && echo "Already up-to-date" && exit 0
NEEDS_LABEL_UPDATE=$(echo "$COMPARE_RESULT" | grep "^needs_label_update=" | cut -d= -f2)
EXISTING_PR=$(echo "$COMPARE_RESULT" | grep "^existing_pr=" | cut -d= -f2)
EXISTING_BRANCH=$(echo "$COMPARE_RESULT" | grep "^existing_branch=" | cut -d= -f2)
IS_NEW_VERSION=$(echo "$COMPARE_RESULT" | grep "^is_new_version=" | cut -d= -f2)
NEW_ADDON_VERSION=$(generate_calver_version "$CONFIG_VERSION")
echo "new_addon_version=$NEW_ADDON_VERSION" >> $GITHUB_OUTPUT
if [ "$NEEDS_LABEL_UPDATE" = "true" ] && [ -n "$EXISTING_BRANCH" ]; then BRANCH_NAME="$EXISTING_BRANCH"; else BRANCH_NAME="upgrade/$ADDON_DIR-$LATEST_TAG"; fi
echo "branch_name=$BRANCH_NAME" >> $GITHUB_OUTPUT
sed -i "s/^version: .*/version: \"$NEW_ADDON_VERSION\"/" "$ADDON_DIR"/config.yaml
ESCAPED_CURRENT=$(printf '%s' "$CURRENT_TAG" | sed 's/\./\\./g')
sed -i "s/${ESCAPED_CURRENT}/${LATEST_TAG}/g" "$ADDON_DIR"/build.yaml
git add "$ADDON_DIR/config.yaml" "$ADDON_DIR/build.yaml"
if git ls-remote --heads origin "$BRANCH_NAME" | grep -q "$BRANCH_NAME"; then git fetch origin "$BRANCH_NAME"; git checkout -B "$BRANCH_NAME" origin/"$BRANCH_NAME"; else git checkout -b "$BRANCH_NAME"; fi
```

### Variables expliquées

- `ADDON_DIR` : dossier de l'addon (doit correspondre au dossier réel dans le repo)
- `DISPLAY_NAME` : nom affiché de l'addon
- `UPSTREAM_REPO` : dépôt upstream au format `org/docker-image` ex. `linuxserver/docker-lidarr`
- `VERSION_TYPE` : type de versionning, généralement `ls` pour LinuxServer
- `TAG_PREFIX` : préfixe des tags git, ex. `v` ou vide
- `FILES_TO_UPDATE` : fichiers à modifier lors de la mise à jour (souvent `config.yaml build.yaml`)
- `PKG_PATH` : chemin de package optionnel

---

## Étape 4 — Fichiers dérivés

Aucun fichier dérivé n'est modifié à la racine du dépôt pour cette skill. Le seul fichier créé est le script `.updates/<slug>.sh`.

---

## Étape 5 — Validation (obligatoire)

```powershell
python .opencode/skills/create-updates/validate.py <slug>
```

Le script vérifie :
- Que le script `.updates/<slug>.sh` existe
- Que les variables essentielles sont présentes (ADDON_DIR, DISPLAY_NAME, UPSTREAM_REPO, VERSION_TYPE)
- Que le slug correspond au dossier
- Format des variables cohérent

**Tout ❌ doit être corrigé avant le résumé.** Relancer jusqu'à ce que toutes les vérifications passent.

Puis montrer ce qui a été créé, sans committer :

```powershell
git status --short
```

---

## Étape 6 — Résumé

Lister : script créé, slug retenu, dépôt upstream, type de version, fichiers à mettre à jour, d'éventuels TODO.

Rappeler les étapes suivantes :
1. Vérifier que le script généré correspond aux conventions existantes
2. Tester le script en local si nécessaire
3. Commiter/pousser soi-même

---

## Conventions de développement (checklist)

- [ ] Script à la racine `.updates/<slug>.sh`, slug en kebab-case, dossier existe
- [ ] `ADDON_DIR` correspond au nom du dossier addon
- [ ] `DISPLAY_NAME` nom lisible
- [ ] `UPSTREAM_REPO` au format `org/docker-image`
- [ ] `VERSION_TYPE` valeur valide
- [ ] `FILES_TO_UPDATE` liste des fichiers à modifier
- [ ] Toutes les variables d'export sont présentes
- [ ] Le script source `.scripts/update-lib.sh`
- [ ] Aucune modification de fichiers hors `.updates/`