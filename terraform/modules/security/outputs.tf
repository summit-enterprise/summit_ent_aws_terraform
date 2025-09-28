output "security_group_ids" {
  description = "IDs of the security groups"
  value = {
    web         = aws_security_group.web.id
    app         = aws_security_group.app.id
    database    = aws_security_group.database.id
    kubernetes  = aws_security_group.kubernetes.id
    monitoring  = aws_security_group.monitoring.id
  }
}

output "iam_role_arns" {
  description = "ARNs of the IAM roles"
  value = {
    ecs_task_execution_role = aws_iam_role.ecs_task_execution_role.arn
    ecs_task_role          = aws_iam_role.ecs_task_role.arn
    glue_service_role      = aws_iam_role.glue_service_role.arn
  }
}
