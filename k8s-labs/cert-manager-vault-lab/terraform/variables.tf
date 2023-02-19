variable "vault_issuer_name" {
  description = "The name given to the clusterIssuer resource"
  default     = "vault-issuer"
}

variable "k8s_host" {
  description = "Address for Kubernetes API server"
}

variable "vault_server" {
  description = "Address for Vault api server"
  default     = "vault.vault:8200"
}