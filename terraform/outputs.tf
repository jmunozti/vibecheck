output "web_url" {
  value       = "http://localhost:30080"
  description = "URL to access vibecheck web UI"
}

output "api_url" {
  value       = "http://localhost:30501"
  description = "URL to access vibecheck API"
}

output "grafana_url" {
  value       = "http://localhost:30030"
  description = "URL to access Grafana dashboard"
}

output "namespace" {
  value       = module.vibecheck_namespace.name
  description = "Kubernetes namespace"
}
