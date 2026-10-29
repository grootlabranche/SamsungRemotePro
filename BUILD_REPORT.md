# SamsungRemotePro – rapport de correction et d’interface (29 octobre 2026)

## Base réseau conservée
- Correction de l’erreur Swift signalée par GitHub Actions : suppression du `guard let` appliqué à `compactMap`, qui renvoyait déjà un tableau non optionnel.
- Découverte réseau : Bonjour/mDNS et scan de repli exécutés en parallèle. Le scan utilise l’adresse IPv4 et le masque réel de l’interface Wi-Fi `en0`, limite les lots et vérifie les ports 8002/8001 en privilégiant le canal sécurisé.
- Correction du transport de commandes : le JSON Samsung est envoyé en trame WebSocket texte (`.string`), et non binaire (`.data`).
- Les diagnostics, la connexion manuelle et la gestion de l’autorisation existante sont conservés.

## Modifications de l’édition 1.1.2
- Ajout de l’icône d’app à partir de l’image fournie, intégrée à `Resources/Assets.xcassets/AppIcon.appiconset`.
- Réorganisation de la télécommande principale selon la référence : bandeau TV/réseau/sélection/réglages/alimentation, pavé tactile, rangée Retour/Accueil/Applications, commande de volume verticale avec sourdine et rangée multimédia Retour rapide/Lecture-pause/Avance rapide.
- Retrait des rangées de volume et de lecture/pause redondantes. La saisie de texte se trouve dans la feuille Applications.
- Démarrage automatique de la Live Activity à l’établissement de la connexion. Le choix de l’action rapide est réglable dans Réglages.
- Jusqu’à cinq apps favorites dans la Dynamic Island développée. Les logos sont recherchés dans les informations renvoyées par le téléviseur quand une URL d’icône est fournie, avec une petite galerie hors ligne pour les apps courantes et un import Photo optionnel.
- Ajout d’une page Réglages > Logos personnalisés des apps TV : choix d’une image, recadrage carré par glisser-déposer/zoom, export PNG 256×256 aux coins arrondis et sauvegarde par identifiant d’app.
- Les commandes de la Live Activity utilisent désormais `RemoteActivityActionIntent` conforme à `LiveActivityIntent`; le système exécute l’action dans le processus de l’app sans afficher son interface. Toucher le fond de l’activité reste un raccourci d’ouverture normal. Les logos favoris sont inclus en version compacte dans l’état ActivityKit pour l’affichage WidgetKit.
- Pas d’App Group ajouté : cette édition reste compatible avec le parcours Sideloadly/gratuit. Les logos personnalisés sont persistés dans le conteneur de l’app et recopiés dans l’état de la Live Activity plutôt que dans un conteneur partagé de fichiers.
- Ajout d’une option facultative d’observation de `AVAudioSession.outputVolume` pour envoyer Volume +/− à la TV quand l’app est au premier plan. iOS ne fournit pas de callback public dédié aux pressions physiques : le volume système de l’iPhone peut également changer.
- Mise à niveau de la version app à 1.1.2.

