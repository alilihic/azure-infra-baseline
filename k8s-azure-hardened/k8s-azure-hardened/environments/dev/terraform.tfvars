project        = "k8s"
environment    = "dev"
location       = "westeurope"
location_short = "weu"

vnet_address_space = ["10.10.0.0/16"]

subnet_prefixes = {
  aks_nodes = "10.10.1.0/24"
  aks_pods  = "10.10.2.0/22"
  ingress   = "10.10.6.0/24"
}

kubernetes_version  = "1.29"
system_node_count   = 2
system_node_vm_size = "Standard_D2s_v3"
user_node_count     = 2
user_node_vm_size   = "Standard_D4s_v3"

# Set this to your Azure AD group object ID for cluster admin access
# az ad group show --group "k8s-admins" --query id -o tsv
admin_group_object_id = ""
