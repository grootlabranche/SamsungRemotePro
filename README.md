<div align="center">

# Samsung Remote Pro

### La télécommande Samsung, directement sur votre iPhone.

Application iOS native en SwiftUI pour piloter les téléviseurs Samsung compatibles Tizen via le réseau local.

![iOS](https://img.shields.io/badge/Plateforme-iOS-111111?logo=apple)
![SwiftUI](https://img.shields.io/badge/UI-SwiftUI-orange?logo=swift)
![Build](https://img.shields.io/badge/CI-GitHub%20Actions-2088FF?logo=githubactions)
![Version](https://img.shields.io/badge/version-1.3.0-blue)
![watchOS](https://img.shields.io/badge/watchOS-non%20inclus-lightgrey)

**[Télécharger une release](https://github.com/grootlabranche/SamsungRemotePro/releases/latest)** · **[Signaler un problème](https://github.com/grootlabranche/SamsungRemotePro/issues)** · **[Builds CI](https://github.com/grootlabranche/SamsungRemotePro/actions)**

</div>

---

## Sommaire
- [Aperçu](#aperçu)
- [Fonctionnalités](#fonctionnalités)
- [Compatibilité](#compatibilité)
- [Installer sur iPhone depuis Windows](#installer-sur-iphone-depuis-windows)
- [Première connexion à la TV](#première-connexion-à-la-tv)
- [Compiler depuis les sources](#compiler-depuis-les-sources)
- [Organisation du dépôt](#organisation-du-dépôt)
- [Builds et releases](#builds-et-releases)
- [Dépannage](#dépannage)
- [Sécurité](#sécurité)
- [Limites connues](#limites-connues)
- [Contribuer](#contribuer)
- [Licence](#licence)

## Aperçu

Samsung Remote Pro est une **application iPhone uniquement**. Le projet Xcode ne contient aucune cible watchOS. Les fonctions iOS conservées incluent la télécommande tactile, la découverte réseau, l’appairage, les favoris, les raccourcis, le widget iOS et la Live Activity.

### Architecture

~~~mermaid
flowchart TD
    A["iPhone · Samsung Remote Pro"] -->|"Découverte réseau"| B["Wi-Fi local"]
    B --> C["Téléviseur Samsung Tizen"]
    A -->|"WebSocket · port 8002"| C
    A --> D["Trousseau iOS · jeton"]
    A --> E["Widget iOS / Live Activity"]
    F["Windows · Sideloadly"] -->|"Signature et installation"| A
    G["GitHub Actions · macOS"] --> H["IPA iOS non signée"]
    H --> F
~~~

### Visuels de l’interface

Les captures réelles seront ajoutées dans le dossier docs/images quand elles seront disponibles. Aucun faux screenshot n’est utilisé comme si l’application avait été exécutée.

## Fonctionnalités

| Fonction | Détails |
|---|---|
| Navigation | Directions, validation, retour, accueil, menu et alimentation |
| Volume | Volume +/− et sourdine |
| Média | Lecture/pause, avance/retour rapide et chaînes, selon l’application TV |
| Pavé tactile | Gestes tactiles et navigation directionnelle |
| Découverte | Bonjour/mDNS, scan local de secours et adresse IP manuelle |
| Connexion | WebSocket sécurisé prioritaire et repli selon la TV |
| Appairage | Autorisation sur la TV, jeton conservé dans le Trousseau iOS |
| Applications | Favoris et logos personnalisés |
| Texte | Envoi de texte si l’application TV le permet |
| Personnalisation | Couleur des boutons et logos |
| Widget et Live Activity | Accès rapide et commandes prises en charge par iOS |
| Siri et Raccourcis | App Intents pour les commandes disponibles |
| Diagnostics | Messages lisibles, sans journaliser le jeton d’appairage |

## Compatibilité

- **Plateforme :** iPhone, iOS 18 ou ultérieur selon les réglages du projet.
- **TV visée pendant le développement :** Samsung UE55RU7405UXXC, série Tizen 7.
- **Réseau :** iPhone et TV doivent communiquer sur le même réseau local.
- **Apple Watch :** non prise en charge dans cette édition.
- **Attention :** compatibilité non garantie sur tous les modèles et firmwares Samsung. Une TV physique est nécessaire pour valider les commandes.

## Installer sur iPhone depuis Windows

L’IPA générée par GitHub Actions est **non signée**. Elle doit être signée par un outil de sideloading avant installation. Sideloadly est un outil tiers ; téléchargez-le depuis son site officiel et ne partagez jamais votre mot de passe Apple avec le mainteneur du dépôt.

### 1. Télécharger l’IPA

1. Ouvrez la page [Releases](https://github.com/grootlabranche/SamsungRemotePro/releases).
2. Téléchargez le fichier **SamsungRemotePro-unsigned.ipa** depuis la dernière release qui contient ce fichier.
3. Si aucune release n’est disponible, ouvrez [Actions](https://github.com/grootlabranche/SamsungRemotePro/actions), sélectionnez une exécution réussie et téléchargez l’artefact **SamsungRemotePro-unsigned-ipa**.
4. Ne prenez pas un artefact d’un build rouge ou en cours en supposant qu’il contient les dernières corrections.

### 2. Préparer Windows et l’iPhone

1. Installez Sideloadly depuis [sideloadly.io](https://sideloadly.io/).
2. Installez les composants Apple demandés par l’outil, si nécessaire.
3. Branchez l’iPhone avec un câble USB compatible données.
4. Déverrouillez l’iPhone et acceptez « Faire confiance à cet ordinateur » si iOS le demande.

### 3. Installer l’application

1. Ouvrez Sideloadly.
2. Glissez-déposez le fichier IPA dans la fenêtre.
3. Saisissez votre compte Apple uniquement dans l’outil local si cela est demandé.
4. Lancez l’installation et attendez le message de réussite.
5. Suivez les demandes iOS concernant le mode développeur ou la confiance envers le profil, si elles apparaissent sur votre version d’iOS.

Les menus varient selon la version d’iOS et la méthode de signature. En cas d’erreur, consultez la [FAQ officielle Sideloadly](https://sideloadly.io/faq).

### 4. Renouvellement

Avec une signature gratuite, les applications sideloadées ont généralement une durée de validité limitée et doivent être re-signées périodiquement. Les durées et limites exactes dépendent du compte Apple et de l’outil utilisé. Consultez la documentation officielle de l’outil.

## Première connexion à la TV

1. Connectez l’iPhone et la TV au même réseau domestique. Évitez le réseau invité et l’isolation des clients Wi-Fi.
2. Ouvrez l’app et autorisez l’accès au **Réseau local** dans iOS.
3. Recherchez la TV. Si elle n’apparaît pas, entrez son adresse IPv4 manuellement.
4. Essayez d’abord le canal sécurisé sur le port 8002.
5. Acceptez la demande d’autorisation affichée par le téléviseur.
6. Testez les directions, Accueil et Volume.

| Port | Usage | Conseil |
|---|---|---|
| TCP 8002 | WebSocket sécurisé | À privilégier |
| TCP 8001 | WebSocket non chiffré, selon firmware | Seulement sur un réseau de confiance |

## Compiler depuis les sources

### Prérequis
- macOS et une version compatible de Xcode.
- Git.
- Un iPhone physique pour tester le réseau local.
- Une TV Samsung compatible pour tester les commandes réelles.

### Récupérer et ouvrir le projet

~~~bash
git clone https://github.com/grootlabranche/SamsungRemotePro.git
cd SamsungRemotePro
open SamsungRemotePro.xcodeproj
~~~

Dans Xcode, sélectionnez le schéma **SamsungRemotePro**, choisissez un simulateur ou un iPhone et lancez la compilation. Pour installer sur un appareil réel, configurez la signature de développement dans Xcode.

### Compilation en ligne de commande

~~~bash
xcodebuild -list -project SamsungRemotePro.xcodeproj
xcodebuild -project SamsungRemotePro.xcodeproj \
  -scheme SamsungRemotePro \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  CODE_SIGNING_ALLOWED=NO build
~~~

Un contrôle syntaxique ne remplace pas une compilation complète avec le SDK Apple.

## Organisation du dépôt

~~~text
SamsungRemotePro/
├── .github/workflows/   # Validation, build IPA et release
├── AppIntents/          # Actions Siri et Raccourcis
├── Config/              # Plists et configuration iOS
├── Resources/           # Icône, assets et chaînes localisées
├── Scripts/             # Scripts de build et validation
├── Sources/
│   ├── App/             # Entrée SwiftUI
│   ├── Models/          # Modèles et commandes
│   ├── Services/        # WebSocket, découverte et réseau
│   ├── Storage/         # Préférences et Trousseau
│   ├── Utilities/       # Utilitaires
│   ├── ViewModels/      # Logique de présentation
│   └── Views/           # Écrans SwiftUI
├── Tests/
│   ├── UnitTests/
│   └── IntegrationTests/
├── Widgets/             # Widget iOS et Live Activity
├── README.md
└── BUILD_REPORT.md      # Historique des changements et limites
~~~

## Builds et releases

Le workflow **Build iOS IPA** est conçu pour :
1. récupérer le code ;
2. vérifier la configuration et la syntaxe ;
3. archiver l’application iOS sur un runner macOS ;
4. produire une IPA non signée avec Payload/SamsungRemotePro.app ;
5. vérifier le ZIP ;
6. publier l’IPA comme artefact de build ;
7. pour un tag de version commençant par v, joindre l’IPA à une release GitHub après réussite du build.

Une release n’est valide que si le workflow a terminé avec succès et que la page Releases contient l’IPA. Ne publiez pas un build rouge comme version stable.

## Dépannage

<details>
<summary><strong>La TV n’apparaît pas</strong></summary>

Vérifiez le même réseau, l’autorisation Réseau local iOS, l’absence d’isolation Wi-Fi, puis essayez l’adresse IP manuelle. Le routeur peut bloquer les connexions locales.
</details>

<details>
<summary><strong>La TV ne demande pas l’autorisation</strong></summary>

Vérifiez les réglages de connexion des appareils du téléviseur et sa liste d’appareils autorisés, puis relancez l’appairage. Les menus dépendent du firmware.
</details>

<details>
<summary><strong>Le port 8002 ne répond pas</strong></summary>

Certains firmwares ne proposent pas le même service. Vérifiez la joignabilité de la TV ; n’utilisez le port 8001 non chiffré que sur un réseau domestique de confiance.
</details>

<details>
<summary><strong>Sideloadly ne détecte pas l’iPhone</strong></summary>

Essayez un câble de données, déverrouillez l’iPhone, acceptez la demande de confiance et suivez la documentation officielle de Sideloadly.
</details>

<details>
<summary><strong>Le build Actions échoue</strong></summary>

Ouvrez l’exécution dans Actions, sélectionnez le premier step rouge et lisez le message d’erreur original. Un build rouge ne doit pas être publié.
</details>

## Sécurité et confidentialité

- Les commandes TV sont envoyées sur le réseau local ; aucun serveur cloud n’est requis pour le contrôle.
- Le jeton d’appairage est conservé dans le Trousseau iOS.
- N’ajoutez aucun jeton TV, mot de passe Apple, certificat privé ou profil de provisioning au dépôt.
- Le port 8001 transmet les données sans chiffrement ; évitez-le sur les réseaux publics.
- Connectez-vous uniquement à votre téléviseur sur un réseau de confiance.
- L’IPA du workflow est non signée ; la signature et l’installation sont gérées localement par l’outil de sideloading choisi.

## Limites connues

- Les touches et leurs effets dépendent du modèle, du firmware et de l’application TV active.
- Le téléviseur ne confirme pas toujours l’exécution individuelle d’une commande.
- Le réveil depuis veille profonde n’est pas garanti.
- Les métadonnées d’applications, logos et informations de lecture ne sont pas toujours exposés par la TV.
- iOS n’expose pas directement les pressions physiques de volume aux apps tierces.
- La compilation seule ne prouve pas la compatibilité avec un téléviseur réel.

## Contribuer

1. Ouvrez une issue avec le modèle de TV, la version de firmware et les étapes de reproduction.
2. Ne publiez aucune adresse IP publique, aucun jeton ou identifiant personnel.
3. Travaillez dans une branche dédiée.
4. Vérifiez les changements et les tests pertinents.
5. Ouvrez une pull request avec le résultat CI et les limites restantes.

## Licence

Aucun fichier de licence explicite n’a été confirmé dans le dépôt. Jusqu’à l’ajout d’une licence, ne supposez pas que le code peut être redistribué librement.
