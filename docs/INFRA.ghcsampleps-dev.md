---
goal: Replicate existing rg-ghcsampleps-dev infrastructure using Terraform IaC
---

# Introduction

This implementation plan defines the Terraform Infrastructure as Code (IaC) approach to recreate the existing `rg-ghcsampleps-dev` Azure resource group infrastructure. The environment consists of a modern, cloud-native application stack with Container Apps, SQL Database, monitoring, storage, and security services deployed in Canada Central region.

## WAF Alignment

This implementation plan is designed for a **Production Application** workload with core Well-Architected Framework considerations.

### Cost Optimization Implications

- **Serverless SQL Database (GP_S_Gen5)** selected for automatic scaling and pay-per-use pricing model
- **Basic tier Container Registry** chosen for development workloads to minimize costs
- **Standard LRS storage** provides cost-effective local redundancy suitable for dev environment
- **Consumption-based Container Apps** enable scaling to zero when not in use
- **Serverless tier** for SQL Database with 2 vCores optimizes cost for variable workloads

### Reliability Implications

- **Log Analytics Workspace** provides centralized logging for troubleshooting and diagnostics
- **Application Insights** enables proactive monitoring and alerting
- **System-assigned managed identities** reduce credential management risk
- **Serverless SQL with auto-pause** ensures database availability when needed
- **Container Apps managed environment** provides automatic health monitoring and restarts

### Security Implications

- **Key Vault** for centralized secrets and certificate management with RBAC
- **System-assigned managed identities** on SQL Server and Container App eliminate credential storage
- **Private endpoints** should be considered for production (currently not implemented in dev)
- **Azure RBAC** for access control across all resources
- **Encryption at rest** enabled by default on all storage services

### Performance Implications

- **General Purpose Serverless SQL** (Gen5, 2 vCores) suitable for moderate workloads
- **Container Apps** with auto-scaling capabilities for variable load
- **Canada Central region** for low latency to primary users
- **Basic ACR tier** sufficient for dev, may need upgrade for production

### Operational Excellence Implications

- **Infrastructure as Code** via Terraform enables repeatable deployments
- **Centralized monitoring** through Log Analytics and Application Insights
- **Managed services** (Container Apps, SQL Database) reduce operational overhead
- **Action Groups** for automated alerting and incident response
- **Tagging strategy** (`environment: dev`) for resource organization and cost tracking

---

## Resources

### resourceGroup

```yaml
name: resourceGroup
kind: Raw
resource: azurerm_resource_group
provider: azurerm
version: ~> 4.0

purpose: Container for all infrastructure resources
dependsOn: []

variables:
  required:
    - name: name
      type: string
      description: Name of the resource group
      example: rg-ghcsampleps-dev
    - name: location
      type: string
      description: Azure region for deployment
      example: canadacentral

outputs:
  - name: id
    type: string
    description: Resource group ID
  - name: name
    type: string
    description: Resource group name
  - name: location
    type: string
    description: Resource group location

references:
  docs: https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/manage-resource-groups-portal
```

### logAnalyticsWorkspace

```yaml
name: logAnalyticsWorkspace
kind: AVM
avmModule: Azure/avm-res-operationalinsights-workspace/azurerm
version: 0.4.1

purpose: Centralized logging and analytics workspace for monitoring
dependsOn: [resourceGroup]

variables:
  required:
    - name: name
      type: string
      description: Name of the Log Analytics workspace
      example: ghcsampleps-dev-log
    - name: resource_group_name
      type: string
      description: Resource group name
      example: rg-ghcsampleps-dev
    - name: location
      type: string
      description: Azure region
      example: canadacentral
  optional:
    - name: sku
      type: string
      description: Pricing tier
      default: PerGB2018
    - name: retention_in_days
      type: number
      description: Data retention period
      default: 30
    - name: tags
      type: map(string)
      description: Resource tags
      default: { environment = "dev" }

outputs:
  - name: workspace_id
    type: string
    description: Workspace resource ID
  - name: workspace_customer_id
    type: string
    description: Workspace customer ID for agents

references:
  docs: https://learn.microsoft.com/en-us/azure/azure-monitor/logs/log-analytics-workspace-overview
  avm: https://registry.terraform.io/modules/Azure/avm-res-operationalinsights-workspace/azurerm/latest
```

