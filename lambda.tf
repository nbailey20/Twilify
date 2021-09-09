resource "aws_iam_role" "tmfAppLambdaIamRole" {
  name = "tmf-lambda-app-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })

  inline_policy  {
    name = "tmf-app-lambda-logging-policy"
    policy = jsonencode(
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "logs:CreateLogGroup",
            "Resource": "arn:aws:logs:${var.aws_region}:${var.aws_account_id}:*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": [
                "arn:aws:logs:${var.aws_region}:${var.aws_account_id}:log-group:/aws/lambda/tmf:*"
            ]
        }
    ]
}
    )
  } 

  inline_policy {
    name = "tmf-app-lambda-s3-policy"
    policy = jsonencode(
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:PutObject"
            ],
            "Resource": [
                "${aws_s3_bucket.songbankBucket.arn}/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket"
            ],
            "Resource": [
                aws_s3_bucket.songbankBucket.arn
            ]
        },
    ]
}
    )
  }

  inline_policy {
    name = "tmf-app-lambda-parameter-store-policy"
    policy = jsonencode (
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "",
            "Effect": "Allow",
            "Action": [
              "ssm:GetParameter",
              "ssm:PutParameter"
            ],
            "Resource": [
                aws_ssm_parameter.spotify_refresh_token.arn
            ]
        }
    ]
}
    )
  }

  inline_policy {
    name = "tmf-app-lambda-kms-policy"
    policy = jsonencode (
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "",
            "Effect": "Allow",
            "Action": [
              "kms:Decrypt",
              "kms:Encrypt",
              "kms:GenerateDataKey"
            ],
            "Resource": [
                aws_kms_key.tmf_kms_key.arn
            ]
        }
    ]
}
    )
  }
}





resource "aws_iam_role" "tmfReceptionLambdaIamRole" {
  name = "tmf-lambda-reception-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })

  inline_policy  {
    name = "tmf-reception-lambda-logging-policy"
    policy = jsonencode(
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "logs:CreateLogGroup",
            "Resource": "arn:aws:logs:${var.aws_region}:${var.aws_account_id}:*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": [
                "arn:aws:logs:${var.aws_region}:${var.aws_account_id}:log-group:/aws/lambda/tmf-reception:*"
            ]
        }
    ]
}
    )
  }

  inline_policy {
    name = "tmf-reception-lambda-kms-policy"
    policy = jsonencode (
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "",
            "Effect": "Allow",
            "Action": [
              "kms:Decrypt",
              "kms:Encrypt"
            ],
            "Resource": [
                aws_kms_key.tmf_kms_key.arn
            ]
        }
    ]
}
    )
  }

  inline_policy {
    name = "tmf-reception-lambda-invoke-policy"
    policy = jsonencode(
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "",
            "Effect": "Allow",
            "Action": [
		          "lambda:InvokeFunction"
            ],
            "Resource": [
                aws_lambda_function.tmfAppLambda.arn
            ]
        }
    ]
}
    )
  }
}


resource "aws_lambda_function" "tmfReceptionLambda" {
  depends_on    = [time_sleep.wait_10_seconds1]
  s3_bucket     = aws_s3_bucket.setupBucket.id
  s3_key        = "tmf-reception-lambda.zip"
  function_name = "tmf-reception"
  role          = aws_iam_role.tmfReceptionLambdaIamRole.arn
  handler       = "reception.lambda_handler"
  timeout       = 6
  runtime       = "python3.6"
  kms_key_arn   = aws_kms_key.tmf_kms_key.arn
  environment {
    variables = {
      user_number                    = var.user_number
      twilio_number                  = var.twilio_number
      twilio_account_sid             = var.twilio_account_sid
      twilio_auth_token              = var.twilio_auth_token 
      tmf_app_lambda_arn             = "${aws_lambda_function.tmfAppLambda.arn}:$LATEST"
      num_songs_in_playlist          = var.num_songs_in_playlist
      debug                          = var.debug
    }
  }
}


resource "aws_lambda_function" "tmfAppLambda" {
  depends_on    = [time_sleep.wait_10_seconds2]
  s3_bucket     = aws_s3_bucket.setupBucket.id
  s3_key        = "tmf-app-lambda.zip"
  function_name = "tmf"
  role          = aws_iam_role.tmfAppLambdaIamRole.arn
  handler       = "tmf.lambda_handler"
  timeout       = 60
  runtime       = "python3.6"
  kms_key_arn   = aws_kms_key.tmf_kms_key.arn
  environment {
    variables = {
      spotify_client_id              = var.spotify_client_id
      spotify_client_secret          = var.spotify_client_secret
      refresh_token_parameter_name   = aws_ssm_parameter.spotify_refresh_token.name
      refresh_token_kms_key_arn      = aws_kms_key.tmf_kms_key.arn
      rec_limit                      = var.rec_limit
      bucket_name                    = aws_s3_bucket.songbankBucket.bucket
      songbank_file_name             = var.songbank_file_name
      spotify_user                   = var.spotify_user
      playlist_name                  = var.playlist_name
      #neutral_song_refresh_rate      = var.neutral_song_refresh_rate
      twilio_account_sid             = var.twilio_account_sid
      twilio_auth_token              = var.twilio_auth_token
      twilio_number                  = var.twilio_number
      user_number                    = var.user_number
      num_songs_in_playlist          = var.num_songs_in_playlist
      songbank_cycles_before_rebuild = var.songbank_cycles_before_rebuild
      debug                          = var.debug
    }
  }
}


resource "aws_lambda_function_event_invoke_config" "tmfAppLambdaDestination" {
  function_name = aws_lambda_function.tmfAppLambda.function_name
  maximum_retry_attempts = 0
}
