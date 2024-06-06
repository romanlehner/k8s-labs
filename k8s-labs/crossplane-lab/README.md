# Crossplane Vault Lab

In this lab I used crossplane to manage resources in hashicorp vault. By using the vault kubernetes authentication, crossplane can use its service account to authenticate to vault, assume a vault role and create resources scoped by the vault policy attached to the role.

Tempnote:
Terraform creates the auth for crossplane and creates a secret `static/db` and a policy to access the secret `db_access`. Crossplane creates a kubernetes auth and a role for the vault client test application, accessing the secret with vault agent and renders it on screen.
TODO: 
- run vault client in vcluster and access the secret.
- vault auth backend claim creates a auth with random suffix, currently the role claim requires a fixed backend name

## create kind cluster
```bash
kind create cluster --name crossplane
```

## install vault
This vault instance comes preconfigured with `root` as the admin access token:

```bash
helm repo add hashicorp https://helm.releases.hashicorp.com
helm install vault hashicorp/vault -n vault --set "server.dev.enabled=true" --version 0.28.0 --create-namespace
```

Configure kubernetes auth with service account and add a role:
```bash
# use terraform
kubectl -n vault port-forward svc/vault 8200

cd terraform
terraform init
terraform apply
cd ..

# or apply manually with vault cli from vault server pod
kubectl exec -it -n vault svc/vault 8200 -- sh 

vault login root

vault auth enable kubernetes

vault write auth/kubernetes/config kubernetes_host="https://crossplane-control-plane:6443"

vault write auth/kubernetes/role/crossplane-providers \
    bound_service_account_names="vault-provider" \
    bound_service_account_namespaces=crossplane \
    policies=crossplane \
    ttl=24h

vault policy write crossplane - <<EOF
    path "sys/policies/acl/*"
    {
    capabilities = ["create", "read", "update", "delete", "list", "sudo"]
    }

    path "sys/auth*"
    {
    capabilities = ["create", "read", "update", "delete", "list", "sudo"]
    }

    path "auth/*"
    {
    capabilities = ["create", "read", "update", "delete", "list", "sudo"]
    }

    path "identity/group" {
    capabilities = [ "create", "delete", "list", "patch", "read", "update" ]
    }
    path "identity/group/*" {
    capabilities = [ "create", "delete", "list", "patch", "read", "update" ]
    }
    path "identity/group-alias" {
    capabilities = [ "create", "delete", "list", "patch", "read", "update" ]
    }
    path "identity/group-alias/*" {
    capabilities = [ "create", "delete", "list", "patch", "read", "update" ]
    }
EOF
```

## install crossplane
```bash
helm repo add crossplane-stable https://charts.crossplane.io/stable
helm install crossplane --namespace crossplane --create-namespace crossplane-stable/crossplane
```

## install crossplane vault provider
```bash
kubectl apply -f crossplane/provider.yaml
```

## test the configuration
```bash
kubectl apply -f crossplane/test.yaml

# check the reconsilation status of crossplane
watch kubectl get managed
```

You can check the resources through Vault UI being created. When manually deleting any of those resoures from the Vault UI, then they will be re-created by crossplane (it can take a view minutes until crossplane picks up on the drift).

To instruct crossplane to delete the managed resources:
```bash
kubectl delete -f crossplane/test.yaml

# check the reconsilation status of crossplane
watch kubectl get managed
```
Verify the resources are no longer in Vault through the vault UI.

## test crossplane composition
The test above uses plain managed resources. In this section compositions and claims are used to create resources in vault, which allows to specify custom resource definitions exposing the vault auth configuration through a custom API.

```bash
# install xrds
kubectl apply -f crossplane/auth-backend/composition-definition.yaml
kubectl apply -f crossplane/auth-backend/composition.yaml
kubectl apply -f crossplane/auth-role/composition-definition.yaml
kubectl apply -f crossplane/auth-role/composition-role.yaml
```

Verify the resources have been created successfully:
```bash
kubectl get managed,compositions,xrd

# useful vault commands to check
kubectl exec -it vault-0 -n vault -- vault auth list
kubectl exec -it vault-0 -n vault -- vault read auth/vcluster1/config
kubectl exec -it vault-0 -n vault -- vault list auth/vcluster1/role
kubectl exec -it vault-0 -n vault -- vault policy list
```

Deploy the vault test client:
```bash
kubectl apply -f vault-test-client/client.yaml
```

Check if the secrets are rendered securly for everyone to see:
```bash
kubectl port-forward pod/$(kubectl get pod -l app=vault-client -o json | jq -r '.items[0].metadata.name') 8080:80
```