.PHONY: clean model prediction deployment sync-data-to-gcs sync-data-from-gcs start init-infra init-terraform get-service-account-key authenticate-cluster build-push-images generate-manifests deploy-infra deploy-manifests deploy-services uninit-infra destroy-infra destroy-cluster

#################################################################################
# GLOBALS
#################################################################################

GCS_BUCKET = runtime-ds-test-data
GCP_PROJECT = eds-sandbox-186722

TAG := "latest"
NAMESPACE := "development"
SERVICE := "all"

#################################################################################
# COMMANDS
#################################################################################

## Delete all compiled Python files
clean:
	find . -type f -name "*.py[co]" -delete
	find . -type d -name "__pycache__" -delete
	find ./notebooks -name '*.ipynb' -exec pipenv run nbstripout {} \;

## Trains and saves the model
model:
	echo "This needs to be implemented"

## Upload data to GCS
sync-data-to-gcs:
ifeq (default,$(GCP_PROJECT))
	gsutil rsync -r data/ gs://$(GCS_BUCKET)/data
else
	gcloud config set project $(GCP_PROJECT)
	gsutil rsync -r data/ gs://$(GCS_BUCKET)/data
	echo "\nWARNING: Please note that your default GCP project has changed to $(GCP_PROJECT)"
endif

## Download data from GCS
sync-data-from-gcs:
ifeq (default,$(GCP_PROJECT))
	gsutil rsync -r gs://$(GCS_BUCKET)/data data/
else
	gcloud config set project $(GCP_PROJECT)
	gsutil rsync -r gs://$(GCS_BUCKET)/data data/
	echo "\nWARNING: Please note that your default GCP project has changed to $(GCP_PROJECT)"
endif

## Start all of the services locally
start:
	docker-compose --file services/docker-compose.yaml up --build

## One-time initialization of infrastructure related configuration (service account, Terraform state, etc); requires Owner role
init-infra:
	ruby ./scripts/init-infra.rb

## Initialize the Terraform state; only needed if you weren't the one to run 'init-infra'
init-terraform:
	terraform init terraform

## Verify that all of the components of the infrastructure initialization are present
verify-init-infra:
	ruby ./scripts/verify-init-infra.rb

## Get a copy of the project's service account json key; only needed if you weren't the one to run 'init-infra
get-service-account-key:
	ruby ./scripts/get-service-account-key.rb

## Get credentials for kubectl to access the cluster
authenticate-cluster:
	ruby ./scripts/authenticate-cluster.rb

## Build and push the Docker images for either all services (default) or a single service
build-push-images:
	ruby ./scripts/build-push-images.rb $(TAG) $(SERVICE)

## Generate the Kubernetes manifests from the Helm templates
generate-manifests:
	ruby ./scripts/generate-manifests.rb $(TAG) $(NAMESPACE)

## Deploy the Cloud Build triggers to enable CI/CD
deploy-build-triggers:
	ruby ./scripts/deploy-cloud-build-triggers.rb

## Deploy the Terraform infrastructure to GCP
deploy-infra:
	ruby ./scripts/deploy-infra.rb

## Deploy the Kubernetes services' manifests to the cluster
deploy-manifests:
	bash ./scripts/deploy-manifests.sh

## Does an end-to-end services deployment by combining together the steps of image building, manifest generation, and manifest deployment
deploy-services: build-push-images generate-manifests deploy-manifests

## Un-initialize the infrastructure related configuration (delete service account, Terraform state, etc); requires Owner role
uninit-infra:
	ruby ./scripts/uninit-infra.rb

## Destroy all of the infrastructure that was deployed to GCP
destroy-infra:
	terraform destroy terraform

## Destroy just the Kubernetes cluster
destroy-cluster:
	terraform destroy -target google_container_cluster.primary terraform

## Update from cookiecutter template; will have to resolve git conflicts (if any) manually
update-from-cookiecutter:
	cookiecutter git@github.com:pythian/apulu-runtime.git --output-dir .. --config-file .cookiecutter.yaml --no-input --overwrite-if-exists

## Proxy all unknown commands to be run on all of the services (can do things like run 'ci' on all services)
%:
	ruby ./scripts/run-services-command.rb $@

#################################################################################
# SELF DOCUMENTING COMMANDS
#################################################################################

.DEFAULT_GOAL := show-help

# Inspired by <http://marmelab.com/blog/2016/02/29/auto-documented-makefile.html>
# sed script explained:
# /^##/:
#	* save line in hold space
#	* purge line
#	* Loop:
#		* append newline + line to hold space
#		* go to next line
#		* if line starts with doc comment, strip comment character off and loop
#	* remove target prerequisites
#	* append hold space (+ newline) to line
#	* replace newline plus comments by `---`
#	* print line
# Separate expressions are necessary because labels cannot be delimited by
# semicolon; see <http://stackoverflow.com/a/11799865/1968>
.PHONY: show-help
show-help:
	@echo "$$(tput bold)Available rules:$$(tput sgr0)"
	@echo
	@sed -n -e "/^## / { \
		h; \
		s/.*//; \
		:doc" \
		-e "H; \
		n; \
		s/^## //; \
		t doc" \
		-e "s/:.*//; \
		G; \
		s/\\n## /---/; \
		s/\\n/ /g; \
		p; \
	}" ${MAKEFILE_LIST} \
	| LC_ALL='C' sort --ignore-case \
	| awk -F '---' \
		-v ncol=$$(tput cols) \
		-v indent=19 \
		-v col_on="$$(tput setaf 6)" \
		-v col_off="$$(tput sgr0)" \
	'{ \
		printf "%s%*s%s ", col_on, -indent, $$1, col_off; \
		n = split($$2, words, " "); \
		line_length = ncol - indent; \
		for (i = 1; i <= n; i++) { \
			line_length -= length(words[i]) + 1; \
			if (line_length <= 0) { \
				line_length = ncol - indent - length(words[i]) - 1; \
				printf "\n%*s ", -indent, " "; \
			} \
			printf "%s ", words[i]; \
		} \
		printf "\n"; \
	}' \
	| more $(shell test $(shell uname) = Darwin && echo '--no-init --raw-control-chars')
