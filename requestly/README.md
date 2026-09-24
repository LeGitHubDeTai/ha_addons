# Add-on Requestly pour Home Assistant

Intercepteur HTTP open-source, mocks d'API et débogage réseau — basé sur [requestly/interceptor](https://github.com/requestly/interceptor) (web UI).

## Fonctionnalités

- Redirection d'URLs et changement d'environnements (prod → local/staging)
- Modification des en-têtes et corps de requêtes/réponses
- Mocks d'API locaux pour développer sans backend
- Injection de scripts, Map Local / Map Remote
- Import Charles Proxy, ModHeader, Resource Override

> Associez l'extension navigateur **Requestly** (Chrome / Edge / Firefox) à cette instance auto-hébergée pour intercepter le trafic de votre navigateur.

## Accès

- Via **Ingress** (recommandé) depuis la barre latérale HA
- Ou port direct `3000/tcp` (à exposer explicitement si besoin)
