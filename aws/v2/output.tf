output "website_url" {
  description = "Subdomain pointing to the CloudFront distribution for the website"
  value       = "${var.r53_subdomain_name}/"
}

output "usernames" {
  description = "Username for the Cognito user pool"
  value       = var.twilify_usernames
}

output "temporary_password" {
  description = "Initial password for the Cognito user pool (must be changed on first login)"
  value       = var.twilify_temp_password
}
