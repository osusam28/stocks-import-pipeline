provider "google" {
  project = "${var.project}"
  region = "${var.region}"
}

terraform {
  backend "gcs" {
    bucket  = "stocks-sandbox.appspot.com"
    prefix  = "terraform/state/symbol-extract"
  }
}

resource "google_pubsub_topic" "topic" {
  name = "symbol-extract-topic"
}

resource "google_storage_bucket" "data_bucket" {
  name          = "stocks-sandbox-data-bucket"
  location      = "US"
  force_destroy = true
}

resource "google_storage_bucket" "artifact_bucket" {
  name          = "stocks-sandbox-artifact-bucket"
  location      = "US"
  force_destroy = true
}

resource "google_storage_bucket_acl" "image-store-acl" {
  bucket = "${google_storage_bucket.data_bucket.name}"

  role_entity = [
    "OWNER:user-${var.service_account}"
  ]
}

resource "google_storage_bucket_object" "code_zip" {
  name   = "artifacts/symbol-extract/${formatdate("YYYY-MM-DD-hh-mm", timestamp())}/code.zip"
  source = "code.zip"
  bucket = "${google_storage_bucket.artifact_bucket.name}"
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

  source_archive_bucket = "${google_storage_bucket.artifact_bucket.name}"
  source_archive_object = "${google_storage_bucket_object.code_zip.name}"

  entry_point = "trigger"

  event_trigger {
      event_type = "google.pubsub.topic.publish"
      resource = "${google_pubsub_topic.topic.id}"
  }

  service_account_email = "${var.service_account}"

  environment_variables = {
      BUCKET = "${google_storage_bucket.data_bucket.name}"
      FILE_PREFIX = "symbols"
      AUTH_KEY = "${var.finnhub_key}"
  }
}
