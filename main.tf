provider "azurerm" {
  subscription_id = "bad5e280-31e7-4f3e-961c-263486f09f86"
  features {
  }
}

#Create azure resource group
resource "azurerm_resource_group" "import_rg" {
  name     = "Terraform_Import_Demo_RG"
  location = "centralindia"
}

#Create virtual network for the VM
resource "azurerm_virtual_network" "import_vnet" {
  name                = "vnet"
  location            = azurerm_resource_group.import_rg.location
  address_space       = ["10.0.0.0/16"]
  resource_group_name = azurerm_resource_group.import_rg.name
}

#Create subnet to the virtual network
resource "azurerm_subnet" "import_subnet" {
  name                 = "import_subnet"
  virtual_network_name = azurerm_virtual_network.import_vnet.name
  resource_group_name  = azurerm_resource_group.import_rg.name
  address_prefixes     = ["10.0.2.0/24"]
}

##################################Import Code Block##################################################

resource "azurerm_network_security_group" "nsg_ssh_allow" {
  name                = "import-demo-VM-nsg"
  location            = azurerm_resource_group.import_rg.location
  resource_group_name = azurerm_resource_group.import_rg.name

  security_rule {
    name                       = "SSH"
    priority                   = 300
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface" "nic" {
  name                = "import-demo-vm624"
  location            = azurerm_resource_group.import_rg.location
  resource_group_name = azurerm_resource_group.import_rg.name
  
  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.import_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface_security_group_association" "nsg_nic_association" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg_ssh_allow.id
}

resource "azurerm_virtual_machine" "test_vm" {
  name                  = "import-demo-VM"
  location              = azurerm_resource_group.import_rg.location
  resource_group_name   = azurerm_resource_group.import_rg.name
  network_interface_ids = [azurerm_network_interface.nic.id]
  vm_size               = "Standard_B1ms"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "my-test-os-disk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
  }

  os_profile {
    computer_name  = "test"
    admin_username = "test-user"
    admin_password = "test-password123"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}