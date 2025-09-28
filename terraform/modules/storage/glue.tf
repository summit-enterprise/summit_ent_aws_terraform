# ========================================
# AWS GLUE
# ========================================

# Glue Data Catalog Database
resource "aws_glue_catalog_database" "data_lake_catalog" {
  name = "${var.environment}_data_lake_catalog"

  description = "Data catalog for ${var.environment} data lake"

  tags = {
    Name        = "${var.environment}-data-lake-catalog"
    Environment = var.environment
  }
}

# Glue Crawler for Raw Data
resource "aws_glue_crawler" "raw_data_crawler" {
  database_name = aws_glue_catalog_database.data_lake_catalog.name
  name          = "${var.environment}-raw-data-crawler"
  role          = aws_iam_role.glue_service_role.arn

  s3_target {
    path = "s3://${aws_s3_bucket.data_lake.bucket}/raw/"
  }

  # schedule = "cron(0 2 * * ? *)"  # Run daily at 2 AM - DISABLED to avoid charges

  tags = {
    Name        = "${var.environment}-raw-data-crawler"
    Environment = var.environment
  }
}

# Glue Crawler for Processed Data
resource "aws_glue_crawler" "processed_data_crawler" {
  database_name = aws_glue_catalog_database.data_lake_catalog.name
  name          = "${var.environment}-processed-data-crawler"
  role          = aws_iam_role.glue_service_role.arn

  s3_target {
    path = "s3://${aws_s3_bucket.data_lake.bucket}/processed/"
  }

  # schedule = "cron(0 3 * * ? *)"  # Run daily at 3 AM - DISABLED to avoid charges

  tags = {
    Name        = "${var.environment}-processed-data-crawler"
    Environment = var.environment
  }
}

# Glue Job for Data Processing
resource "aws_glue_job" "data_processing_job" {
  name     = "${var.environment}-data-processing-job"
  role_arn = aws_iam_role.glue_service_role.arn

  command {
    script_location = "s3://${aws_s3_bucket.glue_scripts.bucket}/scripts/data_processing.py"
    python_version  = "3"
  }

  default_arguments = {
    "--job-language"                    = "python"
    "--job-bookmark-option"            = "job-bookmark-enable"
    "--enable-metrics"                 = "true"
        # "--enable-continuous-cloudwatch-log" = "true"  # CloudWatch logging disabled
    "--TempDir"                        = "s3://${aws_s3_bucket.glue_scripts.bucket}/temp/"
    "--job-bookmark-option"            = "job-bookmark-enable"
  }

  max_capacity = 2
  timeout      = 60

  tags = {
    Name        = "${var.environment}-data-processing-job"
    Environment = var.environment
  }
}

# Glue Job for Data Quality Checks
resource "aws_glue_job" "data_quality_job" {
  name     = "${var.environment}-data-quality-job"
  role_arn = aws_iam_role.glue_service_role.arn

  command {
    script_location = "s3://${aws_s3_bucket.glue_scripts.bucket}/scripts/data_quality.py"
    python_version  = "3"
  }

  default_arguments = {
    "--job-language"                    = "python"
    "--enable-metrics"                 = "true"
        # "--enable-continuous-cloudwatch-log" = "true"  # CloudWatch logging disabled
    "--TempDir"                        = "s3://${aws_s3_bucket.glue_scripts.bucket}/temp/"
  }

  max_capacity = 1
  timeout      = 30

  tags = {
    Name        = "${var.environment}-data-quality-job"
    Environment = var.environment
  }
}

# Glue Workflow for ETL Pipeline
resource "aws_glue_workflow" "etl_workflow" {
  name = "${var.environment}-etl-workflow"

  description = "ETL workflow for data processing pipeline"

  tags = {
    Name        = "${var.environment}-etl-workflow"
    Environment = var.environment
  }
}

# Glue Trigger for Workflow
resource "aws_glue_trigger" "etl_trigger" {
  name          = "${var.environment}-etl-trigger"
  workflow_name = aws_glue_workflow.etl_workflow.name
  type          = "ON_DEMAND"  # Changed from SCHEDULED to avoid charges
  # schedule      = "cron(0 1 * * ? *)"  # Run daily at 1 AM - DISABLED to avoid charges

  actions {
    job_name = aws_glue_job.data_processing_job.name
  }

  actions {
    job_name = aws_glue_job.data_quality_job.name
  }

  tags = {
    Name        = "${var.environment}-etl-trigger"
    Environment = var.environment
  }
}

# CloudWatch Log Group for Glue - DISABLED
# Uncomment the block below to enable CloudWatch logging
# resource "aws_cloudwatch_log_group" "glue_logs" {
#   name              = "/aws-glue/jobs/${var.environment}"
#   retention_in_days = 14

#   tags = {
#     Name        = "${var.environment}-glue-logs"
#     Environment = var.environment
#   }
# }
