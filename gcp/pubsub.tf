resource "google_pubsub_topic" "tmf_app_topic" {
    name         = "tmf-app-topic"
    kms_key_name = google_kms_crypto_key.tmf_key.id
}

resource "google_pubsub_topic_iam_binding" "tmf_app_topic_binding" {
    project = google_pubsub_topic.tmf_app_topic.project
    topic   = google_pubsub_topic.tmf_app_topic.name
    role    = "roles/pubsub.publisher"
    members = [google_service_account.tmf_reception_sa.member]
}
