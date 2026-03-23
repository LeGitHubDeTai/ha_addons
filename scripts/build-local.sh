#!/bin/bash

# Script de build local pour les addons Home Assistant
# Basé sur le workflow .github/workflows/docker-build-publish.yml

set -e

# Configuration par défaut
REGISTRY="ghcr.io"
OWNER="legithubdetai"
REPO_PREFIX="ha_addons"
PUSH_TO_REGISTRY=false
SKIP_EXISTING=true
FORCE_BUILD=false
SELECTED_ADDON=""
BUILD_IN_CONTAINER=false
CONTAINER_NAME="ha-addon-builder"
CONTAINER_IMAGE="docker:24-dind"

# Couleurs pour une meilleure lisibilité
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonctions d'aide
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Afficher l'aide
show_help() {
    cat << EOF
Usage: $0 [OPTIONS] [ADDON_NAME]

Script de build local pour les addons Home Assistant basé sur le workflow GitHub Actions.

OPTIONS:
    -h, --help              Afficher cette aide
    -p, --push              Pousser les images vers le registre (défaut: local seulement)
    -f, --force             Forcer le build même si l'image existe déjà
    -a, --all               Builder tous les addons (défaut: détecter les changements)
    -c, --container         Builder dans un container Docker isolé
    --skip-existing         Skipper les builds si l'image existe déjà (défaut: true)

ARGUMENTS:
    ADDON_NAME              Nom de l'addon spécifique à builder (optionnel)

EXEMPLES:
    $0                      # Détecter les changements et builder les addons modifiés
    $0 planka              # Builder uniquement l'addon planka
    $0 -p planka           # Builder et pousser l'addon planka
    $0 -a                  # Builder tous les addons
    $0 -f planka           # Forcer le rebuild de l'addon planka
    $0 -c planka           # Builder l'addon planka dans un container Docker

EOF
}

# Analyser les arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -p|--push)
            PUSH_TO_REGISTRY=true
            shift
            ;;
        -f|--force)
            FORCE_BUILD=true
            shift
            ;;
        -a|--all)
            SELECTED_ADDON="all"
            shift
            ;;
        -c|--container)
            BUILD_IN_CONTAINER=true
            shift
            ;;
        --skip-existing)
            SKIP_EXISTING=true
            shift
            ;;
        --no-skip-existing)
            SKIP_EXISTING=false
            shift
            ;;
        -*)
            log_error "Option inconnue: $1"
            show_help
            exit 1
            ;;
        *)
            SELECTED_ADDON="$1"
            shift
            ;;
    esac
done

# Vérifier les dépendances
check_dependencies() {
    log_info "Vérification des dépendances..."
    
    if [ "$BUILD_IN_CONTAINER" = true ]; then
        # Pour le build dans container, on a besoin de Docker
        if ! command -v docker &> /dev/null; then
            log_error "Docker n'est pas installé ou pas dans le PATH"
            exit 1
        fi
        log_success "Docker disponible pour le build dans container"
    else
        # Pour le build local, on a besoin de tout
        if ! command -v docker &> /dev/null; then
            log_error "Docker n'est pas installé ou pas dans le PATH"
            exit 1
        fi
        
        if ! docker buildx version &> /dev/null; then
            log_error "Docker Buildx n'est pas disponible"
            exit 1
        fi
        
        if ! command -v yq &> /dev/null; then
            log_error "yq n'est pas installé. Veuillez l'installer depuis https://github.com/mikefarah/yq"
            exit 1
        fi
        
        if ! command -v jq &> /dev/null; then
            log_error "jq n'est pas installé. Veuillez l'installer"
            exit 1
        fi
        
        log_success "Toutes les dépendances sont disponibles"
    fi
}

