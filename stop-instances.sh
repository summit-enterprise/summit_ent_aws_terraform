#!/bin/bash

# Stop EC2 instances script
# This script stops the EC2 instances without destroying them

echo "🛑 Stopping EC2 instances..."

# Get instance IDs
MONITORING_INSTANCE_ID=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=dev-monitoring" "Name=instance-state-name,Values=running" \
  --query 'Reservations[0].Instances[0].InstanceId' \
  --output text)

KUBERNETES_INSTANCE_ID=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=dev-kubernetes" "Name=instance-state-name,Values=running" \
  --query 'Reservations[0].Instances[0].InstanceId' \
  --output text)

if [ "$MONITORING_INSTANCE_ID" != "None" ] && [ "$MONITORING_INSTANCE_ID" != "null" ]; then
  echo "Stopping monitoring instance: $MONITORING_INSTANCE_ID"
  aws ec2 stop-instances --instance-ids $MONITORING_INSTANCE_ID
else
  echo "No running monitoring instance found"
fi

if [ "$KUBERNETES_INSTANCE_ID" != "None" ] && [ "$KUBERNETES_INSTANCE_ID" != "null" ]; then
  echo "Stopping kubernetes instance: $KUBERNETES_INSTANCE_ID"
  aws ec2 stop-instances --instance-ids $KUBERNETES_INSTANCE_ID
else
  echo "No running kubernetes instance found"
fi

echo "✅ Instances stop initiated. Check AWS Console for status."
