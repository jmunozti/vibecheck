variable "name" {
  type        = string
  description = "Name of the Service"
}

variable "namespace" {
  type        = string
  description = "Namespace of the Service"
}

variable "selector_label" {
  type        = string
  description = "Label of the Deployment that the Service selects"
}

variable "port" {
  type        = number
  description = "Port of the Service"
}

variable "target_port" {
  type        = number
  description = "Port of the container the Service targets"
}

variable "node_port" {
  type        = number
  default     = null
  description = "Optional NodePort if exposed outside the cluster"
}

variable "type" {
  type        = string
  description = "Service type: ClusterIP, NodePort, LoadBalancer"
}
