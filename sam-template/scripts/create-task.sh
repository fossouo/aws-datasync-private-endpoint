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

# Obtenir l'ARN de la role
echo "Recherche du rôle IAM pour DataSync..."
ROLE_ARN=$(aws iam get-role --role-name "${DESTINATION_BUCKET%-*}-datasync-role" --query "Role.Arn" --output text 2>/dev/null)

if [ $? -ne 0 ]; then
    echo "Rôle IAM spécifique non trouvé, recherche d'un rôle avec le préfixe 'datasync'..."
    ROLE_ARN=$(aws iam list-roles --query "Roles[?starts_with(RoleName, 'datasync')].Arn" --output text | head -1)
    
    if [ -z "$ROLE_ARN" ]; then
        echo "Aucun rôle IAM trouvé pour DataSync. Création d'un nouveau rôle..."
        
        # Créer un nouveau rôle IAM pour DataSync
        POLICY_DOC='{
          "Version": "2012-10-17",
          "Statement": [
            {
              "Effect": "Allow",
              "Principal": {
                "Service": "datasync.amazonaws.com"
              },
              "Action": "sts:AssumeRole"
            }
          ]
        }'
        
        ROLE_ARN=$(aws iam create-role \
            --role-name "datasync-s3-access-role" \
            --assume-role-policy-document "$POLICY_DOC" \
            --query "Role.Arn" \
            --output text)
            
        # Attacher la politique S3FullAccess
        aws iam attach-role-policy \
            --role-name "datasync-s3-access-role" \
            --policy-arn "arn:aws:iam::aws:policy/AmazonS3FullAccess"
    fi
fi

echo "Rôle IAM trouvé/créé: $ROLE_ARN"

# Création de l'emplacement de destination S3
echo "Création de l'emplacement de destination S3..."
DEST_LOCATION_ARN=$(aws datasync create-location-s3 \
    --s3-bucket-arn "arn:aws:s3:::$DESTINATION_BUCKET" \
    --s3-config "{\"BucketAccessRoleArn\":\"$ROLE_ARN\"}" \
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