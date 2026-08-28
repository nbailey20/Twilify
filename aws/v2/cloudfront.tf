// CloudFront distribution for the website
resource "aws_cloudfront_distribution" "twilifyWebsiteDistribution" {
  origin {
    domain_name              = aws_s3_bucket.twilifyBucket.bucket_regional_domain_name
    origin_id                = "Twilify-S3-frontend-origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
    s3_origin_config {
      origin_access_identity = "" # REQUIRED when using OAC
    }
  }

  origin {
    domain_name = replace(aws_apigatewayv2_api.twilifyApi.api_endpoint, "https://", "")
    origin_id   = "Twilify-APIGW-backend-origin"
    origin_path = ""
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Twilify website distribution"
  default_root_object = "index.html"

  default_cache_behavior {
    target_origin_id       = "Twilify-S3-frontend-origin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    cache_policy_id        = var.cloudfront_cache_policy_id

    # function_association {
    #   event_type   = "viewer-request"
    #   function_arn = aws_cloudfront_function.path_guard.arn
    # }
  }

  ordered_cache_behavior {
    path_pattern             = "api/*"
    target_origin_id         = "Twilify-APIGW-backend-origin"
    allowed_methods          = ["GET", "HEAD", "POST", "OPTIONS", "PUT", "PATCH", "DELETE"]
    cached_methods           = ["GET", "HEAD", "OPTIONS"]
    cache_policy_id          = var.cloudfront_cache_policy_id
    viewer_protocol_policy   = "redirect-to-https"
    origin_request_policy_id = var.cloudfront_origin_policy_id

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.twilifyCloudfrontFunctionStripPathPrefix.arn
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.twilifyWebsiteCert.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations        = []
    }
  }

  aliases = [var.r53_subdomain_name]
}

resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "twilify-s3-oac"
  description                       = "Access control for S3"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# resource "aws_cloudfront_function" "twilifyCloudfrontFunctionPathGuard" {
#   name    = "twilify-app-path-guard"
#   runtime = "cloudfront-js-1.0"

#   code = <<EOF
# function handler(event) {
#   var request = event.request;
#   var uri = request.uri;

#   var prefix = '${var.cloudfront_url_obfuscation_string}';

#   // Block everything outside prefix
#   if (!uri.startsWith('/'+prefix+'/')) {
#     return {
#       statusCode: 404,
#       statusDescription: 'Not Found'
#     };
#   }

#   // Strip prefix before sending to origin
#   var newUri = uri.substring(prefix.length+1);

#   // Default to index.html
#   if (newUri === '' || newUri === '/') {
#     newUri = '/index.html';
#   }

#   request.uri = newUri;

#   return request;
# }
# EOF
# }

resource "aws_cloudfront_function" "twilifyCloudfrontFunctionStripPathPrefix" {
  name    = "twilify-app-strip-path-prefix"
  runtime = "cloudfront-js-1.0"
  code    = <<EOF
function handler(event) {
  var request = event.request;
  if (request.uri.startsWith('/api/')) {
    request.uri = request.uri.substring('/api'.length);
  }
  return request;
}
EOF
}
