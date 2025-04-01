# Module Terraform pour AWS DataSync avec Endpoint Privé

Ce dossier contient le code Terraform pour déployer et tester l'infrastructure AWS DataSync avec endpoint privé VPC.

## Composants

- Configuration VPC endpoint pour DataSync
- Security Groups nécessaires
- Bucket S3 et politiques
- Tâche DataSync et emplacements

## Utilisation

1. Configurez vos variables dans `terraform.tfvars` ou en utilisant les variables d'environnement
2. Exécutez `terraform init` pour initialiser les modules
3. Exécutez `terraform plan` pour visualiser les changements
4. Exécutez `terraform apply` pour déployer l'infrastructure

## Variables

Voir le fichier `variables.tf` pour la liste complète des variables configurables.