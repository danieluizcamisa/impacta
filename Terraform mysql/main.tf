terraform {
    required_version =  ">= 0.13 "

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.25.0"
    }
  }
}

provider "azurerm" {
    skip_provider_registration = true
  features {}
}

// resource group
resource "azurerm_resource_group" "rg_aula" {
  name     = "rg"
  location = "West Europe"
      tags = {
        aula = "infra"
    }
}

// rede
resource "azurerm_virtual_network" "vnet_aula" {
  name                = "vnet"
  location            = azurerm_resource_group.rg_aula.location
  resource_group_name = azurerm_resource_group.rg_aula.name
  address_space       = ["10.0.0.0/16"]

  tags = {
    aula = "infra"
  }
}

// subrede - subnet
resource "azurerm_subnet" "subnet_aula" {
  name                 = "subnet"
  resource_group_name  = azurerm_resource_group.rg_aula.name
  virtual_network_name = azurerm_virtual_network.vnet_aula.name
  address_prefixes     = ["10.0.1.0/24"]

}

// Firewall - Network Security Group
resource "azurerm_network_security_group" "nsg_aula" {
  name                = "nsg"
  location            = azurerm_resource_group.rg_aula.location
  resource_group_name = azurerm_resource_group.rg_aula.name

  security_rule {
    name                       = "ssh"
    priority                   = 102
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3306"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

    security_rule {
    name                       = "web"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

// ip publico
resource "azurerm_public_ip" "ip_aula" {
  name                = "ip"
  resource_group_name = azurerm_resource_group.rg_aula.name
  location            = azurerm_resource_group.rg_aula.location
  allocation_method   = "Static"
}

// placa de rede - network interface
resource "azurerm_network_interface" "nic_aula" {
  name                = "nic"
  location            = azurerm_resource_group.rg_aula.location
  resource_group_name = azurerm_resource_group.rg_aula.name

  ip_configuration {
    name                          = "ipvm"
    subnet_id                     = azurerm_subnet.subnet_aula.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.ip_aula.id
  }
}

// associação entre placa de rede e security group
resource "azurerm_network_interface_security_group_association" "nicnsg_aula" {
  network_interface_id      = azurerm_network_interface.nic_aula.id
  network_security_group_id = azurerm_network_security_group.nsg_aula.id
}

// vm
resource "azurerm_linux_virtual_machine" "vm_aula" {
  name                = "vm"
  resource_group_name = azurerm_resource_group.rg_aula.name
  location            = azurerm_resource_group.rg_aula.location
  size                = "Standard_DS1_v2"
  admin_username      = "adminuser"
  admin_password = "adminuser@as02"
  disable_password_authentication = false

  network_interface_ids = [
    azurerm_network_interface.nic_aula.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
}

//sleep
resource "time_sleep" "wait_30_seconds_db" {
  depends_on = [azurerm_linux_virtual_machine.vm_aula]
  create_duration = "30s"
}

// storage account
resource "azurerm_storage_account" "dataStorage" {
  name = "diag${random_id.randomId.hex}"
  account_replication_type = "LRS"
  account_tier = "Standard"
  location = "West Europe"
  resource_group_name = azurerm_resource_group.rg_aula.name

  depends_on = [azurerm_resource_group.rg_aula, random_id.randomId]
}

resource "random_id" "randomId" {
  keepers = {
    resource_group = azurerm_resource_group.rg_aula.name
  }
  byte_length = 8

  depends_on = [azurerm_resource_group.rg_aula]
}








//instalando o mysql
resource "null_resource" "upload_db" {
    provisioner "file" {
        connection {
            type = "ssh"
            host = azurerm_public_ip.ip_aula.ip_address
            user = azurerm_linux_virtual_machine.vm_aula.admin_username
            password = azurerm_linux_virtual_machine.vm_aula.admin_password
        }
        source = "mysql"
        destination = "/home/adminuser"
    }

    //depends_on = [ time_sleep.wait_30_seconds_db ]
}

resource "null_resource" "deploy_db" {
    triggers = {
        order = null_resource.upload_db.id
    }
    provisioner "remote-exec" {
        connection {
            type = "ssh"
            user = "adminuser"
            password = "adminuser@as02"
            host = azurerm_public_ip.ip_aula.ip_address
        }
        inline = [
          "sudo apt update",
          "sudo apt install -y mysql-server-5.7",
          "sudo cp -f /home/adminuser/mysql/mysqld.cnf /etc/mysql/mysql.conf.d/mysqld.cnf",
          "sudo mysql < /home/adminuser/mysql/script.sql",
          "sudo systemctl restart mysql.service",
          "sleep 30"
        ]
    }
}

// exibindo o ip publico
output "publicip" {
  value = azurerm_public_ip.ip_aula.ip_address
  
}
