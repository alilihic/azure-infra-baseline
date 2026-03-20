variable "resource_group_name" { type = string }
variable "location"            { type = string }
variable "project"             { type = string }
variable "environment"         { type = string }
variable "location_short"      { type = string }
variable "node_subnet_id"      { type = string }
variable "pod_subnet_id"       { type = string }
variable "acr_id"              { type = string }
variable "tenant_id"           { type = string }
variable "kubernetes_version"  { type = string }
variable "system_node_count"   { type = number }
variable "system_node_vm_size" { type = string }
variable "user_node_count"     { type = number }
variable "user_node_vm_size"   { type = string }

variable "admin_group_object_id" {
  description = "Azure AD group for AKS cluster admins"
  type        = string
  default     = ""
}

variable "api_server_authorized_ip_ranges" {
  description = "CIDRs allowed to reach the Kubernetes API server"
  type        = list(string)
  default     = []
}

variable "tags" {
  type    = map(string)
  default = {}
}
