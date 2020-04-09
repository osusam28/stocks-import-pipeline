output "data_bucket_name" {
  value = "${google_storage_bucket.data_bucket.name}"
}

output "artifact_bucket_name" {
    value = "${google_storage_bucket.artifact_bucket.name}"
}