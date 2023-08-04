data "aws_iam_policy_document" "twilifyAppLambdaIamPolicyDocument" {
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
        resources = ["${aws_s3_bucket.songbankBucket.arn}/*"]
    }
    statement {
        effect = "Allow"
        actions = [
            "s3:ListBucket"
        ]
        resources = [aws_s3_bucket.songbankBucket.arn]
    }
    statement {
        effect = "Allow"
        actions = ["ssm:GetParameter"]
        resources = [aws_ssm_parameter.spotify_refresh_token.arn]
    }
    statement {
        effect = "Allow"
        actions = [
            "kms:Decrypt",
            "kms:Encrypt",
            "kms:GenerateDataKey"
        ]
        resources = [aws_kms_key.twilify_kms_key.arn]
    }
}


data "aws_iam_policy_document" "twilifyReceptionLambdaIamPolicyDocument" {
    statement {
        effect = "Allow"
        actions = ["logs:CreateLogGroup"]
        resources = ["arn:aws:logs:${var.aws_region}:${var.aws_account_id}:*"]
    }
    statement {
        effect = "Allow"
        actions = [
            "logs:CreateLogStream",
            "logs:PutLogEvents"
        ]
        resources = [
            "arn:aws:logs:${var.aws_region}:${var.aws_account_id}:log-group:/aws/lambda/twilify-reception:*"
        ]
    }
    statement {
        effect = "Allow"
        actions = [
            "kms:Decrypt",
            "kms:Encrypt"
        ]
        resources = [aws_kms_key.twilify_kms_key.arn]
    }
    statement {
        effect = "Allow"
        actions = ["lambda:InvokeFunction"]
        resources = [aws_lambda_function.twilifyAppLambda.arn]
    }
}
