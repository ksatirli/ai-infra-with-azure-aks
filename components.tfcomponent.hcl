# see https://developer.hashicorp.com/terraform/language/block/stack/tfcomponent/component
component "foundry" {
  source = "./components/foundry"

  inputs = {
    location          = var.location
    name_prefix       = var.name_prefix
    resource_group_id = var.resource_group_id
    foundry_name      = var.foundry_name
  }

  providers = {
    azapi     = provider.azapi.this
    azurerm   = provider.azurerm.this
    modtm     = provider.modtm.this
    random    = provider.random.this
    terraform = provider.terraform.this
    time      = provider.time.this
  }
}

# see https://developer.hashicorp.com/terraform/language/block/stack/tfcomponent/component
component "aks" {
  source = "./components/aks"

  inputs = {
    location          = var.location
    resource_group_id = var.resource_group_id
    cluster_name      = var.cluster_name
    registry_name     = var.registry_name
  }

  providers = {
    azapi     = provider.azapi.this
    azurerm   = provider.azurerm.this
    random    = provider.random.this
    terraform = provider.terraform.this
  }
}

# see https://developer.hashicorp.com/terraform/language/block/stack/tfcomponent/component
component "chat_api" {
  source = "./components/chat-api"

  inputs = {
    location              = var.location
    resource_group_id     = var.resource_group_id
    cluster_name          = var.cluster_name
    oidc_issuer_url       = component.aks.oidc_issuer_url
    registry_login_server = component.aks.registry_login_server
    foundry_id            = component.foundry.foundry_id
    inference_base_url    = component.foundry.inference_base_url
    model_deployment_name = component.foundry.model_deployment_name
  }

  providers = {
    azapi      = provider.azapi.this
    azurerm    = provider.azurerm.this
    kubernetes = provider.kubernetes.this
    terraform  = provider.terraform.this
  }
}
