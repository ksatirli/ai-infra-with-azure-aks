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
  description = "Name of the AKS Automatic cluster; prefixes the chat API identity."
}

variable "oidc_issuer_url" {
  type        = string
  description = "OIDC issuer of the AKS cluster."
}

variable "registry_login_server" {
  type        = string
  description = "Login server of the registry that holds the chat API image."
}

variable "foundry_id" {
  type        = string
  description = "Resource ID of the Foundry account."
}

variable "inference_base_url" {
  type        = string
  description = "OpenAI-compatible (v1) base URL of the Foundry account."
}

variable "model_deployment_name" {
  type        = string
  description = "Foundry deployment the chat API calls."
}

variable "namespace" {
  type        = string
  description = "Kubernetes namespace for the chat API."
  default     = "chat"
}

variable "replicas" {
  type        = number
  description = "Number of chat API replicas."
  default     = 2
}