# Préparer le container de build
setup_build_container() {
    if [ "$BUILD_IN_CONTAINER" != true ]; then
        return 0
    fi
    
    log_info "Préparation du container de build..."
    
    # Arrêter et supprimer le container existant s'il y en a un
    if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        log_info "Suppression du container existant..."
        docker stop "$CONTAINER_NAME" 2>/dev/null || true
        docker rm "$CONTAINER_NAME" 2>/dev/null || true
    fi
    
    # Créer un volume pour le cache si nécessaire
    if ! docker volume ls --format '{{.Name}}' | grep -q "^${CONTAINER_NAME}-cache$"; then
        docker volume create "${CONTAINER_NAME}-cache"
    fi
    
    # Obtenir le chemin absolu du workspace compatible Docker
    WORKSPACE_PATH="$(pwd)"
    log_info "Chemin actuel: $WORKSPACE_PATH"
    
    # Détection de l'environnement et conversion du chemin
    if command -v cygpath &> /dev/null; then
        # Utiliser cygpath pour convertir le chemin (Cygwin/MSYS2)
        WORKSPACE_PATH="$(cygpath -u "$(pwd)")"
        log_info "Chemin converti avec cygpath: $WORKSPACE_PATH"
    elif [[ "$WORKSPACE_PATH" =~ ^[A-Za-z]:/ ]]; then
        # Format Windows (C:/...) vers format Docker (/c/...)
        WORKSPACE_PATH="$(echo "$WORKSPACE_PATH" | sed 's|^\([A-Za-z]\):|/\l\1|')"
        log_info "Chemin converti pour Docker: $WORKSPACE_PATH"
    elif [[ "$WORKSPACE_PATH" =~ ^/[A-Za-z]/ ]]; then
        # Déjà au format Git Bash mais avec majuscule
        WORKSPACE_PATH="$(echo "$WORKSPACE_PATH" | sed 's|^\([A-Za-z]\)|\l\1|')"
        log_info "Chemin normalisé: $WORKSPACE_PATH"
    fi
    
    # Vérifier que le chemin est absolu et valide
    if [[ ! "$WORKSPACE_PATH" =~ ^/ ]]; then
        log_error "Le chemin n'est pas absolu: $WORKSPACE_PATH"
        exit 1
    fi
    
    log_info "Chemin final du workspace: $WORKSPACE_PATH"
    
    # Démarrer le container Docker-in-Docker
    log_info "Démarrage du container $CONTAINER_NAME..."
    
    # Sous Windows avec Docker Desktop, nous devons utiliser le chemin Windows natif
    if command -v cygpath &> /dev/null; then
        # Convertir le chemin Unix vers Windows pour Docker Desktop
        WINDOWS_PATH="$(cygpath -w "$(pwd)")"
        log_info "Chemin Windows pour Docker Desktop: $WINDOWS_PATH"
        
        # Démarrer avec démarrage explicite du démon Docker
        if ! docker run -d \
            --name "$CONTAINER_NAME" \
            --privileged \
            -v "${CONTAINER_NAME}-cache":/var/lib/docker \
            -v "$WINDOWS_PATH":/workspace \
            "$CONTAINER_IMAGE" \
            sh -c "
                dockerd-entrypoint.sh &
                sleep 5
                while true; do sleep 30; done
            "; then
            log_error "Échec du démarrage du container avec chemin Windows"
            exit 1
        fi
    else
        # Utiliser le chemin Unix standard (Linux/macOS)
        if ! docker run -d \
            --name "$CONTAINER_NAME" \
            --privileged \
            -v "${CONTAINER_NAME}-cache":/var/lib/docker \
            -v "$WORKSPACE_PATH":/workspace \
            "$CONTAINER_IMAGE" \
            sh -c "
                dockerd-entrypoint.sh &
                sleep 5
                while true; do sleep 30; done
            "; then
            log_error "Échec du démarrage du container"
            exit 1
        fi
    fi
    
    # Attendre que Docker soit prêt dans le container
    log_info "Attente du démarrage de Docker dans le container..."
    for i in {1..30}; do
        if docker exec "$CONTAINER_NAME" docker version &>/dev/null; then
            log_success "Docker est prêt dans le container"
            break
        fi
        if [ $i -eq 30 ]; then
            log_error "Docker n'a pas pu démarrer dans le container après 60 secondes"
            log_info "Vérification de l'état du container:"
            docker exec "$CONTAINER_NAME" ps aux || log_error "Impossible d'exécuter ps aux"
            docker exec "$CONTAINER_NAME" ls -la /var/run/ || log_error "Impossible de lister /var/run/"
            docker exec "$CONTAINER_NAME" ls -la /var/run/docker.sock || log_error "Docker socket non trouvé"
            docker stop "$CONTAINER_NAME" 2>/dev/null
            docker rm "$CONTAINER_NAME" 2>/dev/null
            exit 1
        fi
        log_info "Tentative $i/30 - Docker pas encore prêt..."
        sleep 2
    done
    
    # Installer les dépendances dans le container
    log_info "Installation des dépendances dans le container..."
    if ! docker exec "$CONTAINER_NAME" sh -c "
        apk add --no-cache curl jq &&
        curl -L https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -o /usr/local/bin/yq &&
        chmod +x /usr/local/bin/yq
    "; then
        log_error "Échec de l'installation des dépendances"
        docker stop "$CONTAINER_NAME" 2>/dev/null
        docker rm "$CONTAINER_NAME" 2>/dev/null
        exit 1
    fi
    
    log_success "Container de build prêt"
}

