terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# -----------------------------
# Data lookups for VPC/subnet/AMI
# -----------------------------
data "aws_vpc" "selected" {
  id = var.vpc_id
}

data "aws_subnet" "selected" {
  id = var.subnet_id
}

data "aws_ami" "amzn2" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# stable unique suffix to avoid collisions
resource "random_pet" "suffix" {
  length = 2
}

# -----------------------------
# Security group (unique per VPC thanks to suffix)
# -----------------------------
resource "aws_security_group" "strapi_sg" {
  # Updated SG name
  name        = "strapi_sg_gayathri-${random_pet.suffix.id}"
  description = "Allow SSH and Strapi port"
  vpc_id      = data.aws_vpc.selected.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ssh_allow_cidrs
  }

  ingress {
    description = "Strapi"
    from_port   = 1337
    to_port     = 1337
    protocol    = "tcp"
    cidr_blocks = var.app_allow_cidrs
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "strapi_sg_gayathri-${random_pet.suffix.id}"
    env  = var.environment
  }
}

# -----------------------------
# EC2 Instance
# -----------------------------
resource "aws_instance" "app" {
  ami                         = data.aws_ami.amzn2.id
  instance_type               = var.instance_type
  subnet_id                   = data.aws_subnet.selected.id
  vpc_security_group_ids      = [aws_security_group.strapi_sg.id]
  associate_public_ip_address = true
  key_name                    = var.key_name

  # Use the PRECREATED instance profile name (NOT the role name)
  iam_instance_profile        = var.instance_profile_name

  user_data = <<-EOF
    #!/bin/bash
    set -euo pipefail
    yum update -y
    amazon-linux-extras install docker -y
    systemctl enable docker
    systemctl start docker
    usermod -a -G docker ec2-user

    yum install -y unzip
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
    cd /tmp && unzip -q awscliv2.zip && ./aws/install

    # optional: login will succeed only if the instance profile has ECR permissions
    aws --version
  EOF

  tags = {
    Name = "strapi_app_gayathri-${random_pet.suffix.id}"  # Updated EC2 instance Name
    env  = var.environment
  }
}

# -----------------------------
# Deploy container via remote-exec when image_full changes.
# -----------------------------
resource "null_resource" "deploy_container" {
  triggers = {
    image_full  = var.image_full
    instance_id = aws_instance.app.id
  }

  provisioner "remote-exec" {
    inline = [
      # Login to ECR (requires instance profile to allow ecr:GetAuthorizationToken)
      "aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${var.aws_account_id}.dkr.ecr.${var.aws_region}.amazonaws.com",

      # Pull & run container
      "docker pull ${var.image_full}",
      "docker rm -f strapi || true",
      "docker run -d --restart unless-stopped -p 1337:1337 --name strapi ${var.image_full}"
    ]

    connection {
      type        = "ssh"
      user        = "ec2-user"
      host        = aws_instance.app.public_ip
      private_key = file(var.ssh_private_key)
      timeout     = "2m"
    }
  }

  depends_on = [
    aws_instance.app
  ]
}

}

