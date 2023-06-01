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
  rest_api_id = aws_api_gateway_rest_api.tmfApi.id

  triggers = {
    # NOTE: The configuration below will satisfy ordering considerations,
    #       but not pick up all future REST API changes. More advanced patterns
    #       are possible, such as using the filesha1() function against the
    #       Terraform configuration file(s) or removing the .id references to
    #       calculate a hash against whole resources. Be aware that using whole
    #       resources will show a difference after the initial implementation.
    #       It will stabilize to only change when resources change afterwards.
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.tmfApiResource,
      aws_api_gateway_method.tmfApiMethod,
      aws_api_gateway_integration.tmfApiIntegration,
      aws_api_gateway_method_response.tmfSuccessMethodResponse,
      aws_api_gateway_integration_response.tmfSuccessIntegrationResponse
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "tmfApiStage" {
  deployment_id = aws_api_gateway_deployment.tmfApiDeployment.id
  rest_api_id   = aws_api_gateway_rest_api.tmfApi.id
  stage_name    = "dev"
}
