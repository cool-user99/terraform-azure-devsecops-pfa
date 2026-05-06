resource "azurerm_role_definition" "deployer" {
  name        = "PFA-Deployer"
  scope       = azurerm_resource_group.main.id
  description = "Permissions minimales pour Jenkins"

  permissions {
    actions = [
      "Microsoft.Resources/subscriptions/resourceGroups/read",
      "Microsoft.Compute/virtualMachines/read",
      "Microsoft.Compute/virtualMachines/runCommand/action",
    ]
    not_actions = []
  }

  assignable_scopes = [azurerm_resource_group.main.id]
}

output "jenkins_role_name"     { value = azurerm_role_definition.deployer.name }
output "jenkins_role_assigned" { value = "PFA-Deployer (Least Privilege)" }