variable "resource_group_name" { type = string }
variable "location"            { type = string }
variable "project"             { type = string }
variable "environment"         { type = string }
variable "location_short"      { type = string }
variable "subnet_id"           { type = string }
variable "bastion_subnet_id"   { type = string }
variable "vnet_name"           { type = string }

variable "allowed_ssh_cidrs" {
  type    = list(string)
  default = []
}

variable "tags" {
  type    = map(string)
  default = {}
}
