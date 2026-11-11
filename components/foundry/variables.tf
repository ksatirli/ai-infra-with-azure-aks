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
    deployment_name     = string
    uri                 = string
    deployment_template = string
    accelerator_type    = string
    instances           = number
  })
  description = "Granite model to deploy on Foundry managed compute: the azure-huggingface model asset, one of its allowed deployment templates, and the accelerator that template targets."
  default = {
    deployment_name     = "granite"
    uri                 = "azureml://registries/azure-huggingface/models/ibm-granite--granite-4.2-30b/versions/1"
    deployment_template = "azureml://registries/azure-huggingface/deploymenttemplates/ibm-granite--granite-4-2-30b--64k-nvidia-a100/labels/latest"
    accelerator_type    = "A100_80GB"
    instances           = 1
  }

  validation {
    condition     = startswith(var.model.uri, "azureml://registries/azure-huggingface/models/")
    error_message = "model.uri must be a model asset in the azure-huggingface registry; only that registry serves Foundry managed compute."
  }

  validation {
    condition     = startswith(var.model.deployment_template, "azureml://registries/azure-huggingface/deploymenttemplates/")
    error_message = "model.deployment_template must be a deployment template asset in the azure-huggingface registry."
  }

  validation {
    condition     = contains(["A100_80GB", "H100_80GB", "MI300_192GB"], var.model.accelerator_type)
    error_message = "model.accelerator_type must be A100_80GB, H100_80GB or MI300_192GB."
  }
}
