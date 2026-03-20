variable "resource_group_name" { type = string }
variable "location"            { type = string }
variable "project"             { type = string }
variable "environment"         { type = string }
variable "location_short"      { type = string }
variable "vnet_address_space"  { type = list(string) }

variable "subnet_prefixes" {
  type = object({
    aks_nodes = string
    aks_pods  = string
    ingress   = string
  })
}

variable "tags" {
  type    = map(string)
  default = {}
}
