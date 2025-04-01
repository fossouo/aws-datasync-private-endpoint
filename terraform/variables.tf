variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "eu-west-1"
}

variable "environment" {
  description = "Environment name (e.g., dev, test, prod)"
  type        = string
  default     = "dev"
}

variable "prefix" {
  description = "Prefix to use for resource naming"
  type        = string
  default     = "datasync"
}

variable "vpc_id" {
  description = "ID of the VPC where to deploy the DataSync endpoint"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs where to deploy the DataSync endpoint"
  type        = list(string)
}

variable "allowed_cidr_blocks" {
  description = "List of CIDR blocks allowed to connect to the DataSync endpoint"
  type        = list(string)
  default     = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
}

variable "s3_bucket_name" {
  description = "Name of the S3 bucket to create for DataSync destination (leave empty for auto-generated name)"
  type        = string
  default     = ""
}

variable "create_datasync_agent" {
  description = "Whether to create a DataSync agent (set to false if you will deploy it manually)"
  type        = bool
  default     = false
}

variable "datasync_agent_name" {
  description = "Name of the DataSync agent (if create_datasync_agent is true)"
  type        = string
  default     = "on-premises-agent"
}

variable "create_datasync_locations" {
  description = "Whether to create DataSync locations (source and destination)"
  type        = bool
  default     = false
}

variable "create_datasync_task" {
  description = "Whether to create a DataSync task"
  type        = bool
  default     = false
}

variable "datasync_source_path" {
  description = "Source path for DataSync (if create_datasync_locations is true)"
  type        = string
  default     = "/data"
}

variable "datasync_schedule" {
  description = "Cron expression for DataSync task schedule (if create_datasync_task is true)"
  type        = string
  default     = "cron(0 0 ? * SUN *)"  # Weekly on Sunday at midnight
}

variable "datasync_task_options" {
  description = "Options for the DataSync task"
  type        = map(string)
  default     = {
    VerifyMode                 = "ONLY_FILES_TRANSFERRED"
    Atime                      = "BEST_EFFORT"
    Mtime                      = "PRESERVE"
    Uid                        = "INT_VALUE"
    Gid                        = "INT_VALUE"
    PreserveDeletedFiles       = "PRESERVE"
    PreserveDevices            = "NONE"
    PosixPermissions           = "PRESERVE"
    TransferMode               = "CHANGED"
    OverwriteMode              = "NEVER"
    TaskQueueing               = "ENABLED"
    LogLevel                   = "TRANSFER"
  }
}

variable "enable_cloudwatch_logs" {
  description = "Whether to enable CloudWatch Logs for DataSync"
  type        = bool
  default     = true
}

variable "cloudwatch_logs_retention" {
  description = "Number of days to retain DataSync logs"
  type        = number
  default     = 30
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}