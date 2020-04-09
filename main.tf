provider "google" {
  project = "${var.project}"
  region = "${var.region}"
}

terraform {
  backend "gcs" {
    bucket  = "stocks-sandbox.appspot.com"
    prefix  = "terraform/state/stockapi"
  }
}

module "shared" {
  source = "./shared"
  finnhub_service_account = "${var.finnhub_service_account}"
}


module "symbol_extract" {
  source = "./symbol-extract"
  service_account = "${var.finnhub_service_account}"
  finnhub_key = "${var.FINNHUB_KEY}"
  artifact_bucket_name = "${module.shared.artifact_bucket_name}"
  data_bucket_name = "${module.shared.data_bucket_name}"
}
