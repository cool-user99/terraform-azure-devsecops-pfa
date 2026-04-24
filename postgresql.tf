# Private DNS Zone for PostgreSQL
resource "azurerm_private_dns_zone" "postgresql" {
  name                = "privatelink.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.main.name
}

# Link DNS Zone to VNet
resource "azurerm_private_dns_zone_virtual_network_link" "postgresql" {
  name                  = "postgresql-vnet-link"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.postgresql.name
  virtual_network_id    = azurerm_virtual_network.main.id

  depends_on = [azurerm_private_dns_zone.postgresql]
}

# PostgreSQL Flexible Server
resource "azurerm_postgresql_flexible_server" "main" {
  name                   = "psql-pfa-${random_id.suffix.hex}"
  resource_group_name    = azurerm_resource_group.main.name
  location               = azurerm_resource_group.main.location
  version                = "15"
  delegated_subnet_id    = azurerm_subnet.data.id
  private_dns_zone_id    = azurerm_private_dns_zone.postgresql.id
  administrator_login    = "psqladmin"
  administrator_password = azurerm_key_vault_secret.postgresql_password.value
  zone                   = "1"
  storage_mb             = 32768
  sku_name               = "B_Standard_B1ms"

  backup_retention_days         = 7
  geo_redundant_backup_enabled  = false
  public_network_access_enabled = false

  tags = {
    Environment = "Production"
    Project     = "DevSecOps-PFA"
    ManagedBy   = "Terraform"
  }

  depends_on = [azurerm_private_dns_zone_virtual_network_link.postgresql]
}

# Database inside the server
resource "azurerm_postgresql_flexible_server_database" "main" {
  name      = "pfa_db"
  server_id = azurerm_postgresql_flexible_server.main.id
  collation = "en_US.utf8"
  charset   = "utf8"
}

output "postgresql_fqdn" {
  value = azurerm_postgresql_flexible_server.main.fqdn
}