data "terraform_remote_state" "core" {
  backend = "local"
  config = {
    path = "../core/terraform.tfstate"
  }
}

data "terraform_remote_state" "registry" {
  backend = "local"
  config = {
    path = "../registry/terraform.tfstate"
  }
}

data "azurerm_container_registry" "acr" {
  name                = data.terraform_remote_state.registry.outputs.acr_name
  resource_group_name = data.terraform_remote_state.core.outputs.rg_name
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "pwc-aks"
  location            = data.terraform_remote_state.core.outputs.rg_location
  resource_group_name = data.terraform_remote_state.core.outputs.rg_name

  dns_prefix = "pwcaks"

  default_node_pool {
    name                = "system"
    node_count          = 1
    vm_size             = "Standard_D4ds_v4"
    enable_auto_scaling = true
    min_count           = 1
    max_count           = 3
  }

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                = data.azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
}
