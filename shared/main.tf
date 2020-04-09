resource "google_storage_bucket" "artifact_bucket" {
  name          = "stocks-sandbox-artifact-bucket"
  location      = "US"
  force_destroy = true
}

resource "google_storage_bucket" "data_bucket" {
  name          = "stocks-sandbox-data-bucket"
  location      = "US"
  force_destroy = true
}

resource "google_storage_bucket_acl" "image-store-acl" {
  bucket = "${google_storage_bucket.data_bucket.name}"

  role_entity = [
    "OWNER:user-${var.finnhub_service_account}"
  ]
}