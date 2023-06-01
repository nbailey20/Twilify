resource "aws_ssm_parameter" "spotify_refresh_token" {
  name      = "/tmf/spotify_refresh_token"
  type      = "SecureString"
  value     = var.refresh_token
  key_id    = aws_kms_key.tmf_kms_key.arn
  overwrite = false
}
