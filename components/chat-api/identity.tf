# see https://registry.terraform.io/modules/Azure/avm-res-managedidentity-userassignedidentity/azurerm/latest
module "chat_api_identity" {
  source  = "Azure/avm-res-managedidentity-userassignedidentity/azurerm"
  version = "0.6.0"

  name                = "id-${var.cluster_name}-${local.app_name}"
  location            = var.location
  resource_group_name = local.resource_group_name
  enable_telemetry    = false

  federated_identity_credentials = {
    service_account = {
      name     = "${var.namespace}-${local.sa_name}"
      issuer   = var.oidc_issuer_url
      audience = ["api://AzureADTokenExchange"]
      subject  = "system:serviceaccount:${var.namespace}:${local.sa_name}"
    }
  }
}

# see https://learn.microsoft.com/azure/foundry/concepts/rbac-foundry
resource "azurerm_role_assignment" "chat_api_foundry" {
  scope              = var.foundry_id
  role_definition_id = "/subscriptions/${local.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/53ca6127-db72-4b80-b1b0-d745d6d5456d"
  principal_id       = module.chat_api_identity.principal_id
  principal_type     = "ServicePrincipal"
}
