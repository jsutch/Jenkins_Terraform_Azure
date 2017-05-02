# Configure the Microsoft Azure Provider
variable "server_port" {
  description = "The port the server will use for HTTP requests"
  default = 2112
}
variable "ssh_port" {
  description = "SSH Port"
  default = 22
}

provider "azurerm" {
  subscription_id = "${var.subscription_id}"
  client_id       = "${var.client_id}"
  client_secret   = "${var.client_secret}"
  tenant_id       = "${var.tenant_id}"
}


# create a resource group 
resource "azurerm_resource_group" "Azure_Deploy-3c" {
    name = "azuredeploy3c"
    location = "West US"
}

# Set up network
resource "azurerm_public_ip" "publicIPaddr" {
  name                         = "deploy03pubIP"
  location                     = "West US"
  resource_group_name          = "${azurerm_resource_group.Azure_Deploy-3c.name}"
  public_ip_address_allocation = "static"

}
resource "azurerm_virtual_network" "ten0_net" {
  name                = "deploy03-3c"
  address_space       = ["10.0.0.0/16"]
  location            = "West US"
  resource_group_name = "${azurerm_resource_group.Azure_Deploy-3c.name}"
}

resource "azurerm_subnet" "ten0_subnet" {
  name                 = "deploy03-3c"
  resource_group_name  = "${azurerm_resource_group.Azure_Deploy-3c.name}"
  virtual_network_name = "${azurerm_virtual_network.ten0_net.name}"
  address_prefix       = "10.0.2.0/24"
}

resource "azurerm_network_interface" "ten0_int" {
  name                = "deploy03-3c"
  location            = "West US"
  resource_group_name = "${azurerm_resource_group.Azure_Deploy-3c.name}"

  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = "${azurerm_subnet.ten0_subnet.id}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = "${azurerm_public_ip.publicIPaddr.id}"
  }
}

# Set up Security Group
resource "azurerm_network_security_group" "deploy03secgroup" {
  name                = "Deploy01SecurityGroup3c"
  location            = "West US"
  resource_group_name = "${azurerm_resource_group.Azure_Deploy-3c.name}"
}
# Set up rules
resource "azurerm_network_security_rule" "default-ssh" {
    name = "ssh"
    priority = 100
    direction = "Inbound"
    access = "Allow"
    protocol = "Tcp"
    source_port_range = "*"
    destination_port_range = "22"
    source_address_prefix = "*"
    destination_address_prefix = "*"
    resource_group_name = "${azurerm_resource_group.Azure_Deploy-3c.name}"
    network_security_group_name = "${azurerm_network_security_group.deploy03secgroup.name}"
}
resource "azurerm_network_security_rule" "default-http" {
    name = "http"
    priority = 110
    direction = "Inbound"
    access = "Allow"
    protocol = "Tcp"
    source_port_range = "*"
    destination_port_range = "80"
    source_address_prefix = "*"
    destination_address_prefix = "*"
    resource_group_name = "${azurerm_resource_group.Azure_Deploy-3c.name}"
    network_security_group_name = "${azurerm_network_security_group.deploy03secgroup.name}"
}
resource "azurerm_network_security_rule" "default-http2112" {
    name = "http8080"
    priority = 112
    direction = "Inbound"
    access = "Allow"
    protocol = "Tcp"
    source_port_range = "*"
    destination_port_range = "2112"
    source_address_prefix = "*"
    destination_address_prefix = "*"
    resource_group_name = "${azurerm_resource_group.Azure_Deploy-3c.name}"
    network_security_group_name = "${azurerm_network_security_group.deploy03secgroup.name}"
}

# Make Storage 
resource "azurerm_storage_account" "deploy03sg" {
  name                = "deploy032b"
  resource_group_name = "${azurerm_resource_group.Azure_Deploy-3c.name}"
  location            = "westus"
  account_type        = "Standard_LRS"

  tags {
    environment = "preprod"
  }
}

resource "azurerm_storage_container" "deploy03_container" {
  name                  = "deploy03-3c"
  resource_group_name   = "${azurerm_resource_group.Azure_Deploy-3c.name}"
  storage_account_name  = "${azurerm_storage_account.deploy03sg.name}"
  container_access_type = "private"
}

resource "azurerm_virtual_machine" "deploy03_vm" {
  name                  = "deploy03-3c"
  location              = "West US"
  resource_group_name   = "${azurerm_resource_group.Azure_Deploy-3c.name}"
  network_interface_ids = ["${azurerm_network_interface.ten0_int.id}"]
  vm_size               = "Standard_A0"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name          = "deploy03_disk1"
    vhd_uri       = "${azurerm_storage_account.deploy03sg.primary_blob_endpoint}${azurerm_storage_container.deploy03_container.name}/deploy03_disk1.vhd"
    caching       = "ReadWrite"
    create_option = "FromImage"
  }

# OS setup
  os_profile {
    computer_name  = "deploy3000"
    admin_username = "deployroot"
    admin_password = "${var.admin_password}"
  }

  os_profile_linux_config {
    disable_password_authentication = false
    ssh_keys = [{
      path     = "/home/deployroot/.ssh/authorized_keys"
      key_data = "${file("/var/jenkins_home/.ssh/id_rsa.pub")}"
    }]
  }

 # provisioner "file" {
 #    source      = "/var/jenkins_home/QWERTYFILE"
 #    destination = "/var/tmp/QWERTYFILE"

 #    connection {
 #    type     = "ssh"
 #    user     = "deployroot"
 #    password = "BMoxnn6LPCMt"
 #    timeout = "5m"
 #    }
 #  }

  tags {
    environment = "preprod"
  }
 }
# run the file to start the service
resource "azurerm_virtual_machine_extension" "install" {
  name                 = "busybox"
  location             = "West US"
  resource_group_name  = "${azurerm_resource_group.Azure_Deploy-3c.name}"
  virtual_machine_name = "${azurerm_virtual_machine.deploy03_vm.name}"
  publisher            = "Microsoft.OSTCExtensions"
  type                 = "CustomScriptForLinux"
  type_handler_version = "1.2"

  settings = <<SETTINGS
    {
        "commandToExecute": "echo 'Hello, World - v.10' > /home/deployroot/index.html"
    }
SETTINGS
  tags {
    environment = "preprod"
  }
}



