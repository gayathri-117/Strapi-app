output "security_group_id" {
  description = "ID of the created security group"
  value       = aws_security_group.strapi_sg.id
}

output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.app.id
}

output "public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.app.public_ip
}

# Since IAM is precreated, just echo what was provided
output "instance_profile_used" {
  description = "Precreated instance profile name used by the EC2 instance"
  value       = var.instance_profile_name
}
