output "vm_id" {
  description = "Resource ID of the virtual machine"
  value       = azurerm_linux_virtual_machine.main.id
}

output "vm_name" {
  description = "Name of the virtual machine"
  value       = azurerm_linux_virtual_machine.main.name
}

output "vm_private_ip" {
  description = "Private IP address assigned to the VM NIC"
  value       = azurerm_network_interface.main.private_ip_address
}

output "vm_identity_principal_id" {
  description = "Principal ID of the VM system-assigned managed identity"
  value       = azurerm_linux_virtual_machine.main.identity[0].principal_id
}
