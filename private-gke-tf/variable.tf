
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
  default     = "asia-south2-a"
}
