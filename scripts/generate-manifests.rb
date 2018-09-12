require_relative "services-config"
include ServicesConfig

###############################################################################
# MAIN
###############################################################################

# Constants

TEMPLATES_FOLDER = "templates"
MANIFESTS_FOLDER="manifests/generated"

# Script input and derived values

tag = ARGV.shift || "latest"
namespace = ARGV.shift || "development"

subdomain = if namespace == "production" then "" else "#{namespace}." end

# Clean up of old manifests

system("find ./manifests/generated -type f -name '*.yaml' -delete")
puts "\n[INFO] Removed old manifests."

# Manifest generation

puts "\n[INFO] Generating new manifests..."

SERVICES_CONFIG["services"].each do |service_name, config|
  templates = config["templates"].map {|template| "-x #{TEMPLATES_FOLDER}/#{template}.yaml"}.join(" ")

  command = "
    helm template \
      --output-dir #{MANIFESTS_FOLDER}/#{service_name} \
      --values #{BASE_VALUES_FILE} \
      --values #{VALUES_FOLDER}/values_#{service_name}.yaml \
      --values #{VALUES_FOLDER}/values_#{namespace}.yaml \
      --set-string tag=#{tag} \
      --set-string namespace=#{namespace} \
      --set-string subdomain=#{subdomain} \
      #{templates} \
      helm
  "

  system(command)
end

puts "\n[INFO] Finished generating manifests."
