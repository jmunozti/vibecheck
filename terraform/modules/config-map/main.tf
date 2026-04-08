locals {
  env_data = {
    for line in split("\n", file(var.env_file)) :
    trim(split("=", line)[0], " \t\r\n") => trim(split("=", line)[1], " \t\r\n")
    if length(trim(line, " \t\r\n")) > 0 && !startswith(trim(line, " \t\r\n"), "#")
  }
}

resource "kubernetes_config_map_v1" "this" {
  metadata {
    name      = var.name
    namespace = var.namespace
  }

  data = local.env_data
}

output "name" {
  description = "Name of the created ConfigMap"
  value       = kubernetes_config_map_v1.this.metadata[0].name
}