### applicationInsights

```yaml
name: applicationInsights
kind: AVM
avmModule: Azure/avm-res-insights-component/azurerm
version: 0.1.3

purpose: Application performance monitoring and analytics
dependsOn: [resourceGroup, logAnalyticsWorkspace]

variables:
  required:
    - name: name
      type: string
      description: Name of Application Insights component
      example: ghcsampleps-dev-ai
    - name: resource_group_name
      type: string
      description: Resource group name
      example: rg-ghcsampleps-dev
    - name: location
      type: string
      description: Azure region
      example: canadacentral
    - name: workspace_id
      type: string
      description: Log Analytics workspace ID
      example: (reference from logAnalyticsWorkspace)
  optional:
    - name: application_type
      type: string
      description: Type of application
      default: web
    - name: tags
      type: map(string)
      description: Resource tags
      default: { environment = "dev" }

outputs:
  - name: id
    type: string
    description: Application Insights ID
  - name: instrumentation_key
    type: string
    description: Instrumentation key (sensitive)
  - name: connection_string
    type: string
    description: Connection string (sensitive)

references:
  docs: https://learn.microsoft.com/en-us/azure/azure-monitor/app/app-insights-overview
  avm: https://registry.terraform.io/modules/Azure/avm-res-insights-component/azurerm/latest
```

### containerRegistry

```yaml
name: containerRegistry
kind: AVM
avmModule: Azure/avm-res-containerregistry-registry/azurerm
version: 0.4.0

purpose: Store and manage container images for applications
dependsOn: [resourceGroup]

variables:
  required:
    - name: name
      type: string
      description: Globally unique ACR name
      example: ghcsamplepsdevacr
    - name: resource_group_name
      type: string
      description: Resource group name
      example: rg-ghcsampleps-dev
    - name: location
      type: string
      description: Azure region
      example: canadacentral
  optional:
    - name: sku
      type: string
      description: Service tier
      default: Basic
    - name: admin_enabled
      type: bool
      description: Enable admin user
      default: false
    - name: tags
      type: map(string)
      description: Resource tags
      default: { environment = "dev" }

outputs:
  - name: id
    type: string
    description: Container registry ID
  - name: login_server
    type: string
    description: Registry login server URL
  - name: admin_username
    type: string
    description: Admin username if enabled

references:
  docs: https://learn.microsoft.com/en-us/azure/container-registry/container-registry-intro
  avm: https://registry.terraform.io/modules/Azure/avm-res-containerregistry-registry/azurerm/latest
```

### keyVault

```yaml
name: keyVault
kind: AVM
avmModule: Azure/avm-res-keyvault-vault/azurerm
version: 0.9.1

purpose: Secure storage for secrets, keys, and certificates
dependsOn: [resourceGroup]

variables:
  required:
    - name: name
      type: string
      description: Globally unique Key Vault name
      example: ghcsamplepsdevkv
    - name: resource_group_name
      type: string
      description: Resource group name
      example: rg-ghcsampleps-dev
    - name: location
      type: string
      description: Azure region
      example: canadacentral
    - name: tenant_id
      type: string
      description: Azure AD tenant ID
      example: 66d8e3ac-39f0-4505-b4d8-2d91327ff764
  optional:
    - name: sku_name
      type: string
      description: Key Vault SKU
      default: standard
    - name: soft_delete_retention_days
      type: number
      description: Days to retain deleted vault
      default: 7
    - name: purge_protection_enabled
      type: bool
      description: Enable purge protection
      default: false
    - name: tags
      type: map(string)
      description: Resource tags
      default: { environment = "dev" }

outputs:
  - name: id
    type: string
    description: Key Vault resource ID
  - name: vault_uri
    type: string
    description: Vault URI
  - name: name
    type: string
    description: Key Vault name

references:
  docs: https://learn.microsoft.com/en-us/azure/key-vault/general/overview
  avm: https://registry.terraform.io/modules/Azure/avm-res-keyvault-vault/azurerm/latest
```

