resource "aws_iam_role" "twilifyAppLambdaIamRole" {
  name = "twilify-lambda-app-role"
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
      }
    ]
  })
}

resource "aws_iam_role" "twilifyReceptionLambdaIamRole" {
  name = "twilify-lambda-reception-role"
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
      }
    ]
  })
}


resource "aws_iam_policy" "twilifyAppLambdaIamPolicy" {
  name   = "twilify-lambda-app-policy"
  policy = data.aws_iam_policy_document.twilifyAppLambdaIamPolicyDocument.json
}

resource "aws_iam_policy" "twilifyReceptionLambdaIamPolicy" {
  name   = "twilify-lambda-reception-policy"
  policy = data.aws_iam_policy_document.twilifyReceptionLambdaIamPolicyDocument.json
}


resource "aws_iam_role_policy_attachment" "twilifyAppLambdaIamPolicyAttachment" {
  role       = aws_iam_role.twilifyAppLambdaIamRole.name
  policy_arn = aws_iam_policy.twilifyAppLambdaIamPolicy.arn
}

resource "aws_iam_role_policy_attachment" "twilifyReceptionLambdaIamPolicyAttachment" {
  role       = aws_iam_role.twilifyReceptionLambdaIamRole.name
  policy_arn = aws_iam_policy.twilifyReceptionLambdaIamPolicy.arn
}
