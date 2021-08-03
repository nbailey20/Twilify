terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "3.30.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}


resource "aws_vpc" "vpc" {
  cidr_block       = "10.41.0.0/24"
  tags = {
    Name = "tmf-vpc"
  }
}

resource "aws_subnet" "privateSubnet1" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.41.0.128/26"
  availability_zone = "us-east-1a"
  tags = {
    Name = "tmf-private-subnet-1"
  }
}

resource "aws_subnet" "privateSubnet2" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.41.0.192/26"
  availability_zone = "us-east-1b"
  tags = {
    Name = "tmf-private-subnet-2"
  }
}

resource "aws_subnet" "publicSubnet" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.41.0.0/25"
  availability_zone = "us-east-1c"
  tags = {
    Name = "tmf-public-subnet"
  }
}

resource "aws_route_table" "privateRt" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "tmf-private-rt"
  }
}

resource "aws_route_table" "publicRt" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "tmf-public-rt"
  }
}

resource "aws_route_table_association" "privateRtAssociation1" {
  subnet_id      = aws_subnet.privateSubnet1.id
  route_table_id = aws_route_table.privateRt.id
}

resource "aws_route_table_association" "privateRtAssociation2" {
  subnet_id      = aws_subnet.privateSubnet2.id
  route_table_id = aws_route_table.privateRt.id
}

resource "aws_route_table_association" "publicRtAssociation" {
  subnet_id      = aws_subnet.publicSubnet.id
  route_table_id = aws_route_table.publicRt.id
}

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





