locals {
  app_name    = "chat-api"
  sa_name     = local.app_name
  app_version = trimspace(file("${path.module}/../../app/VERSION"))
  app_image   = "${var.registry_login_server}/${local.app_name}:${local.app_version}"

  resource_group_name = provider::azapi::parse_resource_id("Microsoft.Resources/resourceGroups", var.resource_group_id).name
  subscription_id     = provider::azapi::parse_resource_id("Microsoft.Resources/resourceGroups", var.resource_group_id).subscription_id
}