# Exécuter une commande dans le container de build
exec_in_container() {
    if [ "$BUILD_IN_CONTAINER" = true ]; then
        docker exec "$CONTAINER_NAME" sh -c "cd /workspace && $*"
    else
        "$@"
    fi
}

# Nettoyer le container de build
cleanup_build_container() {
    if [ "$BUILD_IN_CONTAINER" != true ]; then
        return 0
    fi
    
    log_info "Nettoyage du container de build..."
    
    if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        docker stop "$CONTAINER_NAME"
    fi
    
    if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        docker rm "$CONTAINER_NAME"
    fi
    
    log_success "Container nettoyé"
}

# Détecter les addons avec des changements
detect_changed_addons() {
    log_info "Détection des addons avec des changements..."
    
    if [ "$SELECTED_ADDON" = "all" ]; then
        ADDONS=$(exec_in_container find . -maxdepth 2 -name "config.yaml" -exec dirname {} \; | sed 's|^\./||' | grep -v '^\.' | tr '\n' ' ')
        log_info "Build de tous les addons demandé: $ADDONS"
    elif [ -n "$SELECTED_ADDON" ]; then
        if [ -d "$SELECTED_ADDON" ] && [ -f "$SELECTED_ADDON/config.yaml" ]; then
            ADDONS="$SELECTED_ADDON"
            log_info "Addon spécifique demandé: $ADDONS"
        else
            log_error "L'addon '$SELECTED_ADDON' n'existe pas ou n'a pas de config.yaml"
            exit 1
        fi
    else
        # Détecter les changements depuis le dernier commit
        if exec_in_container git rev-parse --git-dir > /dev/null 2>&1; then
            # Récupérer tous les addons possibles
            ALL_ADDONS=$(exec_in_container find . -maxdepth 2 -name "config.yaml" -exec dirname {} \; | sed 's|^\./||' | grep -v '^\.' | tr '\n' '|' | sed 's/|$//')
            
            # Détecter les fichiers changés depuis le dernier commit
            CHANGED_FILES=$(exec_in_container git diff --name-only HEAD~1 HEAD 2>/dev/null || echo "")
            
            if [ -n "$CHANGED_FILES" ]; then
                ADDONS=$(echo "$CHANGED_FILES" | grep -E "^($ALL_ADDONS)/" | cut -d'/' -f1 | sort -u | tr '\n' ' ')
                log_info "Addons avec des changements détectés: $ADDONS"
            else
                log_warning "Aucun changement détecté depuis le dernier commit"
                ADDONS=""
            fi
        else
            log_warning "Pas dans un dépôt git, build de tous les addons"
            ADDONS=$(exec_in_container find . -maxdepth 2 -name "config.yaml" -exec dirname {} \; | sed 's|^\./||' | grep -v '^\.' | tr '\n' ' ')
        fi
    fi
    
    if [ -z "$ADDONS" ]; then
        log_warning "Aucun addon à builder"
        exit 0
    fi
}

