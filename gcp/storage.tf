resource "google_storage_bucket" "twilify_storage" {
    name          = "twilify-storage"
    location      = var.gcp_region
    force_destroy = true

    public_access_prevention = "enforced"

    encryption {
        default_kms_key_name = google_kms_crypto_key.twilify_key.id
    }

    ## Ensure Storage SA can use key before creating encrypted bucket
    depends_on = [google_kms_crypto_key_iam_binding.twilify_kms_binding]
}


resource "google_storage_bucket_object" "twilify_reception_object" {
    name   = "twilify-reception-function.zip"
    bucket = google_storage_bucket.twilify_storage.name
    source = "./functions/twilify-reception/twilify-reception-function.zip"
}


resource "google_storage_bucket_object" "twilify_app_object" {
    name   = "twilify-app-function.zip"
    bucket = google_storage_bucket.twilify_storage.name
    source = "./functions/twilify-app/twilify-app-function.zip"
}

## Create empty songbank object
resource "google_storage_bucket_object" "twilify_songbank" {
  name    = var.songbank_file_name
  content = jsonencode({})
  bucket  = google_storage_bucket.twilify_storage.name
}


resource "google_storage_bucket_iam_binding" "twilify_storage_binding" {
  bucket  = google_storage_bucket.twilify_storage.name
  role    = google_project_iam_custom_role.twilify_storage_user_role.id
  members = [google_service_account.twilify_app_sa.member]
}
