# Terraform configuration for GKE cluster with VPC, subnets, NAT, and bastion setup
# Cost-optimized for learning purposes

terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "7.8.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
  credentials = "ak-here-key.json"
}