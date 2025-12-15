data "terraform_remote_state" "core" {
  backend = "local"
  config = {
    path = "../core/terraform.tfstate"
  }
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
