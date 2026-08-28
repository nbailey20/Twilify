resource "aws_lambda_function" "twilifyLambda" {
  s3_bucket         = aws_s3_bucket.twilifyBucket.id
  s3_key            = aws_s3_object.twilifyLambdaZip.key
  s3_object_version = aws_s3_object.twilifyLambdaZip.version_id
  source_code_hash  = filebase64sha256(local.twilify_lambda_zip)
  function_name     = "twilify"
  role              = aws_iam_role.twilifyLambdaIamRole.arn
  handler           = "lambda_start.lambda_handler"
  timeout           = 60
  runtime           = "python3.14"
  environment {
    variables = {
      COGNITO_REDIRECT_URI = "https://${var.r53_subdomain_name}/api/callback"
      COGNITO_CLIENT_ID    = aws_cognito_user_pool_client.twilifyUserPoolClient.id
      COGNITO_USER_POOL_ID = aws_cognito_user_pool.twilifyUserPool.id
      COGNITO_TOKEN_URL    = "https://${aws_cognito_user_pool_domain.twilifyUserPoolDomain.domain}.auth.${var.aws_region}.amazoncognito.com/oauth2/token"
      FRONTEND_URL         = "https://${var.r53_subdomain_name}/"
      # spotify_client_id            = var.spotify_client_id
      # spotify_client_secret        = var.spotify_client_secret
      # refresh_token_parameter_name = aws_ssm_parameter.spotify_refresh_token.name
      # refresh_token_kms_key_arn    = aws_kms_key.twilify_kms_key.arn
      # spotify_user                 = var.spotify_user_id
      bucket_name           = aws_s3_bucket.twilifyBucket.bucket
      songbank_file_name    = var.songbank_file_name
      playlist_name         = var.spotify_playlist_name
      num_songs_in_playlist = var.num_songs_in_playlist
      debug                 = var.debug
    }
  }
}

## Do not attempt to asynchronously invoke lambda more than once - reception should respond with error
## Override default behavior of 2 attempts
resource "aws_lambda_function_event_invoke_config" "twilifyLambdaDestination" {
  function_name          = aws_lambda_function.twilifyLambda.function_name
  maximum_retry_attempts = 0
}

resource "aws_lambda_permission" "apigw_invoke" {
  for_each = toset(["generate-playlist", "callback", "auth-check"])

  statement_id  = "AllowAPIGatewayInvoke-${each.key}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.twilifyLambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.twilifyApi.execution_arn}/*/*/${each.key}"
}