### storageAccount

```yaml
name: storageAccount
kind: AVM
avmModule: Azure/avm-res-storage-storageaccount/azurerm
version: 0.4.1

purpose: General-purpose storage for blobs, files, tables, and queues
dependsOn: [resourceGroup]

variables:
  required:
    - name: name
      type: string
      description: Globally unique storage account name
      example: ghcsamplepsdevst
    - name: resource_group_name
      type: string
      description: Resource group name
      example: rg-ghcsampleps-dev
    - name: location
      type: string
      description: Azure region
      example: canadacentral
  optional:
    - name: account_kind
      type: string
      description: Storage account kind
      default: StorageV2
    - name: account_tier
      type: string
      description: Performance tier
      default: Standard
    - name: account_replication_type
      type: string
      description: Replication strategy
      default: LRS
    - name: tags
      type: map(string)
      description: Resource tags
      default: { environment = "dev" }

outputs:
  - name: id
    type: string
    description: Storage account ID
  - name: name
    type: string
    description: Storage account name
  - name: primary_blob_endpoint
    type: string
    description: Primary blob endpoint

references:
  docs: https://learn.microsoft.com/en-us/azure/storage/common/storage-account-overview
  avm: https://registry.terraform.io/modules/Azure/avm-res-storage-storageaccount/azurerm/latest
```

### sqlServer

```yaml
name: sqlServer
kind: AVM
avmModule: Azure/avm-res-sql-server/azurerm
version: 0.9.1

purpose: Azure SQL Database server for application databases
dependsOn: [resourceGroup]

variables:
  required:
    - name: name
      type: string
      description: SQL Server name
      example: ghcsampleps-dev-sql
    - name: resource_group_name
      type: string
      description: Resource group name
      example: rg-ghcsampleps-dev
    - name: location
      type: string
      description: Azure region
      example: canadacentral
    - name: administrator_login
      type: string
      description: Admin username
      example: sqladmin
    - name: administrator_login_password
      type: string
      description: Admin password (from Key Vault)
      example: (sensitive)
  optional:
    - name: version
      type: string
      description: SQL Server version
      default: "12.0"
    - name: managed_identity_type
      type: string
      description: Managed identity type
      default: SystemAssigned
    - name: public_network_access_enabled
      type: bool
      description: Enable public access
      default: true
    - name: tags
      type: map(string)
      description: Resource tags
      default: { environment = "dev" }

outputs:
  - name: id
    type: string
    description: SQL Server ID
  - name: fqdn
    type: string
    description: Fully qualified domain name
  - name: identity_principal_id
    type: string
    description: Managed identity principal ID

references:
  docs: https://learn.microsoft.com/en-us/azure/azure-sql/database/sql-database-paas-overview
  avm: https://registry.terraform.io/modules/Azure/avm-res-sql-server/azurerm/latest
```

### sqlDatabase

```yaml
name: sqlDatabase
kind: Raw
resource: azurerm_mssql_database
provider: azurerm
version: ~> 4.0

purpose: Application database with serverless configuration
dependsOn: [sqlServer]

variables:
  required:
    - name: name
      type: string
      description: Database name
      example: ghcsamplepsdb
    - name: server_id
      type: string
      description: SQL Server ID
      example: (reference from sqlServer)
  optional:
    - name: sku_name
      type: string
      description: Database SKU
      default: GP_S_Gen5_2
    - name: min_capacity
      type: number
      description: Minimum vCores
      default: 0.5
    - name: max_size_gb
      type: number
      description: Maximum database size
      default: 32
    - name: auto_pause_delay_in_minutes
      type: number
      description: Auto-pause delay
      default: 60
    - name: tags
      type: map(string)
      description: Resource tags
      default: { environment = "dev" }

outputs:
  - name: id
    type: string
    description: Database ID
  - name: name
    type: string
    description: Database name

references:
  docs: https://learn.microsoft.com/en-us/azure/azure-sql/database/serverless-tier-overview
```

### containerAppEnvironment

