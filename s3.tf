# ========================================
# S3 DATA LAKE
# ========================================

# Random suffix for unique bucket names
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# Main Data Lake S3 Bucket
resource "aws_s3_bucket" "data_lake" {
  bucket = "${var.environment}-data-lake-${random_string.suffix.result}"

  tags = {
    Name        = "${var.environment}-data-lake"
    Environment = var.environment
    Purpose     = "Data Lake Storage"
  }
}

# S3 Bucket Versioning
resource "aws_s3_bucket_versioning" "data_lake" {
  bucket = aws_s3_bucket.data_lake.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 Bucket Server-side Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "data_lake" {
  bucket = aws_s3_bucket.data_lake.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 Bucket Public Access Block
resource "aws_s3_bucket_public_access_block" "data_lake" {
  bucket = aws_s3_bucket.data_lake.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Data Lake Zones (folders)
resource "aws_s3_object" "raw_zone" {
  bucket = aws_s3_bucket.data_lake.id
  key    = "raw/"
  content_type = "application/x-directory"
}

resource "aws_s3_object" "processed_zone" {
  bucket = aws_s3_bucket.data_lake.id
  key    = "processed/"
  content_type = "application/x-directory"
}

resource "aws_s3_object" "analytics_zone" {
  bucket = aws_s3_bucket.data_lake.id
  key    = "analytics/"
  content_type = "application/x-directory"
}

resource "aws_s3_object" "curated_zone" {
  bucket = aws_s3_bucket.data_lake.id
  key    = "curated/"
  content_type = "application/x-directory"
}

# S3 Bucket for Glue scripts and temporary files
resource "aws_s3_bucket" "glue_scripts" {
  bucket = "${var.environment}-glue-scripts-${random_string.suffix.result}"

  tags = {
    Name        = "${var.environment}-glue-scripts"
    Environment = var.environment
    Purpose     = "Glue Scripts and Temp Files"
  }
}

# S3 Bucket for Glue job outputs
resource "aws_s3_bucket" "glue_outputs" {
  bucket = "${var.environment}-glue-outputs-${random_string.suffix.result}"

  tags = {
    Name        = "${var.environment}-glue-outputs"
    Environment = var.environment
    Purpose     = "Glue Job Outputs"
  }
}
