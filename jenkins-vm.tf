# Network Interface pour VM Jenkins (pas d'IP publique)
resource "azurerm_network_interface" "jenkins" {
  name                = "nic-jenkins-vm"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.devops.id
    private_ip_address_allocation = "Dynamic"
  }
}

# VM Jenkins
resource "azurerm_linux_virtual_machine" "jenkins" {
  name                = "vm-jenkins"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  size                = "Standard_D2s_v3"
  admin_username      = "azureuser"

  network_interface_ids = [azurerm_network_interface.jenkins.id]

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("C:/Users/wiki/.ssh/pfa_azure_key.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 64
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
    apt-get install -y openjdk-17-jdk
    wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | apt-key add -
    echo "deb https://pkg.jenkins.io/debian-stable binary/" > /etc/apt/sources.list.d/jenkins.list
    apt-get update && apt-get install -y jenkins
    systemctl enable jenkins && systemctl start jenkins
    curl -fsSL https://get.docker.com | sh
    usermod -aG docker jenkins
    usermod -aG docker azureuser
    wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | apt-key add -
    echo "deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" > /etc/apt/sources.list.d/trivy.list
    apt-get update && apt-get install -y trivy
    curl -sL https://aka.ms/InstallAzureCLIDeb | bash
    sysctl -w vm.max_map_count=524288
    echo "vm.max_map_count=524288" >> /etc/sysctl.conf
    docker run -d --name sonarqube --restart always -p 9000:9000 sonarqube:lts-community
    sleep 90
    cat /var/lib/jenkins/secrets/initialAdminPassword > /home/azureuser/jenkins-init-password.txt
  EOF
  )

  tags = {
    Environment = "Production"
    Project     = "DevSecOps-PFA"
    ManagedBy   = "Terraform"
  }
}

output "jenkins_private_ip" {
  value = azurerm_network_interface.jenkins.private_ip_address
}