resource "google_pubsub_topic" "topic" {
  name = "symbol-broadcast-trigger-topic"
}

resource "google_storage_bucket_object" "code_zip" {
  name   = "artifacts/symbol-broadcast-trigger/${formatdate("YYYY-MM-DD-hh-mm", timestamp())}/code.zip"
  source = "${path.module}/code.zip"
  bucket = "${var.artifact_bucket_name}"
}

resource "google_cloudfunctions_function" "symbol_broadcasttrigger_function" {
  name = "symbol-broadcast-trigger-function"

  runtime = "python37"
  available_memory_mb = 256

  source_archive_bucket = "${google_storage_bucket_object.code_zip.bucket}"
  source_archive_object = "${google_storage_bucket_object.code_zip.name}"

  entry_point = "broadcast"

  event_trigger {
      event_type = "google.storage.object.finalize"
      resource = "${var.data_bucket_name}"
  }

  service_account_email = "${var.service_account}"

  environment_variables = {
      PROJECT_ID = "${var.project_id}"
      PUBSUB_TOPIC_NAME = "${google_pubsub_topic.topic.name}"
      FILE_NAME = "symbols.json"
  }
}