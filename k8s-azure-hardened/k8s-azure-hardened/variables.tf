variable "project" {
  description = "Project name used in resource naming"
  type        = string
  default     = "k8s"

  validation {
    condition     = can(regex("^[a-z0-9-]{2,12}$", var.project))
    error_message = "Project must be 2-12 lowercase alphanumeric characters or hyphens."
  }
}

variable "environment" {
  description = "Deployment environment"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Must be one of: dev, staging, prod."
  }
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "westeurope"
}

variable "location_short" {
  description = "Short location code for resource naming"
  type        = string
  default     = "weu"
}

variable "vnet_address_space" {
  description = "Address space for the VNet"
  type        = list(string)
  default     = ["10.10.0.0/16"]
}

variable "subnet_prefixes" {
  description = "CIDR prefixes for each subnet"
  type = object({
    aks_nodes = string
    aks_pods  = string
    ingress   = string
  })
  default = {
    aks_nodes = "10.10.1.0/24"
    aks_pods  = "10.10.2.0/22"   # larger — one IP per pod with Azure CNI
    ingress   = "10.10.6.0/24"
  }
}

variable "kubernetes_version" {
  description = "Kubernetes version for the AKS cluster"
  type        = string
  default     = "1.29"
}

variable "system_node_count" {
  description = "Number of nodes in the system node pool"
  type        = number
  default     = 2
}

variable "system_node_vm_size" {
  description = "VM size for system node pool"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "user_node_count" {
  description = "Initial number of nodes in the user node pool"
  type        = number
  default     = 2
}

variable "user_node_vm_size" {
  description = "VM size for user node pool"
  type        = string
  default     = "Standard_D4s_v3"
}

variable "admin_group_object_id" {
  description = "Azure AD group object ID for AKS cluster admins"
  type        = string
  default     = ""
}
