output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.data_processing.name
}

output "ecs_cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = aws_ecs_cluster.data_processing.arn
}

output "ecs_task_definition_arns" {
  description = "ARNs of the ECS task definitions"
  value = {
    data_processing = aws_ecs_task_definition.data_processing_task.arn
    spark_job       = aws_ecs_task_definition.spark_job_task.arn
  }
}

output "kubernetes_instance_id" {
  description = "ID of the Kubernetes EC2 instance"
  value       = aws_instance.kubernetes[0].id
}

output "kubernetes_public_ip" {
  description = "Public IP of the Kubernetes instance"
  value       = aws_instance.kubernetes[0].public_ip
}

output "kubernetes_public_dns" {
  description = "Public DNS of the Kubernetes instance"
  value       = aws_instance.kubernetes[0].public_dns
}

output "kubernetes_ssh_command" {
  description = "SSH command to connect to Kubernetes instance"
  value       = "ssh -i ~/.ssh/oci_ed25519 ec2-user@${aws_instance.kubernetes[0].public_ip}"
}

output "kubernetes_minikube_dashboard" {
  description = "Minikube dashboard URL"
  value       = "http://${aws_instance.kubernetes[0].public_ip}:30080"
}

output "kubernetes_argocd_url" {
  description = "ArgoCD URL"
  value       = "http://${aws_instance.kubernetes[0].public_ip}:30080"
}

output "kubernetes_argocd_ssh_access" {
  description = "SSH access instructions for ArgoCD"
  value       = "SSH to the instance and run: kubectl port-forward svc/argocd-server -n argocd 8080:443"
}
