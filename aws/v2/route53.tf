resource "aws_acm_certificate" "twilifyWebsiteCert" {
  domain_name       = var.r53_subdomain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

## Adds CNAME record to R53 zone to prove domain ownership for ACM certificate validation
resource "aws_route53_record" "twilifyCertValidation" {
  for_each = {
    for dvo in aws_acm_certificate.twilifyWebsiteCert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }

  zone_id = var.r53_zone_id
  name    = each.value.name
  type    = each.value.type
  records = [each.value.record]
  ttl     = 60
}

resource "aws_route53_record" "twilifyWebsiteAlias" {
  zone_id = var.r53_zone_id
  name    = var.r53_subdomain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.twilifyWebsiteDistribution.domain_name
    zone_id                = aws_cloudfront_distribution.twilifyWebsiteDistribution.hosted_zone_id
    evaluate_target_health = false
  }
}
