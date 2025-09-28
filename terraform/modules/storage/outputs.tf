output "data_lake_bucket_name" {
  description = "Name of the main data lake S3 bucket"
  value       = aws_s3_bucket.data_lake.bucket
}

output "data_lake_bucket_arn" {
  description = "ARN of the main data lake S3 bucket"
  value       = aws_s3_bucket.data_lake.arn
}

output "ecr_repository_urls" {
  description = "URLs of the ECR repositories"
  value = {
    spark_apps = aws_ecr_repository.spark_apps.repository_url
    data_jobs  = aws_ecr_repository.data_jobs.repository_url
    glue_jobs  = aws_ecr_repository.glue_jobs.repository_url
  }
}

output "glue_catalog_database_name" {
  description = "Name of the Glue catalog database"
  value       = aws_glue_catalog_database.data_lake_catalog.name
}

output "glue_job_names" {
  description = "Names of the Glue jobs"
  value = {
    data_processing = aws_glue_job.data_processing_job.name
    data_quality    = aws_glue_job.data_quality_job.name
  }
}
