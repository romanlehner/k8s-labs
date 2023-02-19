# Create certificates with cert-manager and cluster external vault

This lab only focuses on being able create certificates with vault running outside of the kubernetes cluster. In this scenario we will create a kind cluster and run vault with docker in the same cluster network, so that kind api server and vault api server can reach each other. 

The kubernetes auth service in Vault relies on a token reviewer service account that will verify the vault issuer service account token on requesting certificates. 

## Setup kind cluster and cert-manager

    kind create cluster --name vault --config config.yaml

    helm repo add jetstack https://charts.jetstack.io
	helm install cert-manager jetstack/cert-manager --namespace cert-manager --version v1.5.3 --set installCRDs=true --create-namespace

    kubectl apply -f k8s/vault-issuer.yaml
    kubectl apply -f k8s/vault-auth-token-reviewer.yaml

## Run vault within kind network

    docker run -d -p 8200:8200 --network kind --name vault-server --cap-add=IPC_LOCK -e 'VAULT_DEV_ROOT_TOKEN_ID=root' -e 'VAULT_DEV_LISTEN_ADDRESS=0.0.0.0:8200' vault

    export VAULT_ADDR=http://localhost:8200
    export VAULT_TOKEN=root

## Configure vault kubernetes-auth

    export TF_VAR_token_reviewer_jwt=$(kubectl -n kube-system get secret vault-auth-token-reviewer-token -o jsonpath="{.data.token}" | base64 -d)
	export TF_VAR_kubernetes_ca_cert=$(kubectl -n kube-system get secret vault-auth-token-reviewer-token -o jsonpath="{.data.ca\.crt}" | base64 -d)
	export TF_VAR_k8s_host="vault-control-plane:6443"

    cd terraform
    terraform apply
    cd ..

## Test configuration

Try login with vault-issuer service account:

    JWT=$(kubectl get secret -n cert-manager vault-issuer-token -o jsonpath="{.data.token}" | base64 -d)
    vault write auth/kubernetes/login role=vault-issuer jwt=$JWT

Try to create a certiticate and check certificate status:

    kubectl apply -f k8s/certificate.yaml
    kubectl get cr,cert
