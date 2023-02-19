variable "vault_issuer_name" {
  description = "The name given to the clusterIssuer resource"
  default     = "vault-issuer"
}

variable "k8s_host" {
  description = "Address for Kubernetes API server"
}

variable "token_reviewer_jwt" {
  description = "jwt token of token reviewer service account"
}

variable "kubernetes_ca_cert" {
  description = "kubernetes api server certificate"
}