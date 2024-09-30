resource "vault_auth_backend" "kubernetes" {
  type = "kubernetes"
}

resource "vault_kubernetes_auth_backend_config" "kubernetes" {
  backend         = vault_auth_backend.kubernetes.path
  kubernetes_host = "https://${var.k8s_host}"
  #   disable_iss_validation = "true"
  disable_local_ca_jwt = false
}

resource "vault_kubernetes_auth_backend_role" "service_role" {
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = "argo"
  bound_service_account_names      = [var.service_name]
  bound_service_account_namespaces = [var.service_namespace]
  token_policies                   = ["default", vault_policy.token.name]
  token_ttl                        = 86400
}

data "vault_policy_document" "token_access" {
  rule {
    path         = "static/data/token"
    capabilities = ["read", "list"]
  }
}

resource "vault_policy" "token" {
  name   = "token"
  policy = data.vault_policy_document.token_access.hcl
}

resource "vault_mount" "kvv2" {
  path        = "static"
  type        = "kv"
  options     = { version = "2" }
  description = "KV Version 2 secret engine mount"
}

resource "vault_kv_secret_v2" "service_secrets" {
  mount                      = vault_mount.kvv2.path
  name                       = "token"
  cas                        = 1
  delete_all_versions        = true
  data_json                  = jsonencode(
  {
    token       = "admin"
  }
  )
  custom_metadata {
    max_versions = 5
  }
}