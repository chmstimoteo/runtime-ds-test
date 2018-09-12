require_relative "services-config"
require_relative "triggers-config"

include ServicesConfig
include TriggersConfig

###############################################################################
# GLOBAL VARIABLES
###############################################################################

$exit_status = true

###############################################################################
# HELPER FUNCTIONS
###############################################################################

def verify_resource(resource, command, success_message = "exists", error_message = "does not exist")
  status = system("#{command}", out: File::NULL)

  if status
    puts "✔ #{resource} #{success_message}."
    $exit_status = $exit_status && true
  else
    puts "✗ #{resource} #{error_message}."
    $exit_status = $exit_status && false
  end
end

###############################################################################
# MAIN
###############################################################################

puts "\n[INFO] Switching to project #{PROJECT_ID}..."
system("gcloud config set project #{PROJECT_ID}")

puts ""  # Extra spacing

account_email = `gcloud config get-value account 2>/dev/null`.strip
project_number=`gcloud projects describe #{PROJECT_ID} --format="value(projectNumber)"`.strip

# Project service account

verify_resource(
  "Service account #{SERVICE_ACCOUNT}",
  "gcloud iam service-accounts list | grep #{SERVICE_ACCOUNT}"
)

# Project service account role binding

verify_resource(
  "Service account role binding #{SERVICE_ACCOUNT_ROLE}",
  "gcloud projects get-iam-policy #{PROJECT_ID} \
    --filter='bindings.members:#{SERVICE_ACCOUNT}' \
    --flatten='bindings[].members' --format='value(bindings.role)' 2> /dev/null \
    | grep #{SERVICE_ACCOUNT_ROLE}"
)

# Owner user role binding

verify_resource(
  "ServiceAccountTokenCreator role for #{account_email}",
  "gcloud projects get-iam-policy #{PROJECT_ID} \
    --filter='bindings.members:#{account_email}' \
    --flatten='bindings[].members' --format='value(bindings.role)' 2> /dev/null \
    | grep #{SERVICE_ACCOUNT_TOKEN_CREATOR_ROLE}"
)

# APIs

enabled_services = `gcloud services list --enabled`.strip

APIS_TO_ENABLE.each do |api|
  verify_resource(
    "API #{api}",
    "echo '#{enabled_services}' | grep '#{api}'",
    success_message = "is enabled",
    error_message = "is not enabled"
  )
end

# Terraform state bucket

verify_resource(
  "Terraform state bucket",
  "gsutil ls | grep #{TERRAFORM_STATE_BUCKET}"
)

# Cloud Build service account role binding to GKE

verify_resource(
  "Cloud Build service account role binding to GKE",
  "gcloud projects get-iam-policy #{PROJECT_ID} \
    --filter='bindings.members:#{project_number}@cloudbuild.gserviceaccount.com' \
    --flatten='bindings[].members' --format='value(bindings.role)' 2> /dev/null \
    | grep #{CONTAINER_ADMIN_ROLE}"
)

# Cloud Source repo

verify_resource(
  "Cloud Source repo #{PROJECT_NAME}",
  "gcloud source repos list | grep #{PROJECT_NAME}"
)

verify_resource(
  "Cloud Source repo #{PROJECT_NAME}",
  "gcloud source repos describe #{PROJECT_NAME} 2> /dev/null | grep mirrorConfig",
  success_message = "is being mirrored to a remote repo",
  error_message = "is not being mirrored to a remote repo"
)

# Cloud Build triggers

$all_exist = false

begin
  access_token = get_access_token()
  existing_triggers = get_existing_triggers(access_token)

  $all_exist = BUILD_TRIGGERS.reduce(true) do |acc, trigger| 
    acc && trigger_exists?(existing_triggers, trigger)
  end

  if $all_exist
    puts "✔ All Cloud Build triggers exist."
  else
    puts "✗ Not all Cloud Build triggers exist."
  end
rescue Errno::ENOENT  # get_access_token() fails when the service account is not valid/doesn't exist
  puts "✗ Can't verify Cloud Build triggers because service account is not valid."
end

$exit_status = $exit_status && $all_exist

# Final wrap-up

puts ""  # Extra spacing

if $exit_status
  puts "Everything looks good!"
else
  puts "There are configuration problems. " \
    "They can probably be solved by running 'make init-infra'.\n" \
    "If the Cloud Source repo is not yet being mirrored to a remote repo, " \
    "you'll have to manually link it. " \
    "See the instructions in the Apulu Runtime README for more details."
end

puts ""  # Extra spacing
exit $exit_status
