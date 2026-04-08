# Plan pour corriger les WebSocket Planka

## Problème identifié
- Les WebSocket échouent avec `ws://IP:1338/socket.io/`
- La configuration nginx actuelle utilise `$connection_upgrade` mais cette variable n'est pas correctement définie
- Sails.js utilise socket.io qui nécessite une configuration spécifique

## Solution proposée
1. **Corriger la configuration nginx** :
   - Utiliser `proxy_set_header Connection $http_upgrade` au lieu de `$connection_upgrade`
   - Ajouter une location spécifique pour `/socket.io/`
   - Simplifier la configuration pour éviter les conflits

2. **Configuration Sails.js** :
   - Le fichier `config/sails.js` est déjà bien configuré avec des origins permissives
   - Vérifier que la configuration est bien chargée

3. **Tests à effectuer** :
   - Démarrer l'addon
   - Vérifier les logs nginx et Planka
   - Tester la connexion WebSocket via l'interface web
   - Vérifier que les endpoints API répondent correctement

## Étapes de mise en œuvre
1. Modifier `nginx.conf` pour corriger les headers WebSocket
2. Ajouter une location dédiée pour `/socket.io/`
3. Tester et valider la connexion
4. Ajouter des logs détaillés si nécessaire

Cette approche devrait résoudre les problèmes de WebSocket en suivant les meilleures pratiques pour Sails.js derrière nginx.
