# VPC Network
resource "google_compute_network" "gke_vpc" {
  name                    = "gke-cluster-vpc-tf"
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
}

# Subnet for GKE cluster (private nodes with Cloud NAT)
resource "google_compute_subnetwork" "gke_subnet" {
  name          = "gke-subnet"
  ip_cidr_range = "10.0.0.0/20"
  region        = var.region
  network       = google_compute_network.gke_vpc.id

  # Secondary IP ranges for GKE pods and services
  secondary_ip_range {
    range_name    = "gke-pods-range"
    ip_cidr_range = "10.4.0.0/14"
  }

  secondary_ip_range {
    range_name    = "gke-services-range"
    ip_cidr_range = "10.8.0.0/20"
  }

  private_ip_google_access = true
}

# Subnet for Bastion VM
resource "google_compute_subnetwork" "bastion_subnet" {
  name          = "bastion-subnet"
  ip_cidr_range = "10.1.0.0/24"
  region        = var.region
  network       = google_compute_network.gke_vpc.id

  private_ip_google_access = true
}

# Cloud Router for Cloud NAT
resource "google_compute_router" "nat_router" {
  name    = "gke-nat-router"
  region  = var.region
  network = google_compute_network.gke_vpc.id
}

# Cloud NAT for private GKE nodes to access internet
resource "google_compute_router_nat" "nat_gateway" {
  name                               = "gke-nat-gateway"
  router                             = google_compute_router.nat_router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  subnetwork {
    name                    = google_compute_subnetwork.gke_subnet.id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}


# Firewall rule to allow SSH to bastion
resource "google_compute_firewall" "bastion_ssh" {
  name    = "allow-ssh-bastion"
  network = google_compute_network.gke_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"] # Restrict to your IP in production
  target_tags   = ["bastion"]
}

# Firewall rule to allow internal communication
resource "google_compute_firewall" "internal" {
  name    = "allow-internal"
  network = google_compute_network.gke_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = ["10.0.0.0/8"]
}

# Firewall rule to allow GKE nodes to access Google APIs
resource "google_compute_firewall" "allow_google_apis" {
  name    = "allow-gke-google-apis"
  network = google_compute_network.gke_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  source_ranges = [google_compute_subnetwork.gke_subnet.ip_cidr_range]
  direction     = "EGRESS"
  destination_ranges = ["199.36.153.8/30"] # Google APIs
}

# GKE Cluster (cost-optimized for learning)
resource "google_container_cluster" "primary" {
  name     = "gke-learning-cluster"
  location = var.zone

  # Regional clusters are more expensive, using zonal for cost savings
  network    = google_compute_network.gke_vpc.name
  subnetwork = google_compute_subnetwork.gke_subnet.name

  # Remove default node pool immediately
  remove_default_node_pool = true
  initial_node_count       = 1

  # Private cluster configuration
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false # Set to true for fully private, access via bastion
    master_ipv4_cidr_block  = "172.16.0.0/28"
  }

  # IP allocation for pods and services
  ip_allocation_policy {
    cluster_secondary_range_name  = "gke-pods-range"
    services_secondary_range_name = "gke-services-range"
  }

  # Master authorized networks - allow bastion subnet
  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = google_compute_subnetwork.bastion_subnet.ip_cidr_range
      display_name = "bastion-subnet"
    }
    # Allow public access for easier learning (remove in production)
    cidr_blocks {
      cidr_block   = "0.0.0.0/0"
      display_name = "public-access"
    }
  }

  # Disable features to reduce costs
  addons_config {
    http_load_balancing {
      disabled = false
    }
    horizontal_pod_autoscaling {
      disabled = false
    }
  }

  # Maintenance window
  maintenance_policy {
    daily_maintenance_window {
      start_time = "03:00"
    }
  }

  # Logging and monitoring (minimal for cost savings)
  logging_config {
    enable_components = ["SYSTEM_COMPONENTS"]
  }

  monitoring_config {
    enable_components = ["SYSTEM_COMPONENTS"]
    managed_prometheus {
      enabled = false
    }
  }

  # Workload Identity
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }
}

# Cost-optimized Node Pool
resource "google_container_node_pool" "primary_nodes" {
  name       = "cost-optimized-pool"
  location   = var.zone
  cluster    = google_container_cluster.primary.name
  node_count = 1 # Start with 1 node for cost savings

  # Autoscaling configuration
  autoscaling {
    min_node_count = 1
    max_node_count = 1
  }

  # Node configuration
  node_config {
    preemptible  = true # Use preemptible VMs for 80% cost savings
    machine_type = "e2-small" # Smallest machine type (2 vCPU, 2GB RAM)

    # Service account with minimal permissions
    service_account = google_service_account.gke_nodes.email

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/trace.append"
    ]

    labels = {
      environment = "learning"
      purpose     = "cost-optimized"
    }

    tags = ["gke-node"]

    # Shielded instance config
    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }

    # Workload Identity
    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    disk_size_gb = 10 # Minimal disk size
    disk_type    = "pd-standard" # Standard persistent disk (cheaper)
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }
}

# Service Account for GKE nodes
resource "google_service_account" "gke_nodes" {
  account_id   = "gke-node-sa"
  display_name = "GKE Node Service Account"
}

# IAM bindings for GKE node service account
resource "google_project_iam_member" "gke_node_sa_log_writer" {
  project = var.project_id
  role    = "roles/owner"
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

# resource "google_project_iam_member" "gke_node_sa_log_writer" {
#   project = var.project_id
#   role    = "roles/logging.logWriter"
#   member  = "serviceAccount:${google_service_account.gke_nodes.email}"
# }

# resource "google_project_iam_member" "gke_node_sa_metric_writer" {
#   project = var.project_id
#   role    = "roles/monitoring.metricWriter"
#   member  = "serviceAccount:${google_service_account.gke_nodes.email}"
# }

# resource "google_project_iam_member" "gke_node_sa_monitoring_viewer" {
#   project = var.project_id
#   role    = "roles/monitoring.viewer"
#   member  = "serviceAccount:${google_service_account.gke_nodes.email}"
# }
