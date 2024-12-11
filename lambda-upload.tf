# The following code provisions an AWS Lambda function and an archive file to deploy the Lambda function (/upload).

# Creates an AWS Lambda function resource
resource "aws_lambda_function" "upload_file_sharing_lambda" {
  function_name    = "${var.name}-function-upload"
  role             = aws_iam_role.upload_lambda_execution_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.9"
  timeout          = 30
  filename         = data.archive_file.post_lambda_zip.output_path
  source_code_hash = data.archive_file.post_lambda_zip.output_base64sha256

  # Environment variables for Lambda function
  environment {
    variables = {
      S3_BUCKET_NAME      = aws_s3_bucket.s3_bucket.bucket
      DYNAMODB_TABLE_NAME = aws_dynamodb_table.file_access_codes.name
      SNS_TOPIC_ARN       = aws_sns_topic.file_access_notifications.arn
    }
  }
}

# Archives a file to deploy the Lambda function
data "archive_file" "post_lambda_zip" {
  type        = "zip"
  output_path = "post_lambda_function.zip"

  # Include the Lambda function and all dependencies from the directory
  source_dir = "scripts/upload-script"                                              # Directory with your lambda function and dependencies
  excludes   = ["scripts/upload-script/.git*", "scripts/upload-script/__pycache__"] # Exclude any unnecessary files (optional)
}
