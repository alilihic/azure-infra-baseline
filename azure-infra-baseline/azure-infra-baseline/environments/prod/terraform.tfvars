# environments/prod/terraform.tfvars

project        = "baseline"
environment    = "prod"
location       = "westeurope"
location_short = "weu"

vnet_address_space = ["10.1.0.0/16"]

subnet_address_prefixes = {
  workload = "10.1.1.0/24"
  bastion  = "10.1.0.0/27"
  mgmt     = "10.1.2.0/24"
}

vm_size        = "Standard_D2s_v3"
admin_username = "azureadmin"

# Paste your SSH public key here
ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2E... your-key-here"

# In prod: no direct SSH — use Bastion only
allowed_ssh_cidrs = []
