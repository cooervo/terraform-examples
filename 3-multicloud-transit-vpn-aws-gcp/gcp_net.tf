resource "google_compute_network" "main" {
  name                    = "main"
  auto_create_subnetworks = "false"
  project                 = var.gcp_project_id
}

resource "google_compute_subnetwork" "subnet" {
  name          = "subnet"
  ip_cidr_range = var.gcp_cidr
  network       = google_compute_network.main.self_link
  project       = var.gcp_project_id
}

// this is only needed to allow VM without external IP to access internet
resource "google_compute_router" "router" {
  name    = "router"
  region  = var.gcp_region
  network = google_compute_network.main.id
}


// this is only needed to allow VM without external IP to access internet
resource "google_compute_router_nat" "nat" {
  name                               = "my-router-nat"
  router                             = google_compute_router.router.name
  region                             = google_compute_router.router.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

resource "google_compute_firewall" "icmp_ingress_rule" {
  name    = "allow-aws-ingress"
  network = google_compute_network.main.name

  allow {
    protocol = "icmp"
  }

  source_ranges = [var.aws_cidr]
  direction     = "INGRESS"
}

resource "google_compute_firewall" "icmp_egress_rule" {
  name    = "allow-aws-cidr-egress"
  network = google_compute_network.main.name

  allow {
    protocol = "icmp"
  }

  destination_ranges = [var.aws_cidr]
  direction          = "EGRESS"
  target_tags        = [local.app_server]
}

resource "google_compute_firewall" "allow_ssh" {
  name    = "allow-ssh"
  network = google_compute_network.main.name
  project = var.gcp_project_id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = [local.app_server]

}


# allow traffic from AWS CIDR range into GCP CIDR range
resource "google_compute_firewall" "allow_tcp_from_aws_cidr" {
  name    = "allow-tcp-from-aws-cidr"
  network = google_compute_network.main.name
  project = var.gcp_project_id

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  source_ranges      = [var.aws_cidr]
  destination_ranges = [var.gcp_cidr]
  target_tags        = [local.app_server]

}
