# Samsung Remote Pro

Télécommande iOS native (SwiftUI) pour téléviseurs Samsung compatibles avec le canal local WebSocket Tizen. L’interface est conçue pour iPhone, avec un pavé tactile sombre, un mode directionnel, une connexion locale, un widget et une activité en direct.

## Ce qui est implémenté

- Connexion locale au canal `samsung.remote.control` sur `wss://TV:8002/api/v2/channels/samsung.remote.control` (par défaut) et mode `ws://TV:8001` volontairement choisi en dernier recours.
- Appairage : attente de l’autorisation affichée sur la TV, récupération du jeton retourné par le téléviseur et conservation du jeton dans le Trousseau iOS.
- Touches de navigation, accueil, retour, menu, alimentation, volume, sourdine, lecture/pause, retour/avance rapide et chaînes.
- Pavé tactile à gestes, avec protection contre les déclenchements multiples, ou pavé directionnel accessible.
- Découverte SSDP et vérification de l’API `/api/v2/`, plus saisie manuelle d’adresse IP.
- Réessais de connexion limités, délai de 12 s, diagnostic lisible et journalisation sans jeton ni mot de passe.
- Demande de liste d’applications lorsqu’elle est exposée par la TV, et favoris manuels à partir d’un identifiant connu ; aucun identifiant n’est inventé.
- Saisie de texte par `SendInputString` Base64 (avec début/fin de session), uniquement si l’écran/l’application TV l’accepte.
- Widget petit/moyen et activité en direct qui ouvrent l’app ; ils ne gardent pas de socket et n’exécutent pas de réseau prolongé en extension. Cette édition Sideloadly n’utilise aucun App Group : le widget est un raccourci générique et ne lit pas le nom de la TV sélectionnée.
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

Pour la découverte SSDP, iOS peut nécessiter l’entitlement Apple de multicast, qui n’est pas inclus afin de préserver la signature gratuite. La saisie manuelle de l’adresse IP fonctionne sans cette capacité.

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
- La Live Activity est explicitement déclenchée par l’utilisateur, peut être arrêtée par iOS et ne maintient aucune connexion réseau persistante. Le widget/île dynamique ouvrent l’app pour les actions.
- La saisie de texte dépend du contexte IME fourni par la TV et peut être ignorée par certaines apps.
- iOS ne donne pas à une app tierce un contrôle universel des contrôles multimédias de l’écran verrouillé d’une TV. Cette app ne détourne pas les API audio pour simuler ce comportement.
- Le certificat TLS fourni par certaines TV peut être auto-signé. L’app ne contourne jamais la validation TLS d’iOS. Si la validation échoue, le mode non chiffré doit être choisi explicitement et uniquement sur un réseau de confiance.

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
- Pour une saisie manuelle, essayer d'abord le port 8001, puis activer le port 8002 si nécessaire.
- Accepter la demande d'autorisation qui apparaît sur l'écran de la TV lors de la première connexion.
