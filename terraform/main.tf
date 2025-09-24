provider "aws" {
  region = var.aws_region
}

data "aws_vpc" "selected" {
  id = var.vpc_id
}

data "aws_subnet" "selected" {
  id = var.subnet_id
}

resource "aws_security_group" "strapi_sg" {
  name        = "strapi-sg-"
  description = "Allow SSH and Strapi port"
  vpc_id      = data.aws_vpc.selected.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Strapi"
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

# NOTE: IAM role & instance profile are defined in terraform/iam.tf (do NOT duplicate here)
# The EC2 instance will use the instance profile created in iam.tf:
#   resource "aws_iam_instance_profile" "ec2_profile" { name = "ec2_ecr_full_access_profile" ... }

data "aws_ami" "amzn2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_instance" "app" {
  ami                         = data.aws_ami.amzn2.id
  instance_type               = var.instance_type
  subnet_id                   = data.aws_subnet.selected.id
  vpc_security_group_ids      = [aws_security_group.strapi_sg.id]
  associate_public_ip_address = true
  key_name                    = var.key_name

  # Use the instance profile created in iam.tf
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    amazon-linux-extras install docker -y
    systemctl enable docker
    systemctl start docker
    usermod -a -G docker ec2-user
    yum install -y unzip
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
    cd /tmp && unzip awscliv2.zip && ./aws/install
  EOF

  tags = {
    Name = "strapi-ec2-gayathri"
  }
}

# Deploy container via remote-exec when image_full changes.
resource "null_resource" "deploy_container" {
  triggers = {
    image_full  = var.image_full
    instance_id = aws_instance.app.id
  }

  provisioner "remote-exec" {
    inline = [
      # login to ECR (keeps login using account & region)
      "aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${var.aws_account_id}.dkr.ecr.${var.aws_region}.amazonaws.com",
      # pull and run the exact image provided by CI
      "docker pull ${var.image_full}",
      "docker rm -f strapi || true",
      "docker run -d --restart unless-stopped -p 1337:1337 --name strapi ${var.image_full}"
    ]

    connection {
      type        = "ssh"
      user        = "ec2-user"
      host        = aws_instance.app.public_ip
      private_key = var.ssh_private_key
    }
  }

  depends_on = [
    aws_instance.app
  ]
}
