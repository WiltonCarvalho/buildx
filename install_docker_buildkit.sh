#!/bin/bash
set -ex
sudo mkdir -p /usr/local/lib/docker/cli-plugins

COMPOSE_RELEASES="https://github.com/docker/compose/releases"
COMPOSE_VERSION=$(curl -fsL $COMPOSE_RELEASES/latest | grep -m 1 -Eo 'v[0-9]+\.[0-9]+\.[0-9]*')
COMPOSE_ARCH=$(uname -p)
sudo curl -fSL# $COMPOSE_RELEASES/download/$COMPOSE_VERSION/docker-compose-linux-$COMPOSE_ARCH \
  -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo ln -sf /usr/local/bin/docker-compose /usr/local/lib/docker/cli-plugins/docker-compose
docker-compose version

BUILDX_RELEASES="https://github.com/docker/buildx/releases"
BUILDX_VERSION=$(curl -fsL $BUILDX_RELEASES/latest | grep -m 1 -Eo 'v[0-9]+\.[0-9]+\.[0-9]*')
if [ $(uname -p) == "aarch64" ]; then BUILDX_ARCH=arm64; else BUILDX_ARCH=amd64; fi
sudo curl -fSL# $BUILDX_RELEASES/download/$BUILDX_VERSION/buildx-$BUILDX_VERSION.linux-$BUILDX_ARCH \
  -o /usr/local/lib/docker/cli-plugins/docker-buildx
sudo chmod +x /usr/local/lib/docker/cli-plugins/docker-buildx

docker info | grep -A3 Plugins
docker buildx create --name image-builder --use \
  --driver docker-container \
  --driver-opt network=host
