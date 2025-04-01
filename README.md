# AWS DataSync avec Endpoint Privé VPC

Ce projet fournit une infrastructure-as-code pour déployer AWS DataSync avec un endpoint privé VPC, permettant de transférer des données de manière sécurisée depuis un environnement sur site vers AWS S3.

## Architecture

L'architecture implémente les composants suivants :

- Agent DataSync sur site connecté via Direct Connect ou VPN
- Endpoint VPC DataSync privé dans votre VPC AWS
- Configuration de Security Groups appropriés
- Définition des tâches DataSync et des emplacements source/destination
- Bucket S3 de destination pour les données

## Structure du projet

Le projet est divisé en deux parties principales :

1. **Terraform** : Code pour le développement et tests internes
   - Infrastructure complète pour test et validation

2. **SAM** : Template pour distribution aux clients
   - Permet aux clients de déployer l'agent DataSync avec leurs propres VPC/sous-réseaux

## Prérequis

- AWS CLI configuré avec les permissions appropriées
- Terraform (v1.0+)
- AWS SAM CLI
- VPC et sous-réseaux existants sur AWS