# Plan pour corriger l'erreur de configuration WebSocket

## Problème identifié
- Erreur `Must specify a protocol like http:// or https://, but instead got: *`
- La configuration `origin: '*'` dans sockets.cors n'est pas valide pour Sails.js
- Il faut utiliser une configuration CORS valide avec un protocole

## Solution proposée
1. **Corriger la configuration sockets** dans local.js :
   - Remplacer `origin: '*'` par `origin: ['*']` ou supprimer complètement
   - Garder `onlyAllowOrigins: ['*']` qui est correct
2. **Simplifier la configuration** :
   - Supprimer les configurations CORS dupliquées
   - Garder uniquement les configurations essentielles
3. **Tester la configuration** :
   - Vérifier que Sails.js démarre sans erreur
   - Confirmer que les WebSocket fonctionnent

## Étapes de mise en œuvre
1. Modifier config/local.js pour corriger l'erreur CORS
2. Simplifier la configuration pour éviter les conflits
3. Tester et valider le démarrage
4. Vérifier les connexions WebSocket

Cette approche devrait résoudre l'erreur de protocole et permettre à Planka de démarrer correctement.
