output "resource_group_id" {
  description = "Resource group that holds every Stack resource."
  value       = module.resource_group.resource_id
}

output "container_registry" {
  description = "Login server of the Azure Container Registry (created by the Stack)."
  value       = "${local.names.registry}.azurecr.io"
}

output "stack_identity" {
  description = "Client ID of the managed identity the Stack runs as."
  value       = module.stack_identity.client_id
}

output "stack_subjects" {
  description = "Identity token subjects the Stack identity trusts."
  value       = local.stack_subjects
}

output "github_actions_identity" {
  description = "Client ID of the managed identity that GitHub Actions assumes."
  value       = module.github_actions_identity.client_id
}

output "stack" {
  description = "ID of the HCP Terraform Stack."
  value       = tfe_stack.demo.id
}
