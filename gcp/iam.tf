## Pull current project information
data "google_project" "project" {}

## Pull Cloud Storage GCP-managed SA so we can grant permission for KMS usage
data "google_storage_project_service_account" "gcs_account" {}

resource "google_service_account" "tmf_reception_sa" {
    account_id   = "tmf-reception-sa"
    display_name = "TMF Reception SA"
}

resource "google_service_account" "tmf_app_sa" {
    account_id   = "tmf-app-sa"
    display_name = "TMF App SA"
}

## Create service identity for secret manager, doesn't happen automatically like Storage
resource "google_project_service_identity" "secret_manager_identity" {
    provider = google-beta

    project = var.gcp_project_id
    service = "secretmanager.googleapis.com"
}

## For some reason there's no predefined role with just Storage object read/update
resource "google_project_iam_custom_role" "tmf_storage_user_role" {
  role_id     = "tmfStorageUserRole"
  title       = "TMF Storage User Role"
  description = "Allows get and update for storage objects"
  permissions = ["storage.objects.get", "storage.objects.create", "storage.objects.delete"]
}
