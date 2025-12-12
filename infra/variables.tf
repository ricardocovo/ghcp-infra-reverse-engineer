# Environment Configuration
variable "environment" {
  type        = string
  description = "Environment name (e.g., dev, staging, prod)"
  default     = "dev"
}

variable "location" {
  type        = string
  description = "Azure region for resource deployment"
  default     = "canadacentral"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
  default     = "rg-ghcsampleps-dev"
}

# Naming Convention
variable "naming_prefix" {
  type        = string
  description = "Prefix for resource names"
  default     = "ghcsampleps"
}

# Log Analytics
variable "log_analytics_retention_days" {
  type        = number
  description = "Log Analytics workspace data retention in days"
  default     = 30
}

variable "log_analytics_sku" {
  type        = string
  description = "Log Analytics workspace SKU"
  default     = "PerGB2018"
}

# SQL Database
variable "sql_admin_username" {
  type        = string
  description = "SQL Server administrator username"
  default     = "sqladmin"
}

variable "sql_admin_password" {
  type        = string
  description = "SQL Server administrator password"
  sensitive   = true
}

variable "sql_database_sku" {
  type        = string
  description = "SQL Database SKU name"
  default     = "GP_S_Gen5_2"
}

variable "sql_database_max_size_gb" {
  type        = number
  description = "Maximum database size in GB"
  default     = 32
}

variable "sql_database_min_capacity" {
  type        = number
  description = "Minimum vCores for serverless SQL"
  default     = 0.5
}

variable "sql_auto_pause_delay_minutes" {
  type        = number
  description = "Auto-pause delay in minutes for serverless SQL"
  default     = 60
}

# Storage Account
variable "storage_account_replication" {
  type        = string
  description = "Storage account replication type"
  default     = "LRS"
}

variable "storage_account_tier" {
  type        = string
  description = "Storage account tier"
  default     = "Standard"
}

variable "storage_account_kind" {
  type        = string
  description = "Storage account kind"
  default     = "StorageV2"
}

# Container Registry
variable "container_registry_sku" {
  type        = string
  description = "Container Registry SKU"
  default     = "Basic"
}

variable "container_registry_admin_enabled" {
  type        = bool
  description = "Enable admin user for Container Registry"
  default     = false
}

# Key Vault
variable "key_vault_sku" {
  type        = string
  description = "Key Vault SKU name"
  default     = "standard"
}

variable "key_vault_soft_delete_retention_days" {
  type        = number
  description = "Soft delete retention days for Key Vault"
  default     = 7
}

variable "key_vault_purge_protection_enabled" {
  type        = bool
  description = "Enable purge protection for Key Vault"
  default     = false
}

# Container App
variable "container_app_cpu_requests" {
  type        = string
  description = "CPU requests for container app"
  default     = "0.5"
}

variable "container_app_memory_requests" {
  type        = string
  description = "Memory requests for container app"
  default     = "1Gi"
}

variable "container_app_min_replicas" {
  type        = number
  description = "Minimum number of replicas"
  default     = 0
}

variable "container_app_max_replicas" {
  type        = number
  description = "Maximum number of replicas"
  default     = 3
}

variable "container_app_target_port" {
  type        = number
  description = "Container app target port"
  default     = 80
}

variable "container_app_image" {
  type        = string
  description = "Container image to deploy"
  default     = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
}

# Tags
variable "common_tags" {
  type        = map(string)
  description = "Common tags to apply to all resources"
  default = {
    environment = "dev"
    managed_by  = "terraform"
  }
}

# Tenant ID
variable "tenant_id" {
  type        = string
  description = "Azure AD tenant ID for Key Vault"
  default     = "66d8e3ac-39f0-4505-b4d8-2d91327ff764"
}
