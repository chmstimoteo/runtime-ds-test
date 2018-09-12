# In conjunction with Make, this script allows us to run make commands across all of the defined services.

require_relative "services-config"
include ServicesConfig

###############################################################################
# MAIN
###############################################################################

command = ARGV.shift

if command.nil?
  abort "Missing command"
end
 
SERVICES_CONFIG["services"].each do |service_name, config|
  system("make -C services/#{service_name} #{command}")
end
