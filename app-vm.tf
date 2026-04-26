# Public IP pour VM App
resource "azurerm_public_ip" "app" {
  name                = "pip-app-vm"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    Environment = "Production"
    Project     = "DevSecOps-PFA"
    ManagedBy   = "Terraform"
  }
}

# Network Interface pour VM App
resource "azurerm_network_interface" "app" {
  name                = "nic-app-vm"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.app.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.app.id
  }
}

# VM Application
resource "azurerm_linux_virtual_machine" "app" {
  name                = "vm-app-main"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  size                = "Standard_D2s_v3"
  admin_username      = "azureuser"

  network_interface_ids = [azurerm_network_interface.app.id]

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("C:/Users/wiki/.ssh/pfa_azure_key.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 50
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  custom_data = base64encode(<<-EOF
    #!/bin/bash
    apt-get update && apt-get upgrade -y
    curl -fsSL https://get.docker.com -o get-docker.sh && sh get-docker.sh
    usermod -aG docker azureuser
    apt-get install -y docker-compose-plugin curl wget git htop
    curl -sL https://aka.ms/InstallAzureCLIDeb | bash
    systemctl enable docker && systemctl start docker
  EOF
  )

  tags = {
    Environment = "Production"
    Project     = "DevSecOps-PFA"
    ManagedBy   = "Terraform"
  }
}

output "app_vm_public_ip" {
  value = azurerm_public_ip.app.ip_address
}

output "app_vm_private_ip" {
  value = azurerm_network_interface.app.private_ip_address
}