output "cluster_id" {
  description = "Resource ID of the AKS Automatic cluster."
  value       = module.aks.resource_id
}

output "host" {
  description = "API server URL; configures the Stack's kubernetes provider."
  value       = "https://${module.aks.fqdn}"
}

output "cluster_ca_certificate" {
  description = "PEM-encoded cluster CA certificate (public)."
  value = try(
    base64decode(yamldecode(base64decode(data.azapi_resource_action.kubeconfig.output.kubeconfigs[0].value)).clusters[0].cluster["certificate-authority-data"]),
    null
  )
}

output "oidc_issuer_url" {
  description = "OIDC issuer that workload identity federated credentials trust."
  value       = module.aks.oidc_issuer_profile_issuer_url
}

output "registry_login_server" {
  description = "Login server of the Azure Container Registry."
  value       = "${module.container_registry.name}.azurecr.io"
}

output "registry_id" {
  description = "Resource ID of the Azure Container Registry."
  value       = module.container_registry.resource_id
}
