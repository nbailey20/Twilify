resource "aws_ssm_parameter" "spotify_refresh_token" {
  name      = "/tmf/spotify_refresh_token"
  type      = "SecureString"
  value     = var.refresh_token
  key_id    = aws_kms_key.tmf_kms_key.arn
  overwrite = false
}

resource "aws_ssm_parameter" "playlist_text_params" {
  name      = "/tmf/playlist_text_params"
  type      = "SecureString"
  value     = "{}"
  key_id    = aws_kms_key.tmf_kms_key.arn
  overwrite = false
}

resource "aws_ssm_parameter" "network_keep_alive" {
  name      = "/tmf/network_keep_alive"
  type      = "SecureString"
  value     = "0"
  key_id    = aws_kms_key.tmf_kms_key.arn
  overwrite = false
}
