variable "aws_account_id" {}
variable "aws_region" {}

variable "spotify_playlist_name" {
  default = "Twilify"
}
variable "num_songs_in_playlist" {
  default = 20
}

variable "songbank_file_name" {
  default = "twilify-songbank"
}

## Write helpful Lambda function execution info to CloudWatch logs
variable "debug" {
  default = true
}

variable "spotify_token_param_path" {
  description = "Path to SSM parameters containing Spotify refresh tokens for users"
  default     = "/twilify/spotify_refresh_tokens"
}

variable "twilify_usernames" {
  description = "List of usernames for the Cognito user pool"
  type        = list(string)
}

variable "twilify_temp_password" {
  description = "Temporary password for the Cognito user pool"
  type        = string
}

variable "twilify_user_emails" {
  description = "List of email addresses for the Cognito user pool user, in the same order as twilify_usernames"
  type        = list(string)
}

variable "r53_zone_id" {
  description = "ID of existing Route53 public domain under which a zone will be created to manage DNS records for the website"
  type        = string
}

variable "r53_subdomain_name" {
  description = "Subdomain name for the website (e.g. 'twilify.example.com')"
  type        = string
}

variable "cloudfront_cache_policy_id" {
  description = "ID of the CloudFront cache policy to use for the distribution"
  type        = string
}

variable "cloudfront_origin_policy_id" {
  description = "ID of the CloudFront origin request policy to use for the distribution"
  type        = string
}

variable "cognito_first_auth_factors" {
  description = "List of allowed first authentication factors for Cognito user pool"
  type        = list(string)
}

variable "cognito_access_token_validity" {
  description = "Validity period of the Cognito access token in minutes"
  type        = number
  default     = 1440 # max
}

variable "cognito_id_token_validity" {
  description = "Validity period of the Cognito ID token in minutes"
  type        = number
  default     = 1440 # max
}

variable "cognito_refresh_token_validity" {
  description = "Validity period of the Cognito refresh token in minutes (min 60)"
  type        = number
  default     = 42000
}