```yaml
name: containerAppEnvironment
kind: AVM
avmModule: Azure/avm-res-app-managedenvironment/azurerm
version: 0.2.2

purpose: Managed environment for hosting Container Apps
dependsOn: [resourceGroup, logAnalyticsWorkspace]

variables:
  required:
    - name: name
      type: string
      description: Container App Environment name
      example: ghcsampleps-dev-cae
    - name: resource_group_name
      type: string
      description: Resource group name
      example: rg-ghcsampleps-dev
    - name: location
      type: string
      description: Azure region
      example: canadacentral
    - name: log_analytics_workspace_id
      type: string
      description: Log Analytics workspace ID
      example: (reference from logAnalyticsWorkspace)
  optional:
    - name: infrastructure_subnet_id
      type: string
      description: Subnet ID for infrastructure
      default: null
    - name: internal_load_balancer_enabled
      type: bool
      description: Enable internal load balancer
      default: false

outputs:
  - name: id
    type: string
    description: Container App Environment ID
  - name: default_domain
    type: string
    description: Default domain for apps
  - name: static_ip_address
    type: string
    description: Static IP address

references:
  docs: https://learn.microsoft.com/en-us/azure/container-apps/environment
  avm: https://registry.terraform.io/modules/Azure/avm-res-app-managedenvironment/azurerm/latest
```

### containerApp

```yaml
name: containerApp
kind: AVM
avmModule: Azure/avm-res-app-containerapp/azurerm
version: 0.2.0

purpose: Main containerized application
dependsOn: [resourceGroup, containerAppEnvironment, containerRegistry, applicationInsights, keyVault, sqlServer]

variables:
  required:
    - name: name
      type: string
      description: Container App name
      example: ghcsampleps-dev-app
    - name: resource_group_name
      type: string
      description: Resource group name
      example: rg-ghcsampleps-dev
    - name: location
      type: string
      description: Azure region
      example: canadacentral
    - name: container_app_environment_id
      type: string
      description: Container App Environment ID
      example: (reference from containerAppEnvironment)
  optional:
    - name: managed_identity_type
      type: string
      description: Managed identity type
      default: SystemAssigned
    - name: revision_mode
      type: string
      description: Revision mode
      default: Single
    - name: ingress_external_enabled
      type: bool
      description: Enable external ingress
      default: true
    - name: ingress_target_port
      type: number
      description: Container port
      default: 80

outputs:
  - name: id
    type: string
    description: Container App ID
  - name: fqdn
    type: string
    description: Fully qualified domain name
  - name: identity_principal_id
    type: string
    description: Managed identity principal ID
  - name: latest_revision_name
    type: string
    description: Latest revision name

references:
  docs: https://learn.microsoft.com/en-us/azure/container-apps/overview
  avm: https://registry.terraform.io/modules/Azure/avm-res-app-containerapp/azurerm/latest
```

### actionGroup

```yaml
name: actionGroup
kind: Raw
resource: azurerm_monitor_action_group
provider: azurerm
version: ~> 4.0

purpose: Action group for Application Insights Smart Detection alerts
dependsOn: [resourceGroup, applicationInsights]

variables:
  required:
    - name: name
      type: string
      description: Action group name
      example: Application Insights Smart Detection
    - name: resource_group_name
      type: string
      description: Resource group name
      example: rg-ghcsampleps-dev
    - name: short_name
      type: string
      description: Short name (max 12 chars)
      example: AI-SmartDet
  optional:
    - name: enabled
      type: bool
      description: Enable action group
      default: true

outputs:
  - name: id
    type: string
    description: Action group ID

references:
  docs: https://learn.microsoft.com/en-us/azure/azure-monitor/alerts/action-groups
```

---

# Implementation Plan

This plan recreates the existing `rg-ghcsampleps-dev` infrastructure using Terraform with Azure Verified Modules (AVMs) where available. The implementation is divided into five phases to manage dependencies and enable incremental validation.

## Phase 1 — Foundation Resources

**Objective:**

Establish the foundational infrastructure including resource group, monitoring, and security components that other resources depend on.

- IMPLEMENT-GOAL-001: Deploy core foundation resources (Resource Group, Log Analytics, Application Insights, Key Vault)

