#!/bin/bash
if [ -z "$1" ]; then
  echo -e "\nUsage: \n$0 <ECR_NAME>\n" >&2
  exit 3
else
  set -ex
  AWS_ACCOUNT_ID=$(aws --profile mfa sts get-caller-identity --query Account --output text)
  nc -zv -w 2 10.10.56.92 22
  EC2_ARM64_HOST="ssh://ubuntu@10.10.56.92"
  ECR_NAME=$1
  VERSION=$(cat src/package.json | jq -r .version)
  AWS_DEFAULT_REGION=sa-east-1
  aws --profile mfa ecr get-login-password --region $AWS_DEFAULT_REGION | \
    docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com
  REPOSITORY_URI=$AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$ECR_NAME
  IMAGE_TAG=$VERSION
  export DOCKER_BUILDKIT=1
  docker build --pull --platform amd64 --no-cache -t $REPOSITORY_URI:amd64-$IMAGE_TAG -f Dockerfile . --progress=plain
  docker push $REPOSITORY_URI:amd64-$IMAGE_TAG
  export DOCKER_HOST=$EC2_ARM64_HOST
  docker build --pull --platform linux/arm64/v8 --no-cache -t $REPOSITORY_URI:arm64-$IMAGE_TAG -f Dockerfile . --progress=plain
  docker push $REPOSITORY_URI:arm64-$IMAGE_TAG
  unset DOCKER_HOST
  rm -rf $HOME/.docker/manifests/*
  docker manifest create $REPOSITORY_URI:$IMAGE_TAG $REPOSITORY_URI:amd64-$IMAGE_TAG $REPOSITORY_URI:arm64-$IMAGE_TAG
  docker manifest create $REPOSITORY_URI:latest $REPOSITORY_URI:amd64-$IMAGE_TAG $REPOSITORY_URI:arm64-$IMAGE_TAG
  docker manifest push $REPOSITORY_URI:$IMAGE_TAG
  docker manifest push $REPOSITORY_URI:latest
  docker manifest inspect $REPOSITORY_URI:$IMAGE_TAG | grep arch
fi
