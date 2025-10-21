resource "google_compute_firewall" "allow-ssh" {
  name    = "allow-ssh"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]  # Open to all IPs
  target_tags   = ["allow-ssh"]
  direction     = "INGRESS"
}

resource "google_compute_firewall" "allow-http" {
  name    = "allow-http"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["allow-http"]
  direction     = "INGRESS"
}

resource "google_compute_firewall" "allow-https" {
  name    = "allow-https"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["allow-https"]
  direction     = "INGRESS"
}

resource "google_compute_instance" "vm_instance" {
  name         = "ak-tf-compute-instance"
  machine_type = "e2-micro"  # Modern free-tier eligible
  zone         = "asia-south1-a"

  tags = ["ak", "tf", "compute-instance", "allow-ssh", "allow-http", "allow-https"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size  = 10
      labels = {
        my_label = "value"
      }
    }
  }

  network_interface {
    network = "default"

    access_config {
      // Ephemeral public IP
    }
  }

  # metadata = {
  #   foo = "bar"
  # }

  metadata_startup_script = "echo hi > /var/log/test.txt"
}
