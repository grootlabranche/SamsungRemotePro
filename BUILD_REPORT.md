# Rapport de réparation - Samsung Remote Pro

## Modifications appliquées
- Suppression des anciennes copies de projet et conservation d'une seule arborescence Xcode.
- Interface de télécommande refaite avec défilement vertical, pavé tactile dimensionné à l'écran et boutons multimédias en grille adaptative.
- En-tête compact : le nom de la TV n'est affiché comme connecté que lorsque le canal est établi ; une TV ajoutée manuellement ne reçoit plus un faux nom générique après échec de détection.
- Connexion manuelle : le port 8001 est proposé par défaut pour éviter les échecs de validation des certificats locaux auto-signés fréquents sur les téléviseurs Samsung. Le port 8002 reste disponible par bascule.
- Échec de vérification manuelle explicite au lieu d'enregistrer une fausse TV et de fermer la fenêtre comme si la connexion avait fonctionné.
- Amélioration du traitement des en-têtes SSDP et déclaration ATS pour les connexions locales HTTP.

## Limites de validation
Le projet n'a pas été compilé avec Xcode dans cet environnement. La découverte SSDP/multicast peut encore dépendre des restrictions iOS et du réseau Wi-Fi ; l'autorisation « Réseau local » doit être acceptée sur l'iPhone. Pour tester la connexion, utiliser d'abord l'IP réelle de la TV, même Wi-Fi, puis essayer 8001 et 8002.


## Correctif de découverte réseau

La découverte SSDP interroge maintenant plusieurs cibles (ssdp:all, upnp:rootdevice et le service RemoteControlReceiver Samsung). Le parseur ne filtre plus les réponses sur le mot « Samsung » avant vérification : chaque hôte trouvé doit encore répondre à l’API Samsung pour être retenu. Ce changement améliore la couverture SSDP, mais ne garantit pas la découverte si iOS/le routeur bloque le multicast. La validation TLS standard peut encore empêcher la sonde HTTPS sur certains téléviseurs avec certificat local; cette archive ne prétend pas corriger ce point du transport WebSocket. Compilation Xcode réelle non exécutée dans cet environnement.
