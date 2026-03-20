locals {
  common_tags = {
    project     = var.project
    environment = var.environment
    managed_by  = "terraform"
    repository  = "github.com/alilihic/k8s-azure-hardened"
  }
}
