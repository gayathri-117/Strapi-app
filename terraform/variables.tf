variable "aws_region" {
  type    = string
  default = "ap-south-1"
}

variable "aws_account_id" {
  type = string
}

variable "ecr_repository" {
  type = string
}

# Full image: registry/repo:tag (e.g.
# 145065858967.dkr.ecr.ap-south-1.amazonaws.com/strapi-app-gayathri:66cf966)
variable "image_full" {
  type = string
}

variable "key_name" {
  type = string
}

variable "ssh_private_key" {
  type      = string
  sensitive = true
}

variable "vpc_id" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}
