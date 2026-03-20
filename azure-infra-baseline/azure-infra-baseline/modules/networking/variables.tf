variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "location_short" {
  type = string
}

variable "vnet_address_space" {
  type = list(string)
}

variable "subnet_address_prefixes" {
  type = object({
    workload = string
    bastion  = string
    mgmt     = string
  })
}

variable "tags" {
  type    = map(string)
  default = {}
}
