resource "aws_s3_bucket" "songbankBucket" {
  acl = "private"
  bucket_prefix = "tmf-songbank-"
  tags = {
    Name = "TMF Songbank Bucket"
  }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.tmf_kms_key.arn
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
  bucket_prefix = "tmf-setup-"
  tags = {
    Name = "TMF Setup Bucket"
  }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.tmf_kms_key.arn
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


resource "aws_s3_bucket_object" "tmfReceptionLambda" {
  bucket  = aws_s3_bucket.setupBucket.id
  key     = "tmf-reception-lambda.zip"
  source  = "./lambda/tmf-reception-lambda/tmf-reception-lambda.zip"
}

resource "aws_s3_bucket_object" "tmfAppLambda" {
  bucket  = aws_s3_bucket.setupBucket.id
  key     = "tmf-app-lambda.zip"
  source  = "./lambda/tmf-app-lambda/tmf-app-lambda.zip"
}

resource "aws_s3_bucket_object" "tmfAppSongbank" {
  bucket  = aws_s3_bucket.songbankBucket.id
  key     = var.songbank_file_name
  content = jsonencode({})
}


## Wait 10 seconds after uploading Lambda zip file before creating function
resource "time_sleep" "wait_10_seconds1" {
  depends_on = [
    aws_s3_bucket_object.tmfReceptionLambda
  ]

  create_duration = "10s"
}

resource "time_sleep" "wait_10_seconds2" {
  depends_on = [
    aws_s3_bucket_object.tmfAppLambda
  ]

  create_duration = "10s"
}
