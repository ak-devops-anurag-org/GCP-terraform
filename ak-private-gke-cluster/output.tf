output "vpc_name" {
  description = "The name of the VPC network."
  value       = google_compute_network.ak_vpc.name
}

output "subnet_name" {
  description = "The name of the subnetwork."
  value       = google_compute_subnetwork.ak_vpc_subnet.name
}

output "gke_cluster_name" {
  description = "The name of the GKE cluster."
  value       = google_container_cluster.ak_private_gke_cluster.name
}

output "gke_cluster_private_endpoint" {
  description = "The private endpoint of the GKE cluster."
  value       = google_container_cluster.ak_private_gke_cluster.private_cluster_config[0].private_endpoint
}

output "bastion_ssh_firewall_rule_name" {
  description = "The name of the firewall rule allowing SSH to the bastion host."
  value       = google_compute_firewall.allow_ssh_bastion.name
}


output "pods_secondary_range_name" {
  description = "Secondary IP range name for GKE Pods"
  value       = google_compute_subnetwork.ak_vpc_subnet.secondary_ip_range[0].range_name
}

output "services_secondary_range_name" {
  description = "Secondary IP range name for GKE Services"
  value       = google_compute_subnetwork.ak_vpc_subnet.secondary_ip_range[1].range_name
}

# output "gke_cluster_public_endpoint" {
#   description = "The public endpoint of the GKE cluster (if public access is enabled)."
#   value       = google_container_cluster.ak_private_gke_cluster.endpoint
# }