# see https://registry.terraform.io/modules/Azure/avm-ptn-aiml-ai-foundry/azurerm/latest
module "ai_foundry" {
  source  = "Azure/avm-ptn-aiml-ai-foundry/azurerm"
  version = "0.14.0"

  base_name                  = var.name_prefix
  location                   = var.location
  resource_group_resource_id = var.resource_group_id
  enable_telemetry           = false

  ai_foundry = {
    name                    = var.foundry_name
    disable_local_auth      = true
    create_ai_agent_service = false
  }

  ai_model_deployments = {}

  ai_projects = {
    demo = {
      name                       = "${var.name_prefix}-demo"
      display_name               = "AI infrastructure demo"
      description                = "Project for the chat API running on AKS Automatic."
      create_project_connections = false
    }
  }

  create_byor              = false
  create_private_endpoints = false
}

# see https://learn.microsoft.com/azure/foundry/how-to/deploy-models-managed
resource "azapi_resource" "granite" {
  type      = "Microsoft.CognitiveServices/accounts/managedComputeDeployments@2026-09-15-preview"
  name      = var.model.deployment_name
  parent_id = module.ai_foundry.ai_foundry_id

  schema_validation_enabled = false

  body = {
    sku = {
      name     = "GlobalManagedCompute"
      capacity = var.model.instances
    }

    properties = {
      model                = var.model.uri
      acceleratorType      = var.model.accelerator_type
      versionUpgradeOption = "OnceNewDefaultVersionAvailable"
    }
  }

  response_export_values = ["properties.routes"]

  timeouts {
    create = "90m"
    delete = "60m"
  }
}
