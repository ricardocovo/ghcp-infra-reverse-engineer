# ghcp-infra-reverse-engineer

[![Terraform Deploy](https://github.com/ricardocovo/ghcp-infra-reverse-engineer/actions/workflows/terraform-deploy.yml/badge.svg)](https://github.com/ricardocovo/ghcp-infra-reverse-engineer/actions/workflows/terraform-deploy.yml)
[![Terraform Drift Detection](https://github.com/ricardocovo/ghcp-infra-reverse-engineer/actions/workflows/terraform-drift.yml/badge.svg)](https://github.com/ricardocovo/ghcp-infra-reverse-engineer/actions/workflows/terraform-drift.yml)

Reverse-engineers an existing Azure Resource Group into a Terraform implementation (using Azure Verified Modules where available), so you can recreate the environment deterministically.

This repo currently targets the `rg-ghcsampleps-dev` environment in Canada Central and produces implementation assets under `./infra`.

## Technology Stack

- **Terraform**: `~> 1.9` (see `infra/versions.tf`)
- **AzureRM Provider**: `~> 4.0` (see `infra/versions.tf`)
- **Azure Verified Modules (AVM)**: Terraform modules from the `Azure/avm-*` registry namespace
- **Azure CLI**: used for authentication (`az login`)
- **PowerShell**: examples and local workflows are Windows/PowerShell-friendly

## Project Architecture

The target environment is a small, cloud-native stack:

- Monitoring: Log Analytics + Application Insights
- Security: Key Vault
- Data: Azure SQL Server + serverless SQL Database
- Storage/Artifacts: Storage Account + Container Registry
- Compute: Container Apps Managed Environment + Container App
- Alerting: Action Group for App Insights Smart Detection

Mermaid overview:

```mermaid
flowchart LR

  subgraph RG[Azure Resource Group: rg-ghcsampleps-dev]
    LA[Log Analytics Workspace]
    AI[Application Insights]
    KV[Key Vault]
    ACR[Container Registry]
    ST[Storage Account]
    SQLS[SQL Server]
    SQLDB[SQL Database (Serverless)]
    CAE[Container Apps Environment]
    CA[Container App]
    AG[Monitor Action Group]
  end

  AI --> LA
  CAE --> LA
  CA --> CAE
  CA --> AI
  SQLDB --> SQLS
  SQLS --> KV
```

Primary source docs:

- Implementation plan: `docs/INFRA.ghcsampleps-dev.md`
- Existing resource inventory: `docs/rg-ghcsampleps-dev-resources.md`

## Getting Started

### Prerequisites

- Terraform installed
  - Example (Windows): `winget install HashiCorp.Terraform`
- Azure CLI installed and authenticated: `az login`
- An Azure subscription where you have permissions to create the target resources

### Configure authentication

Terraform uses standard AzureRM environment variables.

PowerShell example:

```powershell
$env:ARM_SUBSCRIPTION_ID = "<your-subscription-id>"

# Optional (Service Principal)
$env:ARM_TENANT_ID       = "<tenant-id>"
$env:ARM_CLIENT_ID       = "<app-id>"
$env:ARM_CLIENT_SECRET   = "<secret>"
```

### Deploy the infrastructure

1. Go to the implementation folder:

   ```powershell
   cd infra
   ```

2. Set required inputs (at minimum, SQL password):

   - Option A: edit `infra/dev.tfvars` and replace `REPLACE_WITH_SECURE_PASSWORD`
   - Option B: set an env var so it’s not stored in a file:

     ```powershell
     $env:TF_VAR_sql_admin_password = "<your-strong-password>"
     ```

3. Initialize and apply:

   ```powershell
   terraform init
   terraform plan  -var-file="dev.tfvars"
   terraform apply -var-file="dev.tfvars"
   ```

### CI/CD deployment (GitHub Actions)

This repo includes GitHub Actions workflows that run `terraform fmt`, `terraform validate`, `terraform plan` (PRs), and `terraform apply` (on `main`) using Azure OIDC.

- Workflows: `.github/workflows/terraform-deploy.yml` and `.github/workflows/terraform-drift.yml`
- Setup guide: `.github/workflows/README.md` (secrets, OIDC federated credential, optional remote state backend)

### State backend

`infra/backend.tf` contains a ready-to-fill template for an `azurerm` remote backend. Configure it before team use.

## Project Structure

High-level layout:

```text
.
├── README.md
├── docs/
│   ├── INFRA.ghcsampleps-dev.md
│   └── rg-ghcsampleps-dev-resources.md
└── infra/
    ├── main.tf
    ├── variables.tf
    ├── outputs.tf
    ├── providers.tf
    ├── versions.tf
    ├── locals.tf
    ├── backend.tf
    └── dev.tfvars
```

## Key Features

- Translates an existing Azure resource group into Terraform IaC
- Uses Azure Verified Modules (AVM) where available for consistency and maintainability
- Captures a phased implementation approach aligned to the Well-Architected Framework themes in the plan
- Provides a ready-to-run Terraform root module under `infra/`

## Coding Standards

The repo follows Azure/Terraform guidance captured in `.github/instructions/terraform-azure.instructions.md`, including:

- Prefer AVM modules for “significant” Azure resources
- Avoid hardcoding environment-specific values; parameterize via variables and `*.tfvars`
- Do not commit secrets (avoid secrets in code/state; prefer Key Vault and env vars)
- Keep Terraform code organized (`main.tf`, `variables.tf`, `outputs.tf`, `locals.tf`) and run `terraform fmt`

## Testing

There are no unit tests in this repo today.

Recommended validation workflow:

```powershell
cd infra
terraform fmt -recursive
terraform validate
```

Optionally add linters such as `tflint` if you want policy/lint coverage.

## Contributing

- Keep changes focused and deterministic.
- Prefer AVM modules over raw resources when possible.
- Do not introduce secrets into committed files; use environment variables and Key Vault.

Helpful references:

- Instructions: `.github/instructions/terraform-azure.instructions.md`
- Agents (planning/implementation): `.github/agents/`
- Environment plan and inventory: `docs/`

## License

No license file is currently included in this repository.
