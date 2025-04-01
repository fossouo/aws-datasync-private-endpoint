provider "aws" {
  region = var.aws_region
}

terraform {
  required_version = ">= 0.14.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

locals {
  tags = {
    Project     = "DataSync-Private-Endpoint"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Génération d'un suffixe aléatoire pour les noms de ressources
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# Security Groups pour l'endpoint DataSync
resource "aws_security_group" "datasync_endpoint" {
  name        = "${var.prefix}-datasync-endpoint-sg"
  description = "Security group for DataSync VPC Endpoint"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.tags,
    {
      Name = "${var.prefix}-datasync-endpoint-sg"
    }
  )
}

# Règles entrantes pour le security group
resource "aws_security_group_rule" "datasync_endpoint_inbound" {
  security_group_id = aws_security_group.datasync_endpoint.id
  type              = "ingress"
  from_port         = 1024
  to_port           = 1064
  protocol          = "tcp"
  cidr_blocks       = var.allowed_cidr_blocks
  description       = "Allow DataSync agent communication"
}

resource "aws_security_group_rule" "datasync_endpoint_https" {
  security_group_id = aws_security_group.datasync_endpoint.id
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = var.allowed_cidr_blocks
  description       = "Allow HTTPS for DataSync API"
}

# Création de l'endpoint VPC pour DataSync
resource "aws_vpc_endpoint" "datasync" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.datasync"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.subnet_ids
  security_group_ids  = [aws_security_group.datasync_endpoint.id]
  private_dns_enabled = true

  tags = merge(
    local.tags,
    {
      Name = "${var.prefix}-datasync-endpoint"
    }
  )
}

# Bucket S3 de destination
resource "aws_s3_bucket" "destination" {
  bucket = var.s3_bucket_name != "" ? var.s3_bucket_name : "${var.prefix}-datasync-destination-${random_string.suffix.result}"

  tags = merge(
    local.tags,
    {
      Name = "${var.prefix}-datasync-destination"
    }
  )

  # Empêcher la suppression accidentelle
  lifecycle {
    prevent_destroy = false # Changez à true en production
  }
}

# Configuration du bucket S3
resource "aws_s3_bucket_ownership_controls" "destination" {
  bucket = aws_s3_bucket.destination.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "destination" {
  depends_on = [aws_s3_bucket_ownership_controls.destination]
  bucket     = aws_s3_bucket.destination.id
  acl        = "private"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "destination" {
  bucket = aws_s3_bucket.destination.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "destination" {
  bucket = aws_s3_bucket.destination.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# IAM Role pour DataSync
resource "aws_iam_role" "datasync" {
  name = "${var.prefix}-datasync-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "datasync.amazonaws.com"
        }
      }
    ]
  })

  tags = local.tags
}

# Politique IAM pour permettre à DataSync d'accéder à S3
resource "aws_iam_policy" "datasync_s3_access" {
  name        = "${var.prefix}-datasync-s3-access"
  description = "Policy for DataSync to access S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetBucketLocation",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads"
        ]
        Effect   = "Allow"
        Resource = aws_s3_bucket.destination.arn
      },
      {
        Action = [
          "s3:AbortMultipartUpload",
          "s3:DeleteObject",
          "s3:GetObject",
          "s3:ListMultipartUploadParts",
          "s3:PutObject",
          "s3:GetObjectTagging",
          "s3:PutObjectTagging"
        ]
        Effect   = "Allow"
        Resource = "${aws_s3_bucket.destination.arn}/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "datasync_s3_access" {
  role       = aws_iam_role.datasync.name
  policy_arn = aws_iam_policy.datasync_s3_access.arn
}

# CloudWatch Logs pour DataSync (optionnel)
resource "aws_cloudwatch_log_group" "datasync" {
  count = var.enable_cloudwatch_logs ? 1 : 0
  
  name              = "/aws/datasync/${var.prefix}"
  retention_in_days = var.cloudwatch_logs_retention
  
  tags = merge(
    local.tags,
    {
      Name = "${var.prefix}-datasync-logs"
    }
  )
}

# Outputs pour être utilisés par d'autres modules ou pour l'information
output "vpc_endpoint_dns" {
  description = "DNS entries for the VPC endpoint"
  value       = aws_vpc_endpoint.datasync.dns_entry
}

output "s3_bucket_name" {
  description = "Name of the destination S3 bucket"
  value       = aws_s3_bucket.destination.bucket
}

output "s3_bucket_arn" {
  description = "ARN of the destination S3 bucket"
  value       = aws_s3_bucket.destination.arn
}

output "security_group_id" {
  description = "ID of the security group for the DataSync endpoint"
  value       = aws_security_group.datasync_endpoint.id
}

output "datasync_role_arn" {
  description = "ARN of the IAM role used by DataSync"
  value       = aws_iam_role.datasync.arn
}

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch Log Group for DataSync (if enabled)"
  value       = var.enable_cloudwatch_logs ? aws_cloudwatch_log_group.datasync[0].name : "N/A - Logs not enabled"
}