resource "aws_s3_bucket" "songbankBucket" {
  acl = "private"
  bucket_prefix = "tmf-songbank"
  tags = {
    Name = "TMF Songbank Bucket"
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
  bucket_prefix = "tmf-setup"
  tags = {
    Name = "TMF Setup Bucket"
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
  content = jsonencode({"refreshToken": var.refresh_token})
}

resource "aws_s3_bucket_object" "tmfNetworkCft" {
  bucket  = aws_s3_bucket.setupBucket.id
  key     = "tmf-network-setup.template"
  content = jsonencode( 
{
    "AWSTemplateFormatVersion": "2010-09-09",
    "Resources": {
        "ElasticIP": {
            "Type": "AWS::EC2::EIP",
            "Properties": {
                "Domain": "vpc",
                "Tags": [
                    {
                        "Key": "Name",
                        "Value": "tmf-eip"
                    }
                ]
            }
        },
        "NatGateway": {
            "Type": "AWS::EC2::NatGateway",
            "Properties": {
                "AllocationId": {
                    "Fn::GetAtt": [
                        "ElasticIP",
                        "AllocationId"
                    ]
                },
                "SubnetId": aws_subnet.publicSubnet.id,
                "Tags": [
                    {
                        "Key": "Name",
                        "Value": "tmf-nat-gw"
                    }
                ]
            }
        },
        "IGW": {
            "Type": "AWS::EC2::InternetGateway",
            "Properties": {
                "Tags": [
                    {
                        "Key": "Name",
                        "Value": "tmf-igw"
                    }
                ]
            }
        },
        "AttachIGW": {
            "Type": "AWS::EC2::VPCGatewayAttachment",
            "Properties": {
                "VpcId": aws_vpc.vpc.id,
                "InternetGatewayId": {
                    "Ref": "IGW"
                }
            }
        },
        "PrivateNatGwRoute": {
            "Type": "AWS::EC2::Route",
            "Properties": {
                "RouteTableId": aws_route_table.privateRt.id,
                "DestinationCidrBlock": "0.0.0.0/0",
                "NatGatewayId": {
                    "Ref": "NatGateway"
                }
            }
        },
        "IgwRoute": {
            "Type": "AWS::EC2::Route",
            "DependsOn": "AttachIGW",
            "Properties": {
                "RouteTableId": aws_route_table.publicRt.id,
                "DestinationCidrBlock": "0.0.0.0/0",
                "GatewayId": {
                    "Ref": "IGW"
                }
            }
        }
    }
} 
  )
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



resource "aws_lambda_function" "tmfReceptionLambda" {
  depends_on    = [time_sleep.wait_10_seconds1]
  s3_bucket     = aws_s3_bucket.setupBucket.id
  s3_key        = "tmf-reception-lambda.zip"
  function_name = "tmf-reception"
  role          = aws_iam_role.tmfReceptionLambdaIamRole.arn
  handler       = "reception.lambda_handler"
  timeout       = 5
  runtime       = "python3.6"
  environment {
    variables = {
      twilio_account_sid = var.twilio_account_sid
      twilio_auth_token  = var.twilio_auth_token
      s3_template_url    = "https://s3.amazonaws.com/${aws_s3_bucket.setupBucket.id}/${aws_s3_bucket_object.tmfNetworkCft.key}"
      user_number        = var.user_number
      twilio_number      = var.twilio_number
      sns_topic_arn      = aws_sns_topic.tmfSnsTopic.arn 
      tmf_app_lambda_arn = "${aws_lambda_function.tmfAppLambda.arn}:$LATEST"
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
  timeout       = 40
  runtime       = "python3.6"
  vpc_config {
    security_group_ids = [aws_security_group.lambdaSg.id]
    subnet_ids         = [aws_subnet.privateSubnet1.id, aws_subnet.privateSubnet2.id]
  }
  environment {
    variables = {
      client_id                      = var.client_id
      client_secret                  = var.client_secret
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


resource "aws_api_gateway_rest_api" "tmfApi" {
  name        = "tmf-api"
  description = "API to accept Twilio SMS webhook POST requests for TMF" 
}


resource "aws_lambda_permission" "tmfReceptionLambdaApiGwPermission" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.tmfReceptionLambda.function_name
  principal     = "apigateway.amazonaws.com"

  # The /*/*/* part allows invocation from any stage, method and resource path
  # within API Gateway REST API.
  source_arn = "${aws_api_gateway_rest_api.tmfApi.execution_arn}/*/POST/tmf"
}

resource "aws_api_gateway_resource" "tmfApiResource" {
  rest_api_id = aws_api_gateway_rest_api.tmfApi.id
  parent_id   = aws_api_gateway_rest_api.tmfApi.root_resource_id
  path_part   = "tmf"
}

resource "aws_api_gateway_method" "tmfApiMethod" {
  rest_api_id   = aws_api_gateway_rest_api.tmfApi.id
  resource_id   = aws_api_gateway_resource.tmfApiResource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "tmfApiIntegration" {
  rest_api_id             = aws_api_gateway_rest_api.tmfApi.id
  resource_id             = aws_api_gateway_resource.tmfApiResource.id
  http_method             = aws_api_gateway_method.tmfApiMethod.http_method
  integration_http_method = aws_api_gateway_method.tmfApiMethod.http_method
  type                    = "AWS"
  uri                     = aws_lambda_function.tmfReceptionLambda.invoke_arn

  # Transforms the incoming URL-encoded request to JSON
  request_templates = {
    "application/x-www-form-urlencoded" = <<EOF
#set($httpPost = $input.path('$').split("&"))
{
#foreach( $kvPair in $httpPost )
 #set($kvTokenised = $kvPair.split("="))
 #if( $kvTokenised.size() > 1 )
   "$kvTokenised[0]" : "$kvTokenised[1]"#if( $foreach.hasNext ),#end
 #else
   "$kvTokenised[0]" : ""#if( $foreach.hasNext ),#end
 #end
#end
}
EOF
  }
}


resource "aws_api_gateway_method_response" "tmfSuccessMethodResponse" {
  rest_api_id     = aws_api_gateway_rest_api.tmfApi.id
  resource_id     = aws_api_gateway_resource.tmfApiResource.id
  http_method     = aws_api_gateway_method.tmfApiMethod.http_method
  response_models =  {
    "application/xml": "Empty"
  }
  status_code = "200"
}



resource "aws_api_gateway_integration_response" "tmfSuccessIntegrationResponse" {
  depends_on  = [aws_api_gateway_integration.tmfApiIntegration]
  rest_api_id = aws_api_gateway_rest_api.tmfApi.id
  resource_id = aws_api_gateway_resource.tmfApiResource.id
  http_method = aws_api_gateway_method.tmfApiMethod.http_method
  status_code = aws_api_gateway_method_response.tmfSuccessMethodResponse.status_code

  # Transforms the backend JSON response to XML
  response_templates = {
    "application/xml" = <<EOF
$input.path('$')
EOF
  }
}


resource "aws_api_gateway_deployment" "tmfApiDeployment" {
  depends_on  = [
    aws_api_gateway_method.tmfApiMethod,
    aws_api_gateway_integration.tmfApiIntegration
  ]
  rest_api_id = aws_api_gateway_rest_api.tmfApi.id
}

resource "aws_api_gateway_stage" "tmfApiStage" {
  deployment_id = aws_api_gateway_deployment.tmfApiDeployment.id
  rest_api_id   = aws_api_gateway_rest_api.tmfApi.id
  stage_name    = "dev"
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


## Outputs to configure Twilio phone number webhook URL for incoming messages
output "tmf-invoke-url" {
  value = "${aws_api_gateway_stage.tmfApiStage.invoke_url}/${aws_api_gateway_resource.tmfApiResource.path_part}"
}

output "account_sid" {
  value = var.twilio_account_sid
}

output "number_sid" {
  value = var.twilio_number_sid
}

output "token" {
  value = var.twilio_auth_token
}
