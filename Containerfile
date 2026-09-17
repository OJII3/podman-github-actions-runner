FROM docker.io/library/ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# The runner is mounted at runtime. This image only contains its OS
# dependencies and the Docker CLI used to talk to Podman's Docker API.
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      bash \
      ca-certificates \
      curl \
      git \
      git-lfs \
      jq \
      unzip \
      zip \
      libicu74 \
      libkrb5-3 \
      liblttng-ust1t64 \
      libssl3t64 \
      zlib1g \
 && git lfs install --system \
 && rm -rf /var/lib/apt/lists/*

# Install the Docker CLI without Docker Engine. GameCI invokes `docker run`,
# while DOCKER_HOST points that CLI at the Podman socket.
RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl gnupg \
 && install -m 0755 -d /etc/apt/keyrings \
 && curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
      -o /etc/apt/keyrings/docker.asc \
 && chmod a+r /etc/apt/keyrings/docker.asc \
 && printf '%s\n' \
      'Types: deb' \
      'URIs: https://download.docker.com/linux/ubuntu' \
      'Suites: noble' \
      'Components: stable' \
      "Architectures: $(dpkg --print-architecture)" \
      'Signed-By: /etc/apt/keyrings/docker.asc' \
      > /etc/apt/sources.list.d/docker.sources \
 && apt-get update \
 && apt-get install -y --no-install-recommends docker-ce-cli \
 && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /runner-home \
 && chmod 0777 /runner-home

ENV HOME=/runner-home
ENV RUNNER_ROOT=/srv/gha-runner

COPY entrypoint.sh /usr/local/bin/gha-runner-entrypoint
RUN chmod 0755 /usr/local/bin/gha-runner-entrypoint

WORKDIR /srv/gha-runner
ENTRYPOINT ["/usr/local/bin/gha-runner-entrypoint"]
