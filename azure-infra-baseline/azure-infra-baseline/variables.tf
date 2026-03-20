variable "project" {
  description = "Project or workload name used in resource naming"
  type        = string
  default     = "baseline"

  validation {
    condition     = can(regex("^[a-z0-9-]{2,16}$", var.project))
    error_message = "Project name must be 2-16 lowercase alphanumeric characters or hyphens."
  }
}

variable "environment" {
  description = "Deployment environment"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "location" {
  description = "Azure region for all resources"
  type        = string
  default     = "westeurope"
}

variable "location_short" {
  description = "Short location code used in resource naming (e.g. weu, neu, eus)"
  type        = string
  default     = "weu"
}

variable "vnet_address_space" {
  description = "CIDR address space for the Virtual Network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnet_address_prefixes" {
  description = "Address prefixes for each subnet"
  type = object({
    workload = string
    bastion  = string
    mgmt     = string
  })
  default = {
    workload = "10.0.1.0/24"
    bastion  = "10.0.0.0/27"  # AzureBastionSubnet requires /27 minimum
    mgmt     = "10.0.2.0/24"
  }
}

variable "vm_size" {
  description = "Azure VM SKU size"
  type        = string
  default     = "Standard_B2s"
}

variable "admin_username" {
  description = "Local administrator username for the VM"
  type        = string
  default     = "azureadmin"
}

variable "ssh_public_key" {
  description = "SSH public key for VM authentication (paste contents of ~/.ssh/id_rsa.pub)"
  type        = string
  sensitive   = true
}

variable "allowed_ssh_cidrs" {
  description = "List of CIDRs allowed to reach SSH via NSG (use Bastion in prod — this is a dev fallback)"
  type        = list(string)
  default     = []
}
