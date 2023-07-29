# ## Spotify Refresh Token
# resource "google_secret_manager_secret" "twilify_spotify_refresh_token" {
#     secret_id = "twilify-refresh-token"

#     replication {
#         user_managed {
#             replicas {
#                 location = var.gcp_region
#                 customer_managed_encryption {
#                     kms_key_name = local.kms_full_name
#                 }
#             }
#         }
#     }

#     ## Ensure secret manager identity can use key before creating secret
#     depends_on = [google_kms_crypto_key_iam_binding.twilify_kms_binding]
# }

# resource "google_secret_manager_secret_version" "twilify_spotify_refresh_token" {
#     secret      = google_secret_manager_secret.twilify_spotify_refresh_token.id
#     secret_data = var.spotify_refresh_token
# }

# resource "google_secret_manager_secret_iam_binding" "twilify_spotify_token_binding" {
#     project   = google_secret_manager_secret.twilify_spotify_refresh_token.project
#     secret_id = google_secret_manager_secret.twilify_spotify_refresh_token.secret_id

#     role = "roles/secretmanager.secretAccessor"
#     members = [
#         google_service_account.twilify_app_sa.member
#     ]
# }


# ## Twilio Account SID
# resource "google_secret_manager_secret" "twilify_twilio_account_sid" {
#     secret_id = "twilify-twilio-account-sid"

#     replication {
#         user_managed {
#             replicas {
#                 location = var.gcp_region
#                 customer_managed_encryption {
#                     kms_key_name = local.kms_full_name
#                 }
#             }
#         }
#     }

#     ## Ensure secret manager identity can use key before creating secret
#     depends_on = [google_kms_crypto_key_iam_binding.twilify_kms_binding]
# }

# resource "google_secret_manager_secret_version" "twilify_twilio_account_sid" {
#     secret      = google_secret_manager_secret.twilify_twilio_account_sid.id
#     secret_data = var.twilio_account_sid
# }

# resource "google_secret_manager_secret_iam_binding" "twilify_twilio_sid_binding" {
#     project   = google_secret_manager_secret.twilify_twilio_account_sid.project
#     secret_id = google_secret_manager_secret.twilify_twilio_account_sid.secret_id

#     role = "roles/secretmanager.secretAccessor"
#     members = [
#         google_service_account.twilify_reception_sa.member,
#         google_service_account.twilify_app_sa.member
#     ]
# }


# ## Twilio Auth Token
# resource "google_secret_manager_secret" "twilify_twilio_auth_token" {
#     secret_id = "twilify-twilio-auth-token"

#     replication {
#         user_managed {
#             replicas {
#                 location = var.gcp_region
#                 customer_managed_encryption {
#                     kms_key_name = local.kms_full_name
#                 }
#             }
#         }
#     }

#     ## Ensure secret manager identity can use key before creating secret
#     depends_on = [google_kms_crypto_key_iam_binding.twilify_kms_binding]
# }

# resource "google_secret_manager_secret_version" "twilify_twilio_auth_token" {
#     secret      = google_secret_manager_secret.twilify_twilio_auth_token.id
#     secret_data = var.twilio_auth_token
# }

# resource "google_secret_manager_secret_iam_binding" "twilify_twilio_token_binding" {
#     project   = google_secret_manager_secret.twilify_twilio_auth_token.project
#     secret_id = google_secret_manager_secret.twilify_twilio_auth_token.secret_id

#     role = "roles/secretmanager.secretAccessor"
#     members = [
#         google_service_account.twilify_reception_sa.member,
#         google_service_account.twilify_app_sa.member
#     ]
# }



locals {
    app_secrets_map = {
        spotify_client_id     = var.spotify_client_id
        spotify_client_secret = var.spotify_client_secret
        spotify_refresh_token = var.spotify_refresh_token
        twilio_account_sid    = var.twilio_account_sid
        twilio_auth_token     = var.twilio_auth_token
    }

    reception_secret_vars_list = [
        "twilio_account_sid",
        "twilio_auth_token"
    ]
}


resource "google_secret_manager_secret" "twilify_secrets" {
    for_each = local.app_secrets_map

    secret_id = replace("twilify-${each.key}", "_", "-")
    replication {
        user_managed {
            replicas {
                location = var.gcp_region
                customer_managed_encryption {
                    kms_key_name = local.kms_full_name
                }
            }
        }
    }
    ## Ensure secret manager identity can use key before creating secret
    depends_on = [google_kms_crypto_key_iam_binding.twilify_kms_binding]
}

resource "google_secret_manager_secret_version" "twilify_secret_versions" {
    for_each = local.app_secrets_map

    secret      = google_secret_manager_secret.twilify_secrets[each.key].id
    secret_data = each.value
}

resource "google_secret_manager_secret_iam_binding" "twilify_secret_read_bindings" {
    for_each = local.app_secrets_map

    project   = google_secret_manager_secret.twilify_secrets[each.key].project
    secret_id = google_secret_manager_secret.twilify_secrets[each.key].secret_id

    role = "roles/secretmanager.secretAccessor"
    members = contains(local.reception_secret_vars_list, each.key) ? [
            google_service_account.twilify_app_sa.member,
            google_service_account.twilify_reception_sa.member
        ] : [
            google_service_account.twilify_app_sa.member
        ]
}

resource "google_secret_manager_secret_iam_binding" "twilify_secret_write_binding" {
    project   = google_secret_manager_secret.twilify_secrets["spotify_refresh_token"].project
    secret_id = google_secret_manager_secret.twilify_secrets["spotify_refresh_token"].secret_id

    role    = "roles/secretmanager.secretVersionAdder"
    members = [google_service_account.twilify_app_sa.member]
}
