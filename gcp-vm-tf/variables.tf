variable "project_id" {
  description = "project id"
  type = string
  default = "ak-here"
}

variable "region" {
  description = "region name"
  default = "asia-south1"
  type = string
}

variable "zone" {
  description = "Zone name"
  type        = string
  default     = "asia-south1-a"
}

variable "instance_name" {
  description = "The name of the VM instance."
  type        = string
  default     = "gcp-vm-instance"
}

variable "machine_type" {
  description = "The machine type for the VM instance."
  type        = string
  default     = "e2-micro"  # Cost-effective option for free tier
}


variable "image_family" {
  description = "The image family to use for the VM instance."
  type        = string
  default     = "debian-11"  # Example image family
}

variable "image_project" {
  description = "The project that the image family belongs to."
  type        = string
  default     = "debian-cloud"  # Example image project
}