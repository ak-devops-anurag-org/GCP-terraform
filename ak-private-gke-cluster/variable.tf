# variables.tf
variable "pods_range_name" {
  description = "Name of the secondary IP range for GKE Pods"
  type        = string
  default     = "ak-gke-pods-range"
}

variable "services_range_name" {
  description = "Name of the secondary IP range for GKE Services"
  type        = string
  default     = "ak-gke-services-range"
}



# Variables
variable "project_id" {
  description = "GCP Project ID"
  type        = string
  default = "ak-here"
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "asia-south2"
}

variable "zone" {
  description = "GCP zone"
  type        = string
  default     = "asia-south2-b"
}
