resource "azurerm_policy_definition" "require_tags" {
  name         = "pfa-require-mandatory-tags"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "PFA - Require Mandatory Tags"
  description  = "Toutes les ressources doivent avoir les tags Environment, Project et ManagedBy"

  policy_rule = jsonencode({
    if = {
      anyOf = [
        { field = "tags['Environment']", exists = "false" },
        { field = "tags['Project']",     exists = "false" },
        { field = "tags['ManagedBy']",   exists = "false" }
      ]
    }
    then = { effect = "deny" }
  })
}

resource "azurerm_resource_group_policy_assignment" "require_tags" {
  name                 = "assign-require-tags"
  resource_group_id    = azurerm_resource_group.main.id
  policy_definition_id = azurerm_policy_definition.require_tags.id
  display_name         = "Enforce Mandatory Tags on all resources"
}

resource "azurerm_policy_definition" "require_disk_encryption" {
  name         = "pfa-require-disk-encryption"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "PFA - Require Disk Encryption on VMs"
  description  = "Toutes les VMs doivent avoir le chiffrement des disques activé"

  policy_rule = jsonencode({
    if = {
      allOf = [
        { field = "type", equals = "Microsoft.Compute/virtualMachines" },
        { field = "Microsoft.Compute/virtualMachines/storageProfile.osDisk.encryptionSettings", exists = "false" }
      ]
    }
    then = { effect = "audit" }
  })
}

resource "azurerm_resource_group_policy_assignment" "require_disk_encryption" {
  name                 = "assign-disk-encryption"
  resource_group_id    = azurerm_resource_group.main.id
  policy_definition_id = azurerm_policy_definition.require_disk_encryption.id
  display_name         = "Audit VM Disk Encryption"
}

resource "azurerm_policy_definition" "deny_dangerous_ports" {
  name         = "pfa-deny-dangerous-ports"
  policy_type  = "Custom"
  mode         = "All"
  display_name = "PFA - Deny Dangerous Ports from Internet"
  description  = "Interdit l'exposition des ports SSH(22), RDP(3389), Telnet(23), FTP(21) depuis Internet"

  policy_rule = jsonencode({
    if = {
      allOf = [
        { field = "type", equals = "Microsoft.Network/networkSecurityGroups/securityRules" },
        { field = "Microsoft.Network/networkSecurityGroups/securityRules/access", equals = "Allow" },
        { field = "Microsoft.Network/networkSecurityGroups/securityRules/direction", equals = "Inbound" },
        { field = "Microsoft.Network/networkSecurityGroups/securityRules/sourceAddressPrefix", in = ["*", "Internet", "0.0.0.0/0"] },
        { field = "Microsoft.Network/networkSecurityGroups/securityRules/destinationPortRange", in = ["22", "3389", "23", "21"] }
      ]
    }
    then = { effect = "deny" }
  })
}

resource "azurerm_resource_group_policy_assignment" "deny_dangerous_ports" {
  name                 = "assign-deny-dangerous-ports"
  resource_group_id    = azurerm_resource_group.main.id
  policy_definition_id = azurerm_policy_definition.deny_dangerous_ports.id
  display_name         = "Deny Dangerous Ports from Internet"
}

resource "azurerm_policy_definition" "require_secure_transfer" {
  name         = "pfa-require-secure-transfer"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "PFA - Require Secure Transfer on Storage"
  description  = "Tous les Storage Accounts doivent forcer HTTPS"

  policy_rule = jsonencode({
    if = {
      allOf = [
        { field = "type", equals = "Microsoft.Storage/storageAccounts" },
        { field = "Microsoft.Storage/storageAccounts/supportsHttpsTrafficOnly", equals = "false" }
      ]
    }
    then = { effect = "deny" }
  })
}

resource "azurerm_resource_group_policy_assignment" "require_secure_transfer" {
  name                 = "assign-require-https"
  resource_group_id    = azurerm_resource_group.main.id
  policy_definition_id = azurerm_policy_definition.require_secure_transfer.id
  display_name         = "Enforce HTTPS on Storage Accounts"
}

output "policy_1" { value = "P-01 : ${azurerm_policy_definition.require_tags.display_name} [DENY]" }
output "policy_2" { value = "P-02 : ${azurerm_policy_definition.require_disk_encryption.display_name} [AUDIT]" }
output "policy_3" { value = "P-03 : ${azurerm_policy_definition.deny_dangerous_ports.display_name} [DENY]" }
output "policy_4" { value = "P-04 : ${azurerm_policy_definition.require_secure_transfer.display_name} [DENY]" }