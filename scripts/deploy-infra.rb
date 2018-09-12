require_relative "services-config"
include ServicesConfig

###############################################################################
# MAIN
###############################################################################

# Deploy infrastructure

puts "\n[INFO] Deploying Terraform infrastructure..."
system("terraform apply terraform")

# Update Helm value files with new Terraform values

puts "\n[INFO] Updating Helm values..."
system("ruby ./scripts/update-helm-values.rb")

# Get credentials to the cluster to enable kubectl

puts "\n[INFO] Getting cluster credentials..."

cluster = `terraform output cluster_name`.strip
system("gcloud container clusters get-credentials --zone #{PROJECT_ZONE} #{cluster}")

# Create the default namespaces

puts "\n[INFO] Deploying default namespaces..."
system("kubectl apply --recursive -f manifests/static/namespaces")
