# AWS Secrets Manager Integration Guide

## 🔐 **AWS Secrets Manager Setup**

This guide shows you how to use AWS Secrets Manager to securely store and manage secrets for your infrastructure.

## 📋 **What's Included**

### **🔑 Pre-configured Secrets:**

| **Secret** | **Purpose** | **Contains** |
|------------|-------------|--------------|
| **MySQL Credentials** | RDS Database | username, password, host, port, dbname |
| **Redis Credentials** | ElastiCache | password, host, port |
| **Grafana Credentials** | Monitoring | username, password, URL |
| **ArgoCD Credentials** | Kubernetes | username, password, URL |
| **App Secrets** | Applications | JWT secret, API key, encryption key, webhook secret |

### **🛡️ Security Features:**

- **Random Password Generation** - 16-character passwords with special characters
- **Encryption at Rest** - All secrets encrypted with AWS KMS
- **IAM Access Control** - Fine-grained permissions for each service
- **Automatic Rotation** - Can be configured for automatic password rotation
- **Audit Logging** - All access logged in CloudTrail

## 🚀 **How to Use**

### **1. Deploy with Secrets Manager:**
```bash
# Deploy the infrastructure with secrets
terraform apply

# Enable databases (optional)
# Edit examples/ec2.tf and set count = 1 for RDS and Redis
```

### **2. Retrieve Secrets in Your Applications:**

#### **Using AWS CLI:**
```bash
# Get MySQL credentials
aws secretsmanager get-secret-value \
  --secret-id dev-mysql-credentials \
  --query SecretString --output text | jq .

# Get Redis credentials
aws secretsmanager get-secret-value \
  --secret-id dev-redis-credentials \
  --query SecretString --output text | jq .

# Get Grafana credentials
aws secretsmanager get-secret-value \
  --secret-id dev-grafana-credentials \
  --query SecretString --output text | jq .
```

#### **Using AWS SDK (Python):**
```python
import boto3
import json

def get_secret(secret_name, region_name="us-east-2"):
    session = boto3.session.Session()
    client = session.client(
        service_name='secretsmanager',
        region_name=region_name
    )
    
    try:
        get_secret_value_response = client.get_secret_value(
            SecretId=secret_name
        )
    except ClientError as e:
        raise e
    
    secret = get_secret_value_response['SecretString']
    return json.loads(secret)

# Usage
mysql_creds = get_secret("dev-mysql-credentials")
redis_creds = get_secret("dev-redis-credentials")
grafana_creds = get_secret("dev-grafana-credentials")
```

#### **Using AWS SDK (Node.js):**
```javascript
const AWS = require('aws-sdk');
const secretsManager = new AWS.SecretsManager({ region: 'us-east-2' });

async function getSecret(secretName) {
    try {
        const result = await secretsManager.getSecretValue({
            SecretId: secretName
        }).promise();
        
        return JSON.parse(result.SecretString);
    } catch (error) {
        console.error('Error retrieving secret:', error);
        throw error;
    }
}

// Usage
const mysqlCreds = await getSecret('dev-mysql-credentials');
const redisCreds = await getSecret('dev-redis-credentials');
```

### **3. Using Secrets in ECS Tasks:**

#### **Task Definition with Secrets:**
```json
{
  "family": "my-app",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "256",
  "memory": "512",
  "executionRoleArn": "arn:aws:iam::ACCOUNT:role/ecsTaskExecutionRole",
  "containerDefinitions": [
    {
      "name": "my-app",
      "image": "my-app:latest",
      "secrets": [
        {
          "name": "DB_PASSWORD",
          "valueFrom": "arn:aws:secretsmanager:us-east-2:ACCOUNT:secret:dev-mysql-credentials:password::"
        },
        {
          "name": "REDIS_PASSWORD",
          "valueFrom": "arn:aws:secretsmanager:us-east-2:ACCOUNT:secret:dev-redis-credentials:password::"
        }
      ],
      "environment": [
        {
          "name": "DB_HOST",
          "value": "dev-mysql.cluster-xyz.us-east-2.rds.amazonaws.com"
        },
        {
          "name": "REDIS_HOST",
          "value": "dev-redis.xyz.cache.amazonaws.com"
        }
      ]
    }
  ]
}
```

### **4. Using Secrets in Kubernetes (ArgoCD):**

#### **Create Secret in Kubernetes:**
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
type: Opaque
data:
  # These will be populated by an init container or operator
  db-password: ""
  redis-password: ""
