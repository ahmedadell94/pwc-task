# PWC Python Microservice

## Overview

This repository contains the **Python microservice** for PWC, along with its **CI/CD pipeline** and Kubernetes deployment configuration.  
The microservice is packaged as a Docker container and deployed to an **Azure Kubernetes Service (AKS)** cluster.  
Infrastructure is managed using Terraform, and monitoring and platform setup are handled separately.

---

## Task Description

- Build a Python microservice Docker image.
- Push Docker image to **Azure Container Registry (ACR)**.
- Deploy the image to **AKS** using Kubernetes manifests.
- Handle rollout, validate deployment, and rollback if deployment fails.
- Pipeline triggers on changes to application code, Dockerfile, requirements, or Kubernetes manifests.

---

## Repository Structure

├── app/ # Application source code
│ ├── main.py
│ └── ...
├── k8s/ # Kubernetes manifests (Deployment, Service, etc.)
│ ├── deployment.yaml
│ └── service.yaml
├── .github/workflows/ # GitHub Actions pipeline
│ └── pipeline.yml
├── terraform/ # Terraform infrastructure code
│ └── README.md # Terraform layer instructions
├── Dockerfile # Dockerfile for microservice
├── requirements.txt # Python dependencies
└── README.md # This file

---

## CI/CD Pipeline

The pipeline is defined in **`.github/workflows/deploy.yml`**.

### Triggers

- On **push** to `main` branch.
- On manual trigger (`workflow_dispatch`).
- Only triggers if changes occur in:
  - `app/**`
  - `Dockerfile`
  - `requirements.txt`
  - `k8s/**`
  - `.github/workflows/pipeline.yml`

### Steps

1. **Checkout code**
2. **Set image tag** based on branch and commit SHA:
   - `main` → `prod-<short_sha>`
   - Feature branches can be configured for dev tags
3. **Login to Azure Container Registry (ACR)**
   - Using secrets: `ACR_USERNAME` and `ACR_PASSWORD`
4. **Build Docker image** and push to ACR
5. **Set up kubectl**
6. **Configure kubeconfig**
   - Using secret: `KUBECONFIG_CONTENT`
7. **Deploy to AKS**
   - Update deployment image
   - Wait for rollout
   - Rollback if rollout fails

---

## Required Secrets

Add the following **GitHub Secrets** for the pipeline to work:

| Secret Name            | Description | Example / Notes |
|------------------------|-------------|----------------|
| `ACR_NAME`             | Azure Container Registry name | `pwcregistry` |
| `ACR_USERNAME`         | Username to access ACR | `pwcacr` |
| `ACR_PASSWORD`         | Password / Access Key for ACR | `abc123XYZ...` |
| `KUBECONFIG_CONTENT`   | Full kubeconfig content for AKS cluster | Content of `~/.kube/config` for the cluster |
| `AKS_RG`               | Resource group of AKS cluster | `pwc-rg` |
| `AKS_NAME`             | AKS cluster name | `pwc-aks` |

**Note:** `KUBECONFIG_CONTENT` should contain all cluster and user information. You can export it from your local kubeconfig.

---

## Project Run Order

### 1. Terraform (Infrastructure Layer)

Deploy the **cluster** first. Terraform instructions are in `terraform/README.md`:

- Create AKS cluster
- Create ACR, and other resources
- Output `kube_config_raw` (used in the pipeline)

### 2. CI/CD / Application Layer

- Push changes to main (or trigger manually)
- Pipeline builds image, pushes to ACR, and deploys to AKS
- Validate rollout and rollback if needed

### 3. Access Application

```
kubectl get svc -n prod python-microservice \
  -o jsonpath='{.status.loadBalancer.ingress[0].ip}:{.spec.ports[0].port}'
```
- Open Grafana in your browser
    Use the EXTERNAL-IP (e.g., http://48.194.98.60) in a web browser.
