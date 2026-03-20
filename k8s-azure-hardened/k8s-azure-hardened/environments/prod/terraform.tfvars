project        = "k8s"
environment    = "prod"
location       = "westeurope"
location_short = "weu"

vnet_address_space = ["10.20.0.0/16"]

subnet_prefixes = {
  aks_nodes = "10.20.1.0/24"
  aks_pods  = "10.20.2.0/22"
  ingress   = "10.20.6.0/24"
}

kubernetes_version  = "1.29"
system_node_count   = 3
system_node_vm_size = "Standard_D4s_v3"
user_node_count     = 3
user_node_vm_size   = "Standard_D8s_v3"

admin_group_object_id = ""
