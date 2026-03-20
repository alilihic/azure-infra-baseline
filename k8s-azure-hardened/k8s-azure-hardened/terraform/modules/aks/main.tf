# ── Log Analytics Workspace (for Container Insights) ─────────────────────────
resource "azurerm_log_analytics_workspace" "aks" {
  name                = "law-${var.project}-${var.environment}-${var.location_short}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = var.tags
}

# ── AKS Cluster ───────────────────────────────────────────────────────────────
resource "azurerm_kubernetes_cluster" "main" {
  name                = "aks-${var.project}-${var.environment}-${var.location_short}"
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = "${var.project}-${var.environment}"
  kubernetes_version  = var.kubernetes_version

  # ── System node pool ───────────────────────────────────────────────────────
  default_node_pool {
    name                         = "system"
    node_count                   = var.system_node_count
    vm_size                      = var.system_node_vm_size
    vnet_subnet_id               = var.node_subnet_id
    pod_subnet_id                = var.pod_subnet_id
    os_disk_size_gb              = 64
    os_disk_type                 = "Ephemeral"
    only_critical_addons_enabled = true   # taint: CriticalAddonsOnly
    zones                        = ["1", "2", "3"]

    upgrade_settings {
      max_surge = "33%"
    }
  }

  # ── Identity ───────────────────────────────────────────────────────────────
  identity {
    type = "SystemAssigned"
  }

  # ── Network: Azure CNI with network policies ───────────────────────────────
  network_profile {
    network_plugin    = "azure"
    network_policy    = "calico"       # enforce NetworkPolicy objects
    load_balancer_sku = "standard"
    outbound_type     = "loadBalancer"
    service_cidr      = "172.16.0.0/16"
    dns_service_ip    = "172.16.0.10"
  }

  # ── RBAC: Entra ID (Azure AD) integration ─────────────────────────────────
  azure_active_directory_role_based_access_control {
    managed                = true
    tenant_id              = var.tenant_id
    admin_group_object_ids = var.admin_group_object_id != "" ? [var.admin_group_object_id] : []
    azure_rbac_enabled     = true
  }

  # ── Security hardening ─────────────────────────────────────────────────────
  local_account_disabled = true    # force AAD auth — no local admin account

  api_server_access_profile {
    authorized_ip_ranges = var.api_server_authorized_ip_ranges
  }

  # ── Add-ons ────────────────────────────────────────────────────────────────
  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.aks.id
  }

  azure_policy_enabled             = true
  http_application_routing_enabled = false  # use ingress-nginx instead

  # ── Maintenance window ─────────────────────────────────────────────────────
  maintenance_window {
    allowed {
      day   = "Sunday"
      hours = [2, 4]
    }
  }

  # ── Auto-upgrade ──────────────────────────────────────────────────────────
  automatic_channel_upgrade = "patch"

  tags = var.tags
}

# ── User node pool (workloads) ─────────────────────────────────────────────────
resource "azurerm_kubernetes_cluster_node_pool" "user" {
  name                  = "user"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  vm_size               = var.user_node_vm_size
  node_count            = var.user_node_count
  vnet_subnet_id        = var.node_subnet_id
  pod_subnet_id         = var.pod_subnet_id
  os_disk_type          = "Ephemeral"
  zones                 = ["1", "2", "3"]

  # Auto-scaling
  enable_auto_scaling = true
  min_count           = var.user_node_count
  max_count           = var.user_node_count * 3

  node_labels = {
    "workload-type" = "user"
  }

  upgrade_settings {
    max_surge = "33%"
  }

  tags = var.tags
}

# ── ACR pull permission for AKS kubelet identity ──────────────────────────────
resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                = var.acr_id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
}

# ── Diagnostic settings → Log Analytics ──────────────────────────────────────
resource "azurerm_monitor_diagnostic_setting" "aks" {
  name                       = "diag-aks-${var.project}-${var.environment}"
  target_resource_id         = azurerm_kubernetes_cluster.main.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.aks.id

  enabled_log { category = "kube-apiserver" }
  enabled_log { category = "kube-controller-manager" }
  enabled_log { category = "kube-scheduler" }
  enabled_log { category = "kube-audit" }
  enabled_log { category = "kube-audit-admin" }
  enabled_log { category = "guard" }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}