# Vérifier les versions et déterminer quoi builder
check_versions() {
    log_info "Vérification des versions..."
    BUILD_MATRIX=""
    
    for addon in $ADDONS; do
        log_info "Traitement de l'addon: $addon"
        
        if [ ! -f "$addon/config.yaml" ]; then
            log_warning "config.yaml manquant pour $addon, skip"
            continue
        fi
        
        # Récupérer les informations de configuration
        VERSION=$(exec_in_container yq eval '.version' "$addon/config.yaml" 2>/dev/null | tr -d '"')
        SLUG=$(exec_in_container yq eval '.slug' "$addon/config.yaml" 2>/dev/null | tr -d '"')
        
        if [ -z "$VERSION" ] || [ -z "$SLUG" ]; then
            log_error "Impossible de lire la version ou le slug depuis $addon/config.yaml"
            continue
        fi
        
        # Récupérer les architectures
        ARCHS=$(exec_in_container yq eval '.arch[]' "$addon/config.yaml" 2>/dev/null | tr '\n' ' ')
        if [ -z "$ARCHS" ]; then
            log_error "Aucune architecture définie dans $addon/config.yaml"
            continue
        fi
        
        log_info "  Version: $VERSION"
        log_info "  Slug: $SLUG"
        log_info "  Architectures: $ARCHS"
        
        # Vérifier si les images existent déjà
        if [ "$SKIP_EXISTING" = true ] && [ "$FORCE_BUILD" = false ]; then
            SKIP_BUILD=true
            IMAGE_PREFIX="$REGISTRY/$OWNER/$REPO_PREFIX/$SLUG"
            
            for arch in $ARCHS; do
                IMAGE_TAG="$IMAGE_PREFIX-$arch:$VERSION"
                
                if exec_in_container docker manifest inspect "$IMAGE_TAG" > /dev/null 2>&1; then
                    log_info "  Image existante: $IMAGE_TAG"
                else
                    log_info "  Image manquante: $IMAGE_TAG"
                    SKIP_BUILD=false
                    break
                fi
            done
            
            if [ "$SKIP_BUILD" = true ]; then
                log_warning "  Skip - toutes les images existent déjà pour la version $VERSION"
                continue
            fi
        fi
        
        # Ajouter à la matrice de build
        if [ -n "$BUILD_MATRIX" ]; then
            BUILD_MATRIX="$BUILD_MATRIX,"
        fi
        BUILD_MATRIX="$BUILD_MATRIX{\"addon\":\"$addon\",\"version\":\"$VERSION\",\"slug\":\"$SLUG\",\"archs\":\"$ARCHS\"}"
        
        log_success "  Ajouté au build queue"
    done
    
    if [ -z "$BUILD_MATRIX" ]; then
        log_info "Aucun addon nécessitant un build"
        exit 0
    fi
    
    BUILD_MATRIX="[$BUILD_MATRIX]"
    log_success "Matrice de build créée"
}

