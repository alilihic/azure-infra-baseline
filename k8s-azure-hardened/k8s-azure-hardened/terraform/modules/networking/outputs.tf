output "vnet_id"            { value = azurerm_virtual_network.main.id }
output "vnet_name"          { value = azurerm_virtual_network.main.name }
output "aks_node_subnet_id" { value = azurerm_subnet.aks_nodes.id }
output "aks_pod_subnet_id"  { value = azurerm_subnet.aks_pods.id }
output "ingress_subnet_id"  { value = azurerm_subnet.ingress.id }
