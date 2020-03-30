provider "google" {
  region = "${var.region}"
}

terraform {
  backend "gcs" {
    bucket  = "tf-state-prod"
    prefix  = "terraform/state"
  }
}

resource "google_storage_bucket" "artifact_bucket" {
  name          = "stocks-sandbox-artifact-bucket"
  location      = "US"
  force_destroy = true

  lifecycle_rule {
    condition {
      age = "30"
    }
    action {
      type = "Delete"
    }
  }
}

resource "google_storage_bucket_object" "code_zip" {
  name   = "symbol-extract"
  source = "artifacts/${formatdate("YYYY-MM-DD-hh-mm", timestamp())}/symbol-extract/code.zip"
  bucket = "image-store"
}