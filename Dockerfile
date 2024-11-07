# ----------------------Stage 1: base image----------------------

ARG BASE_REGISTRY=public.ecr.aws/ubuntu
ARG BASE_IMAGE=ubuntu
ARG BASE_TAG=22.04

FROM ${BASE_REGISTRY}/${BASE_IMAGE}:${BASE_TAG} AS base

# Define environment variables
ARG WORK_PATH "" \
    GITHUB_REPO "" \
    RUNNER_VERSION "" \
    RUNNER_USER "" \
    RUNNER_USER_ID "" \
    RUNNER_GROUP "" \
    RUNNER_GROUP_ID "" \
    ARTIFACTS_DIR "" \
    DATA_DIR ""

ENV WORK_PATH=${WORK_PATH} \
    GITHUB_REPO=${GITHUB_REPO} \
    RUNNER_VERSION=${RUNNER_VERSION} \
    RUNNER_USER=${RUNNER_USER} \
    RUNNER_USER_ID$={RUNNER_USER_ID} \
    RUNNER_GROUP=${RUNNER_GROUP} \
    RUNNER_GROUP_ID=${RUNNER_GROUP_ID} \
    ARTIFACTS_DIR=${ARTIFACTS_DIR} \
    DATA_DIR=${DATA_DIR} 

# Set up env variables for proxy settings
RUN if [ -z "${http_proxy}" ]; then export http_proxy=${http_proxy}; fi \
    && if [ -z "${https_proxy}" ]; then export https_proxy=${https_proxy}; fi \
    && if [ -z "${no_proxy}" ]; then export no_proxy=${no_proxy}; fi

# Install required packages
RUN apt-get update && \
    apt-get upgrade && \
    apt-get install --no-install-recommends -y \
    build-essential \
    unzip \
    zip \
    tar \
    jq \
    cmake \
    make \
    gcc \
    g++ \
    clang \
    rsync \
    wget \
    git \
    shellcheck \
    subversion \
    apt-transport-https \
    gnupg \
    gnupg2 \
    ninja-build \
    lsb-release \
    ca-certificates \
    curl \
    python3-pip \
    python3-setuptools \
    python3.10 \
    python3.10-dev \
    iputils-ping \
    sudo \
    && apt-get clean && rm -rf /var/lib/apt/lists/* \
    && apt-get autoremove -y

# ----------------------Stage 2: builder stage----------------------
FROM base AS builder

RUN mkdir -p ${ARTIFACTS_DIR} \
    && mkdir -p ${DATA_DIR}

RUN groupadd -g ${RUNNER_GROUP_ID} ${RUNNER_GROUP} \
    && useradd -m -u ${RUNNER_USER_ID} -g ${RUNNER_GROUP_ID} ${RUNNER_USER}
    # && usermod -aG sudo ${RUNNER_USER}
    # && echo "%sudo ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

RUN chown -R ${RUNNER_USER}:${RUNNER_GROUP} ${ARTIFACTS_DIR} \
    && chown -R ${RUNNER_USER}:${RUNNER_GROUP} ${DATA_DIR}

# ----------------------Stage 3: action runner stage----------------------
FROM builder AS runner

# ARG RUNNER_VERSION=2.283.3

ENV VERSION_CODENAME $(grep VERSION_CODENAME /etc/os-release | cut -d '=' -f 2)

# Add docker official GPG key
RUN apt-get update && \
    apt-get install -y ca-certificates curl gnupg && \
    install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg && \
    chmod a+r /etc/apt/keyrings/docker.gpg

# Add the repo to the sources list
RUN echo "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
    tee /etc/apt/sources.list.d/docker.list > /dev/null

RUN apt-get update && \
    apt-get install -y docker-ce-cli jq docker-ce containerd.io


RUN usermod -aG docker ${RUNNER_USER}

WORKDIR /actions-runner
RUN curl -Ls https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz | tar xz \
    && ./bin/installdependencies.sh

# Copy the modified config.sh file into image
COPY --chown=${RUNNER_USER}:${RUNNER_GROUP} config.sh /actions-runner/config.sh

COPY --chown=${RUNNER_USER}:${RUNNER_GROUP} entrypoint.sh /actions-runner/entrypoint.sh

RUN chmod u+x /actions-runner/entrypoint.sh

RUN chown -R ${RUNNER_USER}:${RUNNER_GROUP} /actions-runner && \
    chmod -R $(RUNNER_USER):$(RUNNER_GROUP) ${WORK_PATH} && \
    chmod -R $(RUNNER_USER):$(RUNNER_GROUP) /home/${RUNNER_USER}

USER ${RUNNER_USER} 

ENTRYPOINT [ "/action-runner/entrypoint.sh" ]