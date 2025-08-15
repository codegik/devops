#!/bin/sh

set -e

if ! docker info > /dev/null 2>&1; then
  echo ">>> Error: Docker is not running. Please start Docker and try again."
  exit 1
fi

echo ">>> Docker is running, creating infrastructure with OpenTofu..."
export OPENTOFU_ENFORCE_GPG_VALIDATION=false

echo ""
echo ""
echo ">>> Creating infrastructure (including Kind cluster)..."
cd iac/src
tofu init
tofu apply -auto-approve
cd -

echo ""
echo ">>> Waiting for infrastructure to stabilize..."
sleep 10

echo ">>> Testing infrastructure..."
./test.sh
