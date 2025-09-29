# Serverless Container & Kubernetes Guide

## 🚀 **Complete Guide to Serverless Container Deployment**

This guide covers all the serverless options for running Kubernetes workloads and Docker containers on AWS, including when to use each service and how to implement them.

---

## 📋 **Serverless Container Options Overview**

### **AWS Services for Serverless Containers**

| **Service** | **Use Case** | **Max Runtime** | **Max Memory** | **Max CPU** | **Best For** |
|-------------|--------------|-----------------|----------------|-------------|--------------|
| **AWS Lambda** | Event-driven functions | 15 minutes | 10 GB | 6 vCPU | Microservices, APIs |
| **AWS Fargate** | Long-running containers | Unlimited | 30 GB | 4 vCPU | Web apps, batch jobs |
| **AWS Batch** | Batch processing | Unlimited | 30 GB | 4 vCPU | ETL, ML training |
| **AWS App Runner** | Web applications | Unlimited | 4 GB | 2 vCPU | Simple web apps |
| **AWS Lambda Container** | Container functions | 15 minutes | 10 GB | 6 vCPU | Containerized functions |

---

## 🔥 **1. AWS Lambda (Serverless Functions)**

### **Overview**
AWS Lambda is perfect for event-driven, short-running functions that respond to triggers.

### **When to Use Lambda**
- ✅ **Event-driven processing** (S3 uploads, API calls, database changes)
- ✅ **Microservices** with simple logic
- ✅ **Data transformation** and validation
- ✅ **API endpoints** (with API Gateway)
- ✅ **Scheduled tasks** (with EventBridge)

### **Lambda Container Support**
```hcl
# Lambda function using container image
resource "aws_lambda_function" "container_function" {
  function_name = "${var.environment}-container-function"
  role          = aws_iam_role.lambda_role.arn
  package_type  = "Image"
  image_uri     = "${aws_ecr_repository.data_jobs.repository_url}:latest"
  
  timeout     = 900  # 15 minutes max
  memory_size = 1024 # 1 GB max (can go up to 10 GB)
  
  environment {
    variables = {
      S3_BUCKET = aws_s3_bucket.data_lake.bucket
      ENVIRONMENT = var.environment
    }
  }
}

# IAM role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "${var.environment}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Lambda permissions
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_s3_access" {
  name = "${var.environment}-lambda-s3-access"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = [
          "${aws_s3_bucket.data_lake.arn}/*"
        ]
      }
    ]
  })
}
```

### **Lambda Container Example**
```dockerfile
# Dockerfile for Lambda container
FROM public.ecr.aws/lambda/python:3.9

# Copy function code
COPY lambda_function.py ${LAMBDA_TASK_ROOT}

# Install dependencies
COPY requirements.txt .
RUN pip install -r requirements.txt

# Set the CMD to your handler
CMD ["lambda_function.handler"]
```

```python
# lambda_function.py
import json
import boto3
import os

def handler(event, context):
    """
    Lambda function handler
    """
    s3 = boto3.client('s3')
    bucket_name = os.environ['S3_BUCKET']
    
    # Process the event
    print(f"Processing event: {json.dumps(event)}")
    
    # Your business logic here
    result = {
        'statusCode': 200,
        'body': json.dumps({
            'message': 'Hello from Lambda container!',
            'bucket': bucket_name
        })
    }
    
    return result
```

---

## 🐳 **2. AWS Fargate (Serverless Containers)**

### **Overview**
AWS Fargate is perfect for long-running containerized applications that need to be always available.

### **When to Use Fargate**
- ✅ **Web applications** that need to be always running
- ✅ **API services** with consistent traffic
- ✅ **Background workers** and batch processing
- ✅ **Microservices** that need persistent connections
- ✅ **Containerized applications** without Kubernetes complexity

