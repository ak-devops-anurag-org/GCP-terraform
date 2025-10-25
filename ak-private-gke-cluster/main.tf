# VPC Network
resource "google_compute_network" "ak_vpc" {
  name                    = "ak-vpc"
  auto_create_subnetworks = false
  description             = "ak vpc for private gke"
  routing_mode            = "REGIONAL"
}

# Subnet with secondary ranges for GKE (pods and services)
resource "google_compute_subnetwork" "ak_vpc_subnet" {
  name                     = "ak-vpc-subnet"
  ip_cidr_range            = "10.10.0.0/20"
  region                   = "asia-south2"
  network                  = google_compute_network.ak_vpc.self_link
  private_ip_google_access = true

  secondary_ip_range {
    range_name    = var.pods_range_name
    ip_cidr_range = "10.20.0.0/16"
  }

  secondary_ip_range {
    range_name    = var.services_range_name
    ip_cidr_range = "10.30.0.0/16"
  }

}

# Firewall Rule for Bastion SSH Access
# This rule allows SSH from anywhere (0.0.0.0/0) to instances tagged with 'bastion-host'.
# You'll apply this tag (bastion-host) to your manually created bastion VM.
resource "google_compute_firewall" "allow_ssh_bastion" {
  name    = "allow-ssh-bastion"
  network = google_compute_network.ak_vpc.self_link
  description = "allow-ssh-bastion"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"] # Allow SSH from any IP for the bastion
  target_tags   = ["bastion-host"]
}

# Router for NAT
resource "google_compute_router" "ak_gke_router" {
  name    = "ak-gke-router"
  region  = google_compute_subnetwork.ak_vpc_subnet.region
  network = google_compute_network.ak_vpc.self_link
}

# NAT Gateway
resource "google_compute_router_nat" "ak_gke_nat_gateway" {
  name                          = "ak-gke-nat-gateway"
  router                        = google_compute_router.ak_gke_router.name
  region                        = google_compute_router.ak_gke_router.region
  nat_ip_allocate_option        = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = false
    filter = "ALL"
  }
  # No specific NAT IPs were defined in external-ips.json for the NAT gateway directly
  # as it was AUTO_ONLY. If static IPs were desired, they would be listed here.
}

 # === Private GKE Cluster ===
resource "google_container_cluster" "ak_private_gke_cluster" {
  name     = "ak-private-gke-cluster"
  location = "asia-south2-b"

  network    = google_compute_network.ak_vpc.self_link
  subnetwork = google_compute_subnetwork.ak_vpc_subnet.self_link

  initial_node_count      = 1

  remove_default_node_pool = true
  deletion_protection      = false

  release_channel {
    channel = "REGULAR"
  }

  # IP Allocation Policy (must match your subnet secondary ranges)
  ip_allocation_policy {
    cluster_secondary_range_name  = google_compute_subnetwork.ak_vpc_subnet.secondary_ip_range[0].range_name
    services_secondary_range_name = google_compute_subnetwork.ak_vpc_subnet.secondary_ip_range[1].range_name
  }
  # ip_allocation_policy {
  #   cluster_secondary_range_name  = "ak-gke-pods-range"
  #   services_secondary_range_name = "ak-gke-services-range"
  # }

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = true
    # master_ipv4_cidr_block  = "10.10.0.0/28" # Required for private endpoint mode
  }

  master_authorized_networks_config {
    cidr_blocks {
      display_name = "primary-subnet"
      cidr_block   = google_compute_subnetwork.ak_vpc_subnet.ip_cidr_range
    }
  }

  workload_identity_config {
    workload_pool = "ak-here.svc.id.goog"
  }

  logging_config {
    enable_components = []
  }

  monitoring_config {
    enable_components = []
  }

  # Required to avoid race conditions with NAT setup
  depends_on = [
    google_compute_network.ak_vpc,
    google_compute_subnetwork.ak_vpc_subnet
  ]
}

# === Node Pool ===
resource "google_container_node_pool" "ak_gke_cluster_node_pool" {
  name     = "ak-gke-cluster-node-pool"
  cluster  = google_container_cluster.ak_private_gke_cluster.name
  location = "asia-south2-b"

  node_count = 1

  node_config {
    machine_type    = "e2-micro"
    disk_size_gb    = 15
    disk_type       = "pd-balanced"
    image_type      = "COS_CONTAINERD"
    service_account = "sa-bastion-vm@ak-here.iam.gserviceaccount.com"

    oauth_scopes = [
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/trace.append",
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    metadata = {
      disable-legacy-endpoints = "true"
    }

    shielded_instance_config {
      enable_integrity_monitoring = true
      enable_secure_boot          = false
    }
  }

  autoscaling {
    min_node_count = 1
    max_node_count = 1
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  upgrade_settings {
    max_surge       = 1
    max_unavailable = 0
  }

  depends_on = [
    google_container_cluster.ak_private_gke_cluster
  ]
}
