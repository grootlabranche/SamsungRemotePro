# Test checklist — SamsungRemotePro 1.2.5

## Pourquoi les raccourcis pouvaient casser la Live Activity

Chaque raccourci pouvait embarquer des octets d’image dans le `ContentState` ActivityKit. Des PNG de 96 px pour plusieurs apps pouvaient dépasser la limite de taille du payload. La création ou la mise à jour de l’activité pouvait alors être rejetée, donnant l’impression que la Live Activity ne répondait plus.

## Correctifs

- Icônes de transport réduites à des JPEG de 28×28. Les originaux restent enregistrés dans l’application.
- Budget de sécurité de 3 500 octets appliqué au `ContentState` sérialisé ; si nécessaire, les images sont retirées du payload en dernier recours, sans retirer les boutons ni les identifiants des apps.
- Un seul gestionnaire de Live Activity continue à dédupliquer les activités existantes.
- Les logos personnalisés sont séparés des logos fournis par le téléviseur et des logos de secours.
- Les logos du téléviseur peuvent être rafraîchis sans écraser un logo choisi par l’utilisateur.
- Ajout du logo hors ligne Apple Music (dessiné localement) dans le catalogue de secours.

## Tests à faire sur l’iPhone après compilation

1. Activer « Dynamic Island / Live Activity ».
2. Épingler successivement 1, 2, 3, 4 puis 5 apps, dont YouTube, Apple Music, Disney+ et Prime Video.
3. Vérifier après chaque ajout que le bandeau reste visible et que chaque bouton lance la bonne app TV.
4. Balayer la Live Activity puis revenir dans l’application : une seule activité doit être recréée.
5. Désactiver l’option : l’activité doit se terminer ; la télécommande doit continuer à fonctionner.
6. Changer un logo personnalisé, revenir à la Live Activity et vérifier que l’icône est mise à jour.
7. Relancer la détection des apps TV et vérifier que les logos réels sont rafraîchis sans écraser les logos personnalisés.

L’environnement de préparation n’inclut pas Xcode/iOS Simulator. Le ZIP peut être contrôlé statiquement, mais la compilation iOS et le test ActivityKit réel doivent être validés par GitHub Actions et sur l’iPhone.
