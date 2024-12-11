# The default region for the AWS provider
variable "default-region" {
  default = "us-east-1"
}

# A name to use for the resources that will be created
variable "name" {
  description = "Name to use for Resources"
  default     = "Serverless-APIGateway-Lambda"
}

# ---- S3 bucket ----

# The name of an S3 bucket that will be created for storing uploaded files
variable "files-bucket-name" {
  default = "files-incognito-korabel"
}

# Specifies who should own the S3 bucket
variable "bucket-ovnership" {
  default = "BucketOwnerEnforced"
}

# ---- Usage Plan ----

# A quota limit for the number of API requests that can be made within a period of time
variable "quota-limit" {
  default = "50000"
}

# The period of time for the quota limit, e.g. DAY, WEEK, MONTH
variable "quota-period" {
  default = "DAY"
}

# The number of requests that can be made in a short burst without exceeding the quota limit
variable "burst" {
  default = "3"
}

# The rate at which requests can be made without exceeding the quota limit
variable "rate" {
  default = "1"
}

# ---- Deployment ----

# The name of the API Gateway deployment stage.
variable "stage" {
  default = "run"
}

# ---- SNS ----

# Define a list variable for email recipients
variable "email_recipients" {
  type    = list(string)
  default = ["yurakorabel@gmail.com", "yurakorabel3@gmail.com"]
}
