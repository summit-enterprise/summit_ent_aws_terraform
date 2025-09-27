variable "AWS_DEFAULT_REGION" {
    description = "AWS default region"
    type = string
    default = "us-east-2"
}

variable "TEST_VAR" {
    description = "A test variable with no default value"
    type = string
    default = "my-custom-value"
}