## Recherche documentaire
- Les Live Activities peuvent inclure des interactions et s’étendre au toucher-maintien ; voir la [documentation Apple ActivityKit](https://developer.apple.com/documentation/activitykit/displaying-live-data-with-live-activities) et [WidgetKit interactions](https://developer.apple.com/documentation/widgetkit/adding-interactivity-to-widgets-and-live-activities).
- `AVAudioSession.outputVolume` est observable via KVO mais en lecture seule ; Apple recommande `MPVolumeView` pour régler le volume système. Voir [Apple AVAudioSession.outputVolume](https://developer.apple.com/documentation/avfaudio/avaudiosession/outputvolume) et [MPVolumeView](https://developer.apple.com/documentation/mediaplayer/mpvolumeview).
- Le SDK officiel Samsung Smart View couvre les apps mobiles et réceptrices compatibles ; le canal local de télécommande WebSocket reste recoupé avec les implémentations open source mentionnées dans `README.md`.

## Vérifications locales réalisées
- Tous les fichiers Swift passent `swiftc -frontend -parse` dans cet environnement après les derniers changements.
- Les modèles non dépendants d’Apple ont été vérifiés par `swiftc -typecheck` avec une définition de remplacement pour le type ActivityKit.
- Le fichier Xcode `.pbxproj`, les deux fichiers plist et le JSON de l’asset app icon ont été validés syntaxiquement. L’icône source est une image PNG RGB de 1024×1024.

## Limites / vérification nécessaire
- Ce conteneur n’a pas le SDK iOS/Xcode Apple ; aucune compilation d’archive iOS complète, aucun test d’extension WidgetKit sur iPhone et aucun essai sur la TV physique n’ont été exécutés ici. GitHub Actions doit confirmer la compilation finale.
- La compilation iOS complète et le fonctionnement du nouvel intent doivent être confirmés par GitHub Actions puis sur iPhone. iOS peut demander l’authentification pour une action depuis l’écran verrouillé; le toucher du fond de la Live Activity ouvre toujours l’app.
- Le raccourci `Lecture / pause` envoie la touche Samsung `KEY_PLAY`. Certaines applications l’interprètent comme une bascule, d’autres comme une simple commande Lecture. Les touches multimédia dépendent de l’app active sur la TV.
- La détection des changements de volume iPhone est une approximation, seulement au premier plan. Le volume du téléphone peut bouger en parallèle, et les changements au minimum/maximum ne sont pas détectés si la valeur ne change pas.
- Une découverte qui marche dépend encore du réseau local, du réglage Réseau local iOS, du firmware de la TV et de l’acceptation du dialogue d’appairage.

## Modifications de l’édition 1.2.0 (archive source)
- La Live Activity existante est retrouvée et réutilisée au retour dans l’app ; l’app tente une reconnexion au téléviseur sélectionné si « Reconnexion automatique » est activé.
- Les changements de favoris, logos et couleur des boutons déclenchent une actualisation de l’état ActivityKit. Les logos transmis au widget sont réduits à 96×96 pixels pour limiter leur poids.
- La commande Lecture/Pause est désormais une bascule d’interface : l’icône passe de Lecture à Pause, puis inversement après chaque commande envoyée. Cet état est optimiste, car le téléviseur ne confirme pas systématiquement les commandes média.
- Réglage de couleur ajouté dans Réglages > Personnalisation. La couleur est utilisée pour les boutons ronds, le rocker de volume et les raccourcis de la Live Activity.
- Ajout de l’action App Intent « Envoyer une commande à la TV Samsung » avec un sélecteur couvrant toutes les commandes usuelles disponibles (directions, valider, retour, accueil, menu, alimentation, volume, sourdine, lecture/pause, avance/retour rapides et chaînes). Dix actions fréquentes disposent aussi de phrases Siri préconfigurées.
- L’état Live Activity décode aussi les anciennes données sans les champs de couleur et d’état de lecture.
- Version du projet mise à 1.2.0.

## Vérification de l’édition 1.2.0
- Tous les fichiers Swift du projet passent le contrôle syntaxique `swiftc -frontend -parse`.
- Les fichiers Xcode `.pbxproj` et les deux fichiers plist passent `plutil -lint`.
- Aucune compilation Xcode/iOS complète n’a été possible ici : ces contrôles valident la syntaxe et la structure, pas le build final ni le comportement sur iPhone/TV.

## Limites de l’édition 1.2.0
- iOS ne fournit pas de notification fiable au moment précis où l’utilisateur force la fermeture de l’app. Une Live Activity peut donc rester affichée après un balayage forcé ; elle est réutilisée et rafraîchie à la prochaine ouverture.
- Les logos sont sauvegardés dans le conteneur local de l’app. Une désinstallation complète peut les effacer ; ils ne peuvent pas être restaurés automatiquement après suppression sans sauvegarde/importation ou synchronisation cloud.
- L’état Lecture/Pause reflète la dernière commande envoyée, pas une confirmation de lecture réelle provenant de la télévision.


## Modifications de l’édition 1.2.4 – Live Activity configurable
- Ajout de Réglages > Dynamic Island > « Activer la Live Activity », désactivé par défaut. Les anciennes préférences sont décodées avec cette option désactivée si la clé n’existe pas encore.
- Lorsque l’option est activée, l’activité est créée à l’ouverture de l’écran télécommande et au retour au premier plan. Une activité déjà existante est actualisée/réutilisée ; les doublons détectés sont terminés immédiatement.
- Quand l’option est désactivée, toutes les activités de ce type sont terminées avec la politique de suppression immédiate. La télécommande continue de fonctionner.
- Les changements de connexion et de personnalisation actualisent uniquement une activité existante. Ils ne recréent donc pas spontanément une activité que l’utilisateur a balayée alors que l’app reste en arrière-plan.
- Les opérations ActivityKit sont mises en file pour ordonner création, actualisation et fin. L’intent multimédia recherche le nom du téléviseur dans l’état affiché, ce qui reste valide si l’activité unique est réutilisée après un changement de TV.
- Ajout de tests de modèle pour le défaut désactivé et la compatibilité avec les anciennes préférences. Version de l’app et de l’extension : 1.2.4 (build 6).

## Vérifications de l’édition 1.2.4
- Les fichiers Swift modifiés passent `swiftc -frontend -parse`.
- Le projet Xcode `.pbxproj` et les fichiers plist passent `plutil -lint`. Le contenu de l’archive ZIP est aussi contrôlé par `unzip -t`.
- Limite d’environnement : ce conteneur ne possède pas `xcodebuild` ni le SDK iOS. La compilation Apple réelle et les tests ActivityKit sur iPhone devront être confirmés par GitHub Actions puis sur appareil.
- Limite iOS inchangée : iOS ne garantit pas un callback lorsque l’utilisateur force la fermeture de l’app. La Live Activity peut rester visible jusqu’à ce qu’iOS ou l’utilisateur la retire ; l’app ne la recrée pas spontanément pendant qu’elle reste fermée. À la prochaine ouverture, si l’option est activée, l’app réutilise l’activité existante ou en crée une seule si elle a été supprimée.


## Modifications de l’édition 1.2.5 — correctifs du lanceur

- Réduction et contrôle du poids du `ContentState` ActivityKit pour éviter que plusieurs logos épinglés fassent dépasser le budget de payload.
- Conservation des cinq boutons de lancement même si certaines images doivent être omises pour rester sous la limite de sécurité.
- Séparation des logos choisis par l’utilisateur, des logos fournis par le téléviseur et des images de secours.
- Rafraîchissement des logos TV sans écraser les logos personnalisés.
- Ajout du logo de secours Apple Music.
- Réglage renommé « Dynamic Island / Live Activity ». Version 1.2.5 (build 7).

Les fichiers Swift ont passé l’analyse syntaxique et les plist ont été validés. Une compilation Xcode complète et des essais sur iPhone restent nécessaires.
