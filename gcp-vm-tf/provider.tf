terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "7.7.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  credentials = "ak-here-key.json"
}

# terraform {
#   required_providers {
#     google = {
#       source  = "hashicorp/google"
#       version = "~> 3.5"
#     }
#   }

#   required_version = ">= 0.12"
# }


