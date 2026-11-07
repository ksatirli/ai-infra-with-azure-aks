locals {
  resource_group_name = provider::azapi::parse_resource_id("Microsoft.Resources/resourceGroups", var.resource_group_id).name
}

# see https://registry.terraform.io/modules/Azure/avm-res-containerservice-managedcluster/azurerm/latest
module "aks" {
  source  = "Azure/avm-res-containerservice-managedcluster/azurerm"
  version = "0.9.0"

  name             = var.cluster_name
  location         = var.location
  parent_id        = var.resource_group_id
  enable_telemetry = false

  sku = {
    name = "Automatic"
    tier = "Standard"
  }

  oidc_issuer_profile = {
    enabled = true
  }

  security_profile = {
    workload_identity = {
      enabled = true
    }
  }
}

# see https://registry.terraform.io/providers/Azure/azapi/latest/docs/data-sources/resource_action
data "azapi_resource_action" "kubeconfig" {
  type                   = "Microsoft.ContainerService/managedClusters@2026-03-01"
  resource_id            = module.aks.resource_id
  action                 = "listClusterUserCredential"
  method                 = "POST"
  response_export_values = ["kubeconfigs"]
}

# see https://registry.terraform.io/modules/Azure/avm-res-containerregistry-registry/azurerm/latest
module "container_registry" {
  source  = "Azure/avm-res-containerregistry-registry/azurerm"
  version = "0.9.0"

  name                = var.registry_name
  location            = var.location
  resource_group_name = local.resource_group_name
  enable_telemetry    = false

  admin_enabled          = false
  anonymous_pull_enabled = false

  role_assignments = {
    kubelet_pull = {
      role_definition_id_or_name = "AcrPull"
      principal_id               = module.aks.kubelet_identity.objectId
      principal_type             = "ServicePrincipal"
    }
  }
}