### **Fargate with ECS**
```hcl
# ECS Cluster with Fargate
resource "aws_ecs_cluster" "fargate_cluster" {
  name = "${var.environment}-fargate-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

# Fargate Task Definition
resource "aws_ecs_task_definition" "fargate_task" {
  family                   = "${var.environment}-fargate-task"
  network_mode            = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                     = 1024  # 1 vCPU
  memory                  = 2048  # 2 GB
  execution_role_arn      = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn          = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name  = "web-app"
      image = "${aws_ecr_repository.data_jobs.repository_url}:latest"
      
      portMappings = [
        {
          containerPort = 8080
          protocol      = "tcp"
        }
      ]
      
      environment = [
        {
          name  = "ENVIRONMENT"
          value = var.environment
        },
        {
          name  = "S3_BUCKET"
          value = aws_s3_bucket.data_lake.bucket
        }
      ]
      
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.fargate_logs.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

# Fargate Service
resource "aws_ecs_service" "fargate_service" {
  name            = "${var.environment}-fargate-service"
  cluster         = aws_ecs_cluster.fargate_cluster.id
  task_definition = aws_ecs_task_definition.fargate_task.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.fargate.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.fargate.arn
    container_name   = "web-app"
    container_port   = 8080
  }

  depends_on = [aws_lb_listener.fargate]
}

# Application Load Balancer
resource "aws_lb" "fargate_alb" {
  name               = "${var.environment}-fargate-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web.id]
  subnets            = aws_subnet.public[*].id
}

resource "aws_lb_target_group" "fargate" {
  name     = "${var.environment}-fargate-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "fargate" {
  load_balancer_arn = aws_lb.fargate_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.fargate.arn
  }
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "fargate_logs" {
  name              = "/ecs/${var.environment}-fargate"
  retention_in_days = 30
}
```

---

## ⚡ **3. AWS Batch (Serverless Batch Processing)**

### **Overview**
AWS Batch is perfect for running batch jobs, ETL processes, and machine learning training.

### **When to Use Batch**
- ✅ **ETL processes** and data transformation
- ✅ **Machine learning training** and inference
- ✅ **Image processing** and video encoding
- ✅ **Scientific computing** and simulations
- ✅ **Scheduled batch jobs**

### **Batch Job Definition**
```hcl
# Batch Compute Environment
resource "aws_batch_compute_environment" "fargate_batch" {
  compute_environment_name = "${var.environment}-fargate-batch"
  type                    = "MANAGED"
  state                   = "ENABLED"

  compute_resources {
    type                = "FARGATE"
    max_vcpus          = 256
    min_vcpus          = 0
    security_group_ids = [aws_security_group.batch.id]
    subnets            = aws_subnet.private[*].id

    tags = {
      Name = "${var.environment}-batch-compute"
    }
  }
}

# Batch Job Queue
resource "aws_batch_job_queue" "batch_queue" {
  name     = "${var.environment}-batch-queue"
  state    = "ENABLED"
  priority = 1

  compute_environments = [aws_batch_compute_environment.fargate_batch.arn]
}

# Batch Job Definition
resource "aws_batch_job_definition" "etl_job" {
  name = "${var.environment}-etl-job"
  type = "container"
  platform_capabilities = ["FARGATE"]

  container_properties = jsonencode({
    image = "${aws_ecr_repository.data_jobs.repository_url}:latest"
    
    vcpus   = 2
    memory  = 4096
    
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
    
    jobRoleArn = aws_iam_role.batch_job_role.arn
    executionRoleArn = aws_iam_role.batch_execution_role.arn
    
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.batch_logs.name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "batch"
      }
    }
  })
}

# IAM Role for Batch Jobs
resource "aws_iam_role" "batch_job_role" {
  name = "${var.environment}-batch-job-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role" "batch_execution_role" {
  name = "${var.environment}-batch-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

# CloudWatch Log Group for Batch
resource "aws_cloudwatch_log_group" "batch_logs" {
  name              = "/aws/batch/${var.environment}"
  retention_in_days = 30
}
```

---

## 🌐 **4. AWS App Runner (Simple Web Apps)**

### **Overview**
AWS App Runner is perfect for simple web applications that need automatic scaling and deployment.

### **When to Use App Runner**
- ✅ **Simple web applications** (React, Vue, Angular)
- ✅ **API services** with basic requirements
- ✅ **Static websites** with backend
- ✅ **Quick deployments** without complex configuration
- ✅ **Cost-effective** solutions for small applications

