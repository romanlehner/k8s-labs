output "jwt" {
  description = "The token of the token reviewer service account"
  value       = var.token_reviewer_jwt
}

output "cacert" {
  description = "The kubernetes API server CA cert"
  value       = var.kubernetes_ca_cert
}