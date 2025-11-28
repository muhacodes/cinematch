output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = aws_subnet.private[*].id
}

output "ec2_public_ip" {
  description = "EC2 instance public IP"
  value       = aws_eip.app.public_ip
}

output "ec2_instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.app.id
}

output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.postgres.endpoint
  sensitive   = true
}

output "rds_address" {
  description = "RDS instance address"
  value       = aws_db_instance.postgres.address
  sensitive   = true
}

output "redis_info" {
  description = "Redis is running inside EC2 via Docker"
  value       = "redis://localhost:6379 (inside EC2)"
}

output "application_url" {
  description = "Application URL"
  value       = "https://${var.domain_name}"
}

output "temporary_ip_url" {
  description = "Temporary URL using IP (before DNS setup)"
  value       = "http://${aws_eip.app.public_ip}"
}

output "ssh_command" {
  description = "SSH command to connect to EC2 (Ubuntu)"
  value       = "ssh -i /path/to/${var.ec2_key_name}.pem ubuntu@${aws_eip.app.public_ip}"
}

output "ssm_command" {
  description = "Connect via SSM Session Manager (no SSH key needed, more secure)"
  value       = "aws ssm start-session --target ${aws_instance.app.id}"
}

output "setup_ssl_command" {
  description = "Command to setup SSL after DNS is pointed"
  value       = "ssh -i /path/to/${var.ec2_key_name}.pem ubuntu@${aws_eip.app.public_ip} 'sudo /root/setup-ssl.sh'"
}

output "ssm_parameters" {
  description = "SSM Parameter Store paths for secrets"
  value = {
    django_secret = aws_ssm_parameter.django_secret_key.name
    db_password   = aws_ssm_parameter.db_password.name
    db_host       = aws_ssm_parameter.db_host.name
    tmdb_token    = aws_ssm_parameter.tmdb_token.name
    llm_api_key   = aws_ssm_parameter.llm_api_key.name
  }
}

output "dns_instructions" {
  description = "DNS Setup Instructions"
  value       = <<-EOT
    1. Go to your DNS provider (muhacodes.com)
    2. Add A record: ${var.domain_name} -> ${aws_eip.app.public_ip}
    3. Wait 5-10 minutes for DNS propagation
    4. Run: terraform output setup_ssl_command
  EOT
}

