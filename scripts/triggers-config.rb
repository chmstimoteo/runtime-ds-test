# For reference on how authentication to Google/GCP APIs works,
# visit https://developers.google.com/identity/protocols/OAuth2ServiceAccount#authorizingrequests

require "json"
require "net/http"
require "uri"
require_relative "services-config"
include ServicesConfig

module TriggersConfig
  ###############################################################################
  # CONSTANTS
  ###############################################################################

  CLAIM_SET_FILE = "claim_set.json"
  SIGNED_JWT_FILE = "output.jwt"

  BUILD_TRIGGERS = [
    {
      "triggerTemplate": {
        "projectId": "#{PROJECT_ID}",
        "repoName": "#{PROJECT_NAME}",
        "branchName": "[^master|develop]"
      },
      "description": "#{PROJECT_TITLE} (non-deployable)",
      "filename": "cloudbuild.yaml"
    },
    {
      "triggerTemplate": {
        "projectId": "#{PROJECT_ID}",
        "repoName": "#{PROJECT_NAME}",
        "branchName": "develop"
      },
      "description": "#{PROJECT_TITLE} (development)",
      "substitutions": {
        "_NAMESPACE": "development"
      },
      "filename": "cloudbuild.deployable.yaml"
    },
    {
      "triggerTemplate": {
        "projectId": "#{PROJECT_ID}",
        "repoName": "#{PROJECT_NAME}",
        "branchName": "master"
      },
      "description": "#{PROJECT_TITLE} (production)",
      "substitutions": {
        "_NAMESPACE": "production"
      },
      "filename": "cloudbuild.deployable.yaml"
    }
  ]

  ###############################################################################
  # HELPER FUNCTIONS
  ###############################################################################

  def create_trigger_request(method, access_token, trigger_id = "")
    trigger_uri = URI.parse("https://cloudbuild.googleapis.com/v1/projects/#{PROJECT_ID}/triggers/#{trigger_id}")
    http = Net::HTTP.new(trigger_uri.host, trigger_uri.port)
    http.use_ssl = true

    request = Net::HTTP.const_get(method).new(trigger_uri.request_uri)
    request["Authorization"] = "Bearer #{access_token}"

    return request, http
  end

  def create_claim_set_file(claim_set_file)
    claim_set = {
      "iss": "#{FULLY_QUALIFIED_SERVICE_ACCOUNT}",
      "scope": "https://www.googleapis.com/auth/cloud-platform",
      "aud": "https://www.googleapis.com/oauth2/v4/token",
      "exp": Time.now.to_i + 600,  # Set expiry to 10 minutes past current time, in epoch
      "iat": Time.now.to_i
    }

    File.open(claim_set_file, "w") do |f|
      f.write(claim_set.to_json)
    end
  end

  def get_signed_jwt(claim_set_file)
    system("gcloud beta iam service-accounts sign-jwt --iam-account #{FULLY_QUALIFIED_SERVICE_ACCOUNT} #{claim_set_file} #{SIGNED_JWT_FILE} 2> /dev/null")
    return File.read(SIGNED_JWT_FILE)
  end

  def get_access_token()
    create_claim_set_file(CLAIM_SET_FILE)
    signed_jwt = get_signed_jwt(CLAIM_SET_FILE)

    access_token_uri = URI.parse("https://www.googleapis.com/oauth2/v4/token")
    form_data = {"grant_type": "urn:ietf:params:oauth:grant-type:jwt-bearer", "assertion": signed_jwt}

    response = Net::HTTP.post_form(access_token_uri, form_data)
    access_token = JSON.parse(response.body)["access_token"]

    # Clean up the generated files
    File.delete(CLAIM_SET_FILE)
    File.delete(SIGNED_JWT_FILE)

    return access_token
  end

  def get_existing_triggers(access_token)
    request, http = create_trigger_request(:Get, access_token)
    response = http.request(request)

    data = JSON.parse(response.body)

    if data
      return data["triggers"]
    else
      return []
    end
  end

  def get_project_triggers(access_token)
    all_triggers = get_existing_triggers(access_token)
    return all_triggers.select {|trigger| trigger["triggerTemplate"]["repoName"] == PROJECT_NAME}
  end

  def trigger_exists?(existing_triggers, trigger)
    if existing_triggers
      return existing_triggers.any? {|existing_trigger| existing_trigger["description"] == trigger[:description]}
    else
      return false
    end
  end
end
