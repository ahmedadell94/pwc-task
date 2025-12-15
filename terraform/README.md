# Terraform Infrastructure

This directory contains the Terraform code for provisioning the full infrastructure for the Python microservices platform on Azure.  
The code is structured in **layers** for clarity, maintainability, and reusability.

---

## Architecture & Layers

The Terraform code is organized into the following **layers**:

| Layer       | Purpose                                                                                 |
|------------|-----------------------------------------------------------------------------------------|
| **core** | Provision the **Azure Resource Group** (`pwc-rg`). This is the single RG used by all other layers. |
| **registry** | Provision **Azure Container Registry (ACR)** for storing Docker images. Uses outputs from the `core` layer. |
| **cluster**  | Provision **Azure Kubernetes Service (AKS)** cluster. References the same RG from the `core` layer. |
| **platform** | Deploy **base platform applications** (Prometheus, Grafana) on the AKS cluster. Requires the cluster from `cluster`. |

> Each layer is independent and has a **single responsibility**, following platform engineering best practices. Outputs from previous layers are consumed using `terraform_remote_state`.

---

## Terraform Layer Details

### 1. core
- **Purpose:** Create the resource group `pwc-rg` where all resources will reside.
- **Key output:**  
  - `rg_name` – Resource Group Name  
  - `rg_location` – Resource Group Location

### 2. registry
- **Purpose:** Create Azure Container Registry (ACR) to store Docker images.  
- **Dependencies:** `core` (RG)  
- **Key outputs:**  
  - `acr_name`  
  - `acr_login_server`  
  - `acr_admin_username` / `acr_admin_password`

### 3. cluster
- **Purpose:** Provision AKS cluster.  
- **Dependencies:** `core` (RG)  
- **Key outputs:**  
  - `kube_config` – Raw kubeconfig for accessing the cluster

### 4. platform
- **Purpose:** Deploy base platform applications on AKS.  
- **Dependencies:** `cluster` (AKS)  
- **Components deployed:**  
  - Prometheus + Grafana for monitoring  
- **Notes:** Uses Helm provider and Kubernetes provider.

---

## How to Apply Terraform Layers

The layers **must be applied in order**:

### Step 1 – Core (Resource Group)
```bash
cd terraform/core
terraform init
terraform apply
```

**Expected result:**
- Azure resource group pwc-rg is created.

- Outputs rg_name and rg_location are available.

### Step 2 – Registry (ACR)
```bash
cd ../registry
terraform init
terraform apply
```

**Expected result:**
- Azure Container Registry is created inside pwc-rg.

- Outputs for login server and credentials are available.

### Step 3 – Cluster (AKS)
```
cd ../cluster
terraform init
terraform apply
```

**Expected result:**
- AKS cluster is created in pwc-rg.
- Node pool with autoscaling is enabled.
- Output kube_config is available.

### Step 4 – Platform Apps
```
# Get kubeconfig from previous step
az aks get-credentials --resource-group pwc-rg --name pwc-aks

cd ../platform
terraform init
terraform apply
```

**Expected result:**
- Prometheus + Grafana are installed in monitoring namespace.
- Cluster is ready for application deployments.

### Step 5 - Configure Cluster Access Locally
```
az aks get-credentials --resource-group pwc-rg --name pwc-aks --overwrite-existing
kubectl get nodes
```
**Expected result:**
- kubeconfig updated locally
- Able to run kubectl get nodes to see AKS nodes

### Step 6 - Access Grafana Dashboard

```
kubectl get svc -n monitoring kube-prometheus-stack-grafana \
  -o jsonpath='{.status.loadBalancer.ingress[0].ip}:{.spec.ports[0].port}'
```
- Open Grafana in your browser
    Use the EXTERNAL-IP (e.g., http://48.194.98.60) in a web browser.
- Login credentials
    Username: admin
    Password: admin