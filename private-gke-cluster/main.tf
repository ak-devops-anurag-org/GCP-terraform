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

# 1. VPC Network
resource "google_compute_network" "ak_vpc" {
  name                    = "ak-vpc"
  auto_create_subnetworks = false
  description             = "ak vpc for private gke"
  routing_mode            = "REGIONAL"
}

# 2. Subnet
resource "google_compute_subnetwork" "ak_vpc_subnet" {
  name                     = "ak-vpc-subnet"
  ip_cidr_range            = "10.10.0.0/20"
  region                   = "asia-south2"
  network                  = google_compute_network.ak_vpc.self_link
  private_ip_google_access = true

  secondary_ip_range {
    range_name    = "ak-gke-pods-range"
    ip_cidr_range = "10.20.0.0/16"
  }

  secondary_ip_range {
    range_name    = "ak-gke-services-range"
    ip_cidr_range = "10.30.0.0/16"
  }

}

# 3. Router for NAT
resource "google_compute_router" "ak_gke_router" {
  name    = "ak-gke-router"
  region  = google_compute_subnetwork.ak_vpc_subnet.region
  network = google_compute_network.ak_vpc.self_link
}

# 4. NAT Gateway
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

############################################################
# 1. Private GKE Cluster
############################################################
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
    cluster_secondary_range_name  = "ak-gke-pods-range"
    services_secondary_range_name = "ak-gke-services-range"
  }

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

############################################################
# 2. Node Pool
############################################################
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


# # 5. GKE Private Cluster
# resource "google_container_cluster" "ak_private_gke_cluster" {
#   name     = "ak-private-gke-cluster"
#   location = "asia-south2-a"

#   network    = google_compute_network.ak_vpc.self_link
#   subnetwork = google_compute_subnetwork.ak_vpc_subnet.self_link

#   # Basic cluster settings
#   initial_node_count = 1 # Managed by the default node pool below
#   remove_default_node_pool = true
  
#   deletion_protection = false
  
#   logging_service   = "none" 
#   monitoring_service = "none" 

#   release_channel {
#     channel = "REGULAR"
#   }

#   # IP Allocation Policy
#   ip_allocation_policy {
#     cluster_secondary_range_name = "ak-gke-pods-range" # pods
#     services_secondary_range_name = "ak-gke-services-range" # services
#   }

#   # Private Cluster Configuration
#   private_cluster_config {
#     enable_private_nodes = true
#     enable_private_endpoint = true # Allows internal access to control plane
#     # master_ipv4_cidr_block = "10.10.0.0/28" # A small CIDR for master in the primary subnet
#   }

#   master_authorized_networks_config {
#     cidr_blocks {
#       display_name = "primary-subnet"
#       cidr_block   = google_compute_subnetwork.ak_vpc_subnet.ip_cidr_range
#     }
#   }

#   # Workload Identity Config
#   workload_identity_config {
#     # No specific configuration provided, GKE will set up default Workload Identity if enabled.
#     # If a specific pool needed it, we would configure it there.
#   }

#   # depends_on = [ google_compute_router_nat.ak_gke_nat_gateway, google_compute_router.ak_gke_router ]
  
# }

# # 6. Node Pool
# resource "google_container_node_pool" "ak_gke_cluster_node_pool" {
#   name       = "ak-gke-cluster-node-pool"
#   location   = "asia-south2-a"
#   cluster    = google_container_cluster.ak_private_gke_cluster.name
#   node_count = 1 # As per initialNodeCount in all-node-pools.json

#   node_config {
#     machine_type = "e2-micro"
#     disk_size_gb = 10
#     disk_type    = "pd-balanced"
#     service_account = "sa-bastion-vm@ak-here.iam.gserviceaccount.com"
#     # image_type   = "COS_CONTAINERD"
#     # service_account = "default" # default service account used by the original config

#     oauth_scopes = [
#       "https://www.googleapis.com/auth/devstorage.read_only",
#       "https://www.googleapis.com/auth/logging.write",
#       "https://www.googleapis.com/auth/monitoring",
#       "https://www.googleapis.com/auth/service.management.readonly",
#       "https://www.googleapis.com/auth/servicecontrol",
#       "https://www.googleapis.com/auth/trace.append",
#       "https://www.googleapis.com/auth/cloud-platform" # Added cloud-platform scope as it's common for GKE nodes
#     ]
#   }

#   autoscaling {
#     max_node_count = 1 # No specific autoscaling range, so keeping it fixed at 1 for cost saving.
#     min_node_count = 1
#   }

#   management {
#     auto_repair  = true
#     auto_upgrade = true
#   }

#   # Ensure the node pool uses private nodes
#   # network_config {
#   #   enable_private_nodes = true
#   # }
# }

