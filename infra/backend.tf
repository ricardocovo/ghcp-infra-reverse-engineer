# Backend configuration for Terraform state management
# Configure this with your Azure Storage Account details
# Example:
# terraform {
#   backend "azurerm" {
#     resource_group_name  = "rg-terraform-state"
#     storage_account_name = "tfstatestorage"
#     container_name       = "tfstate"
#     key                  = "ghcsampleps-dev.tfstate"
#   }
# }
#
# Or use local backend for development:
# terraform {
#   backend "local" {
#     path = "terraform.tfstate"
#   }
# }
