# Data
data "google_client_config" "current" {}


# Network: VPC + Subnet + Secondary ranges
resource "google_compute_network" "vpc" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
  # routing_mode            = "REGIONAL"
}

resource "google_compute_subnetwork" "gke_private_subnet" {
  name                     = "${var.vpc_name}-subnet"
  region                   = var.region
  network                  = google_compute_network.vpc.id
  ip_cidr_range            = var.subnet_cidr
  
  private_ip_google_access = true

  secondary_ip_range {
    range_name    = "pods-range"
    ip_cidr_range = var.pods_range_cidr
  }

  secondary_ip_range {
    range_name    = "services-range"
    ip_cidr_range = var.services_range_cidr
  }
}

resource "google_compute_subnetwork" "public_subnet" {
  name          = "${var.vpc_name}-public-subnet"
  region        = var.region
  ip_cidr_range = var.public_subnet_cidr
  network       = google_compute_network.vpc.id
}

############################
# Cloud Router + Cloud NAT
############################
resource "google_compute_router" "nat_router" {
  name    = "${var.vpc_name}-router"
  network = google_compute_network.vpc.id
  region  = var.region
}

resource "google_compute_router_nat" "cloud_nat" {
  name                               = "${var.vpc_name}-nat"
  router                             = google_compute_router.nat_router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  # min_ports_per_vm                   = 64
}

############################
# Firewall rules (basic)
############################
# Allow SSH only to Bastion
resource "google_compute_firewall" "allow_ssh" {
  name    = "${var.vpc_name}-allow-ssh"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["bastion"]
}

# Allow Bastion subnet to reach GKE control plane
resource "google_compute_firewall" "allow_bastion_to_master" {
  name    = "${var.vpc_name}-allow-bastion-to-master"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  source_ranges = [var.public_subnet_cidr]
  direction     = "EGRESS"
}

############################
# Service Account for Node Pool
############################
resource "google_service_account" "gke_node_sa" {
  account_id   = "gke-node-sa-tf"
  display_name = "GKE Node Service Account using tf"
}

# Assign Editor role for POC purpose (broad permissions)
resource "google_project_iam_member" "node_sa_editor" {
  project = var.project
  role    = "roles/owner"
  member  = "serviceAccount:${google_service_account.gke_node_sa.email}"
}


# Project-level role bindings for the node service account
# NOTE: For POC/learning we grant a set of roles to ensure node creation succeeds.
# Later you can reduce to least privilege (container.nodeServiceAgent, compute.instanceAdmin.v1, iam.serviceAccountUser, logging, monitoring).
# resource "google_project_iam_member" "node_sa_container_admin" {
#   project = var.project
#   role    = "roles/container.admin"
#   member  = "serviceAccount:${google_service_account.gke_node_sa.email}"
# }

# resource "google_project_iam_member" "node_sa_compute_admin" {
#   project = var.project
#   role    = "roles/compute.admin"
#   member  = "serviceAccount:${google_service_account.gke_node_sa.email}"
# }

# resource "google_project_iam_member" "node_sa_network_admin" {
#   project = var.project
#   role    = "roles/compute.networkAdmin"
#   member  = "serviceAccount:${google_service_account.gke_node_sa.email}"
# }

# resource "google_project_iam_member" "node_sa_servicenetworking" {
#   project = var.project
#   role    = "roles/servicenetworking.networksAdmin"
#   member  = "serviceAccount:${google_service_account.gke_node_sa.email}"
# }

# resource "google_project_iam_member" "node_sa_iam_user" {
#   project = var.project
#   role    = "roles/iam.serviceAccountUser"
#   member  = "serviceAccount:${google_service_account.gke_node_sa.email}"
# }

# resource "google_project_iam_member" "node_sa_logging" {
#   project = var.project
#   role    = "roles/logging.logWriter"
#   member  = "serviceAccount:${google_service_account.gke_node_sa.email}"
# }

