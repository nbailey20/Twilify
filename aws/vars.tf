variable aws_account_id {}
variable aws_region {}
variable "spotify_user" {}
variable "spotify_client_id" {}
variable "spotify_client_secret" {}
variable "refresh_token" {}
variable "twilio_account_sid" {}
variable "twilio_auth_token" {}
variable "twilio_number" {}
variable "twilio_number_sid" {}
variable "user_numbers" {}

variable "songbank_file_name" {
  default = "songbank"
}

variable "rec_limit" {
  default = 5
}

variable "playlist_name" {
  default = "Trusty Music Fabricator"
}

variable "num_songs_in_playlist" {
  default = 20
}

variable "songbank_cycles_before_rebuild" {
  default = 2
}

variable "debug" {
  default = false
}
