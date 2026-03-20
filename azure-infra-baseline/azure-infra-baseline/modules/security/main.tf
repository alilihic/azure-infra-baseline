resource "azurerm_network_security_group" "workload" {
  name                = "nsg-workload-${var.project}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name

  # ── Inbound rules ──────────────────────────────────────────────────────────

  # Allow SSH from Bastion subnet only (preferred over direct SSH)
  security_rule {
    name                       = "Allow-SSH-From-Bastion"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefixes    = var.allowed_ssh_cidrs
    destination_address_prefix = "*"
  }

  # Allow inbound from VNet (internal traffic)
  security_rule {
    name                       = "Allow-VNet-Inbound"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }

  # Allow Azure Load Balancer probes
  security_rule {
    name                       = "Allow-AzureLoadBalancer"
    priority                   = 300
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "*"
  }

  # Deny all other inbound
  security_rule {
    name                       = "Deny-All-Inbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # ── Outbound rules ─────────────────────────────────────────────────────────

  # Allow HTTPS outbound (package managers, Azure APIs)
  security_rule {
    name                       = "Allow-HTTPS-Outbound"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "Internet"
  }

  # Allow HTTP outbound (package managers)
  security_rule {
    name                       = "Allow-HTTP-Outbound"
    priority                   = 110
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "Internet"
  }

  # Allow DNS
  security_rule {
    name                       = "Allow-DNS-Outbound"
    priority                   = 120
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_range     = "53"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = var.tags
}

# ── NSG Association ───────────────────────────────────────────────────────────
resource "azurerm_subnet_network_security_group_association" "workload" {
  subnet_id                 = var.subnet_id
  network_security_group_id = azurerm_network_security_group.workload.id
}

# ── Azure Bastion ─────────────────────────────────────────────────────────────
resource "azurerm_public_ip" "bastion" {
  name                = "pip-bastion-${var.project}-${var.environment}-${var.location_short}"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]

  tags = var.tags
}

resource "azurerm_bastion_host" "main" {
  name                = "bas-${var.project}-${var.environment}-${var.location_short}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Basic"

  ip_configuration {
    name                 = "configuration"
    subnet_id            = var.bastion_subnet_id
    public_ip_address_id = azurerm_public_ip.bastion.id
  }

  tags = var.tags
}