# resource "google_project_iam_member" "node_sa_monitoring" {
#   project = var.project
#   role    = "roles/monitoring.metricWriter"
#   member  = "serviceAccount:${google_service_account.gke_node_sa.email}"
# }


#######################################################
# GKE PRIVATE CLUSTER
#######################################################
resource "google_container_cluster" "gke_private" {
  name     = var.cluster_name
  location = var.zone
  network    = google_compute_network.vpc.name
  subnetwork = google_compute_subnetwork.gke_private_subnet.name

  remove_default_node_pool = true
  initial_node_count       = 1

  ip_allocation_policy {
    cluster_secondary_range_name  = "pods-range"
    services_secondary_range_name = "services-range"
  }

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false   # to access master from internet (can be false if using bastion only)
    master_ipv4_cidr_block  = "10.10.0.0/28"
  }

  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = "10.20.0.0/28"  # Bastion subnet
      display_name = "net1"
    }

  }

  # release_channel {
  #   channel = "REGULAR"
  # }

  # cluster_autoscaling {
  #   auto_provisioning_defaults {
  #     disk_size = 10
  #     disk_type = "pd-standard"  
  #   }
  #   enabled = false  
  # }

  # enable_shielded_nodes = true

  

  depends_on = [google_compute_router.nat_router,google_compute_router_nat.cloud_nat]
}

#######################################################
# NODE POOL
#######################################################
resource "google_container_node_pool" "primary_pool" {
  name     = "primary-pool"
  location = var.zone
  cluster  = google_container_cluster.gke_private.name
  node_count = 1

  node_config {
    machine_type    = "e2-small" # smallest possible - e2-micro
    service_account = google_service_account.gke_node_sa.email

    disk_size_gb = 10
    # disk_type    = "pd-standard"  # Explicitly use standard disk

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
      # "https://www.googleapis.com/auth/devstorage.read_only",
      # "https://www.googleapis.com/auth/logging.write",
      # "https://www.googleapis.com/auth/monitoring"
    ]
  }

  autoscaling {
    min_node_count = 1
    max_node_count = 1
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }
}

############################
# Bastion VM (small, public IP) - for access to private cluster
############################

## Create jump host . We will allow this jump host to access GKE cluster. the ip of this jump host is already authorized to allowin the GKE cluster

# resource "google_compute_address" "my_internal_ip_addr" {
#   project      = "tcb-project-371706"
#   address_type = "INTERNAL"
#   region       = "asia-south2"
#   subnetwork   = "subnet1"
#   name         = "my-ip"
#   address      = "10.0.0.7"
#   description  = "An internal IP address for my jump host"
# }

# resource "google_compute_instance" "default" {
#   project      = "tcb-project-371706"
#   zone         = "asia-south2-a"
#   name         = "jump-host"
#   machine_type = "e2-medium"

#   boot_disk {
#     initialize_params {
#       image = "debian-cloud/debian-11"
#     }
#   }
#   network_interface {
#     network    = "vpc1"
#     subnetwork = "subnet1" # Replace with a reference or self link to your subnet, in quotes
#     network_ip         = google_compute_address.my_internal_ip_addr.address
#   }

# }

# --------------------------------------------------
# resource "google_compute_instance" "bastion" {
#   name         = "bastion-vm"
#   machine_type = "e2-micro"
#   zone         = var.zone

#   boot_disk {
#     initialize_params {
#       image = "projects/debian-cloud/global/images/family/debian-12"
#       size  = 10
#       type  = "pd-balanced"
#     }
#   }

#   network_interface {
#     network    = google_compute_network.vpc.id
#     subnetwork = google_compute_subnetwork.private_.name

#     access_config {
#       # Ephemeral external IP for SSH from internet / console SSH
#     }
#   }

#   # Allow the console "SSH" button (OS Login not required here)
#   metadata = {
#     enable-oslogin = "FALSE"
#   }

#   tags = ["bastion"]
# }
