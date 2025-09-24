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

# Attach AWS-managed policies only (no custom policies)
resource "aws_iam_role_policy_attachment" "ecr_full" {
  role       = aws_iam_role.ec2_ecr_full_access_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
}

resource "aws_iam_role_policy_attachment" "ec2_full" {
  role       = aws_iam_role.ec2_ecr_full_access_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ec2_ecr_full_access_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Instance profile so EC2 instances can assume the role
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2_ecr_full_access_profile"
  role = aws_iam_role.ec2_ecr_full_access_role.name
}
