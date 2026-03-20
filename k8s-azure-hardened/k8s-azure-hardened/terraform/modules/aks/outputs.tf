output "cluster_id" {
  value = azurerm_kubernetes_cluster.main.id
}

output "cluster_name" {
  value = azurerm_kubernetes_cluster.main.name
}

output "kube_config" {
  description = "Kubernetes connection config for providers"
  sensitive   = true
  value       = azurerm_kubernetes_cluster.main.kube_config[0]
}

output "kubelet_identity_object_id" {
  value = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
}

output "cluster_oidc_issuer_url" {
  description = "OIDC issuer URL for workload identity"
  value       = azurerm_kubernetes_cluster.main.oidc_issuer_url
}

output "log_analytics_workspace_id" {
  value = azurerm_log_analytics_workspace.aks.id
}
