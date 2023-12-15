
locals {
  app_server = "app-server"
}
resource "google_compute_instance" "example_instance" {
  name         = "gcp-node-app"
  machine_type = "e2-micro"

  zone = "${var.gcp_region}-b"
  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2004-lts"
    }
  }

  metadata_startup_script = <<-SCRIPT
    #!/bin/bash
    
    sudo apt-get update
    
    sudo apt-get install -y docker.io
    
    docker pull cooervo/simple-nodejs
    
    sudo docker run -d -p 80:3000 cooervo/simple-nodejs "Hi from GCP!"
  SCRIPT

  network_interface {
    subnetwork         = google_compute_subnetwork.subnet.name
    subnetwork_project = var.gcp_project_id
  }

  tags = [local.app_server, "http-server", "https-server"]
}
