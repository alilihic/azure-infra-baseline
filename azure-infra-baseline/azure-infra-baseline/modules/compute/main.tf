resource "azurerm_network_interface" "main" {
  name                = "nic-${var.project}-${var.environment}-${var.location_short}-001"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
  }

  tags = var.tags
}

resource "azurerm_linux_virtual_machine" "main" {
  name                = "vm-${var.project}-${var.environment}-${var.location_short}-001"
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = var.vm_size
  admin_username      = var.admin_username

  # SSH key auth only — no password
  disable_password_authentication = true

  network_interface_ids = [azurerm_network_interface.main.id]

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }

  os_disk {
    name                 = "osdisk-${var.project}-${var.environment}-001"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = 64

    # Encrypt OS disk with platform-managed key
    disk_encryption_set_id = null
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  # System-assigned managed identity — use for Key Vault access without secrets
  identity {
    type = "SystemAssigned"
  }

  # Boot diagnostics — useful for troubleshooting
  boot_diagnostics {}

  # Cloud-init: harden SSH, install useful tooling
  custom_data = base64encode(local.cloud_init)

  tags = var.tags
}

# ── Managed Identity: grant VM read access to Key Vault secrets ───────────────
resource "azurerm_role_assignment" "vm_kv_reader" {
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_linux_virtual_machine.main.identity[0].principal_id
}

locals {
  cloud_init = <<-EOF
    #cloud-config
    package_update: true
    package_upgrade: true
    packages:
      - curl
      - git
      - unzip
      - jq
      - htop
      - ufw

    runcmd:
      # Install Azure CLI
      - curl -sL https://aka.ms/InstallAzureCLIDeb | bash

      # Install Terraform
      - curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
      - echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" > /etc/apt/sources.list.d/hashicorp.list
      - apt-get update && apt-get install -y terraform

      # Harden SSH
      - sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
      - sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
      - systemctl restart sshd

      # Enable and configure UFW
      - ufw default deny incoming
      - ufw default allow outgoing
      - ufw allow 22/tcp
      - ufw --force enable

    final_message: "VM provisioned and hardened by cloud-init."
  EOF
}
