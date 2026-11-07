variable "location" {
  type        = string
  description = "Azure region."
}

variable "resource_group_id" {
  type        = string
  description = "Resource ID of the demo resource group."
}

variable "cluster_name" {
  type        = string
  description = "Name of the AKS Automatic cluster."
}

variable "registry_name" {
  type        = string
  description = "Name of the Azure Container Registry (GitHub Actions pushes to it by this name)."
}
