variable "identity_token" {
  type        = string
  description = "OIDC token that Azure exchanges for an access token."
  ephemeral   = true
}

variable "subscription_id" {
  type        = string
  description = "Azure subscription."
}

variable "tenant_id" {
  type        = string
  description = "Entra ID tenant."
}

variable "client_id" {
  type        = string
  description = "Client ID of the managed identity this Stack runs as."
}

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

variable "cluster_name" {
  type        = string
  description = "Name of the AKS Automatic cluster."
}

variable "registry_name" {
  type        = string
  description = "Name of the Azure Container Registry."
}
