// Cognito user pool, user, MFA-enabled login domain for authentication
// Immutable email address attribute used for account recovery and verification
resource "aws_cognito_user_pool" "twilifyUserPool" {
  name = "twilify-user-pool"

  admin_create_user_config {
    allow_admin_create_user_only = true
  }

  email_verification_subject = "Verify your email for Twilify"
  email_verification_message = "Your verification code is {####}"

  sign_in_policy {
    allowed_first_auth_factors = var.cognito_first_auth_factors
  }

  mfa_configuration = "ON"
  software_token_mfa_configuration {
    enabled = true
  }

  dynamic "password_policy" {
    for_each = contains(var.cognito_first_auth_factors, "PASSWORD") ? [1] : []
    content {
      minimum_length    = 12
      require_uppercase = true
      require_lowercase = true
      require_numbers   = true
      require_symbols   = true
    }
  }

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }
}

resource "aws_cognito_user_pool_domain" "twilifyUserPoolDomain" {
  domain       = "twilify-auth-user-pool-domain" # must be globally unique
  user_pool_id = aws_cognito_user_pool.twilifyUserPool.id
}

resource "aws_cognito_user_pool_client" "twilifyUserPoolClient" {
  name                                 = "twilify-user-pool-client"
  user_pool_id                         = aws_cognito_user_pool.twilifyUserPool.id
  callback_urls                        = ["https://${var.r53_subdomain_name}/api/callback"]
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code"]
  explicit_auth_flows                  = ["ALLOW_USER_AUTH"]
  allowed_oauth_scopes                 = ["openid", "email"]
  supported_identity_providers         = ["COGNITO"]
  generate_secret                      = false

  access_token_validity  = var.cognito_access_token_validity
  id_token_validity      = var.cognito_id_token_validity
  refresh_token_validity = var.cognito_refresh_token_validity
  token_validity_units {
    access_token  = "minutes"
    id_token      = "minutes"
    refresh_token = "minutes"
  }
}

resource "aws_cognito_user" "twilifyUser" {
  count = length(var.twilify_usernames)

  user_pool_id       = aws_cognito_user_pool.twilifyUserPool.id
  username           = var.twilify_usernames[count.index]
  temporary_password = var.twilify_temp_password
  attributes = {
    email          = var.twilify_user_emails[count.index]
    email_verified = "true"
  }
}
