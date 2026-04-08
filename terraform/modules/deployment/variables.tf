variable "name" {
  type        = string
  description = "Name of the Deployment"
}

variable "namespace" {
  type        = string
  description = "Namespace of the Deployment"
}

variable "image" {
  type        = string
  description = "Container image"
}

variable "container_port" {
  type        = number
  description = "Container port"
}

variable "env_configmap" {
  type        = string
  default     = ""
  description = "ConfigMap to load environment variables for the main container"
}

variable "init_container" {
  type        = bool
  default     = false
  description = "Whether to add the Postgres wait init container"
}

variable "init_env_configmap" {
  type        = string
  default     = ""
  description = "ConfigMap to load environment variables for the init container"
}

variable "env_vars" {
  type        = map(string)
  default     = {}
  description = "Additional environment variables"
}

variable "cpu_request" {
  type        = string
  default     = "50m"
  description = "CPU request"
}

variable "cpu_limit" {
  type        = string
  default     = "200m"
  description = "CPU limit"
}

variable "memory_request" {
  type        = string
  default     = "64Mi"
  description = "Memory request"
}

variable "memory_limit" {
  type        = string
  default     = "256Mi"
  description = "Memory limit"
}

variable "health_path" {
  type        = string
  default     = ""
  description = "HTTP path for liveness and readiness probes (empty to disable)"
}
