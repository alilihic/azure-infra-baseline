variable "resource_group_name" { type = string }
variable "location"            { type = string }
variable "project"             { type = string }
variable "environment"         { type = string }
variable "location_short"      { type = string }
variable "subnet_id"           { type = string }
variable "key_vault_id"        { type = string }
variable "vm_size"             { type = string }
variable "admin_username"      { type = string }

variable "ssh_public_key" {
  type      = string
  sensitive = true
}

variable "tags" {
  type    = map(string)
  default = {}
}
