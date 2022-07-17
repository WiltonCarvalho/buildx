#!/bin/bash
set -ex
mkdir -p $HOME/.docker/cli-plugins
BUILDX_RELESES="https://github.com/docker/buildx/releases"
BUILDX_VERSION=$(curl -fsL $BUILDX_RELESES | grep -m 1 -Eo 'v[0-9]+\.[0-9]+\.[0-9]*')
curl -fsSL $BUILDX_RELESES/download/$BUILDX_VERSION/buildx-$BUILDX_VERSION.linux-amd64 \
  -o $HOME/.docker/cli-plugins/docker-buildx
chmod +x $HOME/.docker/cli-plugins/docker-buildx
docker buildx create --name image-builder --use \
  --driver docker-container \
  --driver-opt network=host
