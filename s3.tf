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
  content = jsonencode({})
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
