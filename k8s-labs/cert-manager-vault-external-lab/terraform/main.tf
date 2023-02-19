module "pki" {
  source       = "../../tf-modules/pki"
  vault_server = var.vault_server
}

module "kubernetes-auth" {
  source             = "../../tf-modules/kubernetes-auth"
  vault_issuer_name  = var.vault_issuer_name
  k8s_host           = var.k8s_host
  token_reviewer_jwt = var.token_reviewer_jwt
  kubernetes_ca_cert = var.kubernetes_ca_cert
}