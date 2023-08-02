variable aws_account_id {}
variable aws_region {}

variable "spotify_user_id" {}
variable "spotify_client_id" {}
variable "spotify_client_secret" {}
variable "spotify_refresh_token" {}
variable "spotify_playlist_name" {
  default = "Twilify"
}
variable "num_songs_in_playlist" {
  default = 20
}

variable "twilio_account_sid" {}
variable "twilio_auth_token" {}
variable "twilio_number" {}
variable "twilio_number_sid" {}
variable "allowed_user_numbers" {}

variable "songbank_file_name" {
  default = "twilify-songbank"
}

variable "debug" {
  default = false
}
