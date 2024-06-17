# Crossplane vCluster Vault Lab

In this lab I used crossplane to manage resources in hashicorp vault. By using the vault kubernetes authentication, crossplane can use its service account to authenticate to vault, assume a vault role and create resources scoped by the vault policy attached to the role.

Notes:
Terraform creates the auth for crossplane and creates a secret `static/db` and a policy to access the secret `db_access`. Crossplane creates a kubernetes auth and a role for the vault client test application, accessing the secret with vault agent and renders it on screen. The configuration follows these steps:
- Create a kubernetes cluster
- Install vault and the example secret store
- Configure kubernetes authentication, role and policy for crossplane
- Install crossplane and the vault provider with vault agent
- Create the vcluster
- Configure kubernetes authentication, and role for the client service. An existing policy to access the secret store path is referenced in the role
- Deploy the client application in the vcluster

## Create kind cluster
```bash
kind create cluster --name crossplane
```

## Install vault
This vault instance comes preconfigured with `root` as the admin access token:

```bash
helm repo add hashicorp https://helm.releases.hashicorp.com
helm install vault hashicorp/vault -n vault --set "server.dev.enabled=true" --set "server.logLevel=debug" --version 0.28.0 --create-namespace
```

Configure kubernetes authentication. Since vault is running in the same cluster as crossplane it can be configured to use its own service account to verify incoming authentication requests. The terraform script will create the authbackend, a role for crossplane and a secret store example with a read policy that can be used by clients to access the secret:

```bash
# use terraform
kubectl -n vault port-forward svc/vault 8200

cd terraform
terraform init
terraform apply
cd ..
``` 

Here are manual instructions for testing purpose of the authentication setup:
```bash
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

    path "identity/group" 
    {
    capabilities = [ "create", "delete", "list", "patch", "read", "update" ]
    }

    path "identity/group/*" 
    {
    capabilities = [ "create", "delete", "list", "patch", "read", "update" ]
    }

    path "identity/group-alias" 
    {
    capabilities = [ "create", "delete", "list", "patch", "read", "update" ]
    }

    path "identity/group-alias/*" 
    {
    capabilities = [ "create", "delete", "list", "patch", "read", "update" ]
    }
EOF
```

## Install crossplane
```bash
helm repo add crossplane-stable https://charts.crossplane.io/stable
helm install crossplane --namespace crossplane-system --create-namespace crossplane-stable/crossplane
```

Install crossplane vault provider. The provider adds the capability to create resources in Vaul:
```bash
kubectl apply -f crossplane/provider.yaml
```

Install crossplane composition and defition resources. While we can use plain managed resources, I created a composition for the `authbackend` and `role` separately. This allows to configure multiple vclusters with their own auth backend, while a role will only be created for each client service that requires access to vault. The auth backend composition creates both the `authbackend` as well as its `authconfiguration`. Note an auth backend can only be used for one kube api. Since vclusters come with their own API, we have to create a path for each vcluster. Also, for the vcluster, the vault service account cannot be used to verify requests, since vclusters act as a different cluster. Therefore Vault has to be handled as an kubernetes external service and requires a token reviewer service account. In this case, the auth backend is configured to accept the client service account token for verification. Still we need to add the kubernetes CA of the vcluster to the configuration to allow authentication the the vcluster kube API. This allows to still have short lived service account tokens, but every service account has to be added to the `system:auth-delegator` RBAC rule. (Note: another possibility to explore here would be to mirror service accounts from the vcluster to the host cluster)
```bash
# install xrds
kubectl apply -f crossplane/auth-backend/composition-definition.yaml
kubectl apply -f crossplane/auth-backend/composition.yaml
kubectl apply -f crossplane/auth-role/composition-definition.yaml
kubectl apply -f crossplane/auth-role/composition-role.yaml
```

## Prepare the vcluster
Install vcluster and prepare the kubernetes auth config with crossplane:
```bash
helm install v-cluster vcluster/vcluster -n team-x --values vcluster/config.yaml --create-namespace --version 0.20.0-beta.6

# edit the k8s cluster certificate authority
# you will get it from the the vcluster kubeconfig secret
kubectl get secret vc-v-cluster -n team-x --template={{.data.config}} -o json | jq -r '.data.["certificate-authority"]' | base64 -d

# after edit apply the resources
kubectl apply -f vault-test-client/auth.yaml
```

Useful vault commands to verify configurations:
```bash
# vault
kubectl exec -it vault-0 -n vault -- vault auth list
kubectl exec -it vault-0 -n vault -- vault read auth/vault-client/config
kubectl exec -it vault-0 -n vault -- vault list auth/vault-client/role
kubectl exec -it vault-0 -n vault -- vault policy list

# crossplane resources
kubectl get managed
```

Connect to the vcluster:
```bash
vcluster connect v-cluster --namespace team-x
```

Configure rbac role to let vault use the client service account token for the token review API:
```bash
kubectl apply -f vault-test-client/rbac-token-review.yaml
```

Deploy the vault test client:
```bash
kubectl apply -f vault-test-client/client.yaml
```

Check if the secrets are rendered securly for everyone to see:
```bash
kubectl port-forward pod/$(kubectl get pod -l app=vault-client -o json | jq -r '.items[0].metadata.name') 8080:80
```
