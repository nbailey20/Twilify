resource "google_pubsub_topic" "twilify_app_topic" {
    name         = "twilify-app-topic"
    kms_key_name = google_kms_crypto_key.twilify_key.id
}

resource "google_pubsub_topic_iam_binding" "twilify_app_topic_binding" {
    project = google_pubsub_topic.twilify_app_topic.project
    topic   = google_pubsub_topic.twilify_app_topic.name
    role    = "roles/pubsub.publisher"
    members = [google_service_account.twilify_reception_sa.member]
}
