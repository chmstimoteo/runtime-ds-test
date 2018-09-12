################################################################################
# TERRAFORM CONFIGURATION
################################################################################

# Terraform state is backed by a GCP Storage bucket for remote state. 
# This way, more than one person can access/use Terraform.
terraform {
    backend "gcs" {
        # NOTE: Don't have access to ${var} here.
        credentials = "./runtime-ds-test-account.json"
        bucket = "runtime-ds-test-terraform"
    }
}

# Use GCP by default.
provider "google" {
    credentials = "./${var.project_codename}-account.json"
    project = "${var.gcp_project}"
    region = "${var.region}"
}

################################################################################
# MANDATORY RESOURCES
################################################################################

# The static IP address that is used for the production backend API service.
resource "google_compute_address" "backend" {
    name = "${var.project_codename}-backend-ip"
}

# The static IP address that is used for the development backend API service.
resource "google_compute_address" "backend_development" {
    name = "${var.project_codename}-backend-development-ip"
}

# The separate VPC network to use just for the Kubernetes cluster.
# The reason we need this is so that we can allocate a subnetwork with
# secondary IP ranges to enable IP aliasing for the cluster.
# And the reason we need IP aliasing is to use the Redis (GCP Memorystore) service
# (not configured here by default).
resource "google_compute_network" "primary" {
    name = "${var.project_codename}-network"
    auto_create_subnetworks = "false"
}

# The special subnetwork that is used to enable IP aliasing for the cluster.
resource "google_compute_subnetwork" "primary" {
    depends_on = ["google_compute_network.primary"]

    name = "${var.project_codename}-subnetwork"
    network = "${google_compute_network.primary.self_link}"
    region = "${var.region}"

    # The IP range for us-east1 in an Auto Mode network; arbitrarily chosen.
    # Can be changed if necessary.
    ip_cidr_range = "10.142.0.0/20"

    # These secondary ranges are kinda arbitrary; they were picked from a GKE Cluster
    # that had automatically generated them (can't seem to do that from Terraform).
    # But we need them for the ip_allocation_policy for the Kubernetes cluster to ensure
    # IP aliases get enabled. They can be changed if necessary.
    secondary_ip_range = {
        range_name = "gke-${var.project_codename}-pods"
        ip_cidr_range = "10.60.0.0/14"
    }

    secondary_ip_range = {
        range_name = "gke-${var.project_codename}-services"
        ip_cidr_range = "10.125.0.0/20"
    }
}

# The Kubernetes cluster where all of the application containers will be deployed to.
resource "google_container_cluster" "primary" {
    depends_on = ["google_compute_subnetwork.primary"]

    name = "${var.cluster_name}"
    zone = "${var.zone}"
    initial_node_count = "${var.cluster_initial_node_count}"

    network = "${google_compute_network.primary.self_link}"
    subnetwork = "${google_compute_subnetwork.primary.self_link}"

    min_master_version = "1.10.6-gke.2"
    monitoring_service = "monitoring.googleapis.com/kubernetes"
    logging_service = "logging.googleapis.com/kubernetes"

    # Need to have an IP allocation policy setup so that IP Aliases get enabled.
    # And we need IP Aliases enabled to access the Memorystore (Redis) instance.
    # See Step 2 of https://cloud.google.com/memorystore/docs/redis/connecting-redis-instance#connecting-cluster
    ip_allocation_policy = {
        cluster_secondary_range_name = "gke-${var.project_codename}-pods"
        services_secondary_range_name = "gke-${var.project_codename}-services"
    }

    node_config {
        machine_type = "${var.cluster_machine_type}"

        oauth_scopes = [
            "https://www.googleapis.com/auth/compute",
            "https://www.googleapis.com/auth/devstorage.read_only",
            "https://www.googleapis.com/auth/logging.write",
            "https://www.googleapis.com/auth/monitoring",
            "https://www.googleapis.com/auth/cloud-platform",
        ]

        tags = ["${var.cluster_name}", "nodes"]
    }
}

# A persistent data disk (SSD) that can be used to store models on for fast access by the cluster.
resource "google_compute_disk" "model_storage" {
    name = "${var.project_codename}-model-storage-ssd"
    type = "pd-ssd"
    zone = "${var.zone}"
    size = "15"
}

################################################################################
# OPTIONAL RESOURCES
################################################################################

# A Redis instance that the Kubernetes cluster can access.
#
# resource "google_redis_instance" "primary" {
#     depends_on = ["google_compute_network.primary"]
# 
#     name = "${var.project_codename}-redis"
#     tier = "BASIC"
#     memory_size_gb = 1
# 
#     region = "${var.region}"
#     location_id = "${var.zone}"
#     authorized_network = "${google_compute_network.primary.self_link}" 
#     reserved_ip_range = "10.0.0.0/29"
# }

# A Cloud Storage bucket for holding models.
# 
# resource "google_storage_bucket" "models_bucket" {
#     name = "${var.bucket_prefix}-models-1"
#     storage_class = "REGIONAL"
#     location = "${var.region}"
# }

################################################################################
# MANDATORY OUTPUT VALUES
################################################################################

output "cluster_name" {
    value = "${google_container_cluster.primary.name}"
}

output "backend_ip" {
    value = "${google_compute_address.backend.address}"
}

output "backend_development_ip" {
    value = "${google_compute_address.backend_development.address}"
}

output "model_storage_disk_name" {
    value = "${google_compute_disk.model_storage.name}"
}

################################################################################
# OPTIONAL OUTPUT VALUES
################################################################################

# output "redis_ip" {
#     value = "${google_redis_instance.primary.host}"
# }
# 
# output "redis_port" {
#     value = "${google_redis_instance.primary.port}"
# }
