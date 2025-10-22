
# Outputs
output "vpc_name" {
  description = "VPC network name"
  value       = google_compute_network.gke_vpc.name
}

output "gke_subnet_name" {
  description = "GKE subnet name"
  value       = google_compute_subnetwork.gke_subnet.name
}

output "bastion_subnet_name" {
  description = "Bastion subnet name"
  value       = google_compute_subnetwork.bastion_subnet.name
}

output "gke_cluster_name" {
  description = "GKE cluster name"
  value       = google_container_cluster.primary.name
}

# output "gke_cluster_endpoint" {
#   description = "GKE cluster endpoint"
#   value       = google_container_cluster.primary.endpoint
#   sensitive   = true
# }

# output "gke_cluster_ca_certificate" {
#   description = "GKE cluster CA certificate"
#   value       = google_container_cluster.primary.master_auth[0].cluster_ca_certificate
#   sensitive   = true
# }

output "nat_gateway_name" {
  description = "Cloud NAT gateway name"
  value       = google_compute_router_nat.nat_gateway.name
}

output "get_credentials_command" {
  description = "Command to get GKE credentials"
  value       = "gcloud container clusters get-credentials ${google_container_cluster.primary.name} --zone ${var.zone} --project ${var.project_id}"
}