variable "credentials_file" { 
  default = "/home/jac5499/.config/gcloud/application_default_credentials.json"
}

variable "project" {
  default = "cis91-project"
}

variable "region" {
  default = "us-central1"
}

variable "zone" {
  default = "us-central1-c"
}

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "3.5.0"
    }
  }
}

provider "google" {
  credentials = file(var.credentials_file)
  region  = var.region
  zone    = var.zone 
  project = var.project
}

resource "google_compute_network" "vpc_network" {
  name = "mediawiki-network"
}

resource "google_compute_instance" "webservers" {
  count        = 3
  name         = "web${count.index}"
  machine_type = "e2-micro"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2004-lts"
    }
  }

  attached_disk {
    source = google_compute_disk.mediawiki.self_link
    device_name = "mediawiki"
  }

  tags = ["web"]
  labels = {
    name: "web${count.index}"
  }
}

  network_interface {
    network = google_compute_network.vpc_network.name
    access_config {
    }
  }

resource "google_compute_disk" "mediawiki" {
  name  = "mediawiki-data"
  type  = "pd-ssd"
  size = "128"
  labels = {
    environment = "dev"
  }
  physical_block_size_bytes = 4096
}

resource "google_compute_firewall" "default-firewall" {
  name = "default-firewall"
  network = google_compute_network.vpc_network.name
  allow {
    protocol = "tcp"
    ports = ["22", "80"]
  }
  source_ranges = ["0.0.0.0/0"]
}

output "external-ip" {
  value = google_compute_instance.webservers[*].network_interface[0].access_config[0].nat_ip
}
