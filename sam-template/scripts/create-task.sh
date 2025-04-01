#!/bin/bash
# Script pour créer une tâche DataSync après le déploiement de l'infrastructure

# Vérification des arguments
if [ "$#" -lt 3 ]; then
    echo "Usage: $0 <source_location_arn> <destination_bucket> <task_name> [region]"
    echo "Example: $0 arn:aws:datasync:eu-west-1:123456789012:location/loc-1234567890abcdef0 my-bucket my-datasync-task eu-west-1"
    exit 1
fi

SOURCE_LOCATION_ARN=$1
DESTINATION_BUCKET=$2
TASK_NAME=$3
REGION=${4:-eu-west-1}  # Région par défaut si non spécifiée

echo "Création de la tâche DataSync '$TASK_NAME' dans la région '$REGION'..."

# Création de l'emplacement de destination S3
echo "Création de l'emplacement de destination S3..."
DEST_LOCATION_ARN=$(aws datasync create-location-s3 \
    --s3-bucket-arn "arn:aws:s3:::$DESTINATION_BUCKET" \
    --s3-config '{"BucketAccessRoleArn":"'$(aws iam get-role --role-name datasync-s3-access-role --query "Role.Arn" --output text)'"}' \
    --region "$REGION" \
    --query "LocationArn" \
    --output text)

if [ $? -ne 0 ]; then
    echo "Erreur lors de la création de l'emplacement de destination S3."
    exit 1
fi

echo "Emplacement de destination S3 créé: $DEST_LOCATION_ARN"

# Création de la tâche DataSync
echo "Création de la tâche DataSync..."
TASK_ARN=$(aws datasync create-task \
    --source-location-arn "$SOURCE_LOCATION_ARN" \
    --destination-location-arn "$DEST_LOCATION_ARN" \
    --name "$TASK_NAME" \
    --options '{"VerifyMode":"ONLY_FILES_TRANSFERRED","Atime":"BEST_EFFORT","Mtime":"PRESERVE","Uid":"INT_VALUE","Gid":"INT_VALUE","PreserveDeletedFiles":"PRESERVE","PreserveDevices":"NONE","PosixPermissions":"PRESERVE","TransferMode":"CHANGED"}' \
    --region "$REGION" \
    --query "TaskArn" \
    --output text)

if [ $? -ne 0 ]; then
    echo "Erreur lors de la création de la tâche DataSync."
    exit 1
fi

echo "Tâche DataSync créée avec succès!"
echo "ARN de la tâche: $TASK_ARN"
echo ""
echo "Utilisez cette commande pour démarrer la tâche:"
echo "aws datasync start-task-execution --task-arn $TASK_ARN --region $REGION"
echo ""
echo "URL de la tâche sur AWS Console: https://$REGION.console.aws.amazon.com/datasync/home?region=$REGION#/tasks/details/$TASK_ARN"
