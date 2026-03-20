resource "random_string" "acr_suffix" {
  length  = 5
  upper   = false
  special = false
  numeric = true
}

resource "azurerm_container_registry" "main" {
  # ACR name: 5-50 alphanumeric only
  name                = "acr${var.project}${var.environment}${random_string.acr_suffix.result}"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.sku
  admin_enabled       = false   # use managed identity, not admin credentials

  # Geo-redundancy for prod
  dynamic "georeplications" {
    for_each = var.geo_replication_locations
    content {
      location                  = georeplications.value
      zone_redundancy_enabled   = true
      regional_endpoint_enabled = true
    }
  }

  tags = var.tags
}
