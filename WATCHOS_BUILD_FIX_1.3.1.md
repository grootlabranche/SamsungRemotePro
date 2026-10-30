# SamsungRemotePro 1.3.1 — correctif architecture watchOS

- Correction de la configuration d'architecture de la cible SamsungRemoteProWatch : `ARCHS = arm64_32` en Debug et Release.
- Cela évite que la cible de montre demande un binaire universel `arm64 arm64_32` puis produise le même exécutable une seconde fois, ce qui correspond à l'erreur `Multiple commands produce ... SamsungRemoteProWatch`.
- Le workflow conserve la commande d'archivage sans `-sdk iphoneos`.

À vérifier : compilation réelle par GitHub Actions. Ce ZIP n'a pas été compilé dans Xcode sur cet environnement.
