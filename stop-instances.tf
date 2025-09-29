# ========================================
# STOP EC2 INSTANCES CONFIGURATION
# ========================================
# This file can be used to stop instances without destroying them
# Comment out the instances you want to keep running

# Uncomment the lines below to stop instances
# resource "aws_instance" "monitoring" {
#   # This will recreate the instance in stopped state
#   # Comment out the entire block to stop the instance
# }

# resource "aws_instance" "kubernetes" {
#   # This will recreate the instance in stopped state
#   # Comment out the entire block to stop the instance
# }
