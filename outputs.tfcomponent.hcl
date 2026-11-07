output "chat_api_url" {
  type        = string
  description = "Public URL of the chat API."
  value       = component.chat_api.url
}

output "chat_api_image" {
  type        = string
  description = "Image the chat API runs; GitHub Actions builds and pushes it."
  value       = component.chat_api.image
}

output "try_it" {
  type        = string
  description = "Call the chat API."
  value       = "curl -s -X POST ${component.chat_api.url}/chat -H 'content-type: application/json' -d '{\"message\":\"Hello from AKS Automatic\"}'"
}
