locals {
  common_tags = {
    project     = var.project
    environment = var.environment
    managed_by  = "terraform"
    repository  = "github.com/alilihic/azure-infra-baseline"
  }
}
