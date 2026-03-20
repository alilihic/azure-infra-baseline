# environments/dev/terraform.tfvars
# Copy this file and fill in your values before running terraform apply

project        = "baseline"
environment    = "dev"
location       = "westeurope"
location_short = "weu"

vnet_address_space = ["10.0.0.0/16"]

subnet_address_prefixes = {
  workload = "10.0.1.0/24"
  bastion  = "10.0.0.0/27"
  mgmt     = "10.0.2.0/24"
}

vm_size        = "Standard_B2s"
admin_username = "azureadmin"

# Paste your SSH public key here (cat ~/.ssh/id_rsa.pub)
ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2E... your-key-here"

# Optional: restrict SSH to your IP (leave empty to rely on Bastion only)
allowed_ssh_cidrs = []
