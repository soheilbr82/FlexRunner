#!/bin/bash

PROJECT_NAME="flexrunner" # The name of the project
SERVICE_NAME="flexrunner"

RUNNER_VERSION=$(curl -s https://api.github.com/repos/actions/runner/releases/latest | jq -r '.tag_name' | grep -oP "[0-9.]*")
RUNNER_USER="runner"
RUNNER_GROUP="runner"
RUNNER_USER_ID=$(id -u $RUNNER_USER)
RUNNER_GROUP_ID=$(getent group "$RUNNER_GROUP" | cut -d: -f3)

# Create automated testing variables
WORK_PATH="/home/${RUNNER_USER}/_work"
ARTIFACT_DIR="${PWD}/models" # The directory where the artifacts will be stored
DATA_DIR="${PWD}/data" # The directory where the data will be stored
GITHUB_REPO="flexteam/flexrunner" # The Github repository where the runner will be registered
SERVER_NAME=$(hostname) # The name of the server



# Output to .env file
echo "PROJECT_NAME=${PROJECT_NAME}" > .env
echo "SERVICE_NAME=${SERVICE_NAME}" >> .env
echo "RUNNER_VERSION=${RUNNER_VERSION}" >> .env
echo "RUNNER_USER=${RUNNER_USER}" >> .env   
echo "RUNNER_GROUP=${RUNNER_GROUP}" >> .env
echo "RUNNER_USER_ID=${RUNNER_USER_ID}" >> .env
echo "RUNNER_GROUP_ID=${RUNNER_GROUP_ID}" >> .env
echo "WORK_PATH=${WORK_PATH}" >> .env
echo "ARTIFACT_DIR=${ARTIFACT_DIR}" >> .env
echo "DATA_DIR=${DATA_DIR}" >> .env
echo "GITHUB_REPO=${GITHUB_REPO}" >> .env
echo "SERVER_NAME=${SERVER_NAME}" >> .env


# Check if the .env file was created
if [ -f .env ]; then
    echo ".env file created successfully"
    export $(grep -v '^#' .env | xargs)
else
    echo "Failed to create .env file"
fi