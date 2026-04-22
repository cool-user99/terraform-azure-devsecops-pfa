terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "sttfstatepfa2026"
    container_name       = "tfstate"
    key                  = "pfa.terraform.tfstate"
  }
}