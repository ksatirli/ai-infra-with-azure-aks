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
      subject  = "repo:${var.github_owner}/${var.github_repository}:environment:${github_repository_environment.production.environment}"
    }
  }
}
