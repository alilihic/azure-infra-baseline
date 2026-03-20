output "resource_group_name" {
  description = "Name of the main resource group"
  value       = azurerm_resource_group.main.name
}

output "vnet_id" {
  description = "Resource ID of the Virtual Network"
  value       = module.networking.vnet_id
}

output "vnet_name" {
  description = "Name of the Virtual Network"
  value       = module.networking.vnet_name
}

output "workload_subnet_id" {
  description = "Resource ID of the workload subnet"
  value       = module.networking.workload_subnet_id
}

output "key_vault_id" {
  description = "Resource ID of the Key Vault"
  value       = module.keyvault.key_vault_id
}

output "key_vault_uri" {
  description = "URI of the Key Vault"
  value       = module.keyvault.key_vault_uri
}

output "vm_id" {
  description = "Resource ID of the virtual machine"
  value       = module.compute.vm_id
}

output "vm_private_ip" {
  description = "Private IP address of the virtual machine"
  value       = module.compute.vm_private_ip
}

output "bastion_hostname" {
  description = "DNS name of the Azure Bastion host"
  value       = module.security.bastion_hostname
}
