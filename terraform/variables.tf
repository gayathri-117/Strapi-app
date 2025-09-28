variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "vpc_id" {
  description = "VPC id where resources will be created"
  type        = string
}

variable "subnet_id" {
  description = "Subnet id for the EC2 instance"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type (flavor), e.g. t3.small"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Name of the EC2 KeyPair (must exist in the region)"
  type        = string
}

variable "ssh_private_key" {
  description = "Path to the SSH private key file (PEM). For provisioner connection."
  type        = string
  sensitive   = true
}

# Automatically fetch AWS account ID so you don't have to hardcode it.
data "aws_caller_identity" "current" {}

variable "aws_account_id" {
  description = "AWS account id used to compose ECR registry URL"
  type        = string
  default     = "" # Will be overridden dynamically below
}

locals {
  resolved_aws_account_id = var.aws_account_id != "" ? var.aws_account_id : data.aws_caller_identity.current.account_id
}

variable "image_full" {
  description = "Full image registry path with tag (e.g. 123456789012.dkr.ecr.ap-south-1.amazonaws.com/myrepo:tag)"
  type        = string
}

variable "environment" {
  description = "Environment name (dev/test/prod). Used for tags and naming."
  type        = string
  default     = "dev"
}

variable "app_allow_cidrs" {
  description = "Allowed CIDRs for accessing Strapi app (default: open to all)"
  type        = list(string)
  default     = ["0.0.0.0/0"] # 🔴 Restrict in production
}

variable "ssh_allow_cidrs" {
  description = "Allowed CIDRs for SSH access (default: open to all)"
  type        = list(string)
  default     = ["0.0.0.0/0"] # 🔴 Restrict in production
}

variable "instance_profile_name" {
  description = "Precreated EC2 instance profile name (attach role with ECR+SSM permissions)"
  type        = string
}

