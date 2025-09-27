# ========================================
# ECS CLUSTER WITH FARGATE SPOT
# ========================================

# ECS Cluster
resource "aws_ecs_cluster" "data_processing" {
  name = "${var.environment}-data-processing-cluster"

  tags = {
    Name        = "${var.environment}-data-processing-cluster"
    Environment = var.environment
  }
}

# ECS Cluster Capacity Providers
resource "aws_ecs_cluster_capacity_providers" "data_processing" {
  cluster_name = aws_ecs_cluster.data_processing.name

  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight           = 1
  }

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight           = 0
  }
}

# ECS Task Definition for Data Processing
resource "aws_ecs_task_definition" "data_processing_task" {
  family                   = "${var.environment}-data-processing-task"
  network_mode            = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                     = 1024
  memory                  = 2048
  execution_role_arn      = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn          = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name  = "data-processor"
      image = "${aws_ecr_repository.data_jobs.repository_url}:latest"
      
      environment = [
        {
          name  = "S3_BUCKET"
          value = aws_s3_bucket.data_lake.bucket
        },
        {
          name  = "ENVIRONMENT"
          value = var.environment
        }
      ]
      
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs_logs.name
          "awslogs-region"        = var.AWS_DEFAULT_REGION
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = {
    Name        = "${var.environment}-data-processing-task"
    Environment = var.environment
  }
}

# ECS Task Definition for Spark Jobs
resource "aws_ecs_task_definition" "spark_job_task" {
  family                   = "${var.environment}-spark-job-task"
  network_mode            = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                     = 2048
  memory                  = 4096
  execution_role_arn      = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn          = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name  = "spark-job"
      image = "${aws_ecr_repository.spark_apps.repository_url}:latest"
      
      environment = [
        {
          name  = "S3_BUCKET"
          value = aws_s3_bucket.data_lake.bucket
        },
        {
          name  = "ENVIRONMENT"
          value = var.environment
        }
      ]
      
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs_logs.name
          "awslogs-region"        = var.AWS_DEFAULT_REGION
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = {
    Name        = "${var.environment}-spark-job-task"
    Environment = var.environment
  }
}

# ECS Service for Data Processing
resource "aws_ecs_service" "data_processing_service" {
  name            = "${var.environment}-data-processing-service"
  cluster         = aws_ecs_cluster.data_processing.id
  task_definition = aws_ecs_task_definition.data_processing_task.arn
  desired_count   = 0  # Start with 0, scale up as needed

  capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight           = 1
  }

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.app.id]
    assign_public_ip = false
  }

  tags = {
    Name        = "${var.environment}-data-processing-service"
    Environment = var.environment
  }
}

# CloudWatch Log Group for ECS
resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = "/ecs/${var.environment}-data-processing"
  retention_in_days = 14

  tags = {
    Name        = "${var.environment}-ecs-logs"
    Environment = var.environment
  }
}

# Application Load Balancer for ECS (optional)
resource "aws_lb" "data_processing_alb" {
  count = 0  # Set to 1 if you want an ALB

  name               = "${var.environment}-data-processing-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web.id]
  subnets            = aws_subnet.public[*].id

  tags = {
    Name        = "${var.environment}-data-processing-alb"
    Environment = var.environment
  }
}
