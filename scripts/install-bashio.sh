#!/bin/bash
set -euo pipefail

# Script d'installation universel pour bashio
# Détecte si bashio est utilisé et l'installe automatiquement

install_bashio() {
    if [ ! -f "/usr/bin/bashio" ]; then
        echo "🔧 Installation de bashio..."
        
        # Variables
        BASHIO_VERSION="latest"
        VERBOSE="${VERBOSE:-false}"
        
        # Créer le répertoire temporaire
        mkdir -p /tmp/bashio
        
        # Récupérer le tag de la dernière version
        BASHIO_TAG="$(curl -f -L -s -S "https://api.github.com/repos/hassio-addons/bashio/releases/${BASHIO_VERSION}" | awk -F '"' '/tag_name/{print $4; exit}')"
        
        if [ -z "$BASHIO_TAG" ]; then
            echo "❌ Impossible de récupérer la version de bashio"
            return 1
        fi
        
        echo "📦 Téléchargement de bashio ${BASHIO_TAG}..."
        
        # Télécharger et extraire bashio
        if curl -f -L -s -S "https://github.com/hassio-addons/bashio/archive/${BASHIO_TAG}.tar.gz" | tar -xzf - --strip 1 -C /tmp/bashio; then
            # Installer bashio
            mv /tmp/bashio/lib /usr/lib/bashio
            ln -s /usr/lib/bashio/bashio /usr/bin/bashio
            
            # Nettoyer
            rm -rf /tmp/bashio
            
            echo "✅ bashio installé avec succès"
        else
            echo "❌ Erreur lors du téléchargement de bashio"
            rm -rf /tmp/bashio
            return 1
        fi
    else
        echo "✅ bashio est déjà installé"
    fi
}

# Vérifier si bashio est utilisé dans les fichiers
check_bashio_usage() {
    local search_dir="${1:-/opt}"
    
    if [ -d "$search_dir" ]; then
        if grep -r -l "bashio" "$search_dir" >/dev/null 2>&1; then
            echo "🔍 bashio détecté dans les fichiers, installation..."
            return 0
        fi
    fi
    
    return 1
}

# Logique principale
if check_bashio_usage "/opt"; then
    install_bashio
else
    echo "ℹ️ bashio non détecté, installation ignorée"
fi
