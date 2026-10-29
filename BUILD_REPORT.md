# SamsungRemotePro – intégration réseau inspirée de ha-samsungtv-smart

## Ce qui a été changé
- La référence `ollo69/ha-samsungtv-smart` est une intégration Python pour Home Assistant. Elle configure généralement la TV à partir d’une adresse IP, puis utilise les canaux Samsung locaux; ce n’est pas une bibliothèque Swift de découverte automatique.
- La découverte iOS combine maintenant SSDP et un balayage limité du sous-réseau IPv4 local `/24` sur `en0`, puis valide les candidats via `/api/v2/` sur 8002 et 8001. Les résultats ne sont retenus que si la réponse ressemble à l’API d’un téléviseur Samsung.
- Les requêtes locales HTTPS et le WebSocket sécurisé acceptent le certificat local non reconnu uniquement pour les adresses IPv4 privées/link-local. Aucun certificat n’est accepté de cette manière pour un hôte public.
- La recherche est bornée par lots de 24 hôtes et des délais courts.

## À savoir
- Le balayage `/24` suppose un réseau domestique courant. Il ne couvre pas les VLAN séparés, les sous-réseaux plus grands que `/24`, IPv6, ni les réseaux où l’isolation des clients Wi-Fi est activée.
- iOS peut limiter les recherches multicast selon les droits et le réseau. Le balayage local sert de solution de repli, mais nécessite l’autorisation Réseau local.
- L’acceptation d’un certificat auto-signé est restreinte aux IP privées parce que certains téléviseurs utilisent un certificat local. Cela réduit le risque mais ne fournit pas une authentification cryptographique forte du téléviseur.
- L’intégration Home Assistant de référence demande à l’utilisateur l’IP et recommande d’accepter l’autorisation sur l’écran TV. Elle ne prouve pas que la découverte automatique doit fonctionner sur tous les réseaux.

## Vérifications
La structure du ZIP a été préservée et les modifications ont été vérifiées textuellement. Xcode/iOS SDK n’étant pas disponible dans cet environnement, aucune compilation iOS réelle ni test sur téléviseur n’a été exécuté. La prochaine exécution GitHub Actions reste le test de compilation nécessaire.
