# Resource Group
output "resource_group_id" {
  description = "Resource group ID"
  value       = azurerm_resource_group.main.id
}

output "resource_group_name" {
  description = "Resource group name"
  value       = azurerm_resource_group.main.name
}

# Log Analytics Workspace
output "log_analytics_workspace_id" {
  description = "Log Analytics workspace resource ID"
  value       = module.log_analytics.resource_id
}

output "log_analytics_workspace_customer_id" {
  description = "Log Analytics workspace customer ID"
  value       = module.log_analytics.workspace_id
}

# Application Insights
output "application_insights_id" {
  description = "Application Insights resource ID"
  value       = module.application_insights.resource_id
}

output "application_insights_connection_string" {
  description = "Application Insights connection string"
  value       = module.application_insights.connection_string
  sensitive   = true
}

output "application_insights_instrumentation_key" {
  description = "Application Insights instrumentation key"
  value       = module.application_insights.instrumentation_key
  sensitive   = true
}

# Key Vault
output "key_vault_id" {
  description = "Key Vault resource ID"
  value       = module.key_vault.resource_id
}

output "key_vault_uri" {
  description = "Key Vault URI"
  value       = module.key_vault.resource_uri
}

output "key_vault_name" {
  description = "Key Vault name"
  value       = module.key_vault.resource_name
}

# Storage Account
output "storage_account_id" {
  description = "Storage account resource ID"
  value       = module.storage_account.resource_id
}

output "storage_account_name" {
  description = "Storage account name"
  value       = module.storage_account.name
}

output "storage_account_primary_blob_endpoint" {
  description = "Primary blob endpoint"
  value       = module.storage_account.primary_blob_endpoint
}

# Container Registry
output "container_registry_id" {
  description = "Container Registry resource ID"
  value       = module.container_registry.resource_id
}

output "container_registry_login_server" {
  description = "Container Registry login server"
  value       = module.container_registry.login_server
}

# SQL Server
output "sql_server_id" {
  description = "SQL Server resource ID"
  value       = module.sql_server.resource_id
}

output "sql_server_fqdn" {
  description = "SQL Server fully qualified domain name"
  value       = module.sql_server.fully_qualified_domain_name
}

output "sql_server_identity_principal_id" {
  description = "SQL Server managed identity principal ID"
  value       = module.sql_server.identity_principal_id
}

# SQL Database
output "sql_database_id" {
  description = "SQL Database resource ID"
  value       = azurerm_mssql_database.main.id
}

output "sql_database_name" {
  description = "SQL Database name"
  value       = azurerm_mssql_database.main.name
}

# Container App Environment
output "container_app_environment_id" {
  description = "Container App Environment resource ID"
  value       = module.container_app_environment.resource_id
}

output "container_app_environment_default_domain" {
  description = "Container App Environment default domain"
  value       = module.container_app_environment.default_domain
}

output "container_app_environment_static_ip" {
  description = "Container App Environment static IP address"
  value       = module.container_app_environment.static_ip_address
}

# Container App
output "container_app_id" {
  description = "Container App resource ID"
  value       = module.container_app.resource_id
}

output "container_app_fqdn" {
  description = "Container App fully qualified domain name"
  value       = module.container_app.fqdn
}

output "container_app_identity_principal_id" {
  description = "Container App managed identity principal ID"
  value       = module.container_app.identity_principal_id
}

output "container_app_latest_revision_name" {
  description = "Container App latest revision name"
  value       = module.container_app.latest_revision_name
}

# Action Group
output "action_group_id" {
  description = "Action Group resource ID"
  value       = azurerm_monitor_action_group.smart_detection.id
}
