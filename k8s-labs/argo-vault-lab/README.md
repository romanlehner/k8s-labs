# ArgoCD with Vault secrets management

## Create a simple kind cluster
```bash
kind create cluster --name argo
```

## Install argo cd
```bash
kubectl create namespace argocd
kubectl apply -n argocd -f kubectl apply -f argo-vault-lab/argo-server.yaml
```

Get the admin password to login to argo cd:
```bash
argocd admin initial-password -n argocd
```

## Setup Vault with secret store

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

## Test secret management
Update the secret in vault to a new value and use the `hard refresh` option in argocd. It should update the secret in the configmap to use the new value.

## Test authentication with kubernetes

Get the token from the argo-repo-server pod and perform following action:

```bash
jwt=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
vault write auth/kubernetes/login role=argo jwt=$jwt
```

In the avp pod perform the following actions:

```bash
argocd-vault-plugin generate ./ --verbose-sensitive-output
```

## Test locally
Make sure you are have an active port-forward connection to vault and set the respective environment variables:

```bash
kubectl -n vault port-forward svc/vault 8200

vault login root

export AVP_TYPE=vault
export AVP_AUTH_TYPE=token
export VAULT_TOKEN=root

argocd-vault-plugin generate test/configmap.yaml --verbose-sensitive-output
```

Example Output:
```yaml
# key name comes from ConfigMap manifest, stringifying value test-inline to fit
apiVersion: v1
data:
  token: "1234"
kind: ConfigMap
metadata:
  name: test-inline
```
