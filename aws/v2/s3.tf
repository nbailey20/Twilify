resource "aws_s3_bucket" "twilifyBucket" {
  bucket_prefix = "twilify-"
  tags = {
    Name = "Twilify S3 Bucket"
  }
}

resource "aws_s3_bucket_public_access_block" "twilifyBucketAccessBlock" {
  bucket                  = aws_s3_bucket.twilifyBucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "twilifyBucketSSE" {
  bucket = aws_s3_bucket.twilifyBucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256" ## nothing confidential here, save a few bucks and use AES256 instead of KMS
    }
  }
}

## Use OAC to securely allow CloudFront to access S3 bucket without making it public
resource "aws_s3_bucket_policy" "twilifyBucketPolicy" {
  bucket = aws_s3_bucket.twilifyBucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          "Service" : "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.twilifyBucket.arn}/*"
        Condition = {
          StringEquals = {
            "aws:SourceArn" = aws_cloudfront_distribution.twilifyWebsiteDistribution.arn
          }
        }
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.twilifyBucketAccessBlock]
}

resource "aws_s3_object" "twilifyLambdaZip" {
  bucket      = aws_s3_bucket.twilifyBucket.id
  key         = "twilify-lambda.zip"
  source      = local.twilify_lambda_zip
  source_hash = filebase64sha256(local.twilify_lambda_zip)
}

resource "aws_s3_object" "twilifySongbank" {
  bucket  = aws_s3_bucket.twilifyBucket.id
  key     = var.songbank_file_name
  content = jsonencode({})
}

resource "aws_s3_object" "twilifyIndexHtml" {
  bucket = aws_s3_bucket.twilifyBucket.id
  key    = "index.html"
  content = templatefile("${path.module}/src/index.html", {
    CLIENT_ID       = aws_cognito_user_pool_client.twilifyUserPoolClient.id
    COGNITO_DOMAIN  = "${aws_cognito_user_pool_domain.twilifyUserPoolDomain.domain}.auth.${var.aws_region}.amazoncognito.com"
    FRONTEND_DOMAIN = var.r53_subdomain_name
  })
  content_type = "text/html"
}
