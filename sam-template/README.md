# Template SAM pour AWS DataSync

Ce dossier contient le template SAM qui permet aux clients de déployer facilement un agent DataSync avec un endpoint privé dans leur propre VPC.

## Paramètres

Le template accepte les paramètres suivants :
- `VpcId` : ID du VPC où déployer l'endpoint DataSync
- `SubnetIds` : IDs des sous-réseaux pour l'endpoint DataSync
- `S3BucketName` : Nom du bucket S3 de destination
- `SecurityGroupIds` : (Optionnel) IDs des security groups existants
- `TagPrefix` : Préfixe pour les tags des ressources créées

## Déploiement

```bash
sam deploy --guided
```

Lors du déploiement guidé, vous serez invité à fournir les valeurs des paramètres ci-dessus.

## Ressources créées

Le template SAM crée les ressources suivantes :
- Security Groups pour l'endpoint DataSync (si non fournis)
- VPC Endpoint pour DataSync
- IAM Roles pour l'accès à S3
- Configuration des tâches DataSync (si activée via paramètre)

## Surveillance

Une fois déployé, vous pouvez surveiller les transferts DataSync via :
- AWS Console DataSync
- CloudWatch Logs (si activé)
- CloudWatch Metrics