require "yaml"
require_relative "services-config"

include ServicesConfig

PRODUCTION_VALUES_FILE = "#{VALUES_FOLDER}/values_production.yaml"
DEVELOPMENT_VALUES_FILE = "#{VALUES_FOLDER}/values_development.yaml"

model_storage_disk_name = `terraform output model_storage_disk_name`.strip

backend_ip = `terraform output backend_ip`.strip
backend_development_ip = `terraform output backend_development_ip`.strip

# Since Redis is an optional resource, suppress STDERR in case it doesn't exist
redis_ip = `terraform output redis_ip 2>/dev/null`.strip
redis_port = `terraform output redis_port 2>/dev/null`.strip


################################################################################
# GLOBAL VALUES
################################################################################

values = YAML.load_file(BASE_VALUES_FILE)

values["modelStoragePersistentDisk"] = model_storage_disk_name
values["redisHost"] = redis_ip
values["redisPort"] = redis_port

File.open(BASE_VALUES_FILE, "w") {|f| YAML.dump(values, f)}


################################################################################
# PRODUCTION VALUES
################################################################################

values = YAML.load_file(PRODUCTION_VALUES_FILE)

values["services"]["backend"]["host"] = backend_ip

File.open(PRODUCTION_VALUES_FILE, "w") {|f| YAML.dump(values, f)}


################################################################################
# DEVELOPMENT VALUES
################################################################################

values = YAML.load_file(DEVELOPMENT_VALUES_FILE)

values["services"]["backend"]["host"] = backend_development_ip

File.open(DEVELOPMENT_VALUES_FILE, "w") {|f| YAML.dump(values, f)}
