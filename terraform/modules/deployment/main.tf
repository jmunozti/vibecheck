resource "kubernetes_deployment" "this" {
  metadata {
    name      = var.name
    namespace = var.namespace
    labels    = { app = var.name }
  }

  spec {
    replicas = 1

    selector {
      match_labels = { app = var.name }
    }

    template {
      metadata {
        labels = { app = var.name }
      }

      spec {
        dynamic "init_container" {
          for_each = var.init_container ? [1] : []
          content {
            name  = "wait-for-postgres"
            image = "postgres:15"
            command = [
              "sh", "-c",
              "until pg_isready -h postgres -p 5432 -U $POSTGRES_USER -d $POSTGRES_DB; do echo 'Waiting for PostgreSQL...'; sleep 2; done;"
            ]
            env_from {
              config_map_ref {
                name = var.init_env_configmap
              }
            }
          }
        }

        container {
          name               = var.name
          image              = var.image
          image_pull_policy  = "IfNotPresent"
          port {
            container_port = var.container_port
          }

          dynamic "env_from" {
            for_each = var.env_configmap != "" ? [1] : []
            content {
              config_map_ref {
                name = var.env_configmap
              }
            }
          }

          dynamic "env" {
            for_each = var.env_vars
            content {
              name  = env.key
              value = env.value
            }
          }
        }
      }
    }
  }
}

output "name" {
  value = kubernetes_deployment.this.metadata[0].name
}
