provider "kubernetes" {
  config_path    = var.kubeconfig_path
  config_context = var.kubeconfig_context
}

locals {
  all_env = {
    for line in split("\n", file(var.env_file)) :
    trim(split("=", line)[0], " \t\r\n") => trim(split("=", line)[1], " \t\r\n")
    if length(trim(line, " \t\r\n")) > 0 && !startswith(trim(line, " \t\r\n"), "#")
  }
}

# ----------------- Namespace -----------------
module "vibecheck_namespace" {
  source = "./modules/kubernetes-namespace"
  name   = "vibecheck"
}

# ----------------- ConfigMaps -----------------
module "api_configmap" {
  source    = "./modules/config-map"
  name      = "vibecheck-api-env"
  namespace = module.vibecheck_namespace.name
  env_file  = "${path.module}/../api/.env"
}

module "web_configmap" {
  source    = "./modules/config-map"
  name      = "vibecheck-web-env"
  namespace = module.vibecheck_namespace.name
  env_file  = "${path.module}/../web/.env"
}

module "postgres_configmap" {
  source    = "./modules/config-map"
  name      = "postgres-config"
  namespace = module.vibecheck_namespace.name
  env_file  = var.env_file
}

# ----------------- Deployments -----------------
module "postgres" {
  source         = "./modules/deployment"
  name           = "postgres"
  namespace      = module.vibecheck_namespace.name
  image          = "postgres:16"
  container_port = 5432
  env_configmap  = module.postgres_configmap.name
}

module "postgres_exporter" {
  source         = "./modules/deployment"
  name           = "postgres-exporter"
  namespace      = module.vibecheck_namespace.name
  image          = "quay.io/prometheuscommunity/postgres-exporter:latest"
  container_port = 9187
  env_vars = {
    DATA_SOURCE_NAME = local.all_env["DATA_SOURCE_NAME"]
  }
}

module "vibecheck_api" {
  source             = "./modules/deployment"
  name               = "vibecheck-api"
  namespace          = module.vibecheck_namespace.name
  image              = "vibecheck-api:latest"
  container_port     = 8080
  env_configmap      = module.api_configmap.name
  init_container     = true
  init_env_configmap = module.postgres_configmap.name
}

module "vibecheck_web" {
  source         = "./modules/deployment"
  name           = "vibecheck-web"
  namespace      = module.vibecheck_namespace.name
  image          = "vibecheck-web:latest"
  container_port = 3000
  env_configmap  = module.web_configmap.name
}

module "grafana" {
  source         = "./modules/deployment"
  name           = "grafana"
  namespace      = module.vibecheck_namespace.name
  image          = "grafana/grafana:latest"
  container_port = 3000
  env_vars = {
    GF_SECURITY_ADMIN_USER     = local.all_env["GF_SECURITY_ADMIN_USER"]
    GF_SECURITY_ADMIN_PASSWORD = local.all_env["GF_SECURITY_ADMIN_PASSWORD"]
  }
}

module "prometheus" {
  source         = "./modules/deployment"
  name           = "prometheus"
  namespace      = module.vibecheck_namespace.name
  image          = "prom/prometheus:latest"
  container_port = 9090
  env_vars       = {}
}

# ----------------- Services -----------------
module "postgres_service" {
  source         = "./modules/service"
  name           = "postgres"
  namespace      = module.vibecheck_namespace.name
  selector_label = "postgres"
  port           = 5432
  target_port    = 5432
  type           = "ClusterIP"
}

module "postgres_exporter_service" {
  source         = "./modules/service"
  name           = "postgres-exporter"
  namespace      = module.vibecheck_namespace.name
  selector_label = "postgres-exporter"
  port           = 9187
  target_port    = 9187
  type           = "ClusterIP"
}

module "api_service" {
  source         = "./modules/service"
  name           = "vibecheck-api"
  namespace      = module.vibecheck_namespace.name
  selector_label = "vibecheck-api"
  port           = 5001
  target_port    = 8080
  node_port      = 30501
  type           = "NodePort"
}

module "web_service" {
  source         = "./modules/service"
  name           = "vibecheck-web"
  namespace      = module.vibecheck_namespace.name
  selector_label = "vibecheck-web"
  port           = 3000
  target_port    = 3000
  node_port      = 30080
  type           = "NodePort"
}

module "grafana_service" {
  source         = "./modules/service"
  name           = "grafana"
  namespace      = module.vibecheck_namespace.name
  selector_label = "grafana"
  port           = 3000
  target_port    = 3000
  node_port      = 30030
  type           = "NodePort"
}

module "prometheus_service" {
  source         = "./modules/service"
  name           = "prometheus"
  namespace      = module.vibecheck_namespace.name
  selector_label = "prometheus"
  port           = 9090
  target_port    = 9090
  node_port      = 30900
  type           = "NodePort"
}
