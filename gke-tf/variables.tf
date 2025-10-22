variable "project" {
  description = "project id"
  type = string
  default = "ak-here"
}

variable "region" {
  description = "region name"
  default = "asia-south2"
  type = string
}

variable "zone" {
  description = "Zone name"
  type        = string
  default     = "asia-south2-a"
}

variable "vpc_name" {
  type    = string
  default = "gke-private-vpc-tf"
}

variable "subnet_cidr" {
  type    = string
  default = "10.11.0.0/16"
}

variable "pods_range_cidr" {
  type    = string
  default = "10.12.0.0/24"
}

variable "services_range_cidr" {
  type    = string
  default = "10.13.0.0/24"
}

variable "public_subnet_cidr" {
  type = string
  default = "10.20.0.0/28"
}



variable "cluster_name" {
  type    = string
  default = "private-gke-cluster-tf"
}

variable "node_machine_type" {
  type    = string
  default = "e2-micro"    // e2-small, e2-medium, etc. 
}

variable "node_count" {
  type    = number
  default = 1
}