output "vnet_id" {
  description = "Resource ID of the VNet"
  value       = azurerm_virtual_network.main.id
}

output "vnet_name" {
  description = "Name of the VNet"
  value       = azurerm_virtual_network.main.name
}

output "workload_subnet_id" {
  description = "Resource ID of the workload subnet"
  value       = azurerm_subnet.workload.id
}

output "bastion_subnet_id" {
  description = "Resource ID of the AzureBastionSubnet"
  value       = azurerm_subnet.bastion.id
}

output "mgmt_subnet_id" {
  description = "Resource ID of the management subnet"
  value       = azurerm_subnet.mgmt.id
}

output "network_watcher_id" {
  description = "Resource ID of the Network Watcher"
  value       = azurerm_network_watcher.main.id
}
