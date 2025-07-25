# Deployment System POC

This repository contains a Proof of Concept (POC) for a complete deployment system using Kubernetes, Prometheus, and Grafana to monitor a Node.js application. It demonstrates an end-to-end infrastructure and application deployment with monitoring capabilities.

## Content

- **Infrastructure as Code**: Using OpenTofu (TerraForm alternative) to provision and manage infrastructure
- **Container Orchestration**: Kubernetes deployment using Kind for local development
- **Application Monitoring**: Prometheus metrics collection and Grafana dashboards
- **CI/CD Pipeline**: Jenkins pipeline configuration for automated deployments
- **NodeJS App**: application with health checks and metrics endpoints

## Architecture Overview

```
┌─────────────────┐     ┌───────────────┐     ┌────────────────┐
│                 │     │               │     │                │
│  Hello Buddy    │────▶│  Prometheus   │────▶│    Grafana     │
│  Node.js App    │     │  Metrics      │     │   Dashboards   │
│                 │     │               │     │                │
└─────────────────┘     └───────────────┘     └────────────────┘
         │                                             ▲
         │                                             │
         │                                             │
         ▼                                             │
┌─────────────────┐                          ┌────────────────┐
│                 │                          │                │
│   Kubernetes    │                          │  Automatic     │
│                 │                          │  Dashboard     │
└─────────────────┘                          │  Provisioning  │
                                             │                │
                                             └────────────────┘
```

## Requirements
- OpenTofu (or Terraform)
- Kind
- Docker
- Node.js
- npm

## Startup the cluster
```bash
kind create cluster --config kind-config.yaml
```

## Build the Infrastructure
```bash
export OPENTOFU_ENFORCE_GPG_VALIDATION=false
cd iac/src
tofu init
tofu apply
```

This will set up:
- Prometheus for metrics collection
- Grafana for metrics visualization
- Required Kubernetes resources (namespaces, services, etc.)
- There will expose the commands to get user and password for Jenkins and Grafana.
    ```
    grafana_admin_password = "kubectl get secret --namespace iac grafana -o jsonpath='{.data.admin-password}' | base64 --decode"
    jenkins_admin_password = "kubectl get secret --namespace iac jenkins -o jsonpath='{.data.jenkins-admin-password}' | base64 --decode"
    jenkins_admin_user = "kubectl get secret --namespace iac jenkins -o jsonpath='{.data.jenkins-admin-user}' | base64 --decode"
    ```

## Build and Deploy the Application

### By CI/CD
Go to Jenkins and run the pipeline.

### By command line

Run the following commands to build and deploy the application manually.

```bash
cd app/hello-buddy 
./deploy.sh <build-number>
```

## Accessing the Services

After deployment, you can access:

- Hello Buddy application: http://localhost:3000
- Jenkins CI/CD: http://localhost:30600
- Grafana dashboards: http://localhost:30400
- Prometheus: http://localhost:30300

## Monitoring Features

- Custom application metrics (request counts, response times)
- Node.js runtime metrics (memory, CPU, event loop)
- Auto-provisioned Grafana dashboards
- Real-time monitoring of application health

## CI/CD Pipeline

The included Jenkinsfile demonstrates:
- Building the application
- Running tests
- Building a Docker image
- Deploying to Kubernetes via Helm

## Destroying everything

The following command will destroy the infrastructure and the cluster:

```bash
kind delete cluster
```