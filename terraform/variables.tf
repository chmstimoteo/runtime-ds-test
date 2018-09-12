variable "gcp_project" {
    default = "eds-sandbox-186722"
}

variable "project_codename" {
    default = "runtime-ds-test"
}

variable "bucket_prefix" {
    default = "runtime-ds-test"
}

variable "region" {
    default = "us-east1"
}

variable "zone" {
    default = "us-east1-d"
}

variable "cluster_name" {
    default = "runtime-ds-test-cluster"
}

variable "cluster_initial_node_count" {
    default = "3"
}

variable "cluster_machine_type" {
    default = "n1-standard-1"
}
