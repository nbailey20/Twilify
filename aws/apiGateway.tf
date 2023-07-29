resource "aws_api_gateway_rest_api" "twilifyApi" {
  name        = "twilify-api"
  description = "API to accept SMS webhook POST requests from Twilio when text occurs" 
}


resource "aws_lambda_permission" "twilifyReceptionLambdaApiGwPermission" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.twilifyReceptionLambda.function_name
  principal     = "apigateway.amazonaws.com"

  # The /*/*/* part allows invocation from any stage, method and resource path
  # within API Gateway REST API.
  source_arn = "${aws_api_gateway_rest_api.twilifyApi.execution_arn}/*/POST/twilify"
}

resource "aws_api_gateway_resource" "twilifyApiResource" {
  rest_api_id = aws_api_gateway_rest_api.twilifyApi.id
  parent_id   = aws_api_gateway_rest_api.twilifyApi.root_resource_id
  path_part   = "twilify"
}

resource "aws_api_gateway_method" "twilifyApiMethod" {
  rest_api_id   = aws_api_gateway_rest_api.twilifyApi.id
  resource_id   = aws_api_gateway_resource.twilifyApiResource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "twilifyApiIntegration" {
  rest_api_id             = aws_api_gateway_rest_api.twilifyApi.id
  resource_id             = aws_api_gateway_resource.twilifyApiResource.id
  http_method             = aws_api_gateway_method.twilifyApiMethod.http_method
  integration_http_method = aws_api_gateway_method.twilifyApiMethod.http_method
  type                    = "AWS"
  uri                     = aws_lambda_function.twilifyReceptionLambda.invoke_arn

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


resource "aws_api_gateway_method_response" "twilifySuccessMethodResponse" {
  rest_api_id     = aws_api_gateway_rest_api.twilifyApi.id
  resource_id     = aws_api_gateway_resource.twilifyApiResource.id
  http_method     = aws_api_gateway_method.twilifyApiMethod.http_method
  response_models =  {
    "application/xml": "Empty"
  }
  status_code = "200"
}



resource "aws_api_gateway_integration_response" "twilifySuccessIntegrationResponse" {
  depends_on  = [aws_api_gateway_integration.twilifyApiIntegration]
  rest_api_id = aws_api_gateway_rest_api.twilifyApi.id
  resource_id = aws_api_gateway_resource.twilifyApiResource.id
  http_method = aws_api_gateway_method.twilifyApiMethod.http_method
  status_code = aws_api_gateway_method_response.twilifySuccessMethodResponse.status_code

  # Transforms the backend JSON response to XML
  response_templates = {
    "application/xml" = <<EOF
$input.path('$')
EOF
  }
}


resource "aws_api_gateway_deployment" "twilifyApiDeployment" {
  rest_api_id = aws_api_gateway_rest_api.twilifyApi.id

  triggers = {
    # NOTE: The configuration below will satisfy ordering considerations,
    #       but not pick up all future REST API changes. More advanced patterns
    #       are possible, such as using the filesha1() function against the
    #       Terraform configuration file(s) or removing the .id references to
    #       calculate a hash against whole resources. Be aware that using whole
    #       resources will show a difference after the initial implementation.
    #       It will stabilize to only change when resources change afterwards.
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.twilifyApiResource,
      aws_api_gateway_method.twilifyApiMethod,
      aws_api_gateway_integration.twilifyApiIntegration,
      aws_api_gateway_method_response.twilifySuccessMethodResponse,
      aws_api_gateway_integration_response.twilifySuccessIntegrationResponse
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "twilifyApiStage" {
  deployment_id = aws_api_gateway_deployment.twilifyApiDeployment.id
  rest_api_id   = aws_api_gateway_rest_api.twilifyApi.id
  stage_name    = "dev"
}
