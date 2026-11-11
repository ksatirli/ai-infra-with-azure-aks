# see https://developer.hashicorp.com/terraform/language/block/stack/tfdeploy/identity_token
identity_token "azure" {
  audience = ["api://AzureADTokenExchange"]
}

# see https://developer.hashicorp.com/terraform/language/block/stack/tfdeploy/store
store "varset" "bootstrap" {
  name     = "ai-infra-bootstrap"
  category = "terraform"
}

# see https://developer.hashicorp.com/terraform/language/block/stack/tfdeploy/deployment_auto_approve
deployment_auto_approve "successful_plan" {
  check {
    condition = context.success
    reason    = "The plan did not succeed."
  }
}

# see https://developer.hashicorp.com/terraform/language/block/stack/tfdeploy/deployment_group
deployment_group "westus3" {
  auto_approve_checks = [deployment_auto_approve.successful_plan]
}

# see https://developer.hashicorp.com/terraform/language/block/stack/tfdeploy/deployment
deployment "westus3" {
  inputs = {
    identity_token = identity_token.azure.jwt

    subscription_id   = store.varset.bootstrap.stable.subscription_id
    tenant_id         = store.varset.bootstrap.stable.tenant_id
    client_id         = store.varset.bootstrap.stable.client_id
    location          = store.varset.bootstrap.stable.location
    name_prefix       = store.varset.bootstrap.stable.name_prefix
    resource_group_id = store.varset.bootstrap.stable.resource_group_id
    foundry_name      = store.varset.bootstrap.stable.foundry_name
    cluster_name      = store.varset.bootstrap.stable.cluster_name
    registry_name     = store.varset.bootstrap.stable.registry_name
  }

  deployment_group = "deployment_group.westus3"
}
