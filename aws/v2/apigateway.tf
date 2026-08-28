// API Gateway to expose the Lambda function as an API endpoint
resource "aws_apigatewayv2_api" "twilifyApi" {
  name          = "twilify-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "twilifyLambdaIntegration" {
  api_id             = aws_apigatewayv2_api.twilifyApi.id
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.twilifyLambda.invoke_arn
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "twilifyAuthcheckRoute" {
  api_id    = aws_apigatewayv2_api.twilifyApi.id
  route_key = "GET /auth-check"
  target    = "integrations/${aws_apigatewayv2_integration.twilifyLambdaIntegration.id}"
}

resource "aws_apigatewayv2_route" "twilifyCallbackRoute" {
  api_id    = aws_apigatewayv2_api.twilifyApi.id
  route_key = "GET /callback"
  target    = "integrations/${aws_apigatewayv2_integration.twilifyLambdaIntegration.id}"
}

resource "aws_apigatewayv2_route" "twilifySpotifyRoute" {
  api_id    = aws_apigatewayv2_api.twilifyApi.id
  route_key = "POST /generate-playlist"
  target    = "integrations/${aws_apigatewayv2_integration.twilifyLambdaIntegration.id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.twilifyApi.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_apigatewayv2_authorizer" "twilifyCognitoAuthorizer" {
  api_id          = aws_apigatewayv2_api.twilifyApi.id
  name            = "CognitoAuthorizer"
  authorizer_type = "JWT"

  identity_sources = ["$request.header.Authorization"]

  jwt_configuration {
    audience = [aws_cognito_user_pool_client.twilifyUserPoolClient.id]
    issuer   = "https://cognito-idp.${var.aws_region}.amazonaws.com/${aws_cognito_user_pool.twilifyUserPool.id}"
  }
}
