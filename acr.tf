resource "random_id" "acr_suffix" {
  byte_length = 4
}

resource "azurerm_container_registry" "main" {
  name                = "acrpfa${random_id.acr_suffix.hex}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Basic"
  admin_enabled       = true

  tags = {
    Environment = "Production"
    Project     = "DevSecOps-PFA"
    ManagedBy   = "Terraform"
  }
}

output "acr_login_server" {
  value = azurerm_container_registry.main.login_server
}

output "acr_name" {
  value = azurerm_container_registry.main.name
}