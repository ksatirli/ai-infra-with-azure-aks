# see https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs
provider "azurerm" {
  features {}

  subscription_id = var.subscription_id

  resource_provider_registrations = "none"
  resource_providers_to_register  = var.azure_resource_providers
}

# see https://registry.terraform.io/providers/Azure/azapi/latest/docs
provider "azapi" {
  subscription_id = var.subscription_id
}

# see https://registry.terraform.io/providers/hashicorp/tfe/latest/docs
provider "tfe" {
  hostname     = var.tfe_hostname
  organization = var.tfe_organization
}

# see https://registry.terraform.io/providers/integrations/github/latest/docs
provider "github" {
  owner = var.github_owner
  token = var.github_token
}
