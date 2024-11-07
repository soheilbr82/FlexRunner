#!/bin/bash

# Read the Github token from the secret file
export ACTIONS_RUNNER_TOKEN=$(cat /run/secrets/github_token)
export GITHUB_REPO="$GITHUB_REPO"

registration_url="https://api.github.com/repos/${GITHUB_REPO}/actions/runners/registration-token"
echo "Requesting registration URL: '${registration_url}'"

payload=$(curl -sX POST -H "Authorization: token ${ACTIONS_RUNNER_TOKEN}" ${registration_url})
export RUNNER_TOKEN=$(echo $payload | jq .token --raw-output)

if [ -z "$RUNNER_TOKEN" ]; then
  echo "Failed to get the runner token"
  exit 1
fi

# Generate a unique runner name using the hostname and a random UUID
RUNNER_NAME=$(SERVER_NAME)-$(uuidgen)
export RUNNER_LABEL="flexrunner"
export ARTIFACT_DIR="${ARTIFACT_DIR}"
export DATA_DIR="${DATA_DIR}"
export WORK_PATH="${WORK_PATH}"
WORK_DIR="$WORK_PATH

./config.sh \
    --url https://github.com/${GITHUB_REPO} \
    --name ${RUNNER_NAME}
    --token ${RUNNER_TOKEN} \
    --labels ${RUNNER_LABEL} \
    --work ${WORK_DIR} \
    --unattended \
    --replace


remove() {
  ./config.sh remove --unattended --token "${RUNNER_TOKEN}"
}


trap 'remove; exit 130' INT
trap 'remove; exit 143' TERM
trap 'remove; exit 0' EXIT
trap 'remove; exit 138' USR1

./run.sh "$*" &

wait $!


#  The entrypoint.sh script is the main script that will be executed when the container starts. It reads the Github token from the secret file, requests a registration URL from the Github API, and then registers the runner with the Github repository. 
#  The script also sets up a trap to remove the runner when the container is stopped. 
#  The  remove  function is called when the container is stopped. It removes the runner from the Github repository. 
#  The  trap  command is used to catch signals like  INT ,  TERM ,  EXIT , and  USR1  and call the  remove  function to remove the runner. 
#  The  run.sh  script is executed in the background. It starts the runner and waits for it to finish. 
#  The  run.sh  script is a simple script that starts the runner.