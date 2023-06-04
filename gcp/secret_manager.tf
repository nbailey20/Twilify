resource "google_secret_manager_secret" "tmf_refresh_secret" {
    secret_id = "tmf-refresh-token"

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

    ## Ensure secret manager identity can use key before creating encrypted bucket
    depends_on = [google_kms_crypto_key_iam_binding.tmf_kms_binding]
}

resource "google_secret_manager_secret_version" "tmf_refresh_token" {
    secret      = google_secret_manager_secret.tmf_refresh_secret.id
    secret_data = var.refresh_token
}
