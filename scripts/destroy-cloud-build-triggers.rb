require "json"
require "net/http"
require "uri"
require_relative "triggers-config"

include TriggersConfig

###############################################################################
# HELPER FUNCTIONS
###############################################################################

def delete_trigger(id, access_token)
  request, http = create_trigger_request(:Delete, access_token, trigger_id = id)
  http.request(request)
end

###############################################################################
# MAIN
###############################################################################

# Get access token

access_token = get_access_token()

# Get triggers

triggers = get_project_triggers(access_token)

# Delete triggers

if !triggers.empty?
  trigger_ids = triggers.map {|trigger| trigger["id"]}

  trigger_ids.each do |id|
    delete_trigger(id, access_token)
  end

  puts "\n[INFO] Finished deleting build triggers!"
else
  puts "\n[INFO] No triggers to delete. Exiting."
end
