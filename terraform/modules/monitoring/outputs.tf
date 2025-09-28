output "monitoring_instance_id" {
  description = "ID of the monitoring EC2 instance"
  value       = aws_instance.monitoring[0].id
}

output "monitoring_public_ip" {
  description = "Public IP of the monitoring instance"
  value       = aws_instance.monitoring[0].public_ip
}

output "monitoring_public_dns" {
  description = "Public DNS of the monitoring instance"
  value       = aws_instance.monitoring[0].public_dns
}

output "monitoring_ssh_command" {
  description = "SSH command to connect to monitoring instance"
  value       = "ssh -i ~/.ssh/oci_ed25519 ec2-user@${aws_instance.monitoring[0].public_ip}"
}

output "monitoring_urls" {
  description = "URLs for monitoring services"
  value = {
    prometheus          = "http://${aws_instance.monitoring[0].public_ip}:9090"
    grafana             = "http://${aws_instance.monitoring[0].public_ip}:3000 (admin/admin123)"
    kibana              = "http://${aws_instance.monitoring[0].public_ip}:5601"
    jaeger              = "http://${aws_instance.monitoring[0].public_ip}:16686"
    pushgateway         = "http://${aws_instance.monitoring[0].public_ip}:9091"
    cloudwatch_exporter = "http://${aws_instance.monitoring[0].public_ip}:9106"
  }
}
