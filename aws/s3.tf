resource "aws_s3_bucket" "songbankBucket" {
  acl = "private"
  bucket_prefix = "twilify-songbank-"
  tags = {
    Name = "Twilify Songbank Bucket"
  }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.twilify_kms_key.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }
}

resource "aws_s3_bucket_public_access_block" "songbankBucketAccessBlock" {
  bucket = aws_s3_bucket.songbankBucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket" "setupBucket" {
  acl = "private"
  bucket_prefix = "twilify-setup-"
  tags = {
    Name = "Twilify Setup Bucket"
  }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.twilify_kms_key.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }
}

resource "aws_s3_bucket_public_access_block" "setupBucketAccessBlock" {
  bucket = aws_s3_bucket.setupBucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


resource "aws_s3_bucket_object" "twilifyReceptionLambda" {
  bucket  = aws_s3_bucket.setupBucket.id
  key     = "twilify-reception-lambda.zip"
  source  = "./lambda/twilify-reception-lambda/twilify-reception-lambda.zip"
}

resource "aws_s3_bucket_object" "twilifyAppLambda" {
  bucket  = aws_s3_bucket.setupBucket.id
  key     = "twilify-app-lambda.zip"
  source  = "./lambda/twilify-app-lambda/twilify-app-lambda.zip"
}

resource "aws_s3_bucket_object" "twilifyAppSongbank" {
  bucket  = aws_s3_bucket.songbankBucket.id
  key     = var.songbank_file_name
  content = jsonencode({})
}


## Wait 10 seconds after uploading Lambda zip file before creating function
resource "time_sleep" "wait_10_seconds1" {
  depends_on = [
    aws_s3_bucket_object.twilifyReceptionLambda
  ]

  create_duration = "10s"
}

resource "time_sleep" "wait_10_seconds2" {
  depends_on = [
    aws_s3_bucket_object.twilifyAppLambda
  ]

  create_duration = "10s"
}
