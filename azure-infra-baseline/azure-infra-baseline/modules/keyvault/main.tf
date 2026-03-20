resource "random_string" "kv_suffix" {
  length  = 5
  upper   = false
  special = false
}

resource "azurerm_key_vault" "main" {
  # Key Vault names: 3-24 chars, alphanumeric + hyphens
  name                = "kv-${var.project}-${var.environment}-${random_string.kv_suffix.result}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id           = var.tenant_id
  sku_name            = "standard"

  # Security hardening
  enabled_for_disk_encryption     = false
  enabled_for_deployment          = false
  enabled_for_template_deployment = false
  enable_rbac_authorization       = true
  purge_protection_enabled        = true
  soft_delete_retention_days      = 90

  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
    # Add your IP or VNet service endpoint to access the vault
    ip_rules       = var.allowed_ip_rules
  }

  tags = var.tags
}

# ── RBAC: grant the deploying principal Key Vault Administrator ───────────────
resource "azurerm_role_assignment" "kv_admin" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = var.admin_object_id
}

# ── Example secret — SSH public key stored securely ─────────────────────────
resource "azurerm_key_vault_secret" "placeholder" {
  name         = "example-secret"
  value        = "replace-me-with-a-real-secret"
  key_vault_id = azurerm_key_vault.main.id
  content_type = "text/plain"

  depends_on = [azurerm_role_assignment.kv_admin]

  tags = var.tags
}
