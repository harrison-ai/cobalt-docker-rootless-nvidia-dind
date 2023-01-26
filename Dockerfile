FROM debian:bullseye-slim

ARG DEBIAN_FRONTEND=noninteractive
ARG DOCKER_VERSION=20.10.18

WORKDIR /app

# Dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       dumb-init rootlesskit slirp4netns \
       iptables iproute2 ca-certificates \
       containerd runc curl gnupg python3-pip \
       pigz \
    && rm -rf \
       /usr/bin/rootlessctl \
       /usr/bin/containerd-shim-runc-v1 \
       /usr/bin/containerd-shim \
       /usr/bin/ctr

# Docker daemon
RUN curl "https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER_VERSION}.tgz" -o /docker.tgz \
    && tar -xz -f /docker.tgz --strip-components=1 -C /usr/local/bin docker/dockerd docker/docker-proxy \
    && rm -f /docker.tgz

# NVIDIA container toolkit
RUN distribution=$(. /etc/os-release;echo $ID$VERSION_ID) \
    && curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | apt-key add - \
    && curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | tee /etc/apt/sources.list.d/nvidia-docker.list \
    && apt-get update && apt-get install -y nvidia-container-toolkit nvidia-container-runtime
ADD ./config.toml /etc/nvidia-container-runtime/config.toml 
ADD ./daemon.json /etc/docker/daemon.json

# Package clean
RUN apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Project files
COPY entrypoint.sh .
COPY allocator.py .

# Install requirements for the allocator app
RUN pip3 install kubernetes

# Prepare rootless user
RUN set -ex \
    && mkdir /run/user \
    && chmod 1777 /run/user \
    && adduser --home /home/rootless --gecos 'Rootless' --disabled-password --uid 1000 rootless \
    && mkdir -p /home/rootless/.local/share/docker \
    && chown -R rootless:rootless /home/rootless
VOLUME /home/rootless/.local/share/docker

EXPOSE 2375
ENTRYPOINT ["/app/entrypoint.sh"]
CMD []
