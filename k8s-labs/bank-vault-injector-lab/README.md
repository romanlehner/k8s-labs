# Vault ENV test

Application tests the vault access operator integration and bank vault to inject secrets and environment variables.

## install and configure vault server

```bash
helm repo add hashicorp https://helm.releases.hashicorp.com
helm install vault hashicorp/vault --set "server.dev.enabled=true" --version 0.24.0 

export VAULT_TOKEN=root
export VAULT_ADDR='http://127.0.0.1:8200'

kubectl port-forward svc/vault 8200 

cd terraform
terraform apply
cd ..
```
## install bank vault

    helm repo add banzaicloud-stable https://kubernetes-charts.banzaicloud.com
    helm upgrade --install vault-secrets-webhook banzaicloud-stable/vault-secrets-webhook

## build the app

```bash
docker build -t vault-env-test:test .
```

## deploy the app

```bash
kubectl apply -f k8s.yaml
```

## Check integrations

```bash
kubectl logs vault-env-test
```

## Check all the injected environment variables

    kubectl exec -it env-test -- /vault/vault-env env