| Task | Description | Action |
|------|-------------|--------|
| TASK-001 | Create resource group | Define azurerm_resource_group resource |
| TASK-002 | Deploy Log Analytics Workspace | Use AVM module v0.4.1 with 30-day retention |
| TASK-003 | Deploy Application Insights | Use AVM module v0.1.3 linked to Log Analytics |
| TASK-004 | Deploy Key Vault | Use AVM module v0.9.1 with standard SKU |
| TASK-005 | Store SQL admin password in Key Vault | Create azurerm_key_vault_secret resource |
| TASK-006 | Configure RBAC for Key Vault | Grant access to deployment principal |
| TASK-007 | Apply environment tags | Tag all resources with environment=dev |
| TASK-008 | Validate foundation deployment | Run terraform plan and apply |

---

## Phase 2 — Data and Storage Layer

**Objective:**

Deploy data persistence and storage services including SQL Server, SQL Database, Storage Account, and Container Registry.

- IMPLEMENT-GOAL-002: Provision data and storage infrastructure

| Task | Description | Action |
|------|-------------|--------|
| TASK-009 | Deploy SQL Server | Use AVM module v0.9.1 with system-assigned identity |
| TASK-010 | Configure SQL Server firewall rules | Add Azure services and client IP rules |
| TASK-011 | Create SQL Database | Use azurerm_mssql_database with GP_S_Gen5_2 SKU |
| TASK-012 | Configure serverless settings | Set min_capacity=0.5, auto_pause_delay=60 |
| TASK-013 | Deploy Storage Account | Use AVM module v0.4.1 with StorageV2, Standard LRS |
| TASK-014 | Deploy Container Registry | Use AVM module v0.4.0 with Basic SKU |
| TASK-015 | Grant managed identity access | Allow SQL Server identity to access Key Vault |
| TASK-016 | Validate data layer deployment | Verify connectivity and authentication |

---

## Phase 3 — Container App Infrastructure

**Objective:**

Deploy the Container Apps managed environment and configure the runtime platform for containerized applications.

- IMPLEMENT-GOAL-003: Establish Container Apps hosting platform

| Task | Description | Action |
|------|-------------|--------|
| TASK-017 | Deploy Container App Environment | Use AVM module v0.2.2 linked to Log Analytics |
| TASK-018 | Configure environment settings | Set zone redundancy disabled for dev |
| TASK-019 | Wait for environment provisioning | Ensure environment is ready before app deployment |
| TASK-020 | Validate environment health | Check status and obtain default domain |

---

## Phase 4 — Application Deployment

**Objective:**

Deploy the containerized application with proper configuration, secrets management, and monitoring integration.

- IMPLEMENT-GOAL-004: Deploy and configure the Container App

| Task | Description | Action |
|------|-------------|--------|
| TASK-021 | Deploy Container App | Use AVM module v0.2.0 with system-assigned identity |
| TASK-022 | Configure container settings | Set image, ports, resources (CPU, memory) |
| TASK-023 | Add environment variables | Configure App Insights connection string |
| TASK-024 | Configure secrets from Key Vault | Use Key Vault references for SQL connection |
| TASK-025 | Grant Key Vault access | Allow Container App identity to read secrets |
| TASK-026 | Grant SQL access | Add Container App identity to SQL database |
| TASK-027 | Configure ingress | Enable external ingress on port 80/443 |
| TASK-028 | Configure scaling rules | Set min/max replicas for auto-scaling |
| TASK-029 | Deploy Action Group | Create monitor action group for alerts |
| TASK-030 | Link Smart Detection | Configure Application Insights alerts |
| TASK-031 | Validate application deployment | Test FQDN and monitor logs |
| TASK-032 | Verify end-to-end functionality | Test app connectivity to SQL and Key Vault |

---

## Phase 5 — Post-Deployment Configuration

**Objective:**

Apply additional configurations, enable monitoring, and document the deployment for operational handoff.

- IMPLEMENT-GOAL-005: Finalize configuration and enable operational monitoring

