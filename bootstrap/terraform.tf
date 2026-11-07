terraform {
  required_version = ">= 1.17.0, < 2.0.0"

  required_providers {
    # see https://registry.terraform.io/providers/Azure/azapi/latest/docs
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.13"
    }

    # see https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs
    azurerm = {
      source = "hashicorp/azurerm"
      # AVM currently excludes 5.x
      version = ">= 4.81.0, < 5.0.0"
    }

    # see https://registry.terraform.io/providers/integrations/github/latest/docs
    github = {
      source  = "integrations/github"
      version = "~> 6.13"
    }

    # see https://registry.terraform.io/providers/hashicorp/random/latest/docs
    random = {
      source  = "hashicorp/random"
      version = "~> 3.9"
    }

    # see https://registry.terraform.io/providers/hashicorp/tfe/latest/docs
    tfe = {
      source  = "hashicorp/tfe"
      version = "~> 0.83"
    }
  }
}
