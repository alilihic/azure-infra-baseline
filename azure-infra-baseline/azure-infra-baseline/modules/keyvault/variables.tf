variable "resource_group_name" { type = string }
variable "location"            { type = string }
variable "project"             { type = string }
variable "environment"         { type = string }
variable "location_short"      { type = string }
variable "tenant_id"           { type = string }
variable "admin_object_id"     { type = string }

variable "allowed_ip_rules" {
  description = "List of IP CIDRs allowed through the Key Vault network ACL"
  type        = list(string)
  default     = []
}

variable "tags" {
  type    = map(string)
  default = {}
}
