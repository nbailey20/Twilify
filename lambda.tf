resource "aws_security_group" "lambdaSg" {
  name        = "tmf-lambda-sg"
  vpc_id      = aws_vpc.vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

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
        }
    ]
}
    )
  }

  inline_policy {
    name = "tmf-app-lambda-vpc-policy"
    policy = jsonencode(
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:CreateNetworkInterface",
                "ec2:DeleteNetworkInterface",
                "ec2:DescribeNetworkInterfaces"
            ],
            "Resource": "*"
        }
    ]
}
    )
  }

  inline_policy {
    name = "tmf-app-lambda-function-policy"
    policy = jsonencode (
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "",
            "Effect": "Allow",
            "Action": "lambda:InvokeFunction",
            "Resource": [
                "arn:aws:lambda:${var.aws_region}:${var.aws_account_id}:function:tmf-reception*"
            ]
        }
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
    name = "tmf-reception-lambda-s3-policy"
    policy = jsonencode(
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "",
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:GetObject",
            ],
            "Resource": [
                "${aws_s3_bucket.setupBucket.arn}/*"
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
    name = "tmf-reception-lambda-parameter-store-policy"
    policy = jsonencode(
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
                aws_ssm_parameter.playlist_text_params.arn,
                aws_ssm_parameter.network_keep_alive.arn
            ]
        }
    ]
}
    )
  }

  inline_policy {
    name = "tmf-reception-lambda-network-cft-policy"
    policy = jsonencode(
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "",
            "Effect": "Allow",
            "Action": [
                "cloudformation:CreateStack",
		"cloudformation:DescribeStacks",
		"cloudformation:DeleteStack",
                "ec2:CreateInternetGateway",
		"ec2:allocateAddress",
		"ec2:DescribeInternetGateways",
		"ec2:DeleteInternetGateway",
		"ec2:describeAddresses",
		"ec2:createTags",
		"ec2:releaseAddress",
		"ec2:AttachInternetGateway",
		"ec2:CreateNatGateway",
		"ec2:DetachInternetGateway",
		"ec2:DescribeRouteTables",
		"ec2:DescribeNatGateways",
		"ec2:DeleteNatGateway",
		"ec2:CreateRoute",
		"ec2:DeleteRoute",
		"sns:Publish",
		"lambda:InvokeFunction"
		
            ],
            "Resource": [
                "*"
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
  timeout       = 50
  runtime       = "python3.6"
  kms_key_arn   = aws_kms_key.tmf_kms_key.arn
  environment {
    variables = {
      s3_template_url                = "https://s3.amazonaws.com/${aws_s3_bucket.setupBucket.id}/${aws_s3_bucket_object.tmfNetworkCft.key}"
      user_number                    = var.user_number
      twilio_number                  = var.twilio_number
      sns_topic_arn                  = aws_sns_topic.tmfSnsTopic.arn 
      tmf_app_lambda_arn             = "${aws_lambda_function.tmfAppLambda.arn}:$LATEST"
      num_songs_in_playlist          = var.num_songs_in_playlist
      playlist_params_parameter_name = aws_ssm_parameter.playlist_text_params.name
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
  timeout       = 180
  runtime       = "python3.6"
  kms_key_arn   = aws_kms_key.tmf_kms_key.arn
  vpc_config {
    security_group_ids = [aws_security_group.lambdaSg.id]
    subnet_ids         = [aws_subnet.privateSubnet1.id, aws_subnet.privateSubnet2.id]
  }
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
      neutral_song_refresh_rate      = var.neutral_song_refresh_rate
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

  destination_config {
    on_failure {
      destination = aws_lambda_function.tmfReceptionLambda.arn
    }

    on_success {
      destination = aws_lambda_function.tmfReceptionLambda.arn
    }
  }
}


resource "aws_sns_topic" "tmfSnsTopic" {
  name = "tmf-network-stack-sns-topic"
}

resource "aws_sns_topic_subscription" "tmfReceptionSnsSub" {
  topic_arn = aws_sns_topic.tmfSnsTopic.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.tmfReceptionLambda.arn
}

resource "aws_lambda_permission" "tmfReceptionLambdaSnsPermission" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.tmfReceptionLambda.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.tmfSnsTopic.arn
}
