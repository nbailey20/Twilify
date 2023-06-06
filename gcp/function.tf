resource "google_cloudfunctions_function" "tmf_reception_function" {
    name        = "tmf-reception"
    description = "Parses texts and invokes tmf-app with expected input"
    runtime     = "python311"

    available_memory_mb   = 256
    source_archive_bucket = google_storage_bucket.tmf_storage.name
    source_archive_object = google_storage_bucket_object.tmf_reception_object.name
    docker_registry       = "ARTIFACT_REGISTRY"
    docker_repository     = google_artifact_registry_repository.tmf_artifact_repo.id
    kms_key_name          = local.kms_full_name
    service_account_email = google_service_account.tmf_reception_sa.email
    entry_point           = "main"
    trigger_http          = true
    timeout               = 60

    environment_variables = {
        user_numbers          = var.user_numbers
        twilio_number         = var.twilio_number
        tmf_app_topic         = google_pubsub_topic.tmf_app_topic.id
        num_songs_in_playlist = var.num_songs_in_playlist
        debug                 = var.debug
    }
    secret_environment_variables {
        key        = "twilio_account_sid"
        project_id = var.gcp_project_id
        secret     = google_secret_manager_secret.tmf_secrets["twilio_account_sid"].secret_id
        version    = "latest" 
    }
    secret_environment_variables {
        key        = "twilio_auth_token"
        project_id = var.gcp_project_id
        secret     = google_secret_manager_secret.tmf_secrets["twilio_auth_token"].secret_id
        version    = "latest" 
    }

    depends_on = [
        google_secret_manager_secret.tmf_secrets
    ]
}


resource "google_cloudfunctions_function" "tmf_app_function" {
    name        = "tmf-app"
    description = "Main function to generate Spotify playlist"
    runtime     = "python311"

    available_memory_mb   = 256
    source_archive_bucket = google_storage_bucket.tmf_storage.name
    source_archive_object = google_storage_bucket_object.tmf_app_object.name
    docker_registry       = "ARTIFACT_REGISTRY"
    docker_repository     = google_artifact_registry_repository.tmf_artifact_repo.id
    kms_key_name          = local.kms_full_name
    service_account_email = google_service_account.tmf_app_sa.email
    entry_point           = "main"
    timeout               = 60

    event_trigger {
        event_type = "providers/cloud.pubsub/eventTypes/topic.publish"
        resource   = google_pubsub_topic.tmf_app_topic.id
        failure_policy {
            retry = false
        }
    }

    environment_variables = {
        spotify_refresh_token_id       = google_secret_manager_secret.tmf_secrets["spotify_refresh_token"].id
        rec_limit                      = var.rec_limit
        bucket_name                    = google_storage_bucket.tmf_storage.name
        songbank_file_name             = var.songbank_file_name
        spotify_user                   = var.spotify_user
        playlist_name                  = var.playlist_name
        twilio_number                  = var.twilio_number
        num_songs_in_playlist          = var.num_songs_in_playlist
        songbank_cycles_before_rebuild = var.songbank_cycles_before_rebuild
        debug                          = var.debug
    }
    secret_environment_variables {
        key        = "twilio_account_sid"
        project_id = var.gcp_project_id
        secret     = google_secret_manager_secret.tmf_secrets["twilio_account_sid"].secret_id
        version    = "latest" 
    }
    secret_environment_variables {
        key        = "twilio_auth_token"
        project_id = var.gcp_project_id
        secret     = google_secret_manager_secret.tmf_secrets["twilio_auth_token"].secret_id
        version    = "latest" 
    }
    secret_environment_variables {
        key        = "spotify_refresh_token"
        project_id = var.gcp_project_id
        secret     = google_secret_manager_secret.tmf_secrets["spotify_refresh_token"].secret_id
        version    = "latest" 
    }
    secret_environment_variables {
        key        = "spotify_client_id"
        project_id = var.gcp_project_id
        secret     = google_secret_manager_secret.tmf_secrets["spotify_client_id"].secret_id
        version    = "latest" 
    }
    secret_environment_variables {
        key        = "spotify_client_secret"
        project_id = var.gcp_project_id
        secret     = google_secret_manager_secret.tmf_secrets["spotify_client_secret"].secret_id
        version    = "latest" 
    }

    depends_on = [
        google_secret_manager_secret.tmf_secrets
    ]
}

# Allow anonymous invocation for reception function, source # verified in Python
resource "google_cloudfunctions_function_iam_binding" "tmf_reception_invoker" {
    project        = google_cloudfunctions_function.tmf_reception_function.project
    region         = google_cloudfunctions_function.tmf_reception_function.region
    cloud_function = google_cloudfunctions_function.tmf_reception_function.name

    role    = "roles/cloudfunctions.invoker"
    members = ["allUsers"]
}

# Allow reception SA to invoke the app function
resource "google_cloudfunctions_function_iam_binding" "tmf_app_invoker" {
    project        = google_cloudfunctions_function.tmf_app_function.project
    region         = google_cloudfunctions_function.tmf_app_function.region
    cloud_function = google_cloudfunctions_function.tmf_app_function.name

    role    = "roles/cloudfunctions.invoker"
    members = [google_service_account.tmf_reception_sa.member]
}
