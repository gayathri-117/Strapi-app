provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  type    = string
  default = "ap-south-1"
}

variable "key_pair_name" {
  description = "Name of the existing SSH key pair on AWS"
  type        = string
  default     = "strapi-gayathri"
}

variable "docker_image" {
  description = "Docker image to run on EC2"
  type        = string
  default     = "gayathri0315/strapi:latest"
}

variable "vpc_id" {
  description = "VPC ID for the Strapi infrastructure"
  type        = string
  default     = "vpc-06813802d8c49e913"
}

variable "subnet_id" {
  description = "Subnet ID to use for Strapi EC2"
  type        = string
  default     = "subnet-058e4e2fa1ab85f0f"
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]  # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

resource "aws_security_group" "strapi_sg" {
  name        = "strapi_sg"
  description = "Allow SSH and Strapi ports"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Strapi HTTP"
    from_port   = 1337
    to_port     = 1337
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "strapi_instance_gayathri" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  key_name                   = var.key_pair_name
  vpc_security_group_ids     = [aws_security_group.strapi_sg.id]
  associate_public_ip_address = true
  subnet_id                  = var.subnet_id
  # ... rest of your config
}


  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get upgrade -y
              apt-get install -y docker.io
              systemctl start docker
              systemctl enable docker
              usermod -aG docker ubuntu
              docker pull ${var.docker_image}
              docker stop strapi || true
              docker rm strapi || true
              docker run -d -p 1337:1337 --name strapi ${var.docker_image}
              EOF

  tags = {
    Name = "StrapiServer"
  }
}

output "ec2_public_ip" {
  description = "Public IP of the Strapi EC2 instance"
  value       = aws_instance.strapi_instance.public_ip
}
