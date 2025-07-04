#!/bin/bash

# Script to deploy a new version of hello-buddy
# Usage: ./deploy.sh <build_number>

# Check if build number is provided
if [ -z "$1" ]; then
  echo "Error: Build number is required"
  echo "Usage: ./deploy.sh <build_number>"
  exit 1
fi

BUILD_NUMBER=$1
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Deploying hello-buddy version: $BUILD_NUMBER"

# Update the values.yaml file with the new build number and repository
echo "Updating Helm values..."
sed -i '' "s|tag: .*|tag: $BUILD_NUMBER|g" $SCRIPT_DIR/helm/values.yaml
sed -i '' 's|repository: .*|repository: localhost:30500/hello-buddy|g' $SCRIPT_DIR/helm/values.yaml

# Deploy the application using Helm
echo "Deploying with Helm..."
helm upgrade --install hello-buddy $SCRIPT_DIR/helm --namespace app

# Check if the deployment succeeded
echo "Checking deployment status..."
kubectl rollout status deployment/hello-buddy -n app
