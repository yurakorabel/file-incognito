# ========== LAMBDA IAM ==========

# =========== UPLOAD IAM ===========

resource "aws_iam_policy" "upload_lambda_file_sharing_policy" {
  name        = "LambdaFileSharingPolicy"
  description = "IAM policy for Lambda to access S3, DynamoDB, and SNS for file sharing functionality"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        # S3 permissions
        Effect   = "Allow",
        Action   = ["s3:PutObject"],
        Resource = "${aws_s3_bucket.s3_bucket.arn}/*" # Allows access to all objects in the bucket
      },
      {
        # DynamoDB permissions
        Effect   = "Allow",
        Action   = ["dynamodb:PutItem"],
        Resource = aws_dynamodb_table.file_access_codes.arn
      },
      {
        # SNS publish permissions
        Effect   = "Allow",
        Action   = ["sns:Publish"],
        Resource = aws_sns_topic.file_access_notifications.arn
      }
    ]
  })
}

resource "aws_iam_role" "upload_lambda_execution_role" {
  name = "LambdaFileSharingExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Attach the policy to the role
resource "aws_iam_role_policy_attachment" "upload_lambda_policy_attachment" {
  role       = aws_iam_role.upload_lambda_execution_role.name
  policy_arn = aws_iam_policy.upload_lambda_file_sharing_policy.arn
}

# =========== DOWNLOAD IAM ===========

resource "aws_iam_policy" "download_lambda_file_sharing_policy" {
  name        = "LambdaDownloadFilePolicy"
  description = "IAM policy for Lambda to access S3, DynamoDB, and SNS for file sharing functionality"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        # S3 permissions
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ],
        Resource = [
          "${aws_s3_bucket.s3_bucket.arn}/",
          "${aws_s3_bucket.s3_bucket.arn}/*"
        ]
      },
      {
        # DynamoDB permissions
        Effect = "Allow",
        Action = [
          "dynamodb:GetItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ],
        Resource = aws_dynamodb_table.file_access_codes.arn
      }
    ]
  })
}

resource "aws_iam_role" "download_lambda_execution_role" {
  name = "LambdaDownloadFileExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Attach the policy to the role
resource "aws_iam_role_policy_attachment" "download_lambda_policy_attachment" {
  role       = aws_iam_role.download_lambda_execution_role.name
  policy_arn = aws_iam_policy.download_lambda_file_sharing_policy.arn
}
