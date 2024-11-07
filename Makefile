## ------------------------------------------------------------------
## The purpose of this file is to compile the source code.
## ------------------------------------------------------------------

SHELL := /bin/sh
ifneq ("$(wildcard .env)","")
	include .env
	export $(shell sed 's/=.*//' .env)
endif

CONTAINER_NAME = $(SERVICE_NAME)_$(RUNNER_USER)
PROJECT=$(PROJECT_NAME)-$(SERVICE_NAME)-$(RUNNER_USER)
SERVICE=$(PROJECT_NAME)-$(SERVICE_NAME)-$(SERVER_NAME)
SECRET_NAME=github_token
ACTIONS_RUNNER_TOKEN := $(ACTIONS_RUNNER_TOKEN)

help: ## Show this help.
	@egrep -h '##\s' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?##"}; {printf "\033[36m %-30s\033[0m %s\n", $$1, $$2}'


envs: ## List environment variables
	@echo project: $(PROJECT)
	@echo container: $(CONTAINER_NAME)

init: ## Initialize the project
	set_data_permissions copy_data_fils create_data_volume set_model_permissions copy_model_files create_model_volume
	@$(SHELL) -c "./generate_env.sh"

create_model_volume: ## Create docker volume for model
	@echo "Creating docker volume for model ..."
	@docker volume create $(PROJECT)_model

copy_model_files: ## Copy models to docker volume
	@echo "Copying files from host to docker volume ..."
	@docker run --rm -v $(PROJECT)_model:/model -v $(ARTIFACTS_DIR):/host-model busybox sh -c "cp -r /host-model/. /model/"


create_data_volume: ## Create docker volume for data
	@echo "Creating docker volume for data ..."
	@docker volume create $(PROJECT)_data


copy_data_files: ## Copy data to docker volume
	@echo "Copying data files from host to docker volume ..."
	@docker run --rm -v $(PROJECT)_data:/data -v $(DATA_DIR):/host-data busybox sh -c "cp -r /host-data/. /data/"

set_model_permissions: ## Set permissions for data
	@echo "Setting permissions for data ..."
	@docker run --rm -v $(PROJECT)_model:/model busybox sh -c "chown -R $(RUNNER_USER_ID):$(RUNNER_GROUP_ID) /model && chmod -R 2770 /model"

set_data_permissions: ## Set permissions for data
	@echo "Setting permissions for data ..."
	@docker run --rm -v $(PROJECT)_data:/data busybox sh -c "chown -R $(RUNNER_USER_ID):$(RUNNER_GROUP_ID) /data && chmod -R 2770 /data"

create_secret: ## Create secret
	@if docker secret ls | grep -q $(SECRET_NAME); then \
		echo "Secret $(SECRET_NAME) already exists. Skipping creation"; \
	else \
		echo "Creating secret $(SECRET_NAME) ..."; \
		echo -n $(ACTIONS_RUNNER_TOKEN) | docker secret create $(SECRET_NAME) -; \
	fi

build: ## Build the docker image
	@echo "Building docker image $(CONTAINER_NAME) ..."
	@$(SHELL) -c "docker compose -p $(PROJECT) -f docker-compose.yml build"


start: stop create_secret ## Start the docker container
	@$(SHELL) -c "\
	if [ -z '$(ARTIFACTS_DIR)'] then echo 'ARTIFACTS_DIR is not set'; exit 1; fi; \
	if [ -z '$(DATA_DIR)'] then echo 'DATA_DIR is not set'; exit 1; fi; \
	if [ -z '$(GITHUB_REPO)'] then echo 'GITHUB_REPO is not set'; exit 1; fi; \
	docker service create --name $(SERVICE) \
	--replicas 1 \
	--hostname $(SERVICE)-{{.Task.Slot}} \
	--mount type=volume,source=$(PROJECT)_model,target=$(ARTIFACTS_DIR),readonly \
	--mount type=volume,source=$(PROJECT)_data,target=$(DATA_DIR),readonly \
	--secret $(SECRET_NAME) \
	$(PROJECT).app /entrypoint.sh"

scale: ## Scale the docker container
	@read -p "Enter the number of replicas: " replicas; \
	@docker service scale $(SERVICE)=$$replicas

stop: ## Stop the docker container
	@if docker service ls | grep -q $(SERVICE); then \
		echo "Scaling down service $(SERVICE) ..."; \
		docker service scale $(SERVICE)=0; \
		docker service rm $(SERVICE); \
	fi
	@if docker secret ls | grep -q $(SECRET_NAME); then \
		echo "Removing secret $(SECRET_NAME) ..."; \
		docker secret rm $(SECRET_NAME); \
	fi

remove: ## Remove services and their associated containers
	@echo "Cleaning up containers for service $(SERVICE) ..."
	@CONTAINER_IDS=$$(docker ps -a --filter "status=exited" --format="{{.ID}}"); \
	if [ -n "$$CONTAINER_IDS" ]; then \
		docker rm -f $$CONTAINER_IDS; \
	else \
		echo "No containers to remove for service $(SERVICE)"; \
	fi
	@if docker volume ls -q | grep -w $(PROJECT)_model > /dev/null; then \
		echo "Removing volumes for service $(SERVICE) ..."; \
		docker volume rm -f $(PROJECT)_model; \
	else \
		echo "No volumes to remove for service $(SERVICE)"; \
	fi
	@if docker volume ls -q | grep -w $(PROJECT)_data > /dev/null; then \
		echo "Removing volumes for service $(SERVICE) ..."; \
		docker volume rm -f $(PROJECT)_data; \
	else \
		echo "No volumes to remove for service $(SERVICE)"; \
	fi

list: ## List all containers
	@docker ps -a

clean: ## Purge the dangling images to save space
	@echo "Cleaning up dangling images ..."
	@images=$$(docker images -f "dangling=true" -q); \
	if [ -n "$$images" ]; then \
		docker rmi -f $$images; \
	else \
		echo "No dangling images to remove"; \
	fi

.PHONY: help envs init build start stop remove list clean create_secret create_model_volume copy_model_files create_data_volume copy_data_files set_model_permissions set_data_permissions scale