# Configurer Docker Buildx
setup_buildx() {
    if [ "$BUILD_IN_CONTAINER" = true ]; then
        log_info "Configuration de Docker Buildx dans le container..."
        
        # Créer un builder si nécessaire dans le container
        if ! exec_in_container docker buildx inspect local-builder &> /dev/null; then
            exec_in_container docker buildx create --name local-builder --use --bootstrap
            log_success "Builder local-builder créé dans le container"
        else
            exec_in_container docker buildx use local-builder
            log_info "Builder local-builder utilisé dans le container"
        fi
    else
        log_info "Configuration de Docker Buildx..."
        
        # Vérifier si buildx est disponible
        if ! docker buildx version &> /dev/null; then
            log_error "Docker Buildx n'est pas disponible"
            exit 1
        fi
        
        # Créer un builder si nécessaire
        if ! docker buildx inspect local-builder &> /dev/null; then
            docker buildx create --name local-builder --use --bootstrap
            log_success "Builder local-builder créé"
        else
            docker buildx use local-builder
            log_info "Builder local-builder utilisé"
        fi
    fi
}

# Se connecter au registre si nécessaire
setup_registry() {
    if [ "$PUSH_TO_REGISTRY" = true ]; then
        log_info "Connexion au registre $REGISTRY..."
        
        # Vérifier si déjà connecté
        if exec_in_container docker buildx imagetools inspect "$REGISTRY/alpine:latest" &> /dev/null; then
            log_info "Déjà connecté au registre"
        else
            log_warning "Veuillez vous connecter au registre avec: docker login $REGISTRY"
            read -p "Appuyez sur Entrée une fois connecté, ou Ctrl+C pour annuler..."
        fi
    fi
}

