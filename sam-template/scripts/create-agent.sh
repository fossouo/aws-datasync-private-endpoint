#!/bin/bash
# Script pour créer un agent DataSync et générer l'URL d'activation

# Vérification des arguments
if [ "$#" -lt 1 ]; then
    echo "Usage: $0 <agent_name> [region]"
    echo "Example: $0 my-datasync-agent eu-west-1"
    exit 1
fi

AGENT_NAME=$1
REGION=${2:-eu-west-1}  # Région par défaut si non spécifiée

echo "Création de l'agent DataSync '$AGENT_NAME' dans la région '$REGION'..."

# Création de l'agent DataSync
ACTIVATION_KEY=$(aws datasync create-agent \
    --agent-name "$AGENT_NAME" \
    --region "$REGION" \
    --query "ActivationKey" \
    --output text)

if [ $? -ne 0 ]; then
    echo "Erreur lors de la création de l'agent DataSync."
    exit 1
fi

echo "Agent DataSync créé avec succès!"
echo "Clé d'activation: $ACTIVATION_KEY"
echo ""
echo "Utilisez cette clé d'activation lors de la configuration de l'agent DataSync sur site."
echo "URL de l'agent sur AWS Console: https://$REGION.console.aws.amazon.com/datasync/home?region=$REGION#/agents"
