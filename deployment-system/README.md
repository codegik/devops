
## Requirements
- OpenTofu
- Kind

## Startup the cluster
```bash
kind create cluster --config kind-config.yaml
```

## Build the Infra
```bash
export OPENTOFU_ENFORCE_GPG_VALIDATION=false
cd iac/src
tofu init
tofu apply
```

## Build the App
```bash
cd app/hello-buddy
npm install
docker build -t hello-buddy:latest .
```