variable "name" {
  type        = string
  description = "Name of the ConfigMap"
}

variable "namespace" {
  type        = string
  description = "Namespace where the ConfigMap will be created"
}

variable "env_file" {
  type        = string
  description = "Path to the .env file to load into the ConfigMap"
}
