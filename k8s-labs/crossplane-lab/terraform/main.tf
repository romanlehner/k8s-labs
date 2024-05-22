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
