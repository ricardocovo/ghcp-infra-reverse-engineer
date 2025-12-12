# GitHub Actions Workflows

This directory contains CI/CD workflows for deploying and managing the Azure infrastructure defined in the `infra/` directory.

## Workflows

### 1. Terraform Deploy (`terraform-deploy.yml`)

Validates, plans, and deploys Terraform infrastructure to Azure.

**Triggers:**

- Push to `main` branch (when `infra/` files change)
- Pull requests to `main` branch (when `infra/` files change)
- Manual workflow dispatch

**Jobs:**

1. **terraform-validate**: Runs format check, validation
2. **terraform-plan**: Authenticates to Azure and generates plan
3. **terraform-apply**: Applies changes to Azure (only on `main` branch)

**Features:**

- Posts plan results as PR comments
- Uses GitHub Actions summary for visibility
- Stores plan artifacts for apply stage
- Only applies when there are changes (exit code 2)

### 2. Terraform Drift Detection (`terraform-drift.yml`)

Monitors infrastructure for configuration drift (changes made outside Terraform).

**Triggers:**

- Daily at 6 AM UTC (scheduled)
- Manual workflow dispatch

**Features:**

- Runs `terraform plan` to detect drift
- Creates GitHub issues when drift is detected
- Provides detailed drift report in issue

## Setup Instructions

### Prerequisites

1. **Azure Service Principal with OIDC Federation**

   Create a service principal and configure it for OIDC authentication with GitHub:

   ```bash
   # Create service principal
   az ad sp create-for-rbac --name "ghcp-infra-reverse-engineer-sp" \
     --role Contributor \
     --scopes /subscriptions/{subscription-id}/resourceGroups/rg-ghcsampleps-dev

   # Note the appId (client ID) and tenant from the output
   ```

   Then configure federated credentials in Azure Portal or via CLI:

   ```bash
   # For production environment
   az ad app federated-credential create \
     --id <application-object-id> \
     --parameters '{
       "name": "github-deploy",
       "issuer": "https://token.actions.githubusercontent.com",
       "subject": "repo:ricardocovo/ghcp-infra-reverse-engineer:environment:dev",
       "audiences": ["api://AzureADTokenExchange"]
     }'

   # For pull requests
   az ad app federated-credential create \
     --id <application-object-id> \
     --parameters '{
       "name": "github-pr",
       "issuer": "https://token.actions.githubusercontent.com",
       "subject": "repo:ricardocovo/ghcp-infra-reverse-engineer:pull_request",
       "audiences": ["api://AzureADTokenExchange"]
     }'

   # For main branch
   az ad app federated-credential create \
     --id <application-object-id> \
     --parameters '{
       "name": "github-main",
       "issuer": "https://token.actions.githubusercontent.com",
       "subject": "repo:ricardocovo/ghcp-infra-reverse-engineer:ref:refs/heads/main",
       "audiences": ["api://AzureADTokenExchange"]
     }'
   ```

2. **Create GitHub Environment**

   - Go to repository Settings → Environments
   - Create an environment named `dev`
   - (Optional) Add protection rules and required reviewers

3. **Configure GitHub Secrets**

   Add the following secrets to your repository (Settings → Secrets and variables → Actions):

   - `AZURE_CLIENT_ID`: The application (client) ID from the service principal
   - `AZURE_TENANT_ID`: Your Azure AD tenant ID
   - `AZURE_SUBSCRIPTION_ID`: Your Azure subscription ID
   - `SQL_ADMIN_PASSWORD`: Strong password for SQL Server admin

4. **Configure Terraform Backend** (Recommended)

   Update `infra/backend.tf` to use a remote backend:

   ```hcl
   terraform {
     backend "azurerm" {
       resource_group_name  = "rg-terraform-state"
       storage_account_name = "tfstateghcpinfra"
       container_name       = "tfstate"
       key                  = "ghcsampleps-dev.tfstate"
     }
   }
   ```

   Create the storage account:

   ```bash
   # Create resource group for Terraform state
   az group create --name rg-terraform-state --location canadacentral

   # Create storage account
   az storage account create \
     --name tfstateghcpinfra \
     --resource-group rg-terraform-state \
     --location canadacentral \
     --sku Standard_LRS \
     --encryption-services blob

   # Create container
   az storage container create \
     --name tfstate \
     --account-name tfstateghcpinfra
   ```

   Grant the service principal access to the storage account:

   ```bash
   az role assignment create \
     --assignee <service-principal-client-id> \
     --role "Storage Blob Data Contributor" \
     --scope /subscriptions/{subscription-id}/resourceGroups/rg-terraform-state/providers/Microsoft.Storage/storageAccounts/tfstateghcpinfra
   ```

## Workflow Execution

### Pull Request Workflow

1. Create a branch and make changes to `infra/` files
2. Open a pull request to `main`
3. Workflows automatically run:
   - Validation checks (format, validate)
   - Terraform plan (shows what will change)
4. Review the plan in PR comments
5. Merge when ready

### Deployment Workflow

1. Merge PR to `main` branch
2. Workflow runs automatically:
   - Validates configuration
   - Generates plan
   - Applies changes to Azure (if changes detected)
3. Check workflow summary for outputs

### Manual Deployment

Trigger workflow manually from Actions tab:

1. Go to Actions → Terraform Deploy
2. Click "Run workflow"
3. Select branch and run

## Monitoring and Maintenance

### Drift Detection

- Runs daily to detect manual changes
- Creates issues when drift found
- Review and resolve drift issues promptly

### Security Best Practices

- **Never commit secrets**: Use GitHub secrets and Azure Key Vault
- **OIDC instead of credentials**: No long-lived secrets in GitHub
- **Least privilege**: Service principal has minimal required permissions
- **Protected environments**: Use branch protection and required reviewers
- **State file security**: Backend encrypted and access-controlled

## Troubleshooting

### Authentication Failures

If you see OIDC authentication errors:

1. Verify federated credentials are configured correctly
2. Check that `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, and `AZURE_SUBSCRIPTION_ID` secrets are set
3. Ensure service principal has proper permissions
4. Verify the subject claim matches your repository and environment

### Terraform Init Failures

If backend initialization fails:

1. Verify storage account exists and is accessible
2. Check service principal has "Storage Blob Data Contributor" role
3. Ensure `backend.tf` configuration is correct

### Plan/Apply Failures

If plan or apply fails:

1. Check service principal has `Contributor` role on resource group
2. Verify all required variables are set (especially `SQL_ADMIN_PASSWORD`)
3. Review Terraform error messages in workflow logs
4. Ensure no manual changes conflict with Terraform state

## Additional Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Azure OIDC with GitHub Actions](https://learn.microsoft.com/en-us/azure/developer/github/connect-from-azure)
- [Terraform GitHub Actions](https://developer.hashicorp.com/terraform/tutorials/automation/github-actions)
- [Azure Verified Modules](https://aka.ms/avm)
