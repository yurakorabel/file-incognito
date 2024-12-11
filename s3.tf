# ========== WEBSITE BUCKET ==========
resource "aws_s3_bucket" "s3_website_bucket" {
  bucket        = "website-files-incognito-bucket-korabel"
  force_destroy = true
}

resource "aws_s3_bucket_website_configuration" "s3_website_config" {
  bucket = aws_s3_bucket.s3_website_bucket.id
  index_document {
    suffix = "index.html"
  }
  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_public_access_block" "website_public_access_block" {
  bucket                  = aws_s3_bucket.s3_website_bucket.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.s3_website_bucket.id

  # Bucket policy to allow public read access to files (if required for your use case)
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "arn:aws:s3:::${aws_s3_bucket.s3_website_bucket.bucket}/*"
      }
    ]
  })
}

# ========== STATIC FILES BUCKET ==========

# Creates an S3 bucket resource
resource "aws_s3_bucket" "s3_bucket" {
  bucket = var.files-bucket-name

  force_destroy = true
}

# Configures server-side encryption for the S3 bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "sse-conf" {
  bucket = aws_s3_bucket.s3_bucket.id

  # Applies server-side encryption by default using AES256 algorithm
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }

    # Enables bucket key
    bucket_key_enabled = true
  }
}

# Configures versioning for the S3 bucket
resource "aws_s3_bucket_versioning" "versioning_conf" {
  bucket = aws_s3_bucket.s3_bucket.id

  # Disables versioning
  versioning_configuration {
    status = "Disabled"
  }
}

# Configures public access block for the S3 bucket
resource "aws_s3_bucket_public_access_block" "public_access_block" {
  bucket = aws_s3_bucket.s3_bucket.id

  # Blocks public access to ACLs and policies
  block_public_acls   = true
  block_public_policy = true

  # Ignores public ACLs
  ignore_public_acls = true

  # Restricts public access to buckets
  restrict_public_buckets = true
}

# Configures ownership controls for the S3 bucket
resource "aws_s3_bucket_ownership_controls" "example" {
  bucket = aws_s3_bucket.s3_bucket.id

  # Specifies object ownership
  rule {
    object_ownership = var.bucket-ovnership
  }
}
