# SamsungRemotePro 1.2.6 — correctifs lanceur et Live Activity

- Réduction des icônes intégrées à l’état ActivityKit (vignettes JPEG 28×28).
- Contrôle du JSON ContentState avec budget conservateur de 3 500 octets ; si nécessaire, les images sont omises sans supprimer les boutons ni les identifiants des applications épinglées.
- Les logos personnalisés, les icônes récupérées depuis le téléviseur et les logos de secours sont désormais séparés. Un logo de secours ne bloque donc plus une récupération ultérieure du véritable logo de la TV.
- Ajout d’un logo Apple Music hors ligne généré localement et de la détection de son nom.
- Libellé du réglage : « Dynamic Island / Live Activity ».
- Version 1.2.6, build 7.

## Vérifications

Cette archive a été vérifiée par analyse syntaxique Swift, validation du projet/plist et tests statiques du budget ActivityKit. Une compilation iOS complète et un test sur iPhone doivent encore être réalisés dans Xcode/GitHub Actions.
