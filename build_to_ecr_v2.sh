#!/bin/bash
if [ -z "$1" ]; then
  echo -e "\nUsage: \n$0 <ECR_NAME>\n" >&2
  exit 3
else
  set -ex
  AWS_ACCOUNT_ID=$(aws --profile mfa sts get-caller-identity --query Account --output text)
  AWS_DEFAULT_REGION=sa-east-1
  ECR_NAME=$1
  # Nodejs App Version
  VERSION=$(cat src/package.json | jq -r .version)
  # Docker Login
  aws --profile mfa ecr get-login-password --region $AWS_DEFAULT_REGION | \
    docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com
  # Registry Main Tag
  REPOSITORY_URI=$AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$ECR_NAME
  IMAGE_TAG=$VERSION
  # Build and Push
  docker buildx build --progress=plain --platform=linux/arm64/v8,linux/amd64 --pull \
    --push -t $REPOSITORY_URI:$IMAGE_TAG .
  # Inspect
  docker buildx imagetools inspect $REPOSITORY_URI:$IMAGE_TAG
  # Skopeo Login
  aws --profile mfa ecr get-login-password --region $AWS_DEFAULT_REGION | \
    skopeo login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com
  # Other Tags
  skopeo copy --all docker://$REPOSITORY_URI:$IMAGE_TAG docker://$REPOSITORY_URI:latest
  skopeo copy --all docker://$REPOSITORY_URI:$IMAGE_TAG docker://$REPOSITORY_URI:develop
  # Multi Arch Tags
  skopeo copy --override-arch=amd64 docker://$REPOSITORY_URI:$IMAGE_TAG docker://$REPOSITORY_URI:$VERSION-amd64
  skopeo copy --override-arch=arm64 docker://$REPOSITORY_URI:$IMAGE_TAG docker://$REPOSITORY_URI:$VERSION-arm64
fi
