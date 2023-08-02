resource "aws_ssm_parameter" "spotify_refresh_token" {
  name      = "/twilify/spotify_refresh_token"
  type      = "SecureString"
  value     = var.spotify_refresh_token
  key_id    = aws_kms_key.twilify_kms_key.arn
  overwrite = false
}
