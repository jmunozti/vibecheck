resource "kubernetes_namespace_v1" "this" {
  metadata {
    name = var.name
  }
}

output "name" {
  description = "Name of the created Namespace"
  value       = kubernetes_namespace_v1.this.metadata[0].name
}
