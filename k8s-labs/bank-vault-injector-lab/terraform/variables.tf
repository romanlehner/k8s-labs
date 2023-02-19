variable "service_name" {
  description = "Name of the service that wants to authenticate with Vault server"
  type        = string
  default     = "vault-client"
}

variable "service_namespace" {
  description = "Namespace where the service is running"
  type        = string
  default     = "default"
}

variable "k8s_host" {
  type        = string
  description = "Address for Kubernetes API server"
}

variable "namespace" {
  type = string
  description = "service namespace"
}