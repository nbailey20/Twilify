## KMS-encrypted Cloud Functions must be stored in a docker repository
resource "google_artifact_registry_repository" "tmf_artifact_repo" {
    location      = var.gcp_region
    repository_id = "tmf-artifact-repo"
    kms_key_name  = local.kms_full_name
    format        = "DOCKER"

    ## Ensure secret manager identity can use key before creating encrypted bucket
    depends_on = [google_kms_crypto_key_iam_binding.tmf_kms_binding]
}
