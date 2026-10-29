# Samsung Remote Pro

Télécommande iOS native (SwiftUI) pour téléviseurs Samsung compatibles avec le canal local WebSocket Tizen. L’interface est conçue pour iPhone, avec un pavé tactile sombre, un mode directionnel, une connexion locale, un widget et une activité en direct.

## Ce qui est implémenté

- Connexion locale au canal `samsung.remote.control` sur `wss://TV:8002/api/v2/channels/samsung.remote.control` (par défaut) et mode `ws://TV:8001` volontairement choisi en dernier recours.
- Appairage : attente de l’autorisation affichée sur la TV, récupération du jeton retourné par le téléviseur et conservation du jeton dans le Trousseau iOS.
- Touches de navigation, accueil, retour, menu, alimentation, volume, sourdine, lecture/pause, retour/avance rapide et chaînes.
- Pavé tactile à gestes, avec protection contre les déclenchements multiples, ou pavé directionnel accessible.
- Découverte Bonjour/mDNS, vérification de l’API `/api/v2/` et scan IPv4 de repli, plus saisie manuelle d’adresse IP.
- Réessais de connexion limités, délai de 12 s, diagnostic lisible et journalisation sans jeton ni mot de passe.
- Demande de liste d’applications lorsqu’elle est exposée par la TV, lecture des URL de logos si le firmware en renvoie, catalogue local de secours pour quelques services courants et favoris manuels à partir d’un identifiant connu ; aucun identifiant n’est inventé.
- Saisie de texte par `SendInputString` Base64 (avec début/fin de session), uniquement si l’écran/l’application TV l’accepte.
- Icône d’application issue du visuel fourni, intégrée à l’asset catalog iOS.
- Interface principale réorganisée selon le visuel : Retour / Accueil / Applications, bascule de volume unique avec sourdine, puis Retour rapide / Lecture-pause / Avance rapide.
- Live Activity démarrée automatiquement après connexion, réutilisée/rafraîchie au retour dans l’app, avec choix de l’action rapide et jusqu’à cinq apps favorites. Le bouton Lecture/Pause bascule visuellement entre les états Lecture et Pause. Les vrais boutons d’action utilisent `LiveActivityIntent` pour exécuter les commandes sans afficher l’interface ; toucher le fond de l’activité ouvre toujours l’app.
- Actions App Intents disponibles dans Raccourcis pour les directions, valider, retour, accueil, menu, alimentation, volume, sourdine, commandes média et chaînes. Dix actions fréquentes disposent aussi de phrases Siri préconfigurées.
- Réglage de couleur des boutons dans Réglages > Personnalisation, répercuté sur la télécommande, le rocker de volume et les contrôles de la Live Activity.
- Réglages > Logos personnalisés des apps TV : chaque app détectée ou favorite peut recevoir une image importée depuis Photos, recadrée en carré avec coins arrondis, puis réutilisée dans la télécommande, la Dynamic Island et l’écran verrouillé.
- Widget petit/moyen conservé. Pour préserver la signature Sideloadly, pas d’App Group requis : les logos sont conservés localement et les cinq logos favoris réduits sont sérialisés dans l’état ActivityKit envoyé au WidgetKit.
- Option expérimentale pour traduire les changements du volume système en commandes de volume TV, uniquement quand l’app est au premier plan. iOS peut modifier aussi le volume de l’iPhone : les touches physiques ne sont pas exposées comme des événements directs aux apps tierces.
- Tests unitaires, test d’intégration opt-in et scripts de compilation/archivage macOS.

## Compatibilité réelle et protocole

Le modèle cible **UE55RU7405UXXC / [TV] Samsung 7 Series (55)** est une TV Tizen de la génération visée par les implémentations WebSocket 2016+. Le protocole de télécommande WebSocket n’est pas documenté comme API iOS publique par Samsung. Son enveloppe et son comportement ont été recoupés avec des implémentations open source actives ; le format de touche utilise `ms.remote.control`, `SendRemoteKey`, `Cmd: Click` et les codes `KEY_*`.

