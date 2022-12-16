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
  name = "dokuwiki-network"
}

resource "google_compute_instance" "vm_instance" {
  name         = "cis91"
  machine_type = "e2-micro"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2004-lts"
    }
  }

  network_interface {
    network = google_compute_network.vpc_network.name
    access_config {
    }
  }

  attached_disk {
    source = google_compute_disk.dokuwiki.self_link
    device_name = "dokuwiki"
  }
}

resource "google_compute_firewall" "default-firewall" {
  name = "dokuwiki-firewall"
  network = google_compute_network.vpc_network.name
  allow {
    protocol = "tcp"
    ports = ["22", "80"]
  }
  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_disk" "dokuwiki" {
  name  = "dokuwiki-data"
  type  = "pd-ssd"
  size = "128"
  labels = {
    environment = "dev"
  }
  physical_block_size_bytes = 4096
}

output "external-ip" {
  value = google_compute_instance.vm_instance.network_interface[0].access_config[0].nat_ip
}
