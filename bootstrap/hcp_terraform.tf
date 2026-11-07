# see https://registry.terraform.io/providers/hashicorp/tfe/latest/docs/resources/project
resource "tfe_project" "demo" {
  name         = var.tfe_project
  organization = var.tfe_organization
  description  = "Building AI infrastructure with AKS Automatic, Microsoft Foundry and Azure Verified Modules."
}

# see https://registry.terraform.io/providers/hashicorp/tfe/latest/docs/data-sources/github_app_installation
data "tfe_github_app_installation" "demo" {
  name = var.github_owner
}

# see https://registry.terraform.io/providers/hashicorp/tfe/latest/docs/resources/stack
resource "tfe_stack" "demo" {
  name                = var.tfe_stack
  project_id          = tfe_project.demo.id
  description         = "Foundry, AKS Automatic and the chat API for ${var.github_repository}."
  speculative_enabled = true

  trigger_patterns = [
    "*.tfcomponent.hcl",
    "*.tfdeploy.hcl",
    ".terraform.lock.hcl",
    ".terraform-version",
    "components/**",
    "app/VERSION",
  ]

  vcs_repo {
    identifier                 = "${var.github_owner}/${var.github_repository}"
    branch                     = var.github_branch
    github_app_installation_id = data.tfe_github_app_installation.demo.id
  }
}

locals {
  variable_set_name = "ai-infra-bootstrap"

  stack_inputs = {
    subscription_id   = var.subscription_id
    tenant_id         = local.tenant_id
    client_id         = module.stack_identity.client_id
    location          = var.location
    name_prefix       = var.name_prefix
    resource_group_id = module.resource_group.resource_id
    foundry_name      = local.names.foundry
    cluster_name      = local.names.cluster
    registry_name     = local.names.registry
  }
}

# see https://registry.terraform.io/providers/hashicorp/tfe/latest/docs/resources/variable_set
resource "tfe_variable_set" "bootstrap" {
  name         = local.variable_set_name
  description  = "Identifiers the ${var.tfe_stack} Stack reads, written by the bootstrap."
  organization = var.tfe_organization
  global       = false
}

# see https://registry.terraform.io/providers/hashicorp/tfe/latest/docs/resources/variable
resource "tfe_variable" "stack_input" {
  for_each = local.stack_inputs

  variable_set_id = tfe_variable_set.bootstrap.id
  category        = "terraform"
  key             = each.key
  value           = each.value
}

# see https://registry.terraform.io/providers/hashicorp/tfe/latest/docs/resources/stack_variable_set
resource "tfe_stack_variable_set" "bootstrap" {
  stack_id        = tfe_stack.demo.id
  variable_set_id = tfe_variable_set.bootstrap.id
}

# see https://developer.hashicorp.com/terraform/language/block/check
check "stack_subject_length" {
  assert {
    condition     = alltrue([for subject in values(local.stack_subjects) : length(subject) <= 127])
    error_message = "A Stack identity token subject exceeds 127 characters; shorten tfe_project, tfe_stack or tfe_stack_deployment."
  }
}
