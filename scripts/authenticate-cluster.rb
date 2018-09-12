require_relative "services-config"
include ServicesConfig

###############################################################################
# MAIN
###############################################################################

cluster = "#{PROJECT_NAME}-cluster"
system("gcloud container clusters get-credentials --project=#{PROJECT_ID} --zone=#{PROJECT_ZONE} #{cluster}") or abort
