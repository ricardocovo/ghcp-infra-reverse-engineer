# Azure Infrastructure - ghcsampleps-dev

This directory contains the Terraform Infrastructure as Code (IaC) for the `rg-ghcsampleps-dev` Azure resource group.

## Architecture Overview

This implementation creates a modern, cloud-native application stack in Azure Canada Central region:

- **Monitoring**: Log Analytics Workspace and Application Insights
- **Security**: Azure Key Vault for secrets management
- **Storage**: Storage Account (Standard LRS) and Container Registry (Basic)
- **Database**: Azure SQL Database (Serverless GP_S_Gen5_2)
- **Compute**: Azure Container Apps with managed environment
- **Alerting**: Action Group for Application Insights Smart Detection

## Prerequisites

- [Terraform](https://www.terraform.io/downloads) ~> 1.9
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- Azure subscription with appropriate permissions
- Azure CLI authenticated: `az login`

## Environment Variables

Set the following environment variables before running Terraform:

```powershell
# Required
$env:ARM_SUBSCRIPTION_ID = "your-subscription-id"

# Optional - for service principal authentication
$env:ARM_CLIENT_ID = "your-client-id"
$env:ARM_CLIENT_SECRET = "your-client-secret"
$env:ARM_TENANT_ID = "your-tenant-id"
```

## Quick Start

1. **Initialize Terraform**:
   ```powershell
   cd infra
   terraform init
   ```

2. **Review the plan**:
   ```powershell
   terraform plan -var-file="dev.tfvars"
   ```

3. **Apply the configuration**:
   ```powershell
   terraform apply -var-file="dev.tfvars"
   ```

## Configuration Files

- **`versions.tf`**: Terraform and provider version constraints
- **`providers.tf`**: Azure provider configuration
- **`backend.tf`**: State backend configuration (commented out by default)
- **`variables.tf`**: Input variable definitions
- **`locals.tf`**: Local values and naming conventions
- **`main.tf`**: Main resource definitions
- **`outputs.tf`**: Output values
- **`dev.tfvars`**: Development environment variable values

## Customization

### Update Variable Values

Edit `dev.tfvars` to customize your deployment:

```hcl
sql_admin_password = "YourSecurePassword123!"
container_app_image = "your-registry.azurecr.io/your-app:latest"
```

### Configure State Backend

Uncomment and configure the backend in `backend.tf`:

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "tfstatestorage"
    container_name       = "tfstate"
    key                  = "ghcsampleps-dev.tfstate"
  }
}
```

## Security Considerations

- **SQL Password**: Use a strong password and consider using environment variables:
  ```powershell
  $env:TF_VAR_sql_admin_password = "YourSecurePassword"
  ```
- **Key Vault**: Stores SQL admin password securely
- **Managed Identities**: System-assigned identities for SQL Server and Container App
- **Network Access**: Public access enabled for dev; consider private endpoints for production

## Outputs

After deployment, Terraform outputs important values:

```powershell
terraform output container_app_fqdn
terraform output sql_server_fqdn
terraform output key_vault_uri
```

## Resource Naming Convention

Resources follow the naming pattern: `{prefix}-{environment}-{resource-type}`

Example:
- Resource Group: `rg-ghcsampleps-dev`
- Log Analytics: `ghcsampleps-dev-log`
- SQL Server: `ghcsampleps-dev-sql`
- Container App: `ghcsampleps-dev-app`

## Deployment Phases

The infrastructure is organized into logical phases:

1. **Phase 1 - Foundation**: Resource Group, Log Analytics, Application Insights, Key Vault
2. **Phase 2 - Data & Storage**: SQL Server, SQL Database, Storage Account, Container Registry
3. **Phase 3 - Container Platform**: Container App Environment
4. **Phase 4 - Application**: Container App, Action Group

## Cost Optimization

- **Serverless SQL**: Auto-pauses after 60 minutes of inactivity
- **Container Apps**: Scales to zero when not in use (min_replicas = 0)
- **Basic ACR**: Suitable for dev workloads
- **Standard LRS Storage**: Cost-effective for development

## Monitoring

- **Log Analytics**: 30-day retention for logs and metrics
- **Application Insights**: Application performance monitoring
- **Action Group**: Smart detection alerts configured

## Clean Up

To destroy all resources:

```powershell
terraform destroy -var-file="dev.tfvars"
```

## Troubleshooting

### Common Issues

1. **Key Vault name conflict**: Key Vault names must be globally unique
   - Solution: Update `naming_prefix` in `dev.tfvars`

2. **Storage account name conflict**: Storage account names must be globally unique
   - Solution: Update `naming_prefix` in `dev.tfvars`

3. **Authentication errors**: Ensure Azure CLI is authenticated
   - Solution: Run `az login` and set `ARM_SUBSCRIPTION_ID`

## Next Steps

1. Update `container_app_image` to your application image
2. Configure backend for remote state
3. Set up CI/CD pipeline for automated deployments
4. Review and adjust scaling parameters
5. Enable private endpoints for production

## Support

For issues or questions, refer to:
- [Terraform Azure Provider Documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure Verified Modules](https://aka.ms/avm)
- [INFRA Plan](../docs/INFRA.ghcsampleps-dev.md)
