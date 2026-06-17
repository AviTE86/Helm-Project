# Helm Project - CI/CD and GitOps Deployment

## Overview

This project demonstrates a complete CI/CD and GitOps workflow using:

* GitHub
* Jenkins
* Docker Hub
* Helm
* ArgoCD
* Kubernetes
* Terraform

The application is containerized, built automatically through Jenkins, stored in Docker Hub, and deployed to Kubernetes using ArgoCD and GitOps principles.

---

## Repositories

### Application Repository

Contains:

* Flask application source code
* Dockerfile
* Jenkinsfile
* Helm chart

Repository:

https://github.com/AviTE86/Helm-Project

### GitOps Repository

Contains:

* Environment-specific configurations
* ApplicationSet definition
* Deployment manifests managed by ArgoCD

Repository:

https://github.com/AviTE86/GitOps

### Terraform Repository

Contains:

* Infrastructure provisioning code
* Kubernetes environment deployment

Repository:

https://github.com/AviTE86/terraform

---

## Architecture

Developer
→ GitHub
→ Jenkins
→ Docker Hub
→ GitOps Repository
→ ArgoCD
→ Kubernetes

---

## CI/CD Workflow

### 1. Code Commit

The developer pushes code changes to the application repository.

### 2. Jenkins Pipeline

The Jenkins pipeline performs:

* Repository checkout
* Linting checks
* Security scanning
* Docker image build
* Docker image push to Docker Hub

### 3. GitOps Update

Jenkins updates the GitOps repository with the latest deployment artifacts.

### 4. ArgoCD Synchronization

ArgoCD detects changes in the GitOps repository and automatically deploys the updated application.

---

## Environments

The project supports three environments:

* dev
* qa
* prd

Each environment maintains its own configuration through separate values files.

Examples of environment-specific configuration:

* Replica count
* Service type
* Resource allocation
* Image version

---

## Helm

The application is packaged using Helm.

The Helm chart contains:

* Deployment template
* Service template
* Values configuration

Deployment parameters such as image name, image tag, replicas, and ports are configurable through values.yaml.

---

## ArgoCD

ArgoCD is configured using an ApplicationSet.

The ApplicationSet automatically creates applications for:

* dev
* qa
* prd

Features:

* Automated synchronization
* Self-healing
* Automatic pruning
* Environment-specific deployments

---

## Terraform

Terraform is used to provision the Kubernetes infrastructure.

Main Terraform commands:

```bash
terraform init
terraform plan
terraform apply
```

---

## Deployment Verification

The following validations were performed:

* Jenkins pipeline completed successfully
* Docker image pushed to Docker Hub
* ArgoCD applications created successfully
* Environment-specific deployments created
* Kubernetes resources deployed and running
* GitOps synchronization functioning correctly

---

## Technologies Used

* Python
* Docker
* Kubernetes
* Helm
* Jenkins
* ArgoCD
* Terraform
* GitHub
* Docker Hub

---

## Author

Avi Tal-El
