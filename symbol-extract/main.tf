resource "google_pubsub_topic" "topic" {
  name = "symbol-extract-topic"
}

resource "google_storage_bucket_object" "code_zip" {
  name   = "artifacts/symbol-extract/${formatdate("YYYY-MM-DD-hh-mm", timestamp())}/code.zip"
  source = "${path.module}/code.zip"
  bucket = "${var.artifact_bucket_name}"
}

resource "google_cloud_scheduler_job" "job" {
  name        = "symbols-extract-job"
  description = "Kicks off extract job for ticker symbols"
  schedule    = "0 8 * * *"

  pubsub_target {
    # topic.id is the topic's full resource name.
    topic_name = "${google_pubsub_topic.topic.id}"
    data       = "${base64encode("message")}"
  }
}

resource "google_cloudfunctions_function" "symbol_extract_function" {
  name = "symbol-extract-function"

  runtime = "python37"
  available_memory_mb = 256

  source_archive_bucket = "${google_storage_bucket_object.code_zip.bucket}"
  source_archive_object = "${google_storage_bucket_object.code_zip.name}"

  entry_point = "trigger"

  event_trigger {
      event_type = "google.pubsub.topic.publish"
      resource = "${google_pubsub_topic.topic.id}"
  }

  service_account_email = "${var.service_account}"

  environment_variables = {
      BUCKET = "${var.data_bucket_name}"
      FILE_PREFIX = "symbols"
      AUTH_KEY = "${var.finnhub_key}"
  }
}