### **App Runner Service**
```hcl
# App Runner Service
resource "aws_apprunner_service" "web_app" {
  service_name = "${var.environment}-web-app"

  source_configuration {
    image_repository {
      image_identifier      = "${aws_ecr_repository.data_jobs.repository_url}:latest"
      image_configuration {
        port = "8080"
        runtime_environment_variables = {
          ENVIRONMENT = var.environment
          S3_BUCKET   = aws_s3_bucket.data_lake.bucket
        }
      }
      image_repository_type = "ECR"
    }
    auto_deployments_enabled = true
  }

  instance_configuration {
    cpu    = "0.25 vCPU"
    memory = "0.5 GB"
  }

  tags = {
    Name        = "${var.environment}-web-app"
    Environment = var.environment
  }
}
```

---

## ☸️ **5. Serverless Kubernetes Options**

### **Amazon EKS with Fargate**
```hcl
# EKS Cluster
resource "aws_eks_cluster" "serverless" {
  name     = "${var.environment}-serverless-eks"
  role_arn = aws_iam_role.eks_cluster.arn
  version  = "1.28"

  vpc_config {
    subnet_ids = aws_subnet.private[*].id
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
  ]
}

# Fargate Profile
resource "aws_eks_fargate_profile" "serverless" {
  cluster_name           = aws_eks_cluster.serverless.name
  fargate_profile_name   = "${var.environment}-serverless"
  pod_execution_role_arn = aws_iam_role.eks_fargate.arn
  subnet_ids            = aws_subnet.private[*].id

  selector {
    namespace = "default"
  }
}
```

---

## 🔧 **6. Implementation Examples**

### **Example 1: Data Processing Pipeline**
```hcl
# Lambda for S3 trigger
resource "aws_lambda_function" "s3_processor" {
  function_name = "${var.environment}-s3-processor"
  role          = aws_iam_role.lambda_role.arn
  package_type  = "Image"
  image_uri     = "${aws_ecr_repository.data_jobs.repository_url}:s3-processor"
  
  timeout     = 900
  memory_size = 2048
}

# S3 trigger
resource "aws_s3_bucket_notification" "lambda_trigger" {
  bucket = aws_s3_bucket.data_lake.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.s3_processor.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "raw/"
  }
}

# Batch job for heavy processing
resource "aws_batch_job_definition" "data_processor" {
  name = "${var.environment}-data-processor"
  type = "container"
  platform_capabilities = ["FARGATE"]

  container_properties = jsonencode({
    image = "${aws_ecr_repository.data_jobs.repository_url}:processor"
    vcpus = 4
    memory = 8192
  })
}
```

### **Example 2: API Gateway + Lambda**
```hcl
# API Gateway
resource "aws_api_gateway_rest_api" "serverless_api" {
  name = "${var.environment}-serverless-api"
}

resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.serverless_api.id
  parent_id   = aws_api_gateway_rest_api.serverless_api.root_resource_id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "proxy" {
  rest_api_id   = aws_api_gateway_rest_api.serverless_api.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda" {
  rest_api_id = aws_api_gateway_rest_api.serverless_api.id
  resource_id = aws_api_gateway_method.proxy.resource_id
  http_method = aws_api_gateway_method.proxy.http_method

  integration_http_method = "POST"
  type                   = "AWS_PROXY"
  uri                    = aws_lambda_function.api_handler.invoke_arn
}
```

---

## 💰 **Cost Comparison**

### **Cost per Hour (us-east-2)**
| **Service** | **1 vCPU, 2GB RAM** | **2 vCPU, 4GB RAM** | **4 vCPU, 8GB RAM** |
|-------------|---------------------|---------------------|---------------------|
| **Lambda** | $0.0000166667/GB-second | N/A (max 15 min) | N/A (max 15 min) |
| **Fargate** | $0.04048 | $0.08096 | $0.16192 |
| **Batch** | $0.04048 | $0.08096 | $0.16192 |
| **App Runner** | $0.007 | $0.014 | N/A (max 2 vCPU) |

### **When to Choose Each Service**

#### **Choose Lambda When:**
- ✅ **Event-driven** processing
- ✅ **Short-running** tasks (< 15 minutes)
- ✅ **Variable traffic** patterns
- ✅ **Cost optimization** for sporadic usage

