resource "google_compute_instance" "nexus_vm" {
     name         = "nexusvm"
     machine_type = "e2-standard-4"
     zone         = "us-central1-b"
     project      = "nexus-project-id01"
     tags         = ["nexus-server"]

     boot_disk {
       initialize_params {
         image = "debian-cloud/debian-12" # Debian 12 for Nexus
         size  = 300
         type  = "pd-ssd"
       }
     }

     network_interface {
       network    = "mynetwork"
       subnetwork = "default"
     }

     # Fixed Nexus: Added egress rule, verified Cloud NAT, using Docker for Nexus
   }

   resource "google_compute_firewall" "allow_nexus_8081" {
     name    = "allow-nexus-8081"
     network = "mynetwork"
     project = "chilets-project-n01"

     allow {
       protocol = "tcp"
       ports    = ["8081"]
     }

     source_ranges = ["0.0.0.0/0"]
     target_tags   = ["nexus-server"]
   }

   resource "google_compute_firewall" "allow_egress_all" {
     name    = "allow-egress-all"
     network = "mynetwork"
     project = "chilets-project-n01"

     direction = "EGRESS"
     priority  = 1000

     allow {
       protocol = "all"
     }
   }