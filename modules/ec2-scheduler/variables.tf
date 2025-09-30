variable "account_id" {
  description = "AWS account ID where EC2 instances will be started/stopped"
  type        = string
}

variable "region" {
  description = "AWS region where EC2 instances are located"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, stg, prod) to filter EC2 instances by Environment tag"
  type        = string
}

variable "resource_name_prefix" {
  description = "Prefix for naming AWS resources created by this module"
  type        = string
}

variable "start_schedule_expression" {
  description = "Cron expression for when to start EC2 instances (e.g., 'cron(0 22 ? * SUN-THU *)')"
  type        = string
}

variable "stop_schedule_expression" {
  description = "Cron expression for when to stop EC2 instances (e.g., 'cron(0 9 ? * MON-FRI *)')"
  type        = string
}

variable "schedule_expression_timezone" {
  description = "Timezone for schedule expressions (e.g., 'Asia/Tokyo')"
  type        = string
}
