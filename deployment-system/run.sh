#!/bin/sh

if ! docker info > /dev/null 2>&1; then
  echo ">>> Error: Docker is not running. Please start Docker and try again."
  exit 1
fi

echo ">>> Docker is running, creating Kind cluster..."
kind create cluster --config kind-config.yaml

echo ""
echo ""
echo ">>> Creating infrastructure..."
cd iac/src
rm -rf .terraform .terraform.lock.hcl terraform.*
tofu init
tofu apply -auto-approve
cd -

echo ""
echo ">>> Waiting for infrastructure to stabilize..."
sleep 10

echo ">>> Testing infrastructure..."
./test.sh