# Builder les images
build_images() {
    log_info "Début du build des images..."
    
    # Créer le répertoire de cache
    CACHE_DIR="./.build-cache"
    mkdir -p "$CACHE_DIR"
    
    # Traiter chaque addon dans la matrice
    echo "$BUILD_MATRIX" | exec_in_container jq -c '.[]' | while read -r build_info; do
        addon=$(echo "$build_info" | exec_in_container jq -r '.addon')
        version=$(echo "$build_info" | exec_in_container jq -r '.version')
        slug=$(echo "$build_info" | exec_in_container jq -r '.slug')
        archs=$(echo "$build_info" | exec_in_container jq -r '.archs')
        
        log_info "Build de $addon version $version"
        
        # Récupérer la configuration de build
        BUILD_CONFIG="$addon/build.yaml"
        if [ ! -f "$BUILD_CONFIG" ]; then
            log_error "build.yaml manquant pour $addon"
            continue
        fi
        
        # Déterminer le type d'image de base
        if exec_in_container yq eval '.build_from | type' "$BUILD_CONFIG" 2>/dev/null | grep -q "!!map"; then
            BASE_IMAGE_TYPE="arch_specific"
        else
            BASE_IMAGE_TYPE="single"
            SINGLE_BASE_IMAGE=$(exec_in_container yq eval '.build_from' "$BUILD_CONFIG" 2>/dev/null | tr -d '"')
        fi
        
        # Builder pour chaque architecture
        for arch in $archs; do
            log_info "  Build pour $arch..."
            
            # Récupérer l'image de base
            if [ "$BASE_IMAGE_TYPE" = "arch_specific" ]; then
                BASE_IMAGE=$(exec_in_container yq eval ".build_from.$arch" "$BUILD_CONFIG" 2>/dev/null)
                if [ "$BASE_IMAGE" = "null" ] || [ -z "$BASE_IMAGE" ]; then
                    log_warning "  Pas d'image de base pour $arch, skip"
                    continue
                fi
            else
                BASE_IMAGE="$SINGLE_BASE_IMAGE"
            fi
            
            log_info "    Image de base: $BASE_IMAGE"
            
            # Mapper les architectures HA vers les plateformes Docker
            case "$arch" in
                "armv7") PLATFORM="linux/arm/v7" ;;
                "armhf") PLATFORM="linux/arm/v6" ;;
                "aarch64") PLATFORM="linux/arm64" ;;
                "amd64") PLATFORM="linux/amd64" ;;
                "i386") PLATFORM="linux/386" ;;
                *) PLATFORM="linux/$arch" ;;
            esac
            
            # Préparer les arguments de build
            BUILD_ARGS="--build-arg BUILD_FROM=$BASE_IMAGE"
            BUILD_ARGS="$BUILD_ARGS --build-arg BUILD_VERSION=$version"
            BUILD_ARGS="$BUILD_ARGS --build-arg BUILD_ARCH=$arch"
            
            # Préparer les tags
            IMAGE_TAG_LOCAL="$slug-$arch:$version"
            IMAGE_TAG_LATEST_LOCAL="$slug-$arch:latest"
            
            if [ "$PUSH_TO_REGISTRY" = true ]; then
                IMAGE_TAG_REGISTRY="$REGISTRY/$OWNER/$REPO_PREFIX/$slug-$arch:$version"
                IMAGE_TAG_LATEST_REGISTRY="$REGISTRY/$OWNER/$REPO_PREFIX/$slug-$arch:latest"
            fi
            
            # Construire la commande build
            BUILD_CMD="docker buildx build"
            BUILD_CMD="$BUILD_CMD $BUILD_ARGS"
            BUILD_CMD="$BUILD_CMD --platform $PLATFORM"
            BUILD_CMD="$BUILD_CMD --tag $IMAGE_TAG_LOCAL"
            BUILD_CMD="$BUILD_CMD --tag $IMAGE_TAG_LATEST_LOCAL"
            
            if [ "$PUSH_TO_REGISTRY" = true ]; then
                BUILD_CMD="$BUILD_CMD --tag $IMAGE_TAG_REGISTRY"
                BUILD_CMD="$BUILD_CMD --tag $IMAGE_TAG_LATEST_REGISTRY"
            fi
            
            BUILD_CMD="$BUILD_CMD --cache-from type=local,src=$CACHE_DIR"
            BUILD_CMD="$BUILD_CMD --cache-to type=local,dest=$CACHE_DIR-new,mode=max"
            
            if [ "$PUSH_TO_REGISTRY" = true ]; then
                BUILD_CMD="$BUILD_CMD --push"
            else
                BUILD_CMD="$BUILD_CMD --load"
            fi
            
            BUILD_CMD="$BUILD_CMD $addon/"
            
            log_info "    Exécution: $BUILD_CMD"
            
            # Exécuter le build
            if exec_in_container $BUILD_CMD; then
                log_success "    Build réussi pour $addon-$arch:$version"
                
                # Mettre à jour le cache
                rm -rf "$CACHE_DIR"
                mv "$CACHE_DIR-new" "$CACHE_DIR"
            else
                log_error "    Build échoué pour $addon-$arch:$version"
                exit 1
            fi
        done
    done
}

# Afficher un résumé
show_summary() {
    log_info "Résumé du build:"
    echo "$BUILD_MATRIX" | exec_in_container jq -r '.[] | "📦 \(.addon) v\(.version) - \(.archs)"'
    
    if [ "$PUSH_TO_REGISTRY" = true ]; then
        log_info "Images poussées vers: $REGISTRY/$OWNER/$REPO_PREFIX"
    else
        log_info "Images construites localement"
    fi
    
    if [ "$BUILD_IN_CONTAINER" = true ]; then
        log_info "Build effectué dans le container: $CONTAINER_NAME"
    fi
}

# Fonction principale
main() {
    log_info "Démarrage du script de build local"
    
    # Configurer le nettoyage automatique en cas d'erreur
    trap cleanup_build_container EXIT
    
    check_dependencies
    setup_build_container
    detect_changed_addons
    check_versions
    setup_buildx
    setup_registry
    show_summary
    
    read -p "Continuer avec le build? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Build annulé"
        exit 0
    fi
    
    build_images
    
    log_success "Build terminé avec succès!"
}

# Exécuter la fonction principale
main "$@"
