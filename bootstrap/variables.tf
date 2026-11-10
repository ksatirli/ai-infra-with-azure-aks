variable "subscription_id" {
  type        = string
  description = "Azure subscription for the demo (`az account show --query id -o tsv`)."
}

variable "github_token" {
  type        = string
  description = "GitHub CLI token (`gh auth token`). Ephemeral: never stored in state or plan files."
  ephemeral   = true
  sensitive   = true
}

variable "location" {
  type        = string
  description = "Azure region for all demo resources. West US 3 (Phoenix) is the closest region to Salt Lake City with availability zones."
  default     = "westus3"
}

variable "name_prefix" {
  type        = string
  description = "Short prefix used in every resource name."
  default     = "aiaks"

  validation {
    condition     = can(regex("^[a-z][a-z0-9]{2,7}$", var.name_prefix))
    error_message = "name_prefix must be 3-8 lowercase alphanumeric characters, starting with a letter."
  }
}

variable "tfe_hostname" {
  type        = string
  description = "HCP Terraform hostname, also the OIDC issuer for Stack identity tokens."
  default     = "app.terraform.io"
}

variable "tfe_organization" {
  type        = string
  description = "HCP Terraform organization."
  default     = "ksatirli"
}

variable "tfe_project" {
  type        = string
  description = "HCP Terraform project that holds the demo Stack."
  default     = "ai-infra-with-azure-aks"
}

variable "tfe_stack" {
  type        = string
  description = "Name of the HCP Terraform Stack."
  default     = "ai-infra"
}

variable "tfe_stack_deployment" {
  type        = string
  description = "Name of the Stack deployment."
  default     = "westus3"
}

variable "github_owner" {
  type        = string
  description = "GitHub user or organization that owns the demo repository."
  default     = "ksatirli"
}

variable "github_repository" {
  type        = string
  description = "Name of the demo repository."
  default     = "ai-infra-with-azure-aks"
}

variable "github_branch" {
  type        = string
  description = "Branch the Stack tracks."
  default     = "main"
}

variable "github_environment" {
  type        = string
  description = "GitHub Actions environment that is trusted to push images."
  default     = "production"
}

variable "azure_resource_providers" {
  type        = set(string)
  description = "Azure resource providers this demo depends on."
  default = [
    "Microsoft.CognitiveServices",
    "Microsoft.ContainerRegistry",
    "Microsoft.ContainerService",
    "Microsoft.ManagedIdentity",
    "Microsoft.Network",
  ]
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to Azure resources."
  default = {
    project = "ai-infra-with-azure-aks"
    managed = "terraform"
  }
}
