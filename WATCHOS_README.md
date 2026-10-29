# SamsungRemotePro 1.2.7 — compagnon Apple Watch

Cette version ajoute une cible watchOS dédiée, compatible à partir de watchOS 10, intégrée à la cible iOS afin que l’archive iOS contienne le compagnon Apple Watch.

## Commandes disponibles sur la montre
- Navigation haut/bas/gauche/droite et OK
- Accueil et Retour
- Marche/arrêt
- Volume +/− et Muet
- Lecture/Pause
- Chaîne +/−

## Fonctionnement
La montre envoie les commandes via WatchConnectivity à l’iPhone. L’iPhone doit être jumelé à la montre, SamsungRemotePro doit être installé et ouvert, et le téléviseur doit déjà être sélectionné/configuré dans l’app iPhone. La montre ne se connecte pas directement au téléviseur.

## Compilation
Ouvrir `SamsungRemotePro.xcodeproj` sur macOS avec Xcode, sélectionner le schéma `SamsungRemotePro`, puis compiler/archiver pour iOS. La cible `SamsungRemoteProWatch` est intégrée dans le contenu Watch de l’application iOS.

## Limites de validation
Le projet a été modifié et les fichiers de configuration/plist vérifiés dans cet environnement, mais aucun Xcode macOS n’est disponible ici pour effectuer une compilation réelle ni tester la communication sur une Apple Watch physique. L’installation du compagnon Watch à partir d’un IPA re-signé par Sideloadly dépend du traitement des bundles watchOS et de la signature par l’outil : elle doit être testée sur l’appareil. Si Sideloadly ne déploie pas le compagnon, il faudra utiliser une chaîne de signature/installation qui prend explicitement en charge les apps watchOS intégrées.