Les clés utilisées correspondent notamment aux noms de touches publiés par Samsung pour Tizen : [documentation Samsung des touches de télécommande](https://developer.samsung.com/smarttv/develop/guides/user-interaction/remote-control.html). L’enveloppe WebSocket et le point d’accès retenus sont documentés par des implémentations de référence : [samsung-tv-ws-api](https://github.com/xchwarze/samsung-tv-ws-api) et [analyse du canal MSF](https://github.com/TheFab21/ha-samsungtv-smart/blob/master/notes/QN55LS03FAFXZA/RPC_INTERNALS.md).

Cette base n’affirme pas que ce modèle a été validé ici : une TV physique sur le même réseau est nécessaire. Samsung peut modifier la prise en charge par firmware, région ou réglage de la TV.

## Installation gratuite sans Mac — Sideloadly

Cette édition retire uniquement l’App Group, une capacité Apple réservée aux profils provisionnés. La télécommande, la découverte, l’appairage, les commandes, les favoris, le clavier, le widget et la Live Activity restent dans le projet. Le widget affiche « Télécommande Samsung » et ouvre l’app, sans connaître la TV sélectionnée.

1. Pour une compilation entièrement gratuite, créez un dépôt GitHub **public** et copiez **le contenu** de l’archive (pas le dossier extérieur `SamsungRemotePro-main`) à la racine du dépôt. GitHub rend l’usage des runners standards gratuit pour les dépôts publics. Ce projet ne contient ni adresse IP de votre TV, ni jeton d’appairage, ni identifiant Apple : ne les ajoutez jamais au dépôt. Un dépôt privé peut utiliser le quota mensuel de votre compte GitHub et devenir payant au-delà.
2. Dans GitHub, ouvrez **Actions** puis lancez « Construire l’IPA Sideloadly ». Le fichier `.github/workflows/build-unsigned-ipa.yml` compile le projet sur un runner macOS et publie l’artefact `SamsungRemotePro-unsigned-ipa`.
3. Téléchargez l’artefact depuis la page de l’exécution réussie : il contient `SamsungRemotePro-unsigned.ipa`.
4. Sur Windows, installez Sideloadly et les composants iTunes/iCloud qu’il demande. Branchez l’iPhone par câble, déverrouillez-le et acceptez « Faire confiance » si demandé.
5. Glissez l’IPA dans Sideloadly, saisissez votre propre compte Apple directement dans Sideloadly, puis démarrez l’installation. Ne transmettez jamais votre mot de passe Apple à un tiers.
6. Sur l’iPhone, activez **Réglages > Confidentialité et sécurité > Mode développeur**. Ensuite, si iOS le demande, approuvez votre compte Apple dans **Réglages > Général > VPN et gestion de l’appareil**.
7. Lancez l’app, acceptez l’accès au réseau local, puis acceptez l’appairage présenté par la TV.

Avec un compte Apple gratuit, Sideloadly indique une validité de 7 jours et une limite de trois applications. Son démon de rafraîchissement peut réinstaller automatiquement l’app lorsque l’iPhone est à portée du PC. Consultez la [FAQ officielle Sideloadly](https://sideloadly.io/faq) si l’iPhone n’est pas détecté ou si le profil doit être approuvé.

La découverte Bonjour utilise le navigateur réseau intégré à iOS et déclare les deux types de service dans `NSBonjourServices`. Le scan IPv4 local sert de solution de repli sans entitlement de multicast. La saisie manuelle de l’adresse IP reste disponible.

## Configuration de la TV

1. Connectez l’iPhone et le téléviseur au même réseau local (même sous-réseau, sans isolation Wi‑Fi des clients).
2. Sur la TV, ouvrez les réglages de connexion des appareils et autorisez les appareils mobiles quand Samsung affiche la demande.
3. Si la TV redemande toujours l’autorisation, nettoyez sa liste d’appareils autorisés puis reconnectez l’app. Certains firmwares proposent une autorisation « première fois uniquement ».
4. Dans l’app, recherchez le téléviseur ou entrez son IPv4. Essayez d’abord la connexion sécurisée (8002).
5. N’utilisez le port 8001 non chiffré que sur un réseau domestique de confiance si la TV ne propose pas 8002.

## Limites connues — importantes

- Le téléviseur ne confirme pas individuellement l’exécution de chaque touche. L’app confirme uniquement la transmission au canal réseau, pas l’effet à l’écran.
- `KEY_REWIND` et `KEY_FF` ne garantissent pas un saut de 10 secondes : leur effet dépend de l’application TV ouverte. L’app ne prétend pas offrir une recherche temporelle exacte.
- Le volume peut être géré par une barre de son/amplificateur HDMI ARC plutôt que par la TV. Dans ce cas, les touches réseau TV peuvent n’avoir aucun effet.
- Le réveil depuis veille complète n’est pas garanti. `KEY_POWER` ne peut être envoyé qu’à une TV déjà joignable ; Wake-on-LAN n’est pas implémenté car il exige une adresse MAC fiable et un réglage de veille réseau du téléviseur.
- La liste complète des applications installées et les métadonnées de lecture ne sont pas exposées de façon fiable par ce protocole. Les favoris sont donc manuels. Aucun titre de streaming fictif n’est affiché sur l’écran verrouillé.
- La Live Activity est démarrée automatiquement lorsque le canal TV est connecté, mais reste gérée par iOS et peut être arrêtée par le système. iOS ne permet pas à l’app de savoir de façon fiable quand l’utilisateur force sa fermeture, donc l’activité peut rester affichée jusqu’à son expiration ou sa fermeture manuelle ; l’app la retrouve et l’actualise à sa réouverture. Elle ne maintient pas de connexion WebSocket séparée. Les boutons `LiveActivityIntent` reconstruisent le service à partir du téléviseur enregistré et du jeton stocké dans le Trousseau ; les boutons peuvent nécessiter le déverrouillage du téléphone.
- Les boutons physiques de volume sont observés via `AVAudioSession.outputVolume`, pas interceptés directement. Cette fonction est volontairement opt-in et active seulement au premier plan ; elle peut également modifier le volume système de l’iPhone et ne détecte pas forcément les pressions quand le volume est déjà à sa limite.
- La saisie de texte dépend du contexte IME fourni par la TV et peut être ignorée par certaines apps.
- iOS ne donne pas à une app tierce un contrôle universel des contrôles multimédias de l’écran verrouillé d’une TV. Cette app ne détourne pas les API audio pour simuler ce comportement.
- Le certificat TLS fourni par certaines TV peut être auto-signé. Pour tenir compte des certificats auto-signés de certains téléviseurs, le délégué accepte le certificat présenté uniquement lorsqu’il se connecte à une adresse IPv4 privée/link-local. Cela ne prouve pas cryptographiquement l’identité de la TV : ne connectez que votre propre téléviseur sur un réseau de confiance. Si la connexion sécurisée ne répond pas, l’app essaie l’autre port; le port 8001 transmet les échanges sans chiffrement.

Les logos personnalisés sont stockés localement : une suppression complète de l’app peut les effacer si aucune sauvegarde iOS ne les restaure. Le bouton Lecture/Pause affiche la dernière commande envoyée, pas un état de lecture confirmé par la TV.

## Tests et compilation

Sur macOS :

```sh
cd SamsungRemotePro
chmod +x Scripts/build.sh Scripts/package.sh
Scripts/build.sh
```

Le test d’intégration ne modifie pas la TV et ne transmet pas de touche. Pour le lancer sur le réseau réel :

```sh
SAMSUNG_TV_HOST=192.168.1.42 xcodebuild -project SamsungRemotePro.xcodeproj -scheme SamsungRemotePro -destination 'platform=iOS Simulator,name=iPhone 15 Pro' test
```

Une vérification de l’appairage et des commandes exige un iPhone physique car le simulateur ne partage pas les conditions de réseau local et de signature de l’appareil. Sans Mac, utilisez le workflow GitHub Actions fourni pour la compilation, puis Sideloadly pour la signature locale.

## Archivage et IPA

`Scripts/package.sh` crée une archive Xcode sur Mac. Sans Mac, le workflow GitHub Actions crée un IPA volontairement non signé ; Sideloadly signe ensuite localement sur votre PC avec votre compte Apple. Aucun mot de passe, certificat ou identifiant Apple n’est stocké dans ce projet.

## Arborescence

- `Sources/Services` : réseau, protocole, découverte et activité en direct.
- `Sources/Views` : flux de bienvenue, recherche, télécommande, réglages et diagnostic.
- `Sources/Storage` : appareils/préférences de l’app et jeton (Trousseau).
- `Widgets` et `AppIntents` : widget et activité en direct.
- `Tests` : unités et intégration opt-in.
- `BUILD_REPORT.md` : état exact des vérifications réalisées ici.


## Dépannage réseau
- Autoriser l'accès au réseau local dans Réglages iOS.
- L'iPhone et la TV doivent être sur le même réseau, sans réseau invité ni isolation des clients Wi-Fi.
- Pour une saisie manuelle, laisser la connexion sécurisée recommandée activée ; l’app essaie automatiquement l’autre port si le premier ne répond pas.
- Accepter la demande d'autorisation qui apparaît sur l'écran de la TV lors de la première connexion.


## Découverte réseau (version expérimentale)
La recherche combine Bonjour/mDNS (`_samsungmsf._tcp` et `_samsungctl._tcp`) avec un scan IPv4 du sous-réseau Wi-Fi calculé à partir du masque de l’interface `en0`, puis valide les candidats via `/api/v2/` sur 8002 et 8001. Les deux ports sont testés en parallèle et le mode sécurisé est privilégié. Sur les sous-réseaux inhabituellement larges, le scan est limité à une fenêtre de 1 025 adresses autour du téléphone. L’autorisation iOS Réseau local doit être accordée. Certains routeurs isolent les appareils Wi-Fi ou utilisent des VLAN, ce qui peut empêcher la découverte. Les commandes JSON sont émises comme trames WebSocket texte. Voir `BUILD_REPORT.md`.
