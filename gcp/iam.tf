## Pull current project information
data "google_project" "project" {}

## Pull Cloud Storage GCP-managed SA so we can grant permission for KMS usage
data "google_storage_project_service_account" "gcs_account" {}

resource "google_service_account" "twilify_reception_sa" {
    account_id   = "twilify-reception-sa"
    display_name = "Twilify Reception SA"
}

resource "google_service_account" "twilify_app_sa" {
    account_id   = "twilify-app-sa"
    display_name = "Twilify App SA"
}

## Create service identity for secret manager, doesn't happen automatically like Storage
resource "google_project_service_identity" "secret_manager_identity" {
    provider = google-beta

    project = var.gcp_project_id
    service = "secretmanager.googleapis.com"
}

## For some reason there's no predefined role with just Storage object read/update
resource "google_project_iam_custom_role" "twilify_storage_user_role" {
  role_id     = "twilifyStorageUserRole"
  title       = "Twilify Storage User Role"
  description = "Allows get and update for storage objects"
  permissions = ["storage.objects.get", "storage.objects.create", "storage.objects.delete"]
}