```

#### **Init Container to Fetch Secrets:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  template:
    spec:
      initContainers:
      - name: fetch-secrets
        image: amazon/aws-cli:latest
        command:
        - /bin/sh
        - -c
        - |
          aws secretsmanager get-secret-value \
            --secret-id dev-mysql-credentials \
            --query SecretString --output text | \
          jq -r '.password' > /shared/db-password
        volumeMounts:
        - name: shared-secrets
          mountPath: /shared
      containers:
      - name: my-app
        image: my-app:latest
        env:
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: app-secrets
              key: db-password
        volumeMounts:
        - name: shared-secrets
          mountPath: /shared
      volumes:
      - name: shared-secrets
        emptyDir: {}
```

## 🔧 **Managing Secrets**

### **1. View All Secrets:**
```bash
# List all secrets
aws secretsmanager list-secrets

# Get specific secret
aws secretsmanager describe-secret --secret-id dev-mysql-credentials
```

### **2. Update Secrets:**
```bash
# Update secret value
aws secretsmanager update-secret \
  --secret-id dev-mysql-credentials \
  --secret-string '{"username":"admin","password":"newpassword","host":"newhost","port":3306,"dbname":"mydb"}'
```

### **3. Rotate Secrets:**
```bash
# Enable automatic rotation (requires Lambda function)
aws secretsmanager update-secret \
  --secret-id dev-mysql-credentials \
  --description "MySQL credentials with rotation" \
  --secret-string '{"username":"admin","password":"currentpassword","host":"host","port":3306,"dbname":"mydb"}'
```

### **4. Delete Secrets:**
```bash
# Delete secret (immediate)
aws secretsmanager delete-secret \
  --secret-id dev-mysql-credentials \
  --force-delete-without-recovery

# Schedule deletion (7-30 days)
aws secretsmanager delete-secret \
  --secret-id dev-mysql-credentials \
  --recovery-window-in-days 7
```

## 🛡️ **Security Best Practices**

### **1. IAM Permissions:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue"
      ],
      "Resource": [
        "arn:aws:secretsmanager:us-east-2:ACCOUNT:secret:dev-mysql-credentials*"
      ]
    }
  ]
}
```

### **2. Least Privilege Access:**
- Only grant access to specific secrets
- Use resource-based policies when possible
- Regularly audit access permissions

### **3. Encryption:**
- All secrets are encrypted at rest with AWS KMS
- Use customer-managed KMS keys for additional control
- Enable encryption in transit for all API calls

### **4. Monitoring:**
- Enable CloudTrail for audit logging
- Set up CloudWatch alarms for secret access
- Monitor for unusual access patterns

## 🔄 **Secret Rotation**

### **1. Manual Rotation:**
```bash
# Generate new password
NEW_PASSWORD=$(openssl rand -base64 32)

# Update secret
aws secretsmanager update-secret \
  --secret-id dev-mysql-credentials \
  --secret-string "{\"username\":\"admin\",\"password\":\"$NEW_PASSWORD\",\"host\":\"host\",\"port\":3306,\"dbname\":\"mydb\"}"
```

### **2. Automatic Rotation:**
```hcl
# Enable automatic rotation for RDS
resource "aws_db_instance" "mysql" {
  # ... other configuration ...
  
  manage_master_user_password = true
  master_user_secret_kms_key_id = aws_kms_key.rds.arn
}
```

## 📊 **Cost Optimization**

### **1. Secret Storage Costs:**
- **$0.40 per secret per month** (first 10,000 secrets)
- **$0.05 per 10,000 API calls**
- **Free rotation** for RDS, Redshift, DocumentDB

### **2. Cost-Saving Tips:**
- Group related secrets together
- Use resource-based policies to reduce API calls
- Implement caching in your applications
- Use IAM roles instead of access keys

## 🚨 **Troubleshooting**

### **Common Issues:**

#### **1. Access Denied:**
```bash
# Check IAM permissions
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::ACCOUNT:role/MyRole \
  --action-names secretsmanager:GetSecretValue \
  --resource-arns arn:aws:secretsmanager:us-east-2:ACCOUNT:secret:dev-mysql-credentials
```

#### **2. Secret Not Found:**
```bash
# List all secrets
aws secretsmanager list-secrets --query 'SecretList[?contains(Name, `mysql`)]'
```

#### **3. Invalid JSON:**
```bash
# Validate JSON
echo '{"username":"admin","password":"test"}' | jq .
```

## 📚 **Additional Resources**

- [AWS Secrets Manager Documentation](https://docs.aws.amazon.com/secretsmanager/)
- [Best Practices for AWS Secrets Manager](https://docs.aws.amazon.com/secretsmanager/latest/userguide/best-practices.html)
- [Rotating Secrets](https://docs.aws.amazon.com/secretsmanager/latest/userguide/rotating-secrets.html)

---

**Your secrets are now securely managed with AWS Secrets Manager!** 🔐
