resource "vault_policy" "vault-issuer" {
  name = var.vault_issuer_name

  policy = <<EOT
path "pki_int/sign/${var.vault_issuer_name}" {
  capabilities = ["read", "update", "list", "delete"]
}
path "pki_int/issue/${var.vault_issuer_name}" {
  capabilities = ["read", "update", "list", "delete"]
}
EOT
}

resource "vault_kubernetes_auth_backend_role" "vault-issuer" {
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = var.vault_issuer_name
  bound_service_account_names      = [var.vault_issuer_name]
  bound_service_account_namespaces = ["cert-manager"]
  token_policies                   = [vault_policy.vault-issuer.name]
  token_ttl                        = 86400
}
