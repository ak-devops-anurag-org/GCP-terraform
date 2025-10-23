terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "7.8.0"
    }
  }
}

# Configure the Google Cloud provider
provider "google" {
  project = "ak-here"
  region  = "asia-south2"
  zone    = "asia-south2-a"
  credentials = "ak-here-key.json"
}