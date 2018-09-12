################################################################################
# TERRAFORM CONFIGURATION
################################################################################

# NOTE: Due to an inconsistency in how the 'terraform' CLI works (see here: https://github.com/hashicorp/terraform/issues/15761),
# this block of remote state configuration has to be duplicated in here ('root.tf') and in 'terraform/main.tf'.
# In particular, it's because the 'terraform output' command doesn't take a directory as an argument, even though other commands do.

# Terraform state is backed by a GCP Storage bucket for remote state. 
# This way, more than one person can access/use Terraform.
terraform {
    backend "gcs" {
        # NOTE: Don't have access to ${var} here.
        credentials = "./runtime-ds-test-account.json"
        bucket = "runtime-ds-test-terraform"
    }
}
