locals {
    kms_full_name = "projects/${var.gcp_project_id}/locations/${var.gcp_region}/keyRings/${google_kms_key_ring.tmf_keyring.name}/cryptoKeys/${google_kms_crypto_key.tmf_key.name}"
}

resource "random_string" "kms_suffix" {
    length           = 6
    special          = false
}

resource "google_kms_key_ring" "tmf_keyring" {
    name     = "tmf-keyring-${random_string.kms_suffix.id}"
    location = var.gcp_region
}

resource "google_kms_crypto_key" "tmf_key" {
    name     = "tmf-kms-key-${random_string.kms_suffix.id}"
    key_ring = google_kms_key_ring.tmf_keyring.id
}

## Ensure services can use KMS
resource "google_kms_crypto_key_iam_binding" "tmf_kms_binding" {
    crypto_key_id = "${var.gcp_project_id}/${var.gcp_region}/${google_kms_key_ring.tmf_keyring.name}/${google_kms_crypto_key.tmf_key.name}"
    role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"

    members = [
        "serviceAccount:${data.google_storage_project_service_account.gcs_account.email_address}",
        "serviceAccount:${google_project_service_identity.secret_manager_identity.email}",
        "serviceAccount:service-${data.google_project.project.number}@gcp-sa-artifactregistry.iam.gserviceaccount.com",
        "serviceAccount:service-${data.google_project.project.number}@gcf-admin-robot.iam.gserviceaccount.com",
        "serviceAccount:service-${data.google_project.project.number}@gcp-sa-pubsub.iam.gserviceaccount.com"
    ]
}
