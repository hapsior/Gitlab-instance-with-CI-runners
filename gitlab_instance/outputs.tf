output "public_ip_address_gitlab_instance" {
  value = azurerm_public_ip.pip_vm_gitlab_instance.ip_address
}

output "domain_name_label" {
  value = azurerm_public_ip.pip_vm_gitlab_instance.domain_name_label
}

