resource "vault_auth_backend" "kubernetes" {
  type = "kubernetes"
}

resource "vault_kubernetes_auth_backend_config" "cert-manager" {
  backend            = vault_auth_backend.kubernetes.path
  kubernetes_host    = "https://${var.k8s_host}"
  kubernetes_ca_cert = var.kubernetes_ca_cert
  token_reviewer_jwt = var.token_reviewer_jwt
  #   disable_iss_validation = "true"
  disable_local_ca_jwt = false
}