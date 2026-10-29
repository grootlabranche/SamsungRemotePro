# Correctif watchOS 1.3.0

Le workflow précédent conservait encore `-sdk iphoneos` malgré les notes du correctif précédent. Cette option est supprimée de `xcodebuild archive` : le SDK de chaque cible est déterminé par ses paramètres Xcode (`SDKROOT=iphoneos` pour l’app iOS et `SDKROOT=watchos` pour la cible Watch).

Le workflow vérifie aussi la présence de `SamsungRemotePro.app/Watch/SamsungRemoteProWatch.app` avant de créer l’IPA. Il échoue explicitement si le compagnon Watch n’a pas été embarqué.

Ce correctif n’a pas été compilé dans cet environnement ; il faut confirmer le résultat dans GitHub Actions.
