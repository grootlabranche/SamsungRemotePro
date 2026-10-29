# SamsungRemotePro – rapport de correction réseau (29 octobre 2026)

## Corrections appliquées au projet fourni
- Correction de l’erreur Swift signalée par GitHub Actions : suppression du `guard let` appliqué à `compactMap`, qui renvoyait déjà un tableau non optionnel.
- Découverte réseau : Bonjour/mDNS et scan de repli sont exécutés en parallèle. Le scan utilise l’adresse IPv4 et le masque réel de l’interface Wi-Fi `en0` au lieu de supposer systématiquement un réseau `/24`. Sur un sous-réseau inhabituellement large, le scan est limité à une fenêtre de 1 025 adresses autour du téléphone.
- Les tests des endpoints HTTPS `8002` et HTTP `8001` sont lancés en parallèle et le résultat sécurisé est privilégié. Les lots de scan sont limités à 32 adresses pour éviter d’ouvrir plusieurs centaines de connexions simultanément.
- La recherche et la connexion manuelle n’acceptent que des adresses IPv4 privées/locales. Le port choisi dans le formulaire est essayé en premier, puis l’autre endpoint est essayé comme solution de repli.
- Correction du transport de commandes : le JSON de la télécommande est maintenant envoyé en trame WebSocket **texte** (`.string`) au lieu de trame binaire (`.data`). Les canaux Samsung de référence transmettent le JSON comme message texte.
- Le délégué TLS de la session de découverte est conservé explicitement, comme celui de la session WebSocket.
- Les diagnostics réseau expliquent mieux qu’une absence de résultat peut venir du même réseau local, de l’autorisation iOS Réseau local ou du téléviseur qui n’expose pas les ports.

## Recherche documentaire
- Samsung publie la documentation de touches Tizen et du SDK Smart View. Le SDK Smart View concerne la découverte et la communication entre apps compatibles TV/mobile ; cela ne constitue pas une documentation publique du canal de télécommande local `samsung.remote.control`. Le navigateur iOS déclare `_samsungmsf._tcp` et `_samsungctl._tcp` dans `NSBonjourServices`; ces services sont des indices de découverte, pas une preuve suffisante de compatibilité, d’où la vérification HTTP qui suit.
- Le canal WebSocket local `samsung.remote.control`, l’endpoint `/api/v2/` et les ports habituels `8001`/`8002` sont recoupés avec des implémentations open source, notamment `xchwarze/samsung-tv-ws-api` et `ollo69/ha-samsungtv-smart`. L’intégration Home Assistant d’ollo69 est un composant Python, pas une bibliothèque Swift utilisable directement.
- La validation `/api/v2/` identifie une TV seulement quand l’endpoint renvoie une réponse JSON avec les informations d’appareil attendues. Les commandes sont toujours dépendantes du firmware, des autorisations affichées à l’écran et de l’application active sur la TV.

## Limites restantes / vérification
- Le scan ne peut pas traverser les VLAN, les réseaux invités isolés ou les sous-réseaux auxquels l’iPhone n’a pas accès. Les politiques iOS/routeur peuvent limiter Bonjour/mDNS ou isoler les clients Wi-Fi.
- La confiance TLS pour un certificat local non reconnu est restreinte aux IP privées/link-local, mais cela n’authentifie pas cryptographiquement la TV : n’utilisez la connexion qu’avec un appareil de confiance sur votre LAN. Le port 8001 est en clair.
- Aucun accès à la TV physique ni au SDK iOS/Xcode Apple n’est disponible dans cet environnement. Le texte source et le journal fourni ont été audités, mais une compilation GitHub Actions et un essai réel sur la TV restent indispensables pour confirmer le résultat.
