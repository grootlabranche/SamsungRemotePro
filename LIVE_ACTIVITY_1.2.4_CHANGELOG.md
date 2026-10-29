# SamsungRemotePro 1.2.4 — gestion de la Live Activity

## Réglage
Dans Réglages > Dynamic Island, l’interrupteur « Activer la Live Activity » est désactivé par défaut. La télécommande reste pleinement utilisable lorsqu’il est désactivé.

## Cycle de vie
- Activé : création/récupération à l’ouverture de la télécommande et au retour au premier plan.
- Arrière-plan : l’activité demeure affichée. Les actualisations de connexion/configuration ne la recréent pas si elle a été balayée.
- Retour dans l’application après un balayage : l’activité est recréée si nécessaire.
- Désactivation du réglage : toutes les activités SamsungRemotePro sont terminées avec suppression immédiate.
- Anti-doublons : la logique réutilise au plus une activité trouvée et termine les éventuels doublons avant de poursuivre. Les opérations sont mises en file pour éviter les courses entre création et suppression.

## Limite iOS importante
iOS ne garantit pas d’avertir l’application au moment exact où l’utilisateur la force à quitter depuis le sélecteur d’apps. Il n’est donc pas possible de garantir que la Live Activity disparaisse immédiatement à cet instant sans la terminer aussi lorsque l’application passe normalement en arrière-plan, ce qui serait contraire au comportement demandé.

## Vérification
Les fichiers Swift modifiés ont passé l’analyse syntaxique Swift ; le projet `.pbxproj` et les plist sont valides, et l’archive est vérifiée après création. Ce conteneur ne dispose pas de Xcode / `xcodebuild`, donc le build iOS réel reste à confirmer par GitHub Actions.
