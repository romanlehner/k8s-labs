# Vault Agent in Kubernetes Lab 
## Prepare KIND cluster

```bash
kind create cluster --name vault --config=kind/config.yaml
```

## Deploy and configure Vault server

```bash
helm repo add hashicorp https://helm.releases.hashicorp.com
helm install vault hashicorp/vault -n vault --set "server.dev.enabled=true" --version 0.24.0 --create-namespace

export TF_VAR_k8s_host="vault-control-plane:6443"
export VAULT_TOKEN=root
export VAULT_ADDR='http://127.0.0.1:8200'

kubectl -n vault port-forward svc/vault 8200 

cd terraform
terraform apply
cd ..
```

## Deploy a vault client and test vault login with http API

```bash
kubectl apply -f vault-client.yaml

kubectl exec -it $(kubectl get pod -l app=vault-client -o json | jq -r '.items[0].metadata.name') -- bash

apt update
apt install jq

export TOKEN=$(curl --request POST --data '{"jwt": "'"$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)"'", "role": "vault-client_default"}' vault.vault:8200/v1/auth/kubernetes/login | jq -r .auth.client_token)

curl -H "X-Vault-Token: ${TOKEN}" -X GET http://vault.vault:8200/v1/static/data/service/vault-client/database | jq -r '.data.data'
```

## Check vault-agent populating the secrets

```bash
kubectl port-forward pod/$(kubectl get pod -l app=vault-client -o json | jq -r '.items[0].metadata.name') 8080:80
```
