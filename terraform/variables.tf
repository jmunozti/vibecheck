variable "kubeconfig_path" {
  description = "Path to the Kubernetes kubeconfig"
  type        = string
  default     = "../kubeconfig-kind"
}

variable "kubeconfig_context" {
  description = "Kubernetes context to use"
  type        = string
  default     = "kind-vibecheck-cluster"
}

variable "env_file" {
  type        = string
  description = "Path to the .env file to load in the ConfigMap"
  default     = "./.env"
}
