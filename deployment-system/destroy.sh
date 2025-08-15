#!/bin/sh

echo ">>> Destroying infrastructure..."
export OPENTOFU_ENFORCE_GPG_VALIDATION=false

cd iac/src
tofu destroy -auto-approve
rm -rf .terraform .terraform.lock.hcl terraform.*
cd -

echo ">>> Infrastructure destroyed successfully!"
