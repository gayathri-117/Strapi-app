# Create an EC2 role that allows EC2 to assume it
resource "aws_iam_role" "ec2_ecr_full_access_role" {
  name = "ec2_ecr_full_access_role_"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action   = "sts:AssumeRole"
    }]
  })
}


# Use an existing IAM role created by admin (or you)
variable "existing_iam_role_name" {
  type    = string
  default = "ec2_ecr_full_access_role" # change if the role has a different name
}

data "aws_iam_role" "ec2_role" {
  name = var.existing_iam_role_name
}

data "aws_iam_instance_profile" "ec2_profile" {
  # if the instance profile name equals the role name, use that
  name = var.existing_iam_role_name
}

