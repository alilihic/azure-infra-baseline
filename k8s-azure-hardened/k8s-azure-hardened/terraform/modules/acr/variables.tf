variable "resource_group_name" { type = string }
variable "location"            { type = string }
variable "project"             { type = string }
variable "environment"         { type = string }
variable "location_short"      { type = string }

variable "sku" {
  description = "ACR SKU: Basic, Standard, or Premium"
  type        = string
  default     = "Standard"
}

variable "geo_replication_locations" {
  description = "Additional regions for geo-replication (Premium SKU only)"
  type        = list(string)
  default     = []
}

variable "tags" {
  type    = map(string)
  default = {}
}
