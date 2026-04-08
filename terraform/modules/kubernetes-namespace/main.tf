resource "kubernetes_namespace" "this" {
  metadata {
    name = var.name
  }
}

output "name" {
  value = kubernetes_namespace.this.metadata[0].name
}