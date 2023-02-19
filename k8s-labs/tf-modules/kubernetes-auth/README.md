<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_vault"></a> [vault](#provider\_vault) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [vault_auth_backend.kubernetes](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/auth_backend) | resource |
| [vault_kubernetes_auth_backend_config.cert-manager](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/kubernetes_auth_backend_config) | resource |
| [vault_kubernetes_auth_backend_role.vault-issuer](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/kubernetes_auth_backend_role) | resource |
| [vault_policy.vault-issuer](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/policy) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_k8s_host"></a> [k8s\_host](#input\_k8s\_host) | Address for Kubernetes API server | `any` | n/a | yes |
| <a name="input_kubernetes_ca_cert"></a> [kubernetes\_ca\_cert](#input\_kubernetes\_ca\_cert) | kubernetes api server certificate | `any` | n/a | yes |
| <a name="input_token_reviewer_jwt"></a> [token\_reviewer\_jwt](#input\_token\_reviewer\_jwt) | jwt token of token reviewer service account | `any` | n/a | yes |
| <a name="input_vault_issuer_name"></a> [vault\_issuer\_name](#input\_vault\_issuer\_name) | The name given to the clusterIssuer resource | `string` | `"vault-issuer"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cacert"></a> [cacert](#output\_cacert) | The kubernetes API server CA cert |
| <a name="output_jwt"></a> [jwt](#output\_jwt) | The token of the token reviewer service account |
<!-- END_TF_DOCS -->