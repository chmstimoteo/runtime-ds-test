require "yaml"

module ServicesConfig
  # Constants

  VALUES_FOLDER = "helm/values"
  BASE_VALUES_FILE = "#{VALUES_FOLDER}/values.yaml"

  # Configuration loading

  SERVICES_CONFIG = YAML.load_file(BASE_VALUES_FILE)

  # Configuration values

  PROJECT_TITLE = SERVICES_CONFIG["projectTitle"]
  PROJECT_NAME = SERVICES_CONFIG["projectName"]
  PROJECT_ID = SERVICES_CONFIG["gcpProjectId"]
  PROJECT_ZONE = SERVICES_CONFIG["gcpProjectZone"]

  SERVICE_ACCOUNT = "#{PROJECT_NAME}-account"
  SERVICE_ACCOUNT_ROLE = "roles/editor"
  FULLY_QUALIFIED_SERVICE_ACCOUNT = "#{SERVICE_ACCOUNT}@#{PROJECT_ID}.iam.gserviceaccount.com"

  SERVICE_ACCOUNT_TOKEN_CREATOR_ROLE = "roles/iam.serviceAccountTokenCreator"
  CONTAINER_ADMIN_ROLE = "roles/container.admin"

  APIS_TO_ENABLE = [
    "cloudbuild.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "containerregistry.googleapis.com",
    "replicapool.googleapis.com",
    "replicapoolupdater.googleapis.com",
    "resourceviews.googleapis.com"
  ]

  TERRAFORM_STATE_BUCKET = "#{PROJECT_NAME}-terraform"
end
