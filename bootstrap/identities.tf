# see https://registry.terraform.io/modules/Azure/avm-res-managedidentity-userassignedidentity/azurerm/latest
module "stack_identity" {
  source  = "Azure/avm-res-managedidentity-userassignedidentity/azurerm"
  version = "0.6.0"

  name                = "id-${var.name_prefix}-stack"
  location            = var.location
  resource_group_name = module.identity_resource_group.name
  enable_telemetry    = false
  tags                = var.tags

  federated_identity_credentials = {
    for operation, subject in local.stack_subjects : operation => {
      name     = "hcp-terraform-${var.tfe_stack}-${var.tfe_stack_deployment}-${operation}"
      issuer   = "https://${var.tfe_hostname}"
      audience = ["api://AzureADTokenExchange"]
      subject  = subject
    }
  }
}

# GitHub issues immutable OIDC subjects that embed the owner and repository IDs
# (`repo:OWNER@ID/REPO@ID:...`), so the federated credential has to carry them.
# see https://registry.terraform.io/providers/integrations/github/latest/docs/data-sources/user
data "github_user" "owner" {
  username = var.github_owner
}

# see https://registry.terraform.io/providers/integrations/github/latest/docs/data-sources/repository
data "github_repository" "demo" {
  full_name = "${var.github_owner}/${var.github_repository}"
}

locals {
  github_subject = join(":", [
    "repo",
    "${var.github_owner}@${data.github_user.owner.id}/${var.github_repository}@${data.github_repository.demo.repo_id}",
    "environment",
    github_repository_environment.production.environment,
  ])
}

# see https://registry.terraform.io/modules/Azure/avm-res-managedidentity-userassignedidentity/azurerm/latest
module "github_actions_identity" {
  source  = "Azure/avm-res-managedidentity-userassignedidentity/azurerm"
  version = "0.6.0"

  name                = "id-${var.name_prefix}-github-actions"
  location            = var.location
  resource_group_name = module.identity_resource_group.name
  enable_telemetry    = false
  tags                = var.tags

  federated_identity_credentials = {
    environment = {
      name     = "github-${var.github_repository}-${var.github_environment}"
      issuer   = "https://token.actions.githubusercontent.com"
      audience = ["api://AzureADTokenExchange"]
      subject  = local.github_subject
    }
  }
}
