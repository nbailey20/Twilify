resource "aws_lambda_function" "twilifyReceptionLambda" {
  depends_on    = [time_sleep.wait_10_seconds1] ## ensure S3 object is completely uploaded
  s3_bucket     = aws_s3_bucket.setupBucket.id
  s3_key        = "twilify-reception-lambda.zip"
  function_name = "twilify-reception"
  role          = aws_iam_role.twilifyReceptionLambdaIamRole.arn
  handler       = "reception.lambda_handler"
  timeout       = 6
  runtime       = "python3.11"
  kms_key_arn   = aws_kms_key.twilify_kms_key.arn
  environment {
    variables = {
      allowed_source_numbers = var.allowed_source_numbers
      twilio_number          = var.twilio_number
      twilio_account_sid     = var.twilio_account_sid
      twilio_auth_token      = var.twilio_auth_token 
      twilify_app_lambda_arn = "${aws_lambda_function.twilifyAppLambda.arn}:$LATEST"
      num_songs_in_playlist  = var.num_songs_in_playlist
      debug                  = var.debug
    }
  }
}

resource "aws_lambda_function" "twilifyAppLambda" {
  depends_on    = [time_sleep.wait_10_seconds2] ## ensure S3 object is completely uploaded
  s3_bucket     = aws_s3_bucket.setupBucket.id
  s3_key        = "twilify-app-lambda.zip"
  function_name = "twilify"
  role          = aws_iam_role.twilifyAppLambdaIamRole.arn
  handler       = "twilify.lambda_handler"
  timeout       = 60
  runtime       = "python3.11"
  kms_key_arn   = aws_kms_key.twilify_kms_key.arn
  environment {
    variables = {
      spotify_client_id            = var.spotify_client_id
      spotify_client_secret        = var.spotify_client_secret
      refresh_token_parameter_name = aws_ssm_parameter.spotify_refresh_token.name
      refresh_token_kms_key_arn    = aws_kms_key.twilify_kms_key.arn
      bucket_name                  = aws_s3_bucket.songbankBucket.bucket
      songbank_file_name           = var.songbank_file_name
      spotify_user                 = var.spotify_user_id
      playlist_name                = var.spotify_playlist_name
      twilio_account_sid           = var.twilio_account_sid
      twilio_auth_token            = var.twilio_auth_token
      twilio_number                = var.twilio_number
      num_songs_in_playlist        = var.num_songs_in_playlist
      debug                        = var.debug
    }
  }
}

## Do not attempt to asynchronously invoke app lambda more than once - it should text if error
## Override default behavior of 2 attempts
resource "aws_lambda_function_event_invoke_config" "twilifyAppLambdaDestination" {
  function_name          = aws_lambda_function.twilifyAppLambda.function_name
  maximum_retry_attempts = 0
}

resource "aws_lambda_function_url" "twilifyReceptionLambdaFunctionUrl" {
  function_name      = aws_lambda_function.twilifyReceptionLambda.function_name
  authorization_type = "NONE"
}

resource "aws_lambda_permission" "allow_anonymous_reception_invocation" {
  action                 = "lambda:InvokeFunctionUrl"
  function_name          = aws_lambda_function.twilifyReceptionLambda.function_name
  principal              = "*"
  function_url_auth_type = "NONE"
}
