# Plan pour corriger Planka avec la documentation officielle

## Problèmes identifiés
- WebSocket ne fonctionne pas malgré toutes les tentatives
- Configuration nginx ne suit pas les recommandations officielles
- Variables d'environnement mal configurées
- Démarrage incorrect de Planka

## Solution basée sur la documentation officielle

### 1. Configuration nginx officielle
- Utiliser la configuration nginx officielle de Planka
- Location spécifique pour `~* \.io` (WebSocket)
- Upstream correct avec keepalive
- Timeouts appropriés (1d pour WebSocket)
- Headers spécifiques pour socket.io

### 2. Variables d'environnement
- Utiliser BASE_URL correctement
- Configurer DEFAULT_ADMIN_EMAIL, DEFAULT_ADMIN_PASSWORD, DEFAULT_ADMIN_NAME
- Supprimer les variables après premier démarrage
- Utiliser les variables d'environnement standards

### 3. Démarrage de Planka
- Utiliser la méthode de démarrage officielle
- Configurer correctement les ports
- S'assurer que Planka écoute sur le bon port

### 4. Architecture correcte
- Planka sur port 1337 (recommandé officiellement)
- nginx sur port 1339 pour ingress
- Proxy correct vers Planka

## Étapes de mise en oeuvre
1. Remplacer nginx.conf par la configuration officielle
2. Corriger les variables d'environnement dans run.sh
3. Mettre à jour les ports pour correspondre à la documentation
4. Tester et valider les WebSocket

Cette approche utilise la configuration officielle testée et devrait résoudre tous les problèmes.
