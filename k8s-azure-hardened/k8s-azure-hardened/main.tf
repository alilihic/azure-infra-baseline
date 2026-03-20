terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.90"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.47"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.25"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  # backend "azurerm" {
  #   resource_group_name  = "rg-tfstate"
  #   storage_account_name = "sttfstate<unique>"
  #   container_name       = "tfstate"
  #   key                  = "k8s-azure-hardened.tfstate"
  # }
}

provider "azurerm" {
  features {}
}

provider "kubernetes" {
  host                   = module.aks.kube_config.host
  client_certificate     = base64decode(module.aks.kube_config.client_certificate)
  client_key             = base64decode(module.aks.kube_config.client_key)
  cluster_ca_certificate = base64decode(module.aks.kube_config.cluster_ca_certificate)
}

provider "helm" {
  kubernetes {
    host                   = module.aks.kube_config.host
    client_certificate     = base64decode(module.aks.kube_config.client_certificate)
    client_key             = base64decode(module.aks.kube_config.client_key)
    cluster_ca_certificate = base64decode(module.aks.kube_config.cluster_ca_certificate)
  }
}

data "azurerm_client_config" "current" {}

# ── Resource Group ────────────────────────────────────────────────────────────
resource "azurerm_resource_group" "main" {
  name     = "rg-${var.project}-${var.environment}-${var.location_short}"
  location = var.location
  tags     = local.common_tags
}

# ── Networking ────────────────────────────────────────────────────────────────
module "networking" {
  source = "./terraform/modules/networking"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  project             = var.project
  environment         = var.environment
  location_short      = var.location_short
  vnet_address_space  = var.vnet_address_space
  subnet_prefixes     = var.subnet_prefixes
  tags                = local.common_tags
}

# ── Azure Container Registry ──────────────────────────────────────────────────
module "acr" {
  source = "./terraform/modules/acr"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  project             = var.project
  environment         = var.environment
  location_short      = var.location_short
  tags                = local.common_tags
}

# ── AKS Cluster ───────────────────────────────────────────────────────────────
module "aks" {
  source = "./terraform/modules/aks"

  resource_group_name   = azurerm_resource_group.main.name
  location              = azurerm_resource_group.main.location
  project               = var.project
  environment           = var.environment
  location_short        = var.location_short

  node_subnet_id        = module.networking.aks_node_subnet_id
  pod_subnet_id         = module.networking.aks_pod_subnet_id

  kubernetes_version    = var.kubernetes_version
  system_node_count     = var.system_node_count
  system_node_vm_size   = var.system_node_vm_size
  user_node_count       = var.user_node_count
  user_node_vm_size     = var.user_node_vm_size

  acr_id                = module.acr.acr_id
  tenant_id             = data.azurerm_client_config.current.tenant_id
  admin_group_object_id = var.admin_group_object_id

  tags                  = local.common_tags
}