#### **Choose Fargate When:**
- ✅ **Long-running** applications
- ✅ **Consistent traffic** patterns
- ✅ **Container orchestration** needed
- ✅ **Complex networking** requirements

#### **Choose Batch When:**
- ✅ **Batch processing** workloads
- ✅ **High compute** requirements
- ✅ **Scheduled jobs** and ETL
- ✅ **Cost optimization** for batch work

#### **Choose App Runner When:**
- ✅ **Simple web applications**
- ✅ **Quick deployment** needed
- ✅ **Automatic scaling** required
- ✅ **Minimal configuration** desired

---

## 🚀 **Quick Start Commands**

### **Deploy Lambda Function**
```bash
# Build and push container
docker build -t my-lambda .
docker tag my-lambda:latest <ECR_URL>:latest
docker push <ECR_URL>:latest

# Deploy with Terraform
terraform apply -target=aws_lambda_function.container_function
```

### **Deploy Fargate Service**
```bash
# Deploy ECS service
terraform apply -target=aws_ecs_service.fargate_service

# Check service status
aws ecs describe-services --cluster <CLUSTER_NAME> --services <SERVICE_NAME>
```

### **Run Batch Job**
```bash
# Submit batch job
aws batch submit-job \
  --job-name my-etl-job \
  --job-queue <QUEUE_NAME> \
  --job-definition <JOB_DEFINITION_NAME>

# Check job status
aws batch describe-jobs --jobs <JOB_ID>
```

---

## 🔍 **Monitoring and Debugging**

### **CloudWatch Metrics**
```bash
# View Lambda metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Duration \
  --dimensions Name=FunctionName,Value=my-function \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-02T00:00:00Z \
  --period 3600 \
  --statistics Average

# View Fargate metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/ECS \
  --metric-name CPUUtilization \
  --dimensions Name=ServiceName,Value=my-service \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-02T00:00:00Z \
  --period 3600 \
  --statistics Average
```

### **Logs**
```bash
# View Lambda logs
aws logs tail /aws/lambda/my-function --follow

# View Fargate logs
aws logs tail /ecs/my-service --follow

# View Batch logs
aws logs tail /aws/batch/job --follow
```

---

## 🎯 **Best Practices**

### **Lambda Best Practices**
1. **Keep functions small** and focused
2. **Use environment variables** for configuration
3. **Implement proper error handling**
4. **Use dead letter queues** for failed messages
5. **Monitor cold starts** and optimize

### **Fargate Best Practices**
1. **Right-size containers** (CPU and memory)
2. **Use health checks** for load balancers
3. **Implement graceful shutdowns**
4. **Use service discovery** for internal communication
5. **Monitor resource utilization**

### **Batch Best Practices**
1. **Use spot instances** for cost savings
2. **Implement job retry logic**
3. **Use job dependencies** for complex workflows
4. **Monitor job completion** and failures
5. **Clean up resources** after job completion

---

## 🔗 **Integration with Your Current Infrastructure**

### **With S3 Data Lake**
```hcl
# Lambda function triggered by S3 uploads
resource "aws_lambda_function" "s3_processor" {
  # ... configuration
  environment {
    variables = {
      S3_BUCKET = aws_s3_bucket.data_lake.bucket
      ATHENA_DATABASE = module.athena.database_name
    }
  }
}
```

### **With Athena**
```hcl
# Batch job for Athena queries
resource "aws_batch_job_definition" "athena_query" {
  # ... configuration
  container_properties = jsonencode({
    image = "${aws_ecr_repository.data_jobs.repository_url}:athena-query"
    environment = [
      {
        name  = "ATHENA_WORKGROUP"
        value = module.athena.workgroup_name
      }
    ]
  })
}
```

### **With Monitoring**
```hcl
# CloudWatch alarms for serverless services
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "${var.environment}-lambda-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "This metric monitors lambda errors"
}
```

---

**Your serverless container infrastructure is now ready for any workload!** 🎉

**Key Benefits:**
- ✅ **No server management** - AWS handles all infrastructure
- ✅ **Automatic scaling** - Scale based on demand
- ✅ **Cost optimization** - Pay only for what you use
- ✅ **High availability** - Built-in redundancy and failover
- ✅ **Easy deployment** - Simple container deployment process

**Choose the right service for your use case and start building!** 🚀
