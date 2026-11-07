# see https://registry.terraform.io/providers/Azure/azapi/latest/docs/data-sources/client_config
data "azapi_client_config" "current" {}

# see https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string
resource "random_string" "suffix" {
  length  = 4
  lower   = true
  numeric = true
  special = false
  upper   = false
}

locals {
  tenant_id = data.azapi_client_config.current.tenant_id
  suffix    = random_string.suffix.result

  names = {
    identity_resource_group = "rg-${var.name_prefix}-identity-${var.location}"
    resource_group          = "rg-${var.name_prefix}-${var.location}"
    registry                = "cr${var.name_prefix}${local.suffix}"
    foundry                 = "aif-${var.name_prefix}-${local.suffix}"
    cluster                 = "aks-${var.name_prefix}-${var.location}"
  }

  # see https://developer.hashicorp.com/terraform/language/block/stack/tfdeploy/identity_token
  stack_subjects = {
    for operation in ["plan", "apply"] : operation => join(":", [
      "organization", var.tfe_organization,
      "project", tfe_project.demo.name,
      "stack", var.tfe_stack,
      "deployment", var.tfe_stack_deployment,
      "operation", operation,
    ])
  }

  # see https://learn.microsoft.com/azure/role-based-access-control/built-in-roles
  roles = {
    acr_pull     = "7f951dda-4ed3-4680-a7ca-43fe172d538d"
    foundry_user = "53ca6127-db72-4b80-b1b0-d745d6d5456d"
  }

  # see https://learn.microsoft.com/azure/role-based-access-control/delegate-role-assignments-examples
  stack_delegation_condition = <<-EOT
    (
      (
        !(ActionMatches{'Microsoft.Authorization/roleAssignments/write'})
      )
      OR
      (
        @Request[Microsoft.Authorization/roleAssignments:RoleDefinitionId] ForAnyOfAnyValues:GuidEquals {${local.roles.acr_pull}, ${local.roles.foundry_user}}
      )
    )
    AND
    (
      (
        !(ActionMatches{'Microsoft.Authorization/roleAssignments/delete'})
      )
      OR
      (
        @Resource[Microsoft.Authorization/roleAssignments:RoleDefinitionId] ForAnyOfAnyValues:GuidEquals {${local.roles.acr_pull}, ${local.roles.foundry_user}}
      )
    )
  EOT
}

# see https://registry.terraform.io/modules/Azure/avm-res-resources-resourcegroup/azurerm/latest
module "identity_resource_group" {
  source  = "Azure/avm-res-resources-resourcegroup/azurerm"
  version = "0.5.0"

  name             = local.names.identity_resource_group
  location         = var.location
  enable_telemetry = false
  tags             = var.tags
}

# see https://registry.terraform.io/modules/Azure/avm-res-resources-resourcegroup/azurerm/latest
module "resource_group" {
  source  = "Azure/avm-res-resources-resourcegroup/azurerm"
  version = "0.5.0"

  name             = local.names.resource_group
  location         = var.location
  enable_telemetry = false
  tags             = var.tags

  role_assignments = {
    stack_contributor = {
      role_definition_id_or_name = "Contributor"
      principal_id               = module.stack_identity.principal_id
      principal_type             = "ServicePrincipal"
    }

    stack_cluster_admin = {
      role_definition_id_or_name = "Azure Kubernetes Service RBAC Cluster Admin"
      principal_id               = module.stack_identity.principal_id
      principal_type             = "ServicePrincipal"
    }

    stack_rbac_delegation = {
      role_definition_id_or_name = "Role Based Access Control Administrator"
      principal_id               = module.stack_identity.principal_id
      principal_type             = "ServicePrincipal"
      condition                  = local.stack_delegation_condition
      condition_version          = "2.0"
    }

    github_reader = {
      role_definition_id_or_name = "Reader"
      principal_id               = module.github_actions_identity.principal_id
      principal_type             = "ServicePrincipal"
    }

    github_push = {
      role_definition_id_or_name = "AcrPush"
      principal_id               = module.github_actions_identity.principal_id
      principal_type             = "ServicePrincipal"
    }
  }
}
