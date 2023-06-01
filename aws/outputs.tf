## Outputs to configure Twilio phone number webhook URL for incoming messages
output "tmf-invoke-url" {
  value = "${aws_api_gateway_stage.tmfApiStage.invoke_url}/${aws_api_gateway_resource.tmfApiResource.path_part}"
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
