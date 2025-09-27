# ========================================
# ECR REPOSITORIES
# ========================================

# ECR Repository for Spark applications
resource "aws_ecr_repository" "spark_apps" {
  name                 = "${var.environment}-spark-applications"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = "${var.environment}-spark-apps"
    Environment = var.environment
    Purpose     = "Spark Applications"
  }
}

# ECR Repository for data processing jobs
resource "aws_ecr_repository" "data_jobs" {
  name                 = "${var.environment}-data-processing-jobs"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = "${var.environment}-data-jobs"
    Environment = var.environment
    Purpose     = "Data Processing Jobs"
  }
}

# ECR Repository for custom Glue jobs
resource "aws_ecr_repository" "glue_jobs" {
  name                 = "${var.environment}-glue-jobs"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = "${var.environment}-glue-jobs"
    Environment = var.environment
    Purpose     = "AWS Glue Jobs"
  }
}
