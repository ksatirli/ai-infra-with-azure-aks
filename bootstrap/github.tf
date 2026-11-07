# see https://registry.terraform.io/providers/integrations/github/latest/docs/resources/repository_environment
resource "github_repository_environment" "production" {
  repository  = var.github_repository
  environment = var.github_environment

  deployment_branch_policy {
    protected_branches     = false
    custom_branch_policies = true
  }
}

# see https://registry.terraform.io/providers/integrations/github/latest/docs/resources/repository_environment_deployment_policy
resource "github_repository_environment_deployment_policy" "main" {
  repository     = var.github_repository
  environment    = github_repository_environment.production.environment
  branch_pattern = var.github_branch
}

locals {
  github_environment_variables = {
    AZURE_CLIENT_ID       = module.github_actions_identity.client_id
    AZURE_TENANT_ID       = local.tenant_id
    AZURE_SUBSCRIPTION_ID = var.subscription_id
    ACR_NAME              = local.names.registry
    ACR_LOGIN_SERVER      = "${local.names.registry}.azurecr.io"
  }
}

# see https://registry.terraform.io/providers/integrations/github/latest/docs/resources/actions_environment_variable
resource "github_actions_environment_variable" "production" {
  for_each = local.github_environment_variables

  repository    = var.github_repository
  environment   = github_repository_environment.production.environment
  variable_name = each.key
  value         = each.value
}
