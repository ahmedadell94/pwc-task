provider "azurerm" {
  features {}
}

data "terraform_remote_state" "core" {
  backend = "local"
  config = {
    path = "../core/terraform.tfstate"
  }
}

resource "azurerm_container_registry" "acr" {
  name                = "pwcacr"
  resource_group_name = data.terraform_remote_state.core.outputs.rg_name
  location            = data.terraform_remote_state.core.outputs.rg_location
  sku                 = "Basic"
  admin_enabled       = true
}
