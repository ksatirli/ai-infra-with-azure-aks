variable "location" {
  type        = string
  description = "Azure region."
}

variable "name_prefix" {
  type        = string
  description = "Short prefix used in resource names."
}

variable "resource_group_id" {
  type        = string
  description = "Resource ID of the demo resource group."
}

variable "foundry_name" {
  type        = string
  description = "Name (and custom subdomain) of the Foundry account."
}

variable "model" {
  type = object({
    deployment_name  = string
    uri              = string
    accelerator_type = string
    instances        = number
  })
  description = "Granite model to deploy on Foundry managed compute."
  default = {
    deployment_name  = "granite"
    uri              = "azureml://registries/HuggingFace/models/ibm-granite-granite-4.1-8b/versions/1"
    accelerator_type = "A100_80GB"
    instances        = 1
  }

  validation {
    condition     = startswith(var.model.uri, "azureml://registries/")
    error_message = "model.uri must be an AzureML registry asset URI."
  }

  validation {
    condition     = contains(["A100_80GB", "H100_80GB"], var.model.accelerator_type)
    error_message = "model.accelerator_type must be A100_80GB or H100_80GB."
  }
}
