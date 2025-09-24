output "public_ip" {
  value = aws_instance.app.public_ip
}
output "ssh_command" {
  value = "ssh -i <path-to-pem> ec2-user@${aws_instance.app.public_ip}"
}
