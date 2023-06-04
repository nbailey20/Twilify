resource "google_cloudfunctions_function" "tmf_reception_function" {
    name        = "tmf-reception"
    description = "Parses texts and invokes tmf-app with expected input"
    runtime     = "python311"

    available_memory_mb   = 128
    source_archive_bucket = google_storage_bucket.tmf_storage.name
    source_archive_object = google_storage_bucket_object.tmf_reception_object.name
    ## Source is in storage, but built docker images live in KMS-encrypted artifact registry
    docker_registry       = "ARTIFACT_REGISTRY"
    docker_repository     = google_artifact_registry_repository.tmf_artifact_repo.id
    kms_key_name          = local.kms_full_name
    service_account_email = google_service_account.tmf_reception_sa.email
    trigger_http          = true
    entry_point           = "main"

    environment_variables = {
        user_numbers          = var.user_numbers
        twilio_number         = var.twilio_number
        twilio_account_sid    = var.twilio_account_sid
        twilio_auth_token     = var.twilio_auth_token 
       # tmf_app_function_id   = google_cloudfunctions_function.tmf_app_function.id
        num_songs_in_playlist = var.num_songs_in_playlist
        debug                 = var.debug
    }
}

# resource "google_cloudfunctions_function" "tmf_app_function" {
#     name        = "tmf-app"
#     description = "Main function to generate Spotify playlist"
#     runtime     = "python311"

#     available_memory_mb   = 128
#     source_archive_bucket = google_storage_bucket.tmf_storage.name
#     source_archive_object = google_storage_bucket_object.tmf_app_object.name
#     docker_registry       = "ARTIFACT_REGISTRY"
#     docker_repository     = google_artifact_registry_repository.tmf_artifact_repo.id
#     kms_key_name          = local.kms_full_name
#     service_account_email = google_service_account.tmf_app_sa.email
#     trigger_http          = true
#     entry_point           = "main"

#     environment_variables = {
#         spotify_client_id              = var.spotify_client_id
#         spotify_client_secret          = var.spotify_client_secret
#         refresh_token_secret_name      = google_secret_manager_secret_version.tmf_refresh_token.name
#         refresh_token_kms_key_arn      = google_kms_crypto_key.tmf_key.id
#         rec_limit                      = var.rec_limit
#         bucket_name                    = google_storage_bucket.tmf_storage.name
#         songbank_file_name             = var.songbank_file_name
#         spotify_user                   = var.spotify_user
#         playlist_name                  = var.playlist_name
#         twilio_account_sid             = var.twilio_account_sid
#         twilio_auth_token              = var.twilio_auth_token
#         twilio_number                  = var.twilio_number
#         num_songs_in_playlist          = var.num_songs_in_playlist
#         songbank_cycles_before_rebuild = var.songbank_cycles_before_rebuild
#         debug                          = var.debug
#     }
# }

# # IAM entry for reception SA to invoke the app function
# resource "google_cloudfunctions_function_iam_binding" "tmf_app_invoker" {
#     project        = google_cloudfunctions_function.tmf_app_function.project
#     region         = google_cloudfunctions_function.tmf_app_function.region
#     cloud_function = google_cloudfunctions_function.tmf_app_function.name

#     role    = "roles/cloudfunctions.invoker"
#     members = [google_service_account.tmf_reception_sa.member]
# }
