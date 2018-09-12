require_relative "services-config"
include ServicesConfig

###############################################################################
# MAIN
###############################################################################

# Script input

tag = ARGV.shift || "latest"
service_to_build = ARGV.shift || "all"

# Image build/push

gcp_project_id = SERVICES_CONFIG["gcpProjectId"]
project_name = SERVICES_CONFIG["projectName"]

SERVICES_CONFIG["services"].each do |service_name, config|
  if service_name == service_to_build || service_to_build == "all"
    image = "gcr.io/#{gcp_project_id}/#{project_name}-#{service_name}:#{tag}"

    system("docker build -t #{image} ./services/#{service_name}")
    system("docker push #{image}")
  end
end
