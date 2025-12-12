locals {
  # Naming convention
  resource_prefix = "${var.naming_prefix}-${var.environment}"

  # Common tags applied to all resources
  common_tags = merge(
    var.common_tags,
    {
      environment = var.environment
      managed_by  = "terraform"
      project     = var.naming_prefix
    }
  )

  # Resource names
  resource_group_name          = var.resource_group_name
  log_analytics_name           = "${local.resource_prefix}-log"
  application_insights_name    = "${local.resource_prefix}-ai"
  key_vault_name               = "${var.naming_prefix}${var.environment}kv"
  storage_account_name         = "${var.naming_prefix}${var.environment}st"
  container_registry_name      = "${var.naming_prefix}${var.environment}acr"
  sql_server_name              = "${local.resource_prefix}-sql"
  sql_database_name            = "${var.naming_prefix}db"
  container_app_environment_name = "${local.resource_prefix}-cae"
  container_app_name           = "${local.resource_prefix}-app"
  action_group_name            = "Application Insights Smart Detection"
  action_group_short_name      = "AI-SmartDet"
}
