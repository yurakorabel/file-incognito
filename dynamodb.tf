# DynamoDB Table for File Access Codes
resource "aws_dynamodb_table" "file_access_codes" {
  name         = "FileAccessCodes" # Name of the table
  billing_mode = "PAY_PER_REQUEST" # On-demand billing mode (no need to specify RCU/WCU)
  hash_key     = "access_code"     # Primary key column

  attribute {
    name = "access_code" # Define the primary key attribute
    type = "S"           # String type
  }

  # Optional: Define a Time-to-Live (TTL) attribute for automatic expiration
  ttl {
    attribute_name = "expiration_date"
    enabled        = true
  }

  # Tags to identify the environment and purpose
  tags = {
    Name        = "FileAccessCodes"
    Environment = "production"
  }
}
