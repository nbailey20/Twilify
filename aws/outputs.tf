## Outputs to configure Twilio phone number webhook URL for incoming messages
output "twilify-invoke-url" {
  value = aws_lambda_function_url.twilifyReceptionLambdaFunctionUrl.function_url
}

output "account_sid" {
  value = var.twilio_account_sid
  sensitive = true
}

output "number_sid" {
  value = var.twilio_number_sid
  sensitive = true
}

output "token" {
  value = var.twilio_auth_token
  sensitive = true
}

output "twilio_number" {
  value = var.twilio_number
}