| Task | Description | Action |
|------|-------------|--------|
| TASK-033 | Configure diagnostic settings | Enable diagnostics on all resources to Log Analytics |
| TASK-034 | Set up custom dashboards | Create Azure Dashboard for monitoring |
| TASK-035 | Configure retention policies | Set blob lifecycle management on storage |
| TASK-036 | Document outputs | Export Terraform outputs (FQDN, IDs, endpoints) |
| TASK-037 | Create runbook documentation | Document operations and troubleshooting |
| TASK-038 | Tag resources for cost tracking | Ensure all resources tagged consistently |
| TASK-039 | Enable backup policies | Configure SQL backup retention if needed |
| TASK-040 | Final validation | Perform smoke tests and security review |

---

## Additional Considerations

### Terraform State Management

- **Backend Configuration**: Use Azure Storage Account with state locking via Blob Storage
- **State File Security**: Enable encryption at rest and restrict access via RBAC
- **Remote State**: Configure remote backend in `backend.tf`

### Security Enhancements for Production

- **Private Endpoints**: Consider adding private endpoints for SQL, Storage, Key Vault, and ACR
- **Network Security Groups**: Define NSG rules if deploying to VNet
- **Azure Policy**: Apply policies for compliance and governance
- **Conditional Access**: Implement conditional access for administrative access
- **Key Rotation**: Implement automated key and secret rotation

### CI/CD Integration

- **GitHub Actions / Azure DevOps**: Automate Terraform apply via pipeline
- **Environment Protection**: Use separate workspaces for dev/staging/prod
- **Approval Gates**: Require manual approval for production deployments
- **Drift Detection**: Schedule regular `terraform plan` to detect configuration drift

### Cost Management

- **Budget Alerts**: Configure Azure Cost Management budgets
- **Resource Tagging**: Use tags for cost allocation and chargeback
- **Auto-pause SQL**: Leverage serverless auto-pause (already configured)
- **Container Apps Scale-to-Zero**: Configure minimum replicas = 0 for dev

### Monitoring and Alerts

- **Application Insights Alerts**: CPU, memory, response time, failure rate
- **Log Analytics Queries**: Create custom queries for operational insights
- **Availability Tests**: Configure web tests for application endpoints
- **Smart Detection**: Leverage built-in anomaly detection

---

## Terraform Module Structure Recommendation

```
terraform/
├── main.tf                    # Main resource definitions
├── variables.tf               # Input variables
├── outputs.tf                 # Output values
├── providers.tf               # Provider configuration
├── backend.tf                 # Remote state backend
├── locals.tf                  # Local values and computed variables
├── versions.tf                # Terraform and provider versions
├── modules/
│   └── custom/                # Custom modules if needed
├── environments/
│   ├── dev.tfvars            # Development environment variables
│   ├── staging.tfvars        # Staging environment variables
│   └── prod.tfvars           # Production environment variables
└── README.md                  # Documentation
```

---

## Example Variable File (dev.tfvars)

```hcl
# Environment Configuration
environment         = "dev"
location            = "canadacentral"
resource_group_name = "rg-ghcsampleps-dev"

# Naming Convention
naming_prefix = "ghcsampleps"
naming_suffix = "dev"

# Log Analytics
log_analytics_retention_days = 30

# SQL Database
sql_admin_username           = "sqladmin"
sql_database_sku             = "GP_S_Gen5_2"
sql_database_max_size_gb     = 32
sql_auto_pause_delay_minutes = 60

# Storage Account
storage_account_replication = "LRS"
storage_account_tier        = "Standard"

# Container Registry
container_registry_sku = "Basic"

# Key Vault
key_vault_sku = "standard"

# Container App
container_app_cpu_requests    = "0.5"
container_app_memory_requests = "1Gi"
container_app_min_replicas    = 0
container_app_max_replicas    = 3

# Tags
common_tags = {
  environment = "dev"
  managed_by  = "terraform"
  project     = "ghcsampleps"
}
```

---

## Next Steps

1. **Create Terraform directory structure** as outlined above
2. **Initialize provider configuration** with Azure credentials
3. **Implement Phase 1** foundation resources
4. **Validate and test** each phase before proceeding
5. **Document any deviations** from the existing infrastructure
6. **Create CI/CD pipeline** for automated deployments
7. **Implement monitoring and alerting** post-deployment
8. **Conduct security review** before production promotion
