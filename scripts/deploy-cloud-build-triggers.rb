require "json"
require "net/http"
require "uri"
require_relative "triggers-config"

include TriggersConfig

###############################################################################
# HELPER FUNCTIONS
###############################################################################

def create_trigger(trigger, access_token)
  request, http = create_trigger_request(:Post, access_token)
  request["Content-Type"] = "application/json"
  request.body = trigger.to_json

  http.request(request)
end

###############################################################################
# MAIN
###############################################################################

# Get access token

access_token = get_access_token()

# Create build triggers

existing_triggers = get_existing_triggers(access_token)

BUILD_TRIGGERS.each do |trigger|
  if trigger_exists?(existing_triggers, trigger)
    puts "[INFO] Trigger #{trigger[:description]} already exists."
  else
    create_trigger(trigger, access_token)
  end
end

puts "\n[INFO] Finished deploying build triggers!"
