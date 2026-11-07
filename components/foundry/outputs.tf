output "foundry_id" {
  description = "Resource ID of the Foundry account."
  value       = module.ai_foundry.ai_foundry_id
}

output "foundry_name" {
  description = "Name of the Foundry account."
  value       = module.ai_foundry.ai_foundry_name
}

output "inference_base_url" {
  description = "OpenAI-compatible (v1) base URL of the Foundry account."
  value       = "https://${module.ai_foundry.ai_foundry_name}.services.ai.azure.com/openai/v1/"
}

output "model_deployment_name" {
  description = "Name of the Granite managed compute deployment; used as the model field."
  value       = azapi_resource.granite.name
}

output "model_routes" {
  description = "Scoring routes Foundry reports for the deployment."
  value       = try(azapi_resource.granite.output.properties.routes, null)
}

output "project_id" {
  description = "Resource ID of the Foundry project."
  value       = module.ai_foundry.ai_foundry_project_id
}
