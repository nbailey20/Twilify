## Outputs to configure Twilio phone number webhook URL for incoming messages
output "twilify-invoke-url" {
  value = google_cloudfunctions_function.twilify_reception_function.https_trigger_url
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
