resource "azurerm_resource_group" "main" {
  name     = "rg-${var.application_name}-${var.environment_name}"
  location = var.primary_location
}

resource "random_string" "random_name_label" {
  length  = 8
  upper   = false
  special = false
}

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "main" {
  name                        = "hapi-${random_string.random_name_label.result}-keyvault"
  location                    = var.primary_location
  resource_group_name         = azurerm_resource_group.main.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Get",
    ]

    secret_permissions = [
      "Get", "Set", "List",
    ]

    storage_permissions = [
      "Get",
    ]
  }
}

resource "azurerm_public_ip" "pip_vm_gitlab_instance" {
  name                = "pip-${var.application_name}-${var.environment_name}-vm-gitlab-instance"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  allocation_method   = "Static"
  domain_name_label   = "gitlab-testpkls924"
}

resource "azurerm_virtual_network" "main" {
  name                = "vnet-${var.application_name}-${var.environment_name}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "gitlab_subnet" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.0.0/26"]
}

resource "azurerm_network_interface" "nic_vm_gitlab_instance" {
  name                = "nic-${var.application_name}-${var.environment_name}-vm-gitlab-instance"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "public"
    subnet_id                     = azurerm_subnet.gitlab_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip_vm_gitlab_instance.id
  }
}

# RSA key of size 4096 bits
resource "tls_private_key" "vm_gitlab_instance" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azurerm_key_vault_secret" "vm_gitlab_instance_ssh_private" {
  name         = "vm-gitlab-instance-ssh-private"
  value        = tls_private_key.vm_gitlab_instance.private_key_pem
  key_vault_id = azurerm_key_vault.main.id
}

resource "azurerm_key_vault_secret" "vm_gitlab_instance_ssh_public" {
  name         = "vm-gitlab-instance-ssh-public"
  value        = tls_private_key.vm_gitlab_instance.public_key_openssh
  key_vault_id = azurerm_key_vault.main.id
}

resource "azurerm_network_security_group" "gitlab_nsg" {
  name                = "gitlab-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  # HTTP (GitLab UI)
  security_rule {
    name                       = "allow-http-80"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # HTTPS
  security_rule {
    name                       = "allow-https-443"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # SSH to GitLab (container)
  security_rule {
    name                       = "allow-ssh-6022"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "6022"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # SSH to VM
  security_rule {
    name                       = "allow-ssh-vm-22"
    priority                   = 130
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "gitlab_instance" {
  subnet_id                 = azurerm_subnet.gitlab_subnet.id
  network_security_group_id = azurerm_network_security_group.gitlab_nsg.id
}

resource "azurerm_linux_virtual_machine" "vm_gitlab_instance" {
  name                = "vm-gitlab-instance"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  size                = "Standard_D2s_v3"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.nic_vm_gitlab_instance.id,
  ]

  identity {
    type = "SystemAssigned"
  }

  admin_ssh_key {
    username   = "adminuser"
    public_key = tls_private_key.vm_gitlab_instance.public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  custom_data = filebase64("cloud_init.txt")
}




