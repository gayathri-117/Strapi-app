output "instance_id" {
  description = "EC2 instance id"
  value       = aws_instance.app.id
}

output "instance_public_ip" {
  description = "EC2 public IP"
  value       = aws_instance.app.public_ip
}

output "security_group_id" {
  description = "Created Security Group ID"
  value       = aws_security_group.strapi_sg.id
}

output "iam_role_name" {
  description = "IAM role name for EC2"
  value       = aws_iam_role.ec2_role.name
}

output "image_full" {
  description = "Image deployed (input)"
  value       = var.image_full
}
