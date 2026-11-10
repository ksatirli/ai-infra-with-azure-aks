output "image" {
  description = "Image the chat API deployment runs."
  value       = local.app_image
}

# While the kubernetes provider is deferred (first plan, cluster not yet
# created) the Service's planned `status` is null, so index it defensively.
output "url" {
  description = "Public URL of the chat API; null until the load balancer has an IP."
  value       = try("http://${kubernetes_service_v1.chat_api.status[0].load_balancer[0].ingress[0].ip}", null)
}
