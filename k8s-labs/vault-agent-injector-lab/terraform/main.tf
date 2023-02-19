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
  role_name                        = "${var.service_name}_${var.service_namespace}"
  bound_service_account_names      = [var.service_name]
  bound_service_account_namespaces = [var.service_namespace]
  token_policies                   = [vault_policy.service_policy.name]
  token_ttl                        = 86400
}

resource "vault_policy" "service_policy" {
  name   = var.service_name
  policy = data.vault_policy_document.vault_paths_policy.hcl
}

data "vault_policy_document" "vault_paths_policy" {
  rule {
    path         = "static/data/service/${var.service_name}/*"
    capabilities = ["read", "list"]
  }
}

resource "vault_policy" "vault_role_policy" {
  name   = var.service_name # this name will be also used by kubernetes auth config to attach the policy
  policy = data.vault_policy_document.vault_paths_policy.hcl
}

resource "vault_mount" "kvv2" {
  path        = "static"
  type        = "kv"
  options     = { version = "2" }
  description = "KV Version 2 secret engine mount"
}

resource "vault_kv_secret_v2" "service_secrets" {
  mount                      = vault_mount.kvv2.path
  name                       = "service/${var.service_name}/database"
  cas                        = 1
  delete_all_versions        = true
  data_json                  = jsonencode(
  {
    user       = "admin",
    pass       = "123"
  }
  )
  custom_metadata {
    max_versions = 5
  }
}