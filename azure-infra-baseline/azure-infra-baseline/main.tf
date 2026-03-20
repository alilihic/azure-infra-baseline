terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.90"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  # Uncomment to use Azure backend for remote state
  # backend "azurerm" {
  #   resource_group_name  = "rg-tfstate"
  #   storage_account_name = "sttfstate<unique>"
  #   container_name       = "tfstate"
  #   key                  = "azure-infra-baseline.tfstate"
  # }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }
    virtual_machine {
      delete_os_disk_on_deletion     = true
      graceful_shutdown              = false
    }
  }
}

# ── Resource Group ──────────────────────────────────────────────────────────
resource "azurerm_resource_group" "main" {
  name     = "rg-${var.project}-${var.environment}-${var.location_short}"
  location = var.location

  tags = local.common_tags
}

# ── Networking ──────────────────────────────────────────────────────────────
module "networking" {
  source = "./modules/networking"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  project             = var.project
  environment         = var.environment
  location_short      = var.location_short

  vnet_address_space     = var.vnet_address_space
  subnet_address_prefixes = var.subnet_address_prefixes

  tags = local.common_tags
}

# ── Key Vault ───────────────────────────────────────────────────────────────
module "keyvault" {
  source = "./modules/keyvault"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  project             = var.project
  environment         = var.environment
  location_short      = var.location_short

  tenant_id           = data.azurerm_client_config.current.tenant_id
  admin_object_id     = data.azurerm_client_config.current.object_id

  tags = local.common_tags
}

# ── Security (NSG + Bastion) ─────────────────────────────────────────────────
module "security" {
  source = "./modules/security"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  project             = var.project
  environment         = var.environment
  location_short      = var.location_short

  subnet_id           = module.networking.workload_subnet_id
  bastion_subnet_id   = module.networking.bastion_subnet_id
  vnet_name           = module.networking.vnet_name

  allowed_ssh_cidrs   = var.allowed_ssh_cidrs

  tags = local.common_tags
}

# ── Compute ──────────────────────────────────────────────────────────────────
module "compute" {
  source = "./modules/compute"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  project             = var.project
  environment         = var.environment
  location_short      = var.location_short

  subnet_id           = module.networking.workload_subnet_id
  key_vault_id        = module.keyvault.key_vault_id
  vm_size             = var.vm_size
  admin_username      = var.admin_username
  ssh_public_key      = var.ssh_public_key

  tags = local.common_tags
}

# ── Data Sources ─────────────────────────────────────────────────────────────
data "azurerm_client_config" "current" {}
