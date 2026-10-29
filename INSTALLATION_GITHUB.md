# Remplacer le contenu du dépôt GitHub par cette version propre

## Avant de commencer
Téléchargez et conservez une copie de l’ancien dépôt ou créez une branche de sauvegarde. La suppression du contenu du dépôt est une opération destructive.

## Méthode recommandée : remplacer les fichiers dans le dépôt existant
1. Téléchargez `SamsungRemotePro-clean.zip` et extrayez-le sur votre PC.
2. Ouvrez le dossier extrait. Vous devez voir directement `.github`, `AppIntents`, `Config`, `Resources`, `Scripts`, `Sources`, `Tests`, `Widgets`, `SamsungRemotePro.xcodeproj`, `README.md` et `BUILD_REPORT.md`.
3. Dans GitHub, ouvrez votre dépôt, puis **Add file > Upload files**.
4. Faites glisser le contenu du dossier extrait, pas le fichier ZIP et pas le dossier parent `SamsungRemotePro-clean`.
5. Si GitHub demande de remplacer des fichiers existants, acceptez. Attention : l’interface web ne supprime pas automatiquement les anciens fichiers qui ne sont plus présents. Pour supprimer les doublons, utilisez la méthode Git ci-dessous ou supprimez les dossiers `SamsungRemotePro/`, `SamsungRemotePro-Sideloadly/` et le fichier `build-unsigned-ipa.yml` à la racine.
6. Validez le commit sur la branche `main`.

## Méthode la plus propre avec GitHub Desktop
1. Faites une sauvegarde locale de votre dépôt.
2. Ouvrez le dossier local du dépôt cloné.
3. Supprimez son contenu suivi par Git, mais gardez le dossier `.git` (il est caché). Ne supprimez surtout pas `.git`, sinon vous n’êtes plus dans le dépôt cloné.
4. Extrayez l’archive propre dans ce dossier et copiez **le contenu** à la racine. À la racine, `SamsungRemotePro.xcodeproj` doit être visible directement.
5. Dans GitHub Desktop, vérifiez la liste des fichiers supprimés/ajoutés/modifiés, puis committez et poussez vers `main`.

## Arborescence attendue à la racine de GitHub
```text
.github/
  workflows/
    build-unsigned-ipa.yml
AppIntents/
Config/
Resources/
Scripts/
Sources/
  App/
  Models/
  Services/
  Storage/
  Utilities/
  ViewModels/
  Views/
Tests/
  IntegrationTests/
  UnitTests/
Widgets/
SamsungRemotePro.xcodeproj/
.gitignore
BUILD_REPORT.md
LICENSE
README.md
```

Ne téléversez pas le dossier extérieur `SamsungRemotePro-clean` comme un seul dossier. GitHub doit voir `SamsungRemotePro.xcodeproj` et `.github` directement à la racine. Évitez de conserver plusieurs copies des mêmes fichiers : elles rendent la compilation et les futures corrections inutilement ambiguës.

## Relancer la compilation
1. Dans le dépôt GitHub, ouvrez **Actions**.
2. Choisissez **Construire l’IPA Sideloadly**.
3. Cliquez sur **Run workflow** sur la branche `main` (ou attendez le lancement automatique après le commit).
4. Si la compilation réussit, ouvrez l’exécution et téléchargez l’artefact `SamsungRemotePro-unsigned-ipa`.
5. Extrayez l’artefact téléchargé pour récupérer `SamsungRemotePro-unsigned.ipa`, puis utilisez Sideloadly sur Windows pour la signer et l’installer.

L’IPA produite par GitHub Actions est non signée. Le fichier doit être signé par Sideloadly avant installation sur l’iPhone.
