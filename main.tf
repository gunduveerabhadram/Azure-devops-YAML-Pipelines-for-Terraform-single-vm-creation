terraform {
  backend "azurerm" {
    
  }
}

terraform {
  required_version= ">= 0.12"
}
provider "azurerm" {
 
   version = "~>2.0"

    # subscription_id="8f14efb9-d2f2-4ef8-aeb8-afe76bf837bc"
    # tenant_id="2350759d-5605-44a5-b4ba-76c6ac205e2b"
    # client_id="87eec86f-b126-4f5d-8596-5e4a8ad7bca5"
  features {
  }
} 

resource "azurerm_resource_group" "myrg" {
    name ="ccep_rg"
    location = "westeurope"
}
resource "azurerm_virtual_network" "myvnet" {
    name="ccep_vnet"
    resource_group_name = azurerm_resource_group.myrg.name
    location = azurerm_resource_group.myrg.location
    address_space = ["10.0.0.0/16"]
}
resource "azurerm_subnet" "mysubnet" {
    name ="ccep_subnet"
    resource_group_name = azurerm_resource_group.myrg.name
    virtual_network_name = azurerm_virtual_network.myvnet.name
    address_prefixes = ["10.0.0.0/24"]
  
}
resource "azurerm_network_interface" "mynic" {
  name = "ccep-mynic"
  location = azurerm_resource_group.myrg.location
  resource_group_name = azurerm_resource_group.myrg.name

  ip_configuration {
    name= "ccepconfiguration"
    subnet_id = azurerm_subnet.mysubnet.id
    private_ip_address_allocation = "Dynamic"
  }
}
resource "azurerm_windows_virtual_machine" "main" {
  name                            = "vmt01"
  resource_group_name             = azurerm_resource_group.myrg.name
  location                        = azurerm_resource_group.myrg.location
  size                            = "Standard_DS1_v2"
  admin_username                  = "adminuser"
  admin_password                  = "Welcome@2024"
  computer_name = "vmtest"
  network_interface_ids = [ azurerm_network_interface.mynic.id ]

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
    
    
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
    disk_size_gb = "200"
  
  }
  
}
resource "azurerm_managed_disk" "mdisk" {
  name                 = "vm01-disk1"
  location             = azurerm_resource_group.myrg.location
  resource_group_name  = azurerm_resource_group.myrg.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 50
}

resource "azurerm_virtual_machine_data_disk_attachment" "mdisk" {
  managed_disk_id    = azurerm_managed_disk.mdisk.id
  virtual_machine_id = azurerm_windows_virtual_machine.main.id
  lun                = "0"
  caching            = "ReadWrite"
}
