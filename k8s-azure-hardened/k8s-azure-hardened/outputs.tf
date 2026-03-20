output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "aks_cluster_name" {
  description = "Name of the AKS cluster"
  value       = module.aks.cluster_name
}

output "aks_cluster_id" {
  description = "Resource ID of the AKS cluster"
  value       = module.aks.cluster_id
}

output "acr_login_server" {
  description = "Login server URL for the container registry"
  value       = module.acr.acr_login_server
}

output "acr_name" {
  description = "Name of the Azure Container Registry"
  value       = module.acr.acr_name
}

output "vnet_id" {
  description = "Resource ID of the VNet"
  value       = module.networking.vnet_id
}

output "get_credentials_command" {
  description = "Azure CLI command to fetch kubeconfig"
  value       = "az aks get-credentials --resource-group ${azurerm_resource_group.main.name} --name ${module.aks.cluster_name} --overwrite-existing"
}
