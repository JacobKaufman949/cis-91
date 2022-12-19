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

/* resource "google_service_account" "dokuwiki-service-account" {
  account_id   = "dokuwiki-service-account"
  display_name = "dokuwiki-service-account"
  description = "Service account for dokuwiki"
}

resource "google_project_iam_member" "project_member" {
  role = "roles/compute.viewer"
  member = "serviceAccount:${google_service_account.dokuwiki-service-account.email}"
} */

data "google_iam_policy" "admin" {
  binding {
    role = "roles/storage.objectadmin"
    members = [
      "user:jdkaufman00@gmail.com",
    ]
  }
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

   /* service_account {
    email  = google_service_account.dokuwiki-service-account.email
    scopes = ["cloud-platform"]
  } */
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
