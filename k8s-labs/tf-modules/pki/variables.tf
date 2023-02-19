variable "vault_server" {
  description = "Address for Vault api server"
  default     = "vault.vault:8200"
}

variable "vault_issuer_name" {
  description = "The name given to the clusterIssuer resource"
  default     = "vault-issuer"
}