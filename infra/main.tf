# =============================================================================
# Phase 1 - Foundation Resources
# =============================================================================

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = local.resource_group_name
  location = var.location
  tags     = local.common_tags
}

# Log Analytics Workspace
module "log_analytics" {
  source  = "Azure/avm-res-operationalinsights-workspace/azurerm"
  version = "0.4.1"

  name                = local.log_analytics_name
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location

  log_analytics_workspace_retention_in_days = var.log_analytics_retention_days
  log_analytics_workspace_sku               = var.log_analytics_sku

  tags = local.common_tags
}

# Application Insights
module "application_insights" {
  source  = "Azure/avm-res-insights-component/azurerm"
  version = "0.1.3"

  name                = local.application_insights_name
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location

  application_type  = "web"
  workspace_id      = module.log_analytics.resource_id

  tags = local.common_tags
}

# Key Vault
module "key_vault" {
  source  = "Azure/avm-res-keyvault-vault/azurerm"
  version = "0.9.1"

  name                = local.key_vault_name
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  tenant_id           = var.tenant_id

  sku_name                        = var.key_vault_sku
  soft_delete_retention_days      = var.key_vault_soft_delete_retention_days
  purge_protection_enabled        = var.key_vault_purge_protection_enabled
  enabled_for_deployment          = true
  enabled_for_disk_encryption     = true
  enabled_for_template_deployment = true

  network_acls = {
    bypass         = "AzureServices"
    default_action = "Allow"
  }

  tags = local.common_tags
}

# Store SQL Admin Password in Key Vault
resource "azurerm_key_vault_secret" "sql_admin_password" {
  name         = "sql-admin-password"
  value        = var.sql_admin_password
  key_vault_id = module.key_vault.resource_id
}

# =============================================================================
# Phase 2 - Data and Storage Layer
# =============================================================================

# Storage Account
module "storage_account" {
  source  = "Azure/avm-res-storage-storageaccount/azurerm"
  version = "0.4.1"

  name                = local.storage_account_name
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location

  account_kind             = var.storage_account_kind
  account_tier             = var.storage_account_tier
  account_replication_type = var.storage_account_replication

  tags = local.common_tags
}

# Container Registry
module "container_registry" {
  source  = "Azure/avm-res-containerregistry-registry/azurerm"
  version = "0.4.0"

  name                = local.container_registry_name
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location

  sku           = var.container_registry_sku
  admin_enabled = var.container_registry_admin_enabled

  tags = local.common_tags
}

# SQL Server
module "sql_server" {
  source  = "Azure/avm-res-sql-server/azurerm"
  version = "0.9.1"

  name                = local.sql_server_name
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location

  administrator_login          = var.sql_admin_username
  administrator_login_password = var.sql_admin_password
  version                      = "12.0"

  managed_identities = {
    system_assigned = true
  }

  public_network_access_enabled = true

  # Allow Azure services to access the server
  firewall_rules = {
    allow_azure_services = {
      start_ip_address = "0.0.0.0"
      end_ip_address   = "0.0.0.0"
    }
  }

  tags = local.common_tags
}

# SQL Database
resource "azurerm_mssql_database" "main" {
  name      = local.sql_database_name
  server_id = module.sql_server.resource_id

  sku_name                    = var.sql_database_sku
  max_size_gb                 = var.sql_database_max_size_gb
  min_capacity                = var.sql_database_min_capacity
  auto_pause_delay_in_minutes = var.sql_auto_pause_delay_minutes

  tags = local.common_tags
}

# =============================================================================
# Phase 3 - Container App Infrastructure
# =============================================================================

# Container App Environment
module "container_app_environment" {
  source  = "Azure/avm-res-app-managedenvironment/azurerm"
  version = "0.2.2"

  name                = local.container_app_environment_name
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location

  log_analytics_workspace_customer_id  = module.log_analytics.workspace_id
  log_analytics_workspace_primary_key  = module.log_analytics.primary_shared_key

  infrastructure_subnet_id       = null
  internal_load_balancer_enabled = false

  tags = local.common_tags
}

# =============================================================================
# Phase 4 - Application Deployment
# =============================================================================

# Container App
module "container_app" {
  source  = "Azure/avm-res-app-containerapp/azurerm"
  version = "0.2.0"

  name                         = local.container_app_name
  resource_group_name          = azurerm_resource_group.main.name
  location                     = var.location
  container_app_environment_id = module.container_app_environment.resource_id

  managed_identities = {
    system_assigned = true
  }

  revision_mode = "Single"

  template = {
    containers = [
      {
        name   = "main"
        image  = var.container_app_image
        cpu    = var.container_app_cpu_requests
        memory = var.container_app_memory_requests

        env = [
          {
            name  = "APPLICATIONINSIGHTS_CONNECTION_STRING"
            value = module.application_insights.connection_string
          }
        ]
      }
    ]

    min_replicas = var.container_app_min_replicas
    max_replicas = var.container_app_max_replicas
  }

  ingress = {
    external_enabled = true
    target_port      = var.container_app_target_port
    transport        = "auto"
    traffic_weight = {
      latest_revision = true
      percentage      = 100
    }
  }

  tags = local.common_tags
}

# Action Group for Application Insights Smart Detection
resource "azurerm_monitor_action_group" "smart_detection" {
  name                = local.action_group_name
  resource_group_name = azurerm_resource_group.main.name
  short_name          = local.action_group_short_name
  enabled             = true

  tags = local.common_tags
}
