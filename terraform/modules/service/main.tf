resource "kubernetes_service" "this" {
  metadata {
    name      = var.name
    namespace = var.namespace
  }

  spec {
    selector = { app = var.selector_label }

    port {
      port        = var.port
      target_port = var.target_port
      node_port   = var.node_port != null ? var.node_port : null
    }

    type = var.type
  }
}

output "name" {
  value = kubernetes_service.this.metadata[0].name
}
