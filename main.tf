terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}


# SUFFIXE ALÉATOIRE POUR NOM UNIQUE
resource "random_id" "suffix" {
  byte_length = 4
}

# RESOURCE GROUP PRINCIPAL

resource "azurerm_resource_group" "main" {
  name     = "rg-pfa-devsecops"
  location = "germanywestcentral"

  tags = {
    Environment = "Production"
    Project     = "DevSecOps-PFA"
    ManagedBy   = "Terraform"
  }
}


# VNET PRINCIPAL

resource "azurerm_virtual_network" "main" {
  name                = "vnet-pfa"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = {
    Environment = "Production"
    Project     = "DevSecOps-PFA"
    ManagedBy   = "Terraform"
  }
}

#############################################
# SUBNET APP
# VM principale avec Docker Compose
#############################################
resource "azurerm_subnet" "app" {
  name                 = "snet-app"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]
}

#############################################
# SUBNET DEVOPS
# Jenkins + SonarQube
#############################################
resource "azurerm_subnet" "devops" {
  name                 = "snet-devops"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]
}

#############################################
# SUBNET DATA
# PostgreSQL plus tard
#############################################
resource "azurerm_subnet" "data" {
  name                 = "snet-data"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.3.0/24"]

  delegation {
    name = "postgresql-delegation"

    service_delegation {
      name = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action"
      ]
    }
  }
}

#############################################
# SUBNET MONITORING
# Prometheus + Grafana
#############################################
resource "azurerm_subnet" "monitoring" {
  name                 = "snet-monitoring"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.4.0/24"]
}