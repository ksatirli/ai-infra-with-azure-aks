output "image" {
  description = "Image the chat API deployment runs."
  value       = local.app_image
}

output "url" {
  description = "Public URL of the chat API."
  value       = "http://${kubernetes_service_v1.chat_api.status[0].load_balancer[0].ingress[0].ip}"
}
