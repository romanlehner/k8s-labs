# Configure TLS certificates for kubernetes ingress with cert-manager and vault
The goal of this lab is to be able to manage TLS certificates for kubernetes ingress using nginx ingress controller, cert-manager and vault. Vault runs within the kubernetes cluster and can be addressed by its service resource for API operations.

The kubernetes authentication for Vault relies on its vault service account and local token review method. This means that the service account token auf the vault issuer will be verified by the service account token of vault. 

Shoutout to [@joshvanl](https://github.com/JoshVanL/cert-manager-vault-demo) as his repo was one of the main sources to help me with my research.

## Prepare KIND cluster

	kind create cluster --name vault --config=kind/config.yaml

## Install [Metallb](https://kind.sigs.k8s.io/docs/user/loadbalancer/)

	kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.7/config/manifests/metallb-native.yaml

Get the ip address CIDR of the kubernetes cluster and adjust the address pool range:

	docker network inspect -f '{{.IPAM.Config}}' kind
	kubectl apply -f k8s/metallb.yaml

## Install nginx ingress controller

	helm repo add nginx-stable https://helm.nginx.com/stable
	helm repo update
	helm -n nginx install nginx nginx-stable/nginx-ingress --create-namespace

## cert-manager with vault issuer

Setup vault and cert-manager

	helm repo add jetstack https://charts.jetstack.io
	helm install cert-manager jetstack/cert-manager --namespace cert-manager --version v1.5.3 --set installCRDs=true --create-namespace
	helm repo add hashicorp https://helm.releases.hashicorp.com
	helm install vault hashicorp/vault --namespace vault --set "server.dev.enabled=true" --version 0.24.0 --create-namespace

	export TF_VAR_token_reviewer_jwt=$(kubectl -n vault get secret vault -o jsonpath="{.data.token}" | base64 -d)
	export TF_VAR_kubernetes_ca_cert=$(kubectl -n vault get secret vault -o jsonpath="{.data.ca\.crt}" | base64 -d)
	export TF_VAR_k8s_host="vault-control-plane:6443"

Connect to vault over localhost in a different terminal session:

	kubectl port-forward svc/vault 8200 -n vault

Configure vault PKI root and intermediate ca

	export VAULT_TOKEN=root
	export VAULT_ADDR='http://127.0.0.1:8200'

	cd terraform
	terraform apply
	cd ..

Create vault issuer

	kubectl apply -f k8s/vault-issuer.yaml

### Test configuration
Login with vault-issuer JWT token:

	JWT=$(kubectl -n cert-manager get secret vault-issuer-token -o jsonpath="{.data.token}" | base64 -d )
	vault write auth/kubernetes/login role=vault-issuer jwt=$JWT

Create https-ingress and check the certificate served:

	kubectl apply -f ingress-https.yaml
	IP=$(kubectl get ing nginx -o jsonpath={'.status.loadBalancer.ingress[0].ip'})
	docker run -it --network kind alpine/openssl s_client -showcerts -connect $IP:443 -servername nginx.webdomain.com

You can also try to issue a certificate directly and check if the resources are created:

	kubectl apply -f k8s/certifcate.yaml
	kubectl get cr,cert,secret

# Notes
Running vault in kuberentes already comes with its service account with the `system:auth-delegator` cluster role which allows to review tokens of other service accounts that try to authenticate with the kubernetes auth in vault. 