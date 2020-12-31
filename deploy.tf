provider "azurerm" {
  version = "=2.41.0"
  features {}
}


data "azurerm_resource_group" "cirslis" {
  name = "cirslis"
}

data "azurerm_subnet" "cirslis" {
  name                 = "default"
  virtual_network_name = "cirslis-vnet"
  resource_group_name  = "cirslis"
}

data "azurerm_storage_container" "vhds" {
  name                 = "vhds"
  storage_account_name = "cirslisdata"
}


variable "tag" { type = "string" }

locals {
  rg = data.azurerm_resource_group.cirslis.name
}


resource "azurerm_storage_blob" "main" {
  name = "austina-${var.tag}.vhd"
	source = "${path.module}/out/austina-${var.tag}.vhd"
  type = "Page"

  storage_account_name   = data.azurerm_storage_container.vhds.storage_account_name
  storage_container_name = data.azurerm_storage_container.vhds.name
}

resource "azurerm_virtual_machine" "main" {
  name                  = "austina-vm"
  resource_group_name   = local.rg
  location              = "northeurope"

  network_interface_ids = [azurerm_network_interface.main.id]
  vm_size               = "Standard_B1ls"

  storage_os_disk {
    name = "osdisk"
    create_option = "attach"
    os_type = "linux"
    vhd_uri = azurerm_storage_blob.main.url
  }
}

resource "azurerm_network_interface" "main" {
  name                = "austina-nic"
  resource_group_name = local.rg
  location            = "northeurope"

  ip_configuration {
    name                          = "ip1"
    subnet_id                     = data.azurerm_subnet.cirslis.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.main.id
  }
}

resource "azurerm_network_interface_security_group_association" "default" {
  network_interface_id      = azurerm_network_interface.main.id
  network_security_group_id = azurerm_network_security_group.main.id
}

resource "azurerm_public_ip" "main" {
  name                = "austina-ip"
  resource_group_name = local.rg
  location            = "northeurope"
  allocation_method   = "Static"
  domain_name_label   = "austina"
}

resource "azurerm_network_security_group" "main" {
    name                = "austina-nsg"
    resource_group_name = local.rg
    location            = "northeurope"
    
    security_rule {
        name                       = "wireguard"
        priority                   = 2001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Udp"
        source_port_range          = "*"
        destination_port_range     = "51820"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    security_rule {
        name                       = "all-tcp"
        priority                   = 3001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "*"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    security_rule {
        name                       = "all-udp"
        priority                   = 3002
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Udp"
        source_port_range          = "*"
        destination_port_range     = "*"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
}
