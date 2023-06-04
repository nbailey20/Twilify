resource "google_storage_bucket" "tmf_storage" {
    name          = "tmf-storage"
    location      = var.gcp_region
    force_destroy = true

    public_access_prevention = "enforced"

    encryption {
        default_kms_key_name = google_kms_crypto_key.tmf_key.id
    }

    ## Ensure Storage SA can use key before creating encrypted bucket
    depends_on = [google_kms_crypto_key_iam_binding.tmf_kms_binding]
}


resource "google_storage_bucket_object" "tmf_reception_object" {
    name   = "tmf-reception-function.zip"
    bucket = google_storage_bucket.tmf_storage.name
    source = "./functions/tmf-reception/tmf-reception-function.zip"
}


resource "google_storage_bucket_object" "tmf_app_object" {
    name   = "tmf-app-function.zip"
    bucket = google_storage_bucket.tmf_storage.name
    source = "./functions/tmf-app/tmf-app-function.zip"
}
