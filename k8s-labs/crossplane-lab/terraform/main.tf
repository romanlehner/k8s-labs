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
  role_name                        = "crossplane"
  bound_service_account_names      = [var.service_name]
  bound_service_account_namespaces = [var.service_namespace]
  token_policies                   = ["default", vault_policy.crossplane.name]
  token_ttl                        = 86400
}

resource "vault_policy" "crossplane" {
  name   = "crossplane"
  policy = data.vault_policy_document.crossplane_policy.hcl
}

data "vault_policy_document" "crossplane_policy" {
  rule {
    path         = "sys/policies/acl/*"
    capabilities = ["create", "read", "update", "delete", "list", "sudo"]
  }
  rule {
    path         = "sys/auth*"
    capabilities = ["create", "read", "update", "delete", "list", "sudo"]
  }
  rule {
    path         = "auth/*"
    capabilities = ["create", "read", "update", "delete", "list", "sudo"]
  }
  rule {
    path         = "identity/group"
    capabilities = ["create", "delete", "list", "patch", "read", "update"]
  }
  rule {
    path         = "identity/group/*"
    capabilities = ["create", "delete", "list", "patch", "read", "update"]
  }
  rule {
    path         = "identity/group-alias"
    capabilities = ["create", "delete", "list", "patch", "read", "update"]
  }
  rule {
    path         = "identity/group-alias/*"
    capabilities = ["create", "delete", "list", "patch", "read", "update"]
  }
}

# Setup for secret store example
# Creates a secret that will be accessed by the example app for testing kubernetes auth

data "vault_policy_document" "db_access" {
  rule {
    path         = "static/data/db"
    capabilities = ["read", "list"]
  }
}

resource "vault_policy" "db_access" {
  name   = "db_access"
  policy = data.vault_policy_document.db_access.hcl
}

resource "vault_mount" "kvv2" {
  path        = "static"
  type        = "kv"
  options     = { version = "2" }
  description = "KV Version 2 secret engine mount"
}

resource "vault_kv_secret_v2" "service_secrets" {
  mount                      = vault_mount.kvv2.path
  name                       = "db"
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