# 7. Firewall Rule for Bastion SSH Access
# This rule allows SSH from anywhere (0.0.0.0/0) to instances tagged with 'bastion-host'.
# You'll apply this tag to your manually created bastion VM.
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

# 8. Firewall Rules for GKE Cluster
# These are the default firewall rules GKE creates. Recreating them ensures proper cluster function.

# Ingress: Allow all protocols from pod and cluster CIDRs to GKE nodes
# resource "google_compute_firewall" "gke_all_ingress" {
#   name        = "gke-${google_container_cluster.ak_private_gke_cluster.name}-all"
#   network     = google_compute_network.ak_vpc.self_link
#   description = "Allows all internal traffic within the GKE cluster."
#   priority    = 1000

#   allow {
#     protocol = "icmp"
#   }
#   allow {
#     protocol = "tcp"
#   }
#   allow {
#     protocol = "udp"
#   }
#   allow {
#     protocol = "esp"
#   }
#   allow {
#     protocol = "ah"
#   }
#   allow {
#     protocol = "sctp"
#   }

#   source_ranges = [
#     google_compute_subnetwork.ak_vpc_subnet.secondary_ip_range[2].ip_cidr_range, # GKE cluster CIDR (pods)
#     google_compute_subnetwork.ak_vpc_subnet.secondary_ip_range[0].ip_cidr_range  # Node pool pod CIDR
#   ]
#   target_tags = ["gke-${google_container_cluster.ak_private_gke_cluster.name}-node"]
# }

# # Ingress: Deny kubelet readonly port (10255) from 0.0.0.0/0 to GKE nodes
# resource "google_compute_firewall" "gke_exkubelet_ingress" {
#   name        = "gke-${google_container_cluster.ak_private_gke_cluster.name}-exkubelet"
#   network     = google_compute_network.ak_vpc.self_link
#   description = "Denies external access to the kubelet read-only port."
#   priority    = 1000

#   deny {
#     protocol = "tcp"
#     ports    = ["10255"]
#   }

#   source_ranges = ["0.0.0.0/0"]
#   target_tags   = ["gke-${google_container_cluster.ak_private_gke_cluster.name}-node"]
# }

# # Ingress: Allow kubelet readonly port (10255) from GKE nodes to GKE nodes
# resource "google_compute_firewall" "gke_inkubelet_ingress" {
#   name        = "gke-${google_container_cluster.ak_private_gke_cluster.name}-inkubelet"
#   network     = google_compute_network.ak_vpc.self_link
#   description = "Allows internal access to the kubelet read-only port."
#   priority    = 999 # Lower priority to allow this rule to take precedence over the deny rule for internal traffic

#   allow {
#     protocol = "tcp"
#     ports    = ["10255"]
#   }

#   source_tags = ["gke-${google_container_cluster.ak_private_gke_cluster.name}-node"]
#   target_tags = ["gke-${google_container_cluster.ak_private_gke_cluster.name}-node"]
# }

# # Ingress: Allow traffic from the primary subnet to GKE nodes (for control plane and general VPC communication)
# resource "google_compute_firewall" "gke_vms_ingress" {
#   name        = "gke-${google_container_cluster.ak_private_gke_cluster.name}-vms"
#   network     = google_compute_network.ak_vpc.self_link
#   description = "Allows traffic from the primary subnet to GKE nodes."
#   priority    = 1000

#   allow {
#     protocol = "icmp"
#   }
#   allow {
#     protocol = "tcp"
#     ports    = ["1-65535"]
#   }
#   allow {
#     protocol = "udp"
#     ports    = ["1-65535"]
#   }

#   source_ranges = [google_compute_subnetwork.ak_vpc_subnet.ip_cidr_range]
#   target_tags   = ["gke-${google_container_cluster.ak_private_gke_cluster.name}-node"]
# }


# Output the GKE cluster name and endpoint for easy access
output "gke_cluster_name" {
  description = "The name of the GKE cluster."
  value       = google_container_cluster.ak_private_gke_cluster.name
}

# output "gke_cluster_public_endpoint" {
#   description = "The public endpoint of the GKE cluster (if public access is enabled)."
#   value       = google_container_cluster.ak_private_gke_cluster.endpoint
# }

output "gke_cluster_private_endpoint" {
  description = "The private endpoint of the GKE cluster."
  value       = google_container_cluster.ak_private_gke_cluster.private_cluster_config[0].private_endpoint
}

output "bastion_ssh_firewall_rule_name" {
  description = "The name of the firewall rule allowing SSH to the bastion host."
  value       = google_compute_firewall.allow_ssh_bastion.name
}

output "vpc_name" {
  description = "The name of the VPC network."
  value       = google_compute_network.ak_vpc.name
}

output "subnet_name" {
  description = "The name of the subnetwork."
  value       = google_compute_subnetwork.ak_vpc_subnet.name
}