variable "instance_name" {
  description = "The name of the VM instance."
  type        = string
  default     = "gcp-terraform-vm-instance"
}

variable "machine_type" {
  description = "The machine type for the VM instance."
  type        = string
  default     = "f1-micro"  # Cost-effective option for free tier
}

variable "zone" {
  description = "The zone where the VM instance will be created."
  type        = string
  default     = "us-central1-a"  # Change as needed
}

variable "image_family" {
  description = "The image family to use for the VM instance."
  type        = string
  default     = "debian-11"  # Example of a lightweight OS
}

variable "image_project" {
  description = "The project that contains the image family."
  type        = string
  default     = "debian-cloud"
}