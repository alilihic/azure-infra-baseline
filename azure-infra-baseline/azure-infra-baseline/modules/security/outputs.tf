output "nsg_id" {
  description = "Resource ID of the workload NSG"
  value       = azurerm_network_security_group.workload.id
}

output "bastion_id" {
  description = "Resource ID of the Bastion host"
  value       = azurerm_bastion_host.main.id
}

output "bastion_hostname" {
  description = "DNS name of the Bastion public IP"
  value       = azurerm_public_ip.bastion.fqdn
}
