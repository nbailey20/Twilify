data "aws_iam_policy_document" "twilifyLambdaIamPolicyDocument" {
  statement {
    effect    = "Allow"
    actions   = ["logs:CreateLogGroup"]
    resources = ["arn:aws:logs:${var.aws_region}:${var.aws_account_id}:*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "arn:aws:logs:${var.aws_region}:${var.aws_account_id}:log-group:/aws/lambda/twilify:*"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject"
    ]
    resources = ["${aws_s3_bucket.twilifyBucket.arn}/*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket"
    ]
    resources = [aws_s3_bucket.twilifyBucket.arn]
  }
  statement {
    effect    = "Allow"
    actions   = ["ssm:GetParameter"]
    resources = ["arn:aws:ssm:${var.aws_region}:${var.aws_account_id}:parameter${var.spotify_token_param_path}/*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:Encrypt",
      "kms:GenerateDataKey"
    ]
    resources = [
      "arn:aws:kms:${var.aws_region}:${var.aws_account_id}:alias/aws/s3",
      "arn:aws:kms:${var.aws_region}:${var.aws_account_id}:alias/aws/ssm"
    ]
  }
}


# data "aws_iam_policy_document" "twilifyReceptionLambdaIamPolicyDocument" {
#   statement {
#     effect    = "Allow"
#     actions   = ["logs:CreateLogGroup"]
#     resources = ["arn:aws:logs:${var.aws_region}:${var.aws_account_id}:*"]
#   }
#   statement {
#     effect = "Allow"
#     actions = [
#       "logs:CreateLogStream",
#       "logs:PutLogEvents"
#     ]
#     resources = [
#       "arn:aws:logs:${var.aws_region}:${var.aws_account_id}:log-group:/aws/lambda/twilify-reception:*"
#     ]
#   }
#   # statement {
#   #     effect = "Allow"
#   #     actions = [
#   #         "kms:Decrypt",
#   #         "kms:Encrypt"
#   #     ]
#   #     resources = [aws_kms_key.twilify_kms_key.arn]
#   # }
#   statement {
#     effect    = "Allow"
#     actions   = ["lambda:InvokeFunction"]
#     resources = [aws_lambda_function.twilifyLambda.arn]
#   }
# }
