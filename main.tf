terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

provider "azurerm" {
  features {}
}

#Create Resource Group "JWM-Terraform"
resource "azurerm_resource_group" "JWM-Terraform" {
  name     = "JWM-Terraform"
  location = "East US"
  tags = {
    environment = "dev"
  }
}

#Create Virtual Network "VNET1"
resource "azurerm_virtual_network" "VNET1" {
  name                = "VNET1"
  location            = azurerm_resource_group.JWM-Terraform.location
  resource_group_name = azurerm_resource_group.JWM-Terraform.name
  address_space       = ["10.123.0.0/16"]

  tags = {
    environment = "dev"
  }
}

#Create Subnet "subnet" seperatley from VNET1
resource "azurerm_subnet" "subnet" {
  name                 = "subnet"
  resource_group_name  = azurerm_resource_group.JWM-Terraform.name
  virtual_network_name = azurerm_virtual_network.VNET1.name
  address_prefixes     = ["10.123.1.0/24"]
}

#Create NSG "NSG1" seperatley from VNET1
resource "azurerm_network_security_group" "NSG1" {
  name                = "NSG1"
  location            = azurerm_resource_group.JWM-Terraform.location
  resource_group_name = azurerm_resource_group.JWM-Terraform.name

  tags = {
    environment = "dev"
  }
}

#Create NSG rules Seperatley from NSG1 (allowing all inbound from MY IPv4)
resource "azurerm_network_security_rule" "NSG1-rules" {
  name                        = "NSG1-rules"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "99.57.68.167/32"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.JWM-Terraform.name
  network_security_group_name = azurerm_network_security_group.NSG1.name
}

#Associate NSG1 to "subnet"
resource "azurerm_subnet_network_security_group_association" "NSG1-Subnet" {
  subnet_id                 = azurerm_subnet.subnet.id
  network_security_group_id = azurerm_network_security_group.NSG1.id
}

#Create Public IP
resource "azurerm_public_ip" "JWM-IP-1" {
  name                = "JWM-IP-1"
  resource_group_name = azurerm_resource_group.JWM-Terraform.name
  location            = azurerm_resource_group.JWM-Terraform.location
  allocation_method   = "Dynamic"

  tags = {
    environment = "dev"
  }
}

#Create NIC, attatching public IP
resource "azurerm_network_interface" "nic1" {
  name                = "nic1"
  location            = azurerm_resource_group.JWM-Terraform.location
  resource_group_name = azurerm_resource_group.JWM-Terraform.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.JWM-IP-1.id
  }

  tags = {
    environment = "dev"
  }
}

#Create Win 11 Desktop VM, attatching NIC1
resource "azurerm_windows_virtual_machine" "JWM-VM-1" {
  name                = "JWM-VM-1"
  resource_group_name = azurerm_resource_group.JWM-Terraform.name
  location            = azurerm_resource_group.JWM-Terraform.location
  size                = "Standard_DC2s_v2"
  admin_username      = "superuser"
  admin_password      = "Cust0mersf1rst!"
  network_interface_ids = [
    azurerm_network_interface.nic1.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "Windows-11"
    sku       = "win11-22h2-pro"
    version   = "latest"
  }

  tags = {
    environment = "dev"
  }
}