# SamsungRemotePro 1.2.8 — correction de compilation watchOS

## Cause
Le workflow d'archive ajoutait `-sdk iphoneos` à `xcodebuild archive`. Cette option forçait le SDK iOS globalement, y compris lors de la résolution de la cible `SamsungRemoteProWatch`, ce qui produisait l'erreur `unable to resolve product type ... application.watchapp2 for platform iOS`.

## Correction
Le workflow n'impose plus `-sdk iphoneos`. La destination reste `generic/platform=iOS`; Xcode choisit le SDK correspondant à chaque cible à partir de ses paramètres (`SDKROOT=iphoneos` pour l'app iOS et `SDKROOT=watchos` pour la cible watchOS).

## À faire
Pousser ces changements sur GitHub puis relancer l'action « Construire l’IPA Sideloadly ». Cette correction cible l'erreur du journal fourni, mais le succès de compilation et l'installation sur une vraie Apple Watch restent à vérifier dans le runner et sur les appareils.


## Correctif complémentaire 1.2.9

Le workflow GitHub Actions ne doit pas imposer `-sdk iphoneos` pendant l’archivage du schéma iOS, car cette option est propagée à la cible compagnon watchOS et peut provoquer `unable to resolve product type ... application.watchapp2 for platform iOS`. Le workflow laisse maintenant Xcode choisir le SDK de chaque cible et vérifie explicitement que `SamsungRemoteProWatch.app` est intégré dans l’application et dans l’IPA final.
