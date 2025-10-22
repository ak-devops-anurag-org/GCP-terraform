output "cluster_name" {
  value = google_container_cluster.gke_private.name
}

# output "cluster_endpoint" {
#   value = google-beta_container_cluster.gke_private.endpoint
# }

# output "bastion_external_ip" {
#   value = google_compute_instance.bastion.network_interface[0].access_config[0].nat_ip
# }

output "node_service_account_email" {
  value = google_service_account.gke_node_sa.email
}

# output "gke_subnet_selflink" {
#   value = google_compute_subnetwork.gke_subnet.self_link